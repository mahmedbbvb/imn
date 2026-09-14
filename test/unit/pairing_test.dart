import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:imn/core/crypto/crypto_service.dart';
import 'package:imn/features/identity/identity_service.dart';
import 'package:imn/features/pairing/pairing_service.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late CryptoService crypto;
  late IdentityService identityA;
  late IdentityService identityB;
  late PairingService pairingA;
  late PairingService pairingB;

  setUp(() async {
    crypto = CryptoService();

    // Simple in-memory storage mock
    final storeA = <String, String>{};
    final mockStorageA = _FakeSecureStorage(storeA);

    final storeB = <String, String>{};
    final mockStorageB = _FakeSecureStorage(storeB);

    identityA = IdentityService(
        secureStorage: mockStorageA, cryptoService: crypto);
    await identityA.initialize();

    identityB = IdentityService(
        secureStorage: mockStorageB, cryptoService: crypto);
    await identityB.initialize();

    pairingA = PairingService(crypto: crypto, identity: identityA);
    pairingB = PairingService(crypto: crypto, identity: identityB);
  });

  group('QR Pairing Protocol', () {
    test('creates a valid pairing session', () async {
      final result = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=- 123 2 IN IP4 127.0.0.1',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      expect(result.session.sessionId, isNotEmpty);
      expect(result.session.deviceId, equals(identityA.deviceId));
      expect(result.session.signature, isNotEmpty);
      expect(result.session.isExpired, isFalse);
    });

    test('validates a legitimate session signature', () async {
      final result = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=test',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      final valid = await pairingB.validateSession(result.session);
      expect(valid, isTrue);
    });

    test('rejects tampered session', () async {
      final result = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=test',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      final tampered = PairingSession(
        sessionId: result.session.sessionId,
        deviceId: result.session.deviceId,
        identityPublicKey: result.session.identityPublicKey,
        ephemeralPublicKey: result.session.ephemeralPublicKey,
        sdpOffer: 'v=0\r\no=TAMPERED',
        iceCandidates: [],
        expiresAt: result.session.expiresAt,
        signature: result.session.signature,
        signalingUrl: result.session.signalingUrl,
      );
      final valid = await pairingB.validateSession(tampered);
      expect(valid, isFalse);
    });

    test('QR encode/decode round-trip', () async {
      final result = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=test',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      final qr = pairingA.encodeToQR(result.session);
      expect(qr.startsWith('imn://pair?d='), isTrue);

      final decoded = pairingB.decodeFromQR(qr);
      expect(decoded, isNotNull);
      expect(decoded!.sessionId, equals(result.session.sessionId));
      expect(decoded.deviceId, equals(result.session.deviceId));
    });

    test('both parties derive same session key', () async {
      final resultA = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=test',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      final answerResult = await pairingB.createAnswer(
        sessionId: resultA.session.sessionId,
        sdpAnswer: 'v=0\r\no=answer',
        iceCandidates: [],
      );

      final keyA = await pairingA.deriveSessionKey(
        ourEphemeralKeyPair: resultA.ephemeralKeyPair,
        peerEphemeralPublicKeyBytes: answerResult.answer.ephemeralPublicKey,
        sessionId: resultA.session.sessionId,
      );
      final keyB = await pairingB.deriveSessionKey(
        ourEphemeralKeyPair: answerResult.ephemeralKeyPair,
        peerEphemeralPublicKeyBytes: resultA.session.ephemeralPublicKey,
        sessionId: resultA.session.sessionId,
      );

      expect(keyA, equals(keyB));
      expect(keyA.length, 32);
    });

    test('rejects expired session', () async {
      final result = await pairingA.createSession(
        sdpOffer: 'v=0\r\no=test',
        iceCandidates: [],
        signalingUrl: 'ws://localhost:8080',
      );
      final expired = PairingSession(
        sessionId: result.session.sessionId,
        deviceId: result.session.deviceId,
        identityPublicKey: result.session.identityPublicKey,
        ephemeralPublicKey: result.session.ephemeralPublicKey,
        sdpOffer: result.session.sdpOffer,
        iceCandidates: [],
        expiresAt: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
        signature: result.session.signature,
        signalingUrl: result.session.signalingUrl,
      );
      expect(expired.isExpired, isTrue);
      final valid = await pairingB.validateSession(expired);
      expect(valid, isFalse);
    });

    test('different devices have different IDs', () {
      expect(identityA.deviceId, isNot(equals(identityB.deviceId)));
    });
  });
}

/// Simple fake secure storage for tests (no platform dependencies).
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store;
  _FakeSecureStorage(this._store);

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.clear();
}
