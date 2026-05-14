// =============================================================================
// auth_system.dart
// Complete Auth System — UI, Routing, Guards, RBAC, Profile, Notifications
// SignageOS Enterprise — Flutter Web + Material 3
// =============================================================================
// This file contains:
//  • AppRouter with GoRouter + route guards
//  • AuthWrapper (auto-redirect based on auth state)
//  • LoginPage
//  • RegisterPage
//  • ForgotPasswordPage
//  • ProfilePage
//  • NotificationsPanel
//  • RolesManagementPage
//  • PermissionGuard widget
//  • All supporting widgets
// =============================================================================

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:typed_data';
import 'package:digitaltv/route/route.dart';
import 'package:digitaltv/ui/panel/device_portal_screen.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:digitaltv/ui/panel/panel2.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/panel/playlist2.dart';
import 'package:digitaltv/ui/dashboard.dart';
import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/notification/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// Local import — ensure this matches your actual package path


// =============================================================================
// 1. DESIGN TOKENS
// =============================================================================

abstract class _T {
  // Surface
  static const bg        = Color(0xFF080C14);
  static const surface   = Color(0xFF0E1420);
  static const card      = Color(0xFF131B2B);
  static const cardHover = Color(0xFF172035);
  static const border    = Color(0xFF1E2D47);
  static const divider   = Color(0xFF1A2540);

  // Brand
  static const primary    = Color(0xFF6366F1);
  static const primaryLo  = Color(0x1A6366F1);
  static const primaryMid = Color(0x336366F1);
  static const accent     = Color(0xFF38BDF8);

  // Text
  static const textHi  = Color(0xFFF0F4FF);
  static const textMid = Color(0xFF8B9CC8);
  static const textLo  = Color(0xFF3D4F72);

  // Semantic
  static const success  = Color(0xFF22C55E);
  static const warning  = Color(0xFFF59E0B);
  static const error    = Color(0xFFEF4444);
  static const errorLo  = Color(0x1AEF4444);

  // Radius
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static ThemeData get theme => ThemeData(
        useMaterial3:       true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.dark(
          primary:   primary,
          secondary: accent,
          surface:   surface,
          error:     error,
        ),
        textTheme: const TextTheme().apply(
          bodyColor:    textMid,
          displayColor: textHi,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:       true,
          fillColor:    card,
          hintStyle:    const TextStyle(color: textLo, fontSize: 14),
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
              borderRadius: r12,
              borderSide: const BorderSide(color: error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: r12,
              borderSide: const BorderSide(color: error, width: 1.5)),
          errorStyle: const TextStyle(color: error, fontSize: 11),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:         primary,
            foregroundColor:         Colors.white,
            disabledBackgroundColor: card,
            elevation:               0,
            shape: RoundedRectangleBorder(borderRadius: r12),
            minimumSize:             const Size(double.infinity, 48),
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

abstract class AppRoutes {
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const profile        = '/profile';
  static const notifications  = '/notifications';
  static const notifications2  = '/notifications2';
  static const roles          = '/roles';
  static const dashboard      = '/dashboard';
   static const users          = '/users'; // ← NUEVO
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
        style: const TextStyle(color: _T.textHi, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRouteNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuth    = ref.read(authStateProvider).valueOrNull != null;
      final isLoading = ref.read(authStateProvider).isLoading;
      final path      = state.matchedLocation;

      debugPrint("--- RUTA: $path | Autenticado: $isAuth ---");

      if (isLoading) return null;

      // 1. Permitir acceso al visor de playlists sin login
      if (path.startsWith('/view/')) {
        debugPrint("--- Acceso libre a visor ---");
        return null;
      }

      const publicRoutes = [AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword];
      final isPublic = publicRoutes.contains(path);

      if (!isAuth && !isPublic) {
        debugPrint("--- No autenticado, yendo a login ---");
        return AppRoutes.login;
      }
      
      if (isAuth && isPublic) {
        debugPrint("--- Ya autenticado, yendo a dashboard ---");
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // RUTAS FUERA DEL SHELL (Fullscreen)
      GoRoute(
        path: '/view/:id',
        builder: (_, state) => _ViewPlaylistScreen(playlistId: state.pathParameters['id']!),
      ),
      
      // RUTAS DE AUTH
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(path: '/portal', builder: (_, __) => const DevicePortalScreen()),
GoRoute(
  path: '/portal/dashboard',
  builder: (context, state) {
    final device = state.extra as DeviceUser;
    return DeviceDashboardScreen(device: device);
  },
),
      // RUTAS CON SHELL
      ShellRoute(
        builder: (_, __, child) => _DashboardShell(child: child),
        routes: [
        
          GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const _DashboardHome()),
          GoRoute(path: '/devices', builder: (_, __) => const DevicesScreen()),
          GoRoute(path: '/content', builder: (_, __) => const PlaylistsScreen()),
          GoRoute(path: '/playlist2', builder: (_, __) => const PlaylistsListScreen()),
          GoRoute(path: '/schedules', builder: (_, __) => const SchedulesScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/media', builder: (_, __) => const MediaLibraryScreen()),
          GoRoute(path: '/editor', builder: (_, __) => const ScreenEditorScreen()),
          GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersManagementPage()),
          GoRoute(path: AppRoutes.roles, builder: (_, __) => const RolesManagementPage()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfilePage()),
          GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsPage()),
          GoRoute(path: AppRoutes.notifications2, builder: (_, __) => const NotificationsPage22()),
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
    return fallback ??
        _AccessDeniedPage(permission: permission.value);
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
      drawer: isMobile ? _buildDrawer(context, ref, userAsync.valueOrNull) : null,
      body: Row(
        children: [
          if (!isMobile) _Sidebar(user: userAsync.valueOrNull),
          Expanded(
            child: Column(
              children: [
                _TopBar(user: userAsync.valueOrNull, isMobile: isMobile),
                Expanded(child: child),
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
  final userId     = user?.uid ?? '';
  final unreadAsync = userId.isNotEmpty
      ? ref.watch(unreadCountProvider(userId))
      : const AsyncData(0);
  final unread = unreadAsync.valueOrNull ?? 0;

  return Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color:  _T.surface,
      border: Border(bottom: BorderSide(color: _T.divider)),
    ),
    child: Row(
      children: [
        if (isMobile) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: _T.textMid),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _T.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('SignageOS',
            style: TextStyle(
              color: _T.textHi, fontSize: 15,
              fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),

        // ── Notifications icon con badge ──
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: _T.textMid, size: 20),
              tooltip: 'Notificaciones',
              onPressed: () => context.go(AppRoutes.notifications),
            ),
            if (unread > 0)
              Positioned(
                top: 6, right: 6,
                child: IgnorePointer(
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color:  _T.error,
                      shape:  BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 4),

        // ── Avatar → perfil ──
        GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: _Avatar(user: user, size: 34),
        ),
      ],
    ),
  );
}
}

class _Sidebar extends ConsumerWidget {
  final AppUser? user;
  const _Sidebar({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

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
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item == null) {
                  return const Divider(
                      color: _T.divider, height: 24, indent: 4);
                }
                final selected = location == item.route;
                return _NavItem(
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
          // User info + logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Avatar(user: user, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                        style: const TextStyle(
                          color: _T.textHi, fontSize: 12,
                          fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roles.firstOrNull?.displayName ?? '',
                        style: const TextStyle(
                            color: _T.textLo, fontSize: 10),
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
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _T.error.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.error.withOpacity(0.25), width: 1.5),
                  ),
                  child: const Icon(Icons.logout_rounded, color: _T.error, size: 28),
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

List<_NavItemData?> _buildNavItems(AppUser? user) {
  return [
    _NavItemData(
        route: AppRoutes.dashboard,
        icon:  Icons.space_dashboard_outlined,
        label: 'Dashboard'),
    _NavItemData(
        route: '/devices',
        icon:  Icons.tv_outlined,
        label: 'Devices'),
  /*  _NavItemData(
        route: '/content',
        icon:  Icons.perm_media_outlined,
        label: 'Content'),*/
    _NavItemData(
        route: '/playlist2',
        icon:  Icons.queue_music_outlined,
        label: 'Lista de reproducción'),
    _NavItemData(
        route: '/schedules',
        icon:  Icons.calendar_month_outlined,
        label: 'Programación'),
    _NavItemData(
        route: '/analytics',
        icon:  Icons.bar_chart_outlined,
        label: 'Analitica'),
    _NavItemData(
        route: '/media',
        icon:  Icons.photo_library_outlined,
        label: 'Biblioteca de medios'),
    _NavItemData(
        route: '/editor',
        icon:  Icons.edit_outlined,
        label: 'Editor Playlists'),
    null, // divider
   // if (user?.hasPermission(AppPermission.usersView) == true)
      _NavItemData(
          route: AppRoutes.users,
          icon:  Icons.people_rounded,
          label: 'Usuarios'),
  //  if (user?.hasPermission(AppPermission.rolesView) == true)
      _NavItemData(
          route: AppRoutes.roles,
          icon:  Icons.shield_rounded,
          label: 'Roles'),
    null, // divider
    _NavItemData(
        route: AppRoutes.notifications2,
        icon:  Icons.notifications_outlined,
        label: 'Notificaciones'),
    _NavItemData(
        route: AppRoutes.profile,
        icon:  Icons.person_outline_rounded,
        label: 'Mi Perfil'),
  ];
}
}

class _NavItemData {
  final String route;
  final IconData icon;
  final String label;
  const _NavItemData(
      {required this.route, required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? _T.primaryLo : Colors.transparent,
        borderRadius: _T.r8,
        child: InkWell(
          borderRadius: _T.r8,
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(item.icon,
                  size: 16,
                  color: selected ? _T.primary : _T.textMid),
                const SizedBox(width: 10),
                Text(item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? _T.primary : _T.textMid,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 6. AUTH PAGES
// =============================================================================

// ── LOGIN PAGE ──────────────────────────────────────────────────────────────

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  bool _remember   = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await ref.read(firebaseServiceProvider).signIn(
      email:    _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        context.go(AppRoutes.dashboard);
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthHeader(
              title:    'Bienvenido de vuelta',
              subtitle: 'Accede a tu panel de administración',
            ),
            const SizedBox(height: 32),
            if (_error != null) _ErrorBanner(message: _error!),

            _FieldLabel('Email'),
            TextFormField(
              controller:   _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style:        _inputStyle,
              decoration:   _inputDeco(
                hint: 'admin@empresa.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu email';
                if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$').hasMatch(v))
                  return 'Email no válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _FieldLabel('Contraseña'),
            TextFormField(
              controller:  _passCtrl,
              obscureText: !_showPass,
              style:       _inputStyle,
              decoration:  _inputDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffix: _togglePassButton(
                  show: _showPass,
                  onTap: () => setState(() => _showPass = !_showPass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: Checkbox(
                        value:        _remember,
                        onChanged:    (v) => setState(() => _remember = v ?? true),
                        activeColor:  _T.primary,
                        side:         const BorderSide(color: _T.textLo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Recordarme',
                      style: TextStyle(color: _T.textMid, fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: _T.primary, fontSize: 12,
                      fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SubmitButton(
              label:   'Iniciar sesión',
              loading: _loading,
              onTap:   _submit,
            ),
            const SizedBox(height: 20),

            _ToggleLink(
              prompt: '¿No tienes cuenta?',
              action: 'Crear cuenta',
              onTap:  () => context.go(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}

// ── REGISTER PAGE ───────────────────────────────────────────────────────────

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form        = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  AppRole _role      = AppRole.user;
  bool _loading      = false;
  bool _showPass     = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await ref.read(firebaseServiceProvider).register(
      name:     _nameCtrl.text,
      email:    _emailCtrl.text,
      password: _passCtrl.text,
      role:     _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        context.go(AppRoutes.dashboard);
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthHeader(
              title:    'Crear cuenta',
              subtitle: 'Configura tu acceso al sistema',
            ),
            const SizedBox(height: 28),
            if (_error != null) _ErrorBanner(message: _error!),

            _FieldLabel('Nombre completo'),
            TextFormField(
              controller: _nameCtrl,
              style:      _inputStyle,
              decoration: _inputDeco(
                hint: 'Juan García',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 14),

            _FieldLabel('Email'),
            TextFormField(
              controller:   _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style:        _inputStyle,
              decoration:   _inputDeco(
                hint: 'usuario@empresa.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu email';
                if (!v.contains('@')) return 'Email no válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _FieldLabel('Contraseña'),
            TextFormField(
              controller:  _passCtrl,
              obscureText: !_showPass,
              style:       _inputStyle,
              decoration:  _inputDeco(
                hint:   '••••••••',
                icon:   Icons.lock_outline_rounded,
                suffix: _togglePassButton(
                  show:  _showPass,
                  onTap: () => setState(() => _showPass = !_showPass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _FieldLabel('Confirmar contraseña'),
            TextFormField(
              controller:  _confirmCtrl,
              obscureText: !_showPass,
              style:       _inputStyle,
              decoration:  _inputDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
              ),
              validator: (v) =>
                  v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 20),

            _FieldLabel('Rol del usuario'),
            const SizedBox(height: 8),
            _RoleSelector(
              selected:  _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 24),

            _SubmitButton(
              label:   'Crear cuenta',
              loading: _loading,
              onTap:   _submit,
            ),
            const SizedBox(height: 20),

            _ToggleLink(
              prompt: '¿Ya tienes cuenta?',
              action: 'Iniciar sesión',
              onTap:  () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FORGOT PASSWORD PAGE ─────────────────────────────────────────────────────

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading    = false;
  bool _sent       = false;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await ref
        .read(firebaseServiceProvider)
        .sendPasswordReset(_emailCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        setState(() => _sent = true);
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: _sent ? _SuccessView() : _FormView(),
    );
  }

  Widget _SuccessView() => Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _T.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: _T.success, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Email enviado',
            style: TextStyle(
              color: _T.textHi, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Hemos enviado instrucciones de recuperación a\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _T.textMid, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Volver al login'),
            ),
          ),
        ],
      );

  Widget _FormView() => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthHeader(
              title:    'Recuperar contraseña',
              subtitle: 'Te enviaremos un link para resetear tu contraseña',
            ),
            const SizedBox(height: 32),
            if (_error != null) _ErrorBanner(message: _error!),
            _FieldLabel('Email'),
            TextFormField(
              controller:   _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style:        _inputStyle,
              decoration:   _inputDeco(
                hint: 'tu@email.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu email';
                if (!v.contains('@')) return 'Email no válido';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            _SubmitButton(
              label:   'Enviar instrucciones',
              loading: _loading,
              onTap:   _submit,
            ),
            const SizedBox(height: 20),
            _ToggleLink(
              prompt: '¿Recuerdas tu contraseña?',
              action: 'Iniciar sesión',
              onTap:  () => context.go(AppRoutes.login),
            ),
          ],
        ),
      );
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
  final _form       = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _addressCtrl= TextEditingController();
  bool _editing     = false;
  bool _saving      = false;
  bool _uploadingPhoto = false;
  String? _successMsg;
  String? _errorMsg;

  // Change password
  final _passForm    = GlobalKey<FormState>();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _changingPass  = false;
  bool _showPassFields= false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _nameCtrl.text    = user.name;
    _emailCtrl.text   = user.email;
    _phoneCtrl.text   = user.phone;
    _addressCtrl.text = user.address;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _addressCtrl.dispose();
    _currPassCtrl.dispose(); _newPassCtrl.dispose(); _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; });

    final user = ref.read(currentUserProvider).valueOrNull!;
    final result = await ref.read(firebaseServiceProvider).updateProfile(
      uid:     user.uid,
      name:    _nameCtrl.text,
      phone:   _phoneCtrl.text,
      address: _addressCtrl.text,
    );

    if (!mounted) return;
    setState(() { _saving = false; });

    switch (result) {
      case Success():
        setState(() {
          _editing    = false;
          _successMsg = 'Perfil actualizado correctamente.';
        });
        Future.delayed(const Duration(seconds: 3),
            () { if (mounted) setState(() => _successMsg = null); });
      case Failure(:final message):
        setState(() => _errorMsg = message);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    final bytes    = await file.readAsBytes();
    final svc      = ref.read(firebaseServiceProvider);
    final user     = ref.read(currentUserProvider).valueOrNull!;

    final uploadResult = await svc.uploadProfilePhoto(
      uid:      user.uid,
      bytes:    bytes,
      filename: file.name,
    );

    if (!mounted) return;

    switch (uploadResult) {
      case Success(:final value):
        final updateResult = await svc.updateProfile(
          uid:      user.uid,
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
      email:    user.email,
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
      loading: () => const Center(
          child: CircularProgressIndicator(color: _T.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _T.error))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _buildProfile(user);
      },
    );
  }

Widget _buildProfile(AppUser user) {
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
            const SizedBox(height: 24),

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
                        // Left column: avatar card
                        SizedBox(
                          width: 260,
                          child: _AvatarCard(
                            user: user,
                            uploadingPhoto: _uploadingPhoto,
                            onPickPhoto: _pickAndUploadPhoto,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right column
                        Expanded(
                          child: Column(
                            children: [
                              _InfoCard(
                                user: user,
                                editing: _editing,
                                saving: _saving,
                                formKey: _form,
                                nameCtrl: _nameCtrl,
                                emailCtrl: _emailCtrl,
                                phoneCtrl: _phoneCtrl,
                                addressCtrl: _addressCtrl,
                                onEdit: () => setState(() => _editing = true),
                                onCancel: () =>
                                    setState(() {
                                      _editing = false;
                                      _loadUser();
                                    }),
                                onSave: _save,
                              ),
                              const SizedBox(height: 16),
                              _SecurityCard(
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
                        _InfoCard(
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
                        _SecurityCard(
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
            _CardContainer(
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
                          user.roles.map((r) => _RoleChip(role: r)).toList(),
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
                          .map((p) => _PermBadge(permission: p))
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
           
        GestureDetector(onTap: (){


  Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => const NotificationsPage(),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  ),
);
        },child:  Text('Notificaciones1',
                style: TextStyle(
                  color: _T.textHi, fontSize: 22,
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
                  itemBuilder: (_, i) =>
                      _NotifTile(notif: notifs[i], svc: svc),
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
        NotificationType.error   => _T.error,
        NotificationType.system  => _T.primary,
        NotificationType.info    => _T.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.read ? Colors.transparent : _T.primaryLo,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:  _typeColor.withOpacity(0.12),
            shape:  BoxShape.circle,
          ),
          child: Icon(Icons.notifications_rounded,
              color: _typeColor, size: 18),
        ),
        title: Text(notif.title,
          style: TextStyle(
            color:      _T.textHi,
            fontSize:   13,
            fontWeight: notif.read
                ? FontWeight.w400 : FontWeight.w600,
          )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notif.body,
              style: const TextStyle(color: _T.textMid, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_formatDate(notif.createdAt),
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

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Roles y permisos',
              style: TextStyle(
                color: _T.textHi, fontSize: 22,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const TabBar(
              isScrollable: true,
              labelColor:     _T.primary,
              unselectedLabelColor: _T.textMid,
              indicatorColor: _T.primary,
              tabs: [
                Tab(text: 'Definición de roles'),
                Tab(text: 'Usuarios y roles'),
              ],
            ),
            const Divider(color: _T.divider, height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Roles list
                  rolesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: _T.primary)),
                    error: (e, _) => Text('Error: $e'),
                    data: (roles) => _RolesTab(roles: roles, svc: svc),
                  ),
                  // Users with roles
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
              return _CardContainer(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _roleColor(appRole).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield_rounded, color: _roleColor(appRole), size: 18),
                  ),
                  title: Text(role.displayName,
                    style: const TextStyle(color: _T.textHi, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: role.permissions.map((p) => _PermBadge(permission: p)).toList(),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: _T.textMid),
                        onPressed: () => _showEditRoleDialog(context, role),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: _T.error),
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
        content: Text('¿Eliminar "${role.displayName}"? Esta acción no se puede deshacer.',
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
            style: ElevatedButton.styleFrom(backgroundColor: _T.error, minimumSize: const Size(80, 36)),
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
          title: const Text('Crear nuevo rol', style: TextStyle(color: _T.textHi)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre interno (sin espacios)', style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: _T.textHi, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ej: content_manager',
                        hintStyle: const TextStyle(color: _T.textLo, fontSize: 13),
                        filled: true, fillColor: _T.surface,
                        border: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.primary, width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Nombre visible', style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: displayCtrl,
                      style: const TextStyle(color: _T.textHi, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ej: Content Manager',
                        hintStyle: const TextStyle(color: _T.textLo, fontSize: 13),
                        filled: true, fillColor: _T.surface,
                        border: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.primary, width: 1.5)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Permisos', style: TextStyle(color: _T.textMid, fontSize: 12)),
                    const SizedBox(height: 6),
                    ...AppPermission.values.map((perm) => CheckboxListTile(
                      dense: true,
                      value: selected.contains(perm),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) selected.add(perm);
                          else selected.remove(perm);
                        });
                      },
                      title: Text(perm.value, style: const TextStyle(color: _T.textMid, fontSize: 13)),
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
              child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
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
          title: Text('Editar: ${role.displayName}', style: const TextStyle(color: _T.textHi)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre visible', style: TextStyle(color: _T.textMid, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: displayCtrl,
                    style: const TextStyle(color: _T.textHi, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: _T.surface,
                      border: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: _T.r8, borderSide: const BorderSide(color: _T.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Permisos', style: TextStyle(color: _T.textMid, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...AppPermission.values.map((perm) => CheckboxListTile(
                    dense: true,
                    value: selected.contains(perm),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) selected.add(perm);
                        else selected.remove(perm);
                      });
                    },
                    title: Text(perm.value, style: const TextStyle(color: _T.textMid, fontSize: 13)),
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
              child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
            ),
            ElevatedButton(
              onPressed: () async {
                await svc.updateRole(RoleDefinition(
                  id: role.id,
                  name: role.name,
                  displayName: displayCtrl.text.trim().isEmpty ? role.displayName : displayCtrl.text.trim(),
                  description: role.description,
                  permissions: selected.toList(),
                  createdAt: role.createdAt,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(AppRole role) => switch (role) {
    AppRole.superAdmin => const Color(0xFFEF4444),
    AppRole.admin      => const Color(0xFF6366F1),
    AppRole.manager    => const Color(0xFF38BDF8),
    AppRole.editor     => const Color(0xFF22C55E),
    AppRole.user       => const Color(0xFFF59E0B),
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
        return _CardContainer(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            leading: _Avatar(user: user, size: 40),
            title: Text(user.name,
              style: const TextStyle(
                  color: _T.textHi, fontSize: 14,
                  fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4, runSpacing: 4,
                children: user.roles
                    .map((r) => _RoleChip(role: r))
                    .toList(),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.manage_accounts_rounded,
                  size: 18, color: _T.textMid),
              onPressed: () =>
                  _showAssignRoleDialog(context, user),
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
        title: Text('Roles de ${user.name}', style: const TextStyle(color: _T.textHi)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppRole.values.map((role) {
            return CheckboxListTile(
              dense: true,
              value: selected.contains(role),
              onChanged: (v) {
                setState(() {
                  if (v == true) selected.add(role);
                  else selected.remove(role);
                });
              },
              title: Text(role.displayName, style: const TextStyle(color: _T.textMid, fontSize: 13)),
              activeColor: _T.primary,
              checkColor: Colors.white,
              side: const BorderSide(color: _T.textLo),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selected.isEmpty) return;
              await svc.updateUserRoles(uid: user.uid, roles: selected.toList());
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, ${user?.name ?? '—'} 👋',
            style: const TextStyle(
              color: _T.textHi, fontSize: 22,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Bienvenido al panel de administración · '
            '${user?.roles.map((r) => r.displayName).join(', ')}',
            style: const TextStyle(color: _T.textMid, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              _StatCard(
                label: 'Dispositivos', value: '0',
                icon: Icons.tv_rounded, color: _T.primary),
              _StatCard(
                label: 'Usuarios',     value: '—',
                icon: Icons.people_rounded, color: _T.accent),
              _StatCard(
                label: 'Uptime',       value: '99.9%',
                icon: Icons.bolt_rounded, color: _T.success),
              _StatCard(
                label: 'Latencia',     value: '<50ms',
                icon: Icons.speed_rounded, color: _T.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        _T.card,
        borderRadius: _T.r16,
        border:       const Border.fromBorderSide(BorderSide(color: _T.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: _T.r8,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value,
            style: const TextStyle(
              color: _T.textHi, fontSize: 22,
              fontWeight: FontWeight.w800)),
          Text(label,
            style: const TextStyle(color: _T.textMid, fontSize: 11)),
        ],
      ),
    );
  }
}

// =============================================================================
// 11. ERROR & ACCESS DENIED
// =============================================================================

class _ErrorPage extends StatelessWidget {
  final String error;
  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: _T.error, size: 48),
            const SizedBox(height: 12),
            Text('Error 404 — $error',
              style: const TextStyle(color: _T.textMid)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44)),
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
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _T.error.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outlined,
                  color: _T.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Acceso denegado',
              style: TextStyle(
                color: _T.textHi, fontSize: 20,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Necesitas el permiso: $permission',
              style: const TextStyle(color: _T.textMid, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44)),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 12. SHARED WIDGETS
// =============================================================================

class _AuthScaffold extends StatelessWidget {
  final Widget child;
  const _AuthScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated bg orbs
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _T.primary.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -120, right: -80,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _T.accent.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Grid overlay
          CustomPaint(painter: _GridPainter()),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color:        _T.card,
                      borderRadius: _T.r20,
                      border:       const Border.fromBorderSide(
                          BorderSide(color: _T.border)),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _T.border.withOpacity(0.4)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _AuthHeader extends StatelessWidget {
  final String title, subtitle;
  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _T.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('SignageOS',
            style: TextStyle(
              color: _T.textHi, fontSize: 16,
              fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _T.primaryLo,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: _T.primary.withOpacity(0.3)),
            ),
            child: const Text('ENTERPRISE',
              style: TextStyle(
                color: _T.primary, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ),
        ]),
        const SizedBox(height: 24),
        Text(title,
          style: const TextStyle(
            color: _T.textHi, fontSize: 24,
            fontWeight: FontWeight.w800, letterSpacing: -0.8)),
        const SizedBox(height: 4),
        Text(subtitle,
          style: const TextStyle(color: _T.textMid, fontSize: 13)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
          style: const TextStyle(
            color: _T.textMid, fontSize: 12,
            fontWeight: FontWeight.w500, letterSpacing: 0.3)),
      );
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class _ToggleLink extends StatelessWidget {
  final String prompt, action;
  final VoidCallback onTap;
  const _ToggleLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prompt ',
            style: const TextStyle(color: _T.textMid, fontSize: 13)),
          GestureDetector(
            onTap: onTap,
            child: Text(action,
              style: const TextStyle(
                color: _T.primary, fontSize: 13,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return _Banner(
        message: message, color: _T.error,
        icon: Icons.error_outline_rounded);
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _Banner({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: _T.r12,
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
              style: TextStyle(
                color:      color,
                fontSize:   12,
                fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final AppRole selected;
  final ValueChanged<AppRole> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AppRole.values.map((role) {
        final isSelected = role == selected;
        return GestureDetector(
          onTap: () => onChanged(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? _roleColor(role).withOpacity(0.08)
                  : _T.card,
              borderRadius: _T.r12,
              border: Border.all(
                color: isSelected
                    ? _roleColor(role).withOpacity(0.5)
                    : _T.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _roleColor(role)
                        .withOpacity(isSelected ? 0.15 : 0.07),
                    borderRadius: _T.r8,
                  ),
                  child: Icon(Icons.shield_rounded,
                    size:  15,
                    color: _roleColor(role)
                        .withOpacity(isSelected ? 1 : 0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.displayName,
                        style: TextStyle(
                          color: isSelected ? _T.textHi : _T.textMid,
                          fontSize:   13,
                          fontWeight: isSelected
                              ? FontWeight.w600 : FontWeight.w400)),
                      Text(_roleDesc(role),
                        style: const TextStyle(
                            color: _T.textLo, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                    size: 16, color: _roleColor(role)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _roleColor(AppRole r) => switch (r) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.admin      => const Color(0xFF6366F1),
        AppRole.manager    => const Color(0xFF38BDF8),
        AppRole.editor     => const Color(0xFF22C55E),
        AppRole.user       => const Color(0xFFF59E0B),
      };

  String _roleDesc(AppRole r) => switch (r) {
        AppRole.superAdmin => 'Control total del sistema',
        AppRole.admin      => 'Gestiona usuarios y dispositivos',
        AppRole.manager    => 'Supervisa equipos y contenido',
        AppRole.editor     => 'Crea y edita contenido',
        AppRole.user       => 'Acceso básico al sistema',
      };
}

class _Avatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  const _Avatar({this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name.trim().split(' ').take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color:  _T.primaryMid,
        shape:  BoxShape.circle,
        border: Border.all(color: _T.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(photoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsWidget(
                  initials: initials, size: size))
          : _InitialsWidget(initials: initials, size: size),
    );
  }
}

class _InitialsWidget extends StatelessWidget {
  final String initials;
  final double size;
  const _InitialsWidget({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
          style: TextStyle(
            color:      _T.primary,
            fontSize:   size * 0.32,
            fontWeight: FontWeight.w700)),
      );
}

class _RoleChip extends StatelessWidget {
  final AppRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(role.displayName,
        style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor(AppRole r) => switch (r) {
        AppRole.superAdmin => const Color(0xFFEF4444),
        AppRole.admin      => const Color(0xFF6366F1),
        AppRole.manager    => const Color(0xFF38BDF8),
        AppRole.editor     => const Color(0xFF22C55E),
        AppRole.user       => const Color(0xFFF59E0B),
      };
}

class _PermBadge extends StatelessWidget {
  final AppPermission permission;
  const _PermBadge({required this.permission});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:        _T.primaryLo,
          borderRadius: BorderRadius.circular(4),
          border:       Border.all(color: _T.primary.withOpacity(0.2)),
        ),
        child: Text(permission.value,
          style: const TextStyle(
            color: _T.primary, fontSize: 10,
            fontWeight: FontWeight.w500)),
      );
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        _T.card,
          borderRadius: _T.r16,
          border:       const Border.fromBorderSide(
              BorderSide(color: _T.border)),
        ),
        child: child,
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => _CardContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                    style: const TextStyle(
                      color: _T.textHi, fontSize: 15,
                      fontWeight: FontWeight.w600)),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return Column(
        children: children
            .expand((c) => [c, const SizedBox(height: 14)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }
    return Row(
      children: children
          .expand((c) => [Expanded(child: c), const SizedBox(width: 14)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.enabled,
    this.obscure = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextFormField(
          controller:  controller,
          enabled:     enabled,
          obscureText: obscure,
          style:       _inputStyle,
          decoration:  _inputDeco(hint: label, icon: icon).copyWith(
            fillColor: enabled ? _T.card : _T.surface,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:        _T.surface,
              borderRadius: _T.r12,
              border:       const Border.fromBorderSide(
                  BorderSide(color: _T.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 8),
                Text(value,
                  style: const TextStyle(
                      color: _T.textMid, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
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
    final svc = ref.read(firebaseServiceProvider);
    final canCreate = currentUser?.hasPermission(AppPermission.usersCreate) ?? false;
    final canEdit   = currentUser?.hasPermission(AppPermission.usersEdit)   ?? false;
    final canDelete = currentUser?.hasPermission(AppPermission.usersDelete)  ?? false;

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
                final filtered = users.where((u) {
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
                          width: 64, height: 64,
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
                            style: TextStyle(
                                color: _T.textMid, fontSize: 13)),
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
                      onSuccess: () => Navigator.pop(context),
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
    AppRole.admin      => const Color(0xFF6366F1),
    AppRole.manager    => const Color(0xFF38BDF8),
    AppRole.editor     => const Color(0xFF22C55E),
    AppRole.user       => const Color(0xFFF59E0B),
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
    return _CardContainer(
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
            child: _Avatar(user: user, size: 36),
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
              children:
                  user.roles.map((r) => _RoleChip(role: r)).toList(),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _StatusBadge(status: user.status),
          ),
          // Last login
          Expanded(
            flex: 2,
            child: Text(
              user.lastLogin != null
                  ? _formatDate(user.lastLogin!)
                  : 'Sin acceso',
              style: const TextStyle(color: _T.textLo, fontSize: 11),
            ),
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
                if (canEdit && !isSelf)
                  _ActionBtn(
                    icon: isBlocked
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    color: isBlocked ? _T.success : _T.warning,
                    tooltip: isBlocked ? 'Desbloquear' : 'Bloquear',
                    onTap: () => _toggleBlock(context, user, svc),
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
    final newStatus =
        user.status == 'suspended' ? 'active' : 'suspended';
    await svc.updateUserStatus(uid: user.uid, status: newStatus);
  }

  void _confirmDelete(
      BuildContext context, AppUser user, FirebaseService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _T.border),
        ),
        title: const Text('Eliminar usuario',
            style: TextStyle(color: _T.textHi)),
        content: Text(
            '¿Eliminar la cuenta de "${user.name}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Soft delete: marca como inactivo
              await svc.updateUserStatus(
                  uid: user.uid, status: 'inactive');
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.error,
                minimumSize: const Size(80, 36)),
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

        return _CardContainer(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(user: user, size: 42),
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
                    _StatusBadge(status: user.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: user.roles
                      .map((r) => _RoleChip(role: r))
                      .toList(),
                ),
                if (user.lastLogin != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: _T.textLo),
                      const SizedBox(width: 4),
                      Text(_formatDate(user.lastLogin!),
                          style: const TextStyle(
                              color: _T.textLo, fontSize: 11)),
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

  void _confirmDelete(
      BuildContext context, AppUser user, FirebaseService svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _T.border),
        ),
        title: const Text('Eliminar usuario',
            style: TextStyle(color: _T.textHi)),
        content: Text('¿Eliminar la cuenta de "${user.name}"?',
            style: const TextStyle(color: _T.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            onPressed: () async {
              await svc.updateUserStatus(
                  uid: user.uid, status: 'inactive');
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.error,
                minimumSize: const Size(80, 36)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active'    => (_T.success, 'Activo'),
      'suspended' => (_T.warning, 'Bloqueado'),
      'inactive'  => (_T.error,   'Inactivo'),
      _           => (_T.textMid, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
    _nameCtrl    = TextEditingController(text: widget.user.name);
    _phoneCtrl   = TextEditingController(text: widget.user.phone);
    _addressCtrl = TextEditingController(text: widget.user.address);
    _roles       = Set.from(widget.user.roles);
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
    setState(() { _saving = true; _error = null; });

    final svc = ref.read(firebaseServiceProvider);

    final profileResult = await svc.updateProfile(
      uid:     widget.user.uid,
      name:    _nameCtrl.text.trim(),
      phone:   _phoneCtrl.text.trim(),
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
      uid:   widget.user.uid,
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
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    _Avatar(user: widget.user, size: 36),
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
                      if (_error != null) _ErrorBanner(message: _error!),

                      _ProfileField(
                        label: 'Nombre',
                        controller: _nameCtrl,
                        icon: Icons.badge_outlined,
                        enabled: true,
                        validator: (v) =>
                            v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: 'Teléfono',
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        enabled: true,
                        validator: null,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
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
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
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


class _InlineRegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _InlineRegisterForm({required this.onSuccess});

  @override
  ConsumerState<_InlineRegisterForm> createState() =>
      _InlineRegisterFormState();
}

class _InlineRegisterFormState extends ConsumerState<_InlineRegisterForm>
    with SingleTickerProviderStateMixin {
  final _form        = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  AppRole _role      = AppRole.user;
  bool _loading      = false;
  bool _showPass     = false;
  bool _done         = false;
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
    _successScale = CurvedAnimation(
        parent: _successCtrl, curve: Curves.elasticOut);
    _successFade  = CurvedAnimation(
        parent: _successCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // ← Usa createUserAsAdmin para NO cambiar la sesión actual
    final result = await ref.read(firebaseServiceProvider).createUserAsAdmin(
      name:     _nameCtrl.text,
      email:    _emailCtrl.text,
      password: _passCtrl.text,
      role:     _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success(:final value):
        setState(() {
          _done        = true;
          _createdName = value.name;
        });
        _successCtrl.forward();
        // Cierra el dialog automáticamente después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onSuccess();
        });
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
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color:  _T.success.withOpacity(0.12),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: _T.success.withOpacity(0.3), width: 2),
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
            // Progress bar que indica el cierre automático
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(seconds: 2),
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: _T.success.withOpacity(0.10),
                  valueColor:
                      const AlwaysStoppedAnimation(_T.success),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),

          _ProfileField(
            label: 'Nombre completo',
            controller: _nameCtrl,
            icon: Icons.person_outline_rounded,
            enabled: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          _ProfileField(
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
              const _FieldLabel('Contraseña'),
              TextFormField(
                controller:  _passCtrl,
                obscureText: !_showPass,
                style:       _inputStyle,
                decoration:  _inputDeco(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  suffix: _togglePassButton(
                    show:  _showPass,
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
          _ProfileField(
            label: 'Confirmar contraseña',
            controller: _confirmCtrl,
            icon: Icons.lock_rounded,
            enabled: true,
            obscure: true,
            validator: (v) =>
                v != _passCtrl.text ? 'No coinciden' : null,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Rol del usuario'),
          const SizedBox(height: 8),
          _RoleSelector(
            selected:  _role,
            onChanged: (r) => setState(() => _role = r),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
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

// =============================================================================
// 13. HELPERS
// =============================================================================

const TextStyle _inputStyle = TextStyle(color: _T.textHi, fontSize: 14);

InputDecoration _inputDeco({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText:    hint,
      prefixIcon:  Icon(icon, size: 18, color: _T.textMid),
      suffixIcon:  suffix,
    );

Widget _togglePassButton({
  required bool show,
  required VoidCallback onTap,
}) =>
    IconButton(
      icon: Icon(
        show
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        size: 18, color: _T.textMid,
      ),
      onPressed: onTap,
    );

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Ahora mismo';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
  if (diff.inHours < 24)   return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7)     return 'Hace ${diff.inDays}d';

  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// =============================================================================
// 14. MAIN APP ENTRY POINT
// =============================================================================

/// Wrap your MaterialApp with this.
/// Usage in main.dart:
///
///   void main() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     await Firebase.initializeApp(
///         options: DefaultFirebaseOptions.currentPlatform);
///     runApp(const ProviderScope(child: SignageApp()));
///   }
///
class SignageApp extends ConsumerWidget {
  const SignageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider); // ← este ahora es el de app_router.dart

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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
      child: _CardContainer(
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
                  _Avatar(user: widget.user, size: 84),
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
                children: widget.user.roles
                    .map((r) => _RoleChip(role: r))
                    .toList(),
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
                    ? _formatDate(widget.user.lastLogin!)
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
            style:
                const TextStyle(color: _T.textLo, fontSize: 11)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: _T.textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AppUser user;
  final bool editing, saving;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl, addressCtrl;
  final VoidCallback onEdit, onCancel, onSave;

  const _InfoCard({
    required this.user,
    required this.editing,
    required this.saving,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _T.primaryLo, borderRadius: _T.r8),
                        child: const Icon(Icons.person_outline_rounded,
                            color: _T.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Información personal',
                          style: TextStyle(
                              color: _T.textHi,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: editing
                        ? Row(
                            key: const ValueKey('editing'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: onCancel,
                                child: const Text('Cancelar',
                                    style: TextStyle(color: _T.textMid)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: saving ? null : onSave,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Guardar'),
                              ),
                            ],
                          )
                        : IconButton(
                            key: const ValueKey('view'),
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: _T.textMid),
                            tooltip: 'Editar perfil',
                            onPressed: onEdit,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Fields
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    _FormRow(
                      children: [
                        _ProfileField(
                          label: 'Nombre completo',
                          controller: nameCtrl,
                          icon: Icons.badge_outlined,
                          enabled: editing,
                          validator: (v) =>
                              v!.isEmpty ? 'Requerido' : null,
                        ),
                        _ProfileField(
                          label: 'Email',
                          controller: emailCtrl,
                          icon: Icons.mail_outline_rounded,
                          enabled: false,
                          validator: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormRow(
                      children: [
                        _ProfileField(
                          label: 'Teléfono',
                          controller: phoneCtrl,
                          icon: Icons.phone_outlined,
                          enabled: editing,
                          validator: null,
                        ),
                        _ProfileField(
                          label: 'Dirección',
                          controller: addressCtrl,
                          icon: Icons.location_on_outlined,
                          enabled: editing,
                          validator: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Security Card ─────────────────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  final GlobalKey<FormState> passForm;
  final TextEditingController currPassCtrl, newPassCtrl, confPassCtrl;
  final bool showPassFields, changingPass;
  final VoidCallback onToggle, onChangePassword;

  const _SecurityCard({
    required this.passForm,
    required this.currPassCtrl,
    required this.newPassCtrl,
    required this.confPassCtrl,
    required this.showPassFields,
    required this.changingPass,
    required this.onToggle,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _T.warning.withOpacity(0.10),
                        borderRadius: _T.r8,
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: _T.warning, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text('Seguridad',
                        style: TextStyle(
                            color: _T.textHi,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    showPassFields ? 'Cancelar' : 'Cambiar contraseña',
                    style: const TextStyle(color: _T.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: showPassFields
                  ? Form(
                      key: passForm,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Divider(color: _T.divider),
                          const SizedBox(height: 16),
                          _ProfileField(
                            label: 'Contraseña actual',
                            controller: currPassCtrl,
                            icon: Icons.lock_outline_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) =>
                                v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          _ProfileField(
                            label: 'Nueva contraseña',
                            controller: newPassCtrl,
                            icon: Icons.lock_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Requerido';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _ProfileField(
                            label: 'Confirmar nueva contraseña',
                            controller: confPassCtrl,
                            icon: Icons.lock_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) => v != newPassCtrl.text
                                ? 'No coinciden'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  changingPass ? null : onChangePassword,
                              child: changingPass
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Actualizar contraseña'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}