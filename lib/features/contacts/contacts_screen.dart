import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../services/database/app_database.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/signaling/signaling_service.dart';
import '../chat/chat_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  static const _uuid = Uuid();
  StreamSubscription<SignalingMessage>? _signalingSub;

  @override
  void initState() {
    super.initState();
    // Listen for incoming contact requests from signaling server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToSignaling();
    });
  }

  @override
  void dispose() {
    _signalingSub?.cancel();
    super.dispose();
  }

  void _subscribeToSignaling() {
    final signaling = ref.read(signalingServiceProvider);
    _signalingSub = signaling.messages?.listen((msg) async {
      if (msg.type == SignalingMessageType.contactRequest) {
        await _handleIncomingContactRequest(msg);
      } else if (msg.type == SignalingMessageType.contactRequestResponse) {
        await _handleContactRequestResponse(msg);
      }
    });
  }

  /// Called when THIS device receives a contact request from another device.
  Future<void> _handleIncomingContactRequest(SignalingMessage msg) async {
    final data = msg.data;
    if (data == null) return;

    final fromDeviceId = msg.fromDeviceId ?? data['fromDeviceId'] as String?;
    final fromName = data['fromDisplayName'] as String? ?? 'مستخدم';
    final fromIpk = data['fromIdentityPublicKey'] as String?;
    final fromEpk = data['fromEphemeralPublicKey'] as String?;
    if (fromDeviceId == null || fromIpk == null || fromEpk == null) return;

    final db = ref.read(databaseProvider);
    final existing = await db.getContactByDeviceId(fromDeviceId);

    // Don't override an already-accepted contact
    if (existing?.requestStatus == 'accepted') return;

    final contactId = existing?.id ?? _uuid.v4();
    await db.upsertContact(ContactsCompanion(
      id: drift.Value(contactId),
      deviceId: drift.Value(fromDeviceId),
      displayName: drift.Value(fromName),
      identityPublicKey: drift.Value(fromIpk),
      ephemeralPublicKey: drift.Value(fromEpk),
      createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      isBlocked: const drift.Value(false),
      requestStatus: const drift.Value('pending_received'),
    ));

    if (mounted) {
      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('طلب مراسلة جديد من $fromName'),
          action: SnackBarAction(label: 'عرض', onPressed: () => setState(() {})),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Called when THIS device receives a response (accepted/rejected) to a
  /// contact request it previously sent.
  Future<void> _handleContactRequestResponse(SignalingMessage msg) async {
    final data = msg.data;
    if (data == null) return;

    final fromDeviceId = msg.fromDeviceId ?? data['fromDeviceId'] as String?;
    final accepted = data['accepted'] as bool? ?? false;
    final sessionId = data['sessionId'] as String?;

    if (fromDeviceId == null) return;

    final db = ref.read(databaseProvider);
    final contact = await db.getContactByDeviceId(fromDeviceId);
    if (contact == null) return;

    if (!accepted) {
      // They rejected — delete pending request
      await db.deleteContact(contact.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رفض ${contact.displayName} طلب المراسلة'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // They accepted — update status + join WebRTC session
    await db.updateContactRequestStatus(contact.id, 'accepted');

    // Create conversation
    final existingConv = await db.getConversationByContactId(contact.id);
    final conversationId = existingConv?.id ?? _uuid.v4();
    final newSessionId = sessionId ?? 'sess_${contact.deviceId.replaceAll('-', '')}';

    await db.upsertConversation(ConversationsCompanion(
      id: drift.Value(conversationId),
      contactId: drift.Value(contact.id),
      sessionId: drift.Value(newSessionId),
      createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      lastMessageAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      lastMessagePreview: const drift.Value('بدأت المحادثة المشفرة'),
    ));

    // Setup encryption session
    final pairing = ref.read(pairingServiceProvider);
    final encryption = ref.read(encryptionServiceProvider);
    try {
      final epkBytes = base64Url.decode(contact.ephemeralPublicKey);
      final sessionKey = await pairing.deriveSessionKeyFromProfile(
        peerEphemeralPublicKey: epkBytes,
        peerDeviceId: contact.deviceId,
      );
      encryption.addSession(EncryptionSession(
        sessionId: newSessionId,
        contactDeviceId: contact.deviceId,
        sessionKey: sessionKey,
      ));
    } catch (e) {
      // Key derivation might fail if keys are not available — continue anyway
    }

    // If acceptor provided a sessionId, join the WebRTC session as responder
    if (sessionId != null) {
      await _joinAsResponder(sessionId, contact.deviceId);
    }

    if (mounted) {
      setState(() {});
      // Open chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            contactId: contact.id,
            sessionId: newSessionId,
          ),
        ),
      );
    }
  }

  /// Accept a pending_received request: create conversation, initiate WebRTC.
  Future<void> _acceptRequest(Contact contact) async {
    final db = ref.read(databaseProvider);
    final signaling = ref.read(signalingServiceProvider);
    final identity = ref.read(identityServiceProvider);
    final pairing = ref.read(pairingServiceProvider);
    final encryption = ref.read(encryptionServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);

    try {
      // 1. Update to accepted
      await db.updateContactRequestStatus(contact.id, 'accepted');

      // 2. Create conversation
      final existingConv = await db.getConversationByContactId(contact.id);
      final conversationId = existingConv?.id ?? _uuid.v4();
      final sessionId = 'sess_${contact.deviceId.replaceAll('-', '')}_${identity.deviceId.replaceAll('-', '').substring(0, 8)}';

      await db.upsertConversation(ConversationsCompanion(
        id: drift.Value(conversationId),
        contactId: drift.Value(contact.id),
        sessionId: drift.Value(sessionId),
        createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        lastMessageAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        lastMessagePreview: const drift.Value('بدأت المحادثة المشفرة'),
      ));

      // 3. Setup encryption session
      try {
        final epkBytes = base64Url.decode(contact.ephemeralPublicKey);
        final sessionKey = await pairing.deriveSessionKeyFromProfile(
          peerEphemeralPublicKey: epkBytes,
          peerDeviceId: contact.deviceId,
        );
        encryption.addSession(EncryptionSession(
          sessionId: sessionId,
          contactDeviceId: contact.deviceId,
          sessionKey: sessionKey,
        ));
      } catch (_) {}

      // 4. Ensure registered on signaling
      await signaling.registerDevice(identity.deviceId);

      // 5. Create WebRTC session as initiator (offer maker)
      try {
        signaling.createSession(sessionId);
        final offerSdp = await webrtc.createOffer(sessionId);
        signaling.sendOffer(sessionId, offerSdp);
      } catch (e) {
        // WebRTC might not be available on all platforms for testing
      }

      // 6. Notify the requester: accepted + sessionId
      signaling.sendContactRequestResponse(
        contact.deviceId,
        true,
        extra: {
          'sessionId': sessionId,
          'fromDeviceId': identity.deviceId,
        },
      );

      if (mounted) {
        setState(() {});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              contactId: contact.id,
              sessionId: sessionId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في قبول الطلب: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Reject a pending_received request.
  Future<void> _rejectRequest(Contact contact) async {
    final db = ref.read(databaseProvider);
    final signaling = ref.read(signalingServiceProvider);
    final identity = ref.read(identityServiceProvider);

    await db.deleteContact(contact.id);

    // Notify requester of rejection
    signaling.sendContactRequestResponse(contact.deviceId, false,
        extra: {'fromDeviceId': identity.deviceId});

    if (mounted) setState(() {});
  }

  /// Join as responder (answer side) after acceptor sends session info.
  Future<void> _joinAsResponder(String sessionId, String peerDeviceId) async {
    final signaling = ref.read(signalingServiceProvider);
    final webrtc = ref.read(webrtcServiceProvider);

    signaling.joinSession(sessionId);

    // Listen for the offer from the acceptor
    StreamSubscription? sub;
    sub = signaling.messages?.listen((msg) async {
      if (msg.type == SignalingMessageType.offer &&
          msg.sessionId == sessionId) {
        final offerSdp = msg.data?['sdp'] as String?;
        if (offerSdp != null) {
          try {
            final answerSdp = await webrtc.createAnswer(sessionId, offerSdp);
            signaling.sendAnswer(sessionId, answerSdp);
          } catch (_) {}
        }
        sub?.cancel();
      } else if (msg.type == SignalingMessageType.iceCandidate &&
          msg.sessionId == sessionId) {
        final data = msg.data;
        if (data != null) {
          await webrtc.addIceCandidate(data);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('جهات الاتصال')),
      body: FutureBuilder<List<Contact>>(
        future: _loadAllContactData(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allContacts = snapshot.data ?? [];
          final pendingReceived = allContacts
              .where((c) => c.requestStatus == 'pending_received')
              .toList();
          final pendingSent = allContacts
              .where((c) => c.requestStatus == 'pending_sent')
              .toList();
          final accepted = allContacts
              .where((c) => c.requestStatus == 'accepted')
              .toList();

          if (allContacts.isEmpty) {
            return _buildEmpty(context);
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Pending Received Requests ────────────────────────────
                if (pendingReceived.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.mark_email_unread_rounded,
                    title: 'طلبات المراسلة',
                    count: pendingReceived.length,
                    color: theme.colorScheme.primary,
                  ),
                  ...pendingReceived.map((c) => _PendingRequestTile(
                        contact: c,
                        onAccept: () => _acceptRequest(c),
                        onReject: () => _rejectRequest(c),
                      )),
                  const SizedBox(height: 8),
                ],

                // ── Pending Sent ─────────────────────────────────────────
                if (pendingSent.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.schedule_send_rounded,
                    title: 'في انتظار الموافقة',
                    count: pendingSent.length,
                    color: Colors.orange,
                  ),
                  ...pendingSent.map((c) => _PendingSentTile(contact: c)),
                  const SizedBox(height: 8),
                ],

                // ── Accepted Contacts ────────────────────────────────────
                if (accepted.isNotEmpty) ...[
                  if (pendingReceived.isNotEmpty || pendingSent.isNotEmpty)
                    _SectionHeader(
                      icon: Icons.people_rounded,
                      title: 'جهات الاتصال',
                      count: accepted.length,
                      color: Colors.greenAccent,
                    ),
                  ...accepted.asMap().entries.map((entry) {
                    final i = entry.key;
                    final contact = entry.value;
                    return Column(
                      children: [
                        _AcceptedContactTile(
                          contact: contact,
                          onTap: () => _openChat(contact),
                          onBlock: () async {
                            await db.setContactBlocked(contact.id, true);
                            setState(() {});
                          },
                          onDelete: () async {
                            await db.deleteContact(contact.id);
                            setState(() {});
                          },
                        ),
                        if (i < accepted.length - 1)
                          const Divider(
                              height: 1, indent: 72, endIndent: 16),
                      ],
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Contact>> _loadAllContactData(db) async {
    final all = await db.getAllContacts();
    final pending = await db.getPendingReceivedContacts();
    final sent = await db.getPendingSentContacts();
    return [...pending, ...sent, ...all];
  }

  Future<void> _openChat(Contact contact) async {
    final db = ref.read(databaseProvider);
    final conv = await db.getConversationByContactId(contact.id);
    if (conv != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conv.id,
            contactId: contact.id,
            sessionId: conv.sessionId,
          ),
        ),
      );
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('لا توجد جهات اتصال بعد',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('امسح رمز QR لإضافة صديق',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Received Request Tile ─────────────────────────────────────────────

class _PendingRequestTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestTile({
    required this.contact,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Text(
            contact.displayName.isNotEmpty
                ? contact.displayName[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        title: Text(contact.displayName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'يريد إرسال رسالة إليك',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reject button
            Material(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onReject,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded,
                      color: Colors.redAccent, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Accept button
            Material(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAccept,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.check_rounded,
                      color: Colors.greenAccent, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Sent Tile ─────────────────────────────────────────────────────────

class _PendingSentTile extends StatelessWidget {
  final Contact contact;
  const _PendingSentTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: Text(
            contact.displayName.isNotEmpty
                ? contact.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        title: Text(contact.displayName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: const Text(
          'في انتظار الموافقة...',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}

// ── Accepted Contact Tile ─────────────────────────────────────────────────────

class _AcceptedContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const _AcceptedContactTile({
    required this.contact,
    required this.onTap,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Text(
          contact.displayName.isNotEmpty
              ? contact.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(contact.displayName,
          style: theme.textTheme.titleMedium),
      subtitle: Text(
        'ID: ${contact.deviceId.length >= 8 ? contact.deviceId.substring(0, 8) : contact.deviceId}...',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: onTap,
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'block') onBlock();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(children: [
                  Icon(Icons.block_rounded, size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('حظر المستخدم'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('حذف جهة الاتصال'),
                ]),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
