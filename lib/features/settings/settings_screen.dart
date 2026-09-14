import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import 'blocked_contacts_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('التقاط بالكاميرا'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final identity = ref.read(identityServiceProvider);
        await identity.setAvatarPath(picked.path);
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _editDisplayName() async {
    final identity = ref.read(identityServiceProvider);
    final ctrl = TextEditingController(text: identity.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'أدخل اسمك الشخصي',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await identity.setDisplayName(newName);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showPublicKey() async {
    final identity = ref.read(identityServiceProvider);
    try {
      final bytes = await identity.publicKeyBytes;
      final b64 = base64Url.encode(bytes);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('مفتاح الهوية العام (Ed25519)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هذا هو مفتاحك العام الموثق لتأكيد هويتك وتوقيع جلساتك المشفرة:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    b64,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('نسخ'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: b64));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ المفتاح العام')),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _confirmClearMessages() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح جميع الرسائل؟'),
        content: const Text(
            'سيتم مسح جميع الرسائل والمرفقات المخزنة محلياً على هذا الجهاز بشكل نهائي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.clearAllMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح جميع الرسائل محلياً')),
        );
      }
    }
  }

  Future<void> _confirmResetIdentity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تعيين الهوية بالكامل؟'),
        content: const Text(
          'سيتم حذف مفاتيح التشفير والهوية الرقمية وجميع جهات الاتصال والمحادثات على هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف وإعادة ضبط'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(identityServiceProvider).deleteIdentity();
      ref.invalidate(identityInitProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(identityServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Header Card ───────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with Edit Button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
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
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Name and Device ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                identity.displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _editDisplayName,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'ID: ${identity.deviceId.length >= 12 ? identity.deviceId.substring(0, 12) : identity.deviceId}...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: identity.deviceId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم نسخ معرّف الجهاز')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Section: الخصوصية والمحادثات ─────────────────────────────
          _SectionTitle(title: 'الخصوصية والمحادثات'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.block_rounded,
                  title: 'جهات الاتصال المحظورة',
                  subtitle: 'إدارة وفك الحظر عن جهات الاتصال',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockedContactsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'مسح جميع المحادثات',
                  subtitle: 'حذف الرسائل والمرفقات المخزنة محلياً',
                  iconColor: Colors.orangeAccent,
                  onTap: _confirmClearMessages,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section: الأمان والتشفير ─────────────────────────────────
          _SectionTitle(title: 'الأمان والتشفير (P2P E2EE)'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.verified_user_rounded,
                  title: 'تشفير تام بدون خوادم (Zero-Server)',
                  subtitle: 'ChaCha20-Poly1305 + X25519 + Ed25519',
                  iconColor: Colors.greenAccent,
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.key_rounded,
                  title: 'مفتاح الهوية الرقمي (Ed25519)',
                  subtitle: 'عرض وتأكيد المفتاح العام لجهازك',
                  onTap: _showPublicKey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Section: منطقة الخطر ─────────────────────────────────────
          _SectionTitle(title: 'إدارة الحساب والجهاز', color: Colors.redAccent),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: _SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.redAccent,
              title: 'إعادة ضبط الهوية بالكامل',
              subtitle: 'حذف مفاتيح التشفير والمحادثات والبدء من جديد',
              onTap: _confirmResetIdentity,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionTitle({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? theme.colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_left_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
