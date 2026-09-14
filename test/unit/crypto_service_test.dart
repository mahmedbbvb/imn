import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:imn/core/crypto/crypto_service.dart';

void main() {
  late CryptoService crypto;

  setUp(() => crypto = CryptoService());

  group('Ed25519 Identity Keys', () {
    test('generates a key pair', () async {
      final kp = await crypto.generateIdentityKeyPair();
      final pub = await crypto.extractPublicKeyBytes(kp);
      expect(pub.length, 32);
    });

    test('signs and verifies data', () async {
      final kp = await crypto.generateIdentityKeyPair();
      final data = Uint8List.fromList('hello imn'.codeUnits);
      final sig = await crypto.sign(data, kp);
      final pub = await crypto.extractPublicKeyBytes(kp);
      final ok = await crypto.verify(
          data: data, signature: sig, publicKeyBytes: pub);
      expect(ok, isTrue);
    });

    test('rejects tampered data', () async {
      final kp = await crypto.generateIdentityKeyPair();
      final data = Uint8List.fromList('hello'.codeUnits);
      final sig = await crypto.sign(data, kp);
      final pub = await crypto.extractPublicKeyBytes(kp);
      final tampered = Uint8List.fromList('world'.codeUnits);
      final ok = await crypto.verify(
          data: tampered, signature: sig, publicKeyBytes: pub);
      expect(ok, isFalse);
    });

    test('derives stable device ID', () async {
      final kp = await crypto.generateIdentityKeyPair();
      final id1 = await crypto.deriveDeviceId(kp);
      final id2 = await crypto.deriveDeviceId(kp);
      expect(id1, equals(id2));
      expect(id1.length, 36); // UUID format (8-4-4-4-12)
    });
  });

  group('X25519 Key Exchange', () {
    test('both parties derive same shared secret', () async {
      final kpA = await crypto.generateEphemeralKeyPair();
      final kpB = await crypto.generateEphemeralKeyPair();
      final pubA = await crypto.extractX25519PublicKeyBytes(kpA);
      final pubB = await crypto.extractX25519PublicKeyBytes(kpB);

      final sharedA = await crypto.deriveSharedSecret(
          ourKeyPair: kpA, peerPublicKeyBytes: pubB);
      final sharedB = await crypto.deriveSharedSecret(
          ourKeyPair: kpB, peerPublicKeyBytes: pubA);

      expect(sharedA, equals(sharedB));
    });

    test('derived session keys match', () async {
      final kpA = await crypto.generateEphemeralKeyPair();
      final kpB = await crypto.generateEphemeralKeyPair();
      final pubA = await crypto.extractX25519PublicKeyBytes(kpA);
      final pubB = await crypto.extractX25519PublicKeyBytes(kpB);

      final sharedA = await crypto.deriveSharedSecret(
          ourKeyPair: kpA, peerPublicKeyBytes: pubB);
      final sharedB = await crypto.deriveSharedSecret(
          ourKeyPair: kpB, peerPublicKeyBytes: pubA);

      const sessionId = 'test-session-123';
      final salt = Uint8List.fromList(sessionId.codeUnits);

      final keyA = await crypto.deriveSessionKey(
          sharedSecret: sharedA, salt: salt);
      final keyB = await crypto.deriveSessionKey(
          sharedSecret: sharedB, salt: salt);

      expect(keyA, equals(keyB));
      expect(keyA.length, 32);
    });
  });

  group('ChaCha20-Poly1305 Encryption', () {
    test('encrypts and decrypts correctly', () async {
      final kp = await crypto.generateEphemeralKeyPair();
      final pub = await crypto.extractX25519PublicKeyBytes(kp);
      final shared = await crypto.deriveSharedSecret(
          ourKeyPair: kp, peerPublicKeyBytes: pub);
      final salt = Uint8List.fromList('test'.codeUnits);
      final key = await crypto.deriveSessionKey(
          sharedSecret: shared, salt: salt);

      final plaintext =
          Uint8List.fromList('Secret message 🔒'.codeUnits);
      final encrypted = await crypto.encrypt(
          plaintext: plaintext, keyBytes: key);
      final decrypted = await crypto.decrypt(
          encryptedData: encrypted, keyBytes: key);

      expect(decrypted, equals(plaintext));
    });

    test('different messages produce different ciphertexts', () async {
      final key = Uint8List(32)..fillRange(0, 32, 0x42);
      final msg1 = Uint8List.fromList('hello'.codeUnits);
      final msg2 = Uint8List.fromList('hello'.codeUnits);

      final enc1 = await crypto.encrypt(plaintext: msg1, keyBytes: key);
      final enc2 = await crypto.encrypt(plaintext: msg2, keyBytes: key);

      // Nonces should differ so ciphertexts are different
      expect(enc1, isNot(equals(enc2)));
    });

    test('rejects wrong key', () async {
      final key1 = Uint8List(32)..fillRange(0, 32, 0x01);
      final key2 = Uint8List(32)..fillRange(0, 32, 0x02);
      final plain = Uint8List.fromList('test'.codeUnits);

      final encrypted = await crypto.encrypt(
          plaintext: plain, keyBytes: key1);

      expect(
        () => crypto.decrypt(encryptedData: encrypted, keyBytes: key2),
        throwsA(isA<Exception>()),
      );
    });

    test('encrypts large payloads (file simulation)', () async {
      final key = Uint8List(32)..fillRange(0, 32, 0x77);
      final large = Uint8List(64 * 1024); // 64 KB
      for (int i = 0; i < large.length; i++) large[i] = i % 256;

      final enc = await crypto.encrypt(plaintext: large, keyBytes: key);
      final dec = await crypto.decrypt(encryptedData: enc, keyBytes: key);

      expect(dec, equals(large));
    });
  });
}
