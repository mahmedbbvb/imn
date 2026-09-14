import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../services/database/app_database.dart';
import '../../services/signaling/signaling_service.dart';
import '../../services/webrtc/webrtc_service.dart';

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
  List<Message> _messages = [];
  bool _peerTyping = false;
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
    _loadContact();
    _listenToWebRTC();
    _listenToSignaling();
    _flushPending();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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
        _typingTimer =
            Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _peerTyping = false);
        });
      }
      if (msg.type == 'msg') _loadMessages();
    });
  }

  Future<void> _flushPending() async {
    final msgSvc = ref.read(messageServiceProvider);
    await msgSvc.flushPendingMessages(widget.conversationId);
  }

  /// Listens for WebRTC signaling messages (offer/answer/ICE) related to
  /// this conversation's sessionId.
  void _listenToSignaling() {
    final signaling = ref.read(signalingServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);

    _signalSub = signaling.messages?.listen((msg) async {
      if (msg.sessionId != widget.sessionId) return;

      switch (msg.type) {
        case SignalingMessageType.offer:
          final sdp = msg.data?['sdp'] as String?;
          if (sdp != null) {
            try {
              final answerSdp =
                  await webrtc.createAnswer(widget.sessionId, sdp);
              signaling.sendAnswer(widget.sessionId, answerSdp);
            } catch (e) {
              // ignore
            }
          }
          break;

        case SignalingMessageType.answer:
          final sdp = msg.data?['sdp'] as String?;
          if (sdp != null) {
            try {
              await webrtc.setRemoteAnswer(sdp);
            } catch (e) {
              // ignore
            }
          }
          break;

        case SignalingMessageType.iceCandidate:
          final data = msg.data;
          if (data != null) {
            try {
              await webrtc.addIceCandidate(data);
            } catch (e) {
              // ignore
            }
          }
          break;

        default:
          break;
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final msgSvc = ref.read(messageServiceProvider);
    await msgSvc.sendTextMessage(
      conversationId: widget.conversationId,
      sessionId: widget.sessionId,
      text: text,
    );
    _loadMessages();
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
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
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
                Text(_contact?.displayName ?? 'Loading...',
                    style: theme.textTheme.titleMedium),
                _ConnectionStatusBadge(state: _connState),
              ],
            ),
          ],
        ),
        actions: [
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
                    child: Text('No messages yet.\nSay hello! 👋',
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
                  _TypingIndicator(),
                  const SizedBox(width: 8),
                  Text('typing...',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          _MessageInput(
            controller: _textController,
            onSend: _sendMessage,
            onTyping: _onTyping,
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
      PeerConnectionState.connected => ('Connected', Colors.greenAccent),
      PeerConnectionState.connecting => ('Connecting...', Colors.orange),
      PeerConnectionState.reconnecting => ('Reconnecting...', Colors.orange),
      PeerConnectionState.failed => ('Offline', Colors.red),
      _ => ('Offline', Colors.grey),
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

    // Decode the encrypted payload preview (plaintext stored separately)
    String text = '🔒 Encrypted';
    try {
      final raw = utf8.decode(base64Url.decode(message.encryptedPayload));
      final json = jsonDecode(raw) as Map<String, dynamic>;
      text = json['text'] as String? ?? text;
    } catch (_) {}

    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(
                    color: isOut
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                      fontSize: 10,
                      color: isOut
                          ? Colors.white70
                          : Colors.grey),
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

// ── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message Input Bar ────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onTyping;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onTyping,
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
          IconButton(
            icon: const Icon(Icons.attach_file_rounded),
            onPressed: () {},
            color: Colors.grey,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onTyping,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message...',
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
          IconButton(
            icon: Icon(Icons.mic_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (ctx, val, _) {
              if (val.text.trim().isEmpty) return const SizedBox.shrink();
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
