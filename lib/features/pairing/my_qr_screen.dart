import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/providers.dart';

class MyQRScreen extends ConsumerStatefulWidget {
  const MyQRScreen({super.key});

  @override
  ConsumerState<MyQRScreen> createState() => _MyQRScreenState();
}

class _MyQRScreenState extends ConsumerState<MyQRScreen> {
  String? _qrData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPermanentQR();
  }

  Future<void> _loadPermanentQR() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pairing = ref.read(pairingServiceProvider);
      // Instant cryptographic generation locally without any server
      final qrString = await pairing.createPermanentProfileQR();
      if (mounted) {
        setState(() {
          _qrData = qrString;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(identityServiceProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User profile mini-header
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              backgroundImage: (identity.avatarPath != null &&
                      File(identity.avatarPath!).existsSync())
                  ? FileImage(File(identity.avatarPath!))
                  : null,
              child: (identity.avatarPath == null ||
                      !File(identity.avatarPath!).existsSync())
                  ? Text(
                      identity.displayName.isNotEmpty
                          ? identity.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              identity.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded,
                    color: Colors.greenAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  'ID: ${identity.deviceId.length >= 8 ? identity.deviceId.substring(0, 8) : identity.deviceId}...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'نسخ المعرف',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: identity.deviceId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ معرّف الجهاز إلى الحافظة'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code Container
            if (_loading)
              Container(
                height: 280,
                width: 280,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const CircularProgressIndicator(),
              )
            else if (_error != null)
              Container(
                height: 280,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('تعذر إنشاء الرمز: $_error',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPermanentQR,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: theme.colorScheme.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E1E2E),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Status Badge: Permanent & Secure
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'رمز هوية دائم وموقّع تشفيرياً (Ed25519)',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'أظهر هذا الرمز لصديقك لإضافتك وبدء محادثة مشفرة P2P مباشرة دون أي سيرفر وسيط.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
