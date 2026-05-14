// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================
abstract class _P {
  static const bg      = Color(0xFF060A14);
  static const surface = Color(0xFF0D1220);
  static const card    = Color(0xFF111827);
  static const border  = Color(0xFF1E2D47);
  static const primary = Color(0xFF6366F1);
  static const accent  = Color(0xFF38BDF8);
  static const green   = Color(0xFF22C55E);
  static const amber   = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);
  static const purple  = Color(0xFFA855F7);
  static const textHi  = Color(0xFFF1F5FF);
  static const textMid = Color(0xFF7B8DB0);
  static const textLo  = Color(0xFF2E3D5C);
}

// =============================================================================
// MODELOS
// =============================================================================
class DeviceUser {
  final String deviceId;
  final String deviceName;
  final String username;
  final String password;
  final String displayToken;
  final String? currentPlaylistId;
  final String? currentPlaylistName;

  const DeviceUser({
    required this.deviceId,
    required this.deviceName,
    required this.username,
    required this.password,
    required this.displayToken,
    this.currentPlaylistId,
    this.currentPlaylistName,
  });

  factory DeviceUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeviceUser(
      deviceId:            doc.id,
      deviceName:          d['name'] ?? 'Dispositivo',
      username:            d['portalUsername'] ?? '',
      password:            d['portalPassword'] ?? '',
      displayToken:        d['displayToken'] ?? '',
      currentPlaylistId:   d['currentPlaylistId'],
      currentPlaylistName: d['currentPlaylistName'],
    );
  }
}

class _PlaylistItem {
  final String id;
  final String type;
  final String title;
  final String? url;
  final String? textContent;
  final int durationSeconds;
  final int order;

  const _PlaylistItem({
    required this.id,
    required this.type,
    required this.title,
    this.url,
    this.textContent,
    this.durationSeconds = 10,
    required this.order,
  });

  factory _PlaylistItem.fromMap(Map<String, dynamic> d) => _PlaylistItem(
    id:              d['id'] ?? '',
    type:            d['type'] ?? 'text',
    title:           d['title'] ?? '',
    url:             d['url'],
    textContent:     d['textContent'],
    durationSeconds: d['durationSeconds'] ?? 10,
    order:           d['order'] ?? 0,
  );
}

class _PlaylistData {
  final String id;
  final String name;
  final String? description;
  final List<_PlaylistItem> items;
  final bool isActive;
  final String displayToken;

  const _PlaylistData({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    required this.isActive,
    required this.displayToken,
  });

  factory _PlaylistData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final raw = (d['items'] as List<dynamic>?) ?? [];
    return _PlaylistData(
      id:           doc.id,
      name:         d['name'] ?? 'Playlist',
      description:  d['description'],
      items:        raw
          .map((i) => _PlaylistItem.fromMap(i as Map<String, dynamic>))
          .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      isActive:     d['isActive'] ?? true,
      displayToken: d['displayToken'] ?? '',
    );
  }
}

// =============================================================================
// DEVICE PORTAL SCREEN — Login
// =============================================================================
class DevicePortalScreen extends StatefulWidget {
  const DevicePortalScreen({super.key});

  @override
  State<DevicePortalScreen> createState() => _DevicePortalScreenState();
}

class _DevicePortalScreenState extends State<DevicePortalScreen>
    with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _passCtrl.dispose();
    _bgCtrl.dispose(); _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('devices')
          .where('portalUsername', isEqualTo: _userCtrl.text.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() { _error = 'Usuario no encontrado'; _loading = false; });
        return;
      }

      final device = DeviceUser.fromFirestore(snap.docs.first);
      if (device.password != _passCtrl.text.trim()) {
        setState(() { _error = 'Contraseña incorrecta'; _loading = false; });
        return;
      }

      if (mounted) {
        context.go('/portal/dashboard', extra: device);
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    -0.5 + _bgCtrl.value,
                    -0.3 + _bgCtrl.value * 0.4,
                  ),
                  radius: 1.4,
                  colors: [
                    _P.primary.withOpacity(0.12),
                    _P.accent.withOpacity(0.06),
                    _P.bg,
                  ],
                ),
              ),
            ),
          ),

          // Floating orbs
          Positioned(
            top: size.height * 0.1,
            right: size.width * 0.05,
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _bgCtrl.value * 20 - 10),
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _P.purple.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.05,
            left: size.width * 0.05,
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, -_bgCtrl.value * 15 + 7),
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _P.accent.withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _logoCtrl,
                      curve: Curves.easeOutBack,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_P.primary, Color(0xFF818CF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _P.primary.withOpacity(0.4),
                                blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: const Icon(Icons.tv_rounded,
                            color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text('Portal de Pantallas',
                          style: TextStyle(
                            color: _P.textHi, fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        const Text('Accede para gestionar tu contenido',
                          style: TextStyle(color: _P.textMid, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login card
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _logoCtrl, curve: Curves.easeOut),
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _P.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error banner
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _P.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _P.red.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded,
                                  size: 16, color: _P.red),
                                const SizedBox(width: 8),
                                Text(_error!,
                                  style: const TextStyle(
                                    color: _P.red, fontSize: 13)),
                              ]),
                            ).animate().fadeIn().slideY(begin: -0.1),

                          // Username
                          _PortalLabel('Usuario'),
                          const SizedBox(height: 8),
                          _PortalField(
                            controller: _userCtrl,
                            hint: 'Tu nombre de usuario',
                            icon: Icons.person_outline_rounded,
                            onSubmit: (_) => FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _PortalLabel('Contraseña'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: const TextStyle(
                              color: _P.textHi, fontSize: 14),
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(
                                color: _P.textLo, fontSize: 14),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18, color: _P.textMid),
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                  setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                  size: 18, color: _P.textMid),
                              ),
                              filled: true,
                              fillColor: _P.card,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _P.border)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _P.border)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _P.primary, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _P.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                  _P.primary.withOpacity(0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                                : const Text('Iniciar sesión',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Powered by DigitalTV',
                    style: TextStyle(color: _P.textLo, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DEVICE DASHBOARD — Lista de playlists + visor fullscreen
// =============================================================================
class DeviceDashboardScreen extends StatefulWidget {
  final DeviceUser device;
  const DeviceDashboardScreen({super.key, required this.device});

  @override
  State<DeviceDashboardScreen> createState() => _DeviceDashboardScreenState();
}

class _DeviceDashboardScreenState extends State<DeviceDashboardScreen>
    with TickerProviderStateMixin {
  _PlaylistData? _selectedPlaylist;
  bool _fullscreen = false;
  late AnimationController _sidebarCtrl;

  @override
  void initState() {
    super.initState();
    _sidebarCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _sidebarCtrl.forward();
    _loadCurrentPlaylist();
  }

  @override
  void dispose() { _sidebarCtrl.dispose(); super.dispose(); }

  Future<void> _loadCurrentPlaylist() async {
    if (widget.device.currentPlaylistId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.device.currentPlaylistId)
          .get();
      if (doc.exists && mounted) {
        setState(() => _selectedPlaylist = _PlaylistData.fromFirestore(doc));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_fullscreen && _selectedPlaylist != null) {
      return _FullscreenViewer(
        playlist: _selectedPlaylist!,
        deviceId: widget.device.deviceId,
        onExit: () => setState(() => _fullscreen = false),
      );
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _sidebarCtrl, curve: Curves.easeOutCubic)),
            child: _Sidebar(device: widget.device),
          ),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                _DashboardTopBar(
                  device: widget.device,
                  selectedPlaylist: _selectedPlaylist,
                  onFullscreen: _selectedPlaylist != null
                    ? () => setState(() => _fullscreen = true)
                    : null,
                  onLogout: () => context.go('/portal'),
                ),

                // Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Playlists list
                      SizedBox(
                        width: 360,
                        child: _PlaylistsPanel(
                          deviceId: widget.device.deviceId,
                          selectedId: _selectedPlaylist?.id,
                          onSelect: (pl) => setState(() =>
                            _selectedPlaylist = pl),
                        ),
                      ),

                      Container(width: 1,
                        color: _P.border.withOpacity(0.5)),

                      // Preview panel
                      Expanded(
                        child: _selectedPlaylist == null
                          ? _EmptyPreview()
                          : _PreviewPanel(
                              playlist: _selectedPlaylist!,
                              deviceId: widget.device.deviceId,
                              onFullscreen: () =>
                                setState(() => _fullscreen = true),
                            ),
                      ),
                    ],
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

// =============================================================================
// SIDEBAR
// =============================================================================
class _Sidebar extends StatelessWidget {
  final DeviceUser device;
  const _Sidebar({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: _P.surface,
        border: Border(right: BorderSide(color: _P.border.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.primary, Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _P.primary.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.tv_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 32),

          _SidebarBtn(
            icon: Icons.playlist_play_rounded,
            label: 'Playlists',
            selected: true,
            color: _P.primary,
          ),
          const SizedBox(height: 8),
          _SidebarBtn(
            icon: Icons.tv_rounded,
            label: 'Display',
            selected: false,
            color: _P.accent,
          ),
          const Spacer(),

          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _P.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _P.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                device.deviceName.isNotEmpty
                  ? device.deviceName[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: _P.primary, fontWeight: FontWeight.w700,
                  fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  const _SidebarBtn({
    required this.icon, required this.label,
    required this.selected, required this.color});

  @override
  State<_SidebarBtn> createState() => _SidebarBtnState();
}

class _SidebarBtnState extends State<_SidebarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.label,
        preferBelow: false,
        child: AnimatedContainer(
          duration: 150.ms,
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: widget.selected || _hovered
              ? widget.color.withOpacity(0.15)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                ? widget.color.withOpacity(0.4)
                : Colors.transparent),
          ),
          child: Icon(widget.icon, size: 20,
            color: widget.selected ? widget.color : _P.textMid),
        ),
      ),
    );
  }
}

// =============================================================================
// TOP BAR
// =============================================================================
class _DashboardTopBar extends StatelessWidget {
  final DeviceUser device;
  final _PlaylistData? selectedPlaylist;
  final VoidCallback? onFullscreen;
  final VoidCallback onLogout;

  const _DashboardTopBar({
    required this.device,
    required this.selectedPlaylist,
    required this.onFullscreen,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _P.surface,
        border: Border(bottom: BorderSide(color: _P.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Device info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(device.deviceName,
                style: const TextStyle(
                  color: _P.textHi, fontWeight: FontWeight.w700,
                  fontSize: 15, letterSpacing: -0.3)),
              Text('@${device.username}',
                style: const TextStyle(color: _P.textMid, fontSize: 11)),
            ],
          ),
          const Spacer(),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _P.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.green.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: _P.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Conectado',
                style: TextStyle(color: _P.green, fontSize: 11,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 12),

          // Fullscreen button
          if (onFullscreen != null) ...[
            _TopBarBtn(
              icon: Icons.fullscreen_rounded,
              label: 'Pantalla completa',
              color: _P.accent,
              onTap: onFullscreen!,
            ),
            const SizedBox(width: 8),
          ],

          // Logout
          _TopBarBtn(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            color: _P.textMid,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _TopBarBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TopBarBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  State<_TopBarBtn> createState() => _TopBarBtnState();
}

class _TopBarBtnState extends State<_TopBarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 130.ms,
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _hovered
                ? widget.color.withOpacity(0.12)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                  ? widget.color.withOpacity(0.4)
                  : Colors.transparent),
            ),
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PLAYLISTS PANEL
// =============================================================================
class _PlaylistsPanel extends StatefulWidget {
  final String deviceId;
  final String? selectedId;
  final void Function(_PlaylistData) onSelect;
  const _PlaylistsPanel({
    required this.deviceId,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_PlaylistsPanel> createState() => _PlaylistsPanelState();
}

class _PlaylistsPanelState extends State<_PlaylistsPanel> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _P.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mis Playlists',
                  style: TextStyle(
                    color: _P.textHi, fontWeight: FontWeight.w700,
                    fontSize: 16, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                const Text('Selecciona una para reproducir',
                  style: TextStyle(color: _P.textMid, fontSize: 12)),
                const SizedBox(height: 14),
                // Search
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _P.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _P.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: _P.textHi, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Buscar playlist...',
                      hintStyle: TextStyle(color: _P.textLo, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                        size: 16, color: _P.textMid),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF1A2540)),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('playlists')
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _P.primary, strokeWidth: 2));
                }

                var playlists = snap.data!.docs
                    .map((d) => _PlaylistData.fromFirestore(d))
                    .toList();

                if (_search.isNotEmpty) {
                  playlists = playlists.where((p) =>
                    p.name.toLowerCase().contains(_search.toLowerCase()))
                    .toList();
                }

                if (playlists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_remove_rounded,
                          color: _P.textLo, size: 40),
                        const SizedBox(height: 12),
                        const Text('Sin playlists disponibles',
                          style: TextStyle(color: _P.textLo, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: playlists.length,
                  itemBuilder: (_, i) => _PlaylistTile(
                    playlist: playlists[i],
                    isSelected: playlists[i].id == widget.selectedId,
                    index: i,
                    onTap: () => widget.onSelect(playlists[i]),
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: i * 50)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatefulWidget {
  final _PlaylistData playlist;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;
  const _PlaylistTile({
    required this.playlist, required this.isSelected,
    required this.index, required this.onTap});

  @override
  State<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<_PlaylistTile> {
  bool _hovered = false;

  Color _typeColor(String type) {
    switch (type) {
      case 'image': return _P.accent;
      case 'video': return _P.purple;
      case 'text':  return _P.green;
      default:      return _P.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    final totalDur = pl.items.fold(0, (s, i) => s + i.durationSeconds);
    final mins = totalDur ~/ 60;
    final secs = totalDur % 60;
    final durStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
              ? _P.primary.withOpacity(0.12)
              : _hovered ? _P.card : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                ? _P.primary.withOpacity(0.4)
                : _hovered ? _P.border : Colors.transparent,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: 150.ms,
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                    ? const LinearGradient(
                        colors: [_P.primary, Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                  color: widget.isSelected
                    ? null : _P.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.playlist_play_rounded,
                  color: widget.isSelected ? Colors.white : _P.primary,
                  size: 20),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pl.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isSelected ? _P.textHi : _P.textMid,
                        fontWeight: widget.isSelected
                          ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text('${pl.items.length} elementos',
                        style: const TextStyle(
                          color: _P.textLo, fontSize: 11)),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3,
                        decoration: const BoxDecoration(
                          color: _P.textLo, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(durStr,
                        style: const TextStyle(
                          color: _P.textLo, fontSize: 11)),
                    ]),
                  ],
                ),
              ),

              // Type indicators
              if (pl.items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 3,
                  children: ({...pl.items.map((i) => i.type)}).map((t) =>
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _typeColor(t),
                        shape: BoxShape.circle),
                    )
                  ).toList(),
                ),
              ],

              const SizedBox(width: 8),
              if (widget.isSelected)
                const Icon(Icons.check_circle_rounded,
                  size: 16, color: _P.primary)
              else if (_hovered)
                const Icon(Icons.play_circle_outline_rounded,
                  size: 16, color: _P.textMid),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PREVIEW PANEL
// =============================================================================
class _PreviewPanel extends StatefulWidget {
  final _PlaylistData playlist;
  final String deviceId;
  final VoidCallback onFullscreen;
  const _PreviewPanel({
    required this.playlist,
    required this.deviceId,
    required this.onFullscreen,
  });

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  bool _playing = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    if (_playing) _startTimer();
  }

  @override
  void didUpdateWidget(_PreviewPanel old) {
    super.didUpdateWidget(old);
    if (old.playlist.id != widget.playlist.id) {
      _timer?.cancel();
      setState(() => _currentIndex = 0);
      _fadeCtrl.forward(from: 0);
      if (_playing) _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); _fadeCtrl.dispose(); super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.playlist.items.isEmpty) return;
    final idx = _currentIndex.clamp(0, widget.playlist.items.length - 1);
    final dur = widget.playlist.items[idx].durationSeconds;
    _timer = Timer(Duration(seconds: dur), _nextSlide);
  }

  Future<void> _nextSlide() async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex =
        (_currentIndex + 1) % widget.playlist.items.length;
    });
    await _fadeCtrl.forward();
    if (_playing) _startTimer();
  }

  Future<void> _prevSlide() async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.playlist.items.length)
        % widget.playlist.items.length;
    });
    await _fadeCtrl.forward();
    if (_playing) _startTimer();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _assignToDevice() async {
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({
        'currentPlaylistId':   widget.playlist.id,
        'currentPlaylistName': widget.playlist.name,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${widget.playlist.name}" asignada al dispositivo'),
            backgroundColor: _P.green.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _P.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    if (pl.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove_rounded,
              color: _P.textLo, size: 48),
            const SizedBox(height: 12),
            const Text('Playlist vacía',
              style: TextStyle(color: _P.textMid, fontSize: 16)),
          ],
        ),
      );
    }

    final safeIdx = _currentIndex.clamp(0, pl.items.length - 1);
    final item = pl.items[safeIdx];
    final totalDur = pl.items.fold(0, (s, i) => s + i.durationSeconds);

    return Column(
      children: [
        // ── Preview header ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pl.name,
                    style: const TextStyle(
                      color: _P.textHi, fontWeight: FontWeight.w700,
                      fontSize: 18, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(
                    '${pl.items.length} elementos · ${totalDur ~/ 60}m ${totalDur % 60}s',
                    style: const TextStyle(color: _P.textMid, fontSize: 12)),
                ],
              ),
              const Spacer(),

              // Assign button
              _ActionButton(
                icon: Icons.tv_rounded,
                label: 'Asignar a mi pantalla',
                color: _P.green,
                onTap: _assignToDevice,
              ),
              const SizedBox(width: 8),

              // Fullscreen button
              _ActionButton(
                icon: Icons.fullscreen_rounded,
                label: 'Pantalla completa',
                color: _P.accent,
                onTap: widget.onFullscreen,
              ),
            ],
          ),
        ),

        // ── Preview canvas 16:9 ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _P.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _ItemPreview(item: item),
                    ),

                    // Progress bar
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: _MiniProgressBar(
                        index: safeIdx,
                        total: pl.items.length,
                        durationSec: item.durationSeconds,
                        playing: _playing,
                        key: ValueKey('bar_$safeIdx'),
                      ),
                    ),

                    // Overlay controls on hover
                    Positioned.fill(
                      child: MouseRegion(
                        child: _CanvasOverlay(
                          onPrev: safeIdx > 0 ? _prevSlide : null,
                          onNext: safeIdx < pl.items.length - 1
                            ? _nextSlide : null,
                          onPlayPause: _togglePlay,
                          isPlaying: _playing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Items strip ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contenido',
                style: TextStyle(
                  color: _P.textMid, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pl.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final it = pl.items[i];
                    final isActive = i == safeIdx;
                    return GestureDetector(
                      onTap: () async {
                        _timer?.cancel();
                        await _fadeCtrl.reverse();
                        if (!mounted) return;
                        setState(() => _currentIndex = i);
                        await _fadeCtrl.forward();
                        if (_playing) _startTimer();
                      },
                      child: AnimatedContainer(
                        duration: 150.ms,
                        width: 100,
                        decoration: BoxDecoration(
                          color: isActive
                            ? _P.primary.withOpacity(0.12)
                            : _P.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                              ? _P.primary.withOpacity(0.5)
                              : _P.border,
                            width: isActive ? 2 : 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_itemIcon(it.type),
                              size: 20,
                              color: isActive ? _P.primary : _itemColor(it.type)),
                            const SizedBox(height: 4),
                            Text(it.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive ? _P.primary : _P.textMid,
                                fontSize: 9, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${it.durationSeconds}s',
                              style: const TextStyle(
                                color: _P.textLo, fontSize: 9)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _itemIcon(String type) {
    switch (type) {
      case 'image': return Icons.image_rounded;
      case 'video': return Icons.videocam_rounded;
      case 'text':  return Icons.text_fields_rounded;
      default:      return Icons.language_rounded;
    }
  }

  Color _itemColor(String type) {
    switch (type) {
      case 'image': return _P.accent;
      case 'video': return _P.purple;
      case 'text':  return _P.green;
      default:      return _P.amber;
    }
  }
}

// =============================================================================
// CANVAS OVERLAY
// =============================================================================
class _CanvasOverlay extends StatefulWidget {
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  const _CanvasOverlay({
    this.onPrev, this.onNext,
    required this.onPlayPause, required this.isPlaying});

  @override
  State<_CanvasOverlay> createState() => _CanvasOverlayState();
}

class _CanvasOverlayState extends State<_CanvasOverlay> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _visible = true),
      onExit:  (_) => setState(() => _visible = false),
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: 200.ms,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              // Prev
              GestureDetector(
                onTap: widget.onPrev,
                child: Container(
                  width: 48, height: double.infinity,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: widget.onPrev != null ? 1.0 : 0.3,
                    duration: 150.ms,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

              // Center play/pause
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: widget.onPlayPause,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle),
                      child: Icon(
                        widget.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),

              // Next
              GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  width: 48, height: double.infinity,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: widget.onNext != null ? 1.0 : 0.3,
                    duration: 150.ms,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 20),
                    ),
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

// =============================================================================
// FULLSCREEN VIEWER
// =============================================================================
class _FullscreenViewer extends StatefulWidget {
  final _PlaylistData playlist;
  final String deviceId;
  final VoidCallback onExit;
  const _FullscreenViewer({
    required this.playlist,
    required this.deviceId,
    required this.onExit,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  bool _playing = true;
  bool _showUI  = true;
  Timer? _hideUITimer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Realtime listener for playlist changes
  StreamSubscription? _playlistSub;
  _PlaylistData? _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _startTimer();
    _listenPlaylistChanges();
    _scheduleHideUI();
  }

  void _listenPlaylistChanges() {
    _playlistSub = FirebaseFirestore.instance
        .collection('playlists')
        .doc(widget.playlist.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _currentPlaylist = _PlaylistData.fromFirestore(doc);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideUITimer?.cancel();
    _playlistSub?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final pl = _currentPlaylist;
    if (pl == null || pl.items.isEmpty) return;
    final idx = _currentIndex.clamp(0, pl.items.length - 1);
    final dur = pl.items[idx].durationSeconds;
    _timer = Timer(Duration(seconds: dur), _nextSlide);
  }

  Future<void> _nextSlide() async {
    final pl = _currentPlaylist;
    if (pl == null || pl.items.isEmpty) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % pl.items.length;
    });
    await _fadeCtrl.forward();
    if (_playing) _startTimer();
  }

  void _scheduleHideUI() {
    _hideUITimer?.cancel();
    setState(() => _showUI = true);
    _hideUITimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showUI = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pl = _currentPlaylist;
    if (pl == null || pl.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tv_off_rounded,
                color: Colors.white30, size: 64),
              const SizedBox(height: 16),
              const Text('Sin contenido',
                style: TextStyle(color: Colors.white54, fontSize: 18)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: widget.onExit,
                child: const Text('Salir',
                  style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      );
    }

    final safeIdx = _currentIndex.clamp(0, pl.items.length - 1);
    final item = pl.items[safeIdx];

    return MouseRegion(
      onHover: (_) => _scheduleHideUI(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Content
            FadeTransition(
              opacity: _fadeAnim,
              child: _ItemPreview(item: item, fullscreen: true),
            ),

            // Progress bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _MiniProgressBar(
                index: safeIdx,
                total: pl.items.length,
                durationSec: item.durationSeconds,
                playing: _playing,
                key: ValueKey('fs_bar_$safeIdx'),
              ),
            ),

            // UI overlay
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: 400.ms,
              child: Stack(
                children: [
                  // Top gradient
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Top bar
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Exit button
                          GestureDetector(
                            onTap: widget.onExit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white24)),
                              child: const Row(children: [
                                Icon(Icons.fullscreen_exit_rounded,
                                  size: 16, color: Colors.white70),
                                SizedBox(width: 6),
                                Text('Salir',
                                  style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(pl.name,
                            style: const TextStyle(
                              color: Colors.white70, fontSize: 14,
                              fontWeight: FontWeight.w600)),
                          const Spacer(),
                          // Slide indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${safeIdx + 1} / ${pl.items.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom gradient
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Bottom controls
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FSControl(
                          icon: Icons.skip_previous_rounded,
                          onTap: safeIdx > 0
                            ? () async {
                                _timer?.cancel();
                                await _fadeCtrl.reverse();
                                if (!mounted) return;
                                setState(() {
                                  _currentIndex = safeIdx - 1;
                                });
                                await _fadeCtrl.forward();
                                if (_playing) _startTimer();
                              }
                            : null,
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() => _playing = !_playing);
                            if (_playing) {
                              _startTimer();
                            } else {
                              _timer?.cancel();
                            }
                          },
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _P.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _P.primary.withOpacity(0.4),
                                  blurRadius: 16, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Icon(
                              _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _FSControl(
                          icon: Icons.skip_next_rounded,
                          onTap: safeIdx < pl.items.length - 1
                            ? () async {
                                _timer?.cancel();
                                await _fadeCtrl.reverse();
                                if (!mounted) return;
                                setState(() {
                                  _currentIndex = safeIdx + 1;
                                });
                                await _fadeCtrl.forward();
                                if (_playing) _startTimer();
                              }
                            : null,
                        ),
                      ],
                    ),
                  ),

                  // Items thumbnail strip
                  Positioned(
                    bottom: 90, left: 0, right: 0,
                    child: SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: pl.items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final isActive = i == safeIdx;
                          return GestureDetector(
                            onTap: () async {
                              _timer?.cancel();
                              await _fadeCtrl.reverse();
                              if (!mounted) return;
                              setState(() => _currentIndex = i);
                              await _fadeCtrl.forward();
                              if (_playing) _startTimer();
                            },
                            child: AnimatedContainer(
                              duration: 150.ms,
                              width: 50,
                              decoration: BoxDecoration(
                                color: isActive
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black45,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                    ? Colors.white
                                    : Colors.white24,
                                  width: isActive ? 2 : 1),
                              ),
                              child: Icon(
                                _iconFor(pl.items[i].type),
                                size: 18,
                                color: isActive ? Colors.white : Colors.white54),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'image': return Icons.image_rounded;
      case 'video': return Icons.videocam_rounded;
      case 'text':  return Icons.text_fields_rounded;
      default:      return Icons.language_rounded;
    }
  }
}

class _FSControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _FSControl({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedOpacity(
      opacity: onTap != null ? 1.0 : 0.3,
      duration: 150.ms,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

// =============================================================================
// ITEM PREVIEW
// =============================================================================
class _ItemPreview extends StatelessWidget {
  final _PlaylistItem item;
  final bool fullscreen;
  const _ItemPreview({required this.item, this.fullscreen = false});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'image': return _ImageContent(url: item.url ?? '');
      case 'video': return _VideoContent(url: item.url ?? '', title: item.title);
      case 'text':  return _TextContent(text: item.textContent ?? '', title: item.title);
      default:      return _UrlContent(url: item.url ?? '', title: item.title);
    }
  }
}

class _ImageContent extends StatelessWidget {
  final String url;
  const _ImageContent({required this.url});

  String _proxyUrl(String u) {
    if (u.contains('firebasestorage.googleapis.com')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(u)}&output=webp&n=-1';
    }
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(u)}&n=-1';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Image.network(
        _proxyUrl(url),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded,
                color: Colors.white30, size: 48),
              const SizedBox(height: 8),
              Text(url, style: const TextStyle(
                color: Colors.white24, fontSize: 10),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoContent extends StatefulWidget {
  final String url;
  final String title;
  const _VideoContent({required this.url, required this.title});

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  final _viewId = 'portal-vid-${DateTime.now().millisecondsSinceEpoch}';
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    try {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
        if (widget.url.contains('.m3u8')) {
          final iframe = html.IFrameElement()
            ..srcdoc = '''
<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;display:flex;align-items:center;justify-content:center;}video{width:100%;height:100%;object-fit:contain;}</style>
</head><body>
<div id="r" style="width:100%;height:100%"></div>
<script>
const url="${widget.url}";
function start(){
  const v=document.createElement('video');v.autoplay=true;v.muted=true;v.controls=true;v.style.cssText='width:100%;height:100%;object-fit:contain;';
  if(typeof Hls!=='undefined'&&Hls.isSupported()){const h=new Hls();h.loadSource(url);h.attachMedia(v);h.on(Hls.Events.MANIFEST_PARSED,()=>{v.play();document.getElementById('r').innerHTML='';document.getElementById('r').appendChild(v);});}
  else if(v.canPlayType('application/vnd.apple.mpegurl')){v.src=url;v.play();document.getElementById('r').appendChild(v);}
}
const s=document.createElement('script');s.src='https://cdn.jsdelivr.net/npm/hls.js@1.5.13/dist/hls.min.js';s.onload=start;document.head.appendChild(s);
</script></body></html>'''
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..setAttribute('sandbox', 'allow-scripts allow-same-origin');
          return iframe;
        }
        final video = html.VideoElement()
          ..src = widget.url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..autoplay = true
          ..controls = true
          ..muted = true;
        return video;
      });
      _registered = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded,
                color: Colors.white30, size: 48),
              const SizedBox(height: 8),
              Text(widget.title,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return HtmlElementView(viewType: _viewId);
  }
}

class _TextContent extends StatelessWidget {
  final String text;
  final String title;
  const _TextContent({required this.text, required this.title});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width < 600 ? 24.0 : 40.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F1E), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty) ...[
                Text(title,
                  style: TextStyle(
                    color: _P.primary,
                    fontSize: fontSize * 0.38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5),
                  textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
              Text(text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.3),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrlContent extends StatelessWidget {
  final String url;
  final String title;
  const _UrlContent({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _P.amber.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _P.amber.withOpacity(0.4), width: 2)),
              child: const Icon(Icons.language_rounded,
                color: _P.amber, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(url, style: const TextStyle(
              color: Colors.white38, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROGRESS BAR
// =============================================================================
class _MiniProgressBar extends StatefulWidget {
  final int index, total, durationSec;
  final bool playing;
  const _MiniProgressBar({
    super.key, required this.index, required this.total,
    required this.durationSec, required this.playing});

  @override
  State<_MiniProgressBar> createState() => _MiniProgressBarState();
}

class _MiniProgressBarState extends State<_MiniProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSec));
    if (widget.playing) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_MiniProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _ctrl.forward(from: _ctrl.value);
    if (!widget.playing && old.playing) _ctrl.stop();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: List.generate(widget.total, (i) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2)),
            child: i < widget.index
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2)))
              : i == widget.index
              ? AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _ctrl.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2))))))
              : const SizedBox.shrink(),
          ),
        )),
      ),
    );
  }
}

// =============================================================================
// EMPTY PREVIEW
// =============================================================================
class _EmptyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _P.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _P.primary.withOpacity(0.2))),
            child: const Icon(Icons.touch_app_rounded,
              color: _P.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Selecciona una playlist',
            style: TextStyle(
              color: _P.textHi, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Elige una playlist del panel izquierdo\npara previsualizar su contenido',
            style: TextStyle(color: _P.textMid, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
      begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================
class _PortalLabel extends StatelessWidget {
  final String text;
  const _PortalLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      color: _P.textMid, fontSize: 13,
      fontWeight: FontWeight.w600));
}

class _PortalField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final void Function(String)? onSubmit;
  const _PortalField({
    required this.controller, required this.hint,
    required this.icon, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _P.textHi, fontSize: 14),
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _P.textLo, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: _P.textMid),
        filled: true,
        fillColor: _P.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _P.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _P.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _P.primary, width: 2)),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
              ? widget.color.withOpacity(0.15)
              : widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                ? widget.color.withOpacity(0.5)
                : widget.color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.color),
              const SizedBox(width: 6),
              Text(widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}