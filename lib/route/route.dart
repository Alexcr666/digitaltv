// lib/core/router/app_router.dart
import 'package:digitaltv/entities/entities.dart';
import 'package:digitaltv/firestore/auth_provider.dart';
import 'package:digitaltv/route/mainshell.dart';
import 'package:digitaltv/ui/auth/auth.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


// Route names
class AppRoutes {
  static const login       = '/login';
  static const dashboard   = '/dashboard';
  static const devices     = '/devices';
  static const deviceDetail = '/devices/:id';
  static const content     = '/content';
  static const assignments = '/assignments';
  static const roles       = '/roles';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading  = authState.isLoading;
      final isOnLogin  = state.matchedLocation == AppRoutes.login;

      if (isLoading) return null;
      if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
      if (isLoggedIn  && isOnLogin)  return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: '/devices',   builder: (_, __) => const DevicesScreen()),
GoRoute(path: '/playlists', builder: (_, __) => const PlaylistsScreen()),
GoRoute(
  path: '/display/:token',
  builder: (_, s) => DisplayViewerScreen(token: s.pathParameters['token']!),
),
      GoRoute(
        path: AppRoutes.login,
           builder: (_, __) => const AuthScreen(),
      //  builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.devices,
               builder: (_, __) => const DashboardScreen(),
           // builder: (_, __) => const DevicesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                   builder: (_, __) => const DashboardScreen(),
               /* builder: (_, state) => DeviceDetailScreen(
                  deviceId: state.pathParameters['id']!,
                ),*/
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.content,
               builder: (_, __) => const DashboardScreen(),
        //    builder: (_, __) => const ContentScreen(),
          ),
          GoRoute(
            path: AppRoutes.assignments,
               builder: (_, __) => const DashboardScreen(),
          //  builder: (_, __) => const AssignmentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.roles,
            // Guard: only admin+ can view roles
            redirect: (context, state) {
              final user = ref.read(authNotifierProvider).valueOrNull;
              if (user != null && !user.role.canManageUsers) {
                return AppRoutes.dashboard;
              }
              return null;
            },
               builder: (_, __) => const  AuthScreen(),
           // builder: (_, __) => const RolesScreen(),
          ),

        
        ],
      ),
    ],
  );
});