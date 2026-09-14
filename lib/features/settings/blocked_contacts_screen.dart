import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../services/database/app_database.dart';

class BlockedContactsScreen extends ConsumerStatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  ConsumerState<BlockedContactsScreen> createState() =>
      _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends ConsumerState<BlockedContactsScreen> {
  List<Contact> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final db = ref.read(databaseProvider);
    final list = await db.getBlockedContacts();
    if (mounted) {
      setState(() {
        _blocked = list;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(Contact contact) async {
    final db = ref.read(databaseProvider);
    await db.setContactBlocked(contact.id, false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء حظر ${contact.displayName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadBlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات الاتصال المحظورة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block_flipped,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد جهات اتصال محظورة',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أي شخص تحظره سيظهر في هذه القائمة مع إمكانية فك الحظر عنه.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _blocked.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (context, i) {
                    final contact = _blocked[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'ID: ${contact.deviceId.substring(0, 10)}...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _unblock(contact),
                        child: const Text('فك الحظر'),
                      ),
                    );
                  },
                ),
    );
  }
}
