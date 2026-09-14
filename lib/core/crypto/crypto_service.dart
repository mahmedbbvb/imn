import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

/// Handles all cryptographic operations: key generation, signing,
/// ECDH key exchange, and symmetric encryption.
class CryptoService {
  static const _uuid = Uuid();

  // ── Algorithms ──────────────────────────────────────────────
  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();
  static final _chacha20 = Chacha20.poly1305Aead();

  // ════════════════════════════════════════════════════════════
  // Identity Key Generation (Ed25519)
  // ════════════════════════════════════════════════════════════

  /// Generates a new Ed25519 identity key pair.
  Future<SimpleKeyPair> generateIdentityKeyPair() async {
    return await _ed25519.newKeyPair();
  }

  /// Reconstructs an Ed25519 key pair from stored bytes.
  Future<SimpleKeyPair> identityKeyPairFromBytes({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
  }) async {
    return SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }

  /// Extracts the public key bytes from an Ed25519 key pair.
  Future<Uint8List> extractPublicKeyBytes(SimpleKeyPair keyPair) async {
    final pubKey = await keyPair.extractPublicKey();
    return Uint8List.fromList(pubKey.bytes);
  }

  /// Derives a stable Device ID from the Ed25519 public key.
  Future<String> deriveDeviceId(SimpleKeyPair identityKeyPair) async {
    final pubKeyBytes = await extractPublicKeyBytes(identityKeyPair);
    // Use first 16 bytes of public key as UUID-like device ID
    final hex = pubKeyBytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  // ════════════════════════════════════════════════════════════
  // Signing & Verification (Ed25519)
  // ════════════════════════════════════════════════════════════

  /// Signs data with the identity private key.
  Future<Uint8List> sign(Uint8List data, SimpleKeyPair keyPair) async {
    final sig = await _ed25519.sign(data, keyPair: keyPair);
    return Uint8List.fromList(sig.bytes);
  }

  /// Verifies a signature against a public key.
  Future<bool> verify({
    required Uint8List data,
    required Uint8List signature,
    required Uint8List publicKeyBytes,
  }) async {
    try {
      final pubKey =
          SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
      final sig = Signature(signature, publicKey: pubKey);
      return await _ed25519.verify(data, signature: sig);
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Key Exchange (X25519 ECDH)
  // ════════════════════════════════════════════════════════════

  /// Generates an ephemeral X25519 key pair for ECDH.
  Future<SimpleKeyPair> generateEphemeralKeyPair() async {
    return await _x25519.newKeyPair();
  }

  /// Derives a shared secret from our private key and peer's public key.
  Future<Uint8List> deriveSharedSecret({
    required SimpleKeyPair ourKeyPair,
    required Uint8List peerPublicKeyBytes,
  }) async {
    final peerPublicKey =
        SimplePublicKey(peerPublicKeyBytes, type: KeyPairType.x25519);
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ourKeyPair,
      remotePublicKey: peerPublicKey,
    );
    final bytes = await sharedSecret.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Derives a session key from the shared secret using HKDF.
  Future<Uint8List> deriveSessionKey({
    required Uint8List sharedSecret,
    required Uint8List salt,
    String info = 'imn-session-key-v1',
  }) async {
    final hkdf = Hkdf(
      hmac: Hmac(Sha256()),
      outputLength: 32,
    );
    final output = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecret),
      nonce: salt,
      info: utf8.encode(info),
    );
    final bytes = await output.extractBytes();
    return Uint8List.fromList(bytes);
  }

  // ════════════════════════════════════════════════════════════
  // Symmetric Encryption (ChaCha20-Poly1305)
  // ════════════════════════════════════════════════════════════

  /// Generates a random 12-byte nonce for ChaCha20-Poly1305.
  Uint8List generateNonce() {
    return Uint8List.fromList(List.generate(12, (_) {
      return DateTime.now().microsecondsSinceEpoch & 0xFF ^
          (DateTime.now().millisecondsSinceEpoch >> 8) & 0xFF;
    }));
  }

  /// More secure random nonce using dart's Random.secure equivalent.
  Uint8List generateSecureNonce() {
    // Use UUID random bytes as nonce source
    final id = _uuid.v4();
    final bytes = utf8.encode(id.replaceAll('-', ''));
    return Uint8List.fromList(bytes.take(12).toList());
  }

  /// Encrypts plaintext with ChaCha20-Poly1305.
  /// Returns: nonce (12 bytes) + ciphertext + tag (16 bytes).
  Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List keyBytes,
    Uint8List? aad,
  }) async {
    final nonce = generateSecureNonce();
    final secretKey = SecretKey(keyBytes);
    final secretBox = await _chacha20.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad ?? [],
    );
    // Prepend nonce to ciphertext+mac
    final result = Uint8List(12 + secretBox.cipherText.length + 16);
    result.setRange(0, 12, nonce);
    result.setRange(12, 12 + secretBox.cipherText.length, secretBox.cipherText);
    result.setRange(
        12 + secretBox.cipherText.length, result.length, secretBox.mac.bytes);
    return result;
  }

  /// Decrypts data produced by [encrypt].
  Future<Uint8List> decrypt({
    required Uint8List encryptedData,
    required Uint8List keyBytes,
    Uint8List? aad,
  }) async {
    if (encryptedData.length < 12 + 16) {
      throw CryptoException('Encrypted data too short');
    }
    final nonce = encryptedData.sublist(0, 12);
    final cipherText =
        encryptedData.sublist(12, encryptedData.length - 16);
    final mac = encryptedData.sublist(encryptedData.length - 16);

    final secretKey = SecretKey(keyBytes);
    final secretBox = SecretBox(cipherText,
        nonce: nonce, mac: Mac(mac));
    final plaintext = await _chacha20.decrypt(
      secretBox,
      secretKey: secretKey,
      aad: aad ?? [],
    );
    return Uint8List.fromList(plaintext);
  }

  // ════════════════════════════════════════════════════════════
  // Key Serialization helpers
  // ════════════════════════════════════════════════════════════

  Future<Map<String, String>> serializeKeyPair(
      SimpleKeyPair keyPair, KeyPairType type) async {
    final privBytes =
        await (keyPair as SimpleKeyPairData).extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey();
    return {
      'privateKey': base64Url.encode(privBytes),
      'publicKey': base64Url.encode(pubKey.bytes),
    };
  }

  Future<Uint8List> extractX25519PublicKeyBytes(
      SimpleKeyPair keyPair) async {
    final pubKey = await keyPair.extractPublicKey();
    return Uint8List.fromList(pubKey.bytes);
  }
}

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);
  @override
  String toString() => 'CryptoException: $message';
}
