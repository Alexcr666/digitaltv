import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    error: (_, __) => Stream.value(null),
  );
});

final requireUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return user;
});

final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isSuperAdmin || user.companyId == null) {
    return Stream.value(null);
  }
  return ref.read(firebaseServiceProvider).companyStream(user.companyId!);
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>(
  (ref, userId) =>
      ref.read(firebaseServiceProvider).notificationsStream(userId),
);

final companyNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.read(firebaseServiceProvider).notificationsStream(userId);
});

final unreadCountProvider = StreamProvider.family<int, String>(
  (ref, userId) => ref.read(firebaseServiceProvider).unreadCountStream(userId),
);

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);
  if (currentUser == null) return Stream.value([]);
  if (currentUser.isSuperAdmin) return svc.allUsersStream();
  return svc.allUsersStream(companyId: currentUser.companyId);
});

final rolesProvider = StreamProvider<List<RoleDefinition>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);
  if (currentUser == null) return Stream.value([]);
  if (currentUser.isSuperAdmin) return svc.rolesStream();
  return svc.rolesStream(companyId: currentUser.companyId);
});

final companiesProvider = StreamProvider<List<Company>>(
  (ref) => ref.read(firebaseServiceProvider).companiesStream(),
);

final permissionCheckerProvider =
    Provider.family<bool, AppPermission>((ref, permission) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.hasPermission(permission) ?? false;
});

enum DashboardType { superAdmin, companyAdmin, user, none }

final dashboardTypeProvider = Provider<DashboardType>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return DashboardType.none;
  if (user.isSuperAdmin) return DashboardType.superAdmin;
  if (user.isCompanyAdmin) return DashboardType.companyAdmin;
  return DashboardType.user;
});
