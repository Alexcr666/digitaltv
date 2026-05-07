// lib/presentation/providers/auth_provider.dart
import 'package:digitaltv/entities/entities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Current authesnticated user state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user entity (with role from Firestore)
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(authState.uid)
      .get();

  if (!doc.exists) return null;

  final data = doc.data()!;
  return UserEntity(
    id: doc.id,
    email: data['email'] ?? '',
    displayName: data['displayName'] ?? '',
    role: UserRoleExt.fromString(data['role'] ?? 'VIEWER'),
    createdAt: (data['createdAt'] as Timestamp).toDate(),
  );
});

// Auth notifier for login/logout actions
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
          state = const AsyncValue.data(null);
          return;
        }
        final data = doc.data()!;
        state = AsyncValue.data(UserEntity(
          id: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? '',
          role: UserRoleExt.fromString(data['role'] ?? 'VIEWER'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        ));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State updated by listener above
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_mapAuthError(e), StackTrace.current);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':    return 'No account found for this email.';
      case 'wrong-password':    return 'Incorrect password.';
      case 'invalid-email':     return 'Invalid email address.';
      case 'user-disabled':     return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return e.message ?? 'Authentication failed.';
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(
  (_) => AuthNotifier(),
);