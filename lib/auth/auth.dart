import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// COMPANY MODEL
// =============================================================================

class Company {
  final String id;
  final String name;
  final String legalName;
  final String email;
  final String phone;
  final String address;
  final String? logoUrl;
  final String status; // active | inactive | suspended
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    required this.legalName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.logoUrl,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: d['name'] as String? ?? '',
      legalName: d['legalName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      address: d['address'] as String? ?? '',
      logoUrl: d['logoUrl'] as String?,
      status: d['status'] as String? ?? 'active',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'legalName': legalName,
        'email': email,
        'phone': phone,
        'address': address,
        'logoUrl': logoUrl,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

// Default permissions per role
const Map<AppRole, List<AppPermission>> kDefaultRolePermissions = {
  AppRole.superAdmin: AppPermission.values,
  AppRole.companyAdmin: [
    AppPermission.usersView,
    AppPermission.usersCreate,
    AppPermission.usersEdit,
    AppPermission.usersDelete,
    AppPermission.rolesView,
    AppPermission.rolesCreate,
    AppPermission.rolesEdit,
    AppPermission.rolesDelete,
    AppPermission.notificationsSend,
    AppPermission.reportsView,
    AppPermission.dashboardCompany,
  ],
  AppRole.manager: [
    AppPermission.usersView,
    AppPermission.usersEdit,
    AppPermission.rolesView,
    AppPermission.notificationsSend,
    AppPermission.reportsView,
    AppPermission.dashboardCompany,
  ],
  AppRole.editor: [
    AppPermission.usersView,
    AppPermission.rolesView,
    AppPermission.dashboardCompany,
  ],
  AppRole.user: [
    AppPermission.dashboardCompany,
  ],
};

// =============================================================================
// USER MODEL
// =============================================================================
// ── core/firestore_utils.dart ────────────────────────────────────────────────

/// Convierte un campo Firestore (List, Map o null) a List<String>.
List<String> firestoreToStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is Map) return value.values.map((e) => e.toString()).toList();
  return const [];
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String address;
  final List<AppRole> roles;
  final List<AppPermission> permissions;
  final String status; // active | inactive | suspended
  final String? companyId; // null solo para superAdmin
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl,
    this.address = '',
    required this.roles,
    required this.permissions,
    this.status = 'active',
    this.companyId,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  bool get isActive => status == 'active';
  bool get isSuperAdmin => roles.contains(AppRole.superAdmin);
  bool get isCompanyAdmin => roles.contains(AppRole.companyAdmin);

  bool hasRole(AppRole role) => roles.contains(role);

  bool hasPermission(AppPermission permission) =>
      roles.contains(AppRole.superAdmin) || permissions.contains(permission);

  bool hasAnyPermission(List<AppPermission> perms) => perms.any(hasPermission);

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    List<AppRole>? roles,
    List<AppPermission>? permissions,
    String? status,
    String? companyId,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) =>
      AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        address: address ?? this.address,
        roles: roles ?? this.roles,
        permissions: permissions ?? this.permissions,
        status: status ?? this.status,
        companyId: companyId ?? this.companyId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLogin: lastLogin ?? this.lastLogin,
      );

// ── models/app_user.dart — factory AppUser.fromFirestore actualizado ─────────

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: d['uid'] as String? ?? doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      address: d['address'] as String? ?? '',
      roles: firestoreToStringList(d['roles']).map(AppRole.fromString).toList(),
      permissions: firestoreToStringList(d['permissions'])
          .map(AppPermission.fromString)
          .whereType<AppPermission>()
          .toList(),
      status: d['status'] as String? ?? 'active',
      companyId: d['companyId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (d['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'address': address,
        'roles': roles.map((r) => r.value).toList(),
        'permissions': permissions.map((p) => p.value).toList(),
        'status': status,
        'companyId': companyId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      };
}

// =============================================================================
// NOTIFICATION MODEL
// =============================================================================

enum NotificationType {
  info,
  success,
  warning,
  error,
  system;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.info,
    this.read = false,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
        metadata: Map.unmodifiable(metadata),
      );

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (d['type'] as String? ?? 'info'),
        orElse: () => NotificationType.info,
      ),
      read: d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata:
          Map.unmodifiable((d['metadata'] as Map<String, dynamic>?) ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
      };
}

// =============================================================================
// ROLE MODEL (Firestore roles collection)
// =============================================================================

class RoleDefinition {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final List<AppPermission> permissions;
  final String? companyId;
  final DateTime createdAt;

  const RoleDefinition({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.permissions,
    this.companyId,
    required this.createdAt,
  });

  factory RoleDefinition.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoleDefinition(
      id: doc.id,
      name: d['name'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      description: d['description'] as String? ?? '',
      permissions: ((d['permissions'] as List<dynamic>?) ?? [])
          .map((p) => AppPermission.fromString(p as String))
          .whereType<AppPermission>()
          .toList(),
      companyId: d['companyId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'displayName': displayName,
        'description': description,
        'permissions': permissions.map((p) => p.value).toList(),
        'companyId': companyId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// =============================================================================
// 2. RESULT TYPE
// =============================================================================

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, {this.error});
}
