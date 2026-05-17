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
  companyAdmin('company_admin'),
  manager('manager'),
  editor('editor'),
  user('user');

  final String value;
  const AppRole(this.value);

  static AppRole fromString(String s) =>
      AppRole.values.firstWhere((r) => r.value == s, orElse: () => AppRole.user);

  String get displayName => switch (this) {
        AppRole.superAdmin   => 'Super Admin',
        AppRole.companyAdmin => 'Admin Empresa',
        AppRole.manager      => 'Manager',
        AppRole.editor       => 'Editor',
        AppRole.user         => 'Usuario',
      };
}
enum AppPermission {
  // Empresas (solo superAdmin)
  companiesView('companies.view'),
  companiesCreate('companies.create'),
  companiesEdit('companies.edit'),
  companiesDelete('companies.delete'),

  // Usuarios
  usersView('users.view'),
  usersCreate('users.create'),
  usersEdit('users.edit'),
  usersDelete('users.delete'),

  // Roles
  rolesView('roles.view'),
  rolesCreate('roles.create'),
  rolesEdit('roles.edit'),
  rolesDelete('roles.delete'),

  // Notificaciones
  notificationsSend('notifications.send'),

  // Configuración
  settingsEdit('settings.edit'),

  // Reportes / Analytics
  reportsView('reports.view'),

  // Dashboard global (solo superAdmin)
  dashboardGlobal('dashboard.global'),

  // Dashboard empresa
  dashboardCompany('dashboard.company');

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
      id:        doc.id,
      name:      d['name'] as String? ?? '',
      legalName: d['legalName'] as String? ?? '',
      email:     d['email'] as String? ?? '',
      phone:     d['phone'] as String? ?? '',
      address:   d['address'] as String? ?? '',
      logoUrl:   d['logoUrl'] as String?,
      status:    d['status'] as String? ?? 'active',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':      name,
        'legalName': legalName,
        'email':     email,
        'phone':     phone,
        'address':   address,
        'logoUrl':   logoUrl,
        'status':    status,
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

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String address;
  final List<AppRole> roles;
  final List<AppPermission> permissions;
  final String status;       // active | inactive | suspended
  final String? companyId;   // null solo para superAdmin
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

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    List<String> toStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is Map) return val.values.map((e) => e.toString()).toList();
      return [];
    }

    return AppUser(
      uid:       d['uid'] as String? ?? doc.id,
      name:      d['name'] as String? ?? '',
      email:     d['email'] as String? ?? '',
      phone:     d['phone'] as String? ?? '',
      photoUrl:  d['photoUrl'] as String?,
      address:   d['address'] as String? ?? '',
      roles: toStringList(d['roles'])
          .map(AppRole.fromString)
          .toList(),
      permissions: toStringList(d['permissions'])
          .map(AppPermission.fromString)
          .whereType<AppPermission>()
          .toList(),
      status:    d['status'] as String? ?? 'active',
      companyId: d['companyId'] as String?,
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
        'companyId':   companyId,
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
      id:          doc.id,
      name:        d['name'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      description: d['description'] as String? ?? '',
      permissions: ((d['permissions'] as List<dynamic>?) ?? [])
          .map((p) => AppPermission.fromString(p as String))
          .whereType<AppPermission>()
          .toList(),
      companyId:   d['companyId'] as String?,
      createdAt:   (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':        name,
        'displayName': displayName,
        'description': description,
        'permissions': permissions.map((p) => p.value).toList(),
        'companyId':   companyId,
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
  static bool suppressAuthRedirect = false;

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _db        = FirebaseFirestore.instance;
  final FirebaseStorage   _storage   = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference get _users         => _db.collection('users');
  CollectionReference get _roles         => _db.collection('roles');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _companies     => _db.collection('companies');

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateStream => _auth.authStateChanges();

  // =========================================================================
  // SEED: Superadmin por defecto
  // =========================================================================

  /// Llama esto en main() después de Firebase.initializeApp()
  Future<void> seedSuperAdmin() async {
    const email    = 'sly@gmail.com';
    const password = 'Mercurio123*';
    const name     = 'Super Administrador';

    try {
      // Verifica si ya existe en Firestore
      final snap = await _users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return;

      // Crea el usuario en Auth
      UserCredential cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Ya existe en Auth pero no en Firestore → obtener uid via sign-in
          final signIn = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
          final uid = signIn.user!.uid;
          await _auth.signOut();
          await _writeSuperAdminDoc(uid, name, email);
          return;
        }
        rethrow;
      }

      await cred.user!.updateDisplayName(name);
      await _writeSuperAdminDoc(cred.user!.uid, name, email);
      await _auth.signOut();
    } catch (e) {
      print('[FirebaseService] seedSuperAdmin error: $e');
    }
  }

  Future<void> _writeSuperAdminDoc(
      String uid, String name, String email) async {
    final now = DateTime.now();
    final appUser = AppUser(
      uid:         uid,
      name:        name,
      email:       email,
      roles:       [AppRole.superAdmin],
      permissions: AppPermission.values.toList(),
      companyId:   null, // superAdmin no pertenece a empresa
      createdAt:   now,
      updatedAt:   now,
    );
    await _users.doc(uid).set(appUser.toFirestore());
  }

  // =========================================================================
  // AUTH
  // =========================================================================

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);

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

      // Valida que usuarios no-superAdmin tengan empresa activa
      if (!appUser.isSuperAdmin && appUser.companyId != null) {
        final compDoc = await _companies.doc(appUser.companyId).get();
        if (!compDoc.exists) {
          await _auth.signOut();
          return const Failure('La empresa asociada no existe.');
        }
        final company = Company.fromFirestore(compDoc);
        if (!company.isActive) {
          await _auth.signOut();
          return const Failure('La empresa está desactivada. Contacta al soporte.');
        }
      }

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

  Future<Result<AppUser>> register({
    required String name,
    required String email,
    required String password,
    AppRole role = AppRole.user,
    String? companyId,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());

      final permissions = kDefaultRolePermissions[role] ?? [];
      final now = DateTime.now();

      final appUser = AppUser(
        uid:         cred.user!.uid,
        name:        name.trim(),
        email:       email.trim(),
        roles:       [role],
        permissions: permissions,
        companyId:   companyId,
        createdAt:   now,
        updatedAt:   now,
      );

      await _users.doc(cred.user!.uid).set(appUser.toFirestore());
      await _sendWelcomeEmail(name: name.trim(), email: email.trim());
      return Success(appUser);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error al crear la cuenta.', error: e);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

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

  Future<Result<void>> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email, password: password);
      await _auth.currentUser!.reauthenticateWithCredential(credential);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      return Failure('Error de re-autenticación.', error: e);
    }
  }

  Future<Result<void>> changePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
      final user = _auth.currentUser!;
      await _sendPasswordChangedEmail(
        email: user.email ?? '', name: user.displayName ?? '');
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

  Future<Result<AppUser>> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Failure('No hay sesión activa.');
    return fetchUser(uid);
  }

  Future<Result<AppUser>> fetchUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return const Failure('Usuario no encontrado.');
      return Success(AppUser.fromFirestore(doc));
    } catch (e) {
      return Failure('Error al obtener perfil.', error: e);
    }
  }

  Stream<AppUser?> currentUserStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

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
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name.trim());
      }
      return fetchUser(uid);
    } catch (e) {
      return Failure('Error al actualizar perfil.', error: e);
    }
  }

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
  // COMPANIES (solo superAdmin)
  // =========================================================================

  Stream<List<Company>> companiesStream() {
    return _companies.snapshots().map((snap) {
      final list = snap.docs.map(Company.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<Result<Company>> createCompany({
    required String name,
    required String legalName,
    required String email,
    String phone = '',
    String address = '',
    // Datos del admin principal
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) return const Failure('No hay sesión activa.');

    FirebaseApp? secondaryApp;
    try {
      FirebaseService.suppressAuthRedirect = true;

      final now     = DateTime.now();
      final compRef = _companies.doc();

      final company = Company(
        id:        compRef.id,
        name:      name.trim(),
        legalName: legalName.trim(),
        email:     email.trim(),
        phone:     phone.trim(),
        address:   address.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await compRef.set(company.toFirestore());

      // Crea admin principal en Auth secundario
      final appName = 'secondary_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName, options: Firebase.app().options);
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: adminEmail.trim(), password: adminPassword);
      await cred.user!.updateDisplayName(adminName.trim());

      final adminPerms = kDefaultRolePermissions[AppRole.companyAdmin] ?? [];
      final appUser = AppUser(
        uid:         cred.user!.uid,
        name:        adminName.trim(),
        email:       adminEmail.trim(),
        roles:       [AppRole.companyAdmin],
        permissions: adminPerms,
        companyId:   compRef.id,
        createdAt:   now,
        updatedAt:   now,
      );
      await _users.doc(cred.user!.uid).set(appUser.toFirestore());

      await secondaryAuth.signOut();
      await secondaryApp.delete();
      secondaryApp = null;

      return Success(company);
    } on FirebaseAuthException catch (e) {
      await secondaryApp?.delete();
      return Failure(_authErrorMessage(e.code));
    } catch (e) {
      await secondaryApp?.delete();
      return Failure('Error al crear empresa: $e');
    } finally {
      FirebaseService.suppressAuthRedirect = false;
    }
  }

  Future<Result<void>> updateCompany(Company company) async {
    try {
      final data = company.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _companies.doc(company.id).update(data);
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar empresa.', error: e);
    }
  }

  Future<Result<void>> deleteCompany(String companyId) async {
    try {
      // Soft delete: marca como inactive
      await _companies.doc(companyId).update({
        'status':    'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar empresa.', error: e);
    }
  }

  Future<Result<void>> updateCompanyStatus({
    required String companyId,
    required String status,
  }) async {
    try {
      await _companies.doc(companyId).update({
        'status':    status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar estado de empresa.', error: e);
    }
  }

  // =========================================================================
  // USERS (admin)
  // =========================================================================

  /// SuperAdmin: todos los usuarios. CompanyAdmin: solo los de su empresa.
Stream<List<AppUser>> allUsersStream({String? companyId}) {
  Query query = _users;
  // Si se pasa companyId, filtra. Si no (superAdmin), trae todos.
  if (companyId != null) {
    query = query.where('companyId', isEqualTo: companyId);
  }
  return query.snapshots().map((snap) {
    final list = snap.docs.map(AppUser.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
}
/// Stream de la empresa actual del usuario logueado
final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isSuperAdmin || user.companyId == null) {
    return Stream.value(null);
  }
  return ref.read(firebaseServiceProvider)
      ._db
      .collection('companies')
      .doc(user.companyId)
      .snapshots()
      .map((doc) => doc.exists ? Company.fromFirestore(doc) : null);
});

/// Notificaciones filtradas por empresa
final companyNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);

  if (user == null) return Stream.value([]);

  // superAdmin ve todas, los demás solo las suyas
  return svc.notificationsStream(userId);
});

Future<Result<void>> createNotificationForCompany({
  required String userId,
  required String companyId,
  required String title,
  required String body,
  NotificationType type = NotificationType.info,
}) async {
  try {
    await _notifications.add({
      'userId':    userId,
      'companyId': companyId,
      'title':     title,
      'body':      body,
      'type':      type.name,
      'read':      false,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata':  {},
    });
    return const Success(null);
  } catch (e) {
    return Failure('Error al crear notificación.', error: e);
  }
}

  Future<Result<AppUser>> createUserAsAdmin({
    required String name,
    required String email,
    required String password,
    AppRole role = AppRole.user,
    String? companyId,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) return const Failure('No hay sesión activa.');

    FirebaseApp? secondaryApp;
    try {
      FirebaseService.suppressAuthRedirect = true;

      final appName = 'secondary_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName, options: Firebase.app().options);
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
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
        companyId:   companyId,
        createdAt:   now,
        updatedAt:   now,
      );

      await _users.doc(uid).set(appUser.toFirestore());
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
      FirebaseService.suppressAuthRedirect = false;
    }
  }

  Future<Result<void>> updateUserRoles({
    required String uid,
    required List<AppRole> roles,
  }) async {
    try {
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
  // ROLES (scoped by company)
  // =========================================================================

  Stream<List<RoleDefinition>> rolesStream({String? companyId}) {
    Query query = _roles;
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }
    return query.snapshots().map((s) {
      if (s.docs.isEmpty) {
        return AppRole.values
            .where((r) => r != AppRole.superAdmin)
            .map((role) => RoleDefinition(
                  id:          role.value,
                  name:        role.value,
                  displayName: role.displayName,
                  description: 'Rol predeterminado',
                  permissions: kDefaultRolePermissions[role] ?? [],
                  companyId:   companyId,
                  createdAt:   DateTime.now(),
                ))
            .toList();
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

  Stream<int> unreadCountStream(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['read'] == false)
            .length);
  }

  Future<Result<void>> createNotification(AppNotification notification) async {
    try {
      await _notifications.add(notification.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Error al crear notificación.', error: e);
    }
  }

  Future<Result<void>> markNotificationRead(String notifId) async {
    try {
      await _notifications.doc(notifId).update({'read': true});
      return const Success(null);
    } catch (e) {
      return Failure('Error al marcar notificación.', error: e);
    }
  }

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

  Future<Result<void>> deleteNotification(String notifId) async {
    try {
      await _notifications.doc(notifId).delete();
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar notificación.', error: e);
    }
  }

  // =========================================================================
  // CLOUD FUNCTIONS
  // =========================================================================

  Future<void> _sendWelcomeEmail({
    required String name, required String email}) async {
    try {
      await _functions.httpsCallable('sendWelcomeEmail')
          .call({'name': name, 'email': email});
    } catch (e) {
      print('[FirebaseService] sendWelcomeEmail error: $e');
    }
  }

  Future<void> _sendPasswordChangedEmail({
    required String name, required String email}) async {
    try {
      await _functions.httpsCallable('sendPasswordChangedEmail')
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
      await _functions.httpsCallable('sendSystemEmail')
          .call({'to': to, 'subject': subject, 'body': body});
      return const Success(null);
    } catch (e) {
      return Failure('Error al enviar email.', error: e);
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  String _authErrorMessage(String code) => switch (code) {
        'user-not-found'         => 'No existe una cuenta con ese email.',
        'wrong-password'         => 'Contraseña incorrecta.',
        'email-already-in-use'   => 'Este email ya está registrado.',
        'weak-password'          => 'La contraseña debe tener al menos 6 caracteres.',
        'invalid-email'          => 'El formato del email no es válido.',
        'too-many-requests'      => 'Demasiados intentos. Intenta más tarde.',
        'user-disabled'          => 'Esta cuenta ha sido desactivada.',
        'invalid-credential'     => 'Credenciales inválidas.',
        'network-request-failed' => 'Error de conexión. Verifica tu internet.',
        'requires-recent-login'  => 'Debes iniciar sesión nuevamente.',
        _                        => 'Error de autenticación ($code).',
      };

  Future<void> seedDefaultRoles({String? companyId}) async {
    Query query = _roles;
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }
    final snap = await query.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final role in AppRole.values) {
      if (role == AppRole.superAdmin) continue;
      final ref = _roles.doc();
      batch.set(ref, RoleDefinition(
        id:          ref.id,
        name:        role.value,
        displayName: role.displayName,
        description: 'Rol predeterminado: ${role.displayName}',
        permissions: kDefaultRolePermissions[role] ?? [],
        companyId:   companyId,
        createdAt:   DateTime.now(),
      ).toFirestore());
    }
    await batch.commit();
  }
}

// =============================================================================
// 4. PROVIDERS (Riverpod)
// =============================================================================
// =============================================================================
// 4. PROVIDERS (Riverpod)
// =============================================================================

final firebaseServiceProvider = Provider<FirebaseService>(
  (_) => FirebaseService(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseServiceProvider).authStateStream;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref.read(firebaseServiceProvider).currentUserStream();
    },
    loading: () => Stream.value(null),
    error:   (_, __) => Stream.value(null),
  );
});

final requireUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return user;
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>(
  (ref, userId) =>
      ref.read(firebaseServiceProvider).notificationsStream(userId),
);

final unreadCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.read(firebaseServiceProvider).unreadCountStream(userId),
);

/// Usuarios filtrados por empresa si el usuario actual es companyAdmin
/// Usuarios filtrados por empresa si el usuario actual es companyAdmin
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);

  if (currentUser == null) return Stream.value([]);

  if (currentUser.isSuperAdmin) {
    return svc.allUsersStream(); // todos
  }
  // companyAdmin y demás: solo su empresa
  return svc.allUsersStream(companyId: currentUser.companyId);
});

/// Roles filtrados por empresa
final rolesProvider = StreamProvider<List<RoleDefinition>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);

  if (currentUser == null) return Stream.value([]);
  if (currentUser.isSuperAdmin) return svc.rolesStream();
  return svc.rolesStream(companyId: currentUser.companyId);
});

/// Empresas (solo superAdmin)
final companiesProvider = StreamProvider<List<Company>>(
  (ref) => ref.read(firebaseServiceProvider).companiesStream(),
);

final permissionCheckerProvider =
    Provider.family<bool, AppPermission>((ref, permission) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.hasPermission(permission) ?? false;
});

/// Proveedor del tipo de dashboard a mostrar
enum DashboardType { superAdmin, companyAdmin, user, none }

final dashboardTypeProvider = Provider<DashboardType>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return DashboardType.none;
  if (user.isSuperAdmin)   return DashboardType.superAdmin;
  if (user.isCompanyAdmin) return DashboardType.companyAdmin;
  return DashboardType.user;
});