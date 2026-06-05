// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================
abstract class _P {
  static const bg = Color(0xFF060A14);
  static const surface = Color(0xFF0D1220);
  static const card = Color(0xFF111827);
  static const border = Color(0xFF1E2D47);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF38BDF8);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
  static const textHi = Color(0xFFF1F5FF);
  static const textMid = Color(0xFF7B8DB0);
  static const textLo = Color(0xFF2E3D5C);
}

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
      deviceId: doc.id,
      deviceName: d['name'] ?? 'Dispositivo',
      username: d['portalUsername'] ?? '',
      password: d['portalPassword'] ?? '',
      displayToken: d['displayToken'] ?? '',
      currentPlaylistId: d['currentPlaylistId'],
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
        id: d['id'] ?? '',
        type: d['type'] ?? 'text',
        title: d['title'] ?? '',
        url: d['url'],
        textContent: d['textContent'],
        durationSeconds: d['durationSeconds'] ?? 10,
        order: d['order'] ?? 0,
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
    final raw =
        (d['items'] as List<dynamic>?) ?? (d['clips'] as List<dynamic>?) ?? [];
    return _PlaylistData(
      id: doc.id,
      name: d['name'] ?? 'Playlist',
      description: d['description'],
      items: raw.map((i) {
        final map = i as Map<String, dynamic>;
        return _PlaylistItem(
          id: map['id'] ?? '',
          type: map['type'] ?? 'text',
          title: map['title'] ?? map['label'] ?? '',
          url: map['url'],
          textContent: map['textContent'] ?? map['text'],
          durationSeconds: (() {
            final v = map['durationSeconds'] ?? map['durationSec'] ?? 10;
            return v is int ? v : (v as num).round();
          })(),
          order: map['order'] ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      isActive: d['isActive'] ?? true,
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
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('devices')
          .where('portalUsername', isEqualTo: _userCtrl.text.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _error = 'Usuario no encontrado';
          _loading = false;
        });
        return;
      }

      final device = DeviceUser.fromFirestore(snap.docs.first);
      if (device.password != _passCtrl.text.trim()) {
        setState(() {
          _error = 'Contraseña incorrecta';
          _loading = false;
        });
        return;
      }

      // Guardar sesión en localStorage
      html.window.localStorage['portal_session'] = jsonEncode({
        'deviceId': device.deviceId,
        'deviceName': device.deviceName,
        'username': device.username,
        'password': device.password,
        'displayToken': device.displayToken,
        'currentPlaylistId': device.currentPlaylistId,
        'currentPlaylistName': device.currentPlaylistName,
      });

      if (mounted) {
        context.go('/portal/dashboard', extra: device);
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
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
                  width: 300,
                  height: 300,
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
                  width: 250,
                  height: 250,
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
                        AppLogo(height: 250, showBadge: false),
                        const SizedBox(height: 16),
                        const Text('Portal de Pantallas',
                            style: TextStyle(
                                color: _P.textHi,
                                fontSize: 28,
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
                              blurRadius: 40,
                              offset: const Offset(0, 20)),
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
                                border:
                                    Border.all(color: _P.red.withOpacity(0.3)),
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
                            style:
                                const TextStyle(color: _P.textHi, fontSize: 14),
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: const TextStyle(
                                  color: _P.textLo, fontSize: 14),
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 18, color: _P.textMid),
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: _P.textMid),
                              ),
                              filled: true,
                              fillColor: _P.card,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: _P.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: _P.border)),
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
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Iniciar sesión',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                            ),
                          ),
                          SizedBox(height: 20),

                          GestureDetector(
                            onTap: () {
                              context.go('/login');
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E2D47),
                                    Color(0xFF172035)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: _T.r12,
                                border: Border.all(
                                    color: _T.primary.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: _T.primary.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 10),
                                  Text(
                                    'Volver',
                                    style: TextStyle(
                                      color: _T.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
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
  final DeviceUser? device;
  const DeviceDashboardScreen({super.key, required this.device});

  @override
  State<DeviceDashboardScreen> createState() => _DeviceDashboardScreenState();
}

class _DeviceDashboardScreenState extends State<DeviceDashboardScreen>
    with TickerProviderStateMixin {
  String? _selectedScheduleId;
  bool _showSchedules = false;
  _PlaylistData? _selectedPlaylist;
  bool _fullscreen = false;
  late AnimationController _sidebarCtrl;
  DeviceUser? _device;
  Timer? _heartbeatTimer;
  @override
  void initState() {
    super.initState();
    _sidebarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _sidebarCtrl.forward();

    _device = widget.device ?? _sessionFromStorage();

    if (_device == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/portal');
      });
      return;
    }

    _loadCurrentPlaylist();

    if (_device != null) {
      // Marcar online al entrar
      FirebaseFirestore.instance
          .collection('devices')
          .doc(_device!.deviceId)
          .update({
        'lastSeen': FieldValue.serverTimestamp(),
        'status': 'online',
      }).catchError((_) {});

      // Heartbeat cada 90 segundos
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 90), (_) {
        if (!mounted) return;
        FirebaseFirestore.instance
            .collection('devices')
            .doc(_device!.deviceId)
            .update({
          'lastSeen': FieldValue.serverTimestamp(),
          'status': 'online',
        }).catchError((_) {});
      });

      // Detectar cierre de pestaña/ventana en web
      html.window.onBeforeUnload.listen((_) {
        FirebaseFirestore.instance
            .collection('devices')
            .doc(_device!.deviceId)
            .update({'status': 'offline'}).catchError((_) {});
      });
    }
  }

  DeviceUser? _sessionFromStorage() {
    try {
      final raw = html.window.localStorage['portal_session'];
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DeviceUser(
        deviceId: map['deviceId'] ?? '',
        deviceName: map['deviceName'] ?? '',
        username: map['username'] ?? '',
        password: map['password'] ?? '',
        displayToken: map['displayToken'] ?? '',
        currentPlaylistId: map['currentPlaylistId'],
        currentPlaylistName: map['currentPlaylistName'],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sidebarCtrl.dispose();
    _heartbeatTimer?.cancel();

    // Marcar offline al destruir el widget
    if (_device != null) {
      FirebaseFirestore.instance
          .collection('devices')
          .doc(_device!.deviceId)
          .update({'status': 'offline'}).catchError((_) {});
    }

    super.dispose();
  }

  Future<void> _loadCurrentPlaylist() async {
    if (_device?.currentPlaylistId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(_device!.currentPlaylistId)
          .get();
      if (doc.exists && mounted) {
        final d = doc.data() as Map<String, dynamic>;
        final rawItems = (d['items'] as List<dynamic>?) ?? [];
        final items = rawItems
            .map((i) => _PlaylistItem.fromMap(i as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        setState(() => _selectedPlaylist = _PlaylistData(
              id: doc.id,
              name: d['name'] ?? 'Playlist',
              description: d['description'],
              items: items,
              isActive: d['isActive'] ?? true,
              displayToken: d['displayToken'] ?? '',
            ));
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('playlists')
          .where('displayToken', isEqualTo: _device!.currentPlaylistId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() =>
            _selectedPlaylist = _PlaylistData.fromFirestore(snap.docs.first));
      }
    } catch (e) {
      debugPrint('Error loading playlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_device == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF060A14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Fullscreen para programación
    if (_fullscreen && _selectedScheduleId != null) {
      return _ScheduleFullscreenViewer(
        scheduleId: _selectedScheduleId!,
        onExit: () => setState(() => _fullscreen = false),
      );
    }

    // Fullscreen para playlist
    if (_fullscreen && _selectedPlaylist != null) {
      return _FullscreenViewer(
        playlist: _selectedPlaylist!,
        deviceId: _device!.deviceId,
        onExit: () => setState(() => _fullscreen = false),
      );
    }

    return Scaffold(
      backgroundColor: _P.bg,
      body: Row(
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: _sidebarCtrl, curve: Curves.easeOutCubic)),
            child: _Sidebar(
              device: _device!,
              showSchedules: _showSchedules,
              onToggleSchedules: () => setState(() {
                _showSchedules = !_showSchedules;
                // Al volver a playlists, limpiar schedule seleccionado
                if (!_showSchedules) _selectedScheduleId = null;
              }),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _DashboardTopBar(
                  device: _device!,
                  selectedPlaylist: _selectedPlaylist,
                  onFullscreen:
                      (_selectedPlaylist != null || _selectedScheduleId != null)
                          ? () => setState(() => _fullscreen = true)
                          : null,
                  onLogout: () {
                    html.window.localStorage.remove('portal_session');
                    context.go('/portal');
                  },
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _showSchedules
                            ? _SchedulesListPanel(
                                deviceId: _device!.deviceId,
                                onScheduleSelected: (scheduleId) {
                                  setState(() {
                                    _selectedScheduleId = scheduleId;
                                    _selectedPlaylist = null;
                                  });
                                },
                              )
                            : _PlaylistsPanel(
                                deviceId: _device!.deviceId,
                                selectedId: _selectedPlaylist?.id,
                                onSelect: (pl) => setState(() {
                                  _selectedPlaylist = pl;
                                  _selectedScheduleId = null;
                                }),
                              ),
                      ),
                      Container(width: 1, color: _P.border.withOpacity(0.5)),
                      Expanded(
                        child: _selectedScheduleId != null
                            ? _ScheduleAutoPlayer(
                                scheduleId: _selectedScheduleId!,
                                onFullscreen: () =>
                                    setState(() => _fullscreen = true),
                              )
                            : _selectedPlaylist == null
                                ? _EmptyPreview()
                                : _PreviewPanel(
                                    playlist: _selectedPlaylist!,
                                    deviceId: _device!.deviceId,
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

void _openSchedulesDialog(BuildContext context, DeviceUser device) {
  showDialog(
    context: context,
    builder: (_) => _DeviceSchedulesDialog(device: device),
  );
}

// =============================================================================
// SIDEBAR
// =============================================================================
class _Sidebar extends StatelessWidget {
  final DeviceUser device;
  final bool showSchedules;
  final VoidCallback onToggleSchedules;
  const _Sidebar({
    required this.device,
    required this.showSchedules,
    required this.onToggleSchedules,
  });

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
          Container(
            width: 44,
            height: 44,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
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
            onTap: null,
          ),
          const SizedBox(height: 8),
          _SidebarBtn(
            icon: showSchedules
                ? Icons.playlist_play_rounded
                : Icons.calendar_view_week_rounded,
            label: showSchedules ? 'Playlists' : 'Programación',
            selected: showSchedules,
            color: _P.purple,
            onTap: onToggleSchedules,
          ),
          const SizedBox(height: 8),
          /* _SidebarBtn(
  icon: Icons.tv_rounded,
  label: 'Ver display',
  selected: false,
  color: _P.accent,
  onTap: () => _launchDisplay(context, device),
),*/

          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _P.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _P.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                  device.deviceName.isNotEmpty
                      ? device.deviceName[0].toUpperCase()
                      : 'D',
                  style: const TextStyle(
                      color: _P.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _launchDisplay(BuildContext context, DeviceUser device) {
    // Usa el displayToken guardado en el device doc de Firestore
    // El token está en device.displayToken (campo 'displayToken' del doc)
    final token = device.displayToken;
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este dispositivo no tiene display configurado'),
          backgroundColor: Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.go('/display/$token');
  }
}

class _SidebarBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  const _SidebarBtn(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.color,
      this.onTap});

  @override
  State<_SidebarBtn> createState() => _SidebarBtnState();
}

class _SidebarBtnState extends State<_SidebarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          child: AnimatedContainer(
            duration: 150.ms,
            width: 44,
            height: 44,
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
            child: Icon(widget.icon,
                size: 20, color: widget.selected ? widget.color : _P.textMid),
          ),
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
                      color: _P.textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.3)),
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
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _P.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Conectado',
                  style: TextStyle(
                      color: _P.green,
                      fontSize: 11,
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
  const _TopBarBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 130.ms,
            width: 36,
            height: 36,
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                Row(
                  children: [
                    Container(
                        width: 250,
                        child: AppLogo(height: 200, showBadge: false)),
                  ],
                ),

                const Text('Mis Playlists',
                    style: TextStyle(
                        color: _P.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3)),
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
            child: // En _PlaylistsPanel, reemplaza el StreamBuilder por este:
                StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('devices')
                  .doc(widget.deviceId)
                  .snapshots(),
              builder: (context, deviceSnap) {
                final deviceData =
                    deviceSnap.data?.data() as Map<String, dynamic>? ?? {};
                final assignedIds =
                    List<String>.from(deviceData['assignedPlaylistIds'] ?? []);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('playlists')
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

                    // Filtrar solo las asignadas (si hay asignadas)
                    if (assignedIds.isNotEmpty) {
                      playlists = playlists
                          .where((p) => assignedIds.contains(p.id))
                          .toList();
                    }

                    if (_search.isNotEmpty) {
                      playlists = playlists
                          .where((p) => p.name
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
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
                            Text(
                                assignedIds.isEmpty
                                    ? 'Sin playlists asignadas'
                                    : 'Sin playlists disponibles',
                                style: const TextStyle(
                                    color: _P.textLo, fontSize: 13)),
                            if (assignedIds.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                    'Pide al administrador que asigne playlists',
                                    style: TextStyle(
                                        color: _P.textLo, fontSize: 11),
                                    textAlign: TextAlign.center),
                              ),
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
                      ),
                    );
                  },
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
  const _PlaylistTile(
      {required this.playlist,
      required this.isSelected,
      required this.index,
      required this.onTap});

  @override
  State<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<_PlaylistTile> {
  bool _hovered = false;

  Color _typeColor(String type) {
    switch (type) {
      case 'image':
        return _P.accent;
      case 'video':
        return _P.purple;
      case 'text':
        return _P.green;
      default:
        return _P.amber;
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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _P.primary.withOpacity(0.12)
                : _hovered
                    ? _P.card
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? _P.primary.withOpacity(0.4)
                  : _hovered
                      ? _P.border
                      : Colors.transparent,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: 150.ms,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? const LinearGradient(
                          colors: [_P.primary, Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                  color:
                      widget.isSelected ? null : _P.primary.withOpacity(0.08),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: widget.isSelected ? _P.textHi : _P.textMid,
                            fontWeight: widget.isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text('${pl.items.length} elementos',
                          style:
                              const TextStyle(color: _P.textLo, fontSize: 11)),
                      const SizedBox(width: 8),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                              color: _P.textLo, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(durStr,
                          style:
                              const TextStyle(color: _P.textLo, fontSize: 11)),
                    ]),
                  ],
                ),
              ),

              // Type indicators
              if (pl.items.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(
                  spacing: 3,
                  children: ({...pl.items.map((i) => i.type)})
                      .map((t) => Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: _typeColor(t), shape: BoxShape.circle),
                          ))
                      .toList(),
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
  double _playhead = 0;
  Timer? _playTimer;
  bool _playing = true;
  SavedPlaylist? _saved;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  double get _total {
    if (widget.playlist.items.isEmpty) return 10;
    return widget.playlist.items.fold(0.0, (s, i) => s + i.durationSeconds) + 1;
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _loadSaved();
  }

  @override
  void didUpdateWidget(_PreviewPanel old) {
    super.didUpdateWidget(old);
    if (old.playlist.id != widget.playlist.id) {
      setState(() {
        _playhead = 0;
        _saved = null;
      });
      _fadeCtrl.forward(from: 0);
      _loadSaved();
    }
  }

  Future<void> _loadSaved() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.playlist.id)
          .get();
      if (!doc.exists) {
        _fallbackSaved();
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['clips'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          [];
      if (raw.isEmpty) {
        _fallbackSaved();
        return;
      }
      final clips = raw
          .map((i) => EditorClip.fromMap(i as Map<String, dynamic>))
          .toList();
      if (mounted)
        setState(() => _saved = SavedPlaylist(
            id: widget.playlist.id,
            name: widget.playlist.name,
            clips: clips,
            createdAt: DateTime.now(),
            viewLink: ''));
    } catch (_) {
      _fallbackSaved();
    }
  }

  void _fallbackSaved() {
    double acc = 0;
    final clips = <EditorClip>[];
    for (final item in widget.playlist.items) {
      EditorLayerType type;
      switch (item.type) {
        case 'image':
          type = EditorLayerType.image;
          break;
        case 'video':
          type = EditorLayerType.video;
          break;
        case 'audio':
          type = EditorLayerType.audio;
          break;
        default:
          type = EditorLayerType.text;
      }
      final start = acc;
      acc += item.durationSeconds;
      clips.add(EditorClip(
        id: item.id.isEmpty ? const Uuid().v4() : item.id,
        type: type,
        label: item.title,
        url: item.url,
        text: item.textContent ?? item.title,
        startSec: start,
        durationSec: item.durationSeconds.toDouble(),
        trackIndex: 0,
        x: 640,
        y: 360,
        width: 1280,
        height: 720,
        textColor: Colors.white,
        fontSize: 48,
        bold: false,
      ));
    }
    if (mounted)
      setState(() => _saved = SavedPlaylist(
          id: widget.playlist.id,
          name: widget.playlist.name,
          clips: clips,
          createdAt: DateTime.now(),
          viewLink: ''));
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (_playhead >= _total) {
        setState(() => _playhead = 0);
      } else {
        setState(() => _playhead += 0.05);
      }
    });
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _startTimer();
      // Enviar play a todos los iframes
      try {
        final iframes = html.document.querySelectorAll('iframe');
        for (final el in iframes) {
          (el as html.IFrameElement).contentWindow?.postMessage('play', '*');
        }
      } catch (_) {}
    } else {
      _playTimer?.cancel();
      // Enviar pause a todos los iframes
      try {
        final iframes = html.document.querySelectorAll('iframe');
        for (final el in iframes) {
          (el as html.IFrameElement).contentWindow?.postMessage('pause', '*');
        }
      } catch (_) {}
    }
  }

  Future<void> _assignToDevice() async {
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({
        'currentPlaylistId': widget.playlist.id,
        'currentPlaylistName': widget.playlist.name,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ "${widget.playlist.name}" asignada al dispositivo'),
            backgroundColor: _P.green.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  List<Map<String, dynamic>> _itemsWithTime() {
    double acc = 0;
    return widget.playlist.items.map((item) {
      final start = acc;
      acc += item.durationSeconds;
      return {'item': item, 'start': start, 'end': acc};
    }).toList();
  }

  List<_PlaylistItem> _activeItems() {
    final timed = _itemsWithTime();
    final active = timed
        .where((t) => _playhead >= t['start'] && _playhead < t['end'])
        .map((t) => t['item'] as _PlaylistItem)
        .toList();
    if (active.isEmpty && widget.playlist.items.isNotEmpty) {
      return [widget.playlist.items.first];
    }
    return active;
  }

  int get _currentIndex {
    final timed = _itemsWithTime();
    for (int i = 0; i < timed.length; i++) {
      if (_playhead >= timed[i]['start'] && _playhead < timed[i]['end']) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    if (pl.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove_rounded, color: _P.textLo, size: 48),
            const SizedBox(height: 12),
            const Text('Playlist vacía',
                style: TextStyle(color: _P.textMid, fontSize: 16)),
          ],
        ),
      );
    }

    final totalDur = pl.items.fold(0, (s, i) => s + i.durationSeconds);
    final safeIdx = _currentIndex.clamp(0, pl.items.length - 1);
    final activeItems = _activeItems();

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Preview header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pl.name,
                        style: const TextStyle(
                            color: _P.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(
                        '${pl.items.length} elementos · ${totalDur ~/ 60}m ${totalDur % 60}s',
                        style:
                            const TextStyle(color: _P.textMid, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                /* _ActionButton(
                  icon: Icons.tv_rounded,
                  label: 'Asignar a mi pantalla1',
                  color: _P.green,
                  onTap: (){
                    

                  },
                ),*/
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.fullscreen_rounded,
                  label: 'Pantalla completa',
                  color: _P.accent,
                  onTap: widget.onFullscreen,
                ),
              ],
            ),
          ),

          // ── Canvas 16:9
          // ── Canvas 16:9
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    _PortalPlaylistCanvas(playlist: pl),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: _P.primary,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Icon(
                                    _playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbColor: _P.primary,
                                  activeTrackColor: _P.primary,
                                  inactiveTrackColor: Colors.white24,
                                  overlayShape: SliderComponentShape.noOverlay,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5),
                                ),
                                child: Slider(
                                  value: _playhead.clamp(0, _total),
                                  min: 0,
                                  max: _total,
                                  onChanged: (v) =>
                                      setState(() => _playhead = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_playhead.toStringAsFixed(1)}s / ${_total.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _itemIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'text':
        return Icons.text_fields_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  Color _itemColor(String type) {
    switch (type) {
      case 'image':
        return _P.accent;
      case 'video':
        return _P.purple;
      case 'text':
        return _P.green;
      default:
        return _P.amber;
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
  const _CanvasOverlay(
      {this.onPrev,
      this.onNext,
      required this.onPlayPause,
      required this.isPlaying});

  @override
  State<_CanvasOverlay> createState() => _CanvasOverlayState();
}

class _CanvasOverlayState extends State<_CanvasOverlay> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _visible = true),
      onExit: (_) => setState(() => _visible = false),
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
                  width: 48,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: widget.onPrev != null ? 1.0 : 0.3,
                    duration: 150.ms,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: Icon(
                          widget.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24),
                    ),
                  ),
                ),
              ),

              // Next
              GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  width: 48,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: widget.onNext != null ? 1.0 : 0.3,
                    duration: 150.ms,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
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

class _FullscreenViewerState extends State<_FullscreenViewer> {
  bool _showUI = true;
  Timer? _hideUITimer;
  SavedPlaylist? _saved;

  @override
  void initState() {
    super.initState();
    _loadDirect();
    _scheduleHideUI();
  }

  Future<void> _loadDirect() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.playlist.id)
          .get();
      if (!doc.exists) {
        _fallback();
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['clips'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          [];
      if (raw.isEmpty) {
        _fallback();
        return;
      }
      final clips = raw
          .map((i) => EditorClip.fromMap(i as Map<String, dynamic>))
          .toList();
      if (mounted)
        setState(() => _saved = SavedPlaylist(
            id: widget.playlist.id,
            name: widget.playlist.name,
            clips: clips,
            createdAt: DateTime.now(),
            viewLink: ''));
    } catch (_) {
      _fallback();
    }
  }

  void _fallback() {
    double acc = 0;
    final clips = <EditorClip>[];
    for (final item in widget.playlist.items) {
      EditorLayerType type;
      switch (item.type) {
        case 'image':
          type = EditorLayerType.image;
          break;
        case 'video':
          type = EditorLayerType.video;
          break;
        case 'audio':
          type = EditorLayerType.audio;
          break;
        default:
          type = EditorLayerType.text;
      }
      final start = acc;
      acc += item.durationSeconds;
      clips.add(EditorClip(
        id: item.id.isEmpty ? const Uuid().v4() : item.id,
        type: type,
        label: item.title,
        url: item.url,
        text: item.textContent ?? item.title,
        startSec: start,
        durationSec: item.durationSeconds.toDouble(),
        trackIndex: 0,
        x: 640,
        y: 360,
        width: 1280,
        height: 720,
        textColor: Colors.white,
        fontSize: 48,
        bold: false,
      ));
    }
    if (mounted)
      setState(() => _saved = SavedPlaylist(
          id: widget.playlist.id,
          name: widget.playlist.name,
          clips: clips,
          createdAt: DateTime.now(),
          viewLink: ''));
  }

  @override
  void dispose() {
    _hideUITimer?.cancel();
    super.dispose();
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
    if (_saved == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return MouseRegion(
      onHover: (_) => _scheduleHideUI(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // USA EL MISMO VISUALIZADOR QUE FUNCIONA
            _PlaylistViewerCanvasOnly(playlist: _saved!),

            // UI overlay
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: 400.ms,
              child: Stack(
                children: [
                  // Top gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onExit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24)),
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
                          Text(widget.playlist.name,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
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
            width: 40,
            height: 40,
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
// BORRA la clase _ItemPreview que tienes y reemplázala por esta:
class _ItemPreview extends StatelessWidget {
  final _PlaylistItem item;
  final bool fullscreen;
  const _ItemPreview({required this.item, this.fullscreen = false});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'image':
        return _ImageContent(url: item.url ?? '');
      case 'video':
        return _VideoContent(url: item.url ?? '', title: item.title);
      case 'text':
        return _TextContent(text: item.textContent ?? '', title: item.title);
      default:
        return _UrlContent(url: item.url ?? '', title: item.title);
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
              Text(url,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: _P.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _P.amber.withOpacity(0.4), width: 2)),
              child:
                  const Icon(Icons.language_rounded, color: _P.amber, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(url,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  const _MiniProgressBar(
      {super.key,
      required this.index,
      required this.total,
      required this.durationSec,
      required this.playing});

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
        vsync: this, duration: Duration(seconds: widget.durationSec));
    if (widget.playing) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_MiniProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) _ctrl.forward(from: _ctrl.value);
    if (!widget.playing && old.playing) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: List.generate(
            widget.total,
            (i) => Expanded(
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
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        2))))))
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
            width: 80,
            height: 80,
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
          const Text(
              'Elige una playlist del panel izquierdo\npara previsualizar su contenido',
              style: TextStyle(color: _P.textMid, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
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
          color: _P.textMid, fontSize: 13, fontWeight: FontWeight.w600));
}

class _PortalField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final void Function(String)? onSubmit;
  const _PortalField(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.onSubmit});

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceSchedulesDialog extends StatefulWidget {
  final DeviceUser device;
  const _DeviceSchedulesDialog({required this.device});
  @override
  State<_DeviceSchedulesDialog> createState() => _DeviceSchedulesDialogState();
}

class _DeviceSchedulesDialogState extends State<_DeviceSchedulesDialog> {
  String _selectedDay = _currentDayKey();

  static String _currentDayKey() {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[DateTime.now().weekday - 1];
  }

  static const _dayLabels = {
    'mon': 'Lunes',
    'tue': 'Martes',
    'wed': 'Miércoles',
    'thu': 'Jueves',
    'fri': 'Viernes',
    'sat': 'Sábado',
    'sun': 'Domingo',
  };
  static const _dayShort = {
    'mon': 'L',
    'tue': 'M',
    'wed': 'X',
    'thu': 'J',
    'fri': 'V',
    'sat': 'S',
    'sun': 'D',
  };
  static const _orderedDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _P.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _P.border)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _P.border))),
              child: Row(
                children: [
                  const Icon(Icons.calendar_view_week_rounded,
                      size: 18, color: _P.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.device.deviceName,
                            style: const TextStyle(
                                color: _P.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const Text('Programaciones asignadas',
                            style: TextStyle(color: _P.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: _P.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: _P.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: _P.textMid),
                    ),
                  ),
                ],
              ),
            ),

            // Selector de día
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Día de la semana',
                      style: TextStyle(
                          color: _P.textMid,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: _orderedDays.map((d) {
                      final sel = d == _selectedDay;
                      final isToday = d == _currentDayKey();
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDay = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: sel
                                    ? _P.purple.withOpacity(0.2)
                                    : isToday
                                        ? _P.green.withOpacity(0.08)
                                        : _P.card,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                    color: sel
                                        ? _P.purple.withOpacity(0.6)
                                        : isToday
                                            ? _P.green.withOpacity(0.4)
                                            : _P.border,
                                    width: sel ? 1.5 : 1)),
                            child: Column(
                              children: [
                                Text(_dayShort[d]!,
                                    style: TextStyle(
                                        color: sel
                                            ? _P.purple
                                            : isToday
                                                ? _P.green
                                                : _P.textMid,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                    textAlign: TextAlign.center),
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: sel ? _P.purple : _P.green,
                                        shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Lista de programaciones del dispositivo para el día
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('program_blocks')
                    .where('companyId', isEqualTo: null)
                    .snapshots(),
                builder: (ctx, _) {
                  // Cargamos todos los blocks y filtramos en cliente
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('program_blocks')
                        .snapshots(),
                    builder: (ctx2, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: _P.purple, strokeWidth: 2),
                          ),
                        );
                      }

                      // Filtra bloques que aplican al día seleccionado
                      final allBlocks = snap.data!.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return _ScheduleBlock(
                          id: d.id,
                          name: data['name'] ?? 'Sin nombre',
                          playlistId: data['playlistId'] ?? '',
                          playlistName: data['playlistName'] ?? '—',
                          days: List<String>.from(data['days'] ?? []),
                          startMinute:
                              (data['startMinute'] as num?)?.toInt() ?? 0,
                          durationMinutes:
                              (data['durationMinutes'] as num?)?.toInt() ?? 60,
                          isActive: data['isActive'] ?? true,
                          colorValue: (data['colorValue'] as num?)?.toInt() ??
                              0xFF6366F1,
                        );
                      }).toList();

                      final dayBlocks = allBlocks
                          .where((b) =>
                              b.days.contains(_selectedDay) && b.isActive)
                          .toList()
                        ..sort(
                            (a, b) => a.startMinute.compareTo(b.startMinute));

                      if (dayBlocks.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_rounded,
                                  color: _P.textMid.withOpacity(0.5), size: 40),
                              const SizedBox(height: 12),
                              Text(
                                  'Sin programación el ${_dayLabels[_selectedDay]}',
                                  style: const TextStyle(
                                      color: _P.textMid,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 6),
                              const Text('No hay bloques activos para este día',
                                  style: TextStyle(
                                      color: _P.textMid, fontSize: 12)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: dayBlocks.length,
                        itemBuilder: (_, i) {
                          final b = dayBlocks[i];
                          final color = Color(b.colorValue);
                          final isNow = _isNowInBlock(b);
                          return GestureDetector(
                            onTap: () => _playBlock(context, b),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                  color:
                                      isNow ? color.withOpacity(0.15) : _P.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isNow
                                          ? color.withOpacity(0.6)
                                          : _P.border,
                                      width: isNow ? 1.5 : 1)),
                              child: Row(
                                children: [
                                  Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(2))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(b.name,
                                                style: TextStyle(
                                                    color: isNow
                                                        ? color
                                                        : _P.textHi,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13)),
                                            if (isNow) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color:
                                                        color.withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: Text('EN VIVO',
                                                    style: TextStyle(
                                                        color: color,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                            '${_fmtMin(b.startMinute)} — ${_fmtMin(b.startMinute + b.durationMinutes)}  ·  ${b.playlistName}',
                                            style: const TextStyle(
                                                color: _P.textMid,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: color.withOpacity(0.4))),
                                    child: Icon(Icons.play_arrow_rounded,
                                        size: 16, color: color),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNowInBlock(_ScheduleBlock b) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= b.startMinute &&
        nowMin < b.startMinute + b.durationMinutes;
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  void _playBlock(BuildContext ctx, _ScheduleBlock block) {
    Navigator.pop(ctx);
    showDialog(
      context: ctx,
      builder: (_) => _SchedulePlaybackViewer(
        block: block,
        day: _selectedDay,
        dayLabel: _dayLabels[_selectedDay]!,
      ),
    );
  }
}

class _ScheduleBlock {
  final String id;
  final String name;
  final String playlistId;
  final String playlistName;
  final List<String> days;
  final int startMinute;
  final int durationMinutes;
  final bool isActive;
  final int colorValue;

  const _ScheduleBlock({
    required this.id,
    required this.name,
    required this.playlistId,
    required this.playlistName,
    required this.days,
    required this.startMinute,
    required this.durationMinutes,
    required this.isActive,
    required this.colorValue,
  });
}

class _SchedulePlaybackViewer extends StatefulWidget {
  final _ScheduleBlock block;
  final String day;
  final String dayLabel;
  const _SchedulePlaybackViewer({
    required this.block,
    required this.day,
    required this.dayLabel,
  });
  @override
  State<_SchedulePlaybackViewer> createState() =>
      _SchedulePlaybackViewerState();
}

class _SchedulePlaybackViewerState extends State<_SchedulePlaybackViewer> {
  _PlaylistData? _playlist;
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  Timer? _timer;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.block.playlistId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Playlist no encontrada';
          _loading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final rawItems = (data['items'] as List<dynamic>?) ??
          (data['clips'] as List<dynamic>?) ??
          [];

      final items = rawItems.map((i) {
        final map = i as Map<String, dynamic>;
        return _PlaylistItem(
          id: map['id'] ?? '',
          type: map['type'] ?? 'text',
          title: map['title'] ?? map['label'] ?? '',
          url: map['url'],
          textContent: map['textContent'] ?? map['text'],
          durationSeconds: (() {
            final v = map['durationSeconds'] ?? map['durationSec'] ?? 10;
            return v is int ? v : (v as num).round();
          })(),
          order: map['order'] ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _playlist = _PlaylistData(
          id: doc.id,
          name: data['name'] ?? widget.block.playlistName,
          items: items,
          isActive: true,
          displayToken: '',
        );
        _loading = false;
      });

      if (_playing) _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_playlist == null || _playlist!.items.isEmpty) return;
    final dur = _playlist!
        .items[_currentIndex.clamp(0, _playlist!.items.length - 1)]
        .durationSeconds;
    _timer = Timer(Duration(seconds: dur), () {
      if (!mounted) return;
      _nextSlide();
    });
  }

  void pause() {
    _timer?.cancel();
    _broadcastToIframes('pause');
  }

  void resume() {
    _startTimer();
  }

  void _broadcastToIframes(String msg) {
    try {
      final iframes = html.document.querySelectorAll('iframe');
      for (final el in iframes) {
        final iframe = el as html.IFrameElement;
        iframe.contentWindow?.postMessage(msg, '*');
      }
    } catch (_) {}
  }

  void _nextSlide() {
    final pl = _playlist;
    if (pl == null || pl.items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % pl.items.length;
    });
    if (_playing) _startTimer();
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.block.colorValue);
    return Dialog(
      backgroundColor: _P.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _P.border)),
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _P.border))),
              child: Row(
                children: [
                  Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.block.name,
                            style: const TextStyle(
                                color: _P.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        Text(
                            '${widget.dayLabel}  ·  ${_fmtMin(widget.block.startMinute)} — ${_fmtMin(widget.block.startMinute + widget.block.durationMinutes)}  ·  ${widget.block.playlistName}',
                            style: const TextStyle(
                                color: _P.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: _P.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: _P.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: _P.textMid),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child:
                    CircularProgressIndicator(color: _P.purple, strokeWidth: 2),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(_error!,
                    style: const TextStyle(color: _P.red, fontSize: 13)),
              )
            else if (_playlist == null || _playlist!.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Esta playlist no tiene contenido',
                    style: TextStyle(color: _P.textMid, fontSize: 13)),
              )
            else ...[
              // Canvas 16:9
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        _ItemPreview(
                            item: _playlist!.items[_currentIndex.clamp(
                                0, _playlist!.items.length - 1)]),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _MiniProgressBar(
                            index: _currentIndex.clamp(
                                0, _playlist!.items.length - 1),
                            total: _playlist!.items.length,
                            durationSec: _playlist!
                                .items[_currentIndex.clamp(
                                    0, _playlist!.items.length - 1)]
                                .durationSeconds,
                            playing: _playing,
                            key: ValueKey('spv_$_currentIndex'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: const Icon(Icons.skip_previous_rounded,
                          color: _P.textMid, size: 20),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() => _playing = !_playing);
                        if (_playing)
                          _startTimer();
                        else
                          _timer?.cancel();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '${_currentIndex + 1} / ${_playlist!.items.length}  ·  ${_playlist!.items[_currentIndex.clamp(0, _playlist!.items.length - 1)].title}',
                          style:
                              const TextStyle(color: _P.textMid, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemPreviewComposed extends StatefulWidget {
  final _PlaylistItem item;
  final double sx;
  final double sy;
  const _ItemPreviewComposed({
    super.key,
    required this.item,
    required this.sx,
    required this.sy,
  });

  @override
  State<_ItemPreviewComposed> createState() => _ItemPreviewComposedState();
}

class _ItemPreviewComposedState extends State<_ItemPreviewComposed> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId =
        'composed-${widget.item.id}-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    final item = widget.item;

    if (item.type == 'image' && (item.url ?? '').isNotEmpty) {
      try {
        ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
          final img = html.ImageElement()
            ..src = item.url!
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.display = 'block';
          return img;
        });
      } catch (_) {}
    } else if (item.type == 'video' && (item.url ?? '').isNotEmpty) {
      try {
        ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
          if (item.url!.contains('.m3u8') ||
              item.url!.contains('streaming.rtvc') ||
              item.url!.contains('cdnmedia') ||
              item.url!.contains('logicideas') ||
              item.url!.contains('multistream') ||
              item.url!.contains('mediaserver')) {
            final iframe = html.IFrameElement()
              ..srcdoc = '''
<!DOCTYPE html><html><head>
<style>
  *{margin:0;padding:0;box-sizing:border-box;}
  body{background:#000;width:100vw;height:100vh;overflow:hidden;}
  video{width:100%;height:100%;object-fit:cover;}
</style>
</head><body>
<div id="r" style="width:100%;height:100%;position:relative;"></div>
<script>
const url="${item.url}";
function start(){
  const v=document.createElement('video');
  v.autoplay=true;v.muted=true;v.controls=false;
  v.style.cssText='width:100%;height:100%;object-fit:cover;';
  if(typeof Hls!=='undefined'&&Hls.isSupported()){
    const h=new Hls({enableWorker:false});
    h.loadSource(url);h.attachMedia(v);
    h.on(Hls.Events.MANIFEST_PARSED,()=>{
      v.play();
      document.getElementById('r').innerHTML='';
      document.getElementById('r').appendChild(v);
    });
  } else if(v.canPlayType('application/vnd.apple.mpegurl')){
    v.src=url;
    v.addEventListener('loadedmetadata',()=>{
      v.play();
      document.getElementById('r').innerHTML='';
      document.getElementById('r').appendChild(v);
    });
  }
}
const s=document.createElement('script');
s.src='https://cdn.jsdelivr.net/npm/hls.js@1.5.13/dist/hls.min.js';
s.onload=start;
document.head.appendChild(s);
</script>
</body></html>'''
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..setAttribute('sandbox', 'allow-scripts allow-same-origin');
            return iframe;
          }

          if (item.url!.contains('youtube.com/embed')) {
            final iframe = html.IFrameElement()
              ..src = item.url!
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%'
              ..allowFullscreen = true
              ..setAttribute(
                  'allow',
                  'accelerometer; autoplay; clipboard-write; '
                      'encrypted-media; gyroscope; picture-in-picture');
            return iframe;
          }

          final video = html.VideoElement()
            ..src = item.url!
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..autoplay = true
            ..controls = false
            ..muted = true;
          return video;
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final sx = widget.sx;

    switch (item.type) {
      case 'image':
        if ((item.url ?? '').isNotEmpty) {
          return HtmlElementView(viewType: _viewId);
        }
        return Container(
          color: const Color(0xFF1E3A5F),
          child: Center(
              child: Icon(Icons.image_rounded,
                  color: const Color(0xFF38BDF8), size: 48 * sx)),
        );

      case 'video':
        if ((item.url ?? '').isNotEmpty) {
          return HtmlElementView(viewType: _viewId);
        }
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFA855F7).withOpacity(0.3),
                const Color(0xFFA855F7).withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
              child: Icon(Icons.play_circle_rounded,
                  color: const Color(0xFFA855F7), size: 64 * sx)),
        );

      case 'text':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0F1E), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.title.isNotEmpty) ...[
                Text(item.title,
                    style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontSize: 18 * sx,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5),
                    textAlign: TextAlign.center),
                SizedBox(height: 16 * sx),
              ],
              Text(
                item.textContent ?? item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48 * sx,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );

      default:
        return Container(
          color: Colors.black,
          child: Center(
              child: Text(item.title,
                  style: TextStyle(color: Colors.white54, fontSize: 14 * sx))),
        );
    }
  }
}

// =============================================================================
// CANVAS PORTAL — usa SavedPlaylist + PlaylistViewerDialog internamente
// =============================================================================
class _PortalPlaylistCanvas extends StatefulWidget {
  final _PlaylistData playlist;
  const _PortalPlaylistCanvas({required this.playlist});

  @override
  State<_PortalPlaylistCanvas> createState() => _PortalPlaylistCanvasState();
}

class _PortalPlaylistCanvasState extends State<_PortalPlaylistCanvas> {
  SavedPlaylist? _saved;

  @override
  void initState() {
    super.initState();
    _loadDirect();
  }

  @override
  void didUpdateWidget(_PortalPlaylistCanvas old) {
    super.didUpdateWidget(old);
    if (old.playlist.id != widget.playlist.id) _loadDirect();
  }

  // Lee directamente de Firestore para obtener startSec, durationSec, trackIndex reales
  Future<void> _loadDirect() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.playlist.id)
          .get();

      if (!doc.exists) {
        _fallbackConvert();
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['clips'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          [];

      if (raw.isEmpty) {
        _fallbackConvert();
        return;
      }

      final clips = raw.map((i) {
        final map = i as Map<String, dynamic>;
        return EditorClip.fromMap(map);
      }).toList();

      if (mounted) {
        setState(() {
          _saved = SavedPlaylist(
            id: widget.playlist.id,
            name: widget.playlist.name,
            clips: clips,
            createdAt: DateTime.now(),
            viewLink: '',
          );
        });
      }
    } catch (e) {
      _fallbackConvert();
    }
  }

  // Fallback: convierte secuencialmente si no hay startSec en Firestore
  void _fallbackConvert() {
    double acc = 0;
    final clips = <EditorClip>[];
    for (final item in widget.playlist.items) {
      EditorLayerType type;
      switch (item.type) {
        case 'image':
          type = EditorLayerType.image;
          break;
        case 'video':
          type = EditorLayerType.video;
          break;
        case 'audio':
          type = EditorLayerType.audio;
          break;
        default:
          type = EditorLayerType.text;
      }
      final start = acc;
      acc += item.durationSeconds;
      clips.add(EditorClip(
        id: item.id.isEmpty ? const Uuid().v4() : item.id,
        type: type,
        label: item.title,
        url: item.url,
        text: item.textContent ?? item.title,
        startSec: start,
        durationSec: item.durationSeconds.toDouble(),
        trackIndex: 0,
        x: 640,
        y: 360,
        width: 1280,
        height: 720,
        textColor: Colors.white,
        fontSize: 48,
        bold: false,
      ));
    }
    if (mounted) {
      setState(() {
        _saved = SavedPlaylist(
          id: widget.playlist.id,
          name: widget.playlist.name,
          clips: clips,
          createdAt: DateTime.now(),
          viewLink: '',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saved == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6366F1), strokeWidth: 2)),
      );
    }
    return _PlaylistViewerCanvasOnly(playlist: _saved!);
  }
}

// Este widget ES el canvas de PlaylistViewerDialog — copiado literal, sin dialog, sin controles
class _PlaylistViewerCanvasOnly extends StatefulWidget {
  final SavedPlaylist playlist;
  final double? externalPlayhead; // recibe playhead externo
  final void Function(double)? onProgress; // reporta progreso al padre
  const _PlaylistViewerCanvasOnly({
    required this.playlist,
    this.externalPlayhead,
    this.onProgress,
  });

  @override
  State<_PlaylistViewerCanvasOnly> createState() =>
      _PlaylistViewerCanvasOnlyState();
}

class _PlaylistViewerCanvasOnlyState extends State<_PlaylistViewerCanvasOnly> {
  Timer? _timer;
  double _playhead = 0;

  double get _total => widget.playlist.clips.isEmpty
      ? 30
      : widget.playlist.clips
              .map((c) => c.startSec + c.durationSec)
              .reduce(math.max) +
          2;

  @override
  void initState() {
    super.initState();
    if (widget.externalPlayhead == null) _startTimer();
  }

  @override
  void didUpdateWidget(_PlaylistViewerCanvasOnly old) {
    super.didUpdateWidget(old);
    // Si recibe playhead externo, úsalo
    if (widget.externalPlayhead != null) {
      _playhead = widget.externalPlayhead!;
    }
    if (old.playlist.id != widget.playlist.id) {
      _timer?.cancel();
      setState(() => _playhead = 0);
      if (widget.externalPlayhead == null) _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      double next;
      if (_playhead >= _total) {
        next = 0;
      } else {
        next = _playhead + 0.05;
      }
      setState(() => _playhead = next);
      widget.onProgress?.call(next); // reporta al padre
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final ph = widget.externalPlayhead ?? _playhead;
    final active = widget.playlist.clips
        .where((c) => ph >= c.startSec && ph <= c.startSec + c.durationSec)
        .toList()
      ..sort((a, b) => b.trackIndex.compareTo(a.trackIndex));

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final sx = constraints.maxWidth / 1280;
        final sy = constraints.maxHeight / 720;
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0F1E), Color(0xFF111827)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ...active.map((clip) => Positioned(
                  left: (clip.x - clip.width / 2) * sx,
                  top: (clip.y - clip.height / 2) * sy,
                  width: clip.width * sx,
                  height: clip.height * sy,
                  child: Opacity(
                    opacity: clip.opacity,
                    child: _renderClip(clip, sx, sy),
                  ),
                )),
            if (widget.playlist.clips.isEmpty)
              const Center(
                  child: Text('Sin clips',
                      style:
                          TextStyle(color: Color(0xFF2E3D5C), fontSize: 12))),
          ],
        );
      }),
    );
  }

  Widget _renderClip(EditorClip clip, double sx, double sy) {
    switch (clip.type) {
      case EditorLayerType.image:
        if (clip.url != null &&
            clip.url!.isNotEmpty &&
            !clip.url!.startsWith('file://')) {
          final viewId = 'img-${clip.id}';
          try {
            ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
              final img = html.ImageElement()
                ..src = clip.url!
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'cover'
                ..style.display = 'block';
              return img;
            });
          } catch (_) {}
          return HtmlElementView(viewType: viewId);
        }
        return Container(
            color: const Color(0xFF38BDF8).withOpacity(0.1),
            child: Center(
                child: Icon(Icons.image_rounded,
                    color: const Color(0xFF38BDF8), size: 22 * sx)));

      case EditorLayerType.video:
        if (clip.url != null &&
            clip.url!.isNotEmpty &&
            !clip.url!.startsWith('file://')) {
          final viewId = 'vid-${clip.id}';
          try {
            ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
              final iframe = html.IFrameElement()
                ..style.cssText = 'border:none;width:100%;height:100%;'
                ..setAttribute('allow', 'autoplay')
                ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
                ..srcdoc = '''
<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;overflow:hidden;}
video{width:100%;height:100%;object-fit:cover;}</style>
</head><body>
<video id="v" src="${clip.url}" autoplay muted loop playsinline preload="auto"></video>
<script>
window.addEventListener('message', function(e) {
  var v = document.getElementById('v');
  if (!v) return;
  if (e.data === 'pause') v.pause();
  if (e.data === 'play') v.play();
});
</script>
</body></html>''';
              return iframe;
            });
          } catch (_) {}
          return HtmlElementView(viewType: viewId);
        }
        return Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              const Color(0xFFA855F7).withOpacity(0.3),
              const Color(0xFFA855F7).withOpacity(0.1)
            ])),
            child: Center(
                child: Icon(Icons.play_circle_rounded,
                    color: const Color(0xFFA855F7), size: 36 * sx)));

      case EditorLayerType.audio:
        if (clip.url != null && clip.url!.isNotEmpty) {
          final viewId = 'audio-${clip.id}';
          try {
            ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
              final iframe = html.IFrameElement()
                ..style.cssText = 'border:none;width:100%;height:100%;'
                ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
                ..srcdoc = '''
<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#0a0f1e;width:100vw;height:100vh;
display:flex;flex-direction:column;align-items:center;justify-content:center;
font-family:sans-serif;gap:8px;}
.note{font-size:28px;}audio{width:88%;}
.lbl{color:#7B8DB0;font-size:10px;}</style>
</head><body>
<div class="note">🎵</div>
<audio id="a" src="${clip.url}" autoplay loop preload="auto"></audio>
<div class="lbl">${clip.label}</div>
<script>
window.addEventListener('message', function(e) {
  var a = document.getElementById('a');
  if (!a) return;
  if (e.data === 'pause') a.pause();
  if (e.data === 'play') { a.play(); }
});
</script>
</body></html>''';
              return iframe;
            });
          } catch (_) {}
          return HtmlElementView(viewType: viewId);
        }
        return Container(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            child: Center(
                child: Icon(Icons.music_note_rounded,
                    color: const Color(0xFF22C55E), size: 20 * sx)));

      case EditorLayerType.text:
        final bgColor = clip.backgroundColor != null
            ? Color(int.parse(clip.backgroundColor!.replaceFirst('#', '0xFF')))
            : Colors.transparent;
        return Container(
            color: bgColor,
            alignment: Alignment.center,
            child: Text(clip.text ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: clip.textColor ?? Colors.white,
                    fontSize: (clip.fontSize ?? 48) * sx,
                    fontWeight: (clip.bold ?? false)
                        ? FontWeight.w900
                        : FontWeight.w400,
                    height: 1.2)));

      case EditorLayerType.overlay:
        return Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    width: 2 * sx)),
            child: Center(
                child: Icon(Icons.layers_rounded,
                    color: const Color(0xFFF59E0B), size: 20 * sx)));
    }
  }
}

class _SchedulesListPanel extends StatefulWidget {
  final String deviceId;
  final void Function(String scheduleId) onScheduleSelected;
  const _SchedulesListPanel({
    required this.deviceId,
    required this.onScheduleSelected,
  });

  @override
  State<_SchedulesListPanel> createState() => _SchedulesListPanelState();
}

class _SchedulesListPanelState extends State<_SchedulesListPanel> {
  String? _selectedScheduleId;

  static const _dayShortLabels = {
    'mon': 'L',
    'tue': 'M',
    'wed': 'X',
    'thu': 'J',
    'fri': 'V',
    'sat': 'S',
    'sun': 'D',
  };
  static const _orderedDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  bool _hasBlockNow(List<Map<String, dynamic>> blocks) {
    final now = DateTime.now();
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final today = days[now.weekday - 1];
    final nowMin = now.hour * 60 + now.minute;
    return blocks.any((b) {
      final bDays = List<String>.from(b['days'] ?? []);
      final start = (b['startMinute'] as num?)?.toInt() ?? 0;
      final dur = (b['durationMinutes'] as num?)?.toInt() ?? 0;
      return bDays.contains(today) && nowMin >= start && nowMin < start + dur;
    });
  }

  Future<void> _onSelectSchedule(String scheduleId) async {
    setState(() => _selectedScheduleId = scheduleId);
    widget.onScheduleSelected(scheduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _P.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 250, child: AppLogo(height: 200, showBadge: false)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Programaciones',
                    style: TextStyle(
                        color: _P.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                const Text('Selecciona para ver su playlist activa',
                    style: TextStyle(color: _P.textMid, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1A2540)),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('devices')
                    .doc(widget.deviceId)
                    .snapshots(),
                builder: (context, deviceSnap) {
                  final deviceData =
                      deviceSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final assignedScheduleIds = List<String>.from(
                      deviceData['assignedScheduleIds'] ?? []);

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('schedules')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: _P.purple, strokeWidth: 2));
                      }

                      var schedules = snap.data!.docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['isActive'] ??
                              true)
                          .toList();

                      // Filtrar solo las asignadas al dispositivo
                      if (assignedScheduleIds.isNotEmpty) {
                        schedules = schedules
                            .where((d) => assignedScheduleIds.contains(d.id))
                            .toList();
                      }

                      if (schedules.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_rounded,
                                  color: _P.textLo, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                  assignedScheduleIds.isEmpty
                                      ? 'Sin programaciones asignadas'
                                      : 'Sin programaciones activas',
                                  style: const TextStyle(
                                      color: _P.textLo, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: schedules.length,
                        itemBuilder: (_, i) {
                          final doc = schedules[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final scheduleId = doc.id;
                          final name = data['name'] ?? 'Sin nombre';
                          final description = data['description'] ?? '';
                          final isSelected = scheduleId == _selectedScheduleId;

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('program_blocks')
                                .where('scheduleId', isEqualTo: scheduleId)
                                .snapshots(),
                            builder: (ctx, blockSnap) {
                              final blocks = blockSnap.hasData
                                  ? blockSnap.data!.docs
                                      .map((d) =>
                                          d.data() as Map<String, dynamic>)
                                      .toList()
                                  : <Map<String, dynamic>>[];

                              final blockCount = blocks.length;
                              final isNow = _hasBlockNow(blocks);

                              // Días que tiene bloques
                              final daysWithBlocks = <String>{};
                              for (final b in blocks) {
                                daysWithBlocks
                                    .addAll(List<String>.from(b['days'] ?? []));
                              }

                              return GestureDetector(
                                onTap: () => _onSelectSchedule(scheduleId),
                                child: AnimatedContainer(
                                  duration: 150.ms,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _P.purple.withOpacity(0.12)
                                        : _P.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? _P.purple.withOpacity(0.5)
                                          : _P.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Icono
                                      AnimatedContainer(
                                        duration: 150.ms,
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [
                                                      _P.purple,
                                                      Color(0xFFBF7FFF)
                                                    ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight)
                                              : null,
                                          color: isSelected
                                              ? null
                                              : _P.purple.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                            Icons.calendar_view_week_rounded,
                                            color: isSelected
                                                ? Colors.white
                                                : _P.purple,
                                            size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                child: Text(name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: isSelected
                                                            ? _P.textHi
                                                            : _P.textMid,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        fontSize: 13)),
                                              ),
                                              if (isNow) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: _P.green
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: const Text('EN VIVO',
                                                      style: TextStyle(
                                                          color: _P.green,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w800)),
                                                ),
                                              ],
                                            ]),
                                            const SizedBox(height: 3),
                                            Text('$blockCount bloques',
                                                style: const TextStyle(
                                                    color: _P.textLo,
                                                    fontSize: 11)),
                                            if (daysWithBlocks.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 3,
                                                children: _orderedDays
                                                    .where((d) => daysWithBlocks
                                                        .contains(d))
                                                    .map((d) => Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 5,
                                                                  vertical: 2),
                                                          decoration: BoxDecoration(
                                                              color: _P.purple
                                                                  .withOpacity(
                                                                      0.12),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4)),
                                                          child: Text(
                                                              _dayShortLabels[
                                                                      d] ??
                                                                  d,
                                                              style: const TextStyle(
                                                                  color:
                                                                      _P.purple,
                                                                  fontSize: 9,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700)),
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded,
                                            size: 16, color: _P.purple)
                                      else
                                        const Icon(
                                            Icons.play_circle_outline_rounded,
                                            size: 16,
                                            color: _P.textMid),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: i * 40));
                            },
                          );
                        },
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class _ScheduleAutoPlayer extends StatefulWidget {
  final String scheduleId;
  final VoidCallback onFullscreen;
  const _ScheduleAutoPlayer({
    required this.scheduleId,
    required this.onFullscreen,
  });

  @override
  State<_ScheduleAutoPlayer> createState() => _ScheduleAutoPlayerState();
}

class _ScheduleAutoPlayerState extends State<_ScheduleAutoPlayer>
    with TickerProviderStateMixin {
  List<_ScheduleBlock>? _blocks;
  int _currentBlockIndex = 0;
  _PlaylistData? _currentPlaylist;
  bool _loading = true;
  Timer? _blockTimer;
  bool _playing = true;
  SavedPlaylist? _saved;
  late AnimationController _fadeCtrl;

  // Playhead propio para controlar el canvas
  double _playhead = 0;
  Timer? _playheadTimer;
  double _total = 30;

  final GlobalKey<_PlaylistViewerCanvasOnlyState> _canvasKey =
      GlobalKey<_PlaylistViewerCanvasOnlyState>();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeCtrl.forward();
    _loadSchedule();
  }

  @override
  void didUpdateWidget(_ScheduleAutoPlayer old) {
    super.didUpdateWidget(old);
    if (old.scheduleId != widget.scheduleId) {
      _blockTimer?.cancel();
      _playheadTimer?.cancel();
      setState(() {
        _blocks = null;
        _currentBlockIndex = 0;
        _currentPlaylist = null;
        _saved = null;
        _loading = true;
        _playhead = 0;
      });
      _fadeCtrl.forward(from: 0);
      _loadSchedule();
    }
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    _playheadTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startPlayheadTimer() {
    _playheadTimer?.cancel();
    _playheadTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        if (_playhead >= _total) {
          _playhead = 0;
        } else {
          _playhead += 0.05;
        }
      });
    });
  }

  void _stopPlayheadTimer() {
    _playheadTimer?.cancel();
  }

  Future<void> _loadSchedule() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('program_blocks')
          .where('scheduleId', isEqualTo: widget.scheduleId)
          .get();

      final now = DateTime.now();
      const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      final today = days[now.weekday - 1];
      final nowMin = now.hour * 60 + now.minute;

      final todayBlocks = snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _ScheduleBlock(
              id: d.id,
              name: data['name'] ?? '',
              playlistId: data['playlistId'] ?? '',
              playlistName: data['playlistName'] ?? '',
              days: List<String>.from(data['days'] ?? []),
              startMinute: (data['startMinute'] as num?)?.toInt() ?? 0,
              durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
              isActive: data['isActive'] ?? true,
              colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6366F1,
            );
          })
          .where((b) => b.isActive && b.days.contains(today))
          .toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

      if (todayBlocks.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      int startIndex = 0;
      for (int i = 0; i < todayBlocks.length; i++) {
        if (nowMin >= todayBlocks[i].startMinute &&
            nowMin <
                todayBlocks[i].startMinute + todayBlocks[i].durationMinutes) {
          startIndex = i;
          break;
        }
        if (nowMin < todayBlocks[0].startMinute) {
          startIndex = 0;
          break;
        }
        if (i == todayBlocks.length - 1) startIndex = i;
      }

      if (mounted) {
        setState(() {
          _blocks = todayBlocks;
          _currentBlockIndex = startIndex;
          _loading = false;
        });
      }

      await _loadPlaylistForBlock(startIndex);
      _scheduleNextBlock(startIndex);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPlaylistForBlock(int index) async {
    if (_blocks == null || index >= _blocks!.length) return;
    final block = _blocks![index];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(block.playlistId)
          .get();
      if (!doc.exists || !mounted) return;

      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['clips'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          [];

      if (raw.isNotEmpty) {
        try {
          final clips = raw
              .map((i) => EditorClip.fromMap(i as Map<String, dynamic>))
              .toList();
          final saved = SavedPlaylist(
            id: doc.id,
            name: data['name'] ?? block.playlistName,
            clips: clips,
            createdAt: DateTime.now(),
            viewLink: '',
          );
          // Calcular total del nuevo saved
          final newTotal = clips.isEmpty
              ? 30.0
              : clips.map((c) => c.startSec + c.durationSec).reduce(math.max) +
                  2;
          if (mounted) {
            setState(() {
              _saved = saved;
              _currentPlaylist = _PlaylistData.fromFirestore(doc);
              _playhead = 0;
              _total = newTotal;
            });
            _fadeCtrl.forward(from: 0);
            if (_playing) _startPlayheadTimer();
          }
          return;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _currentPlaylist = _PlaylistData.fromFirestore(doc);
          _saved = null;
          _playhead = 0;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Error loading playlist for block: $e');
    }
  }

  void _scheduleNextBlock(int currentIndex) {
    _blockTimer?.cancel();
    if (_blocks == null || currentIndex >= _blocks!.length) return;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final block = _blocks![currentIndex];
    final blockEndMin = block.startMinute + block.durationMinutes;
    final remainingSeconds = (blockEndMin - nowMin) * 60 - now.second;
    if (remainingSeconds <= 0) {
      _goToNextBlock(currentIndex);
      return;
    }
    _blockTimer =
        Timer(Duration(seconds: remainingSeconds.clamp(1, 86400)), () {
      if (!mounted) return;
      _goToNextBlock(currentIndex);
    });
  }

  void _goToNextBlock(int currentIndex) {
    if (_blocks == null) return;
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _blocks!.length) return;
    setState(() => _currentBlockIndex = nextIndex);
    _loadPlaylistForBlock(nextIndex);
    _scheduleNextBlock(nextIndex);
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _startPlayheadTimer();
      try {
        final iframes = html.document.querySelectorAll('iframe');
        for (final el in iframes) {
          (el as html.IFrameElement).contentWindow?.postMessage('play', '*');
        }
      } catch (_) {}
    } else {
      _stopPlayheadTimer();
      try {
        final iframes = html.document.querySelectorAll('iframe');
        for (final el in iframes) {
          (el as html.IFrameElement).contentWindow?.postMessage('pause', '*');
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _P.purple, strokeWidth: 2));
    }

    if (_blocks == null || _blocks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: _P.purple.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: _P.purple.withOpacity(0.2))),
              child: const Icon(Icons.event_busy_rounded,
                  color: _P.purple, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Sin bloques programados hoy',
                style: TextStyle(
                    color: _P.textHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Esta programación no tiene bloques activos para hoy',
                style: TextStyle(color: _P.textMid, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final block = _blocks![_currentBlockIndex];
    final color = Color(block.colorValue);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(block.name,
                            style: const TextStyle(
                                color: _P.textHi,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.3)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: color.withOpacity(0.4))),
                          child: Text('EN CURSO',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                          '${_fmtMin(block.startMinute)} — ${_fmtMin(block.startMinute + block.durationMinutes)}  ·  ${block.playlistName}',
                          style:
                              const TextStyle(color: _P.textMid, fontSize: 12)),
                    ],
                  ),
                ),
                // Miniaturas bloques
                Row(
                  children: List.generate(_blocks!.length, (i) {
                    final b = _blocks![i];
                    final isCurrent = i == _currentBlockIndex;
                    final bc = Color(b.colorValue);
                    return GestureDetector(
                      onTap: () {
                        _blockTimer?.cancel();
                        _playheadTimer?.cancel();
                        setState(() {
                          _currentBlockIndex = i;
                          _playhead = 0;
                        });
                        _loadPlaylistForBlock(i);
                        _scheduleNextBlock(i);
                      },
                      child: AnimatedContainer(
                        duration: 150.ms,
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                            color: isCurrent ? bc.withOpacity(0.2) : _P.card,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color:
                                    isCurrent ? bc.withOpacity(0.6) : _P.border,
                                width: isCurrent ? 1.5 : 1)),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: isCurrent ? bc : _P.textMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.fullscreen_rounded,
                  label: 'Pantalla completa',
                  color: _P.accent,
                  onTap: widget.onFullscreen,
                ),
              ],
            ),
          ),

          // Canvas 16:9
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _P.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    // Canvas con playhead externo
                    if (_saved != null)
                      _PlaylistViewerCanvasOnly(
                        //  key: _canvasKey,
                        playlist: _saved!,
                        externalPlayhead: _playhead,
                      )
                    else if (_currentPlaylist != null)
                      _PortalPlaylistCanvas(playlist: _currentPlaylist!)
                    else
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: const Color(0xFF0A0F1E),
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: _P.purple, strokeWidth: 2)),
                        ),
                      ),

                    // Barra de controles
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Botón play/pause
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Icon(
                                    _playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Barra de progreso
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbColor: color,
                                  activeTrackColor: color,
                                  inactiveTrackColor: Colors.white24,
                                  overlayShape: SliderComponentShape.noOverlay,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5),
                                ),
                                child: Slider(
                                  value: _playhead.clamp(0, _total),
                                  min: 0,
                                  max: _total,
                                  onChanged: (v) {
                                    setState(() => _playhead = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                                '${_playhead.toStringAsFixed(1)}s / ${_total.toStringAsFixed(1)}s',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Lista de bloques del día
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bloques de hoy',
                    style: TextStyle(
                        color: _P.textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._blocks!.asMap().entries.map((e) {
                  final i = e.key;
                  final b = e.value;
                  final isCurrent = i == _currentBlockIndex;
                  final bc = Color(b.colorValue);
                  return GestureDetector(
                    onTap: () {
                      _blockTimer?.cancel();
                      _playheadTimer?.cancel();
                      setState(() {
                        _currentBlockIndex = i;
                        _playhead = 0;
                      });
                      _loadPlaylistForBlock(i);
                      _scheduleNextBlock(i);
                    },
                    child: AnimatedContainer(
                      duration: 150.ms,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: isCurrent ? bc.withOpacity(0.12) : _P.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  isCurrent ? bc.withOpacity(0.5) : _P.border,
                              width: isCurrent ? 1.5 : 1)),
                      child: Row(
                        children: [
                          Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: bc,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name,
                                    style: TextStyle(
                                        color: isCurrent ? bc : _P.textHi,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                Text(
                                    '${_fmtMin(b.startMinute)} — ${_fmtMin(b.startMinute + b.durationMinutes)}  ·  ${b.playlistName}',
                                    style: const TextStyle(
                                        color: _P.textMid, fontSize: 10)),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                  color: bc.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text('EN CURSO',
                                  style: TextStyle(
                                      color: bc,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }
}

class _ScheduleFullscreenViewer extends StatefulWidget {
  final String scheduleId;
  final VoidCallback onExit;
  const _ScheduleFullscreenViewer({
    required this.scheduleId,
    required this.onExit,
  });

  @override
  State<_ScheduleFullscreenViewer> createState() =>
      _ScheduleFullscreenViewerState();
}

class _ScheduleFullscreenViewerState extends State<_ScheduleFullscreenViewer> {
  List<_ScheduleBlock>? _blocks;
  int _currentBlockIndex = 0;
  SavedPlaylist? _saved;
  bool _loading = true;
  bool _showUI = true;
  Timer? _blockTimer;
  Timer? _hideUITimer;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _scheduleHideUI();
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    _hideUITimer?.cancel();
    super.dispose();
  }

  void _scheduleHideUI() {
    _hideUITimer?.cancel();
    setState(() => _showUI = true);
    _hideUITimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showUI = false);
    });
  }

  Future<void> _loadSchedule() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('program_blocks')
          .where('scheduleId', isEqualTo: widget.scheduleId)
          .get();

      final now = DateTime.now();
      const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      final today = days[now.weekday - 1];
      final nowMin = now.hour * 60 + now.minute;

      final todayBlocks = snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _ScheduleBlock(
              id: d.id,
              name: data['name'] ?? '',
              playlistId: data['playlistId'] ?? '',
              playlistName: data['playlistName'] ?? '',
              days: List<String>.from(data['days'] ?? []),
              startMinute: (data['startMinute'] as num?)?.toInt() ?? 0,
              durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
              isActive: data['isActive'] ?? true,
              colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6366F1,
            );
          })
          .where((b) => b.isActive && b.days.contains(today))
          .toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

      if (todayBlocks.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      int startIndex = 0;
      for (int i = 0; i < todayBlocks.length; i++) {
        if (nowMin >= todayBlocks[i].startMinute &&
            nowMin <
                todayBlocks[i].startMinute + todayBlocks[i].durationMinutes) {
          startIndex = i;
          break;
        }
        if (i == todayBlocks.length - 1) startIndex = i;
      }

      if (mounted) {
        setState(() {
          _blocks = todayBlocks;
          _currentBlockIndex = startIndex;
          _loading = false;
        });
      }

      await _loadPlaylistForBlock(startIndex);
      _scheduleNextBlock(startIndex);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPlaylistForBlock(int index) async {
    if (_blocks == null || index >= _blocks!.length) return;
    final block = _blocks![index];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(block.playlistId)
          .get();
      if (!doc.exists || !mounted) return;
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['clips'] as List<dynamic>?) ??
          (data['items'] as List<dynamic>?) ??
          [];
      if (raw.isNotEmpty) {
        final clips = raw
            .map((i) => EditorClip.fromMap(i as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() => _saved = SavedPlaylist(
                id: doc.id,
                name: data['name'] ?? block.playlistName,
                clips: clips,
                createdAt: DateTime.now(),
                viewLink: '',
              ));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _scheduleNextBlock(int currentIndex) {
    _blockTimer?.cancel();
    if (_blocks == null || currentIndex >= _blocks!.length) return;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final block = _blocks![currentIndex];
    final blockEndMin = block.startMinute + block.durationMinutes;
    final remainingSeconds = (blockEndMin - nowMin) * 60 - now.second;
    if (remainingSeconds <= 0) {
      _goToNextBlock(currentIndex);
      return;
    }
    _blockTimer =
        Timer(Duration(seconds: remainingSeconds.clamp(1, 86400)), () {
      if (!mounted) return;
      _goToNextBlock(currentIndex);
    });
  }

  void _goToNextBlock(int currentIndex) {
    if (_blocks == null) return;
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _blocks!.length) return;
    setState(() => _currentBlockIndex = nextIndex);
    _loadPlaylistForBlock(nextIndex);
    _scheduleNextBlock(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: _P.purple)),
      );
    }

    if (_saved == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: _P.purple)),
      );
    }

    return MouseRegion(
      onHover: (_) => _scheduleHideUI(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _PlaylistViewerCanvasOnly(playlist: _saved!),
            AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: 400.ms,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onExit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24)),
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
                          if (_blocks != null &&
                              _currentBlockIndex < _blocks!.length)
                            Text(_blocks![_currentBlockIndex].playlistName,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                        ],
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
}
