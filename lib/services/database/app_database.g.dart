// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _identityPublicKeyMeta =
      const VerificationMeta('identityPublicKey');
  @override
  late final GeneratedColumn<String> identityPublicKey =
      GeneratedColumn<String>('identity_public_key', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ephemeralPublicKeyMeta =
      const VerificationMeta('ephemeralPublicKey');
  @override
  late final GeneratedColumn<String> ephemeralPublicKey =
      GeneratedColumn<String>('ephemeral_public_key', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
      'last_seen_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isBlockedMeta =
      const VerificationMeta('isBlocked');
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
      'is_blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_blocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _requestStatusMeta =
      const VerificationMeta('requestStatus');
  @override
  late final GeneratedColumn<String> requestStatus = GeneratedColumn<String>(
      'request_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('accepted'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        displayName,
        identityPublicKey,
        ephemeralPublicKey,
        avatarPath,
        createdAt,
        lastSeenAt,
        isBlocked,
        requestStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<Contact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
          _identityPublicKeyMeta,
          identityPublicKey.isAcceptableOrUnknown(
              data['identity_public_key']!, _identityPublicKeyMeta));
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('ephemeral_public_key')) {
      context.handle(
          _ephemeralPublicKeyMeta,
          ephemeralPublicKey.isAcceptableOrUnknown(
              data['ephemeral_public_key']!, _ephemeralPublicKeyMeta));
    } else if (isInserting) {
      context.missing(_ephemeralPublicKeyMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
    }
    if (data.containsKey('is_blocked')) {
      context.handle(_isBlockedMeta,
          isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta));
    }
    if (data.containsKey('request_status')) {
      context.handle(
          _requestStatusMeta,
          requestStatus.isAcceptableOrUnknown(
              data['request_status']!, _requestStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      identityPublicKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}identity_public_key'])!,
      ephemeralPublicKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ephemeral_public_key'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_seen_at']),
      isBlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_blocked'])!,
      requestStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_status'])!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;
  final String deviceId;
  final String displayName;
  final String identityPublicKey;
  final String ephemeralPublicKey;
  final String? avatarPath;
  final int createdAt;
  final int? lastSeenAt;
  final bool isBlocked;
  final String requestStatus;
  const Contact(
      {required this.id,
      required this.deviceId,
      required this.displayName,
      required this.identityPublicKey,
      required this.ephemeralPublicKey,
      this.avatarPath,
      required this.createdAt,
      this.lastSeenAt,
      required this.isBlocked,
      required this.requestStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['identity_public_key'] = Variable<String>(identityPublicKey);
    map['ephemeral_public_key'] = Variable<String>(ephemeralPublicKey);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(lastSeenAt);
    }
    map['is_blocked'] = Variable<bool>(isBlocked);
    map['request_status'] = Variable<String>(requestStatus);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      identityPublicKey: Value(identityPublicKey),
      ephemeralPublicKey: Value(ephemeralPublicKey),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      createdAt: Value(createdAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      isBlocked: Value(isBlocked),
      requestStatus: Value(requestStatus),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      identityPublicKey: serializer.fromJson<String>(json['identityPublicKey']),
      ephemeralPublicKey:
          serializer.fromJson<String>(json['ephemeralPublicKey']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastSeenAt: serializer.fromJson<int?>(json['lastSeenAt']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      requestStatus: serializer.fromJson<String>(json['requestStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'displayName': serializer.toJson<String>(displayName),
      'identityPublicKey': serializer.toJson<String>(identityPublicKey),
      'ephemeralPublicKey': serializer.toJson<String>(ephemeralPublicKey),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastSeenAt': serializer.toJson<int?>(lastSeenAt),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'requestStatus': serializer.toJson<String>(requestStatus),
    };
  }

  Contact copyWith(
          {String? id,
          String? deviceId,
          String? displayName,
          String? identityPublicKey,
          String? ephemeralPublicKey,
          Value<String?> avatarPath = const Value.absent(),
          int? createdAt,
          Value<int?> lastSeenAt = const Value.absent(),
          bool? isBlocked,
          String? requestStatus}) =>
      Contact(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        displayName: displayName ?? this.displayName,
        identityPublicKey: identityPublicKey ?? this.identityPublicKey,
        ephemeralPublicKey: ephemeralPublicKey ?? this.ephemeralPublicKey,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        createdAt: createdAt ?? this.createdAt,
        lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
        isBlocked: isBlocked ?? this.isBlocked,
        requestStatus: requestStatus ?? this.requestStatus,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      ephemeralPublicKey: data.ephemeralPublicKey.present
          ? data.ephemeralPublicKey.value
          : this.ephemeralPublicKey,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      requestStatus: data.requestStatus.present
          ? data.requestStatus.value
          : this.requestStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('ephemeralPublicKey: $ephemeralPublicKey, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('requestStatus: $requestStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      displayName,
      identityPublicKey,
      ephemeralPublicKey,
      avatarPath,
      createdAt,
      lastSeenAt,
      isBlocked,
      requestStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.identityPublicKey == this.identityPublicKey &&
          other.ephemeralPublicKey == this.ephemeralPublicKey &&
          other.avatarPath == this.avatarPath &&
          other.createdAt == this.createdAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isBlocked == this.isBlocked &&
          other.requestStatus == this.requestStatus);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<String> identityPublicKey;
  final Value<String> ephemeralPublicKey;
  final Value<String?> avatarPath;
  final Value<int> createdAt;
  final Value<int?> lastSeenAt;
  final Value<bool> isBlocked;
  final Value<String> requestStatus;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.ephemeralPublicKey = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.requestStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String deviceId,
    required String displayName,
    required String identityPublicKey,
    required String ephemeralPublicKey,
    this.avatarPath = const Value.absent(),
    required int createdAt,
    this.lastSeenAt = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.requestStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        deviceId = Value(deviceId),
        displayName = Value(displayName),
        identityPublicKey = Value(identityPublicKey),
        ephemeralPublicKey = Value(ephemeralPublicKey),
        createdAt = Value(createdAt);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<String>? identityPublicKey,
    Expression<String>? ephemeralPublicKey,
    Expression<String>? avatarPath,
    Expression<int>? createdAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? isBlocked,
    Expression<String>? requestStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (ephemeralPublicKey != null)
        'ephemeral_public_key': ephemeralPublicKey,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (requestStatus != null) 'request_status': requestStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? deviceId,
      Value<String>? displayName,
      Value<String>? identityPublicKey,
      Value<String>? ephemeralPublicKey,
      Value<String?>? avatarPath,
      Value<int>? createdAt,
      Value<int?>? lastSeenAt,
      Value<bool>? isBlocked,
      Value<String>? requestStatus,
      Value<int>? rowid}) {
    return ContactsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      ephemeralPublicKey: ephemeralPublicKey ?? this.ephemeralPublicKey,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isBlocked: isBlocked ?? this.isBlocked,
      requestStatus: requestStatus ?? this.requestStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<String>(identityPublicKey.value);
    }
    if (ephemeralPublicKey.present) {
      map['ephemeral_public_key'] = Variable<String>(ephemeralPublicKey.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (requestStatus.present) {
      map['request_status'] = Variable<String>(requestStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('ephemeralPublicKey: $ephemeralPublicKey, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('requestStatus: $requestStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (id)'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageAtMeta =
      const VerificationMeta('lastMessageAt');
  @override
  late final GeneratedColumn<int> lastMessageAt = GeneratedColumn<int>(
      'last_message_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>('last_message_preview', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        contactId,
        sessionId,
        createdAt,
        lastMessageAt,
        lastMessagePreview,
        unreadCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
          _lastMessageAtMeta,
          lastMessageAt.isAcceptableOrUnknown(
              data['last_message_at']!, _lastMessageAtMeta));
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
          _lastMessagePreviewMeta,
          lastMessagePreview.isAcceptableOrUnknown(
              data['last_message_preview']!, _lastMessagePreviewMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastMessageAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_message_at']),
      lastMessagePreview: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_message_preview']),
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String id;
  final String contactId;
  final String sessionId;
  final int createdAt;
  final int? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  const Conversation(
      {required this.id,
      required this.contactId,
      required this.sessionId,
      required this.createdAt,
      this.lastMessageAt,
      this.lastMessagePreview,
      required this.unreadCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contact_id'] = Variable<String>(contactId);
    map['session_id'] = Variable<String>(sessionId);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(lastMessageAt);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      contactId: Value(contactId),
      sessionId: Value(sessionId),
      createdAt: Value(createdAt),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      unreadCount: Value(unreadCount),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      contactId: serializer.fromJson<String>(json['contactId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastMessageAt: serializer.fromJson<int?>(json['lastMessageAt']),
      lastMessagePreview:
          serializer.fromJson<String?>(json['lastMessagePreview']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contactId': serializer.toJson<String>(contactId),
      'sessionId': serializer.toJson<String>(sessionId),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastMessageAt': serializer.toJson<int?>(lastMessageAt),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'unreadCount': serializer.toJson<int>(unreadCount),
    };
  }

  Conversation copyWith(
          {String? id,
          String? contactId,
          String? sessionId,
          int? createdAt,
          Value<int?> lastMessageAt = const Value.absent(),
          Value<String?> lastMessagePreview = const Value.absent(),
          int? unreadCount}) =>
      Conversation(
        id: id ?? this.id,
        contactId: contactId ?? this.contactId,
        sessionId: sessionId ?? this.sessionId,
        createdAt: createdAt ?? this.createdAt,
        lastMessageAt:
            lastMessageAt.present ? lastMessageAt.value : this.lastMessageAt,
        lastMessagePreview: lastMessagePreview.present
            ? lastMessagePreview.value
            : this.lastMessagePreview,
        unreadCount: unreadCount ?? this.unreadCount,
      );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('unreadCount: $unreadCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, contactId, sessionId, createdAt,
      lastMessageAt, lastMessagePreview, unreadCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.contactId == this.contactId &&
          other.sessionId == this.sessionId &&
          other.createdAt == this.createdAt &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.unreadCount == this.unreadCount);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> contactId;
  final Value<String> sessionId;
  final Value<int> createdAt;
  final Value<int?> lastMessageAt;
  final Value<String?> lastMessagePreview;
  final Value<int> unreadCount;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.contactId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    required String contactId,
    required String sessionId,
    required int createdAt,
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        contactId = Value(contactId),
        sessionId = Value(sessionId),
        createdAt = Value(createdAt);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? contactId,
    Expression<String>? sessionId,
    Expression<int>? createdAt,
    Expression<int>? lastMessageAt,
    Expression<String>? lastMessagePreview,
    Expression<int>? unreadCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contactId != null) 'contact_id': contactId,
      if (sessionId != null) 'session_id': sessionId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? contactId,
      Value<String>? sessionId,
      Value<int>? createdAt,
      Value<int?>? lastMessageAt,
      Value<String?>? lastMessagePreview,
      Value<int>? unreadCount,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(lastMessageAt.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('contactId: $contactId, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES conversations (id)'));
  static const VerificationMeta _senderDeviceIdMeta =
      const VerificationMeta('senderDeviceId');
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
      'sender_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPayloadMeta =
      const VerificationMeta('encryptedPayload');
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
      'encrypted_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sending'));
  static const VerificationMeta _isOutgoingMeta =
      const VerificationMeta('isOutgoing');
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
      'is_outgoing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_outgoing" IN (0, 1))'));
  static const VerificationMeta _attachmentIdMeta =
      const VerificationMeta('attachmentId');
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
      'attachment_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        conversationId,
        senderDeviceId,
        timestamp,
        messageType,
        encryptedPayload,
        status,
        isOutgoing,
        attachmentId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
          _senderDeviceIdMeta,
          senderDeviceId.isAcceptableOrUnknown(
              data['sender_device_id']!, _senderDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    } else if (isInserting) {
      context.missing(_messageTypeMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
          _encryptedPayloadMeta,
          encryptedPayload.isAcceptableOrUnknown(
              data['encrypted_payload']!, _encryptedPayloadMeta));
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
          _isOutgoingMeta,
          isOutgoing.isAcceptableOrUnknown(
              data['is_outgoing']!, _isOutgoingMeta));
    } else if (isInserting) {
      context.missing(_isOutgoingMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
          _attachmentIdMeta,
          attachmentId.isAcceptableOrUnknown(
              data['attachment_id']!, _attachmentIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      senderDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_device_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      encryptedPayload: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isOutgoing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_outgoing'])!,
      attachmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachment_id']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String conversationId;
  final String senderDeviceId;
  final int timestamp;
  final String messageType;
  final String encryptedPayload;
  final String status;
  final bool isOutgoing;
  final String? attachmentId;
  const Message(
      {required this.id,
      required this.conversationId,
      required this.senderDeviceId,
      required this.timestamp,
      required this.messageType,
      required this.encryptedPayload,
      required this.status,
      required this.isOutgoing,
      this.attachmentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    map['timestamp'] = Variable<int>(timestamp);
    map['message_type'] = Variable<String>(messageType);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['status'] = Variable<String>(status);
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    if (!nullToAbsent || attachmentId != null) {
      map['attachment_id'] = Variable<String>(attachmentId);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderDeviceId: Value(senderDeviceId),
      timestamp: Value(timestamp),
      messageType: Value(messageType),
      encryptedPayload: Value(encryptedPayload),
      status: Value(status),
      isOutgoing: Value(isOutgoing),
      attachmentId: attachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentId),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      messageType: serializer.fromJson<String>(json['messageType']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      status: serializer.fromJson<String>(json['status']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      attachmentId: serializer.fromJson<String?>(json['attachmentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'timestamp': serializer.toJson<int>(timestamp),
      'messageType': serializer.toJson<String>(messageType),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'status': serializer.toJson<String>(status),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'attachmentId': serializer.toJson<String?>(attachmentId),
    };
  }

  Message copyWith(
          {String? id,
          String? conversationId,
          String? senderDeviceId,
          int? timestamp,
          String? messageType,
          String? encryptedPayload,
          String? status,
          bool? isOutgoing,
          Value<String?> attachmentId = const Value.absent()}) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        senderDeviceId: senderDeviceId ?? this.senderDeviceId,
        timestamp: timestamp ?? this.timestamp,
        messageType: messageType ?? this.messageType,
        encryptedPayload: encryptedPayload ?? this.encryptedPayload,
        status: status ?? this.status,
        isOutgoing: isOutgoing ?? this.isOutgoing,
        attachmentId:
            attachmentId.present ? attachmentId.value : this.attachmentId,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      status: data.status.present ? data.status.value : this.status,
      isOutgoing:
          data.isOutgoing.present ? data.isOutgoing.value : this.isOutgoing,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('messageType: $messageType, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('status: $status, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('attachmentId: $attachmentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, senderDeviceId, timestamp,
      messageType, encryptedPayload, status, isOutgoing, attachmentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderDeviceId == this.senderDeviceId &&
          other.timestamp == this.timestamp &&
          other.messageType == this.messageType &&
          other.encryptedPayload == this.encryptedPayload &&
          other.status == this.status &&
          other.isOutgoing == this.isOutgoing &&
          other.attachmentId == this.attachmentId);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderDeviceId;
  final Value<int> timestamp;
  final Value<String> messageType;
  final Value<String> encryptedPayload;
  final Value<String> status;
  final Value<bool> isOutgoing;
  final Value<String?> attachmentId;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.messageType = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.status = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String senderDeviceId,
    required int timestamp,
    required String messageType,
    required String encryptedPayload,
    this.status = const Value.absent(),
    required bool isOutgoing,
    this.attachmentId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        conversationId = Value(conversationId),
        senderDeviceId = Value(senderDeviceId),
        timestamp = Value(timestamp),
        messageType = Value(messageType),
        encryptedPayload = Value(encryptedPayload),
        isOutgoing = Value(isOutgoing);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderDeviceId,
    Expression<int>? timestamp,
    Expression<String>? messageType,
    Expression<String>? encryptedPayload,
    Expression<String>? status,
    Expression<bool>? isOutgoing,
    Expression<String>? attachmentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (messageType != null) 'message_type': messageType,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (status != null) 'status': status,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? conversationId,
      Value<String>? senderDeviceId,
      Value<int>? timestamp,
      Value<String>? messageType,
      Value<String>? encryptedPayload,
      Value<String>? status,
      Value<bool>? isOutgoing,
      Value<String?>? attachmentId,
      Value<int>? rowid}) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      status: status ?? this.status,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      attachmentId: attachmentId ?? this.attachmentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('messageType: $messageType, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('status: $status, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES messages (id)'));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileHashMeta =
      const VerificationMeta('fileHash');
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
      'file_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalChunksMeta =
      const VerificationMeta('totalChunks');
  @override
  late final GeneratedColumn<int> totalChunks = GeneratedColumn<int>(
      'total_chunks', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _receivedChunksMeta =
      const VerificationMeta('receivedChunks');
  @override
  late final GeneratedColumn<int> receivedChunks = GeneratedColumn<int>(
      'received_chunks', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        fileName,
        fileSize,
        mimeType,
        localPath,
        fileHash,
        totalChunks,
        receivedChunks,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<Attachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('file_hash')) {
      context.handle(_fileHashMeta,
          fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta));
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('total_chunks')) {
      context.handle(
          _totalChunksMeta,
          totalChunks.isAcceptableOrUnknown(
              data['total_chunks']!, _totalChunksMeta));
    } else if (isInserting) {
      context.missing(_totalChunksMeta);
    }
    if (data.containsKey('received_chunks')) {
      context.handle(
          _receivedChunksMeta,
          receivedChunks.isAcceptableOrUnknown(
              data['received_chunks']!, _receivedChunksMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      fileHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_hash'])!,
      totalChunks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_chunks'])!,
      receivedChunks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}received_chunks'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String messageId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? localPath;
  final String fileHash;
  final int totalChunks;
  final int receivedChunks;
  final String status;
  const Attachment(
      {required this.id,
      required this.messageId,
      required this.fileName,
      required this.fileSize,
      required this.mimeType,
      this.localPath,
      required this.fileHash,
      required this.totalChunks,
      required this.receivedChunks,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['file_name'] = Variable<String>(fileName);
    map['file_size'] = Variable<int>(fileSize);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['file_hash'] = Variable<String>(fileHash);
    map['total_chunks'] = Variable<int>(totalChunks);
    map['received_chunks'] = Variable<int>(receivedChunks);
    map['status'] = Variable<String>(status);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      fileName: Value(fileName),
      fileSize: Value(fileSize),
      mimeType: Value(mimeType),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      fileHash: Value(fileHash),
      totalChunks: Value(totalChunks),
      receivedChunks: Value(receivedChunks),
      status: Value(status),
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      totalChunks: serializer.fromJson<int>(json['totalChunks']),
      receivedChunks: serializer.fromJson<int>(json['receivedChunks']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'fileName': serializer.toJson<String>(fileName),
      'fileSize': serializer.toJson<int>(fileSize),
      'mimeType': serializer.toJson<String>(mimeType),
      'localPath': serializer.toJson<String?>(localPath),
      'fileHash': serializer.toJson<String>(fileHash),
      'totalChunks': serializer.toJson<int>(totalChunks),
      'receivedChunks': serializer.toJson<int>(receivedChunks),
      'status': serializer.toJson<String>(status),
    };
  }

  Attachment copyWith(
          {String? id,
          String? messageId,
          String? fileName,
          int? fileSize,
          String? mimeType,
          Value<String?> localPath = const Value.absent(),
          String? fileHash,
          int? totalChunks,
          int? receivedChunks,
          String? status}) =>
      Attachment(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        localPath: localPath.present ? localPath.value : this.localPath,
        fileHash: fileHash ?? this.fileHash,
        totalChunks: totalChunks ?? this.totalChunks,
        receivedChunks: receivedChunks ?? this.receivedChunks,
        status: status ?? this.status,
      );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      totalChunks:
          data.totalChunks.present ? data.totalChunks.value : this.totalChunks,
      receivedChunks: data.receivedChunks.present
          ? data.receivedChunks.value
          : this.receivedChunks,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('receivedChunks: $receivedChunks, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, fileName, fileSize, mimeType,
      localPath, fileHash, totalChunks, receivedChunks, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.mimeType == this.mimeType &&
          other.localPath == this.localPath &&
          other.fileHash == this.fileHash &&
          other.totalChunks == this.totalChunks &&
          other.receivedChunks == this.receivedChunks &&
          other.status == this.status);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> fileName;
  final Value<int> fileSize;
  final Value<String> mimeType;
  final Value<String?> localPath;
  final Value<String> fileHash;
  final Value<int> totalChunks;
  final Value<int> receivedChunks;
  final Value<String> status;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.receivedChunks = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String messageId,
    required String fileName,
    required int fileSize,
    required String mimeType,
    this.localPath = const Value.absent(),
    required String fileHash,
    required int totalChunks,
    this.receivedChunks = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        messageId = Value(messageId),
        fileName = Value(fileName),
        fileSize = Value(fileSize),
        mimeType = Value(mimeType),
        fileHash = Value(fileHash),
        totalChunks = Value(totalChunks);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? mimeType,
    Expression<String>? localPath,
    Expression<String>? fileHash,
    Expression<int>? totalChunks,
    Expression<int>? receivedChunks,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (localPath != null) 'local_path': localPath,
      if (fileHash != null) 'file_hash': fileHash,
      if (totalChunks != null) 'total_chunks': totalChunks,
      if (receivedChunks != null) 'received_chunks': receivedChunks,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? messageId,
      Value<String>? fileName,
      Value<int>? fileSize,
      Value<String>? mimeType,
      Value<String?>? localPath,
      Value<String>? fileHash,
      Value<int>? totalChunks,
      Value<int>? receivedChunks,
      Value<String>? status,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      fileHash: fileHash ?? this.fileHash,
      totalChunks: totalChunks ?? this.totalChunks,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (totalChunks.present) {
      map['total_chunks'] = Variable<int>(totalChunks.value);
    }
    if (receivedChunks.present) {
      map['received_chunks'] = Variable<int>(receivedChunks.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('localPath: $localPath, ')
          ..write('fileHash: $fileHash, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('receivedChunks: $receivedChunks, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMessagesTable extends PendingMessages
    with TableInfo<$PendingMessagesTable, PendingMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPayloadMeta =
      const VerificationMeta('encryptedPayload');
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
      'encrypted_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
      'next_retry_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, conversationId, encryptedPayload, createdAt, attempts, nextRetryAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_messages';
  @override
  VerificationContext validateIntegrity(Insertable<PendingMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
          _encryptedPayloadMeta,
          encryptedPayload.isAcceptableOrUnknown(
              data['encrypted_payload']!, _encryptedPayloadMeta));
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    } else if (isInserting) {
      context.missing(_nextRetryAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      encryptedPayload: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_retry_at'])!,
    );
  }

  @override
  $PendingMessagesTable createAlias(String alias) {
    return $PendingMessagesTable(attachedDatabase, alias);
  }
}

class PendingMessage extends DataClass implements Insertable<PendingMessage> {
  final String id;
  final String conversationId;
  final String encryptedPayload;
  final int createdAt;
  final int attempts;
  final int nextRetryAt;
  const PendingMessage(
      {required this.id,
      required this.conversationId,
      required this.encryptedPayload,
      required this.createdAt,
      required this.attempts,
      required this.nextRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['created_at'] = Variable<int>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    map['next_retry_at'] = Variable<int>(nextRetryAt);
    return map;
  }

  PendingMessagesCompanion toCompanion(bool nullToAbsent) {
    return PendingMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      encryptedPayload: Value(encryptedPayload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      nextRetryAt: Value(nextRetryAt),
    );
  }

  factory PendingMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMessage(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextRetryAt: serializer.fromJson<int>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'createdAt': serializer.toJson<int>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextRetryAt': serializer.toJson<int>(nextRetryAt),
    };
  }

  PendingMessage copyWith(
          {String? id,
          String? conversationId,
          String? encryptedPayload,
          int? createdAt,
          int? attempts,
          int? nextRetryAt}) =>
      PendingMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        encryptedPayload: encryptedPayload ?? this.encryptedPayload,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      );
  PendingMessage copyWithCompanion(PendingMessagesCompanion data) {
    return PendingMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, conversationId, encryptedPayload, createdAt, attempts, nextRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.encryptedPayload == this.encryptedPayload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.nextRetryAt == this.nextRetryAt);
}

class PendingMessagesCompanion extends UpdateCompanion<PendingMessage> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> encryptedPayload;
  final Value<int> createdAt;
  final Value<int> attempts;
  final Value<int> nextRetryAt;
  final Value<int> rowid;
  const PendingMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String encryptedPayload,
    required int createdAt,
    this.attempts = const Value.absent(),
    required int nextRetryAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        conversationId = Value(conversationId),
        encryptedPayload = Value(encryptedPayload),
        createdAt = Value(createdAt),
        nextRetryAt = Value(nextRetryAt);
  static Insertable<PendingMessage> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? encryptedPayload,
    Expression<int>? createdAt,
    Expression<int>? attempts,
    Expression<int>? nextRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? conversationId,
      Value<String>? encryptedPayload,
      Value<int>? createdAt,
      Value<int>? attempts,
      Value<int>? nextRetryAt,
      Value<int>? rowid}) {
    return PendingMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EncryptionSessionRecordsTable extends EncryptionSessionRecords
    with TableInfo<$EncryptionSessionRecordsTable, EncryptionSessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EncryptionSessionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactDeviceIdMeta =
      const VerificationMeta('contactDeviceId');
  @override
  late final GeneratedColumn<String> contactDeviceId = GeneratedColumn<String>(
      'contact_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionKeyMeta =
      const VerificationMeta('sessionKey');
  @override
  late final GeneratedColumn<String> sessionKey = GeneratedColumn<String>(
      'session_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rotatedAtMeta =
      const VerificationMeta('rotatedAt');
  @override
  late final GeneratedColumn<int> rotatedAt = GeneratedColumn<int>(
      'rotated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _keyVersionMeta =
      const VerificationMeta('keyVersion');
  @override
  late final GeneratedColumn<int> keyVersion = GeneratedColumn<int>(
      'key_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        contactDeviceId,
        sessionKey,
        createdAt,
        rotatedAt,
        keyVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'encryption_session_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<EncryptionSessionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('contact_device_id')) {
      context.handle(
          _contactDeviceIdMeta,
          contactDeviceId.isAcceptableOrUnknown(
              data['contact_device_id']!, _contactDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_contactDeviceIdMeta);
    }
    if (data.containsKey('session_key')) {
      context.handle(
          _sessionKeyMeta,
          sessionKey.isAcceptableOrUnknown(
              data['session_key']!, _sessionKeyMeta));
    } else if (isInserting) {
      context.missing(_sessionKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('rotated_at')) {
      context.handle(_rotatedAtMeta,
          rotatedAt.isAcceptableOrUnknown(data['rotated_at']!, _rotatedAtMeta));
    }
    if (data.containsKey('key_version')) {
      context.handle(
          _keyVersionMeta,
          keyVersion.isAcceptableOrUnknown(
              data['key_version']!, _keyVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  EncryptionSessionRecord map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EncryptionSessionRecord(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      contactDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contact_device_id'])!,
      sessionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      rotatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rotated_at']),
      keyVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key_version'])!,
    );
  }

  @override
  $EncryptionSessionRecordsTable createAlias(String alias) {
    return $EncryptionSessionRecordsTable(attachedDatabase, alias);
  }
}

class EncryptionSessionRecord extends DataClass
    implements Insertable<EncryptionSessionRecord> {
  final String sessionId;
  final String contactDeviceId;
  final String sessionKey;
  final int createdAt;
  final int? rotatedAt;
  final int keyVersion;
  const EncryptionSessionRecord(
      {required this.sessionId,
      required this.contactDeviceId,
      required this.sessionKey,
      required this.createdAt,
      this.rotatedAt,
      required this.keyVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['contact_device_id'] = Variable<String>(contactDeviceId);
    map['session_key'] = Variable<String>(sessionKey);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || rotatedAt != null) {
      map['rotated_at'] = Variable<int>(rotatedAt);
    }
    map['key_version'] = Variable<int>(keyVersion);
    return map;
  }

  EncryptionSessionRecordsCompanion toCompanion(bool nullToAbsent) {
    return EncryptionSessionRecordsCompanion(
      sessionId: Value(sessionId),
      contactDeviceId: Value(contactDeviceId),
      sessionKey: Value(sessionKey),
      createdAt: Value(createdAt),
      rotatedAt: rotatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rotatedAt),
      keyVersion: Value(keyVersion),
    );
  }

  factory EncryptionSessionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EncryptionSessionRecord(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      contactDeviceId: serializer.fromJson<String>(json['contactDeviceId']),
      sessionKey: serializer.fromJson<String>(json['sessionKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      rotatedAt: serializer.fromJson<int?>(json['rotatedAt']),
      keyVersion: serializer.fromJson<int>(json['keyVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'contactDeviceId': serializer.toJson<String>(contactDeviceId),
      'sessionKey': serializer.toJson<String>(sessionKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'rotatedAt': serializer.toJson<int?>(rotatedAt),
      'keyVersion': serializer.toJson<int>(keyVersion),
    };
  }

  EncryptionSessionRecord copyWith(
          {String? sessionId,
          String? contactDeviceId,
          String? sessionKey,
          int? createdAt,
          Value<int?> rotatedAt = const Value.absent(),
          int? keyVersion}) =>
      EncryptionSessionRecord(
        sessionId: sessionId ?? this.sessionId,
        contactDeviceId: contactDeviceId ?? this.contactDeviceId,
        sessionKey: sessionKey ?? this.sessionKey,
        createdAt: createdAt ?? this.createdAt,
        rotatedAt: rotatedAt.present ? rotatedAt.value : this.rotatedAt,
        keyVersion: keyVersion ?? this.keyVersion,
      );
  EncryptionSessionRecord copyWithCompanion(
      EncryptionSessionRecordsCompanion data) {
    return EncryptionSessionRecord(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      contactDeviceId: data.contactDeviceId.present
          ? data.contactDeviceId.value
          : this.contactDeviceId,
      sessionKey:
          data.sessionKey.present ? data.sessionKey.value : this.sessionKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rotatedAt: data.rotatedAt.present ? data.rotatedAt.value : this.rotatedAt,
      keyVersion:
          data.keyVersion.present ? data.keyVersion.value : this.keyVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EncryptionSessionRecord(')
          ..write('sessionId: $sessionId, ')
          ..write('contactDeviceId: $contactDeviceId, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rotatedAt: $rotatedAt, ')
          ..write('keyVersion: $keyVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId, contactDeviceId, sessionKey, createdAt, rotatedAt, keyVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncryptionSessionRecord &&
          other.sessionId == this.sessionId &&
          other.contactDeviceId == this.contactDeviceId &&
          other.sessionKey == this.sessionKey &&
          other.createdAt == this.createdAt &&
          other.rotatedAt == this.rotatedAt &&
          other.keyVersion == this.keyVersion);
}

class EncryptionSessionRecordsCompanion
    extends UpdateCompanion<EncryptionSessionRecord> {
  final Value<String> sessionId;
  final Value<String> contactDeviceId;
  final Value<String> sessionKey;
  final Value<int> createdAt;
  final Value<int?> rotatedAt;
  final Value<int> keyVersion;
  final Value<int> rowid;
  const EncryptionSessionRecordsCompanion({
    this.sessionId = const Value.absent(),
    this.contactDeviceId = const Value.absent(),
    this.sessionKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rotatedAt = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EncryptionSessionRecordsCompanion.insert({
    required String sessionId,
    required String contactDeviceId,
    required String sessionKey,
    required int createdAt,
    this.rotatedAt = const Value.absent(),
    this.keyVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        contactDeviceId = Value(contactDeviceId),
        sessionKey = Value(sessionKey),
        createdAt = Value(createdAt);
  static Insertable<EncryptionSessionRecord> custom({
    Expression<String>? sessionId,
    Expression<String>? contactDeviceId,
    Expression<String>? sessionKey,
    Expression<int>? createdAt,
    Expression<int>? rotatedAt,
    Expression<int>? keyVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (contactDeviceId != null) 'contact_device_id': contactDeviceId,
      if (sessionKey != null) 'session_key': sessionKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rotatedAt != null) 'rotated_at': rotatedAt,
      if (keyVersion != null) 'key_version': keyVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EncryptionSessionRecordsCompanion copyWith(
      {Value<String>? sessionId,
      Value<String>? contactDeviceId,
      Value<String>? sessionKey,
      Value<int>? createdAt,
      Value<int?>? rotatedAt,
      Value<int>? keyVersion,
      Value<int>? rowid}) {
    return EncryptionSessionRecordsCompanion(
      sessionId: sessionId ?? this.sessionId,
      contactDeviceId: contactDeviceId ?? this.contactDeviceId,
      sessionKey: sessionKey ?? this.sessionKey,
      createdAt: createdAt ?? this.createdAt,
      rotatedAt: rotatedAt ?? this.rotatedAt,
      keyVersion: keyVersion ?? this.keyVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (contactDeviceId.present) {
      map['contact_device_id'] = Variable<String>(contactDeviceId.value);
    }
    if (sessionKey.present) {
      map['session_key'] = Variable<String>(sessionKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rotatedAt.present) {
      map['rotated_at'] = Variable<int>(rotatedAt.value);
    }
    if (keyVersion.present) {
      map['key_version'] = Variable<int>(keyVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EncryptionSessionRecordsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('contactDeviceId: $contactDeviceId, ')
          ..write('sessionKey: $sessionKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rotatedAt: $rotatedAt, ')
          ..write('keyVersion: $keyVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $PendingMessagesTable pendingMessages =
      $PendingMessagesTable(this);
  late final $EncryptionSessionRecordsTable encryptionSessionRecords =
      $EncryptionSessionRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        contacts,
        conversations,
        messages,
        attachments,
        pendingMessages,
        encryptionSessionRecords
      ];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  required String id,
  required String deviceId,
  required String displayName,
  required String identityPublicKey,
  required String ephemeralPublicKey,
  Value<String?> avatarPath,
  required int createdAt,
  Value<int?> lastSeenAt,
  Value<bool> isBlocked,
  Value<String> requestStatus,
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<String> id,
  Value<String> deviceId,
  Value<String> displayName,
  Value<String> identityPublicKey,
  Value<String> ephemeralPublicKey,
  Value<String?> avatarPath,
  Value<int> createdAt,
  Value<int?> lastSeenAt,
  Value<bool> isBlocked,
  Value<String> requestStatus,
  Value<int> rowid,
});

class $$ContactsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder> {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ContactsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ContactsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> identityPublicKey = const Value.absent(),
            Value<String> ephemeralPublicKey = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastSeenAt = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<String> requestStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion(
            id: id,
            deviceId: deviceId,
            displayName: displayName,
            identityPublicKey: identityPublicKey,
            ephemeralPublicKey: ephemeralPublicKey,
            avatarPath: avatarPath,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt,
            isBlocked: isBlocked,
            requestStatus: requestStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String deviceId,
            required String displayName,
            required String identityPublicKey,
            required String ephemeralPublicKey,
            Value<String?> avatarPath = const Value.absent(),
            required int createdAt,
            Value<int?> lastSeenAt = const Value.absent(),
            Value<bool> isBlocked = const Value.absent(),
            Value<String> requestStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            id: id,
            deviceId: deviceId,
            displayName: displayName,
            identityPublicKey: identityPublicKey,
            ephemeralPublicKey: ephemeralPublicKey,
            avatarPath: avatarPath,
            createdAt: createdAt,
            lastSeenAt: lastSeenAt,
            isBlocked: isBlocked,
            requestStatus: requestStatus,
            rowid: rowid,
          ),
        ));
}

class $$ContactsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceId => $state.composableBuilder(
      column: $state.table.deviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get identityPublicKey => $state.composableBuilder(
      column: $state.table.identityPublicKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ephemeralPublicKey => $state.composableBuilder(
      column: $state.table.ephemeralPublicKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get avatarPath => $state.composableBuilder(
      column: $state.table.avatarPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastSeenAt => $state.composableBuilder(
      column: $state.table.lastSeenAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isBlocked => $state.composableBuilder(
      column: $state.table.isBlocked,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get requestStatus => $state.composableBuilder(
      column: $state.table.requestStatus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter conversationsRefs(
      ComposableFilter Function($$ConversationsTableFilterComposer f) f) {
    final $$ConversationsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.conversations,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder, parentComposers) =>
            $$ConversationsTableFilterComposer(ComposerState($state.db,
                $state.db.conversations, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceId => $state.composableBuilder(
      column: $state.table.deviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get displayName => $state.composableBuilder(
      column: $state.table.displayName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get identityPublicKey => $state.composableBuilder(
      column: $state.table.identityPublicKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ephemeralPublicKey => $state.composableBuilder(
      column: $state.table.ephemeralPublicKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get avatarPath => $state.composableBuilder(
      column: $state.table.avatarPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastSeenAt => $state.composableBuilder(
      column: $state.table.lastSeenAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isBlocked => $state.composableBuilder(
      column: $state.table.isBlocked,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get requestStatus => $state.composableBuilder(
      column: $state.table.requestStatus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  required String id,
  required String contactId,
  required String sessionId,
  required int createdAt,
  Value<int?> lastMessageAt,
  Value<String?> lastMessagePreview,
  Value<int> unreadCount,
  Value<int> rowid,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<String> id,
  Value<String> contactId,
  Value<String> sessionId,
  Value<int> createdAt,
  Value<int?> lastMessageAt,
  Value<String?> lastMessagePreview,
  Value<int> unreadCount,
  Value<int> rowid,
});

class $$ConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder> {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ConversationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ConversationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> contactId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastMessageAt = const Value.absent(),
            Value<String?> lastMessagePreview = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion(
            id: id,
            contactId: contactId,
            sessionId: sessionId,
            createdAt: createdAt,
            lastMessageAt: lastMessageAt,
            lastMessagePreview: lastMessagePreview,
            unreadCount: unreadCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String contactId,
            required String sessionId,
            required int createdAt,
            Value<int?> lastMessageAt = const Value.absent(),
            Value<String?> lastMessagePreview = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            id: id,
            contactId: contactId,
            sessionId: sessionId,
            createdAt: createdAt,
            lastMessageAt: lastMessageAt,
            lastMessagePreview: lastMessagePreview,
            unreadCount: unreadCount,
            rowid: rowid,
          ),
        ));
}

class $$ConversationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastMessageAt => $state.composableBuilder(
      column: $state.table.lastMessageAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastMessagePreview => $state.composableBuilder(
      column: $state.table.lastMessagePreview,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get unreadCount => $state.composableBuilder(
      column: $state.table.unreadCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $state.db.contacts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ContactsTableFilterComposer(ComposerState(
                $state.db, $state.db.contacts, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter messagesRefs(
      ComposableFilter Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.messages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder, parentComposers) =>
            $$MessagesTableFilterComposer(ComposerState(
                $state.db, $state.db.messages, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastMessageAt => $state.composableBuilder(
      column: $state.table.lastMessageAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastMessagePreview => $state.composableBuilder(
      column: $state.table.lastMessagePreview,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get unreadCount => $state.composableBuilder(
      column: $state.table.unreadCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $state.db.contacts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ContactsTableOrderingComposer(ComposerState(
                $state.db, $state.db.contacts, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String conversationId,
  required String senderDeviceId,
  required int timestamp,
  required String messageType,
  required String encryptedPayload,
  Value<String> status,
  required bool isOutgoing,
  Value<String?> attachmentId,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> conversationId,
  Value<String> senderDeviceId,
  Value<int> timestamp,
  Value<String> messageType,
  Value<String> encryptedPayload,
  Value<String> status,
  Value<bool> isOutgoing,
  Value<String?> attachmentId,
  Value<int> rowid,
});

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MessagesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MessagesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<String> senderDeviceId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<String> encryptedPayload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isOutgoing = const Value.absent(),
            Value<String?> attachmentId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            conversationId: conversationId,
            senderDeviceId: senderDeviceId,
            timestamp: timestamp,
            messageType: messageType,
            encryptedPayload: encryptedPayload,
            status: status,
            isOutgoing: isOutgoing,
            attachmentId: attachmentId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String conversationId,
            required String senderDeviceId,
            required int timestamp,
            required String messageType,
            required String encryptedPayload,
            Value<String> status = const Value.absent(),
            required bool isOutgoing,
            Value<String?> attachmentId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            senderDeviceId: senderDeviceId,
            timestamp: timestamp,
            messageType: messageType,
            encryptedPayload: encryptedPayload,
            status: status,
            isOutgoing: isOutgoing,
            attachmentId: attachmentId,
            rowid: rowid,
          ),
        ));
}

class $$MessagesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get senderDeviceId => $state.composableBuilder(
      column: $state.table.senderDeviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get encryptedPayload => $state.composableBuilder(
      column: $state.table.encryptedPayload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isOutgoing => $state.composableBuilder(
      column: $state.table.isOutgoing,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get attachmentId => $state.composableBuilder(
      column: $state.table.attachmentId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $state.db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ConversationsTableFilterComposer(ComposerState($state.db,
                $state.db.conversations, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter attachmentsRefs(
      ComposableFilter Function($$AttachmentsTableFilterComposer f) f) {
    final $$AttachmentsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.attachments,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder, parentComposers) =>
            $$AttachmentsTableFilterComposer(ComposerState($state.db,
                $state.db.attachments, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get senderDeviceId => $state.composableBuilder(
      column: $state.table.senderDeviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get encryptedPayload => $state.composableBuilder(
      column: $state.table.encryptedPayload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isOutgoing => $state.composableBuilder(
      column: $state.table.isOutgoing,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get attachmentId => $state.composableBuilder(
      column: $state.table.attachmentId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.conversationId,
            referencedTable: $state.db.conversations,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ConversationsTableOrderingComposer(ComposerState($state.db,
                    $state.db.conversations, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String id,
  required String messageId,
  required String fileName,
  required int fileSize,
  required String mimeType,
  Value<String?> localPath,
  required String fileHash,
  required int totalChunks,
  Value<int> receivedChunks,
  Value<String> status,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> messageId,
  Value<String> fileName,
  Value<int> fileSize,
  Value<String> mimeType,
  Value<String?> localPath,
  Value<String> fileHash,
  Value<int> totalChunks,
  Value<int> receivedChunks,
  Value<String> status,
  Value<int> rowid,
});

class $$AttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder> {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AttachmentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AttachmentsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String> fileHash = const Value.absent(),
            Value<int> totalChunks = const Value.absent(),
            Value<int> receivedChunks = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            messageId: messageId,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            localPath: localPath,
            fileHash: fileHash,
            totalChunks: totalChunks,
            receivedChunks: receivedChunks,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String messageId,
            required String fileName,
            required int fileSize,
            required String mimeType,
            Value<String?> localPath = const Value.absent(),
            required String fileHash,
            required int totalChunks,
            Value<int> receivedChunks = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            messageId: messageId,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            localPath: localPath,
            fileHash: fileHash,
            totalChunks: totalChunks,
            receivedChunks: receivedChunks,
            status: status,
            rowid: rowid,
          ),
        ));
}

class $$AttachmentsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fileName => $state.composableBuilder(
      column: $state.table.fileName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get fileSize => $state.composableBuilder(
      column: $state.table.fileSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get mimeType => $state.composableBuilder(
      column: $state.table.mimeType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fileHash => $state.composableBuilder(
      column: $state.table.fileHash,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalChunks => $state.composableBuilder(
      column: $state.table.totalChunks,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get receivedChunks => $state.composableBuilder(
      column: $state.table.receivedChunks,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $state.db.messages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MessagesTableFilterComposer(ComposerState(
                $state.db, $state.db.messages, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fileName => $state.composableBuilder(
      column: $state.table.fileName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get fileSize => $state.composableBuilder(
      column: $state.table.fileSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get mimeType => $state.composableBuilder(
      column: $state.table.mimeType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localPath => $state.composableBuilder(
      column: $state.table.localPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fileHash => $state.composableBuilder(
      column: $state.table.fileHash,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalChunks => $state.composableBuilder(
      column: $state.table.totalChunks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get receivedChunks => $state.composableBuilder(
      column: $state.table.receivedChunks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $state.db.messages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$MessagesTableOrderingComposer(ComposerState(
                $state.db, $state.db.messages, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$PendingMessagesTableCreateCompanionBuilder = PendingMessagesCompanion
    Function({
  required String id,
  required String conversationId,
  required String encryptedPayload,
  required int createdAt,
  Value<int> attempts,
  required int nextRetryAt,
  Value<int> rowid,
});
typedef $$PendingMessagesTableUpdateCompanionBuilder = PendingMessagesCompanion
    Function({
  Value<String> id,
  Value<String> conversationId,
  Value<String> encryptedPayload,
  Value<int> createdAt,
  Value<int> attempts,
  Value<int> nextRetryAt,
  Value<int> rowid,
});

class $$PendingMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingMessagesTable,
    PendingMessage,
    $$PendingMessagesTableFilterComposer,
    $$PendingMessagesTableOrderingComposer,
    $$PendingMessagesTableCreateCompanionBuilder,
    $$PendingMessagesTableUpdateCompanionBuilder> {
  $$PendingMessagesTableTableManager(
      _$AppDatabase db, $PendingMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PendingMessagesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PendingMessagesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<String> encryptedPayload = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int> nextRetryAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingMessagesCompanion(
            id: id,
            conversationId: conversationId,
            encryptedPayload: encryptedPayload,
            createdAt: createdAt,
            attempts: attempts,
            nextRetryAt: nextRetryAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String conversationId,
            required String encryptedPayload,
            required int createdAt,
            Value<int> attempts = const Value.absent(),
            required int nextRetryAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingMessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            encryptedPayload: encryptedPayload,
            createdAt: createdAt,
            attempts: attempts,
            nextRetryAt: nextRetryAt,
            rowid: rowid,
          ),
        ));
}

class $$PendingMessagesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PendingMessagesTable> {
  $$PendingMessagesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get conversationId => $state.composableBuilder(
      column: $state.table.conversationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get encryptedPayload => $state.composableBuilder(
      column: $state.table.encryptedPayload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get nextRetryAt => $state.composableBuilder(
      column: $state.table.nextRetryAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PendingMessagesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PendingMessagesTable> {
  $$PendingMessagesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get conversationId => $state.composableBuilder(
      column: $state.table.conversationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get encryptedPayload => $state.composableBuilder(
      column: $state.table.encryptedPayload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get nextRetryAt => $state.composableBuilder(
      column: $state.table.nextRetryAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$EncryptionSessionRecordsTableCreateCompanionBuilder
    = EncryptionSessionRecordsCompanion Function({
  required String sessionId,
  required String contactDeviceId,
  required String sessionKey,
  required int createdAt,
  Value<int?> rotatedAt,
  Value<int> keyVersion,
  Value<int> rowid,
});
typedef $$EncryptionSessionRecordsTableUpdateCompanionBuilder
    = EncryptionSessionRecordsCompanion Function({
  Value<String> sessionId,
  Value<String> contactDeviceId,
  Value<String> sessionKey,
  Value<int> createdAt,
  Value<int?> rotatedAt,
  Value<int> keyVersion,
  Value<int> rowid,
});

class $$EncryptionSessionRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EncryptionSessionRecordsTable,
    EncryptionSessionRecord,
    $$EncryptionSessionRecordsTableFilterComposer,
    $$EncryptionSessionRecordsTableOrderingComposer,
    $$EncryptionSessionRecordsTableCreateCompanionBuilder,
    $$EncryptionSessionRecordsTableUpdateCompanionBuilder> {
  $$EncryptionSessionRecordsTableTableManager(
      _$AppDatabase db, $EncryptionSessionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$EncryptionSessionRecordsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$EncryptionSessionRecordsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<String> contactDeviceId = const Value.absent(),
            Value<String> sessionKey = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> rotatedAt = const Value.absent(),
            Value<int> keyVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EncryptionSessionRecordsCompanion(
            sessionId: sessionId,
            contactDeviceId: contactDeviceId,
            sessionKey: sessionKey,
            createdAt: createdAt,
            rotatedAt: rotatedAt,
            keyVersion: keyVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            required String contactDeviceId,
            required String sessionKey,
            required int createdAt,
            Value<int?> rotatedAt = const Value.absent(),
            Value<int> keyVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EncryptionSessionRecordsCompanion.insert(
            sessionId: sessionId,
            contactDeviceId: contactDeviceId,
            sessionKey: sessionKey,
            createdAt: createdAt,
            rotatedAt: rotatedAt,
            keyVersion: keyVersion,
            rowid: rowid,
          ),
        ));
}

class $$EncryptionSessionRecordsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $EncryptionSessionRecordsTable> {
  $$EncryptionSessionRecordsTableFilterComposer(super.$state);
  ColumnFilters<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get contactDeviceId => $state.composableBuilder(
      column: $state.table.contactDeviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sessionKey => $state.composableBuilder(
      column: $state.table.sessionKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get rotatedAt => $state.composableBuilder(
      column: $state.table.rotatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get keyVersion => $state.composableBuilder(
      column: $state.table.keyVersion,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$EncryptionSessionRecordsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $EncryptionSessionRecordsTable> {
  $$EncryptionSessionRecordsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get sessionId => $state.composableBuilder(
      column: $state.table.sessionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get contactDeviceId => $state.composableBuilder(
      column: $state.table.contactDeviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sessionKey => $state.composableBuilder(
      column: $state.table.sessionKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get rotatedAt => $state.composableBuilder(
      column: $state.table.rotatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get keyVersion => $state.composableBuilder(
      column: $state.table.keyVersion,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$PendingMessagesTableTableManager get pendingMessages =>
      $$PendingMessagesTableTableManager(_db, _db.pendingMessages);
  $$EncryptionSessionRecordsTableTableManager get encryptionSessionRecords =>
      $$EncryptionSessionRecordsTableTableManager(
          _db, _db.encryptionSessionRecords);
}
