// lib/core/router/app_router.dart
import 'package:digitaltv/entities/entities.dart';
import 'package:digitaltv/firestore/auth_provider.dart';
import 'package:digitaltv/route/mainshell.dart';
import 'package:digitaltv/ui/auth/auth.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


// Route names
class AppRoutes {
  static const login        = '/login';
  static const dashboard    = '/dashboard';
  static const devices      = '/devices';
  static const deviceDetail = '/devices/:id';
  static const content      = '/content';
  static const assignments  = '/assignments';
  static const roles        = '/roles';
  static const display      = '/display/:token';   // ← NUEVO
}
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading  = authState.isLoading;
      final isOnLogin  = state.matchedLocation == AppRoutes.login;
      final path       = state.matchedLocation;
      final isOnDisplay = path.startsWith('/display');

      if (isLoading)   return null;
      if (isOnDisplay) return null;
      if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
      if (isLoggedIn  && isOnLogin)  return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/display/:token',
        builder: (_, state) => DisplayViewerScreen(
          token: state.pathParameters['token']!,
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [

          GoRoute(path: '/schedules', builder: (_, __) => const SchedulesScreen()),
GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
GoRoute(path: '/media',     builder: (_, __) => const MediaLibraryScreen()),
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/devices',
            builder: (_, __) => const DevicesScreen(),
          ),
          GoRoute(
            path: '/content',
            builder: (_, __) => const PlaylistsScreen(),
          ),
          GoRoute(
            path: '/assignments',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/roles',
            redirect: (context, state) {
              final user = ref.read(authNotifierProvider).valueOrNull;
              if (user != null && !user.role.canManageUsers) {
                return '/dashboard';
              }
              return null;
            },
            builder: (_, __) => const AuthScreen(),
          ),
        ],
      ),
    ],
  );
});