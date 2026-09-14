import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../../services/database/app_database.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/webrtc/webrtc_service.dart';

enum MessageType { text, image, file, audio, system }
enum MessageStatus { sending, sent, delivered, read }

/// Handles sending, receiving, encrypting, and storing messages.
class MessageService {
  static const _uuid = Uuid();

  final AppDatabase _db;
  final EncryptionService _encryption;
  final WebRTCService _webrtc;
  final String _localDeviceId;

  MessageService({
    required AppDatabase db,
    required EncryptionService encryption,
    required WebRTCService webrtc,
    required String localDeviceId,
  })  : _db = db,
        _encryption = encryption,
        _webrtc = webrtc,
        _localDeviceId = localDeviceId {
    _listenForIncoming();
  }

  // ── Send ─────────────────────────────────────────────────────

  Future<String> sendTextMessage({
    required String conversationId,
    required String sessionId,
    required String text,
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

    final plainBytes = Uint8List.fromList(utf8.encode(payload));
    final encrypted = await _encryption.encryptMessage(
      sessionId: sessionId,
      plaintext: plainBytes,
    );
    final encryptedB64 = base64Url.encode(encrypted);

    await _db.insertMessage(MessagesCompanion.insert(
      id: messageId,
      conversationId: conversationId,
      senderDeviceId: _localDeviceId,
      timestamp: now,
      messageType: 'text',
      encryptedPayload: encryptedB64,
      status: const Value('sending'),
      isOutgoing: true,
    ));

    if (_webrtc.isConnected) {
      try {
        await _webrtc.sendMessage(WebRTCMessage(
          type: 'msg',
          id: messageId,
          payload: encryptedB64,
        ));
        await _db.updateMessageStatus(messageId, 'sent');
      } catch (e) {
        appLogger.e('Send failed, queuing: $messageId', error: e);
        await _queuePendingMessage(conversationId, messageId, encryptedB64);
      }
    } else {
      await _queuePendingMessage(conversationId, messageId, encryptedB64);
    }

    await _db.upsertConversation(ConversationsCompanion(
      id: Value(conversationId),
      lastMessageAt: Value(now),
      lastMessagePreview: Value(
          text.length > 40 ? '${text.substring(0, 40)}...' : text),
    ));

    return messageId;
  }

  // ── Receive ──────────────────────────────────────────────────

  void _listenForIncoming() {
    _webrtc.messages.listen((msg) async {
      switch (msg.type) {
        case 'msg':
          await _handleIncomingMessage(msg);
          break;
        case 'ack':
          await _handleAck(msg);
          break;
        case 'typing':
          break;
        default:
          break;
      }
    });
  }

  Future<void> _handleIncomingMessage(WebRTCMessage msg) async {
    try {
      if (await _db.messageExists(msg.id)) {
        appLogger.d('Duplicate message ignored: ${msg.id}');
        return;
      }

      final encryptedB64 = msg.payload as String;
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
          final text = json['text'] as String? ?? '';

          await _db.insertMessage(MessagesCompanion.insert(
            id: msg.id,
            conversationId: conversationId,
            senderDeviceId: senderDeviceId,
            timestamp: timestamp,
            messageType: 'text',
            encryptedPayload: encryptedB64,
            status: const Value('delivered'),
            isOutgoing: false,
          ));

          await _db.upsertConversation(ConversationsCompanion(
            id: Value(conversationId),
            lastMessageAt: Value(timestamp),
            lastMessagePreview: Value(
                text.length > 40 ? '${text.substring(0, 40)}...' : text),
          ));

          await _webrtc.sendMessage(WebRTCMessage(
            type: 'ack',
            id: msg.id,
            payload: {'status': 'delivered'},
          ));
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

  Future<void> flushPendingMessages(String conversationId) async {
    if (!_webrtc.isConnected) return;
    final pending = await _db.getPendingMessages(conversationId);
    for (final msg in pending) {
      try {
        await _webrtc.sendMessage(WebRTCMessage(
          type: 'msg',
          id: msg.id,
          payload: msg.encryptedPayload,
        ));
        await _db.deletePendingMessage(msg.id);
        await _db.updateMessageStatus(msg.id, 'sent');
      } catch (e) {
        break;
      }
    }
  }

  // ── Receipts & Indicators ─────────────────────────────────────

  Future<void> markAsRead(String messageId) async {
    await _db.updateMessageStatus(messageId, 'read');
    try {
      await _webrtc.sendMessage(WebRTCMessage(
        type: 'ack',
        id: messageId,
        payload: {'status': 'read'},
      ));
    } catch (_) {}
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
