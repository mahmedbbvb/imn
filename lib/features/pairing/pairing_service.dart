import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../core/crypto/crypto_service.dart';
import '../../features/identity/identity_service.dart';

/// Represents a pairing session embedded in a QR code.
class PairingSession {
  final String sessionId;
  final String deviceId;
  final Uint8List identityPublicKey; // Ed25519
  final Uint8List ephemeralPublicKey; // X25519
  final String sdpOffer;
  final List<String> iceCandidates;
  final int expiresAt; // Unix timestamp ms
  final Uint8List signature;
  final String signalingUrl;

  PairingSession({
    required this.sessionId,
    required this.deviceId,
    required this.identityPublicKey,
    required this.ephemeralPublicKey,
    required this.sdpOffer,
    required this.iceCandidates,
    required this.expiresAt,
    required this.signature,
    required this.signalingUrl,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toJson() => {
        'sid': sessionId,
        'did': deviceId,
        'ipk': base64Url.encode(identityPublicKey),
        'epk': base64Url.encode(ephemeralPublicKey),
        'sdp': sdpOffer,
        'ice': iceCandidates,
        'exp': expiresAt,
        'sig': base64Url.encode(signature),
        'url': signalingUrl,
      };

  factory PairingSession.fromJson(Map<String, dynamic> json) {
    return PairingSession(
      sessionId: json['sid'] as String,
      deviceId: json['did'] as String,
      identityPublicKey: base64Url.decode(json['ipk'] as String),
      ephemeralPublicKey: base64Url.decode(json['epk'] as String),
      sdpOffer: json['sdp'] as String,
      iceCandidates: (json['ice'] as List).cast<String>(),
      expiresAt: json['exp'] as int,
      signature: base64Url.decode(json['sig'] as String),
      signalingUrl: json['url'] as String,
    );
  }

  /// The bytes that were signed (everything except the signature field).
  Uint8List get signedBytes {
    final data = {
      'sid': sessionId,
      'did': deviceId,
      'ipk': base64Url.encode(identityPublicKey),
      'epk': base64Url.encode(ephemeralPublicKey),
      'sdp': sdpOffer,
      'exp': expiresAt,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }
}

/// Represents the answer sent back after scanning a QR.
class PairingAnswer {
  final String sessionId;
  final String deviceId;
  final Uint8List identityPublicKey;
  final Uint8List ephemeralPublicKey;
  final String sdpAnswer;
  final List<String> iceCandidates;
  final Uint8List signature;

  PairingAnswer({
    required this.sessionId,
    required this.deviceId,
    required this.identityPublicKey,
    required this.ephemeralPublicKey,
    required this.sdpAnswer,
    required this.iceCandidates,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'sid': sessionId,
        'did': deviceId,
        'ipk': base64Url.encode(identityPublicKey),
        'epk': base64Url.encode(ephemeralPublicKey),
        'sdp': sdpAnswer,
        'ice': iceCandidates,
        'sig': base64Url.encode(signature),
      };

  factory PairingAnswer.fromJson(Map<String, dynamic> json) {
    return PairingAnswer(
      sessionId: json['sid'] as String,
      deviceId: json['did'] as String,
      identityPublicKey: base64Url.decode(json['ipk'] as String),
      ephemeralPublicKey: base64Url.decode(json['epk'] as String),
      sdpAnswer: json['sdp'] as String,
      iceCandidates: (json['ice'] as List).cast<String>(),
      signature: base64Url.decode(json['sig'] as String),
    );
  }

  Uint8List get signedBytes {
    final data = {
      'sid': sessionId,
      'did': deviceId,
      'ipk': base64Url.encode(identityPublicKey),
      'epk': base64Url.encode(ephemeralPublicKey),
      'sdp': sdpAnswer,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }
}

/// Creates and validates pairing sessions.
class PairingService {
  static const _sessionTtlMs = 5 * 60 * 1000; // 5 minutes
  static const _uuid = Uuid();

  final CryptoService _crypto;
  final IdentityService _identity;

  PairingService({
    required CryptoService crypto,
    required IdentityService identity,
  })  : _crypto = crypto,
        _identity = identity;

  /// Creates a new pairing session (for QR generation).
  Future<({PairingSession session, dynamic ephemeralKeyPair})>
      createSession({
    required String sdpOffer,
    required List<String> iceCandidates,
    required String signalingUrl,
  }) async {
    final ephemeralKeyPair = await _crypto.generateEphemeralKeyPair();
    final ephemeralPubKey =
        await _crypto.extractX25519PublicKeyBytes(ephemeralKeyPair);
    final identityPubKey = await _identity.publicKeyBytes;
    final sessionId = _uuid.v4();
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + _sessionTtlMs;

    // Build pre-signature data
    final preSession = PairingSession(
      sessionId: sessionId,
      deviceId: _identity.deviceId,
      identityPublicKey: identityPubKey,
      ephemeralPublicKey: ephemeralPubKey,
      sdpOffer: sdpOffer,
      iceCandidates: iceCandidates,
      expiresAt: expiresAt,
      signature: Uint8List(0),
      signalingUrl: signalingUrl,
    );

    final signature = await _identity.sign(preSession.signedBytes);

    final session = PairingSession(
      sessionId: sessionId,
      deviceId: _identity.deviceId,
      identityPublicKey: identityPubKey,
      ephemeralPublicKey: ephemeralPubKey,
      sdpOffer: sdpOffer,
      iceCandidates: iceCandidates,
      expiresAt: expiresAt,
      signature: signature,
      signalingUrl: signalingUrl,
    );

    return (session: session, ephemeralKeyPair: ephemeralKeyPair);
  }

  /// Validates a scanned pairing session.
  Future<bool> validateSession(PairingSession session) async {
    if (session.isExpired) return false;
    return _identity.verify(
      data: session.signedBytes,
      signature: session.signature,
      peerPublicKey: session.identityPublicKey,
    );
  }

  /// Creates a pairing answer after scanning a valid QR.
  Future<({PairingAnswer answer, dynamic ephemeralKeyPair})> createAnswer({
    required String sessionId,
    required String sdpAnswer,
    required List<String> iceCandidates,
  }) async {
    final ephemeralKeyPair = await _crypto.generateEphemeralKeyPair();
    final ephemeralPubKey =
        await _crypto.extractX25519PublicKeyBytes(ephemeralKeyPair);
    final identityPubKey = await _identity.publicKeyBytes;

    final preAnswer = PairingAnswer(
      sessionId: sessionId,
      deviceId: _identity.deviceId,
      identityPublicKey: identityPubKey,
      ephemeralPublicKey: ephemeralPubKey,
      sdpAnswer: sdpAnswer,
      iceCandidates: iceCandidates,
      signature: Uint8List(0),
    );

    final signature = await _identity.sign(preAnswer.signedBytes);

    final answer = PairingAnswer(
      sessionId: sessionId,
      deviceId: _identity.deviceId,
      identityPublicKey: identityPubKey,
      ephemeralPublicKey: ephemeralPubKey,
      sdpAnswer: sdpAnswer,
      iceCandidates: iceCandidates,
      signature: signature,
    );

    return (answer: answer, ephemeralKeyPair: ephemeralKeyPair);
  }

  /// Validates a pairing answer.
  Future<bool> validateAnswer(PairingAnswer answer) async {
    return _identity.verify(
      data: answer.signedBytes,
      signature: answer.signature,
      peerPublicKey: answer.identityPublicKey,
    );
  }

  /// Derives the shared session key from ephemeral key exchange.
  Future<Uint8List> deriveSessionKey({
    required dynamic ourEphemeralKeyPair,
    required Uint8List peerEphemeralPublicKeyBytes,
    required String sessionId,
  }) async {
    final sharedSecret = await _crypto.deriveSharedSecret(
      ourKeyPair: ourEphemeralKeyPair,
      peerPublicKeyBytes: peerEphemeralPublicKeyBytes,
    );
    final salt = Uint8List.fromList(utf8.encode(sessionId));
    return _crypto.deriveSessionKey(
      sharedSecret: sharedSecret,
      salt: salt,
      info: 'imn-chat-session-v1',
    );
  }

  /// Encodes a pairing session to a QR-compatible string.
  String encodeToQR(PairingSession session) {
    return 'imn://pair?d=${base64Url.encode(utf8.encode(jsonEncode(session.toJson())))}';
  }

  /// Decodes a QR string back to a PairingSession.
  PairingSession? decodeFromQR(String qrData) {
    try {
      if (!qrData.startsWith('imn://pair?d=')) return null;
      final encoded = qrData.substring('imn://pair?d='.length);
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      return PairingSession.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Permanent Serverless Profile QR (No timer, No server)
  // ════════════════════════════════════════════════════════════

  /// Generates a permanent QR payload for the user's profile.
  Future<String> createPermanentProfileQR() async {
    final identityPubKey = await _identity.publicKeyBytes;
    final ephPubKey = await _identity.x25519PublicKeyBytes;
    final name = _identity.displayName;
    final did = _identity.deviceId;

    final dataToSign = {
      'did': did,
      'name': name,
      'ipk': base64Url.encode(identityPubKey),
      'epk': base64Url.encode(ephPubKey),
    };
    final bytesToSign = Uint8List.fromList(utf8.encode(jsonEncode(dataToSign)));
    final sig = await _identity.sign(bytesToSign);

    final profile = ProfileQRData(
      deviceId: did,
      displayName: name,
      identityPublicKey: identityPubKey,
      ephemeralPublicKey: ephPubKey,
      signature: sig,
    );

    return 'imn://profile?d=${base64Url.encode(utf8.encode(jsonEncode(profile.toJson())))}';
  }

  /// Parses and verifies a scanned profile QR code.
  Future<ProfileQRData?> parseAndVerifyProfileQR(String qrString) async {
    try {
      if (!qrString.startsWith('imn://profile?d=')) {
        return null;
      }
      final encoded = qrString.substring('imn://profile?d='.length);
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      final profile = ProfileQRData.fromJson(jsonDecode(jsonStr));

      final isValid = await _identity.verify(
        data: profile.signedBytes,
        signature: profile.signature,
        peerPublicKey: profile.identityPublicKey,
      );
      if (!isValid) return null;
      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Derives the shared session key from peer's profile.
  Future<Uint8List> deriveSessionKeyFromProfile({
    required Uint8List peerEphemeralPublicKey,
    required String peerDeviceId,
  }) async {
    final ourEphKey = _identity.ephemeralKeyPair;
    if (ourEphKey == null) throw StateError('Ephemeral key missing');
    final sharedSecret = await _crypto.deriveSharedSecret(
      ourKeyPair: ourEphKey,
      peerPublicKeyBytes: peerEphemeralPublicKey,
    );
    final ids = [_identity.deviceId, peerDeviceId]..sort();
    final salt = Uint8List.fromList(utf8.encode('imn-pair:${ids.join(":")}'));
    return _crypto.deriveSessionKey(
      sharedSecret: sharedSecret,
      salt: salt,
      info: 'imn-permanent-chat-v1',
    );
  }
}

/// Represents a permanent cryptographic profile in a QR code.
class ProfileQRData {
  final String deviceId;
  final String displayName;
  final Uint8List identityPublicKey; // Ed25519
  final Uint8List ephemeralPublicKey; // X25519
  final Uint8List signature;

  ProfileQRData({
    required this.deviceId,
    required this.displayName,
    required this.identityPublicKey,
    required this.ephemeralPublicKey,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'did': deviceId,
        'name': displayName,
        'ipk': base64Url.encode(identityPublicKey),
        'epk': base64Url.encode(ephemeralPublicKey),
        'sig': base64Url.encode(signature),
      };

  factory ProfileQRData.fromJson(Map<String, dynamic> json) => ProfileQRData(
        deviceId: json['did'] as String,
        displayName: (json['name'] as String?)?.isNotEmpty == true
            ? json['name'] as String
            : 'User',
        identityPublicKey: base64Url.decode(json['ipk'] as String),
        ephemeralPublicKey: base64Url.decode(json['epk'] as String),
        signature: base64Url.decode(json['sig'] as String),
      );

  Uint8List get signedBytes {
    final data = {
      'did': deviceId,
      'name': displayName,
      'ipk': base64Url.encode(identityPublicKey),
      'epk': base64Url.encode(ephemeralPublicKey),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }
}
