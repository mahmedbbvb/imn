import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../services/database/app_database.dart';
import '../../services/signaling/signaling_service.dart';
import '../../services/webrtc/webrtc_service.dart';
import '../../services/webrtc/call_service.dart';
import '../call/call_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String contactId;
  final String sessionId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.contactId,
    required this.sessionId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _imagePicker = ImagePicker();

  List<Message> _messages = [];
  bool _peerTyping = false;
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _typingTimer;

  StreamSubscription? _msgSub;
  StreamSubscription? _connSub;
  StreamSubscription? _signalSub;
  PeerConnectionState _connState = PeerConnectionState.idle;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadContact().then((_) => _initConnection());
    _listenToWebRTC();
    _listenToSignaling();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _msgSub?.cancel();
    _connSub?.cancel();
    _signalSub?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContact() async {
    final db = ref.read(databaseProvider);
    var c = await db.getContactByDeviceId(widget.contactId);
    c ??= await db.getContactById(widget.contactId);
    if (mounted) setState(() => _contact = c);
  }

  Future<void> _loadMessages() async {
    final db = ref.read(databaseProvider);
    final msgs = await db.getMessages(widget.conversationId);
    if (mounted) setState(() => _messages = msgs.reversed.toList());
    _scrollToBottom();
  }

  /// Initialize WebRTC / Signaling connection on opening chat
  Future<void> _initConnection() async {
    final signaling = ref.read(signalingServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);
    final identity = ref.read(identityServiceProvider);

    if (!signaling.isConnected) {
      await signaling.connect();
    }
    await signaling.registerDevice(identity.deviceId);

    if (!webrtc.isConnected) {
      signaling.createSession(widget.sessionId);
      try {
        final offerSdp = await webrtc.createOffer(widget.sessionId);
        signaling.sendOffer(widget.sessionId, offerSdp);
      } catch (_) {}
    }

    _flushPending();
  }

  void _listenToWebRTC() {
    final webrtc = ref.read(webrtcServiceProvider);
    _connSub = webrtc.connectionState.listen((state) {
      if (mounted) setState(() => _connState = state);
      if (state == PeerConnectionState.connected) {
        _flushPending();
        _loadMessages();
      }
    });
    _msgSub = webrtc.messages.listen((msg) {
      if (msg.type == 'typing') {
        final payload = msg.payload as Map<String, dynamic>;
        setState(() => _peerTyping = payload['typing'] == true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _peerTyping = false);
        });
      }
      if (msg.type == 'msg') _loadMessages();
    });
  }

  Future<void> _flushPending() async {
    final msgSvc = ref.read(messageServiceProvider);
    await msgSvc.flushPendingMessages(
        widget.conversationId, _contact?.deviceId);
  }

  void _listenToSignaling() {
    final signaling = ref.read(signalingServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);

    _signalSub = signaling.messages?.listen((msg) async {
      // Listen for incoming call offer
      if (msg.type == SignalingMessageType.callSignal) {
        final data = msg.data;
        if (data != null && data['action'] == 'offer' && mounted) {
          final callInfo = CallInfo(
            callId: data['callId'] as String? ?? '',
            peerDeviceId: msg.fromDeviceId ?? widget.contactId,
            peerName: data['callerName'] as String? ?? 'مكالمة واردة',
            isVideo: data['isVideo'] as bool? ?? false,
            state: CallState.incomingRinging,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                callInfo: callInfo,
                offerSdp: data['sdp'] as String?,
              ),
            ),
          );
        }
      }

      if (msg.sessionId != widget.sessionId) return;

      switch (msg.type) {
        case SignalingMessageType.offer:
          final sdp = msg.data?['sdp'] as String?;
          if (sdp != null) {
            try {
              final answerSdp =
                  await webrtc.createAnswer(widget.sessionId, sdp);
              signaling.sendAnswer(widget.sessionId, answerSdp);
            } catch (_) {}
          }
          break;

        case SignalingMessageType.answer:
          final sdp = msg.data?['sdp'] as String?;
          if (sdp != null) {
            try {
              await webrtc.setRemoteAnswer(sdp);
            } catch (_) {}
          }
          break;

        case SignalingMessageType.iceCandidate:
          final data = msg.data;
          if (data != null) {
            try {
              await webrtc.addIceCandidate(data);
            } catch (_) {}
          }
          break;

        default:
          break;
      }
    });
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final msgSvc = ref.read(messageServiceProvider);
    await msgSvc.sendTextMessage(
      conversationId: widget.conversationId,
      sessionId: widget.sessionId,
      text: text,
      targetDeviceId: _contact?.deviceId,
    );
    _loadMessages();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final msgSvc = ref.read(messageServiceProvider);
      await msgSvc.sendMediaMessage(
        conversationId: widget.conversationId,
        sessionId: widget.sessionId,
        messageType: 'image',
        file: file,
        targetDeviceId: _contact?.deviceId ?? widget.contactId,
        fileName: picked.name,
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الصورة: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final msgSvc = ref.read(messageServiceProvider);
      await msgSvc.sendMediaMessage(
        conversationId: widget.conversationId,
        sessionId: widget.sessionId,
        messageType: 'file',
        file: file,
        targetDeviceId: _contact?.deviceId ?? widget.contactId,
        fileName: result.files.single.name,
      );
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الملف: $e')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          final file = File(path);
          final msgSvc = ref.read(messageServiceProvider);
          await msgSvc.sendMediaMessage(
            conversationId: widget.conversationId,
            sessionId: widget.sessionId,
            messageType: 'audio',
            file: file,
            targetDeviceId: _contact?.deviceId ?? widget.contactId,
            fileName: 'voice_note.m4a',
          );
          _loadMessages();
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          _recordingPath =
              '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: _recordingPath!,
          );
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التسجيل الصوتي: $e')),
        );
      }
    }
  }

  Future<void> _startVoiceCall({required bool isVideo}) async {
    final callSvc = ref.read(callServiceProvider);
    final identity = ref.read(identityServiceProvider);
    final peerName = _contact?.displayName ?? 'مستخدم';
    final targetDevice = _contact?.deviceId ?? widget.contactId;

    final callInfo = CallInfo(
      callId: 'call_${DateTime.now().millisecondsSinceEpoch}',
      peerDeviceId: targetDevice,
      peerName: peerName,
      isVideo: isVideo,
      state: CallState.outgoingRinging,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CallScreen(callInfo: callInfo)),
    );

    await callSvc.startCall(
      targetDeviceId: targetDevice,
      peerName: peerName,
      isVideo: isVideo,
      localName: identity.displayName,
    );
  }

  void _onTyping(String v) {
    if (v.isNotEmpty) {
      ref.read(messageServiceProvider).sendTypingIndicator(true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (_contact?.displayName ?? '?').isNotEmpty
                    ? (_contact?.displayName ?? '?')[0].toUpperCase()
                    : '?',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_contact?.displayName ?? 'محادثة',
                    style: theme.textTheme.titleMedium),
                _ConnectionStatusBadge(state: _connState),
              ],
            ),
          ],
        ),
        actions: [
          // Voice Call Button
          IconButton(
            icon: const Icon(Icons.phone_rounded),
            onPressed: () => _startVoiceCall(isVideo: false),
            tooltip: 'مكالمة صوتية',
          ),
          // Video Call Button
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () => _startVoiceCall(isVideo: true),
            tooltip: 'مكالمة فيديو',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              final db = ref.read(databaseProvider);
              if (val == 'block' && _contact != null) {
                await db.setContactBlocked(_contact!.id, true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حظر ${_contact!.displayName}')),
                  );
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('حظر المستخدم'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('لا توجد رسائل بعد.\nقل مرحباً! 👋',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) =>
                        _MessageBubble(message: _messages[i]),
                  ),
          ),
          if (_peerTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text('يكتب الآن...',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          _MessageInputBar(
            controller: _textController,
            isRecording: _isRecording,
            onSend: _sendMessage,
            onTyping: _onTyping,
            onPickImage: () => _pickImage(ImageSource.gallery),
            onTakePhoto: () => _pickImage(ImageSource.camera),
            onPickFile: _pickFile,
            onToggleRecording: _toggleRecording,
          ),
        ],
      ),
    );
  }
}

// ── Connection Status Badge ──────────────────────────────────────────────────

class _ConnectionStatusBadge extends StatelessWidget {
  final PeerConnectionState state;
  const _ConnectionStatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      PeerConnectionState.connected => ('مباشر P2P', Colors.greenAccent),
      PeerConnectionState.connecting => ('جاري الاتصال...', Colors.orange),
      PeerConnectionState.reconnecting => ('إعادة اتصال...', Colors.orange),
      _ => ('عبر السيرفر', Colors.lightBlue),
    };
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOut = message.isOutgoing;
    final status = message.status;

    Map<String, dynamic> payload = {};
    try {
      final raw = utf8.decode(base64Url.decode(message.encryptedPayload));
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}

    final type = message.messageType;
    final text = payload['text'] as String? ?? '';
    final base64Data = payload['base64Data'] as String?;
    final fileName = payload['fileName'] as String? ?? 'ملف';

    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isOut
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOut ? 18 : 4),
            bottomRight: Radius.circular(isOut ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Render Content based on Message Type
            if (type == 'image' && base64Data != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: Image.memory(
                    base64Decode(base64Data),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else if (type == 'audio' && base64Data != null) ...[
              _AudioPlayerBubble(
                base64Audio: base64Data,
                isOut: isOut,
              ),
              const SizedBox(height: 4),
            ] else if (type == 'file') ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_rounded,
                      color: isOut ? Colors.white : theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        color: isOut ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ] else ...[
              Text(
                text.isNotEmpty ? text : '🔒 رسالة مشفرة',
                style: TextStyle(
                    color: isOut ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
            ],

            // Timestamp and Status Icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                      fontSize: 10,
                      color: isOut ? Colors.white70 : Colors.grey),
                ),
                if (isOut) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'sending' => (Icons.access_time_rounded, Colors.white54),
      'sent' => (Icons.check_rounded, Colors.white70),
      'delivered' => (Icons.done_all_rounded, Colors.white70),
      'read' => (Icons.done_all_rounded, Colors.lightBlueAccent),
      _ => (Icons.access_time_rounded, Colors.white54),
    };
    return Icon(icon, size: 14, color: color);
  }
}

// ── Audio Player Widget ──────────────────────────────────────────────────────

class _AudioPlayerBubble extends StatefulWidget {
  final String base64Audio;
  final bool isOut;

  const _AudioPlayerBubble({required this.base64Audio, required this.isOut});

  @override
  State<_AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<_AudioPlayerBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      final bytes = base64Decode(widget.base64Audio);
      await _player.play(BytesSource(bytes));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOut ? Colors.white : Colors.blue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: color, size: 36),
          onPressed: _togglePlay,
        ),
        const SizedBox(width: 8),
        Text('مقطع صوتي 🎤',
            style: TextStyle(color: widget.isOut ? Colors.white : Colors.black87)),
      ],
    );
  }
}

// ── Message Input Bar ────────────────────────────────────────────────────────

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onSend;
  final ValueChanged<String> onTyping;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFile;
  final VoidCallback onToggleRecording;

  const _MessageInputBar({
    required this.controller,
    required this.isRecording,
    required this.onSend,
    required this.onTyping,
    required this.onPickImage,
    required this.onTakePhoto,
    required this.onPickFile,
    required this.onToggleRecording,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          // Attachment Options
          PopupMenuButton<String>(
            icon: const Icon(Icons.attach_file_rounded, color: Colors.grey),
            onSelected: (val) {
              if (val == 'gallery') onPickImage();
              if (val == 'camera') onTakePhoto();
              if (val == 'file') onPickFile();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'gallery',
                child: Row(children: [
                  Icon(Icons.photo_library_rounded, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('المعرض'),
                ]),
              ),
              const PopupMenuItem(
                value: 'camera',
                child: Row(children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('الكاميرا'),
                ]),
              ),
              const PopupMenuItem(
                value: 'file',
                child: Row(children: [
                  Icon(Icons.insert_drive_file_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('ملف / مستند'),
                ]),
              ),
            ],
          ),
          Expanded(
            child: isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.mic_rounded, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('جاري التسجيل... اضغط مرة أخرى للإرسال',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : TextField(
                    controller: controller,
                    onChanged: onTyping,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          // Voice Note Record Button
          IconButton(
            icon: Icon(
              isRecording ? Icons.send_rounded : Icons.mic_rounded,
              color: isRecording ? Colors.redAccent : Colors.grey,
            ),
            onPressed: onToggleRecording,
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (ctx, val, _) {
              if (val.text.trim().isEmpty || isRecording) {
                return const SizedBox.shrink();
              }
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: onSend,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
