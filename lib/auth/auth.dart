// =============================================================================
// firebase_service.dart
// Firebase Service Layer — Auth, Firestore, Storage, Functions
// SignageOS Enterprise — Clean Architecture
// =============================================================================
// pubspec.yaml dependencies:
//   firebase_core: ^2.32.0
//   firebase_auth: ^4.20.0
//   cloud_firestore: ^4.17.5
//   firebase_storage: ^11.7.7
//   cloud_functions: ^4.7.6
//   flutter_riverpod: ^2.5.1
//   riverpod_annotation: ^2.3.5
//   go_router: ^14.2.7
//   image_picker: ^1.1.2
//   image_picker_for_web: ^3.0.4
//   cached_network_image: ^3.3.1
//   intl: ^0.19.0
// =============================================================================

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// FIRESTORE RULES (paste in Firebase Console)
// =============================================================================
/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isSelf(uid) {
      return request.auth.uid == uid;
    }

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function hasRole(role) {
      return isAuthenticated() && getUserData().roles.hasAny([role]);
    }

    function hasPermission(perm) {
      return isAuthenticated() && getUserData().permissions.hasAny([perm]);
    }

    function isSuperAdmin() {
      return hasRole('super_admin');
    }

    // Users collection
    match /users/{uid} {
      allow read: if isAuthenticated() && (isSelf(uid) || hasPermission('users.view'));
      allow create: if isAuthenticated() && isSuperAdmin();
      allow update: if isAuthenticated() && (isSelf(uid) || hasPermission('users.edit'));
      allow delete: if isSuperAdmin();
    }

    // Roles collection
    match /roles/{roleId} {
      allow read: if isAuthenticated() && hasPermission('roles.view');
      allow write: if isSuperAdmin();
    }

    // Permissions collection
    match /permissions/{permId} {
      allow read: if isAuthenticated();
      allow write: if isSuperAdmin();
    }

    // Notifications collection
    match /notifications/{notifId} {
      allow read: if isAuthenticated() &&
        (resource.data.userId == request.auth.uid || isSuperAdmin());
      allow create: if isAuthenticated() && hasPermission('notifications.send');
      allow update: if isAuthenticated() &&
        resource.data.userId == request.auth.uid;
      allow delete: if isSuperAdmin();
    }
  }
}
*/

// =============================================================================
// 1. DOMAIN MODELS
// =============================================================================

enum AppRole {
  superAdmin('super_admin'),
  admin('admin'),
  manager('manager'),
  editor('editor'),
  user('user');

  final String value;
  const AppRole(this.value);

  static AppRole fromString(String s) =>
      AppRole.values.firstWhere((r) => r.value == s, orElse: () => AppRole.user);

  String get displayName => switch (this) {
        AppRole.superAdmin => 'Super Admin',
        AppRole.admin      => 'Admin',
        AppRole.manager    => 'Manager',
        AppRole.editor     => 'Editor',
        AppRole.user       => 'Usuario',
      };
}

enum AppPermission {
  usersView('users.view'),
  usersCreate('users.create'),
  usersEdit('users.edit'),
  usersDelete('users.delete'),
  rolesView('roles.view'),
  rolesEdit('roles.edit'),
  settingsEdit('settings.edit'),
  notificationsSend('notifications.send');

  final String value;
  const AppPermission(this.value);

  static AppPermission? fromString(String s) {
    try {
      return AppPermission.values.firstWhere((p) => p.value == s);
    } catch (_) {
      return null;
    }
  }
}

// Default permissions per role
const Map<AppRole, List<AppPermission>> kDefaultRolePermissions = {
  AppRole.superAdmin: AppPermission.values,
  AppRole.admin: [
    AppPermission.usersView,
    AppPermission.usersCreate,
    AppPermission.usersEdit,
    AppPermission.rolesView,
    AppPermission.notificationsSend,
  ],
  AppRole.manager: [
    AppPermission.usersView,
    AppPermission.usersEdit,
    AppPermission.rolesView,
    AppPermission.notificationsSend,
  ],
  AppRole.editor: [
    AppPermission.usersView,
    AppPermission.rolesView,
  ],
  AppRole.user: [],
};

// =============================================================================
// USER MODEL
// =============================================================================

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
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  bool get isActive => status == 'active';

  bool hasRole(AppRole role) => roles.contains(role);

  bool hasPermission(AppPermission permission) =>
      roles.contains(AppRole.superAdmin) || permissions.contains(permission);

  bool hasAnyPermission(List<AppPermission> perms) =>
      perms.any(hasPermission);

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    List<AppRole>? roles,
    List<AppPermission>? permissions,
    String? status,
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
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLogin: lastLogin ?? this.lastLogin,
      );

factory AppUser.fromFirestore(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;
  
  List<String> toStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is Map) return val.values.map((e) => e.toString()).toList();
    return [];
  }

  return AppUser(
    uid:      d['uid'] as String? ?? doc.id,
    name:     d['name'] as String? ?? '',
    email:    d['email'] as String? ?? '',
    phone:    d['phone'] as String? ?? '',
    photoUrl: d['photoUrl'] as String?,
    address:  d['address'] as String? ?? '',
    roles: toStringList(d['roles'])
        .map(AppRole.fromString)
        .toList(),
    permissions: toStringList(d['permissions'])
        .map(AppPermission.fromString)
        .whereType<AppPermission>()
        .toList(),
    status:    d['status'] as String? ?? 'active',
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    lastLogin: (d['lastLogin'] as Timestamp?)?.toDate(),
  );
}

  Map<String, dynamic> toFirestore() => {
        'uid':         uid,
        'name':        name,
        'email':       email,
        'phone':       phone,
        'photoUrl':    photoUrl,
        'address':     address,
        'roles':       roles.map((r) => r.value).toList(),
        'permissions': permissions.map((p) => p.value).toList(),
        'status':      status,
        'createdAt':   Timestamp.fromDate(createdAt),
        'updatedAt':   Timestamp.fromDate(updatedAt),
        'lastLogin':   lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
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
    this.metadata = const {},
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
        metadata: metadata,
      );

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id:        doc.id,
      userId:    d['userId'] as String? ?? '',
      title:     d['title'] as String? ?? '',
      body:      d['body'] as String? ?? '',
      type:      NotificationType.values.firstWhere(
          (t) => t.name == (d['type'] as String? ?? 'info'),
          orElse: () => NotificationType.info),
      read:      d['read'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata:  (d['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId':    userId,
        'title':     title,
        'body':      body,
        'type':      type.name,
        'read':      read,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata':  metadata,
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
  final DateTime createdAt;

  const RoleDefinition({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.permissions,
    required this.createdAt,
  });

  factory RoleDefinition.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoleDefinition(
      id:          doc.id,
      name:        d['name'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      description: d['description'] as String? ?? '',
      permissions: ((d['permissions'] as List<dynamic>?) ?? [])
          .map((p) => AppPermission.fromString(p as String))
          .whereType<AppPermission>()
          .toList(),
      createdAt:   (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':        name,
        'displayName': displayName,
        'description': description,
        'permissions': permissions.map((p) => p.value).toList(),
        'createdAt':   Timestamp.fromDate(createdAt),
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

// =============================================================================
// 3. FIREBASE SERVICE
// =============================================================================


  class FirebaseService {
  // ← NUEVO: flag para pausar el redirect de auth
  static bool suppressAuthRedirect = false;

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  // ... resto igual

  final FirebaseFirestore _db        = FirebaseFirestore.instance;
  final FirebaseStorage   _storage   = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ── Shortcuts ─────────────────────────────────────────────────────────────
  CollectionReference get _users         => _db.collection('users');
  CollectionReference get _roles         => _db.collection('roles');
  CollectionReference get _notifications => _db.collection('notifications');

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateStream => _auth.authStateChanges();

  // =========================================================================
  // AUTH
  // =========================================================================
Future<Result<AppUser>> createUserAsAdmin({
  required String name,
  required String email,
  required String password,
  AppRole role = AppRole.user,
}) async {
  final adminUser = _auth.currentUser;
  if (adminUser == null) return const Failure('No hay sesión activa.');

  FirebaseApp? secondaryApp;

  try {
    // ← Pausar redirect mientras creamos el usuario
    FirebaseService.suppressAuthRedirect = true;

    final appName = 'secondary_${DateTime.now().millisecondsSinceEpoch}';
    secondaryApp = await Firebase.initializeApp(
      name:    appName,
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email:    email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());

    final uid   = cred.user!.uid;
    final now   = DateTime.now();
    final perms = kDefaultRolePermissions[role] ?? [];

    final appUser = AppUser(
      uid:         uid,
      name:        name.trim(),
      email:       email.trim(),
      roles:       [role],
      permissions: perms,
      createdAt:   now,
      updatedAt:   now,
    );

    await _db.collection('users').doc(uid).set(appUser.toFirestore());
    await secondaryAuth.signOut();
    await secondaryApp.delete();
    secondaryApp = null;

    return Success(appUser);

  } on FirebaseAuthException catch (e) {
    await secondaryApp?.delete();
    return Failure(_authErrorMessage(e.code));
  } catch (e) {
    await secondaryApp?.delete();
    return Failure('Error al crear usuario: $e');
  } finally {
    // ← Siempre reactivar el redirect
    FirebaseService.suppressAuthRedirect = false;
  }
}
  
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await _users.doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return const Failure('Cuenta no encontrada en el sistema.');
      }

      final appUser = AppUser.fromFirestore(doc);
      if (!appUser.isActive) {
        await _auth.signOut();
        return const Failure('Esta cuenta ha sido desactivada.');
      }

      // Update lastLogin
      await _users.doc(cred.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return Success(appUser);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error inesperado al iniciar sesión.', error: e);
    }
  }

  /// Register new account + create Firestore profile.
  Future<Result<AppUser>> register({
    required String name,
    required String email,
    required String password,
    AppRole role = AppRole.user,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user!.updateDisplayName(name.trim());

      final permissions = kDefaultRolePermissions[role] ?? [];
      final now = DateTime.now();

      final appUser = AppUser(
        uid:         cred.user!.uid,
        name:        name.trim(),
        email:       email.trim(),
        roles:       [role],
        permissions: permissions,
        createdAt:   now,
        updatedAt:   now,
      );

      await _users.doc(cred.user!.uid).set(appUser.toFirestore());

      // Send welcome email via Cloud Function
      await _sendWelcomeEmail(name: name.trim(), email: email.trim());

      return Success(appUser);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error al crear la cuenta.', error: e);
    }
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('No se pudo enviar el email de recuperación.', error: e);
    }
  }

  /// Re-authenticate before sensitive operations.
  Future<Result<void>> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error de re-autenticación.', error: e);
    }
  }

  /// Change password (requires re-auth first).
  Future<Result<void>> changePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);

      // Notify via Cloud Function
      final user = _auth.currentUser!;
      await _sendPasswordChangedEmail(
        email: user.email ?? '',
        name: user.displayName ?? '',
      );

      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error al cambiar contraseña.', error: e);
    }
  }

  // =========================================================================
  // USER PROFILE
  // =========================================================================

  /// Fetch current user profile from Firestore.
  Future<Result<AppUser>> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Failure('No hay sesión activa.');
    return fetchUser(uid);
  }

  /// Fetch any user profile.
  Future<Result<AppUser>> fetchUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return const Failure('Usuario no encontrado.');
      return Success(AppUser.fromFirestore(doc));
    } catch (e) {
      return Failure('Error al obtener perfil.', error: e);
    }
  }

  /// Stream of current user (real-time).
  Stream<AppUser?> currentUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  /// Update user profile fields.
  Future<Result<AppUser>> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name     != null) updates['name']     = name.trim();
      if (phone    != null) updates['phone']    = phone.trim();
      if (address  != null) updates['address']  = address.trim();
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _users.doc(uid).update(updates);

      // Also update Firebase Auth display name
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name.trim());
      }

      return fetchUser(uid);
    } catch (e) {
      return Failure('Error al actualizar perfil.', error: e);
    }
  }

  /// Upload profile photo to Firebase Storage, return download URL.
  Future<Result<String>> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final ext  = filename.split('.').last.toLowerCase();
      final ref  = _storage.ref('profile_photos/$uid/avatar.$ext');
      final meta = SettableMetadata(contentType: 'image/$ext');

      await ref.putData(bytes, meta);
      final url = await ref.getDownloadURL();
      return Success(url);
    } catch (e) {
      return Failure('Error al subir foto.', error: e);
    }
  }

  // =========================================================================
  // USERS (admin)
  // =========================================================================

  /// Stream all users (paginated via query snapshot).
Stream<List<AppUser>> allUsersStream() {
  return _users.snapshots().map((snap) {
    final list = snap.docs.map(AppUser.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
}
  /// Update user roles.
  Future<Result<void>> updateUserRoles({
    required String uid,
    required List<AppRole> roles,
  }) async {
    try {
      // Rebuild permissions from roles union
      final perms = roles
          .expand((r) => kDefaultRolePermissions[r] ?? <AppPermission>[])
          .toSet()
          .toList();

      await _users.doc(uid).update({
        'roles':       roles.map((r) => r.value).toList(),
        'permissions': perms.map((p) => p.value).toList(),
        'updatedAt':   FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar roles.', error: e);
    }
  }

  /// Update user status.
  Future<Result<void>> updateUserStatus({
    required String uid,
    required String status,
  }) async {
    try {
      await _users.doc(uid).update({
        'status':    status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar estado.', error: e);
    }
  }

  // =========================================================================
  // ROLES
  // =========================================================================

 Stream<List<RoleDefinition>> rolesStream() {
  return _roles.snapshots().map((s) {
    if (s.docs.isEmpty) {
      // Devuelve roles por defecto en memoria si Firestore está vacío
      return AppRole.values.map((role) => RoleDefinition(
        id: role.value,
        name: role.value,
        displayName: role.displayName,
        description: 'Rol predeterminado: ${role.displayName}',
        permissions: kDefaultRolePermissions[role] ?? [],
        createdAt: DateTime.now(),
      )).toList();
    }
    final list = s.docs.map(RoleDefinition.fromFirestore).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  });
}
  Future<Result<void>> createRole(RoleDefinition role) async {
    try {
      await _roles.add(role.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Error al crear rol.', error: e);
    }
  }

  Future<Result<void>> updateRole(RoleDefinition role) async {
    try {
      await _roles.doc(role.id).update(role.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar rol.', error: e);
    }
  }

  Future<Result<void>> deleteRole(String roleId) async {
    try {
      await _roles.doc(roleId).delete();
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar rol.', error: e);
    }
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  /// Stream of notifications for a specific user.
Stream<List<AppNotification>> notificationsStream(String userId) {
  return _notifications
      .where('userId', isEqualTo: userId)
      .limit(50)
      .snapshots()
      .map((s) {
        final list = s.docs.map(AppNotification.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
}

  /// Unread count stream.
 Stream<int> unreadCountStream(String userId) {
  return _notifications
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs
          .where((d) => (d.data() as Map<String, dynamic>)['read'] == false)
          .length);
}
  /// Create a notification.
  Future<Result<void>> createNotification(AppNotification notification) async {
    try {
      await _notifications.add(notification.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Error al crear notificación.', error: e);
    }
  }

  /// Mark single notification as read.
  Future<Result<void>> markNotificationRead(String notifId) async {
    try {
      await _notifications.doc(notifId).update({'read': true});
      return const Success(null);
    } catch (e) {
      return Failure('Error al marcar notificación.', error: e);
    }
  }

  /// Mark all notifications as read.
  Future<Result<void>> markAllNotificationsRead(String userId) async {
    try {
      final snap = await _notifications
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure('Error al marcar todas las notificaciones.', error: e);
    }
  }

  /// Delete notification.
  Future<Result<void>> deleteNotification(String notifId) async {
    try {
      await _notifications.doc(notifId).delete();
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar notificación.', error: e);
    }
  }

  // =========================================================================
  // CLOUD FUNCTIONS — Email Notifications
  // =========================================================================

  Future<void> _sendWelcomeEmail({
    required String name,
    required String email,
  }) async {
    try {
      await _functions
          .httpsCallable('sendWelcomeEmail')
          .call({'name': name, 'email': email});
    } catch (e) {
      print('[FirebaseService] sendWelcomeEmail error: $e');
    }
  }

  Future<void> _sendPasswordChangedEmail({
    required String name,
    required String email,
  }) async {
    try {
      await _functions
          .httpsCallable('sendPasswordChangedEmail')
          .call({'name': name, 'email': email});
    } catch (e) {
      print('[FirebaseService] sendPasswordChangedEmail error: $e');
    }
  }

  Future<Result<void>> sendSystemEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      await _functions
          .httpsCallable('sendSystemEmail')
          .call({'to': to, 'subject': subject, 'body': body});
      return const Success(null);
    } catch (e) {
      return Failure('Error al enviar email.', error: e);
    }
  }

  // =========================================================================
  // CLOUD FUNCTION SOURCE (deploy separately)
  // =========================================================================
  /*
  // functions/index.js — Firebase Functions v2
  const {onCall} = require('firebase-functions/v2/https');
  const nodemailer = require('nodemailer');
  const admin = require('firebase-admin');
  admin.initializeApp();

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  exports.sendWelcomeEmail = onCall(async (request) => {
    const {name, email} = request.data;
    await transporter.sendMail({
      from: `"SignageOS" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Bienvenido a SignageOS Enterprise',
      html: `<h1>¡Hola ${name}!</h1><p>Tu cuenta ha sido creada exitosamente.</p>`,
    });
  });

  exports.sendPasswordChangedEmail = onCall(async (request) => {
    const {name, email} = request.data;
    await transporter.sendMail({
      from: `"SignageOS" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Contraseña actualizada',
      html: `<h1>Hola ${name}</h1><p>Tu contraseña fue cambiada exitosamente.</p>`,
    });
  });

  exports.sendSystemEmail = onCall(async (request) => {
    const {to, subject, body} = request.data;
    await transporter.sendMail({
      from: `"SignageOS" <${process.env.EMAIL_USER}>`,
      to, subject,
      html: body,
    });
  });
  */

  // =========================================================================
  // HELPERS
  // =========================================================================

  String _authErrorMessage(String code) => switch (code) {
        'user-not-found'        => 'No existe una cuenta con ese email.',
        'wrong-password'        => 'Contraseña incorrecta.',
        'email-already-in-use'  => 'Este email ya está registrado.',
        'weak-password'         => 'La contraseña debe tener al menos 6 caracteres.',
        'invalid-email'         => 'El formato del email no es válido.',
        'too-many-requests'     => 'Demasiados intentos. Intenta más tarde.',
        'user-disabled'         => 'Esta cuenta ha sido desactivada.',
        'invalid-credential'    => 'Credenciales inválidas.',
        'network-request-failed'=> 'Error de conexión. Verifica tu internet.',
        'requires-recent-login' => 'Debes iniciar sesión nuevamente para esta acción.',
        _                       => 'Error de autenticación ($code).',
      };

  /// Initialize default roles in Firestore (run once).
  Future<void> seedDefaultRoles() async {
    final snap = await _roles.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final role in AppRole.values) {
      final ref = _roles.doc(role.value);
      batch.set(ref, RoleDefinition(
        id:          role.value,
        name:        role.value,
        displayName: role.displayName,
        description: 'Rol predeterminado: ${role.displayName}',
        permissions: kDefaultRolePermissions[role] ?? [],
        createdAt:   DateTime.now(),
      ).toFirestore());
    }
    await batch.commit();
  }
}

// =============================================================================
// 4. PROVIDERS (Riverpod)
// =============================================================================

final firebaseServiceProvider = Provider<FirebaseService>(
  (_) => FirebaseService(),
);

// Auth state stream — fires whenever auth changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseServiceProvider).authStateStream;
});

// Current AppUser stream (real-time Firestore)
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref.read(firebaseServiceProvider).currentUserStream();
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Convenience getter — throws if not logged in
final requireUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return user;
});

// Notifications stream
final notificationsProvider = StreamProvider.family<List<AppNotification>, String>(
  (ref, userId) =>
      ref.read(firebaseServiceProvider).notificationsStream(userId),
);

// Unread count
final unreadCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.read(firebaseServiceProvider).unreadCountStream(userId),
);

// All users stream (admin)
final allUsersProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.read(firebaseServiceProvider).allUsersStream(),
);

// Roles stream
final rolesProvider = StreamProvider<List<RoleDefinition>>(
  (ref) => ref.read(firebaseServiceProvider).rolesStream(),
);

// Permission check helper
final permissionCheckerProvider = Provider.family<bool, AppPermission>((ref, permission) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.hasPermission(permission) ?? false;
});