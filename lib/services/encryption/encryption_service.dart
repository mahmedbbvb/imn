import 'dart:convert';
import 'dart:typed_data';
import '../../core/crypto/crypto_service.dart';
import '../../core/utils/app_logger.dart';

/// Manages the E2E encryption session for a single conversation.
class EncryptionSession {
  final String sessionId;
  final String contactDeviceId;
  Uint8List _sessionKey;
  int _messageCounter = 0;
  DateTime _keyCreatedAt;
  static const _keyRotationInterval = Duration(hours: 24);

  EncryptionSession({
    required this.sessionId,
    required this.contactDeviceId,
    required Uint8List sessionKey,
  })  : _sessionKey = sessionKey,
        _keyCreatedAt = DateTime.now();

  bool get needsKeyRotation =>
      DateTime.now().difference(_keyCreatedAt) > _keyRotationInterval;

  void rotateKey(Uint8List newKey) {
    _sessionKey = newKey;
    _keyCreatedAt = DateTime.now();
    _messageCounter = 0;
    appLogger.i('Key rotated for session $sessionId');
  }

  Uint8List get currentKey => _sessionKey;
  int get nextCounter => ++_messageCounter;
}

/// Handles all E2E encryption operations for the chat.
class EncryptionService {
  final CryptoService _crypto;
  final Map<String, EncryptionSession> _sessions = {};

  EncryptionService({required CryptoService crypto}) : _crypto = crypto;

  // ── Session Management ───────────────────────────────────────

  void addSession(EncryptionSession session) {
    _sessions[session.sessionId] = session;
    appLogger.i('Encryption session added: ${session.sessionId}');
  }

  EncryptionSession? getSession(String sessionId) => _sessions[sessionId];
  Map<String, EncryptionSession> get allSessions => Map.unmodifiable(_sessions);

  void removeSession(String sessionId) {
    _sessions.remove(sessionId);
  }

  // ── Encrypt / Decrypt ────────────────────────────────────────

  Future<Uint8List> encryptMessage({
    required String sessionId,
    required Uint8List plaintext,
    Uint8List? additionalData,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) throw StateError('No session: $sessionId');
    return _crypto.encrypt(
      plaintext: plaintext,
      keyBytes: session.currentKey,
      aad: additionalData,
    );
  }

  Future<Uint8List> decryptMessage({
    required String sessionId,
    required Uint8List encryptedData,
    Uint8List? additionalData,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) throw StateError('No session: $sessionId');
    return _crypto.decrypt(
      encryptedData: encryptedData,
      keyBytes: session.currentKey,
      aad: additionalData,
    );
  }

  Future<Uint8List> encryptChunk({
    required String sessionId,
    required Uint8List chunk,
    required int chunkIndex,
    required String fileId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) throw StateError('No session: $sessionId');
    final aad = Uint8List.fromList(utf8.encode('$fileId:$chunkIndex'));
    return _crypto.encrypt(
      plaintext: chunk,
      keyBytes: session.currentKey,
      aad: aad,
    );
  }

  Future<void> rotateKey(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) return;
    final oldKey = session.currentKey;
    final counter = session.nextCounter;
    final salt = Uint8List.fromList(
        utf8.encode('$sessionId:rotation:$counter'));
    final newKey = await _crypto.deriveSessionKey(
      sharedSecret: oldKey,
      salt: salt,
      info: 'imn-key-rotation-v1',
    );
    session.rotateKey(newKey);
  }
}
