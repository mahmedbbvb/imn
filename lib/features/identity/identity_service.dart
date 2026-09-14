import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/utils/app_logger.dart';

/// Manages the device's cryptographic identity.
/// Keys are generated once and stored securely in Keychain/Keystore.
class IdentityService {
  static const _kDeviceId = 'imn_device_id';
  static const _kIdentityPrivKey = 'imn_identity_priv_key';
  static const _kIdentityPubKey = 'imn_identity_pub_key';
  static const _kEphPrivKey = 'imn_eph_priv_key';
  static const _kEphPubKey = 'imn_eph_pub_key';
  static const _kDisplayName = 'imn_display_name';
  static const _kAvatarPath = 'imn_avatar_path';

  final FlutterSecureStorage _secureStorage;
  final CryptoService _cryptoService;

  SimpleKeyPair? _identityKeyPair; // Ed25519
  SimpleKeyPair? _ephemeralKeyPair; // X25519
  String? _deviceId;
  String? _displayName;
  String? _avatarPath;

  IdentityService({
    required FlutterSecureStorage secureStorage,
    required CryptoService cryptoService,
  })  : _secureStorage = secureStorage,
        _cryptoService = cryptoService;

  // ── Public getters ───────────────────────────────────────────
  String get deviceId => _deviceId ?? '';
  String get displayName =>
      (_displayName != null && _displayName!.isNotEmpty) ? _displayName! : 'User';
  String? get avatarPath => _avatarPath;
  SimpleKeyPair? get identityKeyPair => _identityKeyPair;
  SimpleKeyPair? get ephemeralKeyPair => _ephemeralKeyPair;

  /// Returns the identity public key bytes (Ed25519).
  Future<Uint8List> get publicKeyBytes async {
    if (_identityKeyPair == null) throw StateError('Identity not initialized');
    return _cryptoService.extractPublicKeyBytes(_identityKeyPair!);
  }

  /// Returns the exchange public key bytes (X25519).
  Future<Uint8List> get x25519PublicKeyBytes async {
    if (_ephemeralKeyPair == null) throw StateError('Exchange key not initialized');
    return _cryptoService.extractX25519PublicKeyBytes(_ephemeralKeyPair!);
  }

  // ── Initialization ───────────────────────────────────────────

  /// Initializes identity: loads from storage or creates new.
  Future<void> initialize() async {
    try {
      final storedPrivKey = await _secureStorage.read(key: _kIdentityPrivKey);
      final storedPubKey = await _secureStorage.read(key: _kIdentityPubKey);
      final storedDeviceId = await _secureStorage.read(key: _kDeviceId);

      if (storedPrivKey != null &&
          storedPubKey != null &&
          storedDeviceId != null) {
        // Restore existing Ed25519 identity
        final privBytes = base64Url.decode(storedPrivKey);
        final pubBytes = base64Url.decode(storedPubKey);
        _identityKeyPair = await _cryptoService.identityKeyPairFromBytes(
          privateKeyBytes: privBytes,
          publicKeyBytes: pubBytes,
        );
        _deviceId = storedDeviceId;

        // Restore or create X25519 key
        final storedEphPriv = await _secureStorage.read(key: _kEphPrivKey);
        final storedEphPub = await _secureStorage.read(key: _kEphPubKey);
        if (storedEphPriv != null && storedEphPub != null) {
          _ephemeralKeyPair = SimpleKeyPairData(
            base64Url.decode(storedEphPriv),
            publicKey: SimplePublicKey(
              base64Url.decode(storedEphPub),
              type: KeyPairType.x25519,
            ),
            type: KeyPairType.x25519,
          );
        } else {
          await _generateExchangeKey();
        }

        appLogger.i('Identity loaded: $_deviceId');
      } else {
        // First run: generate new identity
        await _generateNewIdentity();
      }

      _displayName = await _secureStorage.read(key: _kDisplayName);
      _avatarPath = await _secureStorage.read(key: _kAvatarPath);
    } catch (e) {
      appLogger.e('Identity initialization failed', error: e);
      rethrow;
    }
  }

  /// Generates and stores a new cryptographic identity.
  Future<void> _generateNewIdentity() async {
    appLogger.i('Generating new device identity...');
    _identityKeyPair = await _cryptoService.generateIdentityKeyPair();
    _deviceId = await _cryptoService.deriveDeviceId(_identityKeyPair!);

    final serialized =
        await _cryptoService.serializeKeyPair(_identityKeyPair!, KeyPairType.ed25519);

    await _secureStorage.write(
        key: _kIdentityPrivKey, value: serialized['privateKey']);
    await _secureStorage.write(
        key: _kIdentityPubKey, value: serialized['publicKey']);
    await _secureStorage.write(key: _kDeviceId, value: _deviceId);

    await _generateExchangeKey();

    appLogger.i('New identity created: $_deviceId');
  }

  Future<void> _generateExchangeKey() async {
    _ephemeralKeyPair = await _cryptoService.generateEphemeralKeyPair();
    final serialized = await _cryptoService.serializeKeyPair(
        _ephemeralKeyPair!, KeyPairType.x25519);
    await _secureStorage.write(
        key: _kEphPrivKey, value: serialized['privateKey']);
    await _secureStorage.write(
        key: _kEphPubKey, value: serialized['publicKey']);
  }

  /// Updates the display name stored securely.
  Future<void> setDisplayName(String name) async {
    _displayName = name.trim();
    await _secureStorage.write(key: _kDisplayName, value: _displayName);
  }

  /// Updates the avatar file path stored securely.
  Future<void> setAvatarPath(String? path) async {
    _avatarPath = path;
    if (path != null) {
      await _secureStorage.write(key: _kAvatarPath, value: path);
    } else {
      await _secureStorage.delete(key: _kAvatarPath);
    }
  }

  /// Signs arbitrary data with the identity key.
  Future<Uint8List> sign(Uint8List data) async {
    if (_identityKeyPair == null) throw StateError('Identity not initialized');
    return _cryptoService.sign(data, _identityKeyPair!);
  }

  /// Verifies a signature from a known peer public key.
  Future<bool> verify({
    required Uint8List data,
    required Uint8List signature,
    required Uint8List peerPublicKey,
  }) async {
    return _cryptoService.verify(
      data: data,
      signature: signature,
      publicKeyBytes: peerPublicKey,
    );
  }

  /// Returns true if identity exists in storage.
  Future<bool> hasIdentity() async {
    final id = await _secureStorage.read(key: _kDeviceId);
    return id != null;
  }

  /// Completely wipes identity (for testing or factory reset).
  Future<void> deleteIdentity() async {
    await _secureStorage.deleteAll();
    _identityKeyPair = null;
    _ephemeralKeyPair = null;
    _deviceId = null;
    _displayName = null;
    _avatarPath = null;
    appLogger.w('Identity deleted');
  }
}
