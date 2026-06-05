import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/auth/auth.dart' as current2;
import 'package:digitaltv/auth/firebaseService.dart';
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

// ── Tile de usuario mini ──────────────────────────────────────────────────────
class UserMiniTile extends StatelessWidget {
  final AppUser user;
  const UserMiniTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: T.r12,
        border: const Border.fromBorderSide(BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          Avatar(user: user, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        color: T.textHi,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(user.email,
                    style: const TextStyle(color: T.textMid, fontSize: 11)),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: user.roles.take(2).map((r) => RoleChip(role: r)).toList(),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: user.status),
        ],
      ),
    );
  }
}

// ── LOGIN PAGE ──────────────────────────────────────────────────────────────

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    const superEmail = 'sly@gmail.com';
    const superPass = 'Mercurio123*';

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // ── Acceso hardcoded superAdmin ──
    if (email == superEmail && password == superPass) {
      final svc = ref.read(firebaseServiceProvider);

      // Intenta login normal primero
      var result = await svc.signIn(email: email, password: password);

      // Si falla (no existe), créalo
      if (result is Failure) {
        result = await svc.register(
          name: 'Alex Super',
          email: superEmail,
          password: superPass,
          role: AppRole.superAdmin,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);

      // Forzar campo isSuperAdmin en Firestore por si acaso
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && !user.isSuperAdmin) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isSuperAdmin': true,
          'roles': ['superAdmin']
        });
        await Future.delayed(const Duration(milliseconds: 400));
      }

      if (!mounted) return;
      context.go(AppRoutesAuth.superDashboard);
      return;
    }

    // ── Login normal ──
    final result = await ref.read(firebaseServiceProvider).signIn(
          email: email,
          password: password,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final updatedUser = ref.read(currentUserProvider).valueOrNull;
        if (updatedUser?.isSuperAdmin == true) {
          context.go(AppRoutesAuth.superDashboard);
        } else {
          context.go(AppRoutesAuth.dashboard);
        }
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
                onTap: () {},
                child: AuthHeader(
                  title: 'Bienvenido de vuelta',
                  subtitle: 'Accede a tu panel de administración',
                )),
            const SizedBox(height: 32),
            if (_error != null) ErrorBanner(message: _error!),

            FieldLabel('Email'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: inputStyle,
              decoration: inputDeco(
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

            FieldLabel('Contraseña'),
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
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v ?? true),
                        activeColor: T.primary,
                        side: const BorderSide(color: T.textLo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Recordarme',
                        style: TextStyle(color: T.textMid, fontSize: 12)),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutesAuth.forgotPassword),
                  child: const Text('¿Olvidaste tu contraseña?',
                      style: TextStyle(
                          color: T.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SubmitButton(
              label: 'Iniciar sesión',
              loading: _loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),
// ── BOTÓN PORTAL DISPOSITIVOS ──
            GestureDetector(
              onTap: () => context.go('/portal'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2D47), Color(0xFF172035)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: T.r12,
                  border: Border.all(color: T.primary.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: T.primary.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_rounded, color: T.primary, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Acceder como dispositivo',
                      style: TextStyle(
                        color: T.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: T.primary, size: 11),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            /*ToggleLink(
              prompt: '¿No tienes cuenta?',
              action: 'Crear cuenta',
              onTap:  () { 
                print("objectportal");
             context.go('/portal');
                
                
               // context.go(AppRoutesAuth.register);
                
                },
            ),*/
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
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  AppRole _role = AppRole.user;
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

// En _LoginPageState — método _submit completo corregido
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final svc = ref.read(firebaseServiceProvider);

    // Acceso superAdmin via credenciales de entorno
    final isSuperAttempt = AppConfig.superAdminEmail.isNotEmpty &&
        email == AppConfig.superAdminEmail &&
        password == AppConfig.superAdminPassword;

    if (isSuperAttempt) {
      final result = await svc.signIn(email: email, password: password);
      if (!mounted) return;
      setState(() => _loading = false);

      if (result is Failure) {
        setState(() => _error = (result as Failure).message);
        return;
      }

      // Forzar isSuperAdmin en Firestore si aún no está seteado
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && !user.isSuperAdmin) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isSuperAdmin': true,
          'roles': ['superAdmin']
        });
        await Future.delayed(const Duration(milliseconds: 400));
      }

      if (!mounted) return;
      context.go(AppRoutesAuth.superDashboard);
      return;
    }

    // Login normal
    final result = await svc.signIn(email: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case Success():
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final updatedUser = ref.read(currentUserProvider).valueOrNull;
        if (updatedUser?.isSuperAdmin == true) {
          context.go(AppRoutesAuth.superDashboard);
        } else {
          context.go(AppRoutesAuth.dashboard);
        }
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              title: 'Crear cuenta',
              subtitle: 'Configura tu acceso al sistema',
            ),
            const SizedBox(height: 28),
            if (_error != null) ErrorBanner(message: _error!),

            FieldLabel('Nombre completo'),
            TextFormField(
              controller: _nameCtrl,
              style: inputStyle,
              decoration: inputDeco(
                hint: 'Juan García',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 14),

            FieldLabel('Email'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: inputStyle,
              decoration: inputDeco(
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

            FieldLabel('Contraseña'),
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
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),

            FieldLabel('Confirmar contraseña'),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: !_showPass,
              style: inputStyle,
              decoration: inputDeco(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
              ),
              validator: (v) =>
                  v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 20),

            FieldLabel('Rol del usuario'),
            const SizedBox(height: 8),
            RoleSelector(
              selected: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 24),

            SubmitButton(
              label: 'Crear cuenta',
              loading: _loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),

            ToggleLink(
              prompt: '¿Ya tienes cuenta?',
              action: 'Iniciar sesión',
              onTap: () => context.go(AppRoutesAuth.login),
            ),

            // ── BOTÓN PORTAL DISPOSITIVOS ──
            GestureDetector(
              onTap: () => context.go('/portal'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2D47), Color(0xFF172035)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: T.r12,
                  border: Border.all(color: T.primary.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: T.primary.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_rounded, color: T.primary, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Acceder como dispositivo',
                      style: TextStyle(
                        color: T.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: T.primary, size: 11),
                  ],
                ),
              ),
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
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

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
    return AuthScaffold(
      child: _sent ? _SuccessView() : _FormView(),
    );
  }

  Widget _SuccessView() => Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: T.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: T.success, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Email enviado',
              style: TextStyle(
                  color: T.textHi, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Hemos enviado instrucciones de recuperación a\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.textMid, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutesAuth.login),
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
            AuthHeader(
              title: 'Recuperar contraseña',
              subtitle: 'Te enviaremos un link para resetear tu contraseña',
            ),
            const SizedBox(height: 32),
            if (_error != null) ErrorBanner(message: _error!),
            FieldLabel('Email'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: inputStyle,
              decoration: inputDeco(
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
            SubmitButton(
              label: 'Enviar instrucciones',
              loading: _loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),
            ToggleLink(
              prompt: '¿Recuerdas tu contraseña?',
              action: 'Iniciar sesión',
              onTap: () => context.go(AppRoutesAuth.login),
            ),
          ],
        ),
      );
}

// ── Security Card ─────────────────────────────────────────────────────────────

class SecurityCard extends StatelessWidget {
  final GlobalKey<FormState> passForm;
  final TextEditingController currPassCtrl, newPassCtrl, confPassCtrl;
  final bool showPassFields, changingPass;
  final VoidCallback onToggle, onChangePassword;

  const SecurityCard({
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
    return CardContainer(
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
                        color: T.warning.withOpacity(0.10),
                        borderRadius: T.r8,
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: T.warning, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text('Seguridad',
                        style: TextStyle(
                            color: T.textHi,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    showPassFields ? 'Cancelar' : 'Cambiar contraseña',
                    style: const TextStyle(color: T.primary, fontSize: 13),
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
                          const Divider(color: T.divider),
                          const SizedBox(height: 16),
                          ProfileField(
                            label: 'Contraseña actual',
                            controller: currPassCtrl,
                            icon: Icons.lock_outline_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          ProfileField(
                            label: 'Nueva contraseña',
                            controller: newPassCtrl,
                            icon: Icons.lock_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          ProfileField(
                            label: 'Confirmar nueva contraseña',
                            controller: confPassCtrl,
                            icon: Icons.lock_rounded,
                            enabled: true,
                            obscure: true,
                            validator: (v) =>
                                v != newPassCtrl.text ? 'No coinciden' : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: changingPass ? null : onChangePassword,
                              child: changingPass
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
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

// ── Info Card ─────────────────────────────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final AppUser user;
  final bool editing, saving;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl, addressCtrl;
  final VoidCallback onEdit, onCancel, onSave;

  const InfoCard({
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
    return CardContainer(
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
                            color: T.primaryLo, borderRadius: T.r8),
                        child: const Icon(Icons.person_outline_rounded,
                            color: T.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Información personal',
                          style: TextStyle(
                              color: T.textHi,
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
                                    style: TextStyle(color: T.textMid)),
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
                                size: 18, color: T.textMid),
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
                    FormRow(
                      children: [
                        ProfileField(
                          label: 'Nombre completo',
                          controller: nameCtrl,
                          icon: Icons.badge_outlined,
                          enabled: editing,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        ProfileField(
                          label: 'Email',
                          controller: emailCtrl,
                          icon: Icons.mail_outline_rounded,
                          enabled: false,
                          validator: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FormRow(
                      children: [
                        ProfileField(
                          label: 'Teléfono',
                          controller: phoneCtrl,
                          icon: Icons.phone_outlined,
                          enabled: editing,
                          validator: null,
                        ),
                        ProfileField(
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
