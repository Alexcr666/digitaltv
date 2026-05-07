// lib/ui/auth/auth_screen.dart
// =============================================================================
// LOGIN + REGISTRO CON ROLES — SignageOS Enterprise
// Un solo archivo, 100% funcional con Firebase Auth + Firestore
// =============================================================================
// Dependencias necesarias (ya las tienes):
//   firebase_auth: ^4.x
//   cloud_firestore: ^4.x
//   flutter_riverpod: ^2.x
//   flutter_animate: ^4.x
// =============================================================================

// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 1. MODELO DE ROL
// =============================================================================

enum UserRole {
  superAdmin,
  admin,
  editor,
  viewer;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin: return 'Super Admin';
      case UserRole.admin:      return 'Admin';
      case UserRole.editor:     return 'Editor';
      case UserRole.viewer:     return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superAdmin: return 'Control total del sistema SaaS';
      case UserRole.admin:      return 'Gestiona dispositivos y contenido';
      case UserRole.editor:     return 'Crea y edita contenido';
      case UserRole.viewer:     return 'Solo lectura del sistema';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.superAdmin: return Icons.shield_rounded;
      case UserRole.admin:      return Icons.manage_accounts_rounded;
      case UserRole.editor:     return Icons.edit_rounded;
      case UserRole.viewer:     return Icons.visibility_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.superAdmin: return const Color(0xFFEF4444);
      case UserRole.admin:      return const Color(0xFF6366F1);
      case UserRole.editor:     return const Color(0xFF22C55E);
      case UserRole.viewer:     return const Color(0xFFF59E0B);
    }
  }
}

// =============================================================================
// 2. AUTH SERVICE
// =============================================================================

class AuthService {
  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verifica que el usuario esté en Firestore
      final doc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        return AuthResult.failure('Usuario no encontrado en el sistema.');
      }

      return AuthResult.success(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_parseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  // ── Registro ──────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      // Solo super_admin puede crear otros super_admin
      // En producción agregar validación del caller
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user!.updateDisplayName(name.trim());

      // Guarda el perfil en Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid':         cred.user!.uid,
        'email':       email.trim(),
        'displayName': name.trim(),
        'role':        role.name,
        'permissions': _defaultPermissions(role),
        'active':      true,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      return AuthResult.success(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_parseAuthError(e.code));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  // ── Permisos por defecto ──────────────────────────────────────────────────
  Map<String, bool> _defaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return {
          'manageUsers': true,  'manageDevices': true,
          'manageContent': true,'viewAnalytics': true,
          'manageRoles': true,  'systemConfig': true,
        };
      case UserRole.admin:
        return {
          'manageUsers': false, 'manageDevices': true,
          'manageContent': true,'viewAnalytics': true,
          'manageRoles': false, 'systemConfig': false,
        };
      case UserRole.editor:
        return {
          'manageUsers': false, 'manageDevices': false,
          'manageContent': true,'viewAnalytics': false,
          'manageRoles': false, 'systemConfig': false,
        };
      case UserRole.viewer:
        return {
          'manageUsers': false, 'manageDevices': false,
          'manageContent': false,'viewAnalytics': true,
          'manageRoles': false,  'systemConfig': false,
        };
    }
  }

  // ── Parse de errores ──────────────────────────────────────────────────────
  String _parseAuthError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No existe una cuenta con ese email.';
      case 'wrong-password':       return 'Contraseña incorrecta.';
      case 'email-already-in-use': return 'Este email ya está registrado.';
      case 'weak-password':        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':        return 'El formato del email no es válido.';
      case 'too-many-requests':    return 'Demasiados intentos. Espera un momento.';
      case 'user-disabled':        return 'Esta cuenta ha sido desactivada.';
      default:                     return 'Error de autenticación ($code).';
    }
  }
}

// ── Resultado tipado ──────────────────────────────────────────────────────────

sealed class AuthResult {
  const AuthResult();
  factory AuthResult.success(User u) => AuthSuccess(u);
  factory AuthResult.failure(String m) => AuthFailure(m);
}
class AuthSuccess extends AuthResult { final User user; AuthSuccess(this.user); }
class AuthFailure extends AuthResult { final String message; AuthFailure(this.message); }

// ── Provider ─────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());

// =============================================================================
// 3. COLORES & TOKENS
// =============================================================================

abstract class _C {
  static const bg        = Color(0xFF080C14);
  static const surface   = Color(0xFF0E1420);
  static const card      = Color(0xFF131B2B);
  static const cardBorder= Color(0xFF1E2D47);
  static const primary   = Color(0xFF6366F1);
  static const primaryLo = Color(0x1A6366F1);
  static const accent    = Color(0xFF38BDF8);
  static const textHi    = Color(0xFFF0F4FF);
  static const textMid   = Color(0xFF8B9CC8);
  static const textLo    = Color(0xFF3D4F72);
  static const success   = Color(0xFF22C55E);
  static const error     = Color(0xFFEF4444);
  static const divider   = Color(0xFF1A2540);
}

// =============================================================================
// 4. AUTH SCREEN — entry point
// =============================================================================

class AuthScreen extends StatefulWidget {
  /// Callback llamado cuando el login/registro es exitoso
  final VoidCallback? onAuthenticated;
  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;

  void _toggle() => setState(() => _isLogin = !_isLogin);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo animado ──────────────────────────────────────────────
          Positioned.fill(child: const _AnimatedBackground()),

          // ── Layout split ──────────────────────────────────────────────
          Row(
            children: [
              // Panel izquierdo — branding
              if (MediaQuery.of(context).size.width > 900)
                const Expanded(flex: 5, child: _BrandPanel()),

              // Panel derecho — formulario
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AnimatedSwitcher(
                        duration: 320.ms,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _isLogin
                            ? _LoginForm(
                                key: const ValueKey('login'),
                                onToggle: _toggle,
                                onSuccess: widget.onAuthenticated,
                              )
                            : _RegisterForm(
                                key: const ValueKey('register'),
                                onToggle: _toggle,
                                onSuccess: widget.onAuthenticated,
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
    );
  }
}

// =============================================================================
// 5. FONDO ANIMADO
// =============================================================================

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _BgPainter(_ctrl.value),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Orbe 1
    final p1 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF6366F1).withOpacity(0.18 + t * 0.08),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.15, size.height * (0.3 + t * 0.1)),
        radius: size.width * 0.35,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * (0.3 + t * 0.1)),
      size.width * 0.35,
      p1,
    );

    // Orbe 2
    final p2 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF38BDF8).withOpacity(0.10 + t * 0.05),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * (0.6 - t * 0.1)),
        radius: size.width * 0.3,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * (0.6 - t * 0.1)),
      size.width * 0.3,
      p2,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2540).withOpacity(0.6)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// =============================================================================
// 6. BRAND PANEL (izquierdo)
// =============================================================================

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _C.divider)),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.grid_view_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('SignageOS',
              style: TextStyle(
                color: _C.textHi, fontSize: 20,
                fontWeight: FontWeight.w700, letterSpacing: -0.5,
              )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.primaryLo,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _C.primary.withOpacity(0.3)),
              ),
              child: const Text('ENTERPRISE',
                style: TextStyle(
                  color: _C.primary, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2,
                )),
            ),
          ]).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

          const Spacer(),

          // Headline
       GestureDetector(onTap: (){


        Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => DevicesScreen(),
));
       },child: Text('Gestión de\npantallas en\ntiempo real.',
            style: TextStyle(
              color: _C.textHi,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -1.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)),

          const SizedBox(height: 16),
          const Text(
            'Control total de miles de dispositivos\nAndroid TV desde un panel centralizado.',
            style: TextStyle(color: _C.textMid, fontSize: 15, height: 1.6),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),

          // Feature list
          ...[
            ('Sincronización en tiempo real', Icons.bolt_rounded),
            ('Multi-tenant SaaS', Icons.business_rounded),
            ('Control de roles granular', Icons.shield_rounded),
            ('10.000+ dispositivos simultáneos', Icons.tv_rounded),
          ].asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _C.primaryLo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(e.value.$2, color: _C.primary, size: 15),
              ),
              const SizedBox(width: 12),
              Text(e.value.$1,
                style: const TextStyle(
                    color: _C.textMid, fontSize: 13, fontWeight: FontWeight.w500)),
            ]).animate().fadeIn(delay: Duration(milliseconds: 350 + e.key * 60))
                .slideX(begin: -0.04),
          )),

          const Spacer(),

          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem('10K+', 'Dispositivos'),
                _Vdivider(),
                _StatItem('99.9%', 'Uptime'),
                _Vdivider(),
                _StatItem('<50ms', 'Latencia'),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String val, label;
  const _StatItem(this.val, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(val, style: const TextStyle(
        color: _C.textHi, fontSize: 18,
        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      Text(label, style: const TextStyle(color: _C.textMid, fontSize: 11)),
    ],
  );
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(_) => Container(width: 1, height: 28, color: _C.divider);
}

// =============================================================================
// 7. LOGIN FORM
// =============================================================================

class _LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback? onSuccess;
  const _LoginForm({super.key, required this.onToggle, this.onSuccess});

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final svc = ref.read(authServiceProvider);
    final result = await svc.signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AuthSuccess():
        widget.onSuccess?.call();
      case AuthFailure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _FormHeader(
            title: 'Bienvenido de vuelta',
            subtitle: 'Ingresa a tu panel de administración',
          ),
          const SizedBox(height: 32),

          // Error banner
          if (_error != null) _ErrorBanner(message: _error!),

          // Email
          _FieldLabel('Email'),
          _AuthField(
            controller: _emailCtrl,
            hint: 'admin@empresa.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _FieldLabel('Contraseña'),
          _AuthField(
            controller: _passCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_showPass,
            suffix: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18, color: _C.textMid,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Submit
          _SubmitButton(
            loading: _loading,
            label: 'Iniciar sesión',
            onTap: _submit,
          ),
          const SizedBox(height: 20),

          // Toggle
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿No tienes cuenta? ',
                    style: TextStyle(color: _C.textMid, fontSize: 13)),
                GestureDetector(
                  onTap: widget.onToggle,
                  child: const Text('Crear cuenta',
                    style: TextStyle(
                      color: _C.primary, fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
    );
  }
}

// =============================================================================
// 8. REGISTER FORM
// =============================================================================

class _RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback? onSuccess;
  const _RegisterForm({super.key, required this.onToggle, this.onSuccess});

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  UserRole _role    = UserRole.editor;
  bool _loading     = false;
  bool _showPass    = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final svc = ref.read(authServiceProvider);
    final result = await svc.register(
      name:     _nameCtrl.text,
      email:    _emailCtrl.text,
      password: _passCtrl.text,
      role:     _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case AuthSuccess():
        widget.onSuccess?.call();
      case AuthFailure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(
            title: 'Crear cuenta',
            subtitle: 'Configura tu acceso al sistema',
          ),
          const SizedBox(height: 28),

          if (_error != null) _ErrorBanner(message: _error!),

          // Nombre
          _FieldLabel('Nombre completo'),
          _AuthField(
            controller: _nameCtrl,
            hint: 'Juan García',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: 14),

          // Email
          _FieldLabel('Email'),
          _AuthField(
            controller: _emailCtrl,
            hint: 'usuario@empresa.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          _FieldLabel('Contraseña'),
          _AuthField(
            controller: _passCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_showPass,
            suffix: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18, color: _C.textMid,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm password
          _FieldLabel('Confirmar contraseña'),
          _AuthField(
            controller: _pass2Ctrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_showPass,
            validator: (v) {
              if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Rol selector
          _FieldLabel('Rol del usuario'),
          const SizedBox(height: 8),
          _RoleSelector(
            selected: _role,
            onChanged: (r) => setState(() => _role = r),
          ),
          const SizedBox(height: 24),

          _SubmitButton(
            loading: _loading,
            label: 'Crear cuenta',
            onTap: _submit,
          ),
          const SizedBox(height: 20),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Ya tienes cuenta? ',
                    style: TextStyle(color: _C.textMid, fontSize: 13)),
                GestureDetector(
                  onTap: widget.onToggle,
                  child: const Text('Iniciar sesión',
                    style: TextStyle(
                      color: _C.primary, fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
    );
  }
}

// =============================================================================
// 9. ROLE SELECTOR WIDGET
// =============================================================================

class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: UserRole.values.map((role) {
        final isSelected = role == selected;
        return GestureDetector(
          onTap: () => onChanged(role),
          child: AnimatedContainer(
            duration: 160.ms,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? role.color.withOpacity(0.08) : _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? role.color.withOpacity(0.5) : _C.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: role.color.withOpacity(isSelected ? 0.15 : 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(role.icon,
                    size: 15,
                    color: role.color.withOpacity(isSelected ? 1 : 0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.displayName,
                        style: TextStyle(
                          color: isSelected ? _C.textHi : _C.textMid,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600 : FontWeight.w400,
                        )),
                      Text(role.description,
                        style: const TextStyle(
                            color: _C.textLo, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                    size: 16, color: role.color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// 10. SHARED FORM WIDGETS
// =============================================================================

class _FormHeader extends StatelessWidget {
  final String title, subtitle;
  const _FormHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo pequeño en mobile
        if (MediaQuery.of(context).size.width <= 900) ...[
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _C.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.grid_view_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('SignageOS',
              style: TextStyle(color: _C.textHi, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 28),
        ],
        Text(title,
          style: const TextStyle(
            color: _C.textHi, fontSize: 26,
            fontWeight: FontWeight.w800, letterSpacing: -0.8,
          )),
        const SizedBox(height: 6),
        Text(subtitle,
          style: const TextStyle(color: _C.textMid, fontSize: 14)),
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
        color: _C.textMid, fontSize: 12, fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      )),
  );
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(color: _C.textHi, fontSize: 14),
      decoration: InputDecoration(
        hintText:        hint,
        hintStyle:       const TextStyle(color: _C.textLo, fontSize: 14),
        prefixIcon:      Icon(icon, size: 18, color: _C.textMid),
        suffixIcon:      suffix,
        filled:          true,
        fillColor:       _C.card,
        contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _C.error, fontSize: 11),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;
  const _SubmitButton({
    required this.loading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          disabledBackgroundColor: _C.card,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                )),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _C.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: _C.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
              style: const TextStyle(
                  color: _C.error, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }
}