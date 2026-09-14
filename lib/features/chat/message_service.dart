import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../../services/database/app_database.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/signaling/signaling_service.dart';
import '../../services/webrtc/webrtc_service.dart';

enum MessageType { text, image, file, audio, system }
enum MessageStatus { sending, sent, delivered, read }

/// Handles sending, receiving, encrypting, and storing messages.
/// Supports both WebRTC P2P DataChannel and Encrypted Signaling Relay fallback.
class MessageService {
  static const _uuid = Uuid();

  final AppDatabase _db;
  final EncryptionService _encryption;
  final WebRTCService _webrtc;
  final SignalingService _signaling;
  final String _localDeviceId;

  MessageService({
    required AppDatabase db,
    required EncryptionService encryption,
    required WebRTCService webrtc,
    required SignalingService signaling,
    required String localDeviceId,
  })  : _db = db,
        _encryption = encryption,
        _webrtc = webrtc,
        _signaling = signaling,
        _localDeviceId = localDeviceId {
    _listenForIncoming();
  }

  // ── Send Text ────────────────────────────────────────────────

  Future<String> sendTextMessage({
    required String conversationId,
    required String sessionId,
    required String text,
    String? targetDeviceId,
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode({
      'messageId': messageId,
      'conversationId': conversationId,
      'senderDevice': _localDeviceId,
      'timestamp': now,
      'messageType': 'text',
      'text': text,
    });

    return _dispatchPayload(
      messageId: messageId,
      conversationId: conversationId,
      sessionId: sessionId,
      messageType: 'text',
      preview: text,
      jsonPayload: payload,
      targetDeviceId: targetDeviceId,
    );
  }

  // ── Send Media (Image, File, Audio) ──────────────────────────

  Future<String> sendMediaMessage({
    required String conversationId,
    required String sessionId,
    required String messageType, // 'image' | 'file' | 'audio'
    required File file,
    required String targetDeviceId,
    String? fileName,
    int? durationMs,
  }) async {
    final messageId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final bytes = await file.readAsBytes();
    final base64Content = base64Encode(bytes);
    final name = fileName ?? file.path.split(Platform.pathSeparator).last;
    final size = bytes.length;

    final payloadMap = {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderDevice': _localDeviceId,
      'timestamp': now,
      'messageType': messageType,
      'fileName': name,
      'fileSize': size,
      'base64Data': base64Content,
      if (durationMs != null) 'durationMs': durationMs,
    };

    final preview = switch (messageType) {
      'image' => '📷 صورة',
      'audio' => '🎤 مقطع صوتي',
      _ => '📁 ملف: $name',
    };

    return _dispatchPayload(
      messageId: messageId,
      conversationId: conversationId,
      sessionId: sessionId,
      messageType: messageType,
      preview: preview,
      jsonPayload: jsonEncode(payloadMap),
      targetDeviceId: targetDeviceId,
    );
  }

  // ── Internal Dispatch (P2P + Signaling Fallback) ─────────────

  Future<String> _dispatchPayload({
    required String messageId,
    required String conversationId,
    required String sessionId,
    required String messageType,
    required String preview,
    required String jsonPayload,
    String? targetDeviceId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final plainBytes = Uint8List.fromList(utf8.encode(jsonPayload));

    final encrypted = await _encryption.encryptMessage(
      sessionId: sessionId,
      plaintext: plainBytes,
    );
    final encryptedB64 = base64Url.encode(encrypted);

    // 1. Store locally in database
    await _db.insertMessage(MessagesCompanion.insert(
      id: messageId,
      conversationId: conversationId,
      senderDeviceId: _localDeviceId,
      timestamp: now,
      messageType: messageType,
      encryptedPayload: encryptedB64,
      status: const Value('sending'),
      isOutgoing: true,
    ));

    bool sentSuccessfully = false;

    // 2. Try WebRTC DataChannel first
    if (_webrtc.isConnected) {
      try {
        await _webrtc.sendMessage(WebRTCMessage(
          type: 'msg',
          id: messageId,
          payload: encryptedB64,
        ));
        await _db.updateMessageStatus(messageId, 'sent');
        sentSuccessfully = true;
      } catch (e) {
        appLogger.w('WebRTC send failed, trying signaling fallback', error: e);
      }
    }

    // 3. Fallback to Encrypted Signaling Relay if WebRTC failed or not connected
    if (!sentSuccessfully && targetDeviceId != null && _signaling.isConnected) {
      try {
        _signaling.sendChatMessage(targetDeviceId, {
          'messageId': messageId,
          'encryptedPayload': encryptedB64,
        });
        await _db.updateMessageStatus(messageId, 'sent');
        sentSuccessfully = true;
      } catch (e) {
        appLogger.e('Signaling relay send failed', error: e);
      }
    }

    // 4. Queue for background retry if offline
    if (!sentSuccessfully) {
      await _queuePendingMessage(conversationId, messageId, encryptedB64);
    }

    // Update conversation preview
    await _db.upsertConversation(ConversationsCompanion(
      id: Value(conversationId),
      lastMessageAt: Value(now),
      lastMessagePreview: Value(
          preview.length > 40 ? '${preview.substring(0, 40)}...' : preview),
    ));

    return messageId;
  }

  // ── Receive Streams ──────────────────────────────────────────

  void _listenForIncoming() {
    // 1. WebRTC Incoming
    _webrtc.messages.listen((msg) async {
      switch (msg.type) {
        case 'msg':
          await _processIncomingEncryptedPayload(
              msg.id, msg.payload as String);
          break;
        case 'ack':
          await _handleAck(msg);
          break;
        default:
          break;
      }
    });

    // 2. Signaling Relay Incoming
    _signaling.messages?.listen((msg) async {
      if (msg.type == SignalingMessageType.chatMessage) {
        final data = msg.data;
        if (data != null) {
          final messageId = data['messageId'] as String? ?? _uuid.v4();
          final encryptedB64 = data['encryptedPayload'] as String?;
          if (encryptedB64 != null) {
            await _processIncomingEncryptedPayload(messageId, encryptedB64);
          }
        }
      } else if (msg.type == SignalingMessageType.chatMessageStatus) {
        final data = msg.data;
        if (data != null) {
          final messageId = data['messageId'] as String?;
          final status = data['status'] as String?;
          if (messageId != null && status == 'delivered') {
            await _db.updateMessageStatus(messageId, 'delivered');
          }
        }
      }
    });
  }

  Future<void> _processIncomingEncryptedPayload(
      String messageId, String encryptedB64) async {
    try {
      if (await _db.messageExists(messageId)) {
        appLogger.d('Duplicate message ignored: $messageId');
        return;
      }

      final encrypted = base64Url.decode(encryptedB64);

      for (final sessionId in _encryption.allSessions.keys) {
        try {
          final plain = await _encryption.decryptMessage(
            sessionId: sessionId,
            encryptedData: encrypted,
          );
          final json =
              jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;

          final conversationId = json['conversationId'] as String;
          final senderDeviceId = json['senderDevice'] as String;
          final timestamp = json['timestamp'] as int;
          final messageType = json['messageType'] as String? ?? 'text';
          final text = json['text'] as String? ?? '';
          final fileName = json['fileName'] as String?;

          final preview = switch (messageType) {
            'image' => '📷 صورة',
            'audio' => '🎤 مقطع صوتي',
            'file' => '📁 ملف: ${fileName ?? ""}',
            _ => text,
          };

          await _db.insertMessage(MessagesCompanion.insert(
            id: messageId,
            conversationId: conversationId,
            senderDeviceId: senderDeviceId,
            timestamp: timestamp,
            messageType: messageType,
            encryptedPayload: encryptedB64,
            status: const Value('delivered'),
            isOutgoing: false,
          ));

          await _db.upsertConversation(ConversationsCompanion(
            id: Value(conversationId),
            lastMessageAt: Value(timestamp),
            lastMessagePreview: Value(
                preview.length > 40 ? '${preview.substring(0, 40)}...' : preview),
          ));

          if (_webrtc.isConnected) {
            await _webrtc.sendMessage(WebRTCMessage(
              type: 'ack',
              id: messageId,
              payload: {'status': 'delivered'},
            ));
          }
          break;
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      appLogger.e('Handle incoming message failed', error: e);
    }
  }

  Future<void> _handleAck(WebRTCMessage msg) async {
    final payload = msg.payload as Map<String, dynamic>;
    final status = payload['status'] as String? ?? 'delivered';
    await _db.updateMessageStatus(msg.id, status);
  }

  // ── Pending Queue ────────────────────────────────────────────

  Future<void> _queuePendingMessage(
      String conversationId, String messageId, String encryptedB64) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insertPendingMessage(PendingMessagesCompanion.insert(
      id: messageId,
      conversationId: conversationId,
      encryptedPayload: encryptedB64,
      createdAt: now,
      nextRetryAt: now,
    ));
  }

  Future<void> flushPendingMessages(
      String conversationId, String? targetDeviceId) async {
    final pending = await _db.getPendingMessages(conversationId);
    if (pending.isEmpty) return;

    for (final msg in pending) {
      bool sent = false;
      if (_webrtc.isConnected) {
        try {
          await _webrtc.sendMessage(WebRTCMessage(
            type: 'msg',
            id: msg.id,
            payload: msg.encryptedPayload,
          ));
          sent = true;
        } catch (_) {}
      }
      if (!sent && targetDeviceId != null && _signaling.isConnected) {
        try {
          _signaling.sendChatMessage(targetDeviceId, {
            'messageId': msg.id,
            'encryptedPayload': msg.encryptedPayload,
          });
          sent = true;
        } catch (_) {}
      }

      if (sent) {
        await _db.deletePendingMessage(msg.id);
        await _db.updateMessageStatus(msg.id, 'sent');
      }
    }
  }

  // ── Receipts & Indicators ─────────────────────────────────────

  Future<void> markAsRead(String messageId) async {
    await _db.updateMessageStatus(messageId, 'read');
    if (_webrtc.isConnected) {
      try {
        await _webrtc.sendMessage(WebRTCMessage(
          type: 'ack',
          id: messageId,
          payload: {'status': 'read'},
        ));
      } catch (_) {}
    }
  }

  Future<void> sendTypingIndicator(bool isTyping) async {
    if (!_webrtc.isConnected) return;
    try {
      await _webrtc.sendMessage(WebRTCMessage(
        type: 'typing',
        id: _uuid.v4(),
        payload: {'typing': isTyping},
      ));
    } catch (_) {}
  }
}
