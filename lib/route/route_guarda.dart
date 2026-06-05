// lib/route/route_guard.dart

import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/auth/utils/utils.dart';
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
      AppRoutesAuth.login,
      AppRoutesAuth.register,
      AppRoutesAuth.forgotPassword,
      '/portal',
      '/panel',
    };
    final isPublic = publicRoutes.contains(path);

    if (!isAuthenticated && !isPublic) return AppRoutesAuth.login;

    if (isAuthenticated && isPublic) {
      if (user == null) return null;
      return user.isSuperAdmin
          ? AppRoutesAuth.superDashboard
          : AppRoutesAuth.dashboard;
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
    const superOnlyRoutes = {
      AppRoutesAuth.superDashboard,
      AppRoutesAuth.companies
    };
    if (superOnlyRoutes.contains(path) || path.startsWith('/company/')) {
      return AppRoutesAuth.dashboard;
    }

    final permissionRoutes = {
      AppRoutesAuth.users: AppPermission.usersView,
      AppRoutesAuth.roles: AppPermission.rolesView,
      AppRoutesAuth.notifications2: AppPermission.notificationsSend,
    };
    final requiredPerm = permissionRoutes[path];
    if (requiredPerm != null &&
        !user.hasPermission(requiredPerm) &&
        !user.isCompanyAdmin) {
      return AppRoutesAuth.dashboard;
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
      return AppRoutesAuth.dashboard;
    }

    return null;
  }

  static String? _evaluateSuperAdmin(String path) {
    const superRoutes = {
      AppRoutesAuth.superDashboard,
      AppRoutesAuth.companies,
      AppRoutesAuth.superUsers,
      AppRoutesAuth.superRoles,
      AppRoutesAuth.superNotifications,
      AppRoutesAuth.superProfile,
    };
    if (!superRoutes.contains(path) && !path.startsWith('/company/')) {
      return AppRoutesAuth.superDashboard;
    }
    return null;
  }
}
