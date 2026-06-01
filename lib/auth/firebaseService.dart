// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';



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

  // ── SEED ──────────────────────────────────────────────────────────────────

  Future<void> seedSuperAdmin() async {
    const email    = 'sly@gmail.com';
    const password = 'Mercurio123*';
    const name     = 'Super Administrador';

    try {
      final exists = await _superAdminExistsInFirestore(email);
      if (exists) return;

      final uid = await _createOrRecoverAuthUser(
          email: email, password: password, name: name);
      if (uid == null) return;

      await _writeSuperAdminDoc(uid, name, email);
      await _auth.signOut();
    } catch (e) {
      print('[FirebaseService] seedSuperAdmin error: $e');
    }
  }

  Future<bool> _superAdminExistsInFirestore(String email) async {
    final snap = await _users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String?> _createOrRecoverAuthUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user!.updateDisplayName(name);
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final signIn = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = signIn.user!.uid;
      await _auth.signOut();
      await _writeSuperAdminDoc(uid, name, email);
      return null;
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
      companyId:   null,
      createdAt:   now,
      updatedAt:   now,
    );
    await _users.doc(uid).set(appUser.toFirestore());
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

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

      if (!appUser.isSuperAdmin && appUser.companyId != null) {
        final compDoc = await _companies.doc(appUser.companyId).get();
        if (!compDoc.exists) {
          await _auth.signOut();
          return const Failure('La empresa asociada no existe.');
        }
        final company = Company.fromFirestore(compDoc);
        if (!company.isActive) {
          await _auth.signOut();
          return const Failure(
              'La empresa está desactivada. Contacta al soporte.');
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

  Future<void> signOut() => _auth.signOut();

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
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
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

  // ── USER PROFILE ──────────────────────────────────────────────────────────

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
    return _users.doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromFirestore(snap) : null,
        );
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
        if (name     != null) 'name':     name.trim(),
        if (phone    != null) 'phone':    phone.trim(),
        if (address  != null) 'address':  address.trim(),
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

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

  // ── COMPANIES ─────────────────────────────────────────────────────────────

  Stream<List<Company>> companiesStream() {
    return _companies
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Company.fromFirestore).toList());
  }

  /// Stream de una empresa por ID.
  Stream<Company?> companyStream(String companyId) {
    return _companies.doc(companyId).snapshots().map(
          (doc) => doc.exists ? Company.fromFirestore(doc) : null,
        );
  }

  Future<Result<Company>> createCompany({
    required String name,
    required String legalName,
    required String email,
    String phone = '',
    String address = '',
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

      final appName = 'secondary_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp  = await Firebase.initializeApp(
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
      final data = company.toFirestore()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _companies.doc(company.id).update(data);
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar empresa.', error: e);
    }
  }

  Future<Result<void>> deleteCompany(String companyId) async {
    try {
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

  // ── USERS (admin) ─────────────────────────────────────────────────────────

  Stream<List<AppUser>> allUsersStream({String? companyId}) {
    final Query query = companyId != null
        ? _users
            .where('companyId', isEqualTo: companyId)
            .orderBy('createdAt', descending: true)
        : _users.orderBy('createdAt', descending: true);

    return query.snapshots().map(
        (snap) => snap.docs.map(AppUser.fromFirestore).toList());
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
      secondaryApp  = await Firebase.initializeApp(
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

  // ── ROLES ─────────────────────────────────────────────────────────────────

  Stream<List<RoleDefinition>> rolesStream({String? companyId}) {
    final Query query = companyId != null
        ? _roles.where('companyId', isEqualTo: companyId)
        : _roles;

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
      return s.docs.map(RoleDefinition.fromFirestore).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
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

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Stream<List<AppNotification>> notificationsStream(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
  }

  Stream<int> unreadCountStream(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<Result<void>> createNotification(AppNotification notification) async {
    try {
      await _notifications.add(notification.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Error al crear notificación.', error: e);
    }
  }

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
        'metadata':  <String, dynamic>{},
      });
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

  // ── CLOUD FUNCTIONS ───────────────────────────────────────────────────────

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

  // ── SEED ROLES ────────────────────────────────────────────────────────────

  Future<void> seedDefaultRoles({String? companyId}) async {
    final Query query = companyId != null
        ? _roles.where('companyId', isEqualTo: companyId)
        : _roles;

    final snap = await query.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final role in AppRole.values) {
      if (role == AppRole.superAdmin) continue;
      final ref = _roles.doc();
      batch.set(
        ref,
        RoleDefinition(
          id:          ref.id,
          name:        role.value,
          displayName: role.displayName,
          description: 'Rol predeterminado: ${role.displayName}',
          permissions: kDefaultRolePermissions[role] ?? [],
          companyId:   companyId,
          createdAt:   DateTime.now(),
        ).toFirestore(),
      );
    }
    await batch.commit();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

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
}