// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, admin, editor, viewer }

extension UserRoleExt on UserRole {
  String get name {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.editor:
        return 'EDITOR';
      case UserRole.viewer:
        return 'VIEWER';
    }
  }

  bool get canManageDevices =>
      this == UserRole.superAdmin || this == UserRole.admin;
  bool get canManageContent => this != UserRole.viewer;
  bool get canAssignContent =>
      this == UserRole.superAdmin || this == UserRole.admin;
  bool get canManageUsers => this == UserRole.superAdmin;
  bool get canViewAnalytics =>
      this == UserRole.superAdmin || this == UserRole.admin;
  bool get canDeleteResources => this == UserRole.superAdmin;

  static UserRole fromString(String s) {
    switch (s) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'EDITOR':
        return UserRole.editor;
      default:
        return UserRole.viewer;
    }
  }
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  @override
  List<Object?> get props => [id, email, role];
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/entities/device_entity.dart

enum DeviceStatus { online, offline, warning }

class DeviceEntity extends Equatable {
  final String id;
  final String name;
  final String uniqueDeviceId;
  final DeviceStatus status;
  final String? groupId;
  final String? groupName;
  final DateTime lastSeen;
  final String? currentContentId;
  final String? currentContentName;
  final DeviceMetadata metadata;

  const DeviceEntity({
    required this.id,
    required this.name,
    required this.uniqueDeviceId,
    required this.status,
    this.groupId,
    this.groupName,
    required this.lastSeen,
    this.currentContentId,
    this.currentContentName,
    required this.metadata,
  });

  bool get isOnline => status == DeviceStatus.online;

  @override
  List<Object?> get props => [id, uniqueDeviceId, status];
}

class DeviceMetadata extends Equatable {
  final String? ipAddress;
  final String? androidVersion;
  final String? appVersion;
  final String? resolution;

  const DeviceMetadata({
    this.ipAddress,
    this.androidVersion,
    this.appVersion,
    this.resolution,
  });

  @override
  List<Object?> get props => [ipAddress, androidVersion];
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/entities/content_entity.dart

enum ContentType { image, video, text, playlist }

class ContentEntity extends Equatable {
  final String id;
  final String name;
  final ContentType type;
  final String? url;
  final String? textContent;
  final Duration duration;
  final DateTime createdAt;
  final String ownerId;
  final List<String> tags;
  final List<String>? playlistItemIds; // for playlist type

  const ContentEntity({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.textContent,
    required this.duration,
    required this.createdAt,
    required this.ownerId,
    required this.tags,
    this.playlistItemIds,
  });

  @override
  List<Object?> get props => [id, type, name];
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/entities/group_entity.dart

class GroupEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int deviceCount;

  const GroupEntity({
    required this.id,
    required this.name,
    this.description,
    required this.deviceCount,
  });

  @override
  List<Object?> get props => [id, name];
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/entities/assignment_entity.dart

enum AssignmentTarget { global, group, device }

class AssignmentEntity extends Equatable {
  final String id;
  final AssignmentTarget targetType;
  final String? tvId;
  final String? groupId;
  final String contentId;
  final String contentName;
  final int priority;
  final bool active;
  final DateTime createdAt;

  const AssignmentEntity({
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

  @override
  List<Object?> get props => [id, targetType, contentId];
}
