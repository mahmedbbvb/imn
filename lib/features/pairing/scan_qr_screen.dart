import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../services/database/app_database.dart';
import '../chat/chat_screen.dart';
import '../pairing/pairing_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends ConsumerStatefulWidget {
  const ScanQRScreen({super.key});

  @override
  ConsumerState<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends ConsumerState<ScanQRScreen> {
  MobileScannerController? _scannerController;
  bool _processing = false;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final qrValue = barcode!.rawValue!;
    setState(() => _processing = true);
    await _scannerController?.stop();

    try {
      final pairing = ref.read(pairingServiceProvider);
      final identity = ref.read(identityServiceProvider);

      // Check if it's a permanent profile QR
      final profile = await pairing.parseAndVerifyProfileQR(qrValue);

      if (profile != null) {
        if (profile.deviceId == identity.deviceId) {
          _showError('هذا هو رمز حسابك الخاص!');
          return;
        }
        if (mounted) {
          _showInviteBottomSheet(profile);
        }
        return;
      }

      // Legacy session QR check
      final session = pairing.decodeFromQR(qrValue);
      if (session != null) {
        final valid = await pairing.validateSession(session);
        if (valid && mounted) {
          final profileData = ProfileQRData(
            deviceId: session.deviceId,
            displayName: 'مستخدم ${session.deviceId.substring(0, 6)}',
            identityPublicKey: session.identityPublicKey,
            ephemeralPublicKey: session.ephemeralPublicKey,
            signature: session.signature,
          );
          _showInviteBottomSheet(profileData);
          return;
        }
      }

      _showError('رمز QR غير صالح أو تم التلاعب به.');
    } catch (e) {
      _showError('خطأ أثناء فحص الرمز: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _processing = false);
        _scannerController?.start();
      }
    });
  }

  /// Shows a bottom sheet with ONLY the "Send Invitation" button.
  /// Does NOT show user data (name, ID, etc.) per requirements.
  void _showInviteBottomSheet(ProfileQRData profile) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),

                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'تم مسح رمز QR بنجاح',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Security Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'هوية موثقة ومشفرة (Ed25519)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'اضغط "إرسال دعوة" لإرسال طلب مراسلة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Send Invitation Button (ONLY action button)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendContactRequest(ctx, profile),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'إرسال دعوة',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _processing = false);
                      _scannerController?.start();
                    },
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && _processing) {
        setState(() => _processing = false);
        _scannerController?.start();
      }
    });
  }

  /// Saves contact as pending_sent and sends request via signaling.
  Future<void> _sendContactRequest(
      BuildContext sheetCtx, ProfileQRData profile) async {
    Navigator.pop(sheetCtx);

    try {
      final db = ref.read(databaseProvider);
      final identity = ref.read(identityServiceProvider);
      final signaling = ref.read(signalingServiceProvider);

      // 1. Check if contact already exists and is accepted
      final existing = await db.getContactByDeviceId(profile.deviceId);
      if (existing != null && existing.requestStatus == 'accepted') {
        final conv = await db.getConversationByContactId(existing.id);
        if (conv != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conv.id,
                contactId: existing.id,
                sessionId: conv.sessionId,
              ),
            ),
          );
        }
        return;
      }

      final contactId = existing?.id ?? _uuid.v4();

      // 2. Save contact as pending_sent
      await db.upsertContact(ContactsCompanion(
        id: drift.Value(contactId),
        deviceId: drift.Value(profile.deviceId),
        displayName: drift.Value(profile.displayName),
        identityPublicKey:
            drift.Value(base64Url.encode(profile.identityPublicKey)),
        ephemeralPublicKey:
            drift.Value(base64Url.encode(profile.ephemeralPublicKey)),
        createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        isBlocked: const drift.Value(false),
        requestStatus: const drift.Value('pending_sent'),
      ));

      // 3. Ensure device is registered on signaling
      await signaling.registerDevice(identity.deviceId);

      // 4. Build our own profile data to include in the request
      final myPubKey = await identity.publicKeyBytes;
      final myEphKey = await identity.x25519PublicKeyBytes;

      // 5. Send contact request via signaling (if target is online)
      signaling.sendContactRequest(profile.deviceId, {
        'fromDeviceId': identity.deviceId,
        'fromDisplayName': identity.displayName,
        'fromIdentityPublicKey': base64Url.encode(myPubKey),
        'fromEphemeralPublicKey': base64Url.encode(myEphKey),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم إرسال دعوة المراسلة بنجاح. في انتظار موافقة الطرف الآخر.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('فشل إرسال الدعوة: $e');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        _scannerController?.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onDetect),
        _ScanOverlay(),
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
              onPressed: () => _scannerController?.toggleTorch(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(primaryColor: Theme.of(context).colorScheme.primary),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 240),
            Text(
              'وجّه الكاميرا نحو رمز QR لإضافة الصديق',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Color primaryColor;
  _OverlayPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2 - 40;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    final cornerPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cl = 28.0;

    void drawCorner(Offset corner, Offset h, Offset v) {
      final p = Path()
        ..moveTo(h.dx, h.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(v.dx, v.dy);
      canvas.drawPath(p, cornerPaint);
    }

    drawCorner(scanRect.topLeft, Offset(scanRect.left + cl, scanRect.top),
        Offset(scanRect.left, scanRect.top + cl));
    drawCorner(scanRect.topRight, Offset(scanRect.right - cl, scanRect.top),
        Offset(scanRect.right, scanRect.top + cl));
    drawCorner(scanRect.bottomLeft, Offset(scanRect.left + cl, scanRect.bottom),
        Offset(scanRect.left, scanRect.bottom - cl));
    drawCorner(scanRect.bottomRight, Offset(scanRect.right - cl, scanRect.bottom),
        Offset(scanRect.right, scanRect.bottom - cl));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
