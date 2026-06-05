// lib/core/router/app_router.dart
import 'package:digitaltv/auth/authSystem.dart';
import 'package:digitaltv/auth/page/login.dart';
import 'package:digitaltv/entities/entities.dart';
import 'package:digitaltv/firestore/auth_provider.dart';
import 'package:digitaltv/notification/notification.dart';
import 'package:digitaltv/route/mainshell.dart';
import 'package:digitaltv/ui/auth/auth.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel/page/pageDevice.dart';
import 'package:digitaltv/ui/panel/panel2.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/panel/playlist2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlaylistsListScreen extends ConsumerWidget {
  const PlaylistsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Center(
        child: PlaylistsListDialog(ref: ref),
      ),
    );
  }
}

class _ViewPlaylistScreen extends ConsumerWidget {
  final String playlistId;
  const _ViewPlaylistScreen({required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(savedPlaylistsProvider);
    final pl = playlists.where((p) => p.id == playlistId).firstOrNull;

    if (pl == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070B12),
        body: Center(
          child: Text('Playlist no encontrada',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PlaylistViewerDialog(playlist: pl),
    );
  }
}

// Route names
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const devices = '/devices';
  static const deviceDetail = '/devices/:id';
  static const content = '/content';
  static const assignments = '/assignments';
  static const roles = '/roles';
  static const display = '/display/:token'; // ← NUEVO
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      debugPrint("--- RUTA: $path | Logueado: $isLoggedIn ---");

      if (isLoading) return null;

      // 1. Permitir rutas públicas de autenticación
      final isPublic =
          [AppRoutes.login, '/register', '/forgot-password'].contains(path);
      if (isPublic) {
        return isLoggedIn ? AppRoutes.dashboard : null;
      }

      // 2. Permitir acceso libre a los visores sin logueo
      if (path.startsWith('/view/') || path.startsWith('/display/')) {
        debugPrint("--- Acceso libre a visor ---");
        return null;
      }

      // 3. Proteger todo lo demás
      if (!isLoggedIn) {
        debugPrint("--- No logueado, redirigiendo a login ---");
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // RUTAS FUERA DEL SHELL (Full Screen)
      GoRoute(
        path: '/view/:id',
        builder: (_, state) =>
            _ViewPlaylistScreen(playlistId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/display/:token',
        builder: (_, state) =>
            DisplayViewerScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),

      // SHELL ROUTE
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/devices', builder: (_, __) => const DevicesScreen()),
          GoRoute(
              path: '/content', builder: (_, __) => const PlaylistsScreen()),
          GoRoute(
              path: '/playlist2',
              builder: (_, __) => const PlaylistsListScreen()),
          GoRoute(
              path: '/schedules', builder: (_, __) => const SchedulesScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(
              path: '/media', builder: (_, __) => const MediaLibraryScreen()),
          GoRoute(
              path: '/editor', builder: (_, __) => const ScreenEditorScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsPage()),
          GoRoute(
              path: '/notifications2',
              builder: (_, __) => const NotificationsPage22()),
          GoRoute(
              path: '/users', builder: (_, __) => const UsersManagementPage()),
          GoRoute(path: '/roles', builder: (_, __) => const AuthScreen()),
        ],
      ),
    ],
  );
});
