import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/crypto/crypto_service.dart';
import '../../features/identity/identity_service.dart';
import '../../features/pairing/pairing_service.dart';
import '../../services/database/app_database.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/network_monitor/network_monitor_service.dart';
import '../../services/signaling/signaling_service.dart';
import '../../services/webrtc/webrtc_service.dart';
import '../../services/webrtc/connection_manager.dart';
import '../../features/chat/message_service.dart';
import '../../features/files/file_transfer_service.dart';

// ── Core Services ────────────────────────────────────────────────────────────

final cryptoServiceProvider = Provider<CryptoService>((_) => CryptoService());

final secureStorageProvider = Provider<FlutterSecureStorage>((_) =>
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ));

final identityServiceProvider = Provider<IdentityService>((ref) {
  return IdentityService(
    secureStorage: ref.read(secureStorageProvider),
    cryptoService: ref.read(cryptoServiceProvider),
  );
});

final identityInitProvider = FutureProvider<void>((ref) async {
  final identity = ref.read(identityServiceProvider);
  await identity.initialize();

  // After identity is ready, connect to signaling and register device
  if (identity.deviceId.isNotEmpty) {
    final signaling = ref.read(signalingServiceProvider);
    // Connect and register in background — don't block app init
    Future.microtask(() async {
      try {
        await signaling.registerDevice(identity.deviceId);
      } catch (_) {
        // Signaling failure should not block the app
      }
    });
  }
});

// ── Database ─────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((_) => AppDatabase());

// ── Encryption ───────────────────────────────────────────────────────────────

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(crypto: ref.read(cryptoServiceProvider));
});

// ── Network Monitor ──────────────────────────────────────────────────────────

final networkMonitorProvider = Provider<NetworkMonitorService>((ref) {
  final monitor = NetworkMonitorService();
  ref.onDispose(() => monitor.dispose());
  return monitor;
});

// ── Signaling ────────────────────────────────────────────────────────────────
//
// ⚠️  CONFIGURATION: Change this URL to match your signaling server.
//
//  Local Android Emulator  → 'ws://10.0.2.2:8080'
//  Real device, same WiFi  → 'ws://<YOUR-PC-LOCAL-IP>:8080'
//                            e.g. 'ws://192.168.1.100:8080'
//  Production server       → 'wss://signaling.yourdomain.com:8080'
//
const signalingServerUrl = 'wss://imn-production.up.railway.app';

final signalingServiceProvider = Provider<SignalingService>((ref) {
  final service = SignalingService(serverUrl: signalingServerUrl);
  ref.onDispose(() => service.disconnect());
  return service;
});

// ── WebRTC ───────────────────────────────────────────────────────────────────

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService(signaling: ref.read(signalingServiceProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final manager = ConnectionManager(
    webrtc: ref.read(webrtcServiceProvider),
    signaling: ref.read(signalingServiceProvider),
    networkMonitor: ref.read(networkMonitorProvider),
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});

// ── Pairing ──────────────────────────────────────────────────────────────────

final pairingServiceProvider = Provider<PairingService>((ref) {
  return PairingService(
    crypto: ref.read(cryptoServiceProvider),
    identity: ref.read(identityServiceProvider),
  );
});

// ── Message Service ──────────────────────────────────────────────────────────

final messageServiceProvider = Provider<MessageService>((ref) {
  final identity = ref.read(identityServiceProvider);
  return MessageService(
    db: ref.read(databaseProvider),
    encryption: ref.read(encryptionServiceProvider),
    webrtc: ref.read(webrtcServiceProvider),
    localDeviceId: identity.deviceId,
  );
});

// ── File Transfer ─────────────────────────────────────────────────────────────

final fileTransferProvider = Provider<FileTransferService>((ref) {
  final service = FileTransferService(
    encryption: ref.read(encryptionServiceProvider),
    webrtc: ref.read(webrtcServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});
