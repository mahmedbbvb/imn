import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get identityPublicKey => text()();
  TextColumn get ephemeralPublicKey => text()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get lastSeenAt => integer().nullable()();
  BoolColumn get isBlocked =>
      boolean().withDefault(const Constant(false))();
  TextColumn get requestStatus =>
      text().withDefault(const Constant('accepted'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get contactId => text().references(Contacts, #id)();
  TextColumn get sessionId => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastMessageAt => integer().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get unreadCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id)();
  TextColumn get senderDeviceId => text()();
  IntColumn get timestamp => integer()();
  TextColumn get messageType => text()();
  TextColumn get encryptedPayload => text()();
  TextColumn get status =>
      text().withDefault(const Constant('sending'))();
  BoolColumn get isOutgoing => boolean()();
  TextColumn get attachmentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text().references(Messages, #id)();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get mimeType => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get fileHash => text()();
  IntColumn get totalChunks => integer()();
  IntColumn get receivedChunks =>
      integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get encryptedPayload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get attempts =>
      integer().withDefault(const Constant(0))();
  IntColumn get nextRetryAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Renamed to avoid conflict with EncryptionSession from encryption_service.dart
class EncryptionSessionRecords extends Table {
  TextColumn get sessionId => text()();
  TextColumn get contactDeviceId => text()();
  TextColumn get sessionKey => text()();
  IntColumn get createdAt => integer()();
  IntColumn get rotatedAt => integer().nullable()();
  IntColumn get keyVersion =>
      integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Contacts,
  Conversations,
  Messages,
  Attachments,
  PendingMessages,
  EncryptionSessionRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async => m.createAll(),
      );

  // ── Contacts ─────────────────────────────────────────────────

  Future<List<Contact>> getAllContacts() =>
      (select(contacts)
            ..where((c) =>
                c.isBlocked.equals(false) & c.requestStatus.equals('accepted'))
            ..orderBy([(c) => OrderingTerm.asc(c.displayName)]))
          .get();

  Future<List<Contact>> getPendingReceivedContacts() =>
      (select(contacts)
            ..where((c) =>
                c.isBlocked.equals(false) &
                c.requestStatus.equals('pending_received'))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .get();

  Future<List<Contact>> getPendingSentContacts() =>
      (select(contacts)
            ..where((c) =>
                c.isBlocked.equals(false) &
                c.requestStatus.equals('pending_sent'))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .get();

  Future<int> updateContactRequestStatus(String contactId, String status) =>
      (update(contacts)..where((c) => c.id.equals(contactId)))
          .write(ContactsCompanion(requestStatus: Value(status)));

  Future<Contact?> getContactByDeviceId(String deviceId) =>
      (select(contacts)
            ..where((c) => c.deviceId.equals(deviceId)))
          .getSingleOrNull();

  Future<Contact?> getContactById(String id) =>
      (select(contacts)
            ..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<List<Contact>> getBlockedContacts() =>
      (select(contacts)
            ..where((c) => c.isBlocked.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.displayName)]))
          .get();

  Future<int> setContactBlocked(String contactId, bool isBlocked) =>
      (update(contacts)..where((c) => c.id.equals(contactId)))
          .write(ContactsCompanion(isBlocked: Value(isBlocked)));

  Future<int> deleteContact(String contactId) async {
    await (delete(conversations)..where((c) => c.contactId.equals(contactId))).go();
    return (delete(contacts)..where((c) => c.id.equals(contactId))).go();
  }

  Future<int> clearAllMessages() async {
    await delete(attachments).go();
    await delete(pendingMessages).go();
    return delete(messages).go();
  }

  Future<int> upsertContact(ContactsCompanion companion) =>
      into(contacts).insertOnConflictUpdate(companion);

  // ── Conversations ─────────────────────────────────────────────

  Future<List<Conversation>> getAllConversations() =>
      (select(conversations)
            ..orderBy([
              (c) => OrderingTerm.desc(c.lastMessageAt),
            ]))
          .get();

  Future<Conversation?> getConversationByContactId(String contactId) =>
      (select(conversations)
            ..where((c) => c.contactId.equals(contactId)))
          .getSingleOrNull();

  Future<int> upsertConversation(ConversationsCompanion companion) =>
      into(conversations).insertOnConflictUpdate(companion);

  // ── Messages ─────────────────────────────────────────────────

  Future<List<Message>> getMessages(String conversationId,
      {int limit = 50, int? beforeTimestamp}) {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..where((m) => beforeTimestamp == null
              ? const Constant(true)
              : m.timestamp.isSmallerThan(Variable(beforeTimestamp)))
          ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<int> insertMessage(MessagesCompanion companion) =>
      into(messages).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<bool> updateMessageStatus(String messageId, String status) async {
    final rows = await (update(messages)
          ..where((m) => m.id.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
    return rows > 0;
  }

  Future<bool> messageExists(String messageId) async {
    final msg = await (select(messages)
          ..where((m) => m.id.equals(messageId)))
        .getSingleOrNull();
    return msg != null;
  }

  // ── Pending Messages ─────────────────────────────────────────

  Future<List<PendingMessage>> getPendingMessages(String conversationId) =>
      (select(pendingMessages)
            ..where((p) => p.conversationId.equals(conversationId))
            ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
          .get();

  Future<int> insertPendingMessage(PendingMessagesCompanion companion) =>
      into(pendingMessages).insert(companion);

  Future<int> deletePendingMessage(String messageId) =>
      (delete(pendingMessages)
            ..where((p) => p.id.equals(messageId)))
          .go();

  // ── Encryption Session Records ────────────────────────────────

  Future<EncryptionSessionRecord?> getEncryptionSessionRecord(
          String sessionId) =>
      (select(encryptionSessionRecords)
            ..where((s) => s.sessionId.equals(sessionId)))
          .getSingleOrNull();

  Future<int> upsertEncryptionSessionRecord(
          EncryptionSessionRecordsCompanion c) =>
      into(encryptionSessionRecords).insertOnConflictUpdate(c);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'imn.db'));
    return NativeDatabase.createInBackground(file);
  });
}
