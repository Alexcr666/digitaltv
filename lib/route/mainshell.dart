// lib/presentation/screens/shell/main_shell.dart
import 'package:digitaltv/entities/entities.dart';
import 'package:digitaltv/firestore/apptheme.dart';
import 'package:digitaltv/firestore/auth_provider.dart';
import 'package:digitaltv/route/route.dart';
import 'package:digitaltv/route/shellprovider.dart' as provider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


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
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentUser: user),
          Expanded(
            child: Column(
              children: [
                _TopBar(currentUser: user),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 220.ms,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final UserEntity? currentUser;
  const _Sidebar({this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final onlineCount = ref.watch(provider.onlineDevicesCountProvider);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.dark800 : Colors.white;
    final borderColor = isDark ? const Color(0x0FFFFFFF) : AppColors.light200;

    return AnimatedContainer(
      duration: 200.ms,
      width: 220,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('SignageOS', style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ENT', style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),


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

          // Nav sections
          _NavLabel('Workspace'),
          _NavItem(icon: Icons.space_dashboard_outlined, label: 'Dashboard',
              route: AppRoutes.dashboard, current: location),
          _NavItem(icon: Icons.tv_outlined, label: 'Devices',
              route: AppRoutes.devices, current: location,
              badge: onlineCount.valueOrNull?.toString()),
        //  _NavItem(icon: Icons.perm_media_outlined, label: 'Content',
          //    route: AppRoutes.content, current: location),
        
   
      
   _NavItem(icon: Icons.send_outlined, label: 'Lista de reproducción',
              route: "/playlist2", current: location),
   _NavItem(icon: Icons.send_outlined, label: 'Programación',
              route: "/schedules", current: location),
  //_NavItem(icon: Icons.send_outlined, label: 'Analitica',
    //          route: "/analytics", current: location),

  _NavItem(icon: Icons.send_outlined, label: 'Biblioteca de medios',
              route: "/media", current: location),

  _NavItem(icon: Icons.send_outlined, label: 'Editor Playlists',
              route: "/editor", current: location),
          const SizedBox(height: 8),
          _NavLabel('Admin'),
          _NavItem(icon: Icons.manage_accounts_outlined, label: 'Roles & Access',
              route: AppRoutes.roles, current: location,
              hidden: /*!(currentUser?.role.canManageUsers ?? false*/true),

          const Spacer(),
          const Divider(height: 1),
          // User card
          Padding(
            padding: const EdgeInsets.all(12),
            child: _UserCard(user: currentUser),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
  }
}

class _NavLabel extends StatelessWidget {
  final String text;
  const _NavLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;
  final String? badge;
  final bool hidden;

  const _NavItem({
    required this.icon, required this.label,
    required this.route, required this.current,
    this.badge, this.hidden = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hidden) return const SizedBox.shrink();

    final isActive = current.startsWith(route);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: AnimatedContainer(
        duration: 150.ms,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => context.go(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(icon,
                    size: 17,
                    color: isActive ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 10),
                  Text(label, style: theme.textTheme.bodyLarge?.copyWith(
                    color: isActive ? AppColors.primary : null,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 13,
                  )),
                  if (badge != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.online.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.online,
                      )),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserEntity? user;
  const _UserCard({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();

    final initials = user!.displayName.isNotEmpty
        ? user!.displayName.split(' ').take(2).map((e) => e[0]).join()
        : user!.email[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(initials, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
          ))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user!.displayName, style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500, fontSize: 12,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(user!.role.name, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 16),
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          color: theme.textTheme.bodyMedium?.color,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  final UserEntity? currentUser;
  const _TopBar({this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark800 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0x0FFFFFFF) : AppColors.light200,
          ),
        ),
      ),
      child: Row(
        children: [
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.online.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.online.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                _PulseDot(),
                const SizedBox(width: 5),
                Text('Live', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.online,
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Search bar (web)
          Expanded(
            child: Container(
              height: 34,
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark700 : AppColors.light100,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isDark ? const Color(0x18FFFFFF) : AppColors.light200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 15,
                    color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 8),
                  Text('Search devices, content…',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dark600 : AppColors.light200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('⌘K', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Theme toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            color: theme.textTheme.bodyMedium?.color,
          ),

          const SizedBox(width: 4),
          // Add device button
          ElevatedButton.icon(
            onPressed: () => _showRegisterDeviceDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Register TV'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _RegisterDeviceDialog(),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle),
    ),
  );
}

class _RegisterDeviceDialog extends ConsumerStatefulWidget {
  const _RegisterDeviceDialog();
  @override
  ConsumerState<_RegisterDeviceDialog> createState() => _RegisterDeviceDialogState();
}

class _RegisterDeviceDialogState extends ConsumerState<_RegisterDeviceDialog> {
  final _nameCtrl = TextEditingController();
  final _idCtrl   = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _idCtrl.dispose(); super.dispose(); }
// REEMPLAZA el método _submit() en _RegisterDeviceDialogState por este:

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _idCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    final uc = ref.read(provider.registerDeviceUseCaseProvider);
    final result = await uc(
      name: _nameCtrl.text,
      uniqueDeviceId: _idCtrl.text,
    );

    if (!mounted) return;

    switch (result) {
      case provider.RegisterSuccess():
        Navigator.pop(context);
      case provider.RegisterFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register New TV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Display Name', hintText: 'e.g. Lobby Main Screen')),
          const SizedBox(height: 12),
          TextField(controller: _idCtrl, decoration: const InputDecoration(labelText: 'Device ID', hintText: 'Unique hardware ID')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
        ),
      ],
    );
  }
}