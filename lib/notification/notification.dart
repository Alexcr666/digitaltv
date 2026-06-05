// =============================================================================
// 8. NOTIFICATIONS PAGE + PUSH OVERLAY
// =============================================================================

// ── PUSH NOTIFICATION OVERLAY ────────────────────────────────────────────────

import 'package:digitaltv/auth/auth.dart';
import 'package:digitaltv/auth/authSystem.dart';
import 'package:digitaltv/auth/firebaseService.dart';
import 'package:digitaltv/auth/page/login.dart';
import 'package:digitaltv/provider/app_providers.dart';
import 'package:digitaltv/utils/permission_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const bg = Color(0xFF080C14);
  static const surface = Color(0xFF0E1420);
  static const card = Color(0xFF131B2B);
  static const cardHover = Color(0xFF172035);
  static const border = Color(0xFF1E2D47);
  static const divider = Color(0xFF1A2540);

  // Brand
  static const primary = Color(0xFF6366F1);
  static const primaryLo = Color(0x1A6366F1);
  static const primaryMid = Color(0x336366F1);
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: _T.r12,
              border: const Border.fromBorderSide(BorderSide(color: _T.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 8),
                Text(value,
                    style: const TextStyle(color: _T.textMid, fontSize: 13)),
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
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: _T.textMid),
      suffixIcon: suffix,
    );

Widget _togglePassButton({
  required bool show,
  required VoidCallback onTap,
}) =>
    IconButton(
      icon: Icon(
        show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 18,
        color: _T.textMid,
      ),
      onPressed: onTap,
    );

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Ahora mismo';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';

  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: _T.textMid,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3)),
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
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser? user;
  final double size;
  const _Avatar({this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _T.primaryMid,
        shape: BoxShape.circle,
        border: Border.all(color: _T.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialsWidget(initials: initials, size: size))
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
                color: _T.primary,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700)),
      );
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
                    color: _T.primary,
                    fontSize: 13,
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
        message: message, color: _T.error, icon: Icons.error_outline_rounded);
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: _T.r12,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. ROUTES
// =============================================================================

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const roles = '/roles';
  static const dashboard = '/dashboard';
}

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
// 3. ROUTER
// =============================================================================

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRouteNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuth = ref.read(authStateProvider).valueOrNull != null;
      final isLoading = ref.read(authStateProvider).isLoading;

      if (isLoading) return null;

      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];
      final isPublic = publicRoutes.contains(state.matchedLocation);

      if (!isAuth && !isPublic) return AppRoutes.login;
      if (isAuth && isPublic) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
    ],
    //  errorBuilder: (_, state) => _ErrorPage(error: state.error.toString()),
  );
});

class NotificationPushOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationPushOverlay({super.key, required this.child});

  @override
  ConsumerState<NotificationPushOverlay> createState() =>
      _NotificationPushOverlayState();
}

class _NotificationPushOverlayState
    extends ConsumerState<NotificationPushOverlay> {
  final List<_PushEntry> _queue = [];
  final Set<String> _shown = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenNotifications();
  }

  void _listenNotifications() {
    /* final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    ref.listen(newNotificationsProvider(user.uid), (_, next) {
      final notifs = next.valueOrNull ?? [];
      for (final n in notifs) {
        if (_shown.contains(n.id)) continue;
        _shown.add(n.id);
        _enqueue(n);
      }
    });
    */
  }

  void _enqueue(AppNotification notif) {
    final entry = _PushEntry(notif: notif);
    setState(() => _queue.add(entry));
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _queue.remove(entry));
    });
  }

  void _dismiss(_PushEntry entry) {
    if (mounted) setState(() => _queue.remove(entry));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 70,
          right: 16,
          child: SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _queue
                  .map((e) => _PushCard(entry: e, onDismiss: () => _dismiss(e)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PushEntry {
  final AppNotification notif;
  _PushEntry({required this.notif});
}

class _PushCard extends StatefulWidget {
  final _PushEntry entry;
  final VoidCallback onDismiss;
  const _PushCard({required this.entry, required this.onDismiss});

  @override
  State<_PushCard> createState() => _PushCardState();
}

class _PushCardState extends State<_PushCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slide = Tween<double>(begin: 60, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _typeColor => switch (widget.entry.notif.type) {
        NotificationType.success => _T.success,
        NotificationType.warning => _T.warning,
        NotificationType.error => _T.error,
        NotificationType.system => _T.primary,
        NotificationType.info => _T.accent,
      };

  IconData get _typeIcon => switch (widget.entry.notif.type) {
        NotificationType.success => Icons.check_circle_rounded,
        NotificationType.warning => Icons.warning_rounded,
        NotificationType.error => Icons.error_rounded,
        NotificationType.system => Icons.settings_rounded,
        NotificationType.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(_slide.value, 0),
        child: Opacity(
          opacity: _fade.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: _T.r16,
              border:
                  Border.all(color: _typeColor.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _typeColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: _T.r16,
              child: Stack(
                children: [
                  // Accent left bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: _typeColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon, color: _typeColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.entry.notif.title,
                                  style: const TextStyle(
                                      color: _T.textHi,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                widget.entry.notif.body,
                                style: const TextStyle(
                                    color: _T.textMid,
                                    fontSize: 12,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _ProgressBar(
                                duration: const Duration(seconds: 5),
                                color: _typeColor,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 14, color: _T.textLo),
                          onPressed: widget.onDismiss,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  const _ProgressBar({required this.duration, required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: 1 - _ctrl.value,
          backgroundColor: widget.color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(widget.color),
          minHeight: 2,
        ),
      ),
    );
  }
}

// ── NOTIFICATIONS PAGE ───────────────────────────────────────────────────────

class NotificationsPage22 extends ConsumerWidget {
  const NotificationsPage22({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final notifsAsync = ref.watch(notificationsProvider(user.uid));
    final svc = ref.read(firebaseServiceProvider);
    final canSend = user.hasPermission(AppPermission.notificationsSend);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notificaciones',
                  style: TextStyle(
                      color: _T.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              Row(
                children: [
                  if (canSend)
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context, ref, user),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Nueva notificación'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  if (canSend) const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => svc.markAllNotificationsRead(user.uid),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Marcar todas leídas'),
                    style: TextButton.styleFrom(foregroundColor: _T.primary),
                  ),
                ],
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _T.primaryLo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: _T.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('Sin notificaciones',
                            style: TextStyle(
                                color: _T.textHi,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Las notificaciones aparecerán aquí',
                            style: TextStyle(color: _T.textMid, fontSize: 13)),
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

  void _showCreateDialog(BuildContext context, WidgetRef ref, AppUser sender) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateNotificationDialog(sender: sender, ref: ref),
    );
  }
}

// ── CREATE NOTIFICATION DIALOG ───────────────────────────────────────────────

class _CreateNotificationDialog extends ConsumerStatefulWidget {
  final AppUser sender;
  final WidgetRef ref;
  const _CreateNotificationDialog({required this.sender, required this.ref});

  @override
  ConsumerState<_CreateNotificationDialog> createState() =>
      _CreateNotificationDialogState();
}

class _CreateNotificationDialogState
    extends ConsumerState<_CreateNotificationDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  NotificationType _type = NotificationType.info;
  String _target = 'self'; // 'self' | 'all' | 'user'
  AppUser? _targetUser;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Color get _typeColor => switch (_type) {
        NotificationType.success => _T.success,
        NotificationType.warning => _T.warning,
        NotificationType.error => _T.error,
        NotificationType.system => _T.primary,
        NotificationType.info => _T.accent,
      };

  IconData get _typeIcon => switch (_type) {
        NotificationType.success => Icons.check_circle_rounded,
        NotificationType.warning => Icons.warning_rounded,
        NotificationType.error => Icons.error_rounded,
        NotificationType.system => Icons.settings_rounded,
        NotificationType.info => Icons.info_rounded,
      };

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_target == 'user' && _targetUser == null) {
      setState(() => _error = 'Selecciona un usuario destinatario');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final svc = ref.read(firebaseServiceProvider);
    final users = ref.read(allUsersProvider).valueOrNull ?? [];

    List<String> targetUids = switch (_target) {
      'self' => [widget.sender.uid],
      'all' => users.map((u) => u.uid).toList(),
      'user' => [_targetUser!.uid],
      _ => [widget.sender.uid],
    };

    String? lastError;
    for (final uid in targetUids) {
      final result = await svc.createNotification(AppNotification(
        id: '',
        userId: uid,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        type: _type,
        read: false,
        createdAt: DateTime.now(),
      ));
      if (result is Failure) lastError = (result as Failure).message;
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
    });

    if (lastError != null) {
      setState(() => _error = lastError);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: _T.r20,
              border:
                  Border.all(color: _typeColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _typeColor.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _sent ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _T.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _T.success, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('¡Notificación enviada!',
              style: TextStyle(
                  color: _T.textHi, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Los destinatarios la recibirán en tiempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _T.textMid, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final usersAsync = ref.watch(allUsersProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nueva notificación',
                            style: TextStyle(
                                color: _T.textHi,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('Se entregará en tiempo real vía Firestore',
                            style: TextStyle(color: _T.textMid, fontSize: 12)),
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

              const SizedBox(height: 24),
              const Divider(color: _T.divider),
              const SizedBox(height: 20),

              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 8),
              ],

              // Tipo
              const _FieldLabel('Tipo de notificación'),
              const SizedBox(height: 8),
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),

              const SizedBox(height: 20),

              // Título
              const _FieldLabel('Título *'),
              TextFormField(
                controller: _titleCtrl,
                style: _inputStyle,
                maxLength: 80,
                decoration: _inputDeco(
                  hint: 'Ej: Mantenimiento programado',
                  icon: Icons.title_rounded,
                ).copyWith(
                    counterStyle:
                        const TextStyle(color: _T.textLo, fontSize: 10)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El título es requerido';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cuerpo
              const _FieldLabel('Mensaje *'),
              TextFormField(
                controller: _bodyCtrl,
                style: _inputStyle,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Describe el contenido de la notificación...',
                  hintStyle: const TextStyle(color: _T.textLo, fontSize: 13),
                  filled: true,
                  fillColor: _T.card,
                  counterStyle: const TextStyle(color: _T.textLo, fontSize: 10),
                  border: OutlineInputBorder(
                      borderRadius: _T.r12,
                      borderSide: const BorderSide(color: _T.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: _T.r12,
                      borderSide: const BorderSide(color: _T.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: _T.r12,
                      borderSide:
                          const BorderSide(color: _T.primary, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: _T.r12,
                      borderSide: const BorderSide(color: _T.error)),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: _T.r12,
                      borderSide:
                          const BorderSide(color: _T.error, width: 1.5)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El mensaje es requerido';
                  if (v.trim().length < 5) return 'Mínimo 5 caracteres';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Destinatario
              const _FieldLabel('Destinatario'),
              const SizedBox(height: 8),
              _TargetSelector(
                selected: _target,
                onChanged: (t) => setState(() {
                  _target = t;
                  _targetUser = null;
                }),
              ),

              // User picker si target == 'user'
              if (_target == 'user') ...[
                const SizedBox(height: 14),
                const _FieldLabel('Seleccionar usuario'),
                const SizedBox(height: 6),
                usersAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: _T.primary, strokeWidth: 2)),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: _T.error, fontSize: 12)),
                  data: (users) {
                    final others =
                        users.where((u) => u.uid != widget.sender.uid).toList();
                    return Container(
                      decoration: BoxDecoration(
                        color: _T.surface,
                        borderRadius: _T.r12,
                        border: const Border.fromBorderSide(
                            BorderSide(color: _T.border)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AppUser>(
                          value: _targetUser,
                          isExpanded: true,
                          dropdownColor: _T.card,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          hint: const Text('Elige un usuario',
                              style: TextStyle(color: _T.textLo, fontSize: 13)),
                          items: others
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Row(
                                      children: [
                                        _Avatar(user: u, size: 24),
                                        const SizedBox(width: 8),
                                        Text(u.name,
                                            style: const TextStyle(
                                                color: _T.textHi,
                                                fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Text(u.email,
                                            style: const TextStyle(
                                                color: _T.textLo,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (u) => setState(() => _targetUser = u),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 28),

              // Preview card
              _NotifPreview(
                title: _titleCtrl.text,
                body: _bodyCtrl.text,
                type: _type,
              ),

              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor,
                    disabledBackgroundColor: _T.card,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Enviar notificación',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
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

// ── TYPE SELECTOR ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final NotificationType selected;
  final ValueChanged<NotificationType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NotificationType.values.map((t) {
        final isSelected = t == selected;
        final color = _color(t);
        return GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : _T.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color.withOpacity(0.6) : _T.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(t), size: 14, color: isSelected ? color : _T.textLo),
                const SizedBox(width: 6),
                Text(t.label,
                    style: TextStyle(
                      color: isSelected ? color : _T.textMid,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _color(NotificationType t) => switch (t) {
        NotificationType.success => _T.success,
        NotificationType.warning => _T.warning,
        NotificationType.error => _T.error,
        NotificationType.system => _T.primary,
        NotificationType.info => _T.accent,
      };

  IconData _icon(NotificationType t) => switch (t) {
        NotificationType.success => Icons.check_circle_rounded,
        NotificationType.warning => Icons.warning_rounded,
        NotificationType.error => Icons.error_rounded,
        NotificationType.system => Icons.settings_rounded,
        NotificationType.info => Icons.info_rounded,
      };
}

// ── TARGET SELECTOR ───────────────────────────────────────────────────────────

class _TargetSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TargetSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('self', Icons.person_rounded, 'Solo yo'),
      ('all', Icons.groups_rounded, 'Todos los usuarios'),
      ('user', Icons.person_search_rounded, 'Usuario específico'),
    ];

    return Row(
      children: options.map((opt) {
        final (val, icon, label) = opt;
        final isSelected = val == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _T.primaryLo : _T.surface,
                borderRadius: _T.r12,
                border: Border.all(
                  color: isSelected ? _T.primary.withOpacity(0.5) : _T.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 20, color: isSelected ? _T.primary : _T.textMid),
                  const SizedBox(height: 4),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? _T.primary : _T.textMid,
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── NOTIF PREVIEW ─────────────────────────────────────────────────────────────

class _NotifPreview extends StatefulWidget {
  final String title, body;
  final NotificationType type;
  const _NotifPreview(
      {required this.title, required this.body, required this.type});

  @override
  State<_NotifPreview> createState() => _NotifPreviewState();
}

class _NotifPreviewState extends State<_NotifPreview> {
  @override
  Widget build(BuildContext context) {
    if (widget.title.isEmpty && widget.body.isEmpty)
      return const SizedBox.shrink();

    final color = switch (widget.type) {
      NotificationType.success => _T.success,
      NotificationType.warning => _T.warning,
      NotificationType.error => _T.error,
      NotificationType.system => _T.primary,
      NotificationType.info => _T.accent,
    };
    final icon = switch (widget.type) {
      NotificationType.success => Icons.check_circle_rounded,
      NotificationType.warning => Icons.warning_rounded,
      NotificationType.error => Icons.error_rounded,
      NotificationType.system => Icons.settings_rounded,
      NotificationType.info => Icons.info_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: _T.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('Vista previa',
                  style: const TextStyle(color: _T.textLo, fontSize: 11)),
            ),
            const Expanded(child: Divider(color: _T.divider)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: _T.r12,
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title.isEmpty ? 'Título...' : widget.title,
                        style: TextStyle(
                          color: widget.title.isEmpty ? _T.textLo : _T.textHi,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(widget.body.isEmpty ? 'Mensaje...' : widget.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.body.isEmpty ? _T.textLo : _T.textMid,
                          fontSize: 11,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── NOTIF TILE ────────────────────────────────────────────────────────────────

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

  IconData get _typeIcon => switch (notif.type) {
        NotificationType.success => Icons.check_circle_rounded,
        NotificationType.warning => Icons.warning_rounded,
        NotificationType.error => Icons.error_rounded,
        NotificationType.system => Icons.settings_rounded,
        NotificationType.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
          child: Icon(_typeIcon, color: _typeColor, size: 18),
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(notif.type.label,
                      style: TextStyle(
                          color: _typeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(_formatDate(notif.createdAt),
                    style: const TextStyle(color: _T.textLo, fontSize: 11)),
              ],
            ),
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
