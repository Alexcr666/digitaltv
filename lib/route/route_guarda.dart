// lib/route/route_guard.dart

import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/utils/permission_label.dart';

import '../auth/authSystem.dart';

abstract class RouteGuard {
  static String? evaluate({
    required String path,
    required bool isLoading,
    required bool isAuthenticated,
    required AppUser? user,
  }) {
    if (isLoading) return null;
    if (path.startsWith('/view/')) return null;
    if (path.startsWith('/portal')) return null;
    if (path.startsWith('/wa/')) return null;

    const publicRoutes = {
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      '/portal',
      '/panel',
    };
    final isPublic = publicRoutes.contains(path);

    if (!isAuthenticated && !isPublic) return AppRoutes.login;

    if (isAuthenticated && isPublic) {
      if (user == null) return null;
      return user.isSuperAdmin ? AppRoutes.superDashboard : AppRoutes.dashboard;
    }

    if (isAuthenticated && user == null) return null;

    if (user != null && !user.isSuperAdmin) {
      return _evaluateNormalUser(path, user);
    }

    if (user != null && user.isSuperAdmin) {
      return _evaluateSuperAdmin(path);
    }

    return null;
  }

  static String? _evaluateNormalUser(String path, AppUser user) {
    const superOnlyRoutes = {AppRoutes.superDashboard, AppRoutes.companies};
    if (superOnlyRoutes.contains(path) || path.startsWith('/company/')) {
      return AppRoutes.dashboard;
    }

    final permissionRoutes = {
      AppRoutes.users: AppPermission.usersView,
      AppRoutes.roles: AppPermission.rolesView,
      AppRoutes.notifications2: AppPermission.notificationsSend,
    };
    final requiredPerm = permissionRoutes[path];
    if (requiredPerm != null &&
        !user.hasPermission(requiredPerm) &&
        !user.isCompanyAdmin) {
      return AppRoutes.dashboard;
    }

    const adminOnlyPaths = {
      '/devices',
      '/playlist2',
      '/schedules',
      '/media',
      '/editor',
      '/content',
    };
    if (adminOnlyPaths.contains(path) && !user.isCompanyAdmin) {
      return AppRoutes.dashboard;
    }

    return null;
  }

  static String? _evaluateSuperAdmin(String path) {
    const superRoutes = {
      AppRoutes.superDashboard,
      AppRoutes.companies,
      AppRoutes.superUsers,
      AppRoutes.superRoles,
      AppRoutes.superNotifications,
      AppRoutes.superProfile,
    };
    if (!superRoutes.contains(path) && !path.startsWith('/company/')) {
      return AppRoutes.superDashboard;
    }
    return null;
  }
}
