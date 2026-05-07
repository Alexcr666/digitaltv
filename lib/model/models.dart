// lib/data/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/entities/entities.dart';


// ── USER MODEL ────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final Timestamp createdAt;
  final Timestamp? lastLogin;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: d['email'] ?? '',
      displayName: d['displayName'] ?? '',
      role: d['role'] ?? 'VIEWER',
      createdAt: d['createdAt'] ?? Timestamp.now(),
      lastLogin: d['lastLogin'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'role': role,
    'createdAt': createdAt,
    'lastLogin': lastLogin,
  };

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    displayName: displayName,
    role: UserRoleExt.fromString(role),
    createdAt: createdAt.toDate(),
    lastLogin: lastLogin?.toDate(),
  );
}

// ── DEVICE MODEL ─────────────────────────────────────────────────────────────

class DeviceModel {
  final String id;
  final String name;
  final String uniqueDeviceId;
  final String status;
  final String? groupId;
  final Timestamp lastSeen;
  final String? currentContentId;
  final Map<String, dynamic> metadata;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.uniqueDeviceId,
    required this.status,
    this.groupId,
    required this.lastSeen,
    this.currentContentId,
    required this.metadata,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: d['name'] ?? '',
      uniqueDeviceId: d['uniqueDeviceId'] ?? '',
      status: d['status'] ?? 'offline',
      groupId: d['groupId'],
      lastSeen: d['lastSeen'] ?? Timestamp.now(),
      currentContentId: d['currentContentId'],
      metadata: Map<String, dynamic>.from(d['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'uniqueDeviceId': uniqueDeviceId,
    'status': status,
    'groupId': groupId,
    'lastSeen': lastSeen,
    'currentContentId': currentContentId,
    'metadata': metadata,
  };

  DeviceEntity toEntity() => DeviceEntity(
    id: id,
    name: name,
    uniqueDeviceId: uniqueDeviceId,
    status: _parseStatus(status),
    groupId: groupId,
    lastSeen: lastSeen.toDate(),
    currentContentId: currentContentId,
    metadata: DeviceMetadata(
      ipAddress: metadata['ipAddress'],
      androidVersion: metadata['androidVersion'],
      appVersion: metadata['appVersion'],
      resolution: metadata['resolution'],
    ),
  );

  static DeviceStatus _parseStatus(String s) {
    switch (s) {
      case 'online':  return DeviceStatus.online;
      case 'warning': return DeviceStatus.warning;
      default:        return DeviceStatus.offline;
    }
  }
}

// ── CONTENT MODEL ─────────────────────────────────────────────────────────────

class ContentModel {
  final String id;
  final String name;
  final String type;
  final String? url;
  final String? textContent;
  final int durationSeconds;
  final Timestamp createdAt;
  final String ownerId;
  final List<String> tags;
  final List<String>? playlistItemIds;

  const ContentModel({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.textContent,
    required this.durationSeconds,
    required this.createdAt,
    required this.ownerId,
    required this.tags,
    this.playlistItemIds,
  });

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      name: d['name'] ?? '',
      type: d['type'] ?? 'image',
      url: d['url'],
      textContent: d['textContent'],
      durationSeconds: d['durationSeconds'] ?? 10,
      createdAt: d['createdAt'] ?? Timestamp.now(),
      ownerId: d['ownerId'] ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      playlistItemIds: d['playlistItemIds'] != null
          ? List<String>.from(d['playlistItemIds'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'url': url,
    'textContent': textContent,
    'durationSeconds': durationSeconds,
    'createdAt': createdAt,
    'ownerId': ownerId,
    'tags': tags,
    'playlistItemIds': playlistItemIds,
  };

  ContentEntity toEntity() => ContentEntity(
    id: id,
    name: name,
    type: _parseType(type),
    url: url,
    textContent: textContent,
    duration: Duration(seconds: durationSeconds),
    createdAt: createdAt.toDate(),
    ownerId: ownerId,
    tags: tags,
    playlistItemIds: playlistItemIds,
  );

  static ContentType _parseType(String t) {
    switch (t) {
      case 'video':    return ContentType.video;
      case 'text':     return ContentType.text;
      case 'playlist': return ContentType.playlist;
      default:         return ContentType.image;
    }
  }
}

// ── ASSIGNMENT MODEL ──────────────────────────────────────────────────────────

class AssignmentModel {
  final String id;
  final String targetType;
  final String? tvId;
  final String? groupId;
  final String contentId;
  final String contentName;
  final int priority;
  final bool active;
  final Timestamp createdAt;

  const AssignmentModel({
    required this.id,
    required this.targetType,
    this.tvId,
    this.groupId,
    required this.contentId,
    required this.contentName,
    required this.priority,
    required this.active,
    required this.createdAt,
  });

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      targetType: d['targetType'] ?? 'global',
      tvId: d['tvId'],
      groupId: d['groupId'],
      contentId: d['contentId'] ?? '',
      contentName: d['contentName'] ?? '',
      priority: d['priority'] ?? 3,
      active: d['active'] ?? true,
      createdAt: d['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'targetType': targetType,
    'tvId': tvId,
    'groupId': groupId,
    'contentId': contentId,
    'contentName': contentName,
    'priority': priority,
    'active': active,
    'createdAt': createdAt,
  };

  AssignmentEntity toEntity() => AssignmentEntity(
    id: id,
    targetType: _parseTarget(targetType),
    tvId: tvId,
    groupId: groupId,
    contentId: contentId,
    contentName: contentName,
    priority: priority,
    active: active,
    createdAt: createdAt.toDate(),
  );

  static AssignmentTarget _parseTarget(String t) {
    switch (t) {
      case 'device': return AssignmentTarget.device;
      case 'group':  return AssignmentTarget.group;
      default:       return AssignmentTarget.global;
    }
  }
}