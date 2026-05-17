
import 'dart:async';
import 'dart:math' as math;
// ignore_for_file: use_build_context_synchronously
import 'package:digitaltv/auth/auth.dart' as current2;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

abstract class _C {
  static const bg         = Color(0xFF070B12);
  static const surface    = Color(0xFF0C1018);
  static const card       = Color(0xFF111827);
  static const cardHover  = Color(0xFF151E2F);
  static const border     = Color(0xFF1F2D45);
  static const borderFocus= Color(0xFF6366F1);
  static const primary    = Color(0xFF6366F1);
  static const primaryLo  = Color(0x1A6366F1);
  static const accent     = Color(0xFF38BDF8);
  static const accentLo   = Color(0x1A38BDF8);
  static const green      = Color(0xFF22C55E);
  static const greenLo    = Color(0x1A22C55E);
  static const amber      = Color(0xFFF59E0B);
  static const amberLo    = Color(0x1AF59E0B);
  static const red        = Color(0xFFEF4444);
  static const redLo      = Color(0x1AEF4444);
  static const purple     = Color(0xFFA855F7);
  static const purpleLo   = Color(0x1AA855F7);
  static const textHi     = Color(0xFFF1F5FF);
  static const textMid    = Color(0xFF7B8DB0);
  static const textLo     = Color(0xFF2E3D5C);
  static const divider    = Color(0xFF141E30);
}

// =============================================================================
// MODELOS
// =============================================================================

enum DeviceStatus { online, offline, warning }
enum ContentType  { image, video, text, url }


class DeviceModel {
  final String id;
  final String name;
  final String uniqueDeviceId;
  final DeviceStatus status;
  final String? groupId;
  final String? groupName;
  final String? currentPlaylistId;
  final String? currentPlaylistName;
  final DateTime? lastSeen;
  final Map<String, dynamic> metadata;
  final String displayUrl;
  final String? location;
  final String? resolution;
  final String? orientation;
  final String? notes;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> assignedPlaylistIds;
final List<String> assignedScheduleIds;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.uniqueDeviceId,
    required this.status,
    this.groupId,
    this.groupName,
    this.currentPlaylistId,
    this.currentPlaylistName,
    this.lastSeen,
    this.metadata = const {},
    required this.displayUrl,
    this.location,
    this.resolution,
    this.orientation,
    this.notes,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.assignedPlaylistIds = const [],
this.assignedScheduleIds = const [],
  });
factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;

  DateTime? parseDate(dynamic val) {
    try {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    } catch (e) {
      debugPrint('[DeviceModel] parseDate error: $e — val=$val');
    }
    return null;
  }

  try {
    return DeviceModel(
      id:                    doc.id,
      name:                  d['name'] ?? 'Dispositivo',
      uniqueDeviceId:        d['uniqueDeviceId'] ?? '',
      status:                _parseStatus(d['status']),
      groupId:               d['groupId'],
      groupName:             d['groupName'],
      currentPlaylistId:     d['currentPlaylistId'],
      currentPlaylistName:   d['currentPlaylistName'],
      lastSeen:              parseDate(d['lastSeen']),
      metadata:              (d['metadata'] as Map<String, dynamic>?) ?? {},
      displayUrl:            d['displayUrl'] ?? '',
      location:              d['location'],
      resolution:            d['resolution'],
      orientation:           d['orientation'],
      notes:                 d['notes'],
      tags:                  List<String>.from(d['tags'] ?? []),
      createdAt:             parseDate(d['createdAt']),
      updatedAt:             parseDate(d['updatedAt']),
      assignedPlaylistIds: List<String>.from(d['assignedPlaylistIds'] ?? []),
assignedScheduleIds: List<String>.from(d['assignedScheduleIds'] ?? []),

    );
  } catch (e, stack) {
    debugPrint('[DeviceModel.fromFirestore] ERROR doc=${doc.id}: $e');
    debugPrint('[DeviceModel.fromFirestore] data=$d');
    debugPrint(stack.toString());
    // Retorna modelo mínimo para no romper la lista
    return DeviceModel(
      id:             doc.id,
      name:           d['name'] ?? 'Dispositivo (error)',
      uniqueDeviceId: d['uniqueDeviceId'] ?? '',
      status:         DeviceStatus.offline,
      displayUrl:     d['displayUrl'] ?? '',
    );
  }
}

  static DeviceStatus _parseStatus(String? s) {
    switch (s) {
      case 'online':  return DeviceStatus.online;
      case 'warning': return DeviceStatus.warning;
      default:        return DeviceStatus.offline;
    }
  }

  Map<String, dynamic> toMap() => {
    'name':           name,
    'uniqueDeviceId': uniqueDeviceId,
    'status':         status.name,
    'groupId':        groupId,
    'groupName':      groupName,
    'currentPlaylistId':   currentPlaylistId,
    'currentPlaylistName': currentPlaylistName,
    'lastSeen':       FieldValue.serverTimestamp(),
    'metadata':       metadata,
    'displayUrl':     displayUrl,
    'location':       location,
    'resolution':     resolution,
    'orientation':    orientation,
    'notes':          notes,
    'tags':           tags,
    'assignedPlaylistIds': assignedPlaylistIds,
'assignedScheduleIds': assignedScheduleIds,
  };
}
class PlaylistItemModel {
  final String id;
  final ContentType type;
  final String title;
  final String? url;          // imagen / video / url externa
  final String? textContent;  // para tipo texto
  final int durationSeconds;
  final int order;

  const PlaylistItemModel({
    required this.id,
    required this.type,
    required this.title,
    this.url,
    this.textContent,
    this.durationSeconds = 10,
    required this.order,
  });

  factory PlaylistItemModel.fromMap(Map<String, dynamic> d) => PlaylistItemModel(
    id:              d['id'] ?? const Uuid().v4(),
    type:            ContentType.values.firstWhere(
                       (e) => e.name == d['type'], orElse: () => ContentType.image),
    title:           d['title'] ?? '',
    url:             d['url'],
    textContent:     d['textContent'],
    durationSeconds: d['durationSeconds'] ?? 10,
    order:           d['order'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id':              id,
    'type':            type.name,
    'title':           title,
    'url':             url,
    'textContent':     textContent,
    'durationSeconds': durationSeconds,
    'order':           order,
  };
}

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<PlaylistItemModel> items;
  final DateTime createdAt;
  final String displayToken;   // token único para URL pública
  final bool isActive;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    required this.createdAt,
    required this.displayToken,
    this.isActive = true,
  });
factory PlaylistModel.fromFirestore(DocumentSnapshot doc) {
  DateTime parseDate(dynamic val, DateTime fallback) {
    try {
      if (val == null) return fallback;
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val) ?? fallback;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    } catch (e) {
      debugPrint('[PlaylistModel] parseDate error: $e — val=$val');
    }
    return fallback;
  }

  final d = doc.data() as Map<String, dynamic>;

  try {
    // Lee 'items' (PlaylistModel) o 'clips' (SavedPlaylist del editor) como fallback
    final rawItems = (d['items'] as List<dynamic>?) 
        ?? (d['clips'] as List<dynamic>?) 
        ?? [];

    List<PlaylistItemModel> parsedItems = [];
    for (final i in rawItems) {
      try {
        final map = i as Map<String, dynamic>;
        // SavedPlaylist.clips tienen campos distintos: type, label, url, text, durationSec
        // PlaylistItemModel.items tienen: type, title, url, textContent, durationSeconds
        parsedItems.add(PlaylistItemModel(
          id:              map['id'] ?? const Uuid().v4(),
          type:            ContentType.values.firstWhere(
                             (e) => e.name == (map['type'] ?? 'image'),
                             orElse: () => ContentType.image),
          title:           map['title'] ?? map['label'] ?? '',
          url:             map['url'],
          textContent:     map['textContent'] ?? map['text'],
          durationSeconds: (map['durationSeconds'] ?? map['durationSec'] ?? 10) is int
                             ? (map['durationSeconds'] ?? map['durationSec'] ?? 10)
                             : (map['durationSeconds'] ?? map['durationSec'] ?? 10.0).round(),
          order:           map['order'] ?? 0,
        ));
      } catch (e) {
        debugPrint('[PlaylistModel] error parsing item: $e');
      }
    }

    parsedItems.sort((a, b) => a.order.compareTo(b.order));

    return PlaylistModel(
      id:           doc.id,
      name:         d['name'] ?? 'Playlist',
      description:  d['description'],
      items:        parsedItems,
      createdAt:    parseDate(d['createdAt'], DateTime.now()),
      displayToken: d['displayToken'] ?? '',
      isActive:     d['isActive'] ?? true,
    );
  } catch (e, stack) {
    debugPrint('[PlaylistModel.fromFirestore] ERROR doc=${doc.id}: $e');
    debugPrint('[PlaylistModel.fromFirestore] data=$d');
    debugPrint(stack.toString());
    return PlaylistModel(
      id:           doc.id,
      name:         d['name'] ?? 'Playlist (error)',
      items:        [],
      createdAt:    DateTime.now(),
      displayToken: d['displayToken'] ?? '',
    );
  }
}

  Map<String, dynamic> toMap() => {
    'name':         name,
    'description':  description,
    'items':        items.map((i) => i.toMap()).toList(),
    'createdAt':    FieldValue.serverTimestamp(),
    'displayToken': displayToken,
    'isActive':     isActive,
  };
}

// =============================================================================
// PROVIDERS (Riverpod)
// =============================================================================

final _db = FirebaseFirestore.instance;
const _uuid = Uuid();

// Devices stream — filtrado por empresa
final devicesStreamProvider = StreamProvider<List<DeviceModel>>((ref) {
  final userAsync = ref.watch(current2.currentUserProvider);
  final user = userAsync.valueOrNull;

  Query query = _db.collection('devices');

  if (user != null && !user.isSuperAdmin && user.companyId != null) {
    query = query.where('companyId', isEqualTo: user.companyId);
  }

  return query.snapshots().map((s) {
    final list = s.docs.map(DeviceModel.fromFirestore).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  });
});

final playlistsStreamProvider = StreamProvider<List<PlaylistModel>>((ref) {
  final user = ref.watch(current2.currentUserProvider).valueOrNull;
  final companyId = user?.isSuperAdmin == true ? null : user?.companyId;

  Stream<QuerySnapshot> stream;

  if (companyId != null) {
    stream = FirebaseFirestore.instance
        .collection('playlists')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance
        .collection('playlists')
        .snapshots();
  }

  return stream.map((snap) {
    final list = snap.docs.map((doc) => PlaylistModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});
// Playlist por token (para el display viewer)
// Playlist por displayToken de playlist
final playlistByTokenProvider =
    StreamProvider.family<PlaylistModel?, String>((ref, token) {
  return _db.collection('playlists')
    .where('displayToken', isEqualTo: token)
  //  .where('isActive', isEqualTo: true)
    .limit(1)
    .snapshots()
    .map((s) => s.docs.isEmpty ? null : PlaylistModel.fromFirestore(s.docs.first));
});
final playlistByDeviceTokenProvider =
    StreamProvider.family<PlaylistModel?, String>((ref, token) {
  return _db
      .collection('devices')
      .where('displayToken', isEqualTo: token)
      .limit(1)
      .snapshots()
      .asyncMap((deviceSnap) async {
        if (deviceSnap.docs.isEmpty) {
          debugPrint('[playlistByDeviceToken] No device found for token=$token');
          return null;
        }
        final device = deviceSnap.docs.first.data() as Map<String, dynamic>;
        final playlistId = device['currentPlaylistId'] as String?;
        debugPrint('[playlistByDeviceToken] device found, playlistId=$playlistId');
        if (playlistId == null || playlistId.isEmpty) return null;
        final playlistDoc =
            await _db.collection('playlists').doc(playlistId).get();
        if (!playlistDoc.exists) {
          debugPrint('[playlistByDeviceToken] playlist doc not found id=$playlistId');
          return null;
        }
        final pl = PlaylistModel.fromFirestore(playlistDoc);
        debugPrint('[playlistByDeviceToken] playlist loaded: ${pl.name}, items=${pl.items.length}');
        return pl;
      });
});
// =============================================================================
// DEVICE SERVICE
// =============================================================================

class DeviceService {
  Future<void> updateDeviceStatus(String token, DeviceStatus status) async {
  final snap = await _db.collection('devices')
    .where('displayToken', isEqualTo: token)
    .limit(1)
    .get();
  if (snap.docs.isEmpty) return;
  await snap.docs.first.reference.update({
    'status':   status.name,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}
  Future<void> addDevice({
    required String name,
    String? groupId,
    String? groupName,
    String? location,
    String? resolution,
    String? orientation,
    String? notes,
    List<String> tags = const [],
  }) async {
    final deviceId = _uuid.v4().substring(0, 8).toUpperCase();
    final token    = _uuid.v4().replaceAll('-', '');
    final docRef   = _db.collection('devices').doc();

    await docRef.set({
      ...DeviceModel(
        id:             docRef.id,
        name:           name,
        uniqueDeviceId: deviceId,
        status:         DeviceStatus.offline,
        groupId:        groupId,
        groupName:      groupName,
        displayUrl:     '/display/$token',
        location:       location,
        resolution:     resolution,
        orientation:    orientation,
        notes:          notes,
        tags:           tags,
      ).toMap(),
      'createdAt':    FieldValue.serverTimestamp(),
      'displayToken': token,
    });
  }

  Future<void> assignPlaylist(String deviceId, PlaylistModel playlist) async {
    await _db.collection('devices').doc(deviceId).update({
      'currentPlaylistId':   playlist.id,
      'currentPlaylistName': playlist.name,
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    await _db.collection('devices').doc(deviceId).delete();
  }
Future<void> updateDevice(DeviceModel device) async {
  await _db.collection('devices').doc(device.id).update({
    'name':        device.name,
    'groupId':     device.groupId,
    'groupName':   device.groupName,
    'location':    device.location,
    'resolution':  device.resolution,
    'orientation': device.orientation,
    'notes':       device.notes,
    'tags':        device.tags,
    'updatedAt':   FieldValue.serverTimestamp(),
  });
}
}

// =============================================================================
// PLAYLIST SERVICE
// =============================================================================

class PlaylistService {
Future<PlaylistModel> createPlaylist({
  required String name,
  String? description,
  List<PlaylistItemModel> items = const [],
  String? companyId,
}) async {
  final token  = _uuid.v4().replaceAll('-', '');
  final docRef = _db.collection('playlists').doc();

  // Si no se pasa companyId, lo obtiene del usuario actual
  String? resolvedCompanyId = companyId;
  if (resolvedCompanyId == null) {
    final userDoc = await _db
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    resolvedCompanyId = (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;
  }

  final playlist = PlaylistModel(
    id:           docRef.id,
    name:         name,
    description:  description,
    items:        items,
    createdAt:    DateTime.now(),
    displayToken: token,
  );

  await docRef.set({
    ...playlist.toMap(),
    'companyId': resolvedCompanyId,  // <-- campo clave
  });
  return playlist;
}

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    await _db.collection('playlists').doc(playlist.id).update({
      'name':        playlist.name,
      'description': playlist.description,
      'items':       playlist.items.map((i) => i.toMap()).toList(),
      'isActive':    playlist.isActive,
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.collection('playlists').doc(playlistId).delete();
  }
}

// =============================================================================
// ============================================================== DEVICES SCREEN
// =============================================================================

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _ScreenHeader(
            title: 'Dispositivos1',
            subtitle: 'Gestiona tus pantallas y asigna playlists',
            action: _AddButton(
              label: '+ Agregar dispositivo',
              onTap: () => _showAddDeviceSheet(context),
            ),
          ),

          // ── Filter tabs ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: devicesAsync.when(
              data: (devices) => _FilterTabs(
                selected: _filter,
                tabs: [
                  ('all',     'Todos',      devices.length),
                  ('online',  'En línea',   devices.where((d) => d.status == DeviceStatus.online).length),
                  ('offline', 'Fuera línea',devices.where((d) => d.status == DeviceStatus.offline).length),
                ],
                onChanged: (v) => setState(() => _filter = v),
              ),
              loading: () => const SizedBox(height: 40),
              error:   (_, __) => const SizedBox(height: 40),
            ),
          ),

          // ── Device list ───────────────────────────────────────────────────
          Expanded(
            child: devicesAsync.when(
              loading: () => const _SkeletonList(),
              error:   (e, _) => _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (devices) {
                final filtered = _filter == 'all'
                    ? devices
                    : devices.where((d) => d.status.name == _filter).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    icon: Icons.tv_off_rounded,
                    title: 'No hay dispositivos',
                    subtitle: 'Agrega tu primera pantalla para comenzar.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _DeviceCard(
                    device: filtered[i],
                    index:  i,
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 40))
                              .slideY(begin: 0.05, curve: Curves.easeOut),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context:        context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddDeviceSheet(),
    );
  }
}

// ── Device Card ───────────────────────────────────────────────────────────────
class _EditDeviceSheet extends ConsumerStatefulWidget {
  final DeviceModel device;
  const _EditDeviceSheet({required this.device});

  @override
  ConsumerState<_EditDeviceSheet> createState() => _EditDeviceSheetState();
}

class _EditDeviceSheetState extends ConsumerState<_EditDeviceSheet> {
  final _formKey      = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _tagCtrl;
  late String _resolution;
  late String _orientation;
  late List<String> _tags;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.device.name);
    _groupCtrl    = TextEditingController(text: widget.device.groupName ?? '');
    _locationCtrl = TextEditingController(text: widget.device.location ?? '');
    _notesCtrl    = TextEditingController(text: widget.device.notes ?? '');
    _tagCtrl      = TextEditingController();
    _resolution   = widget.device.resolution ?? '1920x1080';
    _orientation  = widget.device.orientation ?? 'landscape';
    _tags         = List.from(widget.device.tags);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _groupCtrl.dispose(); _locationCtrl.dispose();
    _notesCtrl.dispose(); _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() { _tags.add(t); _tagCtrl.clear(); });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final updated = DeviceModel(
        id:             widget.device.id,
        name:           _nameCtrl.text.trim(),
        uniqueDeviceId: widget.device.uniqueDeviceId,
        status:         widget.device.status,
        groupId:        _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        groupName:      _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        displayUrl:     widget.device.displayUrl,
        currentPlaylistId:   widget.device.currentPlaylistId,
        currentPlaylistName: widget.device.currentPlaylistName,
        location:    _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        resolution:  _resolution,
        orientation: _orientation,
        notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        tags:        _tags,
        createdAt:   widget.device.createdAt,
      );
      await DeviceService().updateDevice(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Editar dispositivo',
      subtitle: 'ID: ${widget.device.uniqueDeviceId}',
      icon: Icons.edit_outlined,
      iconColor: _C.primary,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) _ErrorBanner(message: _error!),

            // ── Fechas ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _DateInfoBox(
                    label: 'Creado',
                    value: _formatDate(widget.device.createdAt),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateInfoBox(
                    label: 'Actualizado',
                    value: _formatDate(widget.device.updatedAt),
                    icon: Icons.update_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Info básica ───────────────────────────────────────────────
            _SectionTitle('Información básica'),
            _SheetLabel('Nombre *'),
            _SheetField(
              controller: _nameCtrl,
              hint: 'Nombre del dispositivo',
              icon: Icons.label_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 14),
            _SheetLabel('Grupo'),
            _SheetField(
              controller: _groupCtrl,
              hint: 'Ej: Lobby, Piso 2',
              icon: Icons.group_work_outlined,
            ),
            const SizedBox(height: 14),
            _SheetLabel('Ubicación'),
            _SheetField(
              controller: _locationCtrl,
              hint: 'Ej: Entrada principal',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),
            _SectionTitle('Configuración técnica'),
            _SheetLabel('Resolución'),
            _DropdownField<String>(
              value: _resolution,
              items: const ['1920x1080','3840x2160','1280x720','1024x768','1366x768'],
              icon: Icons.monitor_rounded,
              onChanged: (v) => setState(() => _resolution = v!),
            ),
            const SizedBox(height: 14),
            _SheetLabel('Orientación'),
            Row(
              children: [
                _OrientationChip(
                  label: 'Horizontal',
                  icon: Icons.stay_current_landscape_rounded,
                  selected: _orientation == 'landscape',
                  onTap: () => setState(() => _orientation = 'landscape'),
                ),
                const SizedBox(width: 10),
                _OrientationChip(
                  label: 'Vertical',
                  icon: Icons.stay_current_portrait_rounded,
                  selected: _orientation == 'portrait',
                  onTap: () => setState(() => _orientation = 'portrait'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _SectionTitle('Etiquetas'),
            Row(
              children: [
                Expanded(
                  child: _SheetField(
                    controller: _tagCtrl,
                    hint: 'Nueva etiqueta',
                    icon: Icons.tag_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    height: 44, width: 44,
                    decoration: BoxDecoration(
                      color: _C.primaryLo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add_rounded, color: _C.primary, size: 20),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.primaryLo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tag, style: const TextStyle(color: _C.primary, fontSize: 11)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(Icons.close_rounded, size: 12, color: _C.primary),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: 20),
            _SectionTitle('Notas'),
            _SheetField(
              controller: _notesCtrl,
              hint: 'Observaciones...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _SheetSubmitButton(
              label: 'Guardar cambios',
              loading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DateInfoBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _C.textMid),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(color: _C.textLo, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                  style: const TextStyle(color: _C.textMid, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _DeviceCard extends ConsumerStatefulWidget {
  final DeviceModel device;
  final int index;
  const _DeviceCard({required this.device, required this.index});

  @override
  ConsumerState<_DeviceCard> createState() => _DeviceCardState();
}

void _showDeviceSchedules(BuildContext ctx, DeviceModel device) {
  showDialog(
    context: ctx,
    builder: (_) => _DeviceSchedulesManagerDialog(device: device),
  );
}

class _DeviceCardState extends ConsumerState<_DeviceCard> {
  void _showCredentials(BuildContext ctx, DeviceModel device) async {
  // Obtener credenciales frescas de Firestore
  final doc = await FirebaseFirestore.instance
      .collection('devices')
      .doc(device.id)
      .get();
  if (!ctx.mounted) return;
  final data = doc.data() as Map<String, dynamic>? ?? {};
  final username = data['portalUsername'] ?? '—';
  final password = data['portalPassword'] ?? '—';

  showDialog(
    context: ctx,
    builder: (_) => _CredentialsDialog(
      deviceName: device.name,
      username: username,
      password: password,
    ),
  );
}
void _showAssignSchedules(BuildContext ctx, DeviceModel device) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssignSchedulesSheet(device: device),
  );
}
  bool _hovered = false;
void _showEditDevice(BuildContext ctx, DeviceModel device) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditDeviceSheet(device: device),
  );
}
  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final statusColor = d.status == DeviceStatus.online  ? _C.green
                      : d.status == DeviceStatus.warning ? _C.amber : _C.textLo;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 180.ms,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _hovered ? _C.cardHover : _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? _C.border.withOpacity(0.8) : _C.border,
          ),
          boxShadow: _hovered ? [
            BoxShadow(
              color: _C.primary.withOpacity(0.06),
              blurRadius: 20, offset: const Offset(0, 4)),
          ] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status dot
              _StatusDot(color: statusColor, animate: d.status == DeviceStatus.online),
              const SizedBox(width: 14),

              // Icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _C.primaryLo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tv_rounded, color: _C.primary, size: 20),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                      style: const TextStyle(
                        color: _C.textHi, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Badge(label: 'ID: ${d.uniqueDeviceId}', color: _C.textLo),
                        if (d.groupName != null) ...[
                          const SizedBox(width: 6),
                          _Badge(label: d.groupName!, color: _C.accent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Playlist info
              if (d.currentPlaylistName != null)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.playlist_play_rounded,
                        size: 14, color: _C.textMid),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(d.currentPlaylistName!,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _C.textMid, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 12),

              // Actions
  // Actions en _DeviceCard - reemplaza el Row de Actions completo:
Row(
  children: [
    _IconBtn(
      icon: Icons.key_rounded,
      tooltip: 'Ver credenciales',
      color: _C.amber,
      onTap: () => _showCredentials(context, d),
    ),
    const SizedBox(width: 8),
    _IconBtn(
      icon: Icons.edit_outlined,
      tooltip: 'Editar',
      color: _C.primary,
      onTap: () => _showEditDevice(context, d),
    ),
    const SizedBox(width: 8),
    _IconBtn(
      icon: Icons.playlist_add_rounded,
      tooltip: 'Asignar playlists',
      color: _C.accent,
      onTap: () => _showAssignPlaylist(context, d),
    ),
    const SizedBox(width: 8),
    _IconBtn(
      icon: Icons.calendar_view_week_rounded,
      tooltip: 'Programaciones',
      color: _C.purple,
      onTap: () => _showAssignSchedules(context, d),
    ),
    const SizedBox(width: 8),
    _IconBtn(
      icon: Icons.delete_outline_rounded,
      tooltip: 'Eliminar',
      color: _C.red,
      onTap: () => _confirmDelete(context, d),
    ),
  ],
),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignPlaylist(BuildContext ctx, DeviceModel device) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignPlaylistSheet(device: device),
    );
  }

void _openDisplay(BuildContext ctx, DeviceModel device) {
  // displayUrl viene como '/display/TOKEN' — extraemos el token
  final parts = device.displayUrl.split('/');
  final token = parts.isNotEmpty ? parts.last : device.displayUrl;
  
  if (token.isEmpty) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      _snack('Este dispositivo no tiene display asignado'));
    return;
  }

  // Navega usando go_router para respetar las rutas
  ctx.go('/display/$token');
}
void _confirmDelete(BuildContext ctx, DeviceModel device) {
  showCupertinoDialog(
    context: ctx,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogCtx) => CupertinoAlertDialog(
      title: const Text('Eliminar dispositivo'),
      content: Text('¿Eliminar "${device.name}"? Esta acción no se puede deshacer.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
          child: const Text('Cancelar'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(dialogCtx, rootNavigator: true).pop();
            await DeviceService().deleteDevice(device.id);
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
}

// =============================================================================
// ADD DEVICE BOTTOM SHEET
// =============================================================================
class _AddDeviceSheet extends ConsumerStatefulWidget {
  const _AddDeviceSheet();

  @override
  ConsumerState<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends ConsumerState<_AddDeviceSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _groupCtrl     = TextEditingController();
  final _locationCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _tagCtrl       = TextEditingController();
  String _resolution   = '1920x1080';
  String _orientation  = 'landscape';
  List<String> _tags   = [];
  bool _loading        = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _groupCtrl.dispose(); _locationCtrl.dispose();
    _notesCtrl.dispose(); _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() { _tags.add(t); _tagCtrl.clear(); });
    }
  }
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _loading = true; _error = null; });
  try {
    final deviceId = _uuid.v4().substring(0, 8).toUpperCase();
    final token    = _uuid.v4().replaceAll('-', '');
    final docRef   = _db.collection('devices').doc();

    // Obtiene el companyId del usuario actual
    final userDoc = await _db
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    final companyId = (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

    final username = _nameCtrl.text.trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '') +
        '_${deviceId.toLowerCase()}';
    final password = _uuid.v4().substring(0, 10);

    await docRef.set({
      'name':           _nameCtrl.text.trim(),
      'uniqueDeviceId': deviceId,
      'status':         'offline',
      'groupId':        _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
      'groupName':      _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
      'displayUrl':     '/display/$token',
      'displayToken':   token,
      'location':       _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'resolution':     _resolution,
      'orientation':    _orientation,
      'notes':          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'tags':           _tags,
      'portalUsername': username,
      'portalPassword': password,
      'companyId':      companyId,   // <-- campo clave
      'createdAt':      FieldValue.serverTimestamp(),
      'lastSeen':       FieldValue.serverTimestamp(),
      'metadata':       {},
    });

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => _CredentialsDialog(
          deviceName: _nameCtrl.text.trim(),
          username: username,
          password: password,
        ),
      );
    }
  } catch (e) {
    setState(() { _error = e.toString(); _loading = false; });
  }
}
  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Agregar dispositivo',
      subtitle: 'Registra una nueva pantalla en el sistema',
      icon: Icons.tv_rounded,
      iconColor: _C.primary,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) _ErrorBanner(message: _error!),

            // ── Información básica ─────────────────────────────────────────
            _SectionTitle('Información básica'),
            _SheetLabel('Nombre del dispositivo *'),
            _SheetField(
              controller: _nameCtrl,
              hint: 'Ej: Pantalla Recepción, TV Sala A',
              icon: Icons.label_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 14),
            _SheetLabel('Grupo'),
            _SheetField(
              controller: _groupCtrl,
              hint: 'Ej: Lobby, Piso 2, Cafetería',
              icon: Icons.group_work_outlined,
            ),
            const SizedBox(height: 14),
            _SheetLabel('Ubicación'),
            _SheetField(
              controller: _locationCtrl,
              hint: 'Ej: Entrada principal, Oficina 301',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),
            // ── Configuración técnica ──────────────────────────────────────
            _SectionTitle('Configuración técnica'),
            _SheetLabel('Resolución'),
            _DropdownField<String>(
              value: _resolution,
              items: const ['1920x1080', '3840x2160', '1280x720', '1024x768', '1366x768'],
              icon: Icons.monitor_rounded,
              onChanged: (v) => setState(() => _resolution = v!),
            ),
            const SizedBox(height: 14),
            _SheetLabel('Orientación'),
            Row(
              children: [
                _OrientationChip(
                  label: 'Horizontal',
                  icon: Icons.stay_current_landscape_rounded,
                  selected: _orientation == 'landscape',
                  onTap: () => setState(() => _orientation = 'landscape'),
                ),
                const SizedBox(width: 10),
                _OrientationChip(
                  label: 'Vertical',
                  icon: Icons.stay_current_portrait_rounded,
                  selected: _orientation == 'portrait',
                  onTap: () => setState(() => _orientation = 'portrait'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // ── Etiquetas ──────────────────────────────────────────────────
            _SectionTitle('Etiquetas'),
            Row(
              children: [
                Expanded(
                  child: _SheetField(
                    controller: _tagCtrl,
                    hint: 'Ej: principal, promocional, entrada',
                    icon: Icons.tag_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    height: 44, width: 44,
                    decoration: BoxDecoration(
                      color: _C.primaryLo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add_rounded, color: _C.primary, size: 20),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.primaryLo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tag, style: const TextStyle(color: _C.primary, fontSize: 11)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(Icons.close_rounded, size: 12, color: _C.primary),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: 20),
            // ── Notas ──────────────────────────────────────────────────────
            _SectionTitle('Notas'),
            _SheetField(
              controller: _notesCtrl,
              hint: 'Observaciones, instrucciones especiales...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.primaryLo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 14, color: _C.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se generará un ID único y URL de visualización automáticamente.',
                      style: TextStyle(color: _C.textMid, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SheetSubmitButton(
              label: 'Crear dispositivo',
              loading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers para el sheet ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(text,
          style: const TextStyle(
            color: _C.textHi, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _C.divider)),
      ],
    ),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _C.textMid),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                dropdownColor: _C.card,
                style: const TextStyle(color: _C.textHi, fontSize: 13),
                icon: const Icon(Icons.expand_more_rounded, color: _C.textMid, size: 18),
                items: items.map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i.toString()),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrientationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _OrientationChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _C.primaryLo : _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _C.primary.withOpacity(0.5) : _C.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? _C.primary : _C.textMid),
              const SizedBox(height: 4),
              Text(label,
                style: TextStyle(
                  color: selected ? _C.primary : _C.textMid,
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ASSIGN PLAYLIST SHEET
// =============================================================================

class _AssignPlaylistSheet extends ConsumerStatefulWidget {
  final DeviceModel device;
  const _AssignPlaylistSheet({required this.device});

  @override
  ConsumerState<_AssignPlaylistSheet> createState() => _AssignPlaylistSheetState();
}

class _AssignPlaylistSheetState extends ConsumerState<_AssignPlaylistSheet> {
  late Set<String> _selected;
  String _search = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.device.assignedPlaylistIds);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.device.id)
        .update({'assignedPlaylistIds': _selected.toList()});
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('✅ Playlists actualizadas en ${widget.device.name}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    return _Sheet(
      title: 'Gestionar playlists',
      subtitle: 'Selecciona las playlists para "${widget.device.name}"',
      icon: Icons.playlist_play_rounded,
      iconColor: _C.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border),
            ),
            child: TextField(
              style: const TextStyle(color: _C.textHi, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Buscar playlist...',
                hintStyle: TextStyle(color: _C.textLo, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: _C.textMid, size: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                filled: false,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 10),
          // Info seleccionadas
          Row(
            children: [
              Text('${_selected.length} seleccionadas',
                style: const TextStyle(color: _C.accent, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selected.clear()),
                child: const Text('Limpiar todo',
                  style: TextStyle(color: _C.red, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          playlistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _C.primary)),
            error: (e, _) => _ErrorBanner(message: e.toString()),
            data: (playlists) {
              final filtered = _search.isEmpty
                  ? playlists
                  : playlists.where((p) => p.name.toLowerCase().contains(_search)).toList();

              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.playlist_remove_rounded,
                  title: 'Sin resultados',
                  subtitle: 'No se encontraron playlists',
                  compact: true,
                );
              }
              return Column(
                children: [
                  ...filtered.map((pl) {
                    final isSelected = _selected.contains(pl.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) _selected.remove(pl.id);
                        else _selected.add(pl.id);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? _C.primaryLo : _C.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _C.primary.withOpacity(0.5) : _C.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: _C.primaryLo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.playlist_play_rounded,
                                  color: _C.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pl.name,
                                    style: TextStyle(
                                      color: isSelected ? _C.textHi : _C.textMid,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 13)),
                                  Text('${pl.items.length} elementos',
                                    style: const TextStyle(color: _C.textLo, fontSize: 11)),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: isSelected ? _C.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? _C.primary : _C.textLo),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _SheetSubmitButton(
                    label: _saving ? '' : 'Guardar (${_selected.length} seleccionadas)',
                    loading: _saving,
                    onTap: _save,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
class _PlaylistSelectTile extends StatefulWidget {
  final PlaylistModel playlist;
  final int itemCount;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlaylistSelectTile({
    required this.playlist,
    required this.itemCount,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_PlaylistSelectTile> createState() => _PlaylistSelectTileState();
}

class _PlaylistSelectTileState extends State<_PlaylistSelectTile> {
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _C.primaryLo
                : _hovered ? _C.cardHover : _C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? _C.primary.withOpacity(0.5)
                  : _C.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _C.primaryLo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.playlist_play_rounded,
                  color: _C.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.playlist.name,
                      style: TextStyle(
                        color: widget.isSelected ? _C.textHi : _C.textMid,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      )),
                    Text(
                      '${widget.itemCount} elemento${widget.itemCount != 1 ? 's' : ''}',
                      style: const TextStyle(color: _C.textLo, fontSize: 11)),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_circle_rounded,
                  size: 18, color: _C.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ============================================================ PLAYLISTS SCREEN
// =============================================================================

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(
            title: 'Playlists1',
            subtitle: 'Crea y edita colecciones de contenido',
            action: _AddButton(
              label: '+ Nueva playlist',
              onTap: () => _showCreatePlaylist(context),
            ),
          ),
          Expanded(
            child: playlistsAsync.when(
              loading: () => const _SkeletonList(),
              error:   (e, _) => _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (playlists) {
                if (playlists.isEmpty) {
                  return _EmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: 'Sin playlists',
                    subtitle: 'Crea tu primera playlist de contenido.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent:     220,
                    crossAxisSpacing:   12,
                    mainAxisSpacing:    12,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (_, i) => _PlaylistCard(
                    playlist: playlists[i],
                    index:    i,
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50))
                              .scale(begin: const Offset(0.97, 0.97),
                                     curve: Curves.easeOut),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePlaylistSheet(),
    );
  }
}

// ── Playlist Card ─────────────────────────────────────────────────────────────

class _PlaylistCard extends ConsumerStatefulWidget {
  final PlaylistModel playlist;
  final int index;
  const _PlaylistCard({required this.playlist, required this.index});

  @override
  ConsumerState<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<_PlaylistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    final totalDuration = pl.items.fold(0, (sum, i) => sum + i.durationSeconds);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 180.ms,
        decoration: BoxDecoration(
          color: _hovered ? _C.cardHover : _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? _C.primary.withOpacity(0.3) : _C.border,
          ),
          boxShadow: _hovered ? [
            BoxShadow(
              color: _C.primary.withOpacity(0.08),
              blurRadius: 24, offset: const Offset(0, 8)),
          ] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.primary, Color(0xFF818CF8)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.playlist_play_rounded,
                      color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  _ActiveBadge(active: pl.isActive),
                ],
              ),
              const Spacer(),
              Text(pl.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.textHi, fontWeight: FontWeight.w700,
                  fontSize: 15, letterSpacing: -0.3,
                )),
              const SizedBox(height: 4),
              Text(
                pl.description?.isNotEmpty == true
                    ? pl.description!
                    : '${pl.items.length} elementos · ${_formatDuration(totalDuration)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _C.textMid, fontSize: 12),
              ),
              const SizedBox(height: 14),
              // Content type indicators
              Row(
                children: [
                  ..._contentTypeSummary(pl.items).entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Badge(label: '${e.value} ${e.key}', color: _C.textMid),
                  )),
                  const Spacer(),
                  // Actions
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    tooltip: 'Editar',
                    color: _C.accent,
                    onTap: () => _openEditor(context, pl),
                  ),
                  const SizedBox(width: 6),
                /* _IconBtn(
  icon: Icons.open_in_new_rounded,
  tooltip: 'Ver display',
  color: _C.green,
  onTap: () => context.go('/display/${pl.displayToken}'),
),*/
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copiar URL',
                    color: _C.primary,
                    onTap: () {
                       final uri = Uri.base;
    final port = uri.port;
    final showPort = port != 0 && port != 80 && port != 443;
    final base = '${uri.scheme}://${uri.host}${showPort ? ':$port' : ''}';
    final url = '$base/display/${pl.displayToken}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      _snack('URL copiada al portapapeles'));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _contentTypeSummary(List<PlaylistItemModel> items) {
    final map = <String, int>{};
    for (final i in items) {
      final key = i.type.name;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  String _formatDuration(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  void _openEditor(BuildContext context, PlaylistModel playlist) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlaylistEditorScreen(playlist: playlist),
    ));
  }
}

// =============================================================================
// CREATE PLAYLIST SHEET
// =============================================================================

class _CreatePlaylistSheet extends ConsumerStatefulWidget {
  const _CreatePlaylistSheet();

  @override
  ConsumerState<_CreatePlaylistSheet> createState() =>
      _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends ConsumerState<_CreatePlaylistSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final pl = await PlaylistService().createPlaylist(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaylistEditorScreen(playlist: pl),
        ));
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Nueva playlist',
      subtitle: 'Crea una colección de contenido para tus pantallas',
      icon: Icons.playlist_add_rounded,
      iconColor: _C.primary,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            _SheetLabel('Nombre de la playlist *'),
            _SheetField(
              controller: _nameCtrl,
              hint: 'Ej: Bienvenida, Promociones, Menú del día',
              icon: Icons.label_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            _SheetLabel('Descripción (opcional)'),
            _SheetField(
              controller: _descCtrl,
              hint: 'Descripción breve del contenido',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _SheetSubmitButton(
              label: 'Crear y editar contenido →',
              loading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ========================================================= PLAYLIST EDITOR SCREEN
// =============================================================================

class PlaylistEditorScreen extends ConsumerStatefulWidget {
  final PlaylistModel playlist;
  const PlaylistEditorScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistEditorScreen> createState() =>
      _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends ConsumerState<PlaylistEditorScreen> {
  late List<PlaylistItemModel> _items;
  late String _name;
  bool _saving = false;
  bool _dirty  = false;
String get _baseUrl {
  // ignore: undefined_prefixed_name
  final uri = Uri.base;
  return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
}
  @override
  void initState() {
    super.initState();
    _items = List.from(widget.playlist.items);
    _name  = widget.playlist.name;
  }

  void _addItem(PlaylistItemModel item) {
    setState(() {
      _items.add(item.copyWith(order: _items.length));
      _dirty = true;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Re-index
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
      _dirty = true;
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = PlaylistModel(
        id:           widget.playlist.id,
        name:         _name,
        description:  widget.playlist.description,
        items:        _items,
        createdAt:    widget.playlist.createdAt,
        displayToken: widget.playlist.displayToken,
        isActive:     widget.playlist.isActive,
      );
      await PlaylistService().updatePlaylist(updated);
      setState(() { _dirty = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Playlist guardada correctamente'));
      }
    } catch (e) {
      setState(() => _saving = false);
    }
  }
void _showEditItem(BuildContext context, int index) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditItemSheet(
      item: _items[index],
      onSave: (updated) {
        setState(() {
          _items[index] = updated.copyWith(order: index);
          _dirty = true;
        });
      },
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final totalDuration = _items.fold(0, (sum, i) => sum + i.durationSeconds);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Row(
        children: [
          // ── Left: Item list ───────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topbar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _C.divider)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                          color: _C.textMid, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_name,
                              style: const TextStyle(
                                color: _C.textHi, fontWeight: FontWeight.w700,
                                fontSize: 15, letterSpacing: -0.3)),
                            Text(
                              '${_items.length} elementos · ${_formatDuration(totalDuration)}',
                              style: const TextStyle(
                                color: _C.textMid, fontSize: 11)),
                          ],
                        ),
                      ),
                      // Display URL copy
                      _IconBtn(
                        icon: Icons.link_rounded,
                        tooltip: 'Copiar URL del display',
                        color: _C.accent,
                        onTap: () {
                          final url = '$_baseUrl/display/${widget.playlist.displayToken}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(_snack('URL copiada: $url'));
                        },
                      ),
                      const SizedBox(width: 8),
                      // Preview
                    _IconBtn(
  icon: Icons.preview_rounded,
  tooltip: 'Previsualizar display',
  color: _C.green,
  onTap: () => context.go('/display/${widget.playlist.displayToken}'),
),
                      const SizedBox(width: 8),
                      // Save
                      AnimatedOpacity(
                        opacity: _dirty ? 1 : 0.4,
                        duration: 200.ms,
                        child: _SaveButton(loading: _saving, onTap: _dirty ? _save : null),
                      ),
                    ],
                  ),
                ),

                // URL Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.accentLo,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 14, color: _C.accent),
                      const SizedBox(width: 8),
                      Expanded(
        child: Text(
          '$_baseUrl/display/${widget.playlist.displayToken}',
          style: const TextStyle(color: _C.accent, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
                      GestureDetector(
                        onTap: () {
                             Clipboard.setData(ClipboardData(
            text: '$_baseUrl/display/${widget.playlist.displayToken}'));
          ScaffoldMessenger.of(context).showSnackBar(_snack('URL copiada'));
                        },
                        child: const Icon(Icons.copy_rounded,
                          size: 14, color: _C.accent),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Item list (reorderable)
   // En _PlaylistEditorScreenState, reemplaza el Expanded del item list:
Expanded(
  child: _items.isEmpty
    ? _EmptyState(
        icon: Icons.add_circle_outline_rounded,
        title: 'Playlist vacía',
        subtitle: 'Agrega contenido desde el panel derecho.',
      )
    : ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final typeColor = item.type == ContentType.image ? _C.accent
                          : item.type == ContentType.video ? _C.purple
                          : item.type == ContentType.text  ? _C.green : _C.amber;
          final typeIcon  = item.type == ContentType.image ? Icons.image_rounded
                          : item.type == ContentType.video ? Icons.videocam_rounded
                          : item.type == ContentType.text  ? Icons.text_fields_rounded
                          : Icons.language_rounded;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: i > 0 ? () => _reorderItems(i, i - 1) : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 4, 2),
                        child: Icon(Icons.arrow_drop_up_rounded,
                          size: 20, color: i > 0 ? _C.textMid : _C.textLo),
                      ),
                    ),
                    GestureDetector(
                      onTap: i < _items.length - 1 ? () => _reorderItems(i, i + 2) : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 2, 4, 8),
                        child: Icon(Icons.arrow_drop_down_rounded,
                          size: 20, color: i < _items.length - 1 ? _C.textMid : _C.textLo),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 24, height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${i + 1}',
                    style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, size: 16, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _C.textHi, fontWeight: FontWeight.w500, fontSize: 13)),
                      Text(
                        item.url?.isNotEmpty == true ? item.url!
                          : item.textContent?.isNotEmpty == true ? item.textContent!
                          : item.type.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _C.textLo, fontSize: 11)),
                    ],
                  ),
                ),
                _Badge(label: '${item.durationSeconds}s', color: _C.textMid),
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.edit_outlined,
                  tooltip: 'Editar',
                  color: _C.accent,
                  size: 16,
                  onTap: () => _showEditItem(context, i),
                ),
                const SizedBox(width: 4),
                _IconBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Quitar',
                  color: _C.red,
                  size: 16,
                  onTap: () => _removeItem(i),
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
),
              ],
            ),
          ),

          // Divider
          Container(width: 1, color: _C.divider),

          // ── Right: Add content panel ──────────────────────────────────────
          SizedBox(
            width: 340,
            child: _AddContentPanel(onAdd: _addItem),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

extension on PlaylistItemModel {
  PlaylistItemModel copyWith({
    String? id, ContentType? type, String? title, String? url,
    String? textContent, int? durationSeconds, int? order,
  }) => PlaylistItemModel(
    id:              id ?? this.id,
    type:            type ?? this.type,
    title:           title ?? this.title,
    url:             url ?? this.url,
    textContent:     textContent ?? this.textContent,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    order:           order ?? this.order,
  );
}

// ── Playlist Item Tile ────────────────────────────────────────────────────────

class _PlaylistItemTile extends StatelessWidget {
  final PlaylistItemModel item;
  final int index;
  final VoidCallback onRemove;
  const _PlaylistItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // clase ya no se usa, se dejó vacía
  }
}

// =============================================================================
// ADD CONTENT PANEL (right side of editor)
// =============================================================================

class _AddContentPanel extends StatefulWidget {
  final void Function(PlaylistItemModel) onAdd;
  const _AddContentPanel({required this.onAdd});

  @override
  State<_AddContentPanel> createState() => _AddContentPanelState();
}

class _AddContentPanelState extends State<_AddContentPanel> {
  ContentType _selectedType = ContentType.image;
  final _titleCtrl    = TextEditingController();
  final _urlCtrl      = TextEditingController();
  final _textCtrl     = TextEditingController();
  int _duration       = 10;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose(); _urlCtrl.dispose(); _textCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El título es obligatorio');
      return;
    }
    if (_selectedType != ContentType.text && _urlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'La URL es obligatoria');
      return;
    }
    if (_selectedType == ContentType.text && _textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El texto es obligatorio');
      return;
    }

    widget.onAdd(PlaylistItemModel(
      id:              _uuid.v4(),
      type:            _selectedType,
      title:           _titleCtrl.text.trim(),
      url:             _selectedType != ContentType.text
                         ? _urlCtrl.text.trim() : null,
      textContent:     _selectedType == ContentType.text
                         ? _textCtrl.text.trim() : null,
      durationSeconds: _duration,
      order:           0,
    ));

    _titleCtrl.clear(); _urlCtrl.clear(); _textCtrl.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar contenido',
              style: TextStyle(
                color: _C.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Configura cada elemento de la playlist',
              style: TextStyle(color: _C.textMid, fontSize: 12)),
            const SizedBox(height: 20),

            // Type selector
            const _SheetLabel('Tipo de contenido'),
            const SizedBox(height: 8),
            _ContentTypeSelector(
              selected: _selectedType,
              onChanged: (t) => setState(() { _selectedType = t; _error = null; }),
            ),
            const SizedBox(height: 16),

            // Title
            _SheetLabel('Título del elemento *'),
            _SheetField(
              controller: _titleCtrl,
              hint: 'Ej: Imagen promocional, Video bienvenida',
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 16),

            // URL / text
            if (_selectedType == ContentType.text) ...[
              _SheetLabel('Contenido de texto *'),
              _SheetField(
                controller: _textCtrl,
                hint: 'Ingresa el texto que se mostrará en pantalla',
                icon: Icons.text_fields_rounded,
                maxLines: 4,
              ),
            ] else ...[
              _SheetLabel(_urlLabel()),
              _SheetField(
                controller: _urlCtrl,
                hint: _urlHint(),
                icon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
            ],
            const SizedBox(height: 16),

            // Duration
            _SheetLabel('Duración: ${_duration}s'),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbColor: _C.primary,
                activeTrackColor: _C.primary,
                inactiveTrackColor: _C.border,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _duration.toDouble(),
                min: 3, max: 120, divisions: 39,
                onChanged: (v) => setState(() => _duration = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('3s',  style: TextStyle(color: _C.textLo, fontSize: 10)),
                Text('120s',style: TextStyle(color: _C.textLo, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 20),

            if (_error != null) _ErrorBanner(message: _error!),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar elemento',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: _C.divider, height: 1),
            const SizedBox(height: 16),

            // Quick add presets
            const Text('Atajos rápidos',
              style: TextStyle(
                color: _C.textMid, fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                _PresetChip(label: '🖼 Imagen URL', onTap: () {
                  setState(() => _selectedType = ContentType.image);
                }),
                _PresetChip(label: '🎬 Video MP4', onTap: () {
                  setState(() => _selectedType = ContentType.video);
                }),
                _PresetChip(label: '📝 Texto', onTap: () {
                  setState(() => _selectedType = ContentType.text);
                }),
                _PresetChip(label: '🌐 Sitio web', onTap: () {
                  setState(() => _selectedType = ContentType.url);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _urlLabel() {
    switch (_selectedType) {
      case ContentType.image: return 'URL de la imagen *';
      case ContentType.video: return 'URL del video (MP4) *';
      case ContentType.url:   return 'URL del sitio web *';
      default:                return 'URL *';
    }
  }

  String _urlHint() {
    switch (_selectedType) {
      case ContentType.image: return 'https://example.com/imagen.jpg';
      case ContentType.video: return 'https://example.com/video.mp4';
      case ContentType.url:   return 'https://tu-sitio.com';
      default:                return 'https://...';
    }
  }
}

class _ContentTypeSelector extends StatelessWidget {
  final ContentType selected;
  final ValueChanged<ContentType> onChanged;
  const _ContentTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ContentType.values.map((t) {
        final isSelected = t == selected;
        final color = _typeColor(t);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: 150.ms,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color.withOpacity(0.5) : _C.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(_typeIcon(t), size: 18,
                    color: isSelected ? color : _C.textMid),
                  const SizedBox(height: 4),
                  Text(t.name[0].toUpperCase() + t.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? color : _C.textMid,
                      fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _typeColor(ContentType t) {
    switch (t) {
      case ContentType.image: return _C.accent;
      case ContentType.video: return _C.purple;
      case ContentType.text:  return _C.green;
      case ContentType.url:   return _C.amber;
    }
  }

  IconData _typeIcon(ContentType t) {
    switch (t) {
      case ContentType.image: return Icons.image_rounded;
      case ContentType.video: return Icons.videocam_rounded;
      case ContentType.text:  return Icons.text_fields_rounded;
      case ContentType.url:   return Icons.language_rounded;
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Text(label,
        style: const TextStyle(color: _C.textMid, fontSize: 11)),
    ),
  );
}

// =============================================================================
// ========================================================= DISPLAY VIEWER SCREEN
// =============================================================================
// Esta pantalla se muestra en la URL: /display/{token}
// Puede usarse en: TV App, navegador web, modo kiosk
// =============================================================================

class DisplayViewerScreen extends ConsumerStatefulWidget {
  final String token;
  const DisplayViewerScreen({super.key, required this.token});

  @override
  ConsumerState<DisplayViewerScreen> createState() =>
      _DisplayViewerScreenState();
}
class _DisplayViewerScreenState extends ConsumerState<DisplayViewerScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  Timer? _heartbeatTimer;  // ← NUEVO
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  PlaylistModel? _lastPlaylist;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ── Heartbeat: marca online cada 30s ──────────────────────────────────
    _setOnline();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _setOnline();
    });
  }

  void _setOnline() {
    DeviceService().updateDeviceStatus(widget.token, DeviceStatus.online);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    // Marca offline al salir
    DeviceService().updateDeviceStatus(widget.token, DeviceStatus.offline);
    _fadeCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startTimer(PlaylistModel pl) {
    _timer?.cancel();
    if (pl.items.isEmpty) return;
    final idx = _currentIndex.clamp(0, pl.items.length - 1);
    final duration = pl.items[idx].durationSeconds;
    _timer = Timer(Duration(seconds: duration), () => _nextSlide(pl));
  }

  Future<void> _nextSlide(PlaylistModel pl) async {
    if (_transitioning || !mounted) return;
    _transitioning = true;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % pl.items.length;
    });
    await _fadeCtrl.forward();
    _transitioning = false;
    _startTimer(pl);
  }
 
@override
Widget build(BuildContext context) {
  // La URL /display/TOKEN siempre corresponde al token del DISPOSITIVO,
  // así que usamos directamente playlistByDeviceTokenProvider.
  // playlistByTokenProvider queda como fallback por si el token es de playlist directa.
  final byDevice   = ref.watch(playlistByDeviceTokenProvider(widget.token));
  final byPlaylist = ref.watch(playlistByTokenProvider(widget.token));

  // Resuelve: primero intenta por dispositivo, luego por playlist directa
  AsyncValue<PlaylistModel?> combined;
  if (byDevice.hasValue && byDevice.value != null) {
    combined = byDevice;
  } else if (byPlaylist.hasValue && byPlaylist.value != null) {
    combined = byPlaylist;
  } else if (byDevice.isLoading || byPlaylist.isLoading) {
    combined = const AsyncValue.loading();
  } else if (byDevice.hasError) {
    combined = byDevice;
  } else {
    // ambos resolvieron pero son null
    combined = const AsyncValue.data(null);
  }

  return Scaffold(
    backgroundColor: Colors.black,
    body: combined.when(
      loading: () => const _DisplayLoading(),
      error: (_, __) => const _DisplayError(message: 'Error al cargar el contenido'),
      data: (playlist) {
        if (playlist == null) {
          return _DisplayError(
            message: 'Display no encontrado\nToken: ${widget.token}',
          );
        }
        if (playlist.items.isEmpty) {
          return const _DisplayError(message: 'No hay contenido en esta playlist');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastPlaylist?.id != playlist.id ||
              _lastPlaylist?.items.length != playlist.items.length) {
            _lastPlaylist = playlist;
            setState(() => _currentIndex = 0);
            _startTimer(playlist);
          } else if (_timer == null || !(_timer?.isActive ?? false)) {
            _lastPlaylist = playlist;
            _startTimer(playlist);
          }
        });

        final safeIndex = _currentIndex.clamp(0, playlist.items.length - 1).toInt();
        final item = playlist.items[safeIndex];

        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: _DisplayContent(item: item),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _DisplayProgressBar(
                index:       safeIndex,
                total:       playlist.items.length,
                durationSec: item.durationSeconds,
                key: ValueKey('progress_$safeIndex'),
              ),
            ),
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: () => context.go('/dashboard'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(playlist.name,
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
}

// ── Display Content ───────────────────────────────────────────────────────────

class _DisplayContent extends StatelessWidget {
  final PlaylistItemModel item;
  const _DisplayContent({required this.item});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case ContentType.image:
        return _DisplayImage(url: item.url ?? '');
      case ContentType.video:
        return _DisplayVideo(url: item.url ?? '');
      case ContentType.text:
        return _DisplayText(text: item.textContent ?? '', title: item.title);
      case ContentType.url:
        return _DisplayWebUrl(url: item.url ?? '', title: item.title);
    }
  }
}
class _DisplayImage extends StatelessWidget {
  final String url;
  const _DisplayImage({required this.url});

  String _buildUrl(String original) {
    // Firebase Storage: convierte a URL de descarga directa via proxy
    if (original.contains('firebasestorage.googleapis.com')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(original)}&output=webp&n=-1';
    }
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(original)}&n=-1';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Image.network(
        _buildUrl(url),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          final percent = progress.expectedTotalBytes != null
              ? (progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes! *
                      100)
                  .toInt()
              : null;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: _C.primary, strokeWidth: 2),
                const SizedBox(height: 12),
                Text(
                  percent != null ? 'Cargando $percent%' : 'Cargando...',
                  style:
                      const TextStyle(color: _C.textMid, fontSize: 12)),
              ],
            ),
          );
        },
        errorBuilder: (_, __, ___) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded,
                  color: _C.red, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar la imagen',
                  style:
                      TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 8),
              Text(url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: _C.textLo, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
class _DisplayVideo extends StatelessWidget {
  final String url;
  const _DisplayVideo({required this.url});

  @override
  Widget build(BuildContext context) {
    // Placeholder — integra video_player package para producción real
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _C.purple.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _C.purple.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                color: _C.purple, size: 40),
            ),
            const SizedBox(height: 16),
            Text(url,
              style: const TextStyle(
                color: Colors.white30, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Integra video_player para reproducción real',
              style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DisplayText extends StatelessWidget {
  final String text;
  final String title;
  const _DisplayText({required this.text, required this.title});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width < 800 ? 28.0 : 48.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F1E), Color(0xFF111827)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty) ...[
                Text(title,
                  style: TextStyle(
                    color: _C.primary,
                    fontSize: fontSize * 0.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              Text(text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayWebUrl extends StatelessWidget {
  final String url;
  final String title;
  const _DisplayWebUrl({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    // En producción: usar webview_flutter o flutter_inappwebview
    return Container(
      color: const Color(0xFF0A0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _C.amberLo,
                shape: BoxShape.circle,
                border: Border.all(color: _C.amber.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.language_rounded,
                color: _C.amber, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title,
              style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(url,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Integra webview_flutter para renderizado web real',
              style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Display Progress Bar ──────────────────────────────────────────────────────

class _DisplayProgressBar extends StatefulWidget {
  final int index;
  final int total;
  final int durationSec;
  const _DisplayProgressBar({
    super.key,
    required this.index,
    required this.total,
    required this.durationSec,
  });

  @override
  State<_DisplayProgressBar> createState() => _DisplayProgressBarState();
}

class _DisplayProgressBarState extends State<_DisplayProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSec),
    )..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: List.generate(widget.total, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: i < widget.index
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : i == widget.index
                  ? AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => FractionallySizedBox(
                        widthFactor: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _ctrl.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }),
      ),
    );
  }
}

// ── Display Loading & Error ───────────────────────────────────────────────────

class _DisplayLoading extends StatefulWidget {
  const _DisplayLoading();

  @override
  State<_DisplayLoading> createState() => _DisplayLoadingState();
}

class _DisplayLoadingState extends State<_DisplayLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1800.ms)
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: 0.3 + _ctrl.value * 0.5,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: _C.primaryLo,
                shape: BoxShape.circle,
                border: Border.all(color: _C.primary.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.tv_rounded, color: _C.primary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisplayError extends StatelessWidget {
  final String message;
  const _DisplayError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
              color: _C.red, size: 48),
            const SizedBox(height: 16),
            Text(message,
              style: const TextStyle(
                color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget action;
  const _ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.divider))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  color: _C.textHi, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(subtitle,
                style: const TextStyle(color: _C.textMid, fontSize: 13)),
            ],
          ),
          const Spacer(),
          action,
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _AddButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF5254F0) : _C.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered ? [
              BoxShadow(
                color: _C.primary.withOpacity(0.3),
                blurRadius: 14, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Text(widget.label,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _SaveButton({required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _C.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Guardar', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 12)),
              ],
            ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final String selected;
  final List<(String, String, int)> tabs;
  final ValueChanged<String> onChanged;
  const _FilterTabs({
    required this.selected,
    required this.tabs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.map((t) {
        final (id, label, count) = t;
        final isSelected = id == selected;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: 150.ms,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? _C.primaryLo : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _C.primary.withOpacity(0.4) : _C.border),
            ),
            child: Row(
              children: [
                Text(label,
                  style: TextStyle(
                    color: isSelected ? _C.primary : _C.textMid,
                    fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? _C.primary.withOpacity(0.2) : _C.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                    style: TextStyle(
                      color: isSelected ? _C.primary : _C.textLo,
                      fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _StatusDot({required this.color, required this.animate});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_pulse.value * 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _C.greenLo : _C.redLo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? _C.green.withOpacity(0.3) : _C.red.withOpacity(0.3)),
      ),
      child: Text(active ? 'Activa' : 'Inactiva',
        style: TextStyle(
          color: active ? _C.green : _C.red,
          fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Text(label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.size = 18,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 140.ms,
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _hovered
                    ? widget.color.withOpacity(0.4) : Colors.transparent),
            ),
            child: Icon(widget.icon, size: widget.size, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 72,
            height: compact ? 52 : 72,
            decoration: BoxDecoration(
              color: _C.primaryLo,
              shape: BoxShape.circle,
              border: Border.all(color: _C.primary.withOpacity(0.2)),
            ),
            child: Icon(icon,
              color: _C.primary, size: compact ? 24 : 32),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(title,
            style: TextStyle(
              color: _C.textHi,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 14 : 16)),
          const SizedBox(height: 6),
          Text(subtitle,
            style: TextStyle(
              color: _C.textMid,
              fontSize: compact ? 11 : 13),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 5,
      itemBuilder: (_, i) => _SkeletonItem(index: i),
    );
  }
}

class _SkeletonItem extends StatefulWidget {
  final int index;
  const _SkeletonItem({required this.index});

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color.lerp(_C.card, _C.cardHover, _anim.value),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: widget.index * 60));
  }
}

// ── Sheet components ──────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _Sheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: _C.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        color: _C.textHi, fontWeight: FontWeight.w700,
                        fontSize: 15)),
                    Text(subtitle,
                      style: const TextStyle(
                        color: _C.textMid, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(Icons.close_rounded,
                      size: 14, color: _C.textMid),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _C.divider, height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.1, duration: 280.ms, curve: Curves.easeOut,
    ).fadeIn(duration: 200.ms);
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
      style: const TextStyle(
        color: _C.textMid, fontSize: 12,
        fontWeight: FontWeight.w500, letterSpacing: 0.3)),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      maxLines:     maxLines,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(color: _C.textHi, fontSize: 13),
      decoration: InputDecoration(
        hintText:       hint,
        hintStyle:      const TextStyle(color: _C.textLo, fontSize: 13),
        prefixIcon:     Icon(icon, size: 16, color: _C.textMid),
        filled:         true,
        fillColor:      _C.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.red),
        ),
        errorStyle: const TextStyle(color: _C.red, fontSize: 10),
      ),
    );
  }
}

class _SheetSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SheetSubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          disabledBackgroundColor: _C.card,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
class _EditItemSheet extends StatefulWidget {
  final PlaylistItemModel item;
  final void Function(PlaylistItemModel) onSave;
  const _EditItemSheet({required this.item, required this.onSave});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late ContentType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _textCtrl;
  late int _duration;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type     = widget.item.type;
    _titleCtrl= TextEditingController(text: widget.item.title);
    _urlCtrl  = TextEditingController(text: widget.item.url ?? '');
    _textCtrl = TextEditingController(text: widget.item.textContent ?? '');
    _duration = widget.item.durationSeconds;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _urlCtrl.dispose(); _textCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El título es obligatorio');
      return;
    }
    if (_type != ContentType.text && _urlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'La URL es obligatoria');
      return;
    }
    if (_type == ContentType.text && _textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El texto es obligatorio');
      return;
    }
    widget.onSave(PlaylistItemModel(
      id:              widget.item.id,
      type:            _type,
      title:           _titleCtrl.text.trim(),
      url:             _type != ContentType.text ? _urlCtrl.text.trim() : null,
      textContent:     _type == ContentType.text  ? _textCtrl.text.trim() : null,
      durationSeconds: _duration,
      order:           widget.item.order,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Editar elemento',
      subtitle: 'Modifica el contenido de este elemento',
      icon: Icons.edit_outlined,
      iconColor: _C.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),

          const _SheetLabel('Tipo de contenido'),
          const SizedBox(height: 8),
          _ContentTypeSelector(
            selected: _type,
            onChanged: (t) => setState(() { _type = t; _error = null; }),
          ),
          const SizedBox(height: 16),

          const _SheetLabel('Título *'),
          _SheetField(
            controller: _titleCtrl,
            hint: 'Título del elemento',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 16),

          if (_type == ContentType.text) ...[
            const _SheetLabel('Contenido de texto *'),
            _SheetField(
              controller: _textCtrl,
              hint: 'Texto que se mostrará en pantalla',
              icon: Icons.text_fields_rounded,
              maxLines: 4,
            ),
          ] else ...[
            _SheetLabel(_type == ContentType.image ? 'URL de la imagen *'
                       : _type == ContentType.video ? 'URL del video *'
                       : 'URL del sitio web *'),
            _SheetField(
              controller: _urlCtrl,
              hint: _type == ContentType.image ? 'https://example.com/imagen.jpg'
                  : _type == ContentType.video ? 'https://example.com/video.mp4'
                  : 'https://tu-sitio.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
          ],
          const SizedBox(height: 16),

          _SheetLabel('Duración: ${_duration}s'),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbColor: _C.accent,
              activeTrackColor: _C.accent,
              inactiveTrackColor: _C.border,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _duration.toDouble(),
              min: 3, max: 120, divisions: 39,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('3s',   style: TextStyle(color: _C.textLo, fontSize: 10)),
              Text('120s', style: TextStyle(color: _C.textLo, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 24),
          _SheetSubmitButton(
            label: 'Guardar cambios',
            loading: false,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(
                color: _C.textHi, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            Text(message,
              style: const TextStyle(color: _C.textMid, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                    style: TextStyle(color: _C.textMid, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Eliminar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.redLo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _C.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: const TextStyle(
                color: _C.red, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }
}

SnackBar _snack(String message) => SnackBar(
  content: Text(message,
    style: const TextStyle(color: _C.textHi, fontSize: 13)),
  backgroundColor: _C.card,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: _C.border),
  ),
  margin: const EdgeInsets.all(12),
  duration: const Duration(seconds: 2),
);

class _CredentialsDialog extends StatelessWidget {
  final String deviceName;
  final String username;
  final String password;
  const _CredentialsDialog({
    required this.deviceName,
    required this.username,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _C.greenLo,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle_rounded,
                    color: _C.green, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dispositivo creado',
                      style: TextStyle(color: _C.textHi,
                        fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(deviceName,
                      style: const TextStyle(color: _C.textMid, fontSize: 12)),
                  ],
                )),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Credenciales del portal',
                      style: TextStyle(color: _C.textMid, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    _CredRow(label: 'Usuario', value: username,
                      icon: Icons.person_outline_rounded, color: _C.primary),
                    const SizedBox(height: 10),
                    _CredRow(label: 'Contraseña', value: password,
                      icon: Icons.lock_outline_rounded, color: _C.accent),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.amberLo,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.amber.withOpacity(0.3))),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                          size: 14, color: _C.amber),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Guarda estas credenciales. El dispositivo las usará para acceder al portal.',
                          style: TextStyle(color: _C.amber, fontSize: 10, height: 1.5))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: 'Usuario: $username\nContraseña: $password'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Credenciales copiadas'),
                        backgroundColor: _C.card,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.textMid,
                    side: const BorderSide(color: _C.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Copiar todo'),
                    ],
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  child: const Text('Listo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CredRow({
    required this.label, required this.value,
    required this.icon, required this.color});

  @override
  State<_CredRow> createState() => _CredRowState();
}

class _CredRowState extends State<_CredRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(widget.icon, size: 14, color: widget.color),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label,
          style: const TextStyle(color: _C.textLo, fontSize: 9)),
        const SizedBox(height: 1),
        Text(widget.value,
          style: TextStyle(color: widget.color, fontSize: 13,
            fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.value));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _copied
              ? _C.greenLo : widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _copied
                ? _C.green.withOpacity(0.4) : widget.color.withOpacity(0.3))),
          child: Text(_copied ? '✓ Copiado' : 'Copiar',
            style: TextStyle(
              color: _copied ? _C.green : widget.color,
              fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

class _DeviceSchedulesManagerDialog extends StatefulWidget {
  final DeviceModel device;
  const _DeviceSchedulesManagerDialog({required this.device});
  @override
  State<_DeviceSchedulesManagerDialog> createState() =>
      _DeviceSchedulesManagerDialogState();
}

class _DeviceSchedulesManagerDialogState
    extends State<_DeviceSchedulesManagerDialog> {
  String _selectedDay = _todayKey();
  bool _playing = false;
  _ScheduleBlockData? _activeBlock;

  static String _todayKey() {
    const days = ['mon','tue','wed','thu','fri','sat','sun'];
    return days[DateTime.now().weekday - 1];
  }

  static const _dayLabels = {
    'mon': 'Lunes', 'tue': 'Martes', 'wed': 'Miércoles',
    'thu': 'Jueves', 'fri': 'Viernes', 'sat': 'Sábado', 'sun': 'Domingo',
  };
  static const _dayShort = {
    'mon': 'L', 'tue': 'M', 'wed': 'X',
    'thu': 'J', 'fri': 'V', 'sat': 'S', 'sun': 'D',
  };
  static const _orderedDays = ['mon','tue','wed','thu','fri','sat','sun'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border)),
      child: SizedBox(
        width: 580,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20,16,20,14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _C.divider))),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _C.purpleLo,
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_view_week_rounded,
                      color: _C.purple, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.device.name,
                          style: const TextStyle(color: _C.textHi,
                            fontWeight: FontWeight.w800, fontSize: 14)),
                        const Text('Programaciones del dispositivo',
                          style: TextStyle(color: _C.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _C.card, borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _C.border)),
                      child: const Icon(Icons.close_rounded,
                        size: 13, color: _C.textMid),
                    ),
                  ),
                ],
              ),
            ),

            // Selector día
            Padding(
              padding: const EdgeInsets.fromLTRB(20,14,20,10),
              child: Row(
                children: _orderedDays.map((d) {
                  final sel = d == _selectedDay;
                  final isToday = d == _todayKey();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedDay = d;
                        _activeBlock = null;
                        _playing = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                            ? _C.purple.withOpacity(0.18)
                            : isToday
                              ? _C.green.withOpacity(0.07)
                              : _C.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                              ? _C.purple.withOpacity(0.6)
                              : isToday
                                ? _C.green.withOpacity(0.35)
                                : _C.border,
                            width: sel ? 1.5 : 1)),
                        child: Column(
                          children: [
                            Text(_dayShort[d]!,
                              style: TextStyle(
                                color: sel ? _C.purple
                                  : isToday ? _C.green : _C.textMid,
                                fontSize: 12,
                                fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: sel ? _C.purple : _C.green,
                                  shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bloques del día
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('program_blocks')
                  .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(
                        color: _C.purple, strokeWidth: 2)));
                  }

                  final allBlocks = snap.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return _ScheduleBlockData(
                      id: d.id,
                      name: data['name'] ?? 'Sin nombre',
                      playlistId: data['playlistId'] ?? '',
                      playlistName: data['playlistName'] ?? '—',
                      days: List<String>.from(data['days'] ?? []),
                      startMinute: (data['startMinute'] as num?)?.toInt() ?? 0,
                      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
                      isActive: data['isActive'] ?? true,
                      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6366F1,
                    );
                  }).toList();

                  final dayBlocks = allBlocks
                    .where((b) => b.days.contains(_selectedDay) && b.isActive)
                    .toList()
                    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

                  if (dayBlocks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                            color: _C.textLo, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Sin programación el ${_dayLabels[_selectedDay]}',
                            style: const TextStyle(color: _C.textHi,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          const Text('Crea bloques en la sección Programaciones',
                            style: TextStyle(color: _C.textMid, fontSize: 12)),
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
                      final isNow = _isNow(b);
                      final isSelected = _activeBlock?.id == b.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeBlock = b;
                            _playing = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? color.withOpacity(0.14)
                              : isNow
                                ? color.withOpacity(0.08)
                                : _C.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                ? color.withOpacity(0.6)
                                : isNow
                                  ? color.withOpacity(0.4)
                                  : _C.border,
                              width: isSelected ? 1.5 : 1)),
                          child: Row(
                            children: [
                              Container(
                                width: 4, height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(b.name,
                                        style: TextStyle(
                                          color: isSelected ? color : _C.textHi,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                      if (isNow) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4)),
                                          child: Text('EN VIVO',
                                            style: TextStyle(color: color,
                                              fontSize: 8, fontWeight: FontWeight.w800))),
                                      ],
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_fmtMin(b.startMinute)} — ${_fmtMin(b.startMinute + b.durationMinutes)}  ·  ${b.playlistName}',
                                      style: const TextStyle(
                                        color: _C.textMid, fontSize: 11)),
                                  ],
                                ),
                              ),
                              // Botón reproducir
                              GestureDetector(
                                onTap: () => _openViewer(context, b),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: color.withOpacity(0.4))),
                                  child: Icon(Icons.play_arrow_rounded,
                                    size: 16, color: color)),
                              ),
                            ],
                          ),
                        ),
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

  bool _isNow(_ScheduleBlockData b) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= b.startMinute &&
           nowMin < b.startMinute + b.durationMinutes;
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}';
  }

  void _openViewer(BuildContext ctx, _ScheduleBlockData block) {
    showDialog(
      context: ctx,
      builder: (_) => _BlockPlaylistViewer(
        block: block,
        dayLabel: _dayLabels[_selectedDay]!,
      ),
    );
  }
}

class _ScheduleBlockData {
  final String id, name, playlistId, playlistName;
  final List<String> days;
  final int startMinute, durationMinutes, colorValue;
  final bool isActive;
  const _ScheduleBlockData({
    required this.id, required this.name,
    required this.playlistId, required this.playlistName,
    required this.days, required this.startMinute,
    required this.durationMinutes, required this.isActive,
    required this.colorValue,
  });
}

class _BlockPlaylistViewer extends StatefulWidget {
  final _ScheduleBlockData block;
  final String dayLabel;
  const _BlockPlaylistViewer({required this.block, required this.dayLabel});
  @override
  State<_BlockPlaylistViewer> createState() => _BlockPlaylistViewerState();
}

class _BlockPlaylistViewerState extends State<_BlockPlaylistViewer>
    with TickerProviderStateMixin {
  List<PlaylistItemModel>? _items;
  bool _loading = true;
  String? _error;
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
    _loadPlaylist();
  }

  @override
  void dispose() { _timer?.cancel(); _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadPlaylist() async {
    try {
      final doc = await FirebaseFirestore.instance
        .collection('playlists')
        .doc(widget.block.playlistId)
        .get();
      if (!doc.exists) {
        setState(() { _error = 'Playlist no encontrada'; _loading = false; });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['items'] as List<dynamic>?)
          ?? (data['clips'] as List<dynamic>?) ?? [];
      final items = raw.map((i) {
        final m = i as Map<String, dynamic>;
        return PlaylistItemModel(
          id: m['id'] ?? const Uuid().v4(),
          type: ContentType.values.firstWhere(
            (e) => e.name == (m['type'] ?? 'text'),
            orElse: () => ContentType.text),
          title: m['title'] ?? m['label'] ?? '',
          url: m['url'],
          textContent: m['textContent'] ?? m['text'],
          durationSeconds: (() {
            final v = m['durationSeconds'] ?? m['durationSec'] ?? 10;
            return v is int ? v : (v as num).round();
          })(),
          order: m['order'] ?? 0,
        );
      }).toList()..sort((a, b) => a.order.compareTo(b.order));

      setState(() { _items = items; _loading = false; });
      if (_playing && items.isNotEmpty) _startTimer();
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final items = _items;
    if (items == null || items.isEmpty) return;
    final idx = _currentIndex.clamp(0, items.length - 1);
    _timer = Timer(Duration(seconds: items[idx].durationSeconds), _nextSlide);
  }

  Future<void> _nextSlide() async {
    final items = _items;
    if (items == null || items.isEmpty) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % items.length;
    });
    await _fadeCtrl.forward();
    if (_playing) _startTimer();
  }

  String _fmtMin(int m) {
    final h = (m ~/ 60) % 24;
    final min = m % 60;
    return '${h.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.block.colorValue);
    return Dialog(
      backgroundColor: _C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.border)),
      child: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20,16,20,14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _C.divider))),
              child: Row(
                children: [
                  Container(width: 4, height: 36,
                    decoration: BoxDecoration(color: color,
                      borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.block.name,
                          style: const TextStyle(color: _C.textHi,
                            fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(
                          '${widget.dayLabel}  ·  ${_fmtMin(widget.block.startMinute)} — ${_fmtMin(widget.block.startMinute + widget.block.durationMinutes)}  ·  ${widget.block.playlistName}',
                          style: const TextStyle(color: _C.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: _C.card,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _C.border)),
                      child: const Icon(Icons.close_rounded,
                        size: 13, color: _C.textMid)),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Padding(padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: _C.primary, strokeWidth: 2))
            else if (_error != null)
              Padding(padding: const EdgeInsets.all(32),
                child: Text(_error!,
                  style: const TextStyle(color: _C.red, fontSize: 13)))
            else if (_items == null || _items!.isEmpty)
              const Padding(padding: EdgeInsets.all(32),
                child: Text('Playlist sin contenido',
                  style: TextStyle(color: _C.textMid, fontSize: 13)))
            else ...[
              // Canvas
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: Stack(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: _DisplayContent(
                            item: _items![_currentIndex.clamp(0, _items!.length-1)]),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: _DisplayProgressBar(
                            index: _currentIndex.clamp(0, _items!.length-1),
                            total: _items!.length,
                            durationSec: _items![_currentIndex.clamp(0, _items!.length-1)].durationSeconds,
                            key: ValueKey('bpv_$_currentIndex'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16,0,16,8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        _timer?.cancel();
                        await _fadeCtrl.reverse();
                        if (!mounted) return;
                        setState(() {
                          _currentIndex = (_currentIndex - 1 + _items!.length) % _items!.length;
                        });
                        await _fadeCtrl.forward();
                        if (_playing) _startTimer();
                      },
                      child: const Icon(Icons.skip_previous_rounded,
                        color: _C.textMid, size: 20)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() => _playing = !_playing);
                        if (_playing) _startTimer(); else _timer?.cancel();
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white, size: 20)),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        _timer?.cancel();
                        await _fadeCtrl.reverse();
                        if (!mounted) return;
                        setState(() {
                          _currentIndex = (_currentIndex + 1) % _items!.length;
                        });
                        await _fadeCtrl.forward();
                        if (_playing) _startTimer();
                      },
                      child: const Icon(Icons.skip_next_rounded,
                        color: _C.textMid, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${_currentIndex+1} / ${_items!.length}  ·  ${_items![_currentIndex.clamp(0,_items!.length-1)].title}',
                        style: const TextStyle(color: _C.textMid, fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),

              // Thumbnails strip
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final isActive = i == _currentIndex;
                    final item = _items![i];
                    final typeColor = item.type == ContentType.image ? _C.accent
                      : item.type == ContentType.video ? _C.purple
                      : item.type == ContentType.text ? _C.green : _C.amber;
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
                        duration: const Duration(milliseconds: 150),
                        width: 80,
                        decoration: BoxDecoration(
                          color: isActive ? color.withOpacity(0.15) : _C.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? color : _C.border,
                            width: isActive ? 2 : 1)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_iconFor(item.type), size: 16,
                              color: isActive ? color : typeColor),
                            const SizedBox(height: 2),
                            Text(item.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isActive ? color : _C.textLo,
                                fontSize: 8, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ContentType t) {
    switch (t) {
      case ContentType.image: return Icons.image_rounded;
      case ContentType.video: return Icons.videocam_rounded;
      case ContentType.text:  return Icons.text_fields_rounded;
      case ContentType.url:   return Icons.language_rounded;
    }
  }
}




class _AssignSchedulesSheet extends ConsumerStatefulWidget {
  final DeviceModel device;
  const _AssignSchedulesSheet({required this.device});

  @override
  ConsumerState<_AssignSchedulesSheet> createState() => _AssignSchedulesSheetState();
}

class _AssignSchedulesSheetState extends ConsumerState<_AssignSchedulesSheet> {
  late Set<String> _selected;
  String _search = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.device.assignedScheduleIds);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.device.id)
        .update({'assignedScheduleIds': _selected.toList()});
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('✅ Programaciones actualizadas en ${widget.device.name}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Gestionar programaciones',
      subtitle: 'Selecciona las programaciones para "${widget.device.name}"',
      icon: Icons.calendar_view_week_rounded,
      iconColor: _C.purple,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('schedules').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(
            child: CircularProgressIndicator(color: _C.purple, strokeWidth: 2));

          final schedules = snap.data!.docs
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList();

          final filtered = _search.isEmpty
              ? schedules
              : schedules.where((s) =>
                  (s['name'] as String? ?? '').toLowerCase().contains(_search)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscador
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border),
                ),
                child: TextField(
                  style: const TextStyle(color: _C.textHi, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Buscar programación...',
                    hintStyle: TextStyle(color: _C.textLo, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: _C.textMid, size: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    filled: false,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('${_selected.length} seleccionadas',
                    style: const TextStyle(color: _C.purple, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selected.clear()),
                    child: const Text('Limpiar todo',
                      style: TextStyle(color: _C.red, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                _EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Sin programaciones',
                  subtitle: 'No hay programaciones disponibles',
                  compact: true,
                )
              else ...[
                ...filtered.map((s) {
                  final id = s['id'] as String;
                  final name = s['name'] as String? ?? '—';
                  final desc = s['description'] as String? ?? '';
                  final isActive = s['isActive'] as bool? ?? true;
                  final isSelected = _selected.contains(id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) _selected.remove(id);
                      else _selected.add(id);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.purple.withOpacity(0.10) : _C.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _C.purple.withOpacity(0.5) : _C.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: _C.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_view_week_rounded,
                                color: _C.purple, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(name,
                                    style: TextStyle(
                                      color: isSelected ? _C.textHi : _C.textMid,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 13))),
                                  if (!isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _C.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Inactiva',
                                        style: TextStyle(color: _C.red, fontSize: 9,
                                            fontWeight: FontWeight.w700)),
                                    ),
                                ]),
                                if (desc.isNotEmpty)
                                  Text(desc,
                                    style: const TextStyle(color: _C.textLo, fontSize: 11),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: isSelected ? _C.purple : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? _C.purple : _C.textLo),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _SheetSubmitButton(
                  label: _saving ? '' : 'Guardar (${_selected.length} seleccionadas)',
                  loading: _saving,
                  onTap: _save,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}