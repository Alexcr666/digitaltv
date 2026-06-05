import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/auth/auth.dart' as current2;
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/auth/page/login.dart';
import 'package:digitaltv/auth/page/page.dart';
import 'package:digitaltv/auth/utils/utils.dart';
import 'package:digitaltv/auth/widget/widget.dart';
import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/config/app_config.dart';
import 'package:digitaltv/logo.dart';
import 'package:digitaltv/provider/app_providers.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:digitaltv/route/route.dart';
import 'package:digitaltv/ui/panel/device_portal_screen.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel/page/pageDevice.dart';
import 'package:digitaltv/ui/panel/panel/page/widget/widget.dart';
import 'package:digitaltv/ui/panel/panel2.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/panel/playlist2.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/notification/notification.dart';
import 'package:digitaltv/ui/programming/programing.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// Local import — ensure this matches your actual package path

final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isSuperAdmin || user.companyId == null) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('companies')
      .doc(user.companyId)
      .snapshots()
      .map((doc) => doc.exists ? Company.fromFirestore(doc) : null);
});

final companyNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final svc = ref.read(firebaseServiceProvider);
  if (user == null) return Stream.value([]);
  return svc.notificationsStream(userId);
});
// =============================================================================
// 1. DESIGN TOKENS
// =============================================================================

abstract class _T {
  // Surface
  static const bg = Color(0xFF080C14);
  static const surface = Color(0xFF0E1420);
  static const card = Color(0xFF131B2B);
  static const cardHover = Color(0xFF172035);
  static const border = Color(0xFF1E2D47);
  static const divider = Color(0xFF1A2540);

  // Brand
  static const primary = Color(0xFF45c4c4);
  static const primaryLo = Color(0x1A45c4c4);
  static const primaryMid = Color(0x3345c4c4);
  static const accent = Color(0xFF38BDF8);

  // Text
  static const textHi = Color(0xFFF0F4FF);
  static const textMid = Color(0xFF8B9CC8);
  static const textLo = Color(0xFF3D4F72);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const errorLo = Color(0x1AEF4444);

  // Radius
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: error,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: textMid,
          displayColor: textHi,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          hintStyle: const TextStyle(color: textLo, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: r12,
              borderSide: const BorderSide(color: primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: r12, borderSide: const BorderSide(color: error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: r12,
              borderSide: const BorderSide(color: error, width: 1.5)),
          errorStyle: const TextStyle(color: error, fontSize: 11),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: card,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: r12),
            minimumSize: const Size(double.infinity, 48),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: r16,
            side: const BorderSide(color: border),
          ),
        ),
      );
}

// =============================================================================
// 2. ROUTES
// =============================================================================

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

// =============================================================================
// 3. ROUTER
// =============================================================================
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
            color: _T.textHi, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRouteNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutesAuth.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final authAsync = ref.read(authStateProvider);
      final isAuth = authAsync.valueOrNull != null;
      final isLoading = authAsync.isLoading;
      final path = state.matchedLocation;

      debugPrint('🔀 REDIRECT CHECK:');
      debugPrint('   path: $path');
      debugPrint('   isAuth: $isAuth | isLoading: $isLoading');
      debugPrint(
          '   user: ${user?.name} | isSuperAdmin: ${user?.isSuperAdmin} | roles: ${user?.roles.map((r) => r.value).toList()}');
      if (isLoading) return null;
      if (path.startsWith('/view/')) return null;
      if (path.startsWith('/portal')) return null;
      if (path.startsWith('/wa/')) return null;

      const publicRoutes = [
        AppRoutesAuth.login,
        AppRoutesAuth.register,
        '/panel',
        AppRoutesAuth.forgotPassword,
        '/portal',
      ];
      final isPublic = publicRoutes.contains(path);

      if (!isAuth && !isPublic) return AppRoutesAuth.login;

      if (isAuth && isPublic) {
        // Si el usuario de Firestore aún no cargó, esperar
        if (user == null) return null;
        return user.isSuperAdmin
            ? AppRoutesAuth.superDashboard
            : AppRoutesAuth.dashboard;
      }

      // ── CLAVE: si autenticado pero user Firestore aún no cargó, esperar ──
      if (isAuth && user == null) return null;

      // Bloquear rutas exclusivas de superAdmin a usuarios normales
// Bloquear rutas protegidas según rol
      if (user != null && !user.isSuperAdmin) {
        // Rutas solo super admin
        final superOnlyRoutes = [
          AppRoutesAuth.superDashboard,
          AppRoutesAuth.companies
        ];
        if (superOnlyRoutes.contains(path) || path.startsWith('/company/')) {
          return AppRoutesAuth.dashboard;
        }

        // Rutas que requieren permiso específico
        final permissionRoutes = {
          AppRoutesAuth.users: AppPermission.usersView,
          AppRoutesAuth.roles: AppPermission.rolesView,
          AppRoutesAuth.notifications2: AppPermission.notificationsSend,
        };

        for (final entry in permissionRoutes.entries) {
          if (path == entry.key &&
              !user.hasPermission(entry.value) &&
              !user.isCompanyAdmin) {
            return AppRoutesAuth.dashboard;
          }
        }

        // Rutas de contenido/dispositivos solo para companyAdmin o superior
        final adminOnlyPaths = [
          '/devices',
          '/playlist2',
          '/schedules',
          '/media',
          '/editor',
          '/content'
        ];
        if (adminOnlyPaths.contains(path) && !user.isCompanyAdmin) {
          return AppRoutesAuth.dashboard;
        }
      }

      // SuperAdmin solo puede ir a sus rutas
      if (isAuth && user!.isSuperAdmin == true) {
        final superRoutes = [
          AppRoutesAuth.superDashboard,
          AppRoutesAuth.companies,
          AppRoutesAuth.superUsers,
          AppRoutesAuth.superRoles,
          AppRoutesAuth.superNotifications,
          AppRoutesAuth.superProfile,
        ];
        if (!superRoutes.contains(path) && !path.startsWith('/company/')) {
          return AppRoutesAuth.superDashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/view/:id',
        builder: (_, state) =>
            _ViewPlaylistScreen(playlistId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutesAuth.login, builder: (_, __) => const LoginPage()),
      GoRoute(
          path: AppRoutesAuth.register,
          builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: AppRoutesAuth.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/portal', builder: (_, __) => const DevicePortalScreen()),
      GoRoute(
        path: '/portal/dashboard',
        builder: (context, state) {
          final device = state.extra as DeviceUser?;
          return DeviceDashboardScreen(device: device);
        },
      ),

      // ── Shell normal VA PRIMERO ──
      // ── Shell normal ──
      ShellRoute(
        builder: (_, __, child) => _DashboardShell(child: child),
        routes: [
          GoRoute(
              path: AppRoutesAuth.dashboard,
              builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/devices', builder: (_, __) => const DevicesScreen()),
          GoRoute(
              path: '/content', builder: (_, __) => const PlaylistsScreen()),
          GoRoute(
              path: '/playlist2',
              builder: (_, __) => const PlaylistsListScreen()),
          GoRoute(
              path: '/schedules',
              builder: (_, __) => const ProgrammingScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(
              path: '/media', builder: (_, __) => const MediaLibraryScreen()),
          GoRoute(
              path: '/editor', builder: (_, __) => const ScreenEditorScreen()),
          GoRoute(
              path: AppRoutesAuth.notifications,
              builder: (_, __) => const NotificationsPage()),
          GoRoute(
              path: AppRoutesAuth.users,
              builder: (_, __) => const UsersManagementPage()),
          GoRoute(
              path: AppRoutesAuth.roles,
              builder: (_, __) => const RolesManagementPage()),
          GoRoute(
              path: AppRoutesAuth.notifications2,
              builder: (_, __) => const NotificationsPage22()),
          GoRoute(
              path: AppRoutesAuth.profile,
              builder: (_, __) => const ProfilePage()),
          // ── WA Chatbot routes ──
          GoRoute(
            path: '/wa/dashboard',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'dashboard',
            ),
          ),
          GoRoute(
            path: '/wa/massSend',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'massSend',
            ),
          ),
          GoRoute(
            path: '/wa/tokens',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'tokenUsage',
            ),
          ),
          GoRoute(
            path: '/wa/bots',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'bots',
            ),
          ),
          GoRoute(
            path: '/wa/chat',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'chat',
            ),
          ),
          GoRoute(
            path: '/wa/connection',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'connection',
            ),
          ),
          GoRoute(
            path: '/wa/analytics',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'analyticsGlobal',
            ),
          ),
          GoRoute(
            path: '/wa/kanban',
            builder: (_, __) => WhatsappChatbotPage(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              initialView: 'kanban',
            ),
          ),
        ],
      ),

// ── SuperAdmin shell ──
      ShellRoute(
        builder: (_, __, child) => _SuperAdminShell(child: child),
        routes: [
          GoRoute(
              path: AppRoutesAuth.superDashboard,
              builder: (_, __) => const _SuperDashboardHome()),
          GoRoute(
              path: AppRoutesAuth.companies,
              builder: (_, __) => const CompaniesPage()),
          // ── estas 4 rutas también en superAdmin shell ──
          GoRoute(
              path: '/super/users',
              builder: (_, __) => const UsersManagementPage()),
          GoRoute(
              path: '/super/roles',
              builder: (_, __) => const RolesManagementPage()),
          GoRoute(
              path: '/super/notifications',
              builder: (_, __) => const NotificationsPage22()),
          GoRoute(
              path: '/super/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(
            path: '/company/:companyId',
            builder: (_, state) => CompanyDetailPage(
              companyId: state.pathParameters['companyId']!,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => _ErrorPage(error: state.error.toString()),
  );
});

// Notifier that triggers router refresh on auth change
class _AuthRouteNotifier extends ChangeNotifier {
  late final ProviderSubscription _sub;

  _AuthRouteNotifier(Ref ref) {
    _sub = ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

// =============================================================================
// 4. PERMISSION GUARD WIDGET
// =============================================================================

class PermissionGuard extends ConsumerWidget {
  final AppPermission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(permissionCheckerProvider(permission));
    if (hasPermission) return child;
    return fallback ?? _AccessDeniedPage(permission: permission.value);
  }
}

// =============================================================================
// 5. SHARED LAYOUT
// =============================================================================

class _DashboardShell extends ConsumerWidget {
  final Widget child;
  const _DashboardShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    return Scaffold(
      backgroundColor: _T.bg,
      drawer:
          isMobile ? _buildDrawer(context, ref, userAsync.valueOrNull) : null,
      body: Row(
        children: [
          if (!isMobile) _Sidebar(user: userAsync.valueOrNull),
          Expanded(
            child: Stack(
              children: [
                // Contenido ocupa todo el espacio
                Positioned.fill(
                  child: child,
                ),
                // TopBar flotante encima
                Positioned(
                  top: 12,
                  right: 16,
                  child:
                      _TopBar(user: userAsync.valueOrNull, isMobile: isMobile),
                ),
                // Botón hamburguesa flotante (mobile)
                if (isMobile)
                  Positioned(
                    top: 12,
                    left: 16,
                    child: FloatingMenuButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, AppUser? user) =>
      Drawer(
        backgroundColor: _T.surface,
        child: _Sidebar(user: user),
      );
}

class _TopBar extends ConsumerWidget {
  final AppUser? user;
  final bool isMobile;
  const _TopBar({this.user, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = user?.uid ?? '';
    final unreadAsync = userId.isNotEmpty
        ? ref.watch(unreadCountProvider(userId))
        : const AsyncData(0);
    final unread = unreadAsync.valueOrNull ?? 0;

    return Container(
      margin: EdgeInsets.only(top: 50),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _T.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _T.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _T.primary.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notificaciones con badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go(AppRoutesAuth.notifications),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.notifications_outlined,
                        color: _T.textMid, size: 20),
                  ),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: _T.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          // Avatar → perfil
          GestureDetector(
            onTap: () => context.go(AppRoutesAuth.profile),
            child: Avatar(user: user, size: 34),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final AppUser? user;
  const _Sidebar({this.user});
  List<NavItemData> _buildConfigItems(AppUser? user) {
    if (user == null) return [];
    final isCompanyAdmin = user.isCompanyAdmin;
    final canViewUsers = user.hasPermission(AppPermission.usersView);
    final canViewRoles = user.hasPermission(AppPermission.rolesView);
    final canSendNotifs = user.hasPermission(AppPermission.notificationsSend);

    return [
      if (canViewUsers || isCompanyAdmin)
        NavItemData(
            route: AppRoutesAuth.users,
            icon: Icons.people_rounded,
            label: 'Usuarios'),
      if (canViewRoles || isCompanyAdmin)
        NavItemData(
            route: AppRoutesAuth.roles,
            icon: Icons.shield_rounded,
            label: 'Roles'),
      if (canSendNotifs || isCompanyAdmin)
        NavItemData(
            route: AppRoutesAuth.notifications2,
            icon: Icons.notifications_outlined,
            label: 'Notificaciones'),
      NavItemData(
          route: AppRoutesAuth.profile,
          icon: Icons.person_outline_rounded,
          label: 'Mi Perfil'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final companyAsync = ref.watch(currentCompanyProvider);
    final company = companyAsync.valueOrNull;
    final items = _buildNavItems(user);

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(right: BorderSide(color: _T.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          const AppLogo(height: 170, showBadge: true),
          // Badge de empresa (solo para no-superAdmin)
          SizedBox(height: 15),
          if (company != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _T.primaryLo,
                      borderRadius: _T.r8,
                      border: Border.all(color: _T.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: _T.primary, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                              color: _T.textHi,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          company.status == 'active'
                              ? 'Activa'
                              : company.status,
                          style:
                              const TextStyle(color: _T.success, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          /*  Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item == null) {
                return const Divider(color: _T.divider, height: 24, indent: 4);
              }
              final selected = location == item.route;
              return NavItem(
                item: item,
                selected: selected,
                onTap: () {
                  Scaffold.of(context).closeDrawer();
                  context.go(item.route);
                },
              );
            },
          ),
        ),*/

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...items.map((item) {
                  if (item == null) {
                    return const Divider(
                        color: _T.divider, height: 24, indent: 4);
                  }
                  final selected = location == item.route;
                  return NavItem(
                    item: item,
                    selected: selected,
                    onTap: () {
                      Scaffold.of(context).closeDrawer();
                      context.go(item.route);
                    },
                  );
                }),
                const Divider(color: _T.divider, height: 24, indent: 4),
                // Acordeón CONFIGURACIÓN
                NavGroupItem(
                  label: 'Configuración',
                  icon: Icons.settings_outlined,
                  isAnyChildSelected: [
                    AppRoutesAuth.users,
                    AppRoutesAuth.roles,
                    AppRoutesAuth.notifications2,
                    AppRoutesAuth.profile,
                  ].contains(location),
                  children: _buildConfigItems(user),
                ),
                const Divider(color: _T.divider, height: 24, indent: 4),
                // Acordeón CHATBOT WHATSAPP (igual que antes)
                NavGroupItem(
                  label: 'Chatbot WhatsApp',
                  icon: Icons.chat,
                  children: _waItems,
                  isAnyChildSelected: _waItems.any((i) => i.route == location),
                ),
              ],
            ),
          ),
          const Divider(color: _T.divider, height: 1),
          // User info + logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Avatar(user: user, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '—',
                        style: const TextStyle(
                            color: _T.textHi,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roles.firstOrNull?.displayName ?? '',
                        style: const TextStyle(color: _T.textLo, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 16, color: _T.textMid),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, secondAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: _T.r20,
                border: Border.all(color: _T.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono animado
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _T.error.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _T.error.withOpacity(0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: _T.error, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: _T.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¿Estás seguro que deseas cerrar tu sesión actual?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _T.textMid,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _T.surface,
                              borderRadius: _T.r12,
                              border: Border.all(color: _T.border),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: _T.textMid,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(firebaseServiceProvider).signOut();
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _T.error,
                              borderRadius: _T.r12,
                              boxShadow: [
                                BoxShadow(
                                  color: _T.error.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<NavItemData?> _buildNavItems(AppUser? user) {
    if (user == null) return [];
    final isSuperAdmin = user.isSuperAdmin;
    final isCompanyAdmin = user.isCompanyAdmin;
    final canViewDash = user.hasPermission(AppPermission.dashboardCompany);

    return [
      if (canViewDash || isCompanyAdmin)
        NavItemData(
            route: AppRoutesAuth.dashboard,
            icon: Icons.space_dashboard_outlined,
            label: 'Panel de control'),
      if (isCompanyAdmin || isSuperAdmin)
        NavItemData(
            route: '/devices', icon: Icons.tv_outlined, label: 'Dispositivos'),
      if (isCompanyAdmin || isSuperAdmin)
        NavItemData(
            route: '/playlist2',
            icon: Icons.queue_music_outlined,
            label: 'Lista de reproducción'),
      if (isCompanyAdmin || isSuperAdmin)
        NavItemData(
            route: '/schedules',
            icon: Icons.calendar_month_outlined,
            label: 'Programación'),
      if (isCompanyAdmin || isSuperAdmin)
        NavItemData(
            route: '/media',
            icon: Icons.photo_library_outlined,
            label: 'Biblioteca de medios'),
      if (isCompanyAdmin || isSuperAdmin)
        NavItemData(
            route: '/editor',
            icon: Icons.edit_outlined,
            label: 'Editor Playlists'),
    ];
  }

  static const List<NavItemData> _waItems = [
    NavItemData(
        route: '/wa/dashboard',
        icon: Icons.dashboard_rounded,
        label: 'WA Dashboard'),
    NavItemData(
        route: '/wa/bots', icon: Icons.smart_toy_rounded, label: 'Mis Bots'),
    NavItemData(
        route: '/wa/chat',
        icon: Icons.chat_bubble_rounded,
        label: 'Conversaciones'),
    NavItemData(
        route: '/wa/connection',
        icon: Icons.link_rounded,
        label: 'Conexión WA'),
    NavItemData(
        route: '/wa/analytics',
        icon: Icons.analytics_rounded,
        label: 'Analytics WA'),
    NavItemData(
        route: '/wa/kanban',
        icon: Icons.view_kanban_rounded,
        label: 'Kanban Ventas'),
    NavItemData(
        route: '/wa/massSend',
        icon: Icons.send_rounded,
        label: 'Envíos Masivos'),
    NavItemData(
        route: '/wa/tokens', icon: Icons.token_rounded, label: 'Tokens IA'),
  ];
}

// =============================================================================
// 5b. SUPER ADMIN SHELL
// =============================================================================
// _SuperAdminShell — widget completo corregido
class _SuperAdminShell extends ConsumerWidget {
  final Widget child;
  const _SuperAdminShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: _T.bg,
      drawer: isMobile
          ? Drawer(
              backgroundColor: _T.surface,
              child: _SuperSidebar(user: user),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _SuperSidebar(user: user),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  top: 12,
                  right: 16,
                  child: _TopBar(user: user, isMobile: isMobile),
                ),
                if (isMobile)
                  const Positioned(
                    top: 12,
                    left: 16,
                    child: FloatingMenuButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuperSidebar extends ConsumerWidget {
  final AppUser? user;
  const _SuperSidebar({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    final items = [
      NavItemData(
        route: AppRoutesAuth.superDashboard,
        icon: Icons.admin_panel_settings_rounded,
        label: 'Dashboard Global',
      ),
      NavItemData(
        route: AppRoutesAuth.companies,
        icon: Icons.business_rounded,
        label: 'Empresas',
      ),
      NavItemData(
        route: AppRoutesAuth.superUsers,
        icon: Icons.people_rounded,
        label: 'Todos los usuarios',
      ),
      NavItemData(
        route: AppRoutesAuth.superRoles,
        icon: Icons.shield_rounded,
        label: 'Roles globales',
      ),
      null,
      NavItemData(
        route: AppRoutesAuth.superNotifications,
        icon: Icons.notifications_outlined,
        label: 'Notificaciones',
      ),
      NavItemData(
        route: AppRoutesAuth.superProfile,
        icon: Icons.person_outline_rounded,
        label: 'Mi Perfil',
      ),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: _T.surface,
        border: const Border(right: BorderSide(color: _T.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge especial superAdmin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _T.error.withOpacity(0.15),
                    borderRadius: _T.r8,
                    border: Border.all(color: _T.error.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: _T.error, size: 16),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SignageOS',
                        style: TextStyle(
                            color: _T.textHi,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text('SUPER ADMIN',
                        style: TextStyle(
                            color: _T.error,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item == null) {
                  return const Divider(
                      color: _T.divider, height: 24, indent: 4);
                }
                final selected = location == item.route;
                return NavItem(
                  item: item,
                  selected: selected,
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    context.go(item.route);
                  },
                );
              },
            ),
          ),
          const Divider(color: _T.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Avatar(user: user, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                          style: const TextStyle(
                              color: _T.textHi,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const Text('Super Admin',
                          style: TextStyle(color: _T.error, fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 16, color: _T.textMid),
                  tooltip: 'Cerrar sesión',
                  onPressed: () async =>
                      await ref.read(firebaseServiceProvider).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5c. SUPER ADMIN DASHBOARD HOME
// =============================================================================

class _SuperDashboardHome extends ConsumerWidget {
  const _SuperDashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final companies = ref.watch(companiesProvider);
    final allUsers = ref.watch(allUsersProvider);

    final totalCompanies = companies.valueOrNull?.length ?? 0;
    final activeCompanies =
        companies.valueOrNull?.where((c) => c.isActive).length ?? 0;
    final suspendedCompanies =
        companies.valueOrNull?.where((c) => c.status == 'suspended').length ??
            0;
    final totalUsers = allUsers.valueOrNull?.length ?? 0;
    final activeUsers =
        allUsers.valueOrNull?.where((u) => u.status == 'active').length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _T.error.withOpacity(0.12),
                  borderRadius: _T.r12,
                  border: Border.all(color: _T.error.withOpacity(0.3)),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: _T.error, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${user?.name ?? '—'} 👋',
                      style: const TextStyle(
                          color: _T.textHi,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const Text('Panel de Control Global · Super Administrador',
                      style: TextStyle(color: _T.error, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats Row ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCardData(
                  label: 'Empresas totales',
                  value: '$totalCompanies',
                  icon: Icons.business_rounded,
                  color: _T.primary),
              StatCardData(
                  label: 'Empresas activas',
                  value: '$activeCompanies',
                  icon: Icons.check_circle_rounded,
                  color: _T.success),
              StatCardData(
                  label: 'Suspendidas',
                  value: '$suspendedCompanies',
                  icon: Icons.block_rounded,
                  color: _T.warning),
              StatCardData(
                  label: 'Usuarios totales',
                  value: '$totalUsers',
                  icon: Icons.people_rounded,
                  color: _T.accent),
              StatCardData(
                  label: 'Usuarios activos',
                  value: '$activeUsers',
                  icon: Icons.person_rounded,
                  color: _T.success),
              StatCardData(
                  label: 'Sistema',
                  value: '99.9%',
                  icon: Icons.bolt_rounded,
                  color: _T.warning),
            ],
          ),
          const SizedBox(height: 24),

          // ── Acciones rápidas ──
          const Text('Acciones rápidas',
              style: TextStyle(
                  color: _T.textHi, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickAction(
                label: 'Nueva empresa',
                icon: Icons.add_business_rounded,
                color: _T.primary,
                onTap: () => context.go(AppRoutesAuth.companies),
              ),
              QuickAction(
                label: 'Ver usuarios',
                icon: Icons.people_rounded,
                color: _T.accent,
                onTap: () => context.go(AppRoutesAuth.users),
              ),
              QuickAction(
                label: 'Gestionar roles',
                icon: Icons.shield_rounded,
                color: _T.success,
                onTap: () => context.go(AppRoutesAuth.roles),
              ),
              QuickAction(
                label: 'Notificaciones',
                icon: Icons.notifications_rounded,
                color: _T.warning,
                onTap: () => context.go(AppRoutesAuth.notifications2),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Empresas recientes ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Empresas registradas',
                  style: TextStyle(
                      color: _T.textHi,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.go(AppRoutesAuth.companies),
                child: const Text('Ver todas',
                    style: TextStyle(color: _T.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          companies.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: _T.primary)),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: _T.error)),
            data: (list) => Column(
              children: list
                  .take(6)
                  .map((c) => _CompanyClickableTile(company: c))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Usuarios recientes ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Usuarios recientes',
                  style: TextStyle(
                      color: _T.textHi,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.go(AppRoutesAuth.users),
                child: const Text('Ver todos',
                    style: TextStyle(color: _T.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          allUsers.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: _T.primary)),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: _T.error)),
            data: (users) => Column(
              children:
                  users.take(5).map((u) => UserMiniTile(user: u)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de empresa clicable ──────────────────────────────────────────────────
class _CompanyClickableTile extends StatelessWidget {
  final Company company;
  const _CompanyClickableTile({required this.company});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/company/${company.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: _T.r12,
          border: const Border.fromBorderSide(BorderSide(color: _T.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: _T.primaryLo, borderRadius: _T.r8),
              child: const Icon(Icons.business_rounded,
                  color: _T.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name,
                      style: const TextStyle(
                          color: _T.textHi,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(company.email,
                      style: const TextStyle(color: _T.textMid, fontSize: 11)),
                ],
              ),
            ),
            StatusBadge(status: company.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _T.textLo, size: 16),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 7. PROFILE PAGE
// =============================================================================

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _successMsg;
  String? _errorMsg;

  // Change password
  final _passForm = GlobalKey<FormState>();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _changingPass = false;
  bool _showPassFields = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone;
    _addressCtrl.text = user.address;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    final user = ref.read(currentUserProvider).valueOrNull!;
    final result = await ref.read(firebaseServiceProvider).updateProfile(
          uid: user.uid,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
        );

    if (!mounted) return;
    setState(() {
      _saving = false;
    });

    switch (result) {
      case Success():
        setState(() {
          _editing = false;
          _successMsg = 'Perfil actualizado correctamente.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _successMsg = null);
        });
      case Failure(:final message):
        setState(() => _errorMsg = message);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    final bytes = await file.readAsBytes();
    final svc = ref.read(firebaseServiceProvider);
    final user = ref.read(currentUserProvider).valueOrNull!;

    final uploadResult = await svc.uploadProfilePhoto(
      uid: user.uid,
      bytes: bytes,
      filename: file.name,
    );

    if (!mounted) return;

    switch (uploadResult) {
      case Success(:final value):
        final updateResult = await svc.updateProfile(
          uid: user.uid,
          photoUrl: value,
        );
        setState(() => _uploadingPhoto = false);
        if (updateResult is Failure) {
          setState(() => _errorMsg = (updateResult as Failure).message);
        }
      case Failure(:final message):
        setState(() {
          _uploadingPhoto = false;
          _errorMsg = message;
        });
    }
  }

  Future<void> _changePassword() async {
    if (!_passForm.currentState!.validate()) return;
    setState(() => _changingPass = true);

    final svc = ref.read(firebaseServiceProvider);
    final user = ref.read(currentUserProvider).valueOrNull!;

    // Re-authenticate first
    final reauth = await svc.reauthenticate(
      email: user.email,
      password: _currPassCtrl.text,
    );

    if (!mounted) return;
    if (reauth is Failure) {
      setState(() {
        _changingPass = false;
        _errorMsg = (reauth as Failure).message;
      });
      return;
    }

    final result = await svc.changePassword(_newPassCtrl.text);
    if (!mounted) return;
    setState(() => _changingPass = false);

    switch (result) {
      case Success():
        setState(() {
          _showPassFields = false;
          _successMsg = 'Contraseña actualizada.';
          _currPassCtrl.clear();
          _newPassCtrl.clear();
          _confPassCtrl.clear();
        });
      case Failure(:final message):
        setState(() => _errorMsg = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _T.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _T.error))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _buildProfile(user);
      },
    );
  }

  Widget _buildProfile(AppUser user) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final company = companyAsync.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.primaryLo,
                      borderRadius: _T.r12,
                      border: Border.all(color: _T.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: _T.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Mi Perfil',
                          style: TextStyle(
                              color: _T.textHi,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Administra tu información personal y seguridad',
                          style: TextStyle(color: _T.textMid, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tarjeta de empresa (solo si tiene empresa asignada)
              if (company != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _T.primaryLo,
                    borderRadius: _T.r16,
                    border: Border.all(color: _T.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _T.primary.withOpacity(0.15),
                          borderRadius: _T.r12,
                          border:
                              Border.all(color: _T.primary.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.business_rounded,
                            color: _T.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Empresa asociada',
                                style: TextStyle(
                                    color: _T.textLo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(company.name,
                                style: const TextStyle(
                                    color: _T.textHi,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(company.email,
                                style: const TextStyle(
                                    color: _T.textMid, fontSize: 12)),
                          ],
                        ),
                      ),
                      StatusBadge(status: company.status),
                    ],
                  ),
                ),

              if (_successMsg != null)
                _AnimatedBanner(
                  message: _successMsg!,
                  color: _T.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              if (_errorMsg != null)
                _AnimatedBanner(
                  message: _errorMsg!,
                  color: _T.error,
                  icon: Icons.error_outline_rounded,
                ),

              // Responsive layout
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 640;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 260,
                            child: _AvatarCard(
                              user: user,
                              uploadingPhoto: _uploadingPhoto,
                              onPickPhoto: _pickAndUploadPhoto,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                InfoCard(
                                  user: user,
                                  editing: _editing,
                                  saving: _saving,
                                  formKey: _form,
                                  nameCtrl: _nameCtrl,
                                  emailCtrl: _emailCtrl,
                                  phoneCtrl: _phoneCtrl,
                                  addressCtrl: _addressCtrl,
                                  onEdit: () => setState(() => _editing = true),
                                  onCancel: () => setState(() {
                                    _editing = false;
                                    _loadUser();
                                  }),
                                  onSave: _save,
                                ),
                                const SizedBox(height: 16),
                                SecurityCard(
                                  passForm: _passForm,
                                  currPassCtrl: _currPassCtrl,
                                  newPassCtrl: _newPassCtrl,
                                  confPassCtrl: _confPassCtrl,
                                  showPassFields: _showPassFields,
                                  changingPass: _changingPass,
                                  onToggle: () => setState(
                                      () => _showPassFields = !_showPassFields),
                                  onChangePassword: _changePassword,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _AvatarCard(
                            user: user,
                            uploadingPhoto: _uploadingPhoto,
                            onPickPhoto: _pickAndUploadPhoto,
                          ),
                          const SizedBox(height: 16),
                          InfoCard(
                            user: user,
                            editing: _editing,
                            saving: _saving,
                            formKey: _form,
                            nameCtrl: _nameCtrl,
                            emailCtrl: _emailCtrl,
                            phoneCtrl: _phoneCtrl,
                            addressCtrl: _addressCtrl,
                            onEdit: () => setState(() => _editing = true),
                            onCancel: () => setState(() {
                              _editing = false;
                              _loadUser();
                            }),
                            onSave: _save,
                          ),
                          const SizedBox(height: 16),
                          SecurityCard(
                            passForm: _passForm,
                            currPassCtrl: _currPassCtrl,
                            newPassCtrl: _newPassCtrl,
                            confPassCtrl: _confPassCtrl,
                            showPassFields: _showPassFields,
                            changingPass: _changingPass,
                            onToggle: () => setState(
                                () => _showPassFields = !_showPassFields),
                            onChangePassword: _changePassword,
                          ),
                        ],
                      );
              }),

              const SizedBox(height: 16),

              // Roles & permisos
              CardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _T.primaryLo,
                              borderRadius: _T.r8,
                            ),
                            child: const Icon(Icons.shield_rounded,
                                color: _T.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text('Roles y permisos',
                              style: TextStyle(
                                  color: _T.textHi,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            user.roles.map((r) => RoleChip(role: r)).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: _T.divider),
                      const SizedBox(height: 10),
                      const Text('Permisos activos',
                          style: TextStyle(
                              color: _T.textMid,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.permissions
                            .map((p) => PermBadge(permission: p))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 8. NOTIFICATIONS PAGE
// =============================================================================

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final notifsAsync = ref.watch(notificationsProvider(user.uid));
    final svc = ref.read(firebaseServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const NotificationsPage(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Text('Notificaciones1',
                      style: TextStyle(
                          color: _T.textHi,
                          fontSize: 22,
                          fontWeight: FontWeight.w700))),
              TextButton.icon(
                onPressed: () => svc.markAllNotificationsRead(user.uid),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Marcar todas como leídas'),
                style: TextButton.styleFrom(foregroundColor: _T.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _T.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: _T.error))),
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            color: _T.textLo, size: 48),
                        SizedBox(height: 12),
                        Text('No hay notificaciones',
                            style: TextStyle(color: _T.textMid, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: _T.divider, height: 1),
                  itemBuilder: (_, i) => _NotifTile(notif: notifs[i], svc: svc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final FirebaseService svc;
  const _NotifTile({required this.notif, required this.svc});

  Color get _typeColor => switch (notif.type) {
        NotificationType.success => _T.success,
        NotificationType.warning => _T.warning,
        NotificationType.error => _T.error,
        NotificationType.system => _T.primary,
        NotificationType.info => _T.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.read ? Colors.transparent : _T.primaryLo,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_rounded, color: _typeColor, size: 18),
        ),
        title: Text(notif.title,
            style: TextStyle(
              color: _T.textHi,
              fontSize: 13,
              fontWeight: notif.read ? FontWeight.w400 : FontWeight.w600,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notif.body,
                style: const TextStyle(color: _T.textMid, fontSize: 12)),
            const SizedBox(height: 4),
            Text(formatDate(notif.createdAt),
                style: const TextStyle(color: _T.textLo, fontSize: 11)),
          ],
        ),
        trailing: notif.read
            ? null
            : IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: _T.textMid),
                tooltip: 'Marcar como leída',
                onPressed: () => svc.markNotificationRead(notif.id),
              ),
      ),
    );
  }
}

// =============================================================================
// 9. ROLES MANAGEMENT PAGE
// =============================================================================

class RolesManagementPage extends ConsumerWidget {
  const RolesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final svc = ref.read(firebaseServiceProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isSuperAdmin = currentUser?.isSuperAdmin == true;

    // Roles del sistema siempre visibles
    final systemRoles = AppRole.values
        .map((r) => RoleDefinition(
              id: r.value,
              name: r.value,
              displayName: r.displayName,
              description: _roleDesc(r),
              permissions: _defaultPermissions(r),
              createdAt: DateTime(2024),
            ))
        .toList();

    return DefaultTabController(
      length: isSuperAdmin ? 3 : 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Roles y permisos',
                style: TextStyle(
                    color: _T.textHi,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TabBar(
              isScrollable: true,
              labelColor: _T.primary,
              unselectedLabelColor: _T.textMid,
              indicatorColor: _T.primary,
              tabs: [
                const Tab(text: 'Roles del sistema'),
                if (isSuperAdmin) const Tab(text: 'Roles personalizados'),
                const Tab(text: 'Usuarios y roles'),
              ],
            ),
            const Divider(color: _T.divider, height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Roles del sistema (siempre, no editables)
                  SystemRolesTab(roles: systemRoles),

                  // Roles personalizados solo superAdmin
                  if (isSuperAdmin)
                    rolesAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: _T.primary)),
                      error: (e, _) => Text('Error: $e'),
                      data: (roles) => _RolesTab(roles: roles, svc: svc),
                    ),

                  // Usuarios con roles
                  usersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: _T.primary)),
                    error: (e, _) => Text('Error: $e'),
                    data: (users) => _UsersRolesTab(users: users, svc: svc),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleDesc(AppRole r) => switch (r) {
        AppRole.superAdmin => 'Control total del sistema',
        AppRole.companyAdmin => 'Gestiona usuarios y dispositivos',
        AppRole.manager => 'Supervisa equipos y contenido',
        AppRole.editor => 'Crea y edita contenido',
        AppRole.user => 'Acceso básico al sistema',
      };

  List<AppPermission> _defaultPermissions(AppRole r) => switch (r) {
        AppRole.superAdmin => AppPermission.values.toList(),
        AppRole.companyAdmin => [
            AppPermission.usersView,
            AppPermission.usersCreate,
            AppPermission.usersEdit,
            AppPermission.usersDelete,
            AppPermission.rolesView,
          ],
        AppRole.manager => [
            AppPermission.usersView,
            AppPermission.rolesView,
          ],
        AppRole.editor => [AppPermission.usersView],
        AppRole.user => [],
      };
}

class _RolesTab extends StatelessWidget {
  final List<RoleDefinition> roles;
  final FirebaseService svc;
  const _RolesTab({required this.roles, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateRoleDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Nuevo rol'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final role = roles[i];
              final appRole = AppRole.fromString(role.name);
              return CardContainer(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _roleColor(appRole).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield_rounded,
                        color: _roleColor(appRole), size: 18),
                  ),
                  title: Text(role.displayName,
                      style: const TextStyle(
                          color: _T.textHi,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: role.permissions
                          .map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _T.primaryLo,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _T.primary.withOpacity(0.2)),
                                ),
                                child: Text(
                                  _permLabel(p),
                                  style: const TextStyle(
                                      color: _T.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: _T.textMid),
                        onPressed: () => _showEditRoleDialog(context, role),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: _T.error),
                        onPressed: () => _confirmDelete(context, role),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, RoleDefinition role) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _T.border),
        ),
        title: const Text('Eliminar rol', style: TextStyle(color: _T.textHi)),
        content: Text(
            '¿Eliminar "${role.displayName}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              await svc.deleteRole(role.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.error, minimumSize: const Size(80, 36)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final displayCtrl = TextEditingController();
    final selected = <AppPermission>{};
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _T.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _T.border),
          ),
          title:
              const Text('Crear nuevo rol', style: TextStyle(color: _T.textHi)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre interno (sin espacios)',
                        style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: _T.textHi, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ej: gestor_contenido',
                        hintStyle:
                            const TextStyle(color: _T.textLo, fontSize: 13),
                        filled: true,
                        fillColor: _T.surface,
                        border: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(color: _T.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(color: _T.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(
                                color: _T.primary, width: 1.5)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Nombre visible',
                        style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: displayCtrl,
                      style: const TextStyle(color: _T.textHi, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ej: Gestor de Contenido',
                        hintStyle:
                            const TextStyle(color: _T.textLo, fontSize: 13),
                        filled: true,
                        fillColor: _T.surface,
                        border: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(color: _T.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(color: _T.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: _T.r8,
                            borderSide: const BorderSide(
                                color: _T.primary, width: 1.5)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Permisos',
                        style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    ...AppPermission.values.map((perm) => CheckboxListTile(
                          dense: true,
                          value: selected.contains(perm),
                          onChanged: (v) {
                            setState(() {
                              if (v == true)
                                selected.add(perm);
                              else
                                selected.remove(perm);
                            });
                          },
                          title: Text(_permLabel(perm),
                              style: const TextStyle(
                                  color: _T.textMid, fontSize: 13)),
                          subtitle: Text(_permDesc(perm),
                              style: const TextStyle(
                                  color: _T.textLo, fontSize: 11)),
                          activeColor: _T.primary,
                          checkColor: Colors.white,
                          side: const BorderSide(color: _T.textLo),
                        )),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancelar', style: TextStyle(color: _T.textMid)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now();
                await svc.createRole(RoleDefinition(
                  id: nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                  name: nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                  displayName: displayCtrl.text.trim(),
                  description: 'Rol personalizado',
                  permissions: selected.toList(),
                  createdAt: now,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, RoleDefinition role) {
    final selected = Set<AppPermission>.from(role.permissions);
    final displayCtrl = TextEditingController(text: role.displayName);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _T.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _T.border),
          ),
          title: Text('Editar: ${role.displayName}',
              style: const TextStyle(color: _T.textHi)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre visible',
                      style: TextStyle(color: _T.textMid, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: displayCtrl,
                    style: const TextStyle(color: _T.textHi, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _T.surface,
                      border: OutlineInputBorder(
                          borderRadius: _T.r8,
                          borderSide: const BorderSide(color: _T.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: _T.r8,
                          borderSide: const BorderSide(color: _T.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: _T.r8,
                          borderSide:
                              const BorderSide(color: _T.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Permisos disponibles',
                      style: TextStyle(color: _T.textMid, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...AppPermission.values.map((perm) => CheckboxListTile(
                        dense: true,
                        value: selected.contains(perm),
                        onChanged: (v) {
                          setState(() {
                            if (v == true)
                              selected.add(perm);
                            else
                              selected.remove(perm);
                          });
                        },
                        title: Text(_permLabel(perm),
                            style: const TextStyle(
                                color: _T.textMid, fontSize: 13)),
                        subtitle: Text(_permDesc(perm),
                            style: const TextStyle(
                                color: _T.textLo, fontSize: 11)),
                        activeColor: _T.primary,
                        checkColor: Colors.white,
                        side: const BorderSide(color: _T.textLo),
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancelar', style: TextStyle(color: _T.textMid)),
            ),
            ElevatedButton(
              onPressed: () async {
                await svc.updateRole(RoleDefinition(
                  id: role.id,
                  name: role.name,
                  displayName: displayCtrl.text.trim().isEmpty
                      ? role.displayName
                      : displayCtrl.text.trim(),
                  description: role.description,
                  permissions: selected.toList(),
                  createdAt: role.createdAt,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _permLabel(AppPermission p) => switch (p) {
        AppPermission.companiesView => '👁 Ver empresas',
        AppPermission.companiesCreate => '➕ Crear empresas',
        AppPermission.companiesEdit => '✏️ Editar empresas',
        AppPermission.companiesDelete => '🗑 Eliminar empresas',
        AppPermission.usersView => '👁 Ver usuarios',
        AppPermission.usersCreate => '➕ Crear usuarios',
        AppPermission.usersEdit => '✏️ Editar usuarios',
        AppPermission.usersDelete => '🗑 Eliminar usuarios',
        AppPermission.rolesView => '👁 Ver roles',
        AppPermission.rolesCreate => '➕ Crear roles',
        AppPermission.rolesEdit => '✏️ Editar roles',
        AppPermission.rolesDelete => '🗑 Eliminar roles',
        _ => p.value,
      };

  String _permDesc(AppPermission p) => switch (p) {
        AppPermission.companiesView =>
          'Puede ver la lista de empresas registradas',
        AppPermission.companiesCreate =>
          'Puede registrar nuevas empresas en el sistema',
        AppPermission.companiesEdit =>
          'Puede modificar datos de empresas existentes',
        AppPermission.companiesDelete => 'Puede eliminar o desactivar empresas',
        AppPermission.usersView => 'Puede ver la lista de usuarios del sistema',
        AppPermission.usersCreate => 'Puede crear nuevas cuentas de usuario',
        AppPermission.usersEdit => 'Puede modificar datos y roles de usuarios',
        AppPermission.usersDelete => 'Puede eliminar o desactivar usuarios',
        AppPermission.rolesView => 'Puede ver los roles y sus permisos',
        AppPermission.rolesCreate => 'Puede crear nuevos roles personalizados',
        AppPermission.rolesEdit =>
          'Puede modificar permisos de roles existentes',
        AppPermission.rolesDelete => 'Puede eliminar roles del sistema',
        _ => 'Permiso del sistema',
      };

  Color _roleColor(AppRole role) => switch (role) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.companyAdmin => const Color(0xFF6366F1),
        AppRole.manager => const Color(0xFF38BDF8),
        AppRole.editor => const Color(0xFF22C55E),
        AppRole.user => const Color(0xFFF59E0B),
      };
}

class _UsersRolesTab extends StatelessWidget {
  final List<AppUser> users;
  final FirebaseService svc;
  const _UsersRolesTab({required this.users, required this.svc});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final user = users[i];
        return CardContainer(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Avatar(user: user, size: 40),
            title: Text(user.name,
                style: const TextStyle(
                    color: _T.textHi,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: user.roles.map((r) => RoleChip(role: r)).toList(),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.manage_accounts_rounded,
                  size: 18, color: _T.textMid),
              onPressed: () => _showAssignRoleDialog(context, user),
            ),
          ),
        );
      },
    );
  }

  void _showAssignRoleDialog(BuildContext context, AppUser user) {
    final selected = Set<AppRole>.from(user.roles);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _T.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _T.border),
          ),
          title: Text('Roles de ${user.name}',
              style: const TextStyle(color: _T.textHi)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppRole.values.map((role) {
              return CheckboxListTile(
                dense: true,
                value: selected.contains(role),
                onChanged: (v) {
                  setState(() {
                    if (v == true)
                      selected.add(role);
                    else
                      selected.remove(role);
                  });
                },
                title: Text(role.displayName,
                    style: const TextStyle(color: _T.textMid, fontSize: 13)),
                activeColor: _T.primary,
                checkColor: Colors.white,
                side: const BorderSide(color: _T.textLo),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancelar', style: TextStyle(color: _T.textMid)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selected.isEmpty) return;
                await svc.updateUserRoles(
                    uid: user.uid, roles: selected.toList());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 10. DASHBOARD HOME (placeholder)
// =============================================================================

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final allUsers = ref.watch(allUsersProvider);
    final totalUsers = allUsers.valueOrNull?.length ?? 0;

    final isCompanyAdmin = user?.isCompanyAdmin ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${user?.name ?? '—'} 👋',
                      style: const TextStyle(
                          color: _T.textHi,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  Text(
                    'Bienvenido al panel · ${user?.roles.map((r) => r.displayName).join(', ')}',
                    style: const TextStyle(color: _T.textMid, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCardData(
                label: 'Dispositivos',
                value: '0',
                icon: Icons.tv_rounded,
                color: _T.primary,
              ),
              StatCardData(
                label: 'Usuarios',
                value: isCompanyAdmin ? '$totalUsers' : '—',
                icon: Icons.people_rounded,
                color: _T.accent,
              ),
              StatCardData(
                label: 'Uptime',
                value: '99.9%',
                icon: Icons.bolt_rounded,
                color: _T.success,
              ),
              StatCardData(
                label: 'Latencia',
                value: '<50ms',
                icon: Icons.speed_rounded,
                color: _T.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 11. ERROR & ACCESS DENIED
// =============================================================================
class _ErrorPage extends ConsumerWidget {
  final String error;
  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isSuperAdmin ?? false;

    return Scaffold(
      backgroundColor: _T.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _T.error, size: 48),
            const SizedBox(height: 12),
            Text('Error 404 — $error',
                style: const TextStyle(color: _T.textMid)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(
                isSuperAdmin
                    ? AppRoutesAuth.superDashboard
                    : AppRoutesAuth.dashboard,
              ),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  final String permission;
  const _AccessDeniedPage({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _T.error.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outlined, color: _T.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Acceso denegado',
                style: TextStyle(
                    color: _T.textHi,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Necesitas el permiso: $permission',
                style: const TextStyle(color: _T.textMid, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutesAuth.dashboard),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// USERS MANAGEMENT PAGE
// =============================================================================

class UsersManagementPage extends ConsumerStatefulWidget {
  const UsersManagementPage({super.key});

  @override
  ConsumerState<UsersManagementPage> createState() =>
      _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<UsersManagementPage> {
  String _search = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
// ... (currentUser ya se lee abajo, mueve esa línea arriba o elimina el duplicado)
    final svc = ref.read(firebaseServiceProvider);
    final canCreate =
        currentUser?.hasPermission(AppPermission.usersCreate) ?? false;
    final canEdit =
        currentUser?.hasPermission(AppPermission.usersEdit) ?? false;
    final canDelete =
        currentUser?.hasPermission(AppPermission.usersDelete) ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.primaryLo,
                      borderRadius: _T.r12,
                      border: Border.all(color: _T.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.people_rounded,
                        color: _T.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usuarios',
                          style: TextStyle(
                              color: _T.textHi,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text('Gestiona cuentas y accesos',
                          style: TextStyle(color: _T.textMid, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              if (canCreate)
                ElevatedButton.icon(
                  onPressed: () => _showCreateUserDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Nuevo usuario'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Filters ──
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final searchField = _SearchField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            );
            final filters = Row(
              children: [
                _FilterChip2(
                  label: 'Todos',
                  selected: _roleFilter == 'all',
                  onTap: () => setState(() => _roleFilter = 'all'),
                ),
                const SizedBox(width: 6),
                ...AppRole.values.map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip2(
                        label: r.displayName,
                        selected: _roleFilter == r.value,
                        onTap: () => setState(() => _roleFilter = r.value),
                        color: _roleColor(r),
                      ),
                    )),
              ],
            );

            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal, child: filters),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 12),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal, child: filters),
                    ],
                  );
          }),

          const SizedBox(height: 16),

          // ── Table / List ──
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _T.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: _T.error))),
              data: (users) {
                // Filtra por empresa: solo muestra usuarios de la misma compañía
                final companyId = currentUser?.companyId;
                final companyUsers = (currentUser?.isSuperAdmin == true)
                    ? users
                    : users.where((u) => u.companyId == companyId).toList();

                final filtered = companyUsers.where((u) {
                  final matchSearch = _search.isEmpty ||
                      u.name.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search);
                  final matchRole = _roleFilter == 'all' ||
                      u.roles.any((r) => r.value == _roleFilter);
                  return matchSearch && matchRole;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              color: _T.primaryLo, shape: BoxShape.circle),
                          child: const Icon(Icons.people_outline_rounded,
                              color: _T.primary, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('No se encontraron usuarios',
                            style: TextStyle(
                                color: _T.textHi,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Intenta con otro filtro o búsqueda',
                            style: TextStyle(color: _T.textMid, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  return isDesktop
                      ? _UsersTable(
                          users: filtered,
                          svc: svc,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          currentUid: currentUser?.uid ?? '',
                          onEdit: (u) => _showEditUserDialog(context, u),
                        )
                      : _UsersList(
                          users: filtered,
                          svc: svc,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          currentUid: currentUser?.uid ?? '',
                          onEdit: (u) => _showEditUserDialog(context, u),
                        );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Create user dialog (llama RegisterPage en Alert) ──
  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
          child: Container(
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: _T.r20,
              border: Border.all(color: _T.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del dialog
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _T.primaryLo, borderRadius: _T.r8),
                        child: const Icon(Icons.person_add_rounded,
                            color: _T.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Crear nuevo usuario',
                          style: TextStyle(
                              color: _T.textHi,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: _T.textMid, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _T.divider, height: 20),
                // Formulario embebido
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _InlineRegisterForm(
                      onSuccess: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit user dialog ──
  void _showEditUserDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (_) => _EditUserDialog(user: user),
    );
  }

  Color _roleColor(AppRole r) => switch (r) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.companyAdmin => const Color(0xFF6366F1),
        AppRole.manager => const Color(0xFF38BDF8),
        AppRole.editor => const Color(0xFF22C55E),
        AppRole.user => const Color(0xFFF59E0B),
      };
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: _T.r12,
        border: Border.all(color: _T.border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: _T.textHi, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o email...',
          hintStyle: TextStyle(color: _T.textLo, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _T.textMid, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          filled: false,
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip2 extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip2({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? _T.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : _T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withOpacity(0.5) : _T.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c : _T.textMid,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<AppUser> users;
  final FirebaseService svc;
  final bool canEdit, canDelete;
  final String currentUid;
  final void Function(AppUser) onEdit;

  const _UsersTable({
    required this.users,
    required this.svc,
    required this.canEdit,
    required this.canDelete,
    required this.currentUid,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.divider)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 48),
                Expanded(flex: 3, child: _TableHeader('Usuario')),
                Expanded(flex: 3, child: _TableHeader('Email')),
                Expanded(flex: 2, child: _TableHeader('Rol')),
                Expanded(flex: 2, child: _TableHeader('Estado')),
                Expanded(flex: 2, child: _TableHeader('Último acceso')),
                SizedBox(width: 100, child: _TableHeader('Acciones')),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: _T.divider, height: 1),
              itemBuilder: (_, i) => _UserTableRow(
                user: users[i],
                svc: svc,
                canEdit: canEdit,
                canDelete: canDelete,
                isSelf: users[i].uid == currentUid,
                onEdit: onEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: _T.textLo,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}

class _UserTableRow extends StatelessWidget {
  final AppUser user;
  final FirebaseService svc;
  final bool canEdit, canDelete, isSelf;
  final void Function(AppUser) onEdit;

  const _UserTableRow({
    required this.user,
    required this.svc,
    required this.canEdit,
    required this.canDelete,
    required this.isSelf,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = user.status == 'suspended';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          SizedBox(
            width: 48,
            child: Avatar(user: user, size: 36),
          ),
          // Nombre
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: TextStyle(
                      color: isBlocked ? _T.textMid : _T.textHi,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: isBlocked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    )),
                if (isSelf)
                  const Text('(tú)',
                      style: TextStyle(color: _T.primary, fontSize: 10)),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 3,
            child: Text(user.email,
                style: const TextStyle(color: _T.textMid, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          // Roles
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: user.roles.map((r) => RoleChip(role: r)).toList(),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: StatusBadge(status: user.status),
          ),
          // Last login
          Expanded(
            flex: 2,
            child: Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  user.lastLogin != null
                      ? formatDate(user.lastLogin!)
                      : 'Sin acceso',
                  style: const TextStyle(color: _T.textLo, fontSize: 11),
                )),
          ),
          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: _T.primary,
                    tooltip: 'Editar',
                    onTap: () => onEdit(user),
                  ),
                SizedBox(
                  width: 2,
                ),
                if (canEdit && !isSelf)
                  _ActionBtn(
                    icon: isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    color: isBlocked ? _T.success : _T.warning,
                    tooltip: isBlocked ? 'Desbloquear' : 'Bloquear',
                    onTap: () => _toggleBlock(context, user, svc),
                  ),
                SizedBox(
                  width: 2,
                ),
                if (canDelete && !isSelf)
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _T.error,
                    tooltip: 'Eliminar',
                    onTap: () => _confirmDelete(context, user, svc),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBlock(
      BuildContext context, AppUser user, FirebaseService svc) async {
    final newStatus = user.status == 'suspended' ? 'active' : 'suspended';
    await svc.updateUserStatus(uid: user.uid, status: newStatus);
  }

  void _confirmDelete(BuildContext context, AppUser user, FirebaseService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _T.border),
        ),
        title:
            const Text('Eliminar usuario', style: TextStyle(color: _T.textHi)),
        content: Text(
            '¿Eliminar la cuenta de "${user.name}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Soft delete: marca como inactivo
              await svc.updateUserStatus(uid: user.uid, status: 'inactive');
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.error, minimumSize: const Size(80, 36)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: _T.r8,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: _T.r8,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  final List<AppUser> users;
  final FirebaseService svc;
  final bool canEdit, canDelete;
  final String currentUid;
  final void Function(AppUser) onEdit;

  const _UsersList({
    required this.users,
    required this.svc,
    required this.canEdit,
    required this.canDelete,
    required this.currentUid,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final user = users[i];
        final isSelf = user.uid == currentUid;
        final isBlocked = user.status == 'suspended';

        return CardContainer(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(user: user, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(user.name,
                                    style: TextStyle(
                                      color: _T.textHi,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: isBlocked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    )),
                              ),
                              if (isSelf)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _T.primaryLo,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('tú',
                                      style: TextStyle(
                                          color: _T.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          Text(user.email,
                              style: const TextStyle(
                                  color: _T.textMid, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    StatusBadge(status: user.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: user.roles.map((r) => RoleChip(role: r)).toList(),
                ),
                if (user.lastLogin != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: _T.textLo),
                      const SizedBox(width: 4),
                      Text(formatDate(user.lastLogin!),
                          style:
                              const TextStyle(color: _T.textLo, fontSize: 11)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(color: _T.divider, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit)
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: _T.primary,
                        tooltip: 'Editar',
                        onTap: () => onEdit(user),
                      ),
                    const SizedBox(width: 6),
                    if (canEdit && !isSelf)
                      _ActionBtn(
                        icon: isBlocked
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        color: isBlocked ? _T.success : _T.warning,
                        tooltip: isBlocked ? 'Desbloquear' : 'Bloquear',
                        onTap: () async => await svc.updateUserStatus(
                          uid: user.uid,
                          status: user.status == 'suspended'
                              ? 'active'
                              : 'suspended',
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (canDelete && !isSelf)
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        color: _T.error,
                        tooltip: 'Eliminar',
                        onTap: () => _confirmDelete(context, user, svc),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppUser user, FirebaseService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _T.border),
        ),
        title:
            const Text('Eliminar usuario', style: TextStyle(color: _T.textHi)),
        content: Text('¿Eliminar la cuenta de "${user.name}"?',
            style: const TextStyle(color: _T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              await svc.updateUserStatus(uid: user.uid, status: 'inactive');
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.error, minimumSize: const Size(80, 36)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

// ── Edit User Dialog ──────────────────────────────────────────────────────────

class _EditUserDialog extends ConsumerStatefulWidget {
  final AppUser user;
  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late Set<AppRole> _roles;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _addressCtrl = TextEditingController(text: widget.user.address);
    _roles = Set.from(widget.user.roles);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_roles.isEmpty) {
      setState(() => _error = 'Asigna al menos un rol');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final svc = ref.read(firebaseServiceProvider);

    final profileResult = await svc.updateProfile(
      uid: widget.user.uid,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (profileResult is Failure) {
      setState(() {
        _saving = false;
        _error = (profileResult as Failure).message;
      });
      return;
    }

    final rolesResult = await svc.updateUserRoles(
      uid: widget.user.uid,
      roles: _roles.toList(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (rolesResult is Failure) {
      setState(() => _error = (rolesResult as Failure).message);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: _T.r20,
            border: Border.all(color: _T.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                child: Row(
                  children: [
                    Avatar(user: widget.user, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user.name,
                              style: const TextStyle(
                                  color: _T.textHi,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          Text(widget.user.email,
                              style: const TextStyle(
                                  color: _T.textMid, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: _T.textMid, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: _T.divider, height: 20),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ErrorBanner(message: _error!),
                      ProfileField(
                        label: 'Nombre',
                        controller: _nameCtrl,
                        icon: Icons.badge_outlined,
                        enabled: true,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      ProfileField(
                        label: 'Teléfono',
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        enabled: true,
                        validator: null,
                      ),
                      const SizedBox(height: 12),
                      ProfileField(
                        label: 'Dirección',
                        controller: _addressCtrl,
                        icon: Icons.location_on_outlined,
                        enabled: true,
                        validator: null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Roles',
                          style: TextStyle(
                              color: _T.textMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ...AppRole.values.map((role) {
                        final isSelected = _roles.contains(role);
                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true)
                                _roles.add(role);
                              else
                                _roles.remove(role);
                            });
                          },
                          title: Text(role.displayName,
                              style: const TextStyle(
                                  color: _T.textMid, fontSize: 13)),
                          activeColor: _T.primary,
                          checkColor: Colors.white,
                          side: const BorderSide(color: _T.textLo),
                        );
                      }),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline Register Form (dentro del Alert) ───────────────────────────────────

// ── Inline Register Form ──────────────────────────────────────────────────────

class _InlineRegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _InlineRegisterForm({required this.onSuccess});

  @override
  ConsumerState<_InlineRegisterForm> createState() =>
      _InlineRegisterFormState();
}

class _InlineRegisterFormState extends ConsumerState<_InlineRegisterForm>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  AppRole _role = AppRole.user;
  String? _selectedCompanyId; // ← NUEVO: empresa seleccionada por superAdmin
  bool _loading = false;
  bool _showPass = false;
  bool _done = false;
  String? _createdName;
  String? _error;

  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _successFade = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final isSuperAdmin = currentUser?.isSuperAdmin == true;

    // Validar empresa si es superAdmin
    if (isSuperAdmin && _selectedCompanyId == null) {
      setState(() => _error = 'Debes seleccionar una empresa para el usuario');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Si es superAdmin usa la empresa seleccionada, si no usa la propia
    final companyId =
        isSuperAdmin ? _selectedCompanyId : currentUser?.companyId;

    final result = await ref.read(firebaseServiceProvider).createUserAsAdmin(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          role: _role,
          companyId: companyId,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success(:final value):
        setState(() {
          _done = true;
          _createdName = value.name;
        });
        _successCtrl.forward();
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildSuccess();
    return _buildForm();
  }

  Widget _buildSuccess() {
    return FadeTransition(
      opacity: _successFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _successScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _T.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _T.success.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: _T.success, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text('¡Usuario creado!',
                style: const TextStyle(
                    color: _T.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '${_createdName ?? 'El usuario'} ya puede iniciar sesión.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _T.textMid, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onSuccess,
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isSuperAdmin = currentUser?.isSuperAdmin == true;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ErrorBanner(message: _error!),

          ProfileField(
            label: 'Nombre completo',
            controller: _nameCtrl,
            icon: Icons.person_outline_rounded,
            enabled: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          ProfileField(
            label: 'Email',
            controller: _emailCtrl,
            icon: Icons.mail_outline_rounded,
            enabled: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Contraseña'),
              TextFormField(
                controller: _passCtrl,
                obscureText: !_showPass,
                style: inputStyle,
                decoration: inputDeco(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  suffix: togglePassButton(
                    show: _showPass,
                    onTap: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileField(
            label: 'Confirmar contraseña',
            controller: _confirmCtrl,
            icon: Icons.lock_rounded,
            enabled: true,
            obscure: true,
            validator: (v) => v != _passCtrl.text ? 'No coinciden' : null,
          ),
          const SizedBox(height: 16),

          // ── SELECTOR DE EMPRESA (solo superAdmin) ──────────────────────────
          if (isSuperAdmin) ...[
            const FieldLabel('Empresa asignada'),
            const SizedBox(height: 6),
            _CompanyDropdown(
              selectedId: _selectedCompanyId,
              onChanged: (id) => setState(() => _selectedCompanyId = id),
            ),
            const SizedBox(height: 16),
          ],

          const FieldLabel('Rol del usuario'),
          const SizedBox(height: 8),
          RoleSelector(
            selected: _role,
            onChanged: (r) => setState(() => _role = r),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Crear usuario'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Company Dropdown (para superAdmin al crear usuario) ───────────────────────

class _CompanyDropdown extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const _CompanyDropdown({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      loading: () => Container(
        height: 48,
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: _T.r12,
          border: Border.all(color: _T.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _T.primary),
          ),
        ),
      ),
      error: (e, _) => Text('Error: $e',
          style: const TextStyle(color: _T.error, fontSize: 12)),
      data: (companies) {
        final active = companies.where((c) => c.isActive).toList();

        if (active.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: _T.r12,
              border: Border.all(color: _T.border),
            ),
            child: const Text(
              'No hay empresas activas disponibles',
              style: TextStyle(color: _T.textLo, fontSize: 13),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: _T.r12,
            border: Border.all(
              color:
                  selectedId == null ? _T.border : _T.primary.withOpacity(0.6),
              width: selectedId == null ? 1 : 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, size: 16, color: _T.textLo),
                    SizedBox(width: 8),
                    Text('Seleccionar empresa...',
                        style: TextStyle(color: _T.textLo, fontSize: 13)),
                  ],
                ),
              ),
              isExpanded: true,
              dropdownColor: _T.card,
              icon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.expand_more_rounded,
                    color: _T.textMid, size: 18),
              ),
              borderRadius: _T.r12,
              items: active.map((company) {
                return DropdownMenuItem<String>(
                  value: company.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _T.primaryLo,
                            borderRadius: _T.r8,
                          ),
                          child: const Icon(Icons.business_rounded,
                              color: _T.primary, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(company.name,
                                  style: const TextStyle(
                                      color: _T.textHi,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              Text(company.email,
                                  style: const TextStyle(
                                      color: _T.textMid, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class SignageApp extends ConsumerWidget {
  const SignageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router =
        ref.watch(routerProvider); // ← este ahora es el de app_router.dart

    return MaterialApp.router(
      title: 'SignageOS Enterprise',
      debugShowCheckedModeBanner: false,
      theme: _T.theme,
      routerConfig: router,
      builder: (context, child) => NotificationPushOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

// ── Animated Banner ──────────────────────────────────────────────────────────

class _AnimatedBanner extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _AnimatedBanner(
      {required this.message, required this.color, required this.icon});

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: _T.r12,
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.message,
                    style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar Card ───────────────────────────────────────────────────────────────

class _AvatarCard extends StatefulWidget {
  final AppUser user;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;
  const _AvatarCard(
      {required this.user,
      required this.uploadingPhoto,
      required this.onPickPhoto});

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        lowerBound: 0.95,
        upperBound: 1.0);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: CardContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _T.primary.withOpacity(0.25),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  Avatar(user: widget.user, size: 84),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: widget.uploadingPhoto ? null : widget.onPickPhoto,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _T.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.surface, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _T.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: widget.uploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(widget.user.name,
                  style: const TextStyle(
                      color: _T.textHi,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.user.email,
                  style: const TextStyle(color: _T.textMid, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children:
                    widget.user.roles.map((r) => RoleChip(role: r)).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(color: _T.divider),
              const SizedBox(height: 12),
              // Status tile
              _MiniInfoRow(
                icon: Icons.circle,
                iconColor: widget.user.isActive ? _T.success : _T.error,
                label: 'Estado',
                value: widget.user.status,
              ),
              const SizedBox(height: 8),
              _MiniInfoRow(
                icon: Icons.access_time_rounded,
                iconColor: _T.textMid,
                label: 'Último acceso',
                value: widget.user.lastLogin != null
                    ? formatDate(widget.user.lastLogin!)
                    : 'Primera sesión',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  const _MiniInfoRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: _T.textLo, fontSize: 11)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: _T.textMid, fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
