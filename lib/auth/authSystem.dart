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

import 'package:digitaltv/auth/auth.dart';
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
  static const roles          = '/roles';
  static const dashboard      = '/dashboard';
}

// =============================================================================
// 3. ROUTER
// =============================================================================

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRouteNotifier(ref);

  return GoRouter(
    initialLocation:  AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuth   = ref.read(authStateProvider).valueOrNull != null;
      final isLoading = ref.read(authStateProvider).isLoading;

      if (isLoading) return null;

      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];
      final isPublic = publicRoutes.contains(state.matchedLocation);

      if (!isAuth && !isPublic) return AppRoutes.login;
      if (isAuth  &&  isPublic) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path:    AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path:    AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path:    AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path:    AppRoutes.dashboard,
        builder: (_, __) => const _DashboardShell(child: _DashboardHome()),
      ),
      GoRoute(
        path:    AppRoutes.profile,
        builder: (_, __) => const _DashboardShell(child: ProfilePage()),
      ),
      GoRoute(
        path:    AppRoutes.notifications,
        builder: (_, __) => const _DashboardShell(child: NotificationsPage()),
      ),
      GoRoute(
        path:    AppRoutes.roles,
        builder: (_, __) => PermissionGuard(
          permission: AppPermission.rolesView,
          child: const _DashboardShell(child: RolesManagementPage()),
        ),
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
    final userId = user?.uid ?? '';
    final unreadAsync = userId.isNotEmpty
        ? ref.watch(unreadCountProvider(userId))
        : const AsyncData(0);
    final unread = unreadAsync.valueOrNull ?? 0;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _T.surface,
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
                color: _T.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.grid_view_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('SignageOS',
              style: TextStyle(
                color: _T.textHi, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          // Notifications icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: _T.textMid, size: 20),
                onPressed: () => context.go(AppRoutes.notifications),
              ),
              if (unread > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color: _T.error, shape: BoxShape.circle),
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
            ],
          ),
          const SizedBox(width: 4),
          // Avatar
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
                  onPressed: () async {
                    await ref.read(firebaseServiceProvider).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_NavItemData?> _buildNavItems(AppUser? user) {
    return [
      _NavItemData(
          route: AppRoutes.dashboard,
          icon: Icons.dashboard_rounded,
          label: 'Dashboard'),
      _NavItemData(
          route: AppRoutes.notifications,
          icon: Icons.notifications_outlined,
          label: 'Notificaciones'),
      null, // divider
      if (user?.hasPermission(AppPermission.rolesView) == true)
        _NavItemData(
            route: AppRoutes.roles,
            icon: Icons.shield_rounded,
            label: 'Roles'),
      null,
      _NavItemData(
          route: AppRoutes.profile,
          icon: Icons.person_outline_rounded,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mi Perfil',
            style: TextStyle(
              color: _T.textHi, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Administra tu información personal y seguridad',
            style: TextStyle(color: _T.textMid, fontSize: 13)),
          const SizedBox(height: 24),

          // Messages
          if (_successMsg != null)
            _Banner(
              message: _successMsg!,
              color: _T.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          if (_errorMsg != null) _ErrorBanner(message: _errorMsg!),

          // Profile card
          _SectionCard(
            title: 'Información personal',
            trailing: _editing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() { _editing = false; _loadUser(); }),
                        child: const Text('Cancelar',
                            style: TextStyle(color: _T.textMid)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Guardar'),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: _T.textMid),
                    onPressed: () => setState(() => _editing = true),
                  ),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        _Avatar(user: user, size: 80),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color:  _T.primary,
                                shape:  BoxShape.circle,
                                border: Border.all(
                                    color: _T.surface, width: 2),
                              ),
                              child: _uploadingPhoto
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.white))
                                  : const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(user.name,
                      style: const TextStyle(
                          color: _T.textHi,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  ),
                  Center(
                    child: Text(user.roles.map((r) => r.displayName).join(', '),
                      style: const TextStyle(
                          color: _T.textMid, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),

                  _FormRow(
                    children: [
                      _ProfileField(
                        label:      'Nombre',
                        controller: _nameCtrl,
                        icon:       Icons.person_outline_rounded,
                        enabled:    _editing,
                        validator:  (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      _ProfileField(
                        label:      'Email',
                        controller: _emailCtrl,
                        icon:       Icons.mail_outline_rounded,
                        enabled:    false, // Email change via Firebase
                        validator:  null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormRow(
                    children: [
                      _ProfileField(
                        label:      'Teléfono',
                        controller: _phoneCtrl,
                        icon:       Icons.phone_outlined,
                        enabled:    _editing,
                        validator:  null,
                      ),
                      _ProfileField(
                        label:      'Dirección',
                        controller: _addressCtrl,
                        icon:       Icons.location_on_outlined,
                        enabled:    _editing,
                        validator:  null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Read-only info
                  _FormRow(
                    children: [
                      _InfoTile(
                          label: 'Estado',
                          value: user.status,
                          icon:  Icons.circle,
                          iconColor: user.isActive ? _T.success : _T.error),
                      _InfoTile(
                          label: 'Último acceso',
                          value: user.lastLogin != null
                              ? _formatDate(user.lastLogin!)
                              : 'Primera sesión',
                          icon:  Icons.access_time_rounded,
                          iconColor: _T.textMid),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Change password section
          _SectionCard(
            title: 'Seguridad',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Contraseña',
                      style: TextStyle(
                          color: _T.textHi, fontSize: 14,
                          fontWeight: FontWeight.w500)),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showPassFields = !_showPassFields),
                      child: Text(
                        _showPassFields ? 'Cancelar' : 'Cambiar contraseña',
                        style: const TextStyle(
                            color: _T.primary, fontSize: 13)),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _showPassFields
                      ? Form(
                          key: _passForm,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              _ProfileField(
                                label:      'Contraseña actual',
                                controller: _currPassCtrl,
                                icon:       Icons.lock_outline_rounded,
                                enabled:    true,
                                obscure:    true,
                                validator:  (v) =>
                                    v!.isEmpty ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 12),
                              _ProfileField(
                                label:      'Nueva contraseña',
                                controller: _newPassCtrl,
                                icon:       Icons.lock_rounded,
                                enabled:    true,
                                obscure:    true,
                                validator:  (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Requerido';
                                  if (v.length < 6)
                                    return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _ProfileField(
                                label:      'Confirmar nueva contraseña',
                                controller: _confPassCtrl,
                                icon:       Icons.lock_rounded,
                                enabled:    true,
                                obscure:    true,
                                validator:  (v) =>
                                    v != _newPassCtrl.text
                                        ? 'No coinciden'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _changingPass ? null : _changePassword,
                                  child: _changingPass
                                      ? const SizedBox(
                                          width: 16, height: 16,
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

          const SizedBox(height: 16),

          // Roles & permissions (read-only)
          _SectionCard(
            title: 'Roles y permisos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: user.roles.map((r) => _RoleChip(role: r)).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(color: _T.divider),
                const SizedBox(height: 8),
                const Text('Permisos activos',
                  style: TextStyle(
                      color: _T.textMid, fontSize: 11,
                      fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: user.permissions
                      .map((p) => _PermBadge(permission: p))
                      .toList(),
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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title:           'SignageOS Enterprise',
      debugShowCheckedModeBanner: false,
      theme:           _T.theme,
      routerConfig:    router,
    );
  }
}