// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui show TextDirection, Color, Gradient, Shadow, FontWeight;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html_lib;
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

// =============================================================================
// DESIGN TOKENS (mismo que panel.dart)
// =============================================================================
abstract class _EC {
  static const bg = Color(0xFF070B12);
  static const surface = Color(0xFF0C1018);
  static const card = Color(0xFF111827);
  static const cardHi = Color(0xFF151E2F);
  static const border = Color(0xFF1F2D45);
  static const primary = Color(0xFF6366F1);
  static const primaryLo = Color(0x1A6366F1);
  static const accent = Color(0xFF38BDF8);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
  static const purpleLo = Color(0x1AA855F7);
  static const textHi = Color(0xFFF1F5FF);
  static const textMid = Color(0xFF7B8DB0);
  static const textLo = Color(0xFF2E3D5C);
  static const divider = Color(0xFF141E30);
  static const track1 = Color(0xFF6366F1);
  static const track2 = Color(0xFF38BDF8);
  static const track3 = Color(0xFF22C55E);
  static const track4 = Color(0xFFF59E0B);
  static const track5 = Color(0xFFA855F7);
}

const _uuid = Uuid();

int _findOrCreateFreeTrack(
  WidgetRef ref,
  double startSec,
  double durationSec,
) {
  final clips = ref.read(editorClipsProvider);
  final tracks = ref.read(tracksProvider);
  final notifier = ref.read(tracksProvider.notifier);

  for (int i = 0; i < tracks.length; i++) {
    final occupied = clips.any((c) =>
        c.trackIndex == i &&
        c.startSec < (startSec + durationSec) &&
        (c.startSec + c.durationSec) > startSec);
    if (!occupied) return i;
  }

  // No hay track libre → crear uno nuevo
  final newIdx = tracks.length;
  final colors = [
    _EC.track1,
    _EC.track2,
    _EC.track3,
    _EC.track4,
    _EC.track5,
    _EC.red,
    _EC.purple,
    const Color(0xFFEC4899),
    _EC.accent,
    _EC.green
  ];
  notifier.add(TrackDef(
    id: 't${DateTime.now().millisecondsSinceEpoch}',
    label: 'Track ${newIdx + 1}',
    color: colors[newIdx % colors.length],
    defaultType: EditorLayerType.video,
  ));
  return newIdx;
}

// =============================================================================
// MODELOS DEL EDITOR
// =============================================================================

enum EditorLayerType { video, image, text, audio, overlay }

enum TextAlign2 { left, center, right }

class EditorClip {
  final String id;
  final EditorLayerType type;
  final String label;
  final String? url;
  final String? text;
  final double startSec;
  final double durationSec;
  final int trackIndex;
  // Visual properties
  final double x, y, width, height;
  final double opacity;
  final double rotation;
  final Color? textColor;
  final double? fontSize;
  final bool? bold;
  final String? backgroundColor;
  final double volume;
  final double trimStart;
  final double trimEnd;
// Pega esto dentro de la clase EditorClip
  /* factory EditorClip.fromMap(Map<String, dynamic> c) {
    final typeStr = c['type'] as String? ?? 'text';
    final type = EditorLayerType.values.firstWhere(
      (e) => e.name == typeStr, orElse: () => EditorLayerType.text);
    final colorVal = c['textColor'];
    
    return EditorClip(
      id:              c['id'] ?? const Uuid().v4(),
      type:            type,
      label:           c['label'] ?? '',
      url:             c['url'],
      text:            c['text'],
      startSec:        (c['startSec'] as num).toDouble(),
      durationSec:     (c['durationSec'] as num).toDouble(),
      trackIndex:      (c['trackIndex'] as num).toInt(),
      x:               (c['x'] as num?)?.toDouble() ?? 640,
      y:               (c['y'] as num?)?.toDouble() ?? 360,
      width:           (c['width'] as num?)?.toDouble() ?? 1280,
      height:          (c['height'] as num?)?.toDouble() ?? 720,
      opacity:         (c['opacity'] as num?)?.toDouble() ?? 1.0,
      rotation:        (c['rotation'] as num?)?.toDouble() ?? 0,
      textColor:       colorVal != null ? Color(colorVal as int) : null,
      fontSize:        (c['fontSize'] as num?)?.toDouble() ?? 48,
      bold:            c['bold'] as bool? ?? false,
      backgroundColor: c['backgroundColor'],
      volume:          (c['volume'] as num?)?.toDouble() ?? 1.0,
      trimStart:       (c['trimStart'] as num?)?.toDouble() ?? 0,
      trimEnd:         (c['trimEnd'] as num?)?.toDouble() ?? 0,
    );
  }*/
  factory EditorClip.fromMap(Map<String, dynamic> c) {
    final typeStr = c['type'] as String? ?? 'text';
    final type = EditorLayerType.values.firstWhere((e) => e.name == typeStr,
        orElse: () => EditorLayerType.text);
    final colorVal = c['textColor'];

    final startSec = (c['startSec'] as num?)?.toDouble() ??
        (c['start_sec'] as num?)?.toDouble() ??
        0.0;

    final durationSec = (c['durationSec'] as num?)?.toDouble() ??
        (c['duration_sec'] as num?)?.toDouble() ??
        (c['durationSeconds'] as num?)?.toDouble() ??
        5.0;

    final trackIndex = (c['trackIndex'] as num?)?.toInt() ??
        (c['track_index'] as num?)?.toInt() ??
        0;

    return EditorClip(
      id: c['id'] as String? ?? const Uuid().v4(),
      type: type,
      label: c['label'] as String? ?? c['name'] as String? ?? '',
      url: c['url'] as String?,
      text: c['text'] as String?,
      startSec: startSec,
      durationSec: durationSec,
      trackIndex: trackIndex,
      x: (c['x'] as num?)?.toDouble() ?? 640,
      y: (c['y'] as num?)?.toDouble() ?? 360,
      width: (c['width'] as num?)?.toDouble() ?? 1280,
      height: (c['height'] as num?)?.toDouble() ?? 720,
      opacity: (c['opacity'] as num?)?.toDouble() ?? 1.0,
      rotation: (c['rotation'] as num?)?.toDouble() ?? 0,
      textColor: colorVal != null ? Color(colorVal as int) : null,
      fontSize: (c['fontSize'] as num?)?.toDouble() ?? 48,
      bold: c['bold'] as bool? ?? false,
      backgroundColor: c['backgroundColor'] as String?,
      volume: (c['volume'] as num?)?.toDouble() ?? 1.0,
      trimStart: (c['trimStart'] as num?)?.toDouble() ?? 0,
      trimEnd: (c['trimEnd'] as num?)?.toDouble() ?? 0,
    );
  }
  const EditorClip({
    required this.id,
    required this.type,
    required this.label,
    this.url,
    this.text,
    required this.startSec,
    required this.durationSec,
    required this.trackIndex,
    this.x = 0,
    this.y = 0,
    this.width = 1280,
    this.height = 720,
    this.opacity = 1.0,
    this.rotation = 0,
    this.textColor,
    this.fontSize = 48,
    this.bold = false,
    this.backgroundColor,
    this.volume = 1.0,
    this.trimStart = 0,
    this.trimEnd = 0,
  });

  EditorClip copyWith({
    String? id,
    EditorLayerType? type,
    String? label,
    String? url,
    String? text,
    double? startSec,
    double? durationSec,
    int? trackIndex,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    double? rotation,
    Color? textColor,
    double? fontSize,
    bool? bold,
    String? backgroundColor,
    double? volume,
    double? trimStart,
    double? trimEnd,
  }) =>
      EditorClip(
        id: id ?? this.id,
        type: type ?? this.type,
        label: label ?? this.label,
        url: url ?? this.url,
        text: text ?? this.text,
        startSec: startSec ?? this.startSec,
        durationSec: durationSec ?? this.durationSec,
        trackIndex: trackIndex ?? this.trackIndex,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        opacity: opacity ?? this.opacity,
        rotation: rotation ?? this.rotation,
        textColor: textColor ?? this.textColor,
        fontSize: fontSize ?? this.fontSize,
        bold: bold ?? this.bold,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        volume: volume ?? this.volume,
        trimStart: trimStart ?? this.trimStart,
        trimEnd: trimEnd ?? this.trimEnd,
      );
}

// =============================================================================
// PROVIDERS
// =============================================================================

final editorClipsProvider =
    StateNotifierProvider<EditorClipsNotifier, List<EditorClip>>((ref) {
  return EditorClipsNotifier();
});

final selectedClipIdProvider = StateProvider<String?>((ref) => null);
final playheadProvider = StateProvider<double>((ref) => 0.0);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final zoomProvider = StateProvider<double>((ref) => 60.0); // px per second
// Modelo de playlist guardada

class SavedPlaylist {
  final String id;
  final String name;
  final List<EditorClip> clips;
  final DateTime createdAt;
  final String viewLink;

  const SavedPlaylist({
    required this.id,
    required this.name,
    required this.clips,
    required this.createdAt,
    required this.viewLink,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'viewLink': viewLink,
        'clips': clips
            .map((c) => {
                  'id': c.id,
                  'type': c.type.name,
                  'label': c.label,
                  'url': c.url,
                  'text': c.text,
                  'startSec': c.startSec,
                  'durationSec': c.durationSec,
                  'trackIndex': c.trackIndex,
                  'x': c.x,
                  'y': c.y,
                  'width': c.width,
                  'height': c.height,
                  'opacity': c.opacity,
                  'rotation': c.rotation,
                  'textColor': c.textColor?.value,
                  'fontSize': c.fontSize,
                  'bold': c.bold,
                  'backgroundColor': c.backgroundColor,
                  'volume': c.volume,
                  'trimStart': c.trimStart,
                  'trimEnd': c.trimEnd,
                })
            .toList(),
      };

  static SavedPlaylist fromFirestore(Map<String, dynamic> data) {
    final rawItems = (data['clips'] as List<dynamic>?) ?? [];

    DateTime createdAt;
    final rawDate = data['createdAt'];

    if (rawDate is Timestamp) {
      createdAt = rawDate.toDate();
    } else if (rawDate is String) {
      createdAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return SavedPlaylist(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Playlist',
      createdAt: createdAt,
      viewLink: data['viewLink'] ?? '',
      clips: rawItems
          .map((i) => EditorClip.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

final savedPlaylistsProvider =
    StateNotifierProvider<SavedPlaylistsNotifier, List<SavedPlaylist>>((ref) {
  return SavedPlaylistsNotifier();
});

class SavedPlaylistsNotifier extends StateNotifier<List<SavedPlaylist>> {
  SavedPlaylistsNotifier() : super([]) {
    _load();
  }

  static const _collection = 'playlists';
  final _db = FirebaseFirestore.instance;

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = [];
        return;
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      QuerySnapshot snap;
      if (companyId != null) {
        snap = await _db
            .collection(_collection)
            .where('companyId', isEqualTo: companyId)
            .get();
      } else {
        snap = await _db
            .collection(_collection)
            .where('ownerId', isEqualTo: uid)
            .get();
      }

      final list = snap.docs
          .map((d) {
            try {
              return SavedPlaylist.fromFirestore(
                  d.data() as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parseando playlist ${d.id}: $e');
              return null;
            }
          })
          .whereType<SavedPlaylist>()
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = list;
    } catch (e) {
      debugPrint('Error cargando playlists: $e');
      state = [];
    }
  }

  Future<void> add(SavedPlaylist p) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await _db.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      final data = p.toFirestore();
      if (companyId != null) data['companyId'] = companyId;
      data['ownerId'] = uid;

      await _db.collection(_collection).doc(p.id).set(data);
      state = [p, ...state];
    } catch (e) {
      debugPrint('Error guardando playlist: $e');
    }
  }

  Future<void> remove(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      debugPrint('Error eliminando playlist: $e');
    }
  }

  Future<void> update(SavedPlaylist updated) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await _db.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      final data = updated.toFirestore();
      if (companyId != null) data['companyId'] = companyId;
      data['ownerId'] = uid;

      await _db.collection(_collection).doc(updated.id).set(data);
      state = state.map((p) => p.id == updated.id ? updated : p).toList();
    } catch (e) {
      debugPrint('Error actualizando playlist: $e');
    }
  }
}

class EditorClipsNotifier extends StateNotifier<List<EditorClip>> {
  EditorClipsNotifier() : super([]);

  final _sw = Stopwatch()..start();
  EditorClip? _pendingUpdate;

  // Historial para undo/redo
  final List<List<EditorClip>> _history = [];
  int _historyIndex = -1;
  static const _maxHistory = 50;

  void _snapshot() {
    // Elimina los estados "futuros" si estábamos en medio del historial
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(List.from(state));
    if (_history.length > _maxHistory) _history.removeAt(0);
    _historyIndex = _history.length - 1;
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void undo() {
    _flush();
    if (!canUndo) return;
    _historyIndex--;
    state = List.from(_history[_historyIndex]);
  }

  void redo() {
    _flush();
    if (!canRedo) return;
    _historyIndex++;
    state = List.from(_history[_historyIndex]);
  }

  void setAll(List<EditorClip> clips) {
    _pendingUpdate = null;
    state = clips;
    _snapshot();
  }

  void add(EditorClip clip) {
    state = [...state, clip];
    _snapshot();
  }

  void update(EditorClip updated) {
    final current =
        state.firstWhere((c) => c.id == updated.id, orElse: () => updated);
    if (current.trackIndex != updated.trackIndex) {
      state = state.map((c) => c.id == updated.id ? updated : c).toList();
      _snapshot();
      return;
    }
    _pendingUpdate = updated;
    if (_sw.elapsedMilliseconds > 16) {
      _flush();
    }
  }

  void _flush() {
    if (_pendingUpdate == null) return;
    final prev = state;
    state = state
        .map((c) => c.id == _pendingUpdate!.id ? _pendingUpdate! : c)
        .toList();
    // Solo snapshot si cambió algo relevante (posición final, no cada frame)
    if (_sw.elapsedMilliseconds > 300) _snapshot();
    _pendingUpdate = null;
    _sw.reset();
  }

  void remove(String id) {
    _flush();
    state = state.where((c) => c.id != id).toList();
    _snapshot();
  }

  void reorder(String id, double newStart, int newTrack) {
    state = state.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
          startSec: newStart.clamp(0, 9999), trackIndex: newTrack);
    }).toList();
  }

  double get totalDuration {
    if (state.isEmpty) return 30;
    return state.map((c) => c.startSec + c.durationSec).reduce(math.max) + 5;
  }
}

// =============================================================================
// SCREEN EDITOR — MAIN SCREEN
// =============================================================================

class ScreenEditorScreen extends ConsumerStatefulWidget {
  const ScreenEditorScreen({super.key});

  @override
  ConsumerState<ScreenEditorScreen> createState() => _ScreenEditorScreenState();
}

class _ScreenEditorScreenState extends ConsumerState<ScreenEditorScreen> {
  Timer? _playTimer;
  final ScrollController _timelineScroll = ScrollController();

  @override
  void dispose() {
    _playTimer?.cancel();
    _timelineScroll.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final isPlaying = ref.read(isPlayingProvider);
    if (isPlaying) {
      _playTimer?.cancel();
      ref.read(isPlayingProvider.notifier).state = false;
    } else {
      ref.read(isPlayingProvider.notifier).state = true;
      _playTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        final current = ref.read(playheadProvider);
        final total = ref.read(editorClipsProvider.notifier).totalDuration;
        if (current >= total) {
          _playTimer?.cancel();
          ref.read(isPlayingProvider.notifier).state = false;
          ref.read(playheadProvider.notifier).state = 0;
        } else {
          ref.read(playheadProvider.notifier).state = current + 0.05;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EC.bg,
      body: Column(
        children: [
          // ── Top toolbar ─────────────────────────────────────────────────
          _EditorTopBar(onTogglePlay: _togglePlay),
          // ── Main area ───────────────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Left: Media library panel
                const SizedBox(width: 220, child: _MediaPanel()),
                Container(width: 1, color: _EC.divider),
                // Center: Preview + Properties
                const Expanded(child: _CenterPanel()),
                Container(width: 1, color: _EC.divider),
                // Right: Properties panel
                const SizedBox(width: 260, child: _PropertiesPanel()),
              ],
            ),
          ),
          Container(height: 1, color: _EC.divider),
          // ── Timeline ────────────────────────────────────────────────────
          Expanded(
            child: _TimelinePanel(scrollController: _timelineScroll),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TOP BAR
// =============================================================================

class _EditorTopBar extends ConsumerWidget {
  final VoidCallback onTogglePlay;
  const _EditorTopBar({required this.onTogglePlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final playhead = ref.watch(playheadProvider);
    final clips = ref.watch(editorClipsProvider);
    final totalDur = ref.read(editorClipsProvider.notifier).totalDuration;

    String fmt(double s) {
      final m = s ~/ 60;
      final sec = (s % 60).toStringAsFixed(1);
      return '${m.toString().padLeft(2, '0')}:${sec.padLeft(4, '0')}';
    }

    return Container(
      height: 52,
      color: _EC.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => context.go('/content'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _EC.card,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _EC.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_rounded, size: 14, color: _EC.textMid),
                  SizedBox(width: 6),
                  Text('Playlists',
                      style: TextStyle(color: _EC.textMid, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          const Text('Editor de Pantalla',
              style: TextStyle(
                  color: _EC.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.3)),
          const Spacer(),

          // Transport controls
          _TransportBtn(
            icon: Icons.skip_previous_rounded,
            onTap: () => ref.read(playheadProvider.notifier).state = 0,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _EC.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20),
            ),
          ),
          const SizedBox(width: 4),
          _TransportBtn(
            icon: Icons.skip_next_rounded,
            onTap: () => ref.read(playheadProvider.notifier).state = totalDur,
          ),
          const SizedBox(width: 12),

          // Timecode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _EC.card,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _EC.border),
            ),
            child: Text(
              '${fmt(playhead)} / ${fmt(totalDur)}',
              style: const TextStyle(
                  color: _EC.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),

          // Zoom
          const Icon(Icons.zoom_out_rounded, size: 14, color: _EC.textMid),
          SizedBox(
            width: 80,
            child: Consumer(builder: (_, ref, __) {
              final zoom = ref.watch(zoomProvider);
              return Slider(
                value: zoom,
                min: 20,
                max: 200,
                activeColor: _EC.primary,
                inactiveColor: _EC.border,
                onChanged: (v) => ref.read(zoomProvider.notifier).state = v,
              );
            }),
          ),
          const Icon(Icons.zoom_in_rounded, size: 14, color: _EC.textMid),
          const SizedBox(width: 12),

          // Playlists guardadas
          GestureDetector(
            onTap: () => _showPlaylistsDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _EC.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _EC.border),
              ),
              child: Consumer(builder: (_, ref, __) {
                final count = ref.watch(savedPlaylistsProvider).length;
                return Row(
                  children: [
                    const Icon(Icons.video_library_rounded,
                        size: 14, color: _EC.textMid),
                    const SizedBox(width: 6),
                    Text('Mis playlists ($count)',
                        style:
                            const TextStyle(color: _EC.textMid, fontSize: 12)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 8),

          // Guardar
          GestureDetector(
            onTap: () => _showSaveDialog(context, ref, clips),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_EC.primary, Color(0xFF818CF8)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.save_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Guardar',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(
      BuildContext ctx, WidgetRef ref, List<EditorClip> clips) {
    // Busca si hay una playlist cargada actualmente
    final playlists = ref.read(savedPlaylistsProvider);
    // Detecta si los clips actuales coinciden con alguna playlist guardada
    // comparando los IDs de los clips
    final clipIds = clips.map((c) => c.id).toSet();
    SavedPlaylist? existing;
    for (final pl in playlists) {
      final plIds = pl.clips.map((c) => c.id).toSet();
      if (plIds.isNotEmpty &&
          clipIds.containsAll(plIds) &&
          plIds.containsAll(clipIds)) {
        existing = pl;
        break;
      }
      // También detecta si la mayoría de IDs coinciden (>= 70%)
      final intersection = plIds.intersection(clipIds).length;
      if (plIds.isNotEmpty && intersection / plIds.length >= 0.7) {
        existing = pl;
        break;
      }
    }

    showDialog(
      context: ctx,
      builder: (_) => _SavePlaylistDialog(
        clips: clips,
        existingPlaylist: existing,
        onSaved: (playlist) async {
          if (existing != null) {
            await ref.read(savedPlaylistsProvider.notifier).update(playlist);
          } else {
            await ref.read(savedPlaylistsProvider.notifier).add(playlist);
          }
        },
      ),
    );
  }

  void _showPlaylistsDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => const _PlaylistsListDialog(), // ya no pasa ref
    );
  }
}

class _TransportBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TransportBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _EC.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _EC.border),
          ),
          child: Icon(icon, size: 16, color: _EC.textMid),
        ),
      );
}

// =============================================================================
// LEFT: MEDIA PANEL
// =============================================================================

// =============================================================================
// PLANTILLAS GUARDADAS (provider global)
// =============================================================================

class TemplateItem {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final List<EditorClip> clips;

  const TemplateItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.clips,
  });
}

final customTemplatesProvider =
    StateNotifierProvider<CustomTemplatesNotifier, List<TemplateItem>>((ref) {
  return CustomTemplatesNotifier();
});

class CustomTemplatesNotifier extends StateNotifier<List<TemplateItem>> {
  CustomTemplatesNotifier() : super([]) {
    _load();
  }

  static const _collection = 'custom_templates';
  final _db = FirebaseFirestore.instance;

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = [];
        return;
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      QuerySnapshot snap;
      if (companyId != null) {
        snap = await _db
            .collection(_collection)
            .where('companyId', isEqualTo: companyId)
            .get();
      } else {
        snap = await _db
            .collection(_collection)
            .where('ownerId', isEqualTo: uid)
            .get();
      }

      final list = snap.docs
          .map((d) {
            try {
              return _templateFromFirestore(d.data() as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parseando plantilla ${d.id}: $e');
              return null;
            }
          })
          .whereType<TemplateItem>()
          .toList();

      state = list;
    } catch (e) {
      debugPrint('Error cargando plantillas: $e');
      state = [];
    }
  }

  Future<void> add(TemplateItem t) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = await _db.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

      final data = _templateToFirestore(t);
      data['ownerId'] = uid;
      if (companyId != null) data['companyId'] = companyId;

      await _db.collection(_collection).doc(t.id).set(data);
      state = [...state, t];
    } catch (e) {
      debugPrint('Error guardando plantilla: $e');
    }
  }

  Future<void> remove(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      state = state.where((t) => t.id != id).toList();
    } catch (e) {
      debugPrint('Error eliminando plantilla: $e');
    }
  }

  Map<String, dynamic> _templateToFirestore(TemplateItem t) => {
        'id': t.id,
        'name': t.name,
        'category': t.category,
        'iconCodePoint': t.icon.codePoint,
        'iconFontFamily': t.icon.fontFamily ?? 'MaterialIcons',
        'colorValue': t.color.value,
        'clips': t.clips
            .map((c) => {
                  'id': c.id,
                  'type': c.type.name,
                  'label': c.label,
                  if (c.url != null) 'url': c.url,
                  if (c.text != null) 'text': c.text,
                  'startSec': c.startSec,
                  'durationSec': c.durationSec,
                  'trackIndex': c.trackIndex,
                  'x': c.x,
                  'y': c.y,
                  'width': c.width,
                  'height': c.height,
                  'opacity': c.opacity,
                  'rotation': c.rotation,
                  if (c.textColor != null) 'textColor': c.textColor!.value,
                  'fontSize': c.fontSize ?? 48,
                  'bold': c.bold ?? false,
                  if (c.backgroundColor != null)
                    'backgroundColor': c.backgroundColor,
                  'volume': c.volume,
                  'trimStart': c.trimStart,
                  'trimEnd': c.trimEnd,
                })
            .toList(),
      };

  TemplateItem _templateFromFirestore(Map<String, dynamic> data) {
    final List<EditorClip> clips = (data['clips'] as List<dynamic>? ?? [])
        .map(
          (clip) => EditorClip.fromMap(
            Map<String, dynamic>.from(clip as Map),
          ),
        )
        .toList();

    final int iconCodePoint =
        data['iconCodePoint'] as int? ?? Icons.help.codePoint;
    final String iconFontFamily =
        data['iconFontFamily'] as String? ?? 'MaterialIcons';

    final int colorValue = data['colorValue'] as int? ?? Colors.blue.value;

    return TemplateItem(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      icon: _iconFromCodePoint(iconCodePoint),
      color: Color(colorValue),
      clips: clips,
    );
  }

  IconData _iconFromCodePoint(int codePoint) {
    const known = <int, IconData>{
      0xe5d2: Icons.star_rounded,
      0xf06b3: Icons.waving_hand_rounded,
      0xe54e: Icons.local_offer_rounded,
      0xef56: Icons.restaurant_menu_rounded,
      0xf05d4: Icons.newspaper_rounded,
      0xea65: Icons.celebration_rounded,
      0xe88e: Icons.info_rounded,
      0xe0b7: Icons.campaign_rounded,
      0xf04c5: Icons.bookmark_add_rounded,
      0xe047: Icons.image_rounded,
      0xe04b: Icons.videocam_rounded,
      0xe262: Icons.text_fields_rounded,
      0xe405: Icons.music_note_rounded,
      0xe53b: Icons.layers_rounded,
    };
    return known[codePoint] ?? Icons.help_rounded;
  }
}

// =============================================================================
// MEDIA PANEL
// =============================================================================

class _MediaPanel extends ConsumerStatefulWidget {
  const _MediaPanel();
  @override
  ConsumerState<_MediaPanel> createState() => _MediaPanelState();
}

class _MediaPanelState extends ConsumerState<_MediaPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedCategory = 'Todos';

  final _builtinCategories = [
    'Todos',
    'Bienvenida',
    'Promoción',
    'Menú',
    'Noticias',
    'Mis plantillas'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customTemplates = ref.watch(customTemplatesProvider);

    return Container(
      color: _EC.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tabs ──
          Container(
            color: _EC.card,
            child: TabBar(
              controller: _tabs,
              labelColor: _EC.primary,
              unselectedLabelColor: _EC.textMid,
              indicatorColor: _EC.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Media'),
                Tab(text: 'Plantillas'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── TAB 1: Media ──
                _buildMediaTab(),
                // ── TAB 2: Plantillas ──
                _buildTemplatesTab(customTemplates),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAnimationsDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _AnimationLibraryDialog(
        onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip),
      ),
    );
  }

  void _showAddAudioDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _AddMediaDialog(
          type: EditorLayerType.audio,
          onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip)),
    );
  }

  void _showTVColombia(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _TVColombiaDialog(
        onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip),
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: _EC.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _EC.border),
            ),
            child: const TextField(
              style: TextStyle(color: _EC.textHi, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: TextStyle(color: _EC.textLo, fontSize: 11),
                prefixIcon:
                    Icon(Icons.search_rounded, size: 14, color: _EC.textMid),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('AGREGAR ELEMENTO',
              style: TextStyle(
                  color: _EC.textMid,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          _AnimatedMediaBtn(
            icon: Icons.image_rounded,
            label: 'Agregar imagen',
            color: _EC.accent,
            delay: 0,
            onTap: () => _showAddImageDialog(context, ref),
          ),
          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.videocam_rounded,
            label: 'Agregar video',
            color: _EC.purple,
            delay: 50,
            onTap: () => _showAddVideoDialog(context, ref),
          ),
          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.text_fields_rounded,
            label: 'Agregar texto',
            color: _EC.green,
            delay: 100,
            onTap: () => _showAddTextDialog(context, ref),
          ),
          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.layers_rounded,
            label: 'Agregar overlay',
            color: _EC.amber,
            delay: 150,
            onTap: () =>
                _showAddClipDialog(context, ref, EditorLayerType.overlay),
          ),
          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.tv_rounded,
            label: 'TV Colombia en vivo',
            color: const Color(0xFFEC4899),
            delay: 225,
            onTap: () => _showTVColombia(context, ref),
          ),

          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.auto_awesome_rounded,
            label: 'Animaciones',
            color: const Color(0xFFEC4899),
            delay: 200,
            onTap: () => _showAnimationsDialog(context, ref),
          ),
          const SizedBox(height: 6),
          _AnimatedMediaBtn(
            icon: Icons.music_note_rounded,
            label: 'Agregar audio',
            color: _EC.green,
            delay: 175,
            onTap: () => _showAddAudioDialog(context, ref),
          ),
          const SizedBox(height: 16),
          // Botón: guardar selección como plantilla
          GestureDetector(
            onTap: () => _showSaveAsTemplateDialog(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _EC.primaryLo,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _EC.primary.withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_rounded,
                      size: 13, color: _EC.primary),
                  SizedBox(width: 6),
                  Text('Guardar como plantilla',
                      style: TextStyle(
                          color: _EC.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(List<TemplateItem> custom) {
    // Plantillas predefinidas
    final builtin = <TemplateItem>[
      TemplateItem(
        id: 'welcome',
        name: 'Bienvenida',
        category: 'Bienvenida',
        icon: Icons.waving_hand_rounded,
        color: _EC.primary,
        clips: _welcomeClips(),
      ),
      TemplateItem(
        id: 'promo',
        name: 'Promoción',
        category: 'Promoción',
        icon: Icons.local_offer_rounded,
        color: _EC.amber,
        clips: _promoClips(),
      ),
      TemplateItem(
        id: 'menu',
        name: 'Menú del día',
        category: 'Menú',
        icon: Icons.restaurant_menu_rounded,
        color: _EC.green,
        clips: _menuClips(),
      ),
      TemplateItem(
        id: 'news',
        name: 'Noticias',
        category: 'Noticias',
        icon: Icons.newspaper_rounded,
        color: _EC.accent,
        clips: _newsClips(),
      ),
    ];

    final all = [...builtin, ...custom];
    final filtered = _selectedCategory == 'Todos'
        ? all
        : _selectedCategory == 'Mis plantillas'
            ? custom
            : all.where((t) => t.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips de categoría
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: _builtinCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final cat = _builtinCategories[i];
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? _EC.primary : _EC.card,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: selected ? _EC.primary : _EC.border),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          color: selected ? Colors.white : _EC.textMid,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          color: _EC.textLo, size: 32),
                      const SizedBox(height: 8),
                      const Text('Sin plantillas en esta categoría',
                          style: TextStyle(color: _EC.textLo, fontSize: 11),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showSaveAsTemplateDialog(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _EC.primaryLo,
                            borderRadius: BorderRadius.circular(7),
                            border:
                                Border.all(color: _EC.primary.withOpacity(0.3)),
                          ),
                          child: const Text('Crear plantilla',
                              style: TextStyle(
                                  color: _EC.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final t = filtered[i];
                    final isCustom = custom.any((c) => c.id == t.id);
                    return _AnimatedTemplateCard(
                      item: t,
                      delay: i * 40,
                      isCustom: isCustom,
                      onApply: () => _applyTemplate(ref, t),
                      onDelete: isCustom
                          ? () => ref
                              .read(customTemplatesProvider.notifier)
                              .remove(t.id)
                          : null,
                    );
                  },
                ),
        ),

        // Crear nueva plantilla
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: GestureDetector(
            onTap: () => _showSaveAsTemplateDialog(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _EC.primaryLo,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _EC.primary.withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 14, color: _EC.primary),
                  SizedBox(width: 6),
                  Text('Nueva plantilla desde editor',
                      style: TextStyle(
                          color: _EC.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── helpers clips predefinidos ──
  List<EditorClip> _welcomeClips() => [
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Título Bienvenida',
            text: '¡Bienvenido!',
            startSec: 0,
            durationSec: 8,
            trackIndex: 0,
            textColor: Colors.white,
            fontSize: 64,
            bold: true,
            x: 640,
            y: 360),
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Subtítulo',
            text: 'Estamos felices de tenerte aquí',
            startSec: 1,
            durationSec: 6,
            trackIndex: 1,
            textColor: const Color(0xFF38BDF8),
            fontSize: 28,
            x: 640,
            y: 440),
      ];

  List<EditorClip> _promoClips() => [
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Oferta Principal',
            text: '50% DESCUENTO',
            startSec: 0,
            durationSec: 10,
            trackIndex: 0,
            textColor: const Color(0xFFF59E0B),
            fontSize: 72,
            bold: true,
            x: 640,
            y: 300),
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Detalle oferta',
            text: 'Solo por hoy • Válido hasta las 6pm',
            startSec: 0.5,
            durationSec: 9,
            trackIndex: 1,
            textColor: Colors.white,
            fontSize: 24,
            x: 640,
            y: 420),
      ];

  List<EditorClip> _menuClips() => [
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Menú título',
            text: 'Menú del Día',
            startSec: 0,
            durationSec: 15,
            trackIndex: 0,
            textColor: const Color(0xFF22C55E),
            fontSize: 56,
            bold: true,
            x: 640,
            y: 200),
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Plato 1',
            text: '🍽 Sopa del día — 8.500',
            startSec: 0.5,
            durationSec: 14,
            trackIndex: 1,
            textColor: Colors.white,
            fontSize: 28,
            x: 640,
            y: 340),
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Plato 2',
            text: '🥩 Plato principal — 15.000',
            startSec: 1,
            durationSec: 13,
            trackIndex: 2,
            textColor: Colors.white,
            fontSize: 28,
            x: 640,
            y: 400),
      ];

  List<EditorClip> _newsClips() => [
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Breaking news',
            text: '📢 ÚLTIMAS NOTICIAS',
            startSec: 0,
            durationSec: 20,
            trackIndex: 0,
            textColor: Colors.white,
            fontSize: 20,
            bold: true,
            backgroundColor: '#EF4444',
            x: 640,
            y: 660),
        EditorClip(
            id: _uuid.v4(),
            type: EditorLayerType.text,
            label: 'Ticker',
            text: 'Mantente informado con las últimas actualizaciones del día',
            startSec: 0,
            durationSec: 20,
            trackIndex: 1,
            textColor: Colors.white,
            fontSize: 16,
            x: 640,
            y: 690),
      ];

  void _applyTemplate(WidgetRef ref, TemplateItem t) {
    final notifier = ref.read(editorClipsProvider.notifier);
    for (final c in t.clips) {
      final trackIdx = _findOrCreateFreeTrack(ref, c.startSec, c.durationSec);
      notifier.add(c.copyWith(id: _uuid.v4(), trackIndex: trackIdx));
    }
  }

  void _showAddClipDialog(
      BuildContext ctx, WidgetRef ref, EditorLayerType type) {
    showDialog(
      context: ctx,
      builder: (_) => _AddClipDialog(
          type: type,
          onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip)),
    );
  }

  void _showAddTextDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _AddTextDialog(
          onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip)),
    );
  }

  void _showAddImageDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _AddMediaDialog(
          type: EditorLayerType.image,
          onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip)),
    );
  }

  void _showAddVideoDialog(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (_) => _AddMediaDialog(
          type: EditorLayerType.video,
          onAdd: (clip) => ref.read(editorClipsProvider.notifier).add(clip)),
    );
  }

  void _showSaveAsTemplateDialog(BuildContext ctx, WidgetRef ref) {
    final clips = ref.read(editorClipsProvider);
    showDialog(
      context: ctx,
      builder: (_) => _SaveAsTemplateDialog(
        clips: clips,
        onSave: (name, category, icon, color) {
          ref.read(customTemplatesProvider.notifier).add(TemplateItem(
                id: _uuid.v4(),
                name: name,
                category: category,
                icon: icon,
                color: color,
                clips: List.from(clips),
              ));
        },
      ),
    );
  }
}

// =============================================================================
// ANIMATED MEDIA BUTTON
// =============================================================================

class _AnimatedMediaBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;
  final VoidCallback onTap;
  const _AnimatedMediaBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.delay,
      required this.onTap});
  @override
  State<_AnimatedMediaBtn> createState() => _AnimatedMediaBtnState();
}

class _AnimatedMediaBtnState extends State<_AnimatedMediaBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = Tween(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _opacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
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
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: _hovered ? widget.color.withOpacity(0.13) : _EC.card,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color:
                        _hovered ? widget.color.withOpacity(0.5) : _EC.border,
                    width: _hovered ? 1.5 : 1,
                  ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                              color: widget.color.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(_hovered ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(widget.icon, size: 14, color: widget.color),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.label,
                        style: TextStyle(
                            color: _hovered ? widget.color : _EC.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _hovered ? 0.125 : 0,
                      duration: const Duration(milliseconds: 130),
                      child: Icon(Icons.add_rounded,
                          size: 14,
                          color: _hovered ? widget.color : _EC.textLo),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ANIMATED TEMPLATE CARD
// =============================================================================

class _AnimatedTemplateCard extends StatefulWidget {
  final TemplateItem item;
  final int delay;
  final bool isCustom;
  final VoidCallback onApply;
  final VoidCallback? onDelete;
  const _AnimatedTemplateCard(
      {required this.item,
      required this.delay,
      required this.isCustom,
      required this.onApply,
      this.onDelete});
  @override
  State<_AnimatedTemplateCard> createState() => _AnimatedTemplateCardState();
}

class _AnimatedTemplateCardState extends State<_AnimatedTemplateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween(begin: const Offset(-0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _opacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
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
      builder: (_, __) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _hovered ? widget.item.color.withOpacity(0.1) : _EC.card,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: _hovered
                      ? widget.item.color.withOpacity(0.4)
                      : _EC.border,
                  width: _hovered ? 1.5 : 1,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                            color: widget.item.color.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          widget.item.color.withOpacity(_hovered ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.item.icon,
                        size: 16, color: widget.item.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.name,
                            style: TextStyle(
                                color:
                                    _hovered ? widget.item.color : _EC.textHi,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Text(
                            '${widget.item.clips.length} clips • ${widget.item.category}',
                            style: const TextStyle(
                                color: _EC.textMid, fontSize: 9)),
                      ],
                    ),
                  ),
                  if (widget.isCustom && widget.onDelete != null)
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 13, color: _EC.red.withOpacity(0.7)),
                      ),
                    ),
                  GestureDetector(
                    onTap: widget.onApply,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? widget.item.color
                            : widget.item.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Usar',
                          style: TextStyle(
                              color:
                                  _hovered ? Colors.white : widget.item.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
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

// =============================================================================
// DIALOG: GUARDAR COMO PLANTILLA
// =============================================================================

class _SaveAsTemplateDialog extends StatefulWidget {
  final List<EditorClip> clips;
  final void Function(String name, String category, IconData icon, Color color)
      onSave;
  const _SaveAsTemplateDialog({required this.clips, required this.onSave});
  @override
  State<_SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends State<_SaveAsTemplateDialog> {
  final _nameCtrl = TextEditingController();
  String _category = 'Bienvenida';
  IconData _icon = Icons.star_rounded;
  Color _color = _EC.primary;

  final _categories = ['Bienvenida', 'Promoción', 'Menú', 'Noticias', 'Otro'];
  final _icons = [
    Icons.star_rounded,
    Icons.waving_hand_rounded,
    Icons.local_offer_rounded,
    Icons.restaurant_menu_rounded,
    Icons.newspaper_rounded,
    Icons.celebration_rounded,
    Icons.info_rounded,
    Icons.campaign_rounded,
  ];
  final _colors = [
    _EC.primary,
    _EC.accent,
    _EC.green,
    _EC.amber,
    _EC.red,
    _EC.purple,
    const Color(0xFFEC4899),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bookmark_add_rounded,
                      size: 16, color: _EC.primary),
                  SizedBox(width: 8),
                  Text('Guardar como plantilla',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre
              const Text('Nombre',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: const TextStyle(color: _EC.textHi, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Ej: Mi plantilla de verano',
                  hintStyle: const TextStyle(color: _EC.textLo, fontSize: 11),
                  filled: true,
                  fillColor: _EC.card,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(color: _EC.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(color: _EC.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(color: _EC.primary)),
                ),
              ),
              const SizedBox(height: 12),

              // Categoría
              const Text('Categoría',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _categories.map((c) {
                  final sel = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? _EC.primary : _EC.card,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: sel ? _EC.primary : _EC.border),
                      ),
                      child: Text(c,
                          style: TextStyle(
                              color: sel ? Colors.white : _EC.textMid,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Icono
              const Text('Ícono',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((ic) {
                  final sel = ic == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: sel ? _color.withOpacity(0.2) : _EC.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? _color : _EC.border,
                            width: sel ? 2 : 1),
                      ),
                      child:
                          Icon(ic, size: 16, color: sel ? _color : _EC.textMid),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Color
              const Text('Color',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _colors.map((c) {
                  final sel = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 2.5),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: c.withOpacity(0.5), blurRadius: 6)
                              ]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Info clips
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _EC.primaryLo,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _EC.primary.withOpacity(0.2)),
                ),
                child: Text(
                    '${widget.clips.length} clips del editor serán incluidos',
                    style: const TextStyle(color: _EC.textMid, fontSize: 11)),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _EC.textMid,
                          side: const BorderSide(color: _EC.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameCtrl.text.trim().isEmpty) return;
                        widget.onSave(
                            _nameCtrl.text.trim(), _category, _icon, _color);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _EC.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text('Guardar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaAddBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MediaAddBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  State<_MediaAddBtn> createState() => _MediaAddBtnState();
}

class _MediaAddBtnState extends State<_MediaAddBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.12) : _EC.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.4) : _EC.border),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: TextStyle(
                      color: _hovered ? widget.color : _EC.textMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.add_rounded,
                  size: 14, color: _hovered ? widget.color : _EC.textLo),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TemplateCard(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.1) : _EC.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.3) : _EC.border),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(widget.icon, size: 14, color: widget.color),
              ),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(color: _EC.textMid, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CENTER: PREVIEW + CANVAS
// =============================================================================

class _CenterPanel extends ConsumerWidget {
  const _CenterPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Preview canvas
        Expanded(child: _PreviewCanvas()),
        // Below preview: clip inspector mini
        Container(
          height: 40,
          color: _EC.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer(builder: (_, ref, __) {
            final selectedId = ref.watch(selectedClipIdProvider);
            final clips = ref.watch(editorClipsProvider);
            final clip = selectedId != null
                ? clips.firstWhere((c) => c.id == selectedId,
                    orElse: () => clips.isEmpty ? null! : clips.first)
                : null;
            if (clip == null) {
              return const Center(
                  child: Text('Selecciona un clip en el timeline para editarlo',
                      style: TextStyle(color: _EC.textLo, fontSize: 11)));
            }
            return Row(
              children: [
                Icon(_clipIcon(clip.type),
                    size: 14, color: _clipColor(clip.type)),
                const SizedBox(width: 8),
                Text(clip.label,
                    style: const TextStyle(
                        color: _EC.textHi,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text(
                    '${clip.startSec.toStringAsFixed(1)}s — '
                    '${(clip.startSec + clip.durationSec).toStringAsFixed(1)}s  '
                    '(${clip.durationSec.toStringAsFixed(1)}s)',
                    style: const TextStyle(color: _EC.textMid, fontSize: 11)),
                const Spacer(),
                Text(
                    'X:${clip.x.toInt()} Y:${clip.y.toInt()} '
                    '${clip.width.toInt()}×${clip.height.toInt()}',
                    style: const TextStyle(color: _EC.textLo, fontSize: 10)),
              ],
            );
          }),
        ),
      ],
    );
  }

  IconData _clipIcon(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      case EditorLayerType.overlay:
        return Icons.layers_rounded;
    }
  }

  Color _clipColor(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return _EC.purple;
      case EditorLayerType.image:
        return _EC.accent;
      case EditorLayerType.text:
        return _EC.green;
      case EditorLayerType.audio:
        return _EC.amber;
      case EditorLayerType.overlay:
        return _EC.red;
    }
  }
}

class _PreviewCanvas extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PreviewCanvas> createState() => _PreviewCanvasState();
}

class _PreviewCanvasState extends ConsumerState<_PreviewCanvas> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final clips = ref.watch(editorClipsProvider);
    final playhead = ref.watch(playheadProvider);
    final selectedId = ref.watch(selectedClipIdProvider);

    final activeClips = clips
        .where((c) =>
            playhead >= c.startSec && playhead <= c.startSec + c.durationSec)
        .toList();

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
      },
      builder: (ctx, candidateData, rejectedData) {
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (_isDragOver)
                Container(
                  color: _EC.primary.withOpacity(0.15),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_rounded,
                            color: _EC.primary, size: 48),
                        SizedBox(height: 8),
                        Text('Suelta aquí para agregar',
                            style: TextStyle(
                                color: _EC.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    final scaleX = constraints.maxWidth / 1280;
                    final scaleY = constraints.maxHeight / 720;

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

                        // ── MODIFICACIÓN: orden de capas ──
                        // ── MODIFICACIÓN: orden de capas ──
                        ...(() {
                          final tracks = ref.read(tracksProvider);
                          final sorted = [...activeClips];
                          sorted.sort((a, b) {
                            final idxA =
                                a.trackIndex.clamp(0, tracks.length - 1);
                            final idxB =
                                b.trackIndex.clamp(0, tracks.length - 1);
                            return idxB.compareTo(idxA);
                          });
                          return sorted;
                        }())
                            .map((clip) {
                          final isSelected = clip.id == selectedId;
                          final left = (clip.x - clip.width / 2) * scaleX;
                          final top = (clip.y - clip.height / 2) * scaleY;
                          final width = clip.width * scaleX;
                          final height = clip.height * scaleY;

                          return Positioned(
                            key: ValueKey(clip.id),
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: _DraggableClip(
                              clip: clip,
                              scaleX: scaleX,
                              scaleY: scaleY,
                              isSelected: isSelected,
                              onSelect: () => ref
                                  .read(selectedClipIdProvider.notifier)
                                  .state = clip.id,
                              onMove: (dx, dy) {
                                final updated = clip.copyWith(
                                  x: (clip.x + dx / scaleX).clamp(0.0, 1280.0),
                                  y: (clip.y + dy / scaleY).clamp(0.0, 720.0),
                                );
                                ref
                                    .read(editorClipsProvider.notifier)
                                    .update(updated);
                              },
                              onResize: (dw, dh) {
                                final updated = clip.copyWith(
                                  width: (clip.width + dw / scaleX)
                                      .clamp(40.0, 1280.0),
                                  height: (clip.height + dh / scaleY)
                                      .clamp(20.0, 720.0),
                                );
                                ref
                                    .read(editorClipsProvider.notifier)
                                    .update(updated);
                              },
                            ),
                          );
                        }),

                        if (clips.isEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.video_library_rounded,
                                    color: Color(0xFF1F2D45), size: 48),
                                const SizedBox(height: 8),
                                const Text(
                                    'Agrega clips desde el panel izquierdo',
                                    style: TextStyle(
                                        color: Color(0xFF2E3D5C),
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                const Text('o arrastra archivos aquí',
                                    style: TextStyle(
                                        color: Color(0xFF1F2D45),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget para clip draggable + resizable
class _DraggableClip extends ConsumerStatefulWidget {
  final EditorClip clip;
  final double scaleX, scaleY;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(double dx, double dy) onMove;
  final void Function(double dw, double dh) onResize;

  const _DraggableClip({
    super.key,
    required this.clip,
    required this.scaleX,
    required this.scaleY,
    required this.isSelected,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });
  @override
  ConsumerState<_DraggableClip> createState() => _DraggableClipState();
}

class _DraggableClipState extends ConsumerState<_DraggableClip> {
  bool _isDragging = false;
  Offset _pointerStart = Offset.zero;
  double _startX = 0, _startY = 0;

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final scaleX = widget.scaleX;
    final scaleY = widget.scaleY;
    final isSelected = widget.isSelected;
    final w = clip.width * scaleX;
    final h = clip.height * scaleY;
    const hs = 14.0;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        debugPrint('🖱️ [Clip ${clip.label}] pointerDown @ ${e.position} '
            'selected=$isSelected scaleX=$scaleX scaleY=$scaleY '
            'clipX=${clip.x} clipY=${clip.y}');
        widget.onSelect();
        _isDragging = true;
        _pointerStart = e.position;
        _startX = clip.x;
        _startY = clip.y;
      },
      onPointerMove: (e) {
        if (!_isDragging) return;
        final dx = (e.position.dx - _pointerStart.dx) / scaleX;
        final dy = (e.position.dy - _pointerStart.dy) / scaleY;
        debugPrint('🖱️ [Clip ${clip.label}] move '
            'pos=${e.position} start=$_pointerStart '
            'dx=${dx.toStringAsFixed(1)} dy=${dy.toStringAsFixed(1)} '
            'newX=${(_startX + dx).clamp(0.0, 1280.0).toStringAsFixed(1)} '
            'newY=${(_startY + dy).clamp(0.0, 720.0).toStringAsFixed(1)}');
        ref.read(editorClipsProvider.notifier).update(clip.copyWith(
              x: (_startX + dx).clamp(0.0, 1280.0),
              y: (_startY + dy).clamp(0.0, 720.0),
            ));
      },
      onPointerUp: (e) {
        debugPrint('🖱️ [Clip ${clip.label}] pointerUp @ ${e.position}');
        _isDragging = false;
      },
      onPointerCancel: (e) {
        debugPrint('🖱️ [Clip ${clip.label}] pointerCancel');
        _isDragging = false;
      },
      child: MouseRegion(
        cursor: isSelected ? SystemMouseCursors.move : SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: _EC.primary, width: 2)
                      : Border.all(
                          color: Colors.white.withOpacity(0.06), width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: _EC.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1)
                        ]
                      : [],
                ),
                child: Opacity(
                  opacity: clip.opacity,
                  child: _renderClip(clip, scaleX, scaleY),
                ),
              ),
            ),
            // Overlay para capturar eventos sobre HtmlElementView
            if (clip.type == EditorLayerType.image ||
                clip.type == EditorLayerType.video ||
                clip.type == EditorLayerType.audio)
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),
            if (isSelected) ...[
              Positioned(
                  left: -hs / 2,
                  top: -hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeUpLeft,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, -dw, -dh, dw, dh))),
              Positioned(
                  right: -hs / 2,
                  top: -hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeUpRight,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, 0, -dh, dw, dh))),
              Positioned(
                  left: -hs / 2,
                  bottom: -hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeDownLeft,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, -dw, 0, dw, dh))),
              Positioned(
                  right: -hs / 2,
                  bottom: -hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeDownRight,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, 0, 0, dw, dh))),
              Positioned(
                  top: -hs / 2,
                  left: w / 2 - hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeUp,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, 0, -dh, 0, dh))),
              Positioned(
                  bottom: -hs / 2,
                  left: w / 2 - hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeDown,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, 0, 0, 0, dh))),
              Positioned(
                  left: -hs / 2,
                  top: h / 2 - hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeLeft,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, -dw, 0, dw, 0))),
              Positioned(
                  right: -hs / 2,
                  top: h / 2 - hs / 2,
                  child: _ResizeHandle(
                      cursor: SystemMouseCursors.resizeRight,
                      clip: clip,
                      scaleX: scaleX,
                      scaleY: scaleY,
                      onResize: (dw, dh) => _doResize(clip, 0, 0, dw, 0))),
            ],
          ],
        ),
      ),
    );
  }

  void _doResize(EditorClip clip, double dx, double dy, double dw, double dh) {
    final newW = (clip.width + dw / widget.scaleX).clamp(40.0, 1280.0);
    final newH = (clip.height + dh / widget.scaleY).clamp(20.0, 720.0);
    final newX = (clip.x + dx / widget.scaleX).clamp(0.0, 1280.0);
    final newY = (clip.y + dy / widget.scaleY).clamp(0.0, 720.0);
    debugPrint('📐 [Resize ${clip.label}] '
        'dw=$dw dh=$dh → W=${newW.toStringAsFixed(0)} H=${newH.toStringAsFixed(0)} '
        'X=${newX.toStringAsFixed(0)} Y=${newY.toStringAsFixed(0)}');
    ref
        .read(editorClipsProvider.notifier)
        .update(clip.copyWith(x: newX, y: newY, width: newW, height: newH));
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
              return html.ImageElement()
                ..src = clip.url!
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'cover'
                ..style.display = 'block'
                ..style.pointerEvents = 'none';
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
              return html.IFrameElement()
                ..style.cssText =
                    'border:none;width:100%;height:100%;pointer-events:none;'
                ..setAttribute('allow', 'autoplay')
                ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
                ..srcdoc = '<!DOCTYPE html><html><head>'
                    '<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;overflow:hidden;}'
                    'video{width:100%;height:100%;object-fit:cover;pointer-events:none;}</style></head><body>'
                    '<video src="${clip.url}" autoplay loop playsinline preload="auto"></video>'
                    '</body></html>';
            });
          } catch (_) {}
          return HtmlElementView(viewType: viewId);
        }
        return Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              const Color(0xFFA855F7).withOpacity(0.3),
              const Color(0xFFA855F7).withOpacity(0.1)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22 * sx)));

      case EditorLayerType.text:
        final bgColor = clip.backgroundColor != null
            ? Color(int.parse(clip.backgroundColor!.replaceFirst('#', '0xFF')))
            : Colors.transparent;

        final isTypewriter = clip.label.toLowerCase().contains('máquina') ||
            clip.label.toLowerCase().contains('typewriter');
        final isMarquee = clip.label.toLowerCase().contains('marquee') ||
            clip.label.toLowerCase().contains('ticker');
        final isFadeIn = clip.label.toLowerCase().contains('fade in');
        final isFadeOut = clip.label.toLowerCase().contains('fade out');
        final isSlideL = clip.label.contains('←');
        final isSlideR = clip.label.contains('→');
        final isSlideU = clip.label.contains('↑');
        final isSlideD = clip.label.contains('↓');
        final isZoomIn = clip.label.contains('Zoom In');
        final isZoomOut = clip.label.contains('Zoom Out');
        final isBounce = clip.label.contains('Bounce');
        final isPulse = clip.label.contains('Pulse');
        final isAnim = isFadeIn ||
            isFadeOut ||
            isSlideL ||
            isSlideR ||
            isSlideU ||
            isSlideD ||
            isZoomIn ||
            isZoomOut ||
            isBounce ||
            isPulse;

        Widget rawText() {
          if (isTypewriter) {
            return _TypewriterText(
              text: clip.text ?? '',
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              bold: clip.bold ?? false,
            );
          }
          if (isMarquee) {
            return _MarqueeText(
              text: clip.text ?? '',
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              bold: clip.bold ?? false,
            );
          }
          return Text(
            clip.text ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              fontWeight:
                  (clip.bold ?? false) ? FontWeight.w900 : FontWeight.w400,
              height: 1.2,
            ),
          );
        }

        final base = Container(
            color: bgColor, alignment: Alignment.center, child: rawText());

        if (!isAnim) return base;

        return Consumer(builder: (context, ref, _) {
          final playhead = ref.watch(playheadProvider);
          final elapsed =
              (playhead - clip.startSec).clamp(0.0, clip.durationSec);
          final prog = (elapsed / (clip.durationSec * 0.4)).clamp(0.0, 1.0);
          final ease = 1.0 - math.pow(1.0 - prog, 3).toDouble();

          double opacity = 1.0;
          double offX = 0, offY = 0, scale = 1.0;

          if (isFadeIn)
            opacity = (elapsed / (clip.durationSec * 0.4)).clamp(0.0, 1.0);
          if (isFadeOut)
            opacity = (1.0 - elapsed / clip.durationSec).clamp(0.0, 1.0);
          if (isSlideL) offX = (1.0 - ease) * -200;
          if (isSlideR) offX = (1.0 - ease) * 200;
          if (isSlideU) offY = (1.0 - ease) * 100;
          if (isSlideD) offY = (1.0 - ease) * -100;
          if (isZoomIn) scale = 0.2 + ease * 0.8;
          if (isZoomOut) scale = 2.0 - ease;
          if (isBounce) {
            double t = prog;
            double b;
            if (t < 1 / 2.75) {
              b = 7.5625 * t * t;
            } else if (t < 2 / 2.75) {
              t -= 1.5 / 2.75;
              b = 7.5625 * t * t + 0.75;
            } else if (t < 2.5 / 2.75) {
              t -= 2.25 / 2.75;
              b = 7.5625 * t * t + 0.9375;
            } else {
              t -= 2.625 / 2.75;
              b = 7.5625 * t * t + 0.984375;
            }
            offY = -(1.0 - b) * 50;
          }
          if (isPulse)
            scale = 0.95 + math.sin(elapsed * math.pi * 2).abs() * 0.1;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(offX, offY),
              child: Transform.scale(scale: scale, child: base),
            ),
          );
        });

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

      case EditorLayerType.audio:
        if (clip.url != null && clip.url!.isNotEmpty) {
          final viewId = 'audio-${clip.id}';
          try {
            ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
              return html.IFrameElement()
                ..style.cssText =
                    'border:none;width:100%;height:100%;pointer-events:none;'
                ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
                ..srcdoc = '<!DOCTYPE html><html><head>'
                    '<style>*{margin:0;padding:0;}body{background:#0a0f1e;width:100vw;height:100vh;'
                    'display:flex;align-items:center;justify-content:center;}'
                    'audio{width:90%;pointer-events:none;}</style></head><body>'
                    '<audio src="${clip.url}" autoplay loop></audio></body></html>';
            });
          } catch (_) {}
          return HtmlElementView(viewType: viewId);
        }
        return Container(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            child: Center(
                child: Icon(Icons.music_note_rounded,
                    color: const Color(0xFF22C55E), size: 20 * sx)));
    }
  }
}

// ── ResizeHandle con Listener absoluto ───────────────────────────────────────
class _ResizeHandle extends StatefulWidget {
  final MouseCursor cursor;
  final EditorClip clip;
  final double scaleX, scaleY;
  final void Function(double dw, double dh) onResize;
  final double width;
  final double height;

  const _ResizeHandle({
    required this.cursor,
    required this.clip,
    required this.scaleX,
    required this.scaleY,
    required this.onResize,
    this.width = 14,
    this.height = 14,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _active = false;
  Offset _start = Offset.zero;
  double _startW = 0, _startH = 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          setState(() => _active = true);
          _start = e.position;
          _startW = widget.clip.width;
          _startH = widget.clip.height;
        },
        onPointerMove: (e) {
          final dw = (e.position.dx - _start.dx);
          final dh = (e.position.dy - _start.dy);
          widget.onResize(dw, dh);
        },
        onPointerUp: (_) => setState(() => _active = false),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _active ? _EC.primary : Colors.white,
            border: Border.all(color: _EC.primary, width: 2),
            borderRadius: BorderRadius.circular(3),
            boxShadow: _active
                ? [
                    BoxShadow(
                        color: _EC.primary.withOpacity(0.6), blurRadius: 6)
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3), blurRadius: 2)
                  ],
          ),
        ),
      ),
    );
  }
}

class _SelectionHandles extends ConsumerWidget {
  final EditorClip clip;
  final double scaleX, scaleY;
  const _SelectionHandles(
      {required this.clip, required this.scaleX, required this.scaleY});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = (clip.x - clip.width / 2) * scaleX;
    final top = (clip.y - clip.height / 2) * scaleY;
    final width = clip.width * scaleX;
    final height = clip.height * scaleY;

    return Positioned(
      left: left - 4,
      top: top - 4,
      width: width + 8,
      height: height + 8,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _EC.primary, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              for (final pos in [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                Align(
                  alignment: pos,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _EC.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(1),
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
// RIGHT: PROPERTIES PANEL
// =============================================================================

class _PropertiesPanel extends ConsumerStatefulWidget {
  const _PropertiesPanel();

  @override
  ConsumerState<_PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<_PropertiesPanel> {
  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedClipIdProvider);
    final clips = ref.watch(editorClipsProvider);

    if (selectedId == null || clips.isEmpty) {
      return Container(
        color: _EC.surface,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, color: _EC.textLo, size: 32),
              SizedBox(height: 8),
              Text('Selecciona un clip\npara editar propiedades',
                  style: TextStyle(color: _EC.textLo, fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final clip = clips.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => clips.first,
    );

    return Container(
      color: _EC.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(_clipIcon(clip.type),
                    size: 14, color: _clipColor(clip.type)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(clip.label,
                        style: const TextStyle(
                            color: _EC.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () {
                    ref.read(editorClipsProvider.notifier).remove(clip.id);
                    ref.read(selectedClipIdProvider.notifier).state = null;
                  },
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 14, color: _EC.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _propDivider('Posición y tamaño'),

            // Position
            _PropRow('X', clip.x.toStringAsFixed(0),
                onChanged: (v) => _update(
                    ref, clip.copyWith(x: double.tryParse(v) ?? clip.x))),
            _PropRow('Y', clip.y.toStringAsFixed(0),
                onChanged: (v) => _update(
                    ref, clip.copyWith(y: double.tryParse(v) ?? clip.y))),
            _PropRow('Ancho', clip.width.toStringAsFixed(0),
                onChanged: (v) => _update(ref,
                    clip.copyWith(width: double.tryParse(v) ?? clip.width))),
            _PropRow('Alto', clip.height.toStringAsFixed(0),
                onChanged: (v) => _update(ref,
                    clip.copyWith(height: double.tryParse(v) ?? clip.height))),

            const SizedBox(height: 8),
            _propDivider('Tiempo'),
            _PropRow('Inicio (s)', clip.startSec.toStringAsFixed(1),
                onChanged: (v) => _update(
                    ref,
                    clip.copyWith(
                        startSec: double.tryParse(v) ?? clip.startSec))),
            _PropRow('Duración (s)', clip.durationSec.toStringAsFixed(1),
                onChanged: (v) => _update(
                    ref,
                    clip.copyWith(
                        durationSec: double.tryParse(v) ?? clip.durationSec))),

            const SizedBox(height: 8),
            _propDivider('Apariencia'),

            // Opacity slider
            const Text('Opacidad',
                style: TextStyle(color: _EC.textMid, fontSize: 10)),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbColor: _EC.primary,
                      activeTrackColor: _EC.primary,
                      inactiveTrackColor: _EC.border,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: clip.opacity,
                      min: 0,
                      max: 1,
                      onChanged: (v) => _update(ref, clip.copyWith(opacity: v)),
                    ),
                  ),
                ),
                Text('${(clip.opacity * 100).toInt()}%',
                    style: const TextStyle(color: _EC.textMid, fontSize: 10)),
              ],
            ),

            // Rotation
            const Text('Rotación',
                style: TextStyle(color: _EC.textMid, fontSize: 10)),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbColor: _EC.accent,
                      activeTrackColor: _EC.accent,
                      inactiveTrackColor: _EC.border,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: clip.rotation,
                      min: -180,
                      max: 180,
                      onChanged: (v) =>
                          _update(ref, clip.copyWith(rotation: v)),
                    ),
                  ),
                ),
                Text('${clip.rotation.toInt()}°',
                    style: const TextStyle(color: _EC.textMid, fontSize: 10)),
              ],
            ),

            // Text-specific properties
            if (clip.type == EditorLayerType.text) ...[
              const SizedBox(height: 8),
              _propDivider('Texto'),
              _PropRow(
                  'Tamaño fuente', (clip.fontSize ?? 48).toStringAsFixed(0),
                  onChanged: (v) => _update(
                      ref,
                      clip.copyWith(
                          fontSize: double.tryParse(v) ?? clip.fontSize))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Negrita',
                      style: TextStyle(color: _EC.textMid, fontSize: 10)),
                  const Spacer(),
                  Switch(
                    value: clip.bold ?? false,
                    activeColor: _EC.primary,
                    onChanged: (v) => _update(ref, clip.copyWith(bold: v)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Color de texto',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Colors.white,
                  Colors.black,
                  const Color(0xFF6366F1),
                  const Color(0xFF38BDF8),
                  const Color(0xFF22C55E),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                  const Color(0xFFA855F7),
                ]
                    .map((c) => GestureDetector(
                          onTap: () =>
                              _update(ref, clip.copyWith(textColor: c)),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: clip.textColor == c
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              if (clip.text != null) ...[
                const SizedBox(height: 8),
                const Text('Contenido',
                    style: TextStyle(color: _EC.textMid, fontSize: 10)),
                const SizedBox(height: 4),
                TextField(
                  controller: TextEditingController(text: clip.text),
                  maxLines: 3,
                  style: const TextStyle(color: _EC.textHi, fontSize: 11),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _EC.card,
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _EC.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _EC.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _EC.primary)),
                  ),
                  onChanged: (v) => _update(ref, clip.copyWith(text: v)),
                ),
              ],
            ],

            // Image/video URL
            if (clip.type == EditorLayerType.image ||
                clip.type == EditorLayerType.video) ...[
              const SizedBox(height: 8),
              _propDivider('Fuente'),
              const Text('URL del archivo',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(
                controller: TextEditingController(text: clip.url ?? ''),
                style: const TextStyle(color: _EC.textHi, fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: _EC.textLo, fontSize: 11),
                  filled: true,
                  fillColor: _EC.card,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _EC.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _EC.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: _EC.primary)),
                ),
                onChanged: (v) => _update(ref, clip.copyWith(url: v)),
              ),

              // Trim controls for video
              if (clip.type == EditorLayerType.video) ...[
                const SizedBox(height: 8),
                _propDivider('Recorte'),
                _PropRow(
                    'Recorte inicio (s)', clip.trimStart.toStringAsFixed(1),
                    onChanged: (v) => _update(
                        ref,
                        clip.copyWith(
                            trimStart: double.tryParse(v) ?? clip.trimStart))),
                _PropRow('Recorte fin (s)', clip.trimEnd.toStringAsFixed(1),
                    onChanged: (v) => _update(
                        ref,
                        clip.copyWith(
                            trimEnd: double.tryParse(v) ?? clip.trimEnd))),
              ],
            ],

            const SizedBox(height: 16),
            // Duplicate button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final newClip = clip.copyWith(
                    id: _uuid.v4(),
                    startSec: clip.startSec + clip.durationSec + 0.5,
                  );
                  ref.read(editorClipsProvider.notifier).add(newClip);
                  ref.read(selectedClipIdProvider.notifier).state = newClip.id;
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label:
                    const Text('Duplicar clip', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _EC.accent,
                  side: const BorderSide(color: _EC.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _update(WidgetRef ref, EditorClip clip) {
    ref.read(editorClipsProvider.notifier).update(clip);
  }

  Widget _propDivider(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: _EC.textMid,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: _EC.divider)),
          ],
        ),
      );

  IconData _clipIcon(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      case EditorLayerType.overlay:
        return Icons.layers_rounded;
    }
  }

  Color _clipColor(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return _EC.purple;
      case EditorLayerType.image:
        return _EC.accent;
      case EditorLayerType.text:
        return _EC.green;
      case EditorLayerType.audio:
        return _EC.amber;
      case EditorLayerType.overlay:
        return _EC.red;
    }
  }
}

class _PropRow extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _PropRow(this.label, this.value, {required this.onChanged});

  @override
  State<_PropRow> createState() => _PropRowState();
}

class _PropRowState extends State<_PropRow> {
  late TextEditingController _ctrl;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_PropRow old) {
    super.didUpdateWidget(old);
    // Solo actualiza si no tiene foco (el usuario no está escribiendo)
    if (!_hasFocus && old.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(widget.label,
                  style: const TextStyle(color: _EC.textMid, fontSize: 10))),
          Expanded(
            child: SizedBox(
              height: 28,
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() => _hasFocus = hasFocus);
                  if (!hasFocus) {
                    // Al perder foco, sincroniza si el valor externo cambió
                    if (_ctrl.text != widget.value) {
                      widget.onChanged(_ctrl.text);
                    }
                  }
                },
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: _EC.textHi, fontSize: 11),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _EC.card,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: _EC.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: _EC.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: _EC.primary)),
                  ),
                  onChanged: widget.onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TIMELINE PANEL
// =============================================================================
class _TimelinePanel extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _TimelinePanel({required this.scrollController});

  @override
  ConsumerState<_TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends ConsumerState<_TimelinePanel> {
  static const _trackH = 36.0;
  static const _labelW = 80.0;
  static const _rulerH = 24.0;

  @override
  Widget build(BuildContext context) {
    final clips = ref.watch(editorClipsProvider);
    final playhead = ref.watch(playheadProvider);
    final zoom = ref.watch(zoomProvider);
    final selectedId = ref.watch(selectedClipIdProvider);
    final tracks = ref.watch(tracksProvider);
    final total = ref.read(editorClipsProvider.notifier).totalDuration;
    final totalW = total * zoom;
    final trackH = 36.0;
    final rulerH = 24.0;
    final labelW = 82.0;

    return Container(
      color: _EC.surface,
      child: Column(
        children: [
          // ── Header ──
          Container(
            height: 32,
            color: _EC.card,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('TIMELINE',
                    style: TextStyle(
                        color: _EC.textMid,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showExportVideoDialog(context, ref, clips),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFA855F7)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(children: [
                      Icon(Icons.movie_creation_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Exportar video',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                _TLBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _showAddTrackDialog(context, ref)),
                const SizedBox(width: 4),
                _TLBtn(
                    icon: Icons.undo_rounded,
                    onTap: () {
                      ref.read(editorClipsProvider.notifier).undo();
                    }),
                const SizedBox(width: 4),
                _TLBtn(
                    icon: Icons.redo_rounded,
                    onTap: () {
                      ref.read(editorClipsProvider.notifier).redo();
                    }),
                const SizedBox(width: 4),
                _TLBtn(
                    icon: Icons.delete_sweep_rounded,
                    onTap: () {
                      for (final c in ref.read(editorClipsProvider).toList()) {
                        ref.read(editorClipsProvider.notifier).remove(c.id);
                      }
                      ref.read(selectedClipIdProvider.notifier).state = null;
                    }),
              ],
            ),
          ),

          // ── Tracks area ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Labels column — ancho fijo, scroll sincronizado
                SizedBox(
                  width: labelW,
                  child: Column(
                    children: [
                      // Ruler spacer
                      Container(
                        height: rulerH,
                        color: _EC.card,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 8),
                        child: const Text('TIME',
                            style: TextStyle(
                                color: _EC.textLo,
                                fontSize: 8,
                                letterSpacing: 0.5)),
                      ),
                      // Track labels — ReorderableListView con shrinkWrap
                      Expanded(
                        child: ReorderableListView(
                          buildDefaultDragHandles: true,
                          // En _TimelinePanelState.build, donde está el onReorder del ReorderableListView:
                          onReorder: (oldIdx, newIdx) {
                            if (newIdx > oldIdx) newIdx--;

                            final allClips = ref.read(editorClipsProvider);
                            final notifier =
                                ref.read(editorClipsProvider.notifier);

                            // Construye el nuevo estado de clips de una sola vez sin throttle
                            final updatedClips = allClips.map((clip) {
                              int newTrackIdx = clip.trackIndex;
                              if (clip.trackIndex == oldIdx) {
                                newTrackIdx = newIdx;
                              } else if (oldIdx < newIdx &&
                                  clip.trackIndex > oldIdx &&
                                  clip.trackIndex <= newIdx) {
                                newTrackIdx = clip.trackIndex - 1;
                              } else if (oldIdx > newIdx &&
                                  clip.trackIndex >= newIdx &&
                                  clip.trackIndex < oldIdx) {
                                newTrackIdx = clip.trackIndex + 1;
                              }
                              return clip.copyWith(trackIndex: newTrackIdx);
                            }).toList();

                            // Aplica todos los cambios de una sola vez al estado
                            notifier.setAll(updatedClips);

                            // Reordena los tracks visualmente
                            ref
                                .read(tracksProvider.notifier)
                                .reorder(oldIdx, newIdx);
                          },
                          proxyDecorator: (child, idx, anim) => Material(
                              color: _EC.cardHi,
                              borderRadius: BorderRadius.circular(4),
                              child: child),
                          children: tracks.asMap().entries.map((e) {
                            final i = e.key;
                            final t = e.value;
                            return SizedBox(
                              key: ValueKey(t.id),
                              height: trackH,
                              child: _TrackLabel(
                                track: t,
                                index: i,
                                onDelete: tracks.length > 1
                                    ? () => ref
                                        .read(tracksProvider.notifier)
                                        .remove(t.id)
                                    : null,
                                onRename: (name) => ref
                                    .read(tracksProvider.notifier)
                                    .rename(t.id, name),
                                onRecolor: (color) => ref
                                    .read(tracksProvider.notifier)
                                    .recolor(t.id, color),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Separator
                Container(width: 1, color: _EC.divider),

                // Scrollable timeline content
                Expanded(
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(totalW + 120, 500),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Ruler
                              _TimelineRuler(
                                zoom: zoom,
                                total: total,
                                height: rulerH,
                              ),
                              // Track rows — mismo orden que labels
                              ...tracks.asMap().entries.map((e) {
                                final i = e.key;
                                final t = e.value;
                                return _TrackRow(
                                  trackIndex: i,
                                  height: trackH,
                                  zoom: zoom,
                                  clips: clips
                                      .where((c) => c.trackIndex == i)
                                      .toList(),
                                  selectedId: selectedId,
                                  trackColor: t.color,
                                );
                              }),
                            ],
                          ),

                          // Playhead
                          Positioned(
                            left: playhead * zoom,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (d) {
                                final newPos = (playhead + d.delta.dx / zoom)
                                    .clamp(0.0, total);
                                ref.read(playheadProvider.notifier).state =
                                    newPos;
                              },
                              child: SizedBox(
                                width: 12,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 5,
                                      top: 0,
                                      bottom: 0,
                                      width: 2,
                                      child: Container(color: _EC.red),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _EC.red,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTrackDialog(BuildContext ctx, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    Color color = _EC.primary;
    final colors = [
      _EC.primary,
      _EC.accent,
      _EC.green,
      _EC.amber,
      _EC.red,
      _EC.purple,
      const Color(0xFFEC4899)
    ];

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => Dialog(
          backgroundColor: _EC.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _EC.border)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nuevo track',
                        style: TextStyle(
                            color: _EC.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 14),
                    const Text('Nombre',
                        style: TextStyle(color: _EC.textMid, fontSize: 10)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: const TextStyle(color: _EC.textHi, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Ej: Subtítulos',
                        hintStyle:
                            const TextStyle(color: _EC.textLo, fontSize: 11),
                        filled: true,
                        fillColor: _EC.card,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: _EC.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: _EC.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: const BorderSide(color: _EC.primary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Color',
                        style: TextStyle(color: _EC.textMid, fontSize: 10)),
                    const SizedBox(height: 6),
                    Wrap(
                        spacing: 8,
                        children: colors.map((c) {
                          final sel = c == color;
                          return GestureDetector(
                            onTap: () => setState(() => color = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        sel ? Colors.white : Colors.transparent,
                                    width: 2.5),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: c.withOpacity(0.5),
                                            blurRadius: 6)
                                      ]
                                    : [],
                              ),
                            ),
                          );
                        }).toList()),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _EC.textMid,
                            side: const BorderSide(color: _EC.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Cancelar'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton(
                        onPressed: () {
                          final tracks = ref.read(tracksProvider);
                          ref.read(tracksProvider.notifier).add(TrackDef(
                                id: 't${DateTime.now().millisecondsSinceEpoch}',
                                label: nameCtrl.text.trim().isEmpty
                                    ? 'Track ${tracks.length + 1}'
                                    : nameCtrl.text.trim(),
                                color: color,
                                defaultType: EditorLayerType.video,
                              ));
                          Navigator.pop(dialogCtx);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _EC.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Crear',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      )),
                    ]),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  void _showExportVideoDialog(
      BuildContext ctx, WidgetRef ref, List<EditorClip> clips) {
    showDialog(context: ctx, builder: (_) => _ExportVideoDialog(clips: clips));
  }
}

class _TimelineRuler extends StatelessWidget {
  final double zoom, total, height;
  const _TimelineRuler(
      {required this.zoom, required this.total, required this.height});

  @override
  Widget build(BuildContext context) {
    final tickEvery = zoom > 80
        ? 1
        : zoom > 40
            ? 2
            : 5;
    final ticks = (total / tickEvery).ceil() + 1;

    return Container(
      height: height,
      color: _EC.card,
      child: Stack(
        children: List.generate(ticks, (i) {
          final sec = i * tickEvery.toDouble();
          final x = sec * zoom;
          final isMajor = (i % 5 == 0);
          return Positioned(
            left: x,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 1,
                    height: isMajor ? 10 : 5,
                    color: isMajor ? _EC.textMid : _EC.textLo),
                if (isMajor)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                        '${(sec ~/ 60).toString().padLeft(2, '0')}'
                        ':${(sec % 60).toStringAsFixed(0).padLeft(2, '0')}',
                        style: const TextStyle(color: _EC.textLo, fontSize: 8)),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TrackRow extends ConsumerWidget {
  final int trackIndex;
  final double height, zoom;
  final List<EditorClip> clips;
  final String? selectedId;
  final Color trackColor;

  const _TrackRow({
    required this.trackIndex,
    required this.height,
    required this.zoom,
    required this.clips,
    required this.selectedId,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTapUp: (d) {
        ref.read(selectedClipIdProvider.notifier).state = null;
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _EC.bg,
          border: Border(bottom: BorderSide(color: _EC.divider)),
        ),
        child: Stack(
          children: clips.map((clip) {
            final left = clip.startSec * zoom;
            final w = clip.durationSec * zoom;
            final isSelected = clip.id == selectedId;

            return Positioned(
              left: left,
              top: 3,
              width: math.max(w, 20),
              height: height - 6,
              child: GestureDetector(
                onTap: () =>
                    ref.read(selectedClipIdProvider.notifier).state = clip.id,
                onHorizontalDragUpdate: (d) {
                  final newStart =
                      (clip.startSec + d.delta.dx / zoom).clamp(0.0, 9999.0);
                  ref
                      .read(editorClipsProvider.notifier)
                      .reorder(clip.id, newStart, clip.trackIndex);
                },
                child: AnimatedContainer(
                  duration: 100.ms,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? trackColor.withOpacity(0.8)
                        : trackColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : trackColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Icon(_clipIcon(clip.type),
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(clip.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _clipIcon(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      case EditorLayerType.overlay:
        return Icons.layers_rounded;
    }
  }
}

class _TLBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TLBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _EC.bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _EC.border),
          ),
          child: Icon(icon, size: 12, color: _EC.textMid),
        ),
      );
}

// =============================================================================
// DIALOGS
// =============================================================================

class _AddClipDialog extends StatefulWidget {
  final EditorLayerType type;
  final void Function(EditorClip) onAdd;
  const _AddClipDialog({required this.type, required this.onAdd});

  @override
  State<_AddClipDialog> createState() => _AddClipDialogState();
}

class _AddClipDialogState extends State<_AddClipDialog> {
  final _labelCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  double _start = 0;
  double _duration = 10;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(widget.type);
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_typeIcon(widget.type), size: 16, color: color),
                  const SizedBox(width: 8),
                  Text('Agregar ${widget.type.name}',
                      style: const TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _EC.textMid)),
                ],
              ),
              const SizedBox(height: 16),
              _dialogField('Etiqueta', _labelCtrl, 'Nombre del clip'),
              const SizedBox(height: 10),
              _dialogField('URL', _urlCtrl, 'https://...'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inicio: ${_start.toStringAsFixed(1)}s',
                          style: const TextStyle(
                              color: _EC.textMid, fontSize: 10)),
                      Slider(
                        value: _start,
                        min: 0,
                        max: 60,
                        activeColor: color,
                        inactiveColor: _EC.border,
                        onChanged: (v) => setState(() => _start = v),
                      ),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duración: ${_duration.toStringAsFixed(1)}s',
                          style: const TextStyle(
                              color: _EC.textMid, fontSize: 10)),
                      Slider(
                        value: _duration,
                        min: 1,
                        max: 60,
                        activeColor: color,
                        inactiveColor: _EC.border,
                        onChanged: (v) => setState(() => _duration = v),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onAdd(EditorClip(
                      id: _uuid.v4(),
                      type: widget.type,
                      label: _labelCtrl.text.trim().isEmpty
                          ? widget.type.name
                          : _labelCtrl.text.trim(),
                      url: _urlCtrl.text.trim(),
                      startSec: _start,
                      durationSec: _duration,
                      trackIndex: _defaultTrack(widget.type),
                      width: 1280,
                      height: 720,
                      x: 640,
                      y: 360,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar al timeline',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _EC.textMid, fontSize: 10)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: _EC.textHi, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _EC.textLo, fontSize: 11),
            filled: true,
            fillColor: _EC.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _EC.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _EC.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _EC.primary)),
          ),
        ),
      ],
    );
  }

  int _defaultTrack(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return 0;
      case EditorLayerType.image:
        return 2;
      case EditorLayerType.text:
        return 3;
      case EditorLayerType.audio:
        return 4;
      case EditorLayerType.overlay:
        return 5;
    }
  }

  Color _typeColor(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return _EC.purple;
      case EditorLayerType.image:
        return _EC.accent;
      case EditorLayerType.text:
        return _EC.green;
      case EditorLayerType.audio:
        return _EC.amber;
      case EditorLayerType.overlay:
        return _EC.red;
    }
  }

  IconData _typeIcon(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      case EditorLayerType.overlay:
        return Icons.layers_rounded;
    }
  }
}

class _AddTextDialog extends ConsumerStatefulWidget {
  final void Function(EditorClip) onAdd;
  const _AddTextDialog({required this.onAdd});

  @override
  ConsumerState<_AddTextDialog> createState() => _AddTextDialogState();
}

class _AddTextDialogState extends ConsumerState<_AddTextDialog> {
  final _labelCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  double _start = 0;
  double _duration = 8;
  double _fontSize = 48;
  Color _color = Colors.white;
  bool _bold = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_fields_rounded,
                      size: 16, color: _EC.green),
                  const SizedBox(width: 8),
                  const Text('Agregar texto',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _EC.textMid)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Etiqueta',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(
                controller: _labelCtrl,
                style: const TextStyle(color: _EC.textHi, fontSize: 12),
                decoration: _fieldDeco('Nombre del clip de texto'),
              ),
              const SizedBox(height: 10),
              const Text('Contenido del texto',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 4),
              TextField(
                controller: _textCtrl,
                maxLines: 3,
                style: const TextStyle(color: _EC.textHi, fontSize: 12),
                decoration: _fieldDeco('Escribe el texto aquí...'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tamaño: ${_fontSize.toInt()}px',
                          style: const TextStyle(
                              color: _EC.textMid, fontSize: 10)),
                      Slider(
                        value: _fontSize,
                        min: 12,
                        max: 120,
                        activeColor: _EC.green,
                        inactiveColor: _EC.border,
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ],
                  )),
                  Row(
                    children: [
                      const Text('Negrita',
                          style: TextStyle(color: _EC.textMid, fontSize: 10)),
                      Switch(
                          value: _bold,
                          activeColor: _EC.green,
                          onChanged: (v) => setState(() => _bold = v)),
                    ],
                  ),
                ],
              ),
              const Text('Color',
                  style: TextStyle(color: _EC.textMid, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  Colors.white,
                  Colors.black,
                  const Color(0xFF6366F1),
                  const Color(0xFF38BDF8),
                  const Color(0xFF22C55E),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                  const Color(0xFFA855F7),
                ]
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: _color == c
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inicio: ${_start.toStringAsFixed(1)}s',
                          style: const TextStyle(
                              color: _EC.textMid, fontSize: 10)),
                      Slider(
                        value: _start,
                        min: 0,
                        max: 60,
                        activeColor: _EC.green,
                        inactiveColor: _EC.border,
                        onChanged: (v) => setState(() => _start = v),
                      ),
                    ],
                  )),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duración: ${_duration.toStringAsFixed(1)}s',
                          style: const TextStyle(
                              color: _EC.textMid, fontSize: 10)),
                      Slider(
                        value: _duration,
                        min: 1,
                        max: 60,
                        activeColor: _EC.green,
                        inactiveColor: _EC.border,
                        onChanged: (v) => setState(() => _duration = v),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _EC.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final trackIdx =
                        _findOrCreateFreeTrack(ref, _start, _duration);
                    widget.onAdd(EditorClip(
                      id: _uuid.v4(),
                      type: EditorLayerType.text,
                      label: _labelCtrl.text.trim().isEmpty
                          ? 'Texto'
                          : _labelCtrl.text.trim(),
                      text: _textCtrl.text,
                      startSec: _start,
                      durationSec: _duration,
                      trackIndex: trackIdx,
                      textColor: _color,
                      fontSize: _fontSize,
                      bold: _bold,
                      x: 640,
                      y: 360,
                      width: 1000,
                      height: 100,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar texto',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _EC.textLo, fontSize: 11),
        filled: true,
        fillColor: _EC.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _EC.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _EC.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _EC.primary)),
      );
}

class _ExportDialog extends StatelessWidget {
  final List<EditorClip> clips;
  const _ExportDialog({required this.clips});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1018),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.upload_rounded, size: 18, color: _EC.primary),
                  SizedBox(width: 10),
                  Text('Exportar composición',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _EC.primaryLo,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _EC.primary.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${clips.length} clips en el timeline',
                        style: const TextStyle(
                            color: _EC.textHi,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        clips.map((c) => '• ${c.label}').take(5).join('\n') +
                            (clips.length > 5
                                ? '\n... y ${clips.length - 5} más'
                                : ''),
                        style: const TextStyle(
                            color: _EC.textMid, fontSize: 11, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                  'Esta composición se puede guardar como playlist '
                  'para reproducir en tus dispositivos.',
                  style:
                      TextStyle(color: _EC.textMid, fontSize: 12, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _EC.textMid,
                        side: const BorderSide(color: _EC.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Composición exportada correctamente'),
                            backgroundColor: _EC.card,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EC.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Exportar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavePlaylistDialog extends StatefulWidget {
  final List<EditorClip> clips;
  final SavedPlaylist? existingPlaylist;
  final Future<void> Function(SavedPlaylist) onSaved;
  const _SavePlaylistDialog({
    required this.clips,
    required this.onSaved,
    this.existingPlaylist,
  });

  @override
  State<_SavePlaylistDialog> createState() => _SavePlaylistDialogState();
}

class _SavePlaylistDialogState extends State<_SavePlaylistDialog> {
  late TextEditingController _nameCtrl;
  bool _saved = false;
  bool _loading = false;
  SavedPlaylist? _playlist;

  @override
  void initState() {
    super.initState();
    // Si es edición, pre-rellena el nombre
    _nameCtrl = TextEditingController(
      text: widget.existingPlaylist?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingPlaylist != null;

  void _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final currentUri = Uri.base;
    final baseUrl =
        '${currentUri.scheme}://${currentUri.host}${currentUri.hasPort ? ':${currentUri.port}' : ''}';

    // Si es edición conserva el mismo ID y viewLink
    final id = widget.existingPlaylist?.id ??
        'PL-${DateTime.now().millisecondsSinceEpoch}';
    final viewLink = widget.existingPlaylist?.viewLink ?? '$baseUrl/view/$id';

    final pl = SavedPlaylist(
      id: id,
      name: _nameCtrl.text.trim(),
      clips: List.from(widget.clips),
      createdAt: widget.existingPlaylist?.createdAt ?? DateTime.now(),
      viewLink: viewLink,
    );

    await widget.onSaved(pl);
    setState(() {
      _playlist = pl;
      _saved = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1018),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: _saved ? _savedView(context) : _saveForm(context),
        ),
      ),
    );
  }

  Widget _saveForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(_isEditing ? Icons.edit_rounded : Icons.save_rounded,
              size: 18, color: _EC.primary),
          const SizedBox(width: 10),
          Text(_isEditing ? 'Actualizar playlist' : 'Guardar playlist',
              style: const TextStyle(
                  color: _EC.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ]),
        if (_isEditing) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _EC.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _EC.amber.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: _EC.amber),
              const SizedBox(width: 6),
              const Expanded(
                  child: Text('Se actualizará la playlist existente',
                      style: TextStyle(color: _EC.amber, fontSize: 11))),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        const Text('Nombre de la playlist',
            style: TextStyle(color: _EC.textMid, fontSize: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          style: const TextStyle(color: _EC.textHi, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ej: Campaña Verano 2026',
            hintStyle: const TextStyle(color: _EC.textLo, fontSize: 12),
            filled: true,
            fillColor: _EC.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _EC.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _EC.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _EC.primary)),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _EC.primaryLo,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _EC.primary.withOpacity(0.2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.clips.length} clips incluidos',
                style: const TextStyle(
                    color: _EC.textHi,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                widget.clips.map((c) => '• ${c.label}').take(4).join('\n') +
                    (widget.clips.length > 4
                        ? '\n... y ${widget.clips.length - 4} más'
                        : ''),
                style: const TextStyle(
                    color: _EC.textMid, fontSize: 11, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
                foregroundColor: _EC.textMid,
                side: const BorderSide(color: _EC.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Cancelar'),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(_isEditing ? Icons.update_rounded : Icons.save_rounded,
                    size: 14),
            label: Text(_isEditing ? 'Actualizar' : 'Guardar',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _EC.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          )),
        ]),
      ],
    );
  }

  Widget _savedView(BuildContext context) {
    final pl = _playlist!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: _EC.green),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  _isEditing
                      ? '"${pl.name}" actualizada'
                      : '"${pl.name}" guardada',
                  style: const TextStyle(
                      color: _EC.textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 15))),
        ]),
        const SizedBox(height: 16),
        const Text('Link de visualización',
            style: TextStyle(
                color: _EC.textMid, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: _EC.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _EC.border)),
          child: Row(children: [
            const Icon(Icons.link_rounded, size: 14, color: _EC.accent),
            const SizedBox(width: 8),
            Expanded(
                child: Text(pl.viewLink,
                    style: const TextStyle(
                        color: _EC.accent,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: pl.viewLink));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Link copiado'),
                  backgroundColor: _EC.card,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 2),
                ));
              },
              child:
                  const Icon(Icons.copy_rounded, size: 14, color: _EC.textMid),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _ActionBtn(
            icon: Icons.edit_rounded,
            label: 'Seguir editando',
            color: _EC.primary,
            onTap: () => Navigator.pop(context)),
        const SizedBox(height: 8),
        _ActionBtn(
          icon: Icons.public_rounded,
          label: 'Copiar link público',
          color: _EC.amber,
          onTap: () {
            Clipboard.setData(ClipboardData(text: pl.viewLink));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Link público copiado'),
              backgroundColor: _EC.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ));
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _EC.textMid,
                  side: const BorderSide(color: _EC.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Cerrar'),
            )),
      ],
    );
  }
}

// =============================================================================
// LISTADO DE PLAYLISTS GUARDADAS
// =============================================================================
class _PlaylistsListDialog extends ConsumerStatefulWidget {
  const _PlaylistsListDialog();

  @override
  ConsumerState<_PlaylistsListDialog> createState() =>
      _PlaylistsListDialogState();
}

class _PlaylistsListDialogState extends ConsumerState<_PlaylistsListDialog> {
  String? _confirmDeleteId;

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(savedPlaylistsProvider);

    return Dialog(
      backgroundColor: const Color(0xFF0C1018),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_library_rounded,
                      size: 18, color: _EC.primary),
                  const SizedBox(width: 10),
                  const Text('Listas de reproducción',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: _EC.textMid),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_rounded, color: _EC.textLo, size: 40),
                      SizedBox(height: 10),
                      Text('No hay playlists guardadas aún',
                          style: TextStyle(color: _EC.textLo, fontSize: 12)),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 1, color: _EC.divider),
                    itemBuilder: (ctx, i) {
                      final pl = playlists[i];
                      final isConfirming = _confirmDeleteId == pl.id;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _EC.primaryLo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: _EC.primary,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pl.name,
                                      style: const TextStyle(
                                          color: _EC.textHi,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pl.clips.length} clips • ${_fmtDate(pl.createdAt)}',
                                    style: const TextStyle(
                                        color: _EC.textMid, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            if (isConfirming) ...[
                              const Text('¿Eliminar?',
                                  style:
                                      TextStyle(color: _EC.red, fontSize: 11)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  ref
                                      .read(savedPlaylistsProvider.notifier)
                                      .remove(pl.id);
                                  setState(() => _confirmDeleteId = null);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _EC.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: _EC.red.withOpacity(0.4)),
                                  ),
                                  child: const Text('Sí',
                                      style: TextStyle(
                                          color: _EC.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _confirmDeleteId = null),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _EC.card,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _EC.border),
                                  ),
                                  child: const Text('No',
                                      style: TextStyle(
                                          color: _EC.textMid, fontSize: 11)),
                                ),
                              ),
                            ] else ...[
                              _IconAction(
                                icon: Icons.play_arrow_rounded,
                                color: _EC.accent,
                                tooltip: 'Visualizar',
                                onTap: () => _visualize(context, pl),
                              ),
                              const SizedBox(width: 4),
                              _IconAction(
                                icon: Icons.edit_rounded,
                                color: _EC.primary,
                                tooltip: 'Editar',
                                onTap: () => _loadInEditor(context, pl),
                              ),
                              const SizedBox(width: 4),
                              /* _IconAction(
                                icon: Icons.link_rounded,
                                color: _EC.green,
                                tooltip: 'Copiar link',
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: pl.viewLink));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: const Text('Link copiado'),
                                    backgroundColor: _EC.card,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                              ),
                              const SizedBox(width: 4),*/
                              _IconAction(
                                icon: Icons.delete_outline_rounded,
                                color: _EC.red,
                                tooltip: 'Eliminar',
                                onTap: () =>
                                    setState(() => _confirmDeleteId = pl.id),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _EC.textMid,
                    side: const BorderSide(color: _EC.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDateAmPm(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '${day}/${month}/${d.year}  $hour:$minute $ampm';
  }

  String _fmtDate(DateTime d) => _fmtDateAmPm(d);

  void _visualize(BuildContext context, SavedPlaylist pl) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => PlaylistViewerDialog(playlist: pl),
    );
  }

  void _loadInEditor(BuildContext context, SavedPlaylist pl) {
    final notifier = ref.read(editorClipsProvider.notifier);
    // Limpia primero
    for (final c in notifier.state.toList()) {
      notifier.remove(c.id);
    }
    // Carga los clips con sus IDs originales (no genera nuevos IDs)
    for (final c in pl.clips) {
      notifier.add(c);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('"${pl.name}" cargada en el editor'),
      backgroundColor: _EC.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withOpacity(0.12) : _EC.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _hovered ? widget.color.withOpacity(0.5) : _EC.border),
            ),
            child: Icon(widget.icon, size: 14, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// Visor de playlist
class PlaylistViewerDialog extends StatefulWidget {
  final SavedPlaylist playlist;
  const PlaylistViewerDialog({required this.playlist});

  @override
  State<PlaylistViewerDialog> createState() => _PlaylistViewerDialogState();
}

class _PlaylistViewerDialogState extends State<PlaylistViewerDialog> {
  Timer? _timer;
  double _playhead = 0;
  bool _playing = false;

  double get _total => widget.playlist.clips.isEmpty
      ? 30
      : widget.playlist.clips
              .map((c) => c.startSec + c.durationSec)
              .reduce(math.max) +
          2;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (_playhead >= _total) {
          _timer?.cancel();
          setState(() {
            _playing = false;
            _playhead = 0;
          });
        } else {
          setState(() => _playhead += 0.05);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.playlist.clips
        .where((c) =>
            _playhead >= c.startSec && _playhead <= c.startSec + c.durationSec)
        .toList();

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _EC.surface,
              child: Row(
                children: [
                  const Icon(Icons.play_circle_rounded,
                      size: 16, color: _EC.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.playlist.name,
                        style: const TextStyle(
                            color: _EC.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: _EC.textMid),
                  ),
                ],
              ),
            ),

            // Canvas 16:9
            AspectRatio(
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

                    // ── MODIFICACIÓN: orden de capas ──
                    ...(() {
                      final sorted = [...active];
                      sorted.sort((a, b) {
                        return b.trackIndex.compareTo(a.trackIndex);
                      });
                      return sorted;
                    }())
                        .map((clip) => Positioned(
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
                            style: TextStyle(color: _EC.textLo, fontSize: 12)),
                      ),
                  ],
                );
              }),
            ),

            // Controls
            Container(
              color: _EC.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _playhead = 0),
                    child: const Icon(Icons.skip_previous_rounded,
                        size: 18, color: _EC.textMid),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _EC.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbColor: _EC.primary,
                        activeTrackColor: _EC.primary,
                        inactiveTrackColor: _EC.border,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                      ),
                      child: Slider(
                        value: _playhead.clamp(0, _total),
                        min: 0,
                        max: _total,
                        onChanged: (v) => setState(() => _playhead = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_playhead.toStringAsFixed(1)}s / ${_total.toStringAsFixed(1)}s',
                    style: const TextStyle(
                        color: _EC.textMid,
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              return html.ImageElement()
                ..src = clip.url!
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'cover'
                ..style.display = 'block'
                ..style.pointerEvents = 'none';
            });
          } catch (_) {}
          return Stack(children: [
            Positioned.fill(child: HtmlElementView(viewType: viewId)),
            Positioned.fill(child: Container(color: Colors.transparent)),
          ]);
        }
        return Container(
            color: _EC.accent.withOpacity(0.1),
            child: Center(
                child: Icon(Icons.image_rounded,
                    color: _EC.accent, size: 22 * sx)));

      case EditorLayerType.video:
        if (clip.url != null &&
            clip.url!.isNotEmpty &&
            !clip.url!.startsWith('file://')) {
          final viewId = 'vid-${clip.id}';
          try {
            ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
              return html.IFrameElement()
                ..style.cssText =
                    'border:none;width:100%;height:100%;pointer-events:none;'
                ..setAttribute('allow', 'autoplay')
                ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
                ..srcdoc = '''<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;overflow:hidden;}
video{width:100%;height:100%;object-fit:cover;pointer-events:none;}</style>
</head><body>
<video src="${clip.url}" autoplay loop playsinline preload="auto"></video>
</body></html>''';
            });
          } catch (_) {}
          return Stack(children: [
            Positioned.fill(child: HtmlElementView(viewType: viewId)),
            Positioned.fill(child: Container(color: Colors.transparent)),
          ]);
        }
        return Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              const Color(0xFFA855F7).withOpacity(0.3),
              const Color(0xFFA855F7).withOpacity(0.1)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22 * sx)));

      case EditorLayerType.text:
        final bgColor = clip.backgroundColor != null
            ? Color(int.parse(clip.backgroundColor!.replaceFirst('#', '0xFF')))
            : Colors.transparent;

        final isTypewriter = clip.label.toLowerCase().contains('máquina') ||
            clip.label.toLowerCase().contains('typewriter');
        final isMarquee = clip.label.toLowerCase().contains('marquee') ||
            clip.label.toLowerCase().contains('ticker');
        final isFadeIn = clip.label.toLowerCase().contains('fade in');
        final isFadeOut = clip.label.toLowerCase().contains('fade out');
        final isSlideL = clip.label.contains('←');
        final isSlideR = clip.label.contains('→');
        final isSlideU = clip.label.contains('↑');
        final isSlideD = clip.label.contains('↓');
        final isZoomIn = clip.label.contains('Zoom In');
        final isZoomOut = clip.label.contains('Zoom Out');
        final isBounce = clip.label.contains('Bounce');
        final isPulse = clip.label.contains('Pulse');
        final isAnim = isFadeIn ||
            isFadeOut ||
            isSlideL ||
            isSlideR ||
            isSlideU ||
            isSlideD ||
            isZoomIn ||
            isZoomOut ||
            isBounce ||
            isPulse;

        Widget rawText() {
          if (isTypewriter) {
            return _TypewriterText(
              text: clip.text ?? '',
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              bold: clip.bold ?? false,
            );
          }
          if (isMarquee) {
            return _MarqueeText(
              text: clip.text ?? '',
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              bold: clip.bold ?? false,
            );
          }
          return Text(
            clip.text ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: clip.textColor ?? Colors.white,
              fontSize: (clip.fontSize ?? 48) * sx,
              fontWeight:
                  (clip.bold ?? false) ? FontWeight.w900 : FontWeight.w400,
              height: 1.2,
            ),
          );
        }

        final base = Container(
            color: bgColor, alignment: Alignment.center, child: rawText());

        if (!isAnim) return base;

        // Usa _playhead que es el estado local del visualizador
        final elapsed =
            (_playhead - clip.startSec).clamp(0.0, clip.durationSec);
        final prog = (elapsed / (clip.durationSec * 0.4)).clamp(0.0, 1.0);
        final ease = 1.0 - math.pow(1.0 - prog, 3).toDouble();

        double opacity = 1.0;
        double offX = 0, offY = 0, scale = 1.0;

        if (isFadeIn)
          opacity = (elapsed / (clip.durationSec * 0.4)).clamp(0.0, 1.0);
        if (isFadeOut)
          opacity = (1.0 - elapsed / clip.durationSec).clamp(0.0, 1.0);
        if (isSlideL) offX = (1.0 - ease) * -200;
        if (isSlideR) offX = (1.0 - ease) * 200;
        if (isSlideU) offY = (1.0 - ease) * 100;
        if (isSlideD) offY = (1.0 - ease) * -100;
        if (isZoomIn) scale = 0.2 + ease * 0.8;
        if (isZoomOut) scale = 2.0 - ease;
        if (isBounce) {
          double t = prog;
          double b;
          if (t < 1 / 2.75) {
            b = 7.5625 * t * t;
          } else if (t < 2 / 2.75) {
            t -= 1.5 / 2.75;
            b = 7.5625 * t * t + 0.75;
          } else if (t < 2.5 / 2.75) {
            t -= 2.25 / 2.75;
            b = 7.5625 * t * t + 0.9375;
          } else {
            t -= 2.625 / 2.75;
            b = 7.5625 * t * t + 0.984375;
          }
          offY = -(1.0 - b) * 50;
        }
        if (isPulse) scale = 0.95 + math.sin(elapsed * math.pi * 2).abs() * 0.1;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(offX, offY),
            child: Transform.scale(scale: scale, child: base),
          ),
        );

      case EditorLayerType.overlay:
        return Container(
          decoration: BoxDecoration(
            color: _EC.amber.withOpacity(0.15),
            border:
                Border.all(color: _EC.amber.withOpacity(0.4), width: 2 * sx),
          ),
          child: Center(
              child:
                  Icon(Icons.layers_rounded, color: _EC.amber, size: 20 * sx)),
        );

      case EditorLayerType.audio:
        return Container(
          color: _EC.green.withOpacity(0.1),
          child: Center(
              child: Icon(Icons.music_note_rounded,
                  color: _EC.green, size: 20 * sx)),
        );
    }
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.12) : _EC.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hovered ? widget.color.withOpacity(0.5) : _EC.border),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: widget.color),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: TextStyle(
                      color: _hovered ? widget.color : _EC.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: _hovered ? widget.color : _EC.textLo),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider para biblioteca de medios desde Firestore
final mediaLibraryProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    yield [];
    return;
  }

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final companyId =
      (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;

  Stream<QuerySnapshot> stream;

  if (companyId != null) {
    stream = FirebaseFirestore.instance
        .collection('media_library')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance.collection('media_library').snapshots();
  }

  yield* stream.map((snap) {
    final list = snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
    list.sort((a, b) {
      final aDate = a['createdAt'];
      final bDate = b['createdAt'];
      if (aDate == null || bDate == null) return 0;
      return (bDate as Timestamp).compareTo(aDate as Timestamp);
    });
    return list;
  });
});

class _AddMediaDialog extends ConsumerStatefulWidget {
  final EditorLayerType type;
  final void Function(EditorClip) onAdd;
  const _AddMediaDialog({required this.type, required this.onAdd});

  @override
  ConsumerState<_AddMediaDialog> createState() => _AddMediaDialogState();
}

class _AddMediaDialogState extends ConsumerState<_AddMediaDialog>
    with SingleTickerProviderStateMixin {
  final _labelCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  double _start = 0;
  double _duration = 10;
  bool _loading = false;
  String? _fileName;
  String? _blobUrl;
  late TabController _tabs;
  String _libFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  List<String> get _allowedExtensions {
    switch (widget.type) {
      case EditorLayerType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];
      case EditorLayerType.video:
        return ['mp4', 'mov', 'avi', 'webm', 'mkv'];
      case EditorLayerType.audio:
        return ['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a'];
      default:
        return ['jpg', 'jpeg', 'png'];
    }
  }

  String get _mimePrefix {
    switch (widget.type) {
      case EditorLayerType.image:
        return 'image/';
      case EditorLayerType.video:
        return 'video/';
      case EditorLayerType.audio:
        return 'audio/';
      default:
        return 'image/';
    }
  }

  double _uploadProgress = 0;

  String get _libTypeFilter {
    switch (widget.type) {
      case EditorLayerType.image:
        return 'image';
      case EditorLayerType.video:
        return 'video';
      case EditorLayerType.audio:
        return 'audio';
      default:
        return 'image';
    }
  }

  Future<void> _pickFile() async {
    setState(() => _loading = true);
    try {
      debugPrint('📁 [FilePicker] Abriendo selector...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        debugPrint('📁 [FilePicker] Cancelado por el usuario');
        setState(() => _loading = false);
        return;
      }
      final file = result.files.first;
      debugPrint(
          '📁 [FilePicker] Archivo: ${file.name}, size: ${file.size} bytes, bytes null: ${file.bytes == null}');
      if (file.bytes == null) {
        debugPrint('❌ [FilePicker] bytes es null en Flutter Web');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudieron leer los bytes del archivo'),
            backgroundColor: _EC.red,
            behavior: SnackBarBehavior.floating));
        setState(() => _loading = false);
        return;
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      setState(() {
        _fileName = fileName;
        _uploadProgress = 0.01;
      });
      final storageUrl = await _uploadToStorage(file.bytes!, fileName);
      if (storageUrl != null) {
        debugPrint('✅ [Storage] URL obtenida: $storageUrl');
        await _saveToLibrary(file.name, storageUrl);
        setState(() {
          _blobUrl = null;
          _urlCtrl.text = storageUrl;
          _uploadProgress = 1.0;
          if (_labelCtrl.text.isEmpty)
            _labelCtrl.text = file.name.split('.').first;
        });
      } else {
        debugPrint('❌ [Storage] _uploadToStorage retornó null');
        setState(() {
          _fileName = null;
          _uploadProgress = 0;
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error al subir a Firebase Storage. Ver consola.'),
              backgroundColor: _EC.red,
              behavior: SnackBarBehavior.floating));
      }
    } catch (e, stack) {
      debugPrint('❌ [_pickFile] Exception: $e');
      debugPrint('$stack');
      setState(() {
        _fileName = null;
        _uploadProgress = 0;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _EC.red,
            behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<String?> _uploadToStorage(List<int> bytes, String fileName) async {
    try {
      debugPrint('☁️ [Storage] Iniciando upload REST: $fileName');

      setState(() => _uploadProgress = 0.01);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('❌ [Storage] Usuario no autenticado');
        return null;
      }

      final token = await user.getIdToken(true);

      // ⚠️ COLOCA TU BUCKET REAL
      const bucket = 'estilista-7a538.appspot.com';

      final path = 'media_library/images/$fileName';

      final uploadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=media&name=${Uri.encodeComponent(path)}';

      debugPrint('☁️ [Storage] URL: $uploadUrl');

      final mimeType = _getMimeType(fileName);

      final response = await html.HttpRequest.request(
        uploadUrl,
        method: 'POST',
        requestHeaders: {
          'Authorization': 'Bearer $token',
          'Content-Type': mimeType,
        },
        sendData: Uint8List.fromList(bytes),
      );

      debugPrint('☁️ [Storage] STATUS: ${response.status}');
      debugPrint('☁️ [Storage] RESPONSE: ${response.responseText}');

      if (response.status == 200) {
        setState(() => _uploadProgress = 1.0);

        final encodedName = Uri.encodeComponent(path);

        final downloadUrl =
            'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedName?alt=media';

        debugPrint('✅ [Storage] downloadURL: $downloadUrl');

        return downloadUrl;
      }

      debugPrint('❌ [Storage] Error HTTP');

      return null;
    } catch (e, stack) {
      debugPrint('❌ [Storage] Exception: $e');
      debugPrint('$stack');

      if (mounted) {
        setState(() => _uploadProgress = 0);
      }

      return null;
    }
  }
/*
Future<String?> _uploadToStorage(List<int> bytes, String fileName) async {
  try {
    debugPrint('☁️ [Storage] Iniciando upload: $fileName (${bytes.length} bytes)');
    setState(() => _uploadProgress = 0.01);
    final storageRef = _getStorageRef(fileName);
    final mimeType = _getMimeType(fileName);
    debugPrint('☁️ [Storage] Ref path: ${storageRef.fullPath}, mime: $mimeType');

    firebase_storage.UploadTask uploadTask;

    // En Flutter Web, putBlob es más confiable que putData
    try {
      final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
      debugPrint('☁️ [Storage] Usando putBlob (web)');
      uploadTask = storageRef.putBlob(
        blob,
        firebase_storage.SettableMetadata(contentType: mimeType),
      );
    } catch (e) {
      debugPrint('⚠️ [Storage] putBlob falló ($e), usando putData');
      uploadTask = storageRef.putData(
        Uint8List.fromList(bytes),
        firebase_storage.SettableMetadata(contentType: mimeType),
      );
    }

    uploadTask.snapshotEvents.listen(
      (snapshot) {
        debugPrint('☁️ [Storage] Progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} state:${snapshot.state}');
        if (snapshot.totalBytes > 0 && mounted) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() => _uploadProgress = progress.clamp(0.01, 0.99));
        }
      },
      onError: (e) => debugPrint('❌ [Storage] snapshotEvents error: $e'),
    );

    debugPrint('☁️ [Storage] Esperando await uploadTask...');
    final snapshot = await uploadTask;
    debugPrint('☁️ [Storage] Upload completo, state: ${snapshot.state}');
    final downloadUrl = await snapshot.ref.getDownloadURL();
    debugPrint('✅ [Storage] downloadURL: $downloadUrl');
    if (mounted) setState(() => _uploadProgress = 1.0);
    return downloadUrl;
  } catch (e, stack) {
    debugPrint('❌ [Storage] Exception: $e');
    debugPrint('$stack');
    if (mounted) setState(() => _uploadProgress = 0);
    return null;
  }
}*/

  firebase_storage.Reference _getStorageRef(String fileName) {
    final folder = widget.type == EditorLayerType.image
        ? 'images'
        : widget.type == EditorLayerType.video
            ? 'videos'
            : widget.type == EditorLayerType.audio
                ? 'audio'
                : 'files';
    return firebase_storage.FirebaseStorage.instance
        .ref()
        .child('media_library/$folder/$fileName');
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  Future<void> _saveToLibrary(String name, String url) async {
    try {
      debugPrint('🗄️ [Firestore] Guardando en media_library: $name');
      final uid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('🗄️ [Firestore] UID: $uid');
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final companyId =
          (userDoc.data() as Map<String, dynamic>?)?['companyId'] as String?;
      debugPrint('🗄️ [Firestore] companyId: $companyId');
      await FirebaseFirestore.instance.collection('media_library').add({
        'name': name,
        'url': url,
        'type': _libTypeFilter,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [Firestore] Guardado correctamente');
    } catch (e, stack) {
      debugPrint('❌ [Firestore] Exception: $e');
      debugPrint('$stack');
    }
  }

  void _useFromLibrary(Map<String, dynamic> item) {
    setState(() {
      _urlCtrl.text = item['url'] ?? '';
      _blobUrl = null;
      _fileName = item['name'];
      if (_labelCtrl.text.isEmpty) {
        _labelCtrl.text = item['name'] ?? '';
      }
    });
    _tabs.animateTo(0);
  }

  Color get _color {
    switch (widget.type) {
      case EditorLayerType.image:
        return _EC.accent;
      case EditorLayerType.video:
        return _EC.purple;
      case EditorLayerType.audio:
        return _EC.green;
      default:
        return _EC.accent;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  String get _label {
    switch (widget.type) {
      case EditorLayerType.image:
        return 'imagen';
      case EditorLayerType.video:
        return 'video';
      case EditorLayerType.audio:
        return 'audio';
      default:
        return 'archivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(mediaLibraryProvider);

    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 680,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Icon(_icon, size: 16, color: _color),
                const SizedBox(width: 8),
                Text('Agregar $_label',
                    style: const TextStyle(
                        color: _EC.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: _EC.textMid)),
              ]),
              const SizedBox(height: 14),

              // Tabs: Subir / Biblioteca
              Container(
                decoration: BoxDecoration(
                    color: _EC.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _EC.border)),
                child: TabBar(
                  controller: _tabs,
                  labelColor: _color,
                  unselectedLabelColor: _EC.textMid,
                  indicatorColor: _color,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Subir archivo / URL'),
                    Tab(text: 'Biblioteca'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tab content
              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // ── TAB 1: Subir ──
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Etiqueta
                          const Text('Etiqueta',
                              style:
                                  TextStyle(color: _EC.textMid, fontSize: 10)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _labelCtrl,
                            style: const TextStyle(
                                color: _EC.textHi, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Nombre del clip',
                              hintStyle: const TextStyle(
                                  color: _EC.textLo, fontSize: 11),
                              filled: true,
                              fillColor: _EC.card,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide:
                                      const BorderSide(color: _EC.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide:
                                      const BorderSide(color: _EC.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide: BorderSide(color: _color)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Selector de archivo
                          GestureDetector(
                            onTap: _loading ? null : _pickFile,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: _EC.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _fileName != null
                                          ? _color.withOpacity(0.5)
                                          : _EC.border,
                                      width: _fileName != null ? 1.5 : 1)),
                              child: _loading
                                  ? Column(children: [
                                      SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: _color)),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _uploadProgress > 0
                                              ? _uploadProgress
                                              : null,
                                          backgroundColor: _EC.border,
                                          valueColor:
                                              AlwaysStoppedAnimation(_color),
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                          _uploadProgress > 0
                                              ? 'Subiendo ${(_uploadProgress * 100).toInt()}%...'
                                              : 'Procesando...',
                                          style: TextStyle(
                                              color: _color, fontSize: 10)),
                                    ])
                                  : Column(children: [
                                      Icon(
                                          _fileName != null
                                              ? Icons.check_circle_rounded
                                              : Icons.upload_file_rounded,
                                          color: _fileName != null
                                              ? _color
                                              : _EC.textMid,
                                          size: 26),
                                      const SizedBox(height: 5),
                                      Text(_fileName ?? 'Seleccionar archivo',
                                          style: TextStyle(
                                              color: _fileName != null
                                                  ? _color
                                                  : _EC.textMid,
                                              fontSize: 11,
                                              fontWeight: _fileName != null
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                      if (_fileName == null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                            _allowedExtensions
                                                .map((e) => e.toUpperCase())
                                                .join(', '),
                                            style: const TextStyle(
                                                color: _EC.textLo,
                                                fontSize: 9)),
                                        const SizedBox(height: 2),
                                        Text(
                                            '✅ Se sube a Firebase Storage automáticamente',
                                            style: TextStyle(
                                                color: _color.withOpacity(0.7),
                                                fontSize: 9)),
                                      ],
                                    ]),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // O URL
                          const Text('O pega una URL',
                              style:
                                  TextStyle(color: _EC.textMid, fontSize: 10)),

                          // Preview de imagen o video
                          if (_urlCtrl.text.isNotEmpty || _blobUrl != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: widget.type == EditorLayerType.image
                                    ? Image.network(
                                        _blobUrl ?? _urlCtrl.text,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            color: _EC.card,
                                            child: Center(
                                                child: Icon(
                                                    Icons.broken_image_rounded,
                                                    color: _color,
                                                    size: 32))),
                                      )
                                    : widget.type == EditorLayerType.video
                                        ? Builder(builder: (_) {
                                            final viewId =
                                                'preview-vid-${(_blobUrl ?? _urlCtrl.text).hashCode}';
                                            try {
                                              ui_web.platformViewRegistry
                                                  .registerViewFactory(viewId,
                                                      (int id) {
                                                final iframe = html
                                                    .IFrameElement()
                                                  ..style.cssText =
                                                      'border:none;width:100%;height:100%;'
                                                  ..setAttribute('sandbox',
                                                      'allow-scripts allow-same-origin')
                                                  ..srcdoc =
                                                      '''<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;overflow:hidden;}
video{width:100%;height:100%;object-fit:cover;}</style></head><body>
<video src="${_blobUrl ?? _urlCtrl.text}" muted playsinline preload="metadata"
  onloadedmetadata="this.currentTime=1"></video></body></html>''';
                                                return iframe;
                                              });
                                            } catch (_) {}
                                            return HtmlElementView(
                                                viewType: viewId);
                                          })
                                        : widget.type == EditorLayerType.audio
                                            ? _AudioLibraryCard(
                                                url: _blobUrl ?? _urlCtrl.text,
                                                color: _color,
                                                name: _labelCtrl.text
                                                        .trim()
                                                        .isEmpty
                                                    ? 'Audio'
                                                    : _labelCtrl.text.trim(),
                                              )
                                            : Container(
                                                color: _EC.card,
                                                child: Center(
                                                    child: Icon(_icon,
                                                        color: _color,
                                                        size: 32))),
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // O URL

                          const SizedBox(height: 4),
                          TextField(
                            controller: _urlCtrl,
                            style: const TextStyle(
                                color: _EC.textHi, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'https://...',
                              hintStyle: const TextStyle(
                                  color: _EC.textLo, fontSize: 11),
                              filled: true,
                              fillColor: _EC.card,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide:
                                      const BorderSide(color: _EC.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide:
                                      const BorderSide(color: _EC.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(7),
                                  borderSide: BorderSide(color: _color)),
                            ),
                            onChanged: (_) => setState(() {
                              _fileName = null;
                              _blobUrl = null;
                            }),
                          ),
                          const SizedBox(height: 10),

                          // Tiempos
                          Row(children: [
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Inicio: ${_start.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                        color: _EC.textMid, fontSize: 10)),
                                Slider(
                                    value: _start,
                                    min: 0,
                                    max: 60,
                                    activeColor: _color,
                                    inactiveColor: _EC.border,
                                    onChanged: (v) =>
                                        setState(() => _start = v)),
                              ],
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Duración: ${_duration.toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                        color: _EC.textMid, fontSize: 10)),
                                Slider(
                                    value: _duration,
                                    min: 1,
                                    max: 60,
                                    activeColor: _color,
                                    inactiveColor: _EC.border,
                                    onChanged: (v) =>
                                        setState(() => _duration = v)),
                              ],
                            )),
                          ]),
                        ],
                      ),
                    ),

                    // ── TAB 2: Biblioteca ──
                    libraryAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _EC.primary)),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(
                                  color: _EC.red, fontSize: 11))),
                      data: (items) {
                        // Filtra por tipo compatible
                        final filtered = items.where((item) {
                          final t = item['type'] ?? '';
                          if (widget.type == EditorLayerType.image)
                            return t == 'image';
                          if (widget.type == EditorLayerType.video)
                            return t == 'video';
                          if (widget.type == EditorLayerType.audio)
                            return t == 'audio';
                          return true;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                              child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icon, color: _EC.textLo, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                  'Sin $_label en la biblioteca.\nSube uno primero.',
                                  style: const TextStyle(
                                      color: _EC.textLo, fontSize: 11),
                                  textAlign: TextAlign.center),
                            ],
                          ));
                        }

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.1),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['name'] ?? '';
                            final url = item['url'] ?? '';
                            final type = item['type'] ?? '';
                            final isSelected = _urlCtrl.text == url;

                            return GestureDetector(
                              onTap: () => _useFromLibrary(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? _color.withOpacity(0.15)
                                        : _EC.card,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isSelected ? _color : _EC.border,
                                        width: isSelected ? 2 : 1)),
                                child: Column(children: [
                                  Expanded(
                                      child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(7)),
                                    child: type == 'image' &&
                                            url.isNotEmpty &&
                                            !url.startsWith('blob:')
                                        ? Image.network(url,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    color: _EC.surface,
                                                    child: Icon(_icon,
                                                        color: _color,
                                                        size: 24)))
                                        : type == 'video' && url.isNotEmpty
                                            ? Builder(builder: (_) {
                                                final viewId =
                                                    'lib-vid-${url.hashCode}';
                                                try {
                                                  ui_web.platformViewRegistry
                                                      .registerViewFactory(
                                                          viewId, (int id) {
                                                    return html.IFrameElement()
                                                      ..style.cssText =
                                                          'border:none;width:100%;height:100%;pointer-events:none;'
                                                      ..setAttribute('sandbox',
                                                          'allow-scripts allow-same-origin')
                                                      ..srcdoc =
                                                          '''<!DOCTYPE html><html><head>
<style>*{margin:0;padding:0;}body{background:#000;width:100vw;height:100vh;overflow:hidden;}
video{width:100%;height:100%;object-fit:cover;}</style></head><body>
<video src="$url" muted playsinline preload="metadata"
  onloadedmetadata="this.currentTime=2"></video></body></html>''';
                                                  });
                                                } catch (_) {}
                                                return Stack(children: [
                                                  Positioned.fill(
                                                      child: HtmlElementView(
                                                          viewType: viewId)),
                                                  Positioned.fill(
                                                      child: Container(
                                                          color: Colors
                                                              .transparent)),
                                                ]);
                                              })
                                            : type == 'audio' && url.isNotEmpty
                                                ? _AudioLibraryCard(
                                                    url: url,
                                                    color: _color,
                                                    name: name)
                                                : Container(
                                                    color: _EC.surface,
                                                    child: Center(
                                                        child: Icon(_icon,
                                                            color: _color,
                                                            size: 24))),
                                  )),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: isSelected
                                                ? _color
                                                : _EC.textMid,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: _color.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text('Seleccionado',
                                          style: TextStyle(
                                              color: _color,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Botón agregar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0),
                  onPressed: () {
                    final url = _blobUrl ?? _urlCtrl.text.trim();
                    final trackIdx =
                        _findOrCreateFreeTrack(ref, _start, _duration);
                    widget.onAdd(EditorClip(
                      id: _uuid.v4(),
                      type: widget.type,
                      label: _labelCtrl.text.trim().isEmpty
                          ? _label
                          : _labelCtrl.text.trim(),
                      url: url.isEmpty ? null : url,
                      startSec: _start,
                      durationSec: _duration,
                      trackIndex: trackIdx,
                      width: widget.type == EditorLayerType.audio ? 1280 : 640,
                      height: widget.type == EditorLayerType.audio ? 80 : 360,
                      x: 640,
                      y: widget.type == EditorLayerType.audio ? 680 : 360,
                    ));
                    Navigator.pop(context);
                  },
                  child: Text('Agregar $_label',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
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
// ANIMATION LIBRARY DIALOG
// =============================================================================

enum ClipAnimation {
  fadeIn,
  fadeOut,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  zoomIn,
  zoomOut,
  bounce,
  pulse,
  typewriter,
  marquee,
}

extension ClipAnimationExt on ClipAnimation {
  String get label {
    switch (this) {
      case ClipAnimation.fadeIn:
        return 'Fade In';
      case ClipAnimation.fadeOut:
        return 'Fade Out';
      case ClipAnimation.slideLeft:
        return 'Slide ← Izquierda';
      case ClipAnimation.slideRight:
        return 'Slide → Derecha';
      case ClipAnimation.slideUp:
        return 'Slide ↑ Arriba';
      case ClipAnimation.slideDown:
        return 'Slide ↓ Abajo';
      case ClipAnimation.zoomIn:
        return 'Zoom In';
      case ClipAnimation.zoomOut:
        return 'Zoom Out';
      case ClipAnimation.bounce:
        return 'Bounce';
      case ClipAnimation.pulse:
        return 'Pulse';
      case ClipAnimation.typewriter:
        return 'Máquina de escribir';
      case ClipAnimation.marquee:
        return 'Marquee / Ticker';
    }
  }

  IconData get icon {
    switch (this) {
      case ClipAnimation.fadeIn:
      case ClipAnimation.fadeOut:
        return Icons.opacity_rounded;
      case ClipAnimation.slideLeft:
      case ClipAnimation.slideRight:
        return Icons.swap_horiz_rounded;
      case ClipAnimation.slideUp:
      case ClipAnimation.slideDown:
        return Icons.swap_vert_rounded;
      case ClipAnimation.zoomIn:
      case ClipAnimation.zoomOut:
        return Icons.zoom_in_rounded;
      case ClipAnimation.bounce:
        return Icons.expand_rounded;
      case ClipAnimation.pulse:
        return Icons.favorite_rounded;
      case ClipAnimation.typewriter:
        return Icons.keyboard_rounded;
      case ClipAnimation.marquee:
        return Icons.linear_scale_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ClipAnimation.fadeIn:
      case ClipAnimation.fadeOut:
        return const Color(0xFF6366F1);
      case ClipAnimation.slideLeft:
      case ClipAnimation.slideRight:
        return const Color(0xFF38BDF8);
      case ClipAnimation.slideUp:
      case ClipAnimation.slideDown:
        return const Color(0xFF22C55E);
      case ClipAnimation.zoomIn:
      case ClipAnimation.zoomOut:
        return const Color(0xFFA855F7);
      case ClipAnimation.bounce:
        return const Color(0xFFF59E0B);
      case ClipAnimation.pulse:
        return const Color(0xFFEF4444);
      case ClipAnimation.typewriter:
        return const Color(0xFF38BDF8);
      case ClipAnimation.marquee:
        return const Color(0xFFEC4899);
    }
  }

  String get category {
    switch (this) {
      case ClipAnimation.fadeIn:
      case ClipAnimation.fadeOut:
        return 'Opacidad';
      case ClipAnimation.slideLeft:
      case ClipAnimation.slideRight:
      case ClipAnimation.slideUp:
      case ClipAnimation.slideDown:
        return 'Deslizamiento';
      case ClipAnimation.zoomIn:
      case ClipAnimation.zoomOut:
        return 'Escala';
      case ClipAnimation.bounce:
      case ClipAnimation.pulse:
        return 'Atención';
      case ClipAnimation.typewriter:
      case ClipAnimation.marquee:
        return 'Texto';
    }
  }
}

class _AnimationLibraryDialog extends ConsumerStatefulWidget {
  final void Function(EditorClip) onAdd;
  const _AnimationLibraryDialog({required this.onAdd});
  @override
  ConsumerState<_AnimationLibraryDialog> createState() =>
      _AnimationLibraryDialogState();
}

class _AnimationLibraryDialogState
    extends ConsumerState<_AnimationLibraryDialog> {
  ClipAnimation? _selected;
  String _filterCat = 'Todos';
  final _textCtrl = TextEditingController(text: '¡Tu texto aquí!');
  double _duration = 5;
  double _start = 0;

  final _cats = [
    'Todos',
    'Opacidad',
    'Deslizamiento',
    'Escala',
    'Atención',
    'Texto'
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  List<ClipAnimation> get _filtered => ClipAnimation.values
      .where((a) => _filterCat == 'Todos' || a.category == _filterCat)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Color(0xFFEC4899)),
                  const SizedBox(width: 8),
                  const Text('Biblioteca de Animaciones',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _EC.textMid)),
                ],
              ),
              const SizedBox(height: 14),

              // Filtros de categoría
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final cat = _cats[i];
                    final sel = cat == _filterCat;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _filterCat = cat;
                        _selected = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? _EC.primary : _EC.card,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: sel ? _EC.primary : _EC.border),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                color: sel ? Colors.white : _EC.textMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Grid de animaciones
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filtered.map((anim) {
                  final sel = _selected == anim;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = anim),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 110,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sel ? anim.color.withOpacity(0.15) : _EC.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? anim.color : _EC.border,
                            width: sel ? 2 : 1),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: anim.color.withOpacity(0.2),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: anim.color.withOpacity(sel ? 0.25 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(anim.icon, size: 18, color: anim.color),
                          ),
                          const SizedBox(height: 6),
                          Text(anim.label,
                              style: TextStyle(
                                  color: sel ? anim.color : _EC.textMid,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 2),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_selected != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selected!.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _selected!.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configurar: ${_selected!.label}',
                          style: TextStyle(
                              color: _selected!.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      // Texto
                      const Text('Texto',
                          style: TextStyle(color: _EC.textMid, fontSize: 10)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: _EC.textHi, fontSize: 12),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _EC.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(color: _EC.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(color: _EC.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: BorderSide(color: _selected!.color)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inicio: ${_start.toStringAsFixed(1)}s',
                                  style: const TextStyle(
                                      color: _EC.textMid, fontSize: 10)),
                              Slider(
                                value: _start,
                                min: 0,
                                max: 30,
                                activeColor: _selected!.color,
                                inactiveColor: _EC.border,
                                onChanged: (v) => setState(() => _start = v),
                              ),
                            ],
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duración: ${_duration.toStringAsFixed(1)}s',
                                  style: const TextStyle(
                                      color: _EC.textMid, fontSize: 10)),
                              Slider(
                                value: _duration,
                                min: 1,
                                max: 30,
                                activeColor: _selected!.color,
                                inactiveColor: _EC.border,
                                onChanged: (v) => setState(() => _duration = v),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _EC.textMid,
                          side: const BorderSide(color: _EC.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selected == null
                          ? null
                          : () {
                              final anim = _selected!;
                              final trackIdx = _findOrCreateFreeTrack(
                                  ref, _start, _duration);
                              widget.onAdd(EditorClip(
                                id: _uuid.v4(),
                                type: EditorLayerType.text,
                                label: '${anim.label}: ${_textCtrl.text}',
                                text: _textCtrl.text,
                                startSec: _start,
                                durationSec: _duration,
                                trackIndex: trackIdx,
                                textColor: Colors.white,
                                fontSize: 48,
                                bold: false,
                                x: 640,
                                y: 360,
                                width: 1000,
                                height: 120,
                                backgroundColor: anim == ClipAnimation.marquee
                                    ? '#000000'
                                    : null,
                              ));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Animación "${anim.label}" agregada al timeline'),
                                backgroundColor: anim.color.withOpacity(0.9),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Agregar al timeline',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _selected?.color ?? _EC.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Typewriter animation widget
class _TypewriterText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final bool bold;
  const _TypewriterText(
      {required this.text,
      required this.color,
      required this.fontSize,
      required this.bold});
  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _count = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_count < widget.text.length)
        setState(() => _count++);
      else
        _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
          child: Text(
        widget.text.substring(0, _count),
        style: TextStyle(
            color: widget.color,
            fontSize: widget.fontSize,
            fontWeight: widget.bold ? FontWeight.w900 : FontWeight.w400),
      ));
}

// Marquee/ticker animation widget
class _MarqueeText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final bool bold;
  const _MarqueeText(
      {required this.text,
      required this.color,
      required this.fontSize,
      required this.bold});
  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _anim = Tween(begin: 1.0, end: -1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
          child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => FractionalTranslation(
          translation: Offset(_anim.value, 0),
          child: Text(widget.text,
              style: TextStyle(
                  color: widget.color,
                  fontSize: widget.fontSize,
                  fontWeight: widget.bold ? FontWeight.w900 : FontWeight.w400),
              maxLines: 1),
        ),
      ));
}

// Track personalizado
class TrackDef {
  final String id;
  final String label;
  final Color color;
  final EditorLayerType defaultType;

  const TrackDef({
    required this.id,
    required this.label,
    required this.color,
    required this.defaultType,
  });

  TrackDef copyWith({String? label, Color? color}) => TrackDef(
        id: id,
        label: label ?? this.label,
        color: color ?? this.color,
        defaultType: defaultType,
      );
}

final tracksProvider =
    StateNotifierProvider<TracksNotifier, List<TrackDef>>((ref) {
  return TracksNotifier();
});

class TracksNotifier extends StateNotifier<List<TrackDef>> {
  TracksNotifier()
      : super([
          TrackDef(
              id: 't0',
              label: 'Video 1',
              color: _EC.track1,
              defaultType: EditorLayerType.video),
          TrackDef(
              id: 't1',
              label: 'Video 2',
              color: _EC.track2,
              defaultType: EditorLayerType.video),
          TrackDef(
              id: 't2',
              label: 'Imagen',
              color: _EC.track3,
              defaultType: EditorLayerType.image),
          TrackDef(
              id: 't3',
              label: 'Texto',
              color: _EC.track4,
              defaultType: EditorLayerType.text),
          TrackDef(
              id: 't4',
              label: 'Audio',
              color: _EC.track5,
              defaultType: EditorLayerType.audio),
          TrackDef(
              id: 't5',
              label: 'Overlay',
              color: _EC.red,
              defaultType: EditorLayerType.overlay),
        ]);

  void add(TrackDef t) => state = [...state, t];

  void remove(String id) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    state = state.where((t) => t.id != id).toList();
  }

  void reorder(int oldIdx, int newIdx) {
    final list = [...state];
    final item = list.removeAt(oldIdx);
    list.insert(newIdx, item);
    state = list;
  }

  void rename(String id, String newLabel) {
    state =
        state.map((t) => t.id == id ? t.copyWith(label: newLabel) : t).toList();
  }

  void recolor(String id, Color color) {
    state =
        state.map((t) => t.id == id ? t.copyWith(color: color) : t).toList();
  }
}

class _TrackLabel extends ConsumerStatefulWidget {
  final TrackDef track;
  final int index;
  final VoidCallback? onDelete;
  final void Function(String) onRename;
  final void Function(Color) onRecolor;
  const _TrackLabel(
      {super.key,
      required this.track,
      required this.index,
      this.onDelete,
      required this.onRename,
      required this.onRecolor});

  @override
  ConsumerState<_TrackLabel> createState() => _TrackLabelState();
}

class _TrackLabelState extends ConsumerState<_TrackLabel> {
  bool _hovered = false;
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.track.label);
  }

  @override
  void didUpdateWidget(_TrackLabel old) {
    super.didUpdateWidget(old);
    if (old.track.label != widget.track.label) {
      _ctrl.text = widget.track.label;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData _iconForType(EditorLayerType t) {
    switch (t) {
      case EditorLayerType.video:
        return Icons.videocam_rounded;
      case EditorLayerType.image:
        return Icons.image_rounded;
      case EditorLayerType.text:
        return Icons.text_fields_rounded;
      case EditorLayerType.audio:
        return Icons.music_note_rounded;
      case EditorLayerType.overlay:
        return Icons.layers_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 36,
        decoration: BoxDecoration(
          color: _hovered ? widget.track.color.withOpacity(0.08) : _EC.surface,
          border: Border(bottom: BorderSide(color: _EC.divider)),
        ),
        child: Row(
          children: [
            // Drag handle — 20px fijo
            const SizedBox(
              width: 20,
              child: Icon(Icons.drag_indicator_rounded,
                  size: 13, color: _EC.textLo),
            ),

            // Color bar — tap para cambiar color
            GestureDetector(
              onTap: () => _showColorPicker(context),
              child: Tooltip(
                message: 'Cambiar color',
                child: Container(
                  width: 4,
                  height: 22,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: widget.track.color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: widget.track.color.withOpacity(0.4),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),

            // Ícono del tipo con color
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: widget.track.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                _iconForType(widget.track.defaultType),
                size: 11,
                color: widget.track.color,
              ),
            ),

            // Label — editable con doble click
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: const TextStyle(
                          color: _EC.textHi,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        final val = v.trim();
                        if (val.isNotEmpty) widget.onRename(val);
                        setState(() => _editing = false);
                      },
                      onTapOutside: (_) {
                        widget.onRename(_ctrl.text.trim().isEmpty
                            ? widget.track.label
                            : _ctrl.text.trim());
                        setState(() => _editing = false);
                      },
                    )
                  : GestureDetector(
                      onDoubleTap: () => setState(() => _editing = true),
                      child: Text(
                        widget.track.label,
                        style: TextStyle(
                          color: _hovered ? widget.track.color : _EC.textMid,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
            ),

            // Botón eliminar — solo visible en hover
            AnimatedOpacity(
              opacity: _hovered && widget.onDelete != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _EC.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      const Icon(Icons.close_rounded, size: 10, color: _EC.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext ctx) {
    final colors = [
      _EC.track1,
      _EC.track2,
      _EC.track3,
      _EC.track4,
      _EC.track5,
      _EC.red,
      _EC.purple,
      const Color(0xFFEC4899),
      _EC.accent,
      _EC.green,
      const Color(0xFF0EA5E9),
      const Color(0xFFD97706),
    ];
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: _EC.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _EC.border)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(_iconForType(widget.track.defaultType),
                  size: 14, color: widget.track.color),
              const SizedBox(width: 8),
              Text('Color: ${widget.track.label}',
                  style: const TextStyle(
                      color: _EC.textHi,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors
                  .map((c) => GestureDetector(
                        onTap: () {
                          widget.onRecolor(c);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: c == widget.track.color
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5),
                            boxShadow: c == widget.track.color
                                ? [
                                    BoxShadow(
                                        color: c.withOpacity(0.5),
                                        blurRadius: 8)
                                  ]
                                : [],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ExportVideoDialog extends StatefulWidget {
  final List<EditorClip> clips;
  const _ExportVideoDialog({required this.clips});

  @override
  State<_ExportVideoDialog> createState() => _ExportVideoDialogState();
}

class _ExportVideoDialogState extends State<_ExportVideoDialog> {
  String _resolution = '1280x720';
  String _format = 'WebM';
  double _fps = 30;
  bool _exporting = false;
  double _progress = 0;
  bool _done = false;
  String _statusMsg = '';

  final _resolutions = ['1920x1080', '1280x720', '854x480', '640x360'];
  // En browser solo WebM es universal; MP4 solo en Safari
  final _formats = ['WebM', 'MP4 (Safari)'];

  int get _width => int.parse(_resolution.split('x')[0]);
  int get _height => int.parse(_resolution.split('x')[1]);

  double get _totalDuration {
    if (widget.clips.isEmpty) return 10;
    return widget.clips.map((c) => c.startSec + c.durationSec).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _EC.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.movie_creation_rounded,
                    size: 18, color: Color(0xFFEC4899)),
                const SizedBox(width: 10),
                const Text('Exportar como video',
                    style: TextStyle(
                        color: _EC.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const Spacer(),
                if (!_exporting)
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _EC.textMid)),
              ]),
              const SizedBox(height: 20),
              if (!_exporting && !_done) ...[
                // Resolución
                const Text('Resolución',
                    style: TextStyle(color: _EC.textMid, fontSize: 10)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _resolutions.map((r) {
                    final sel = r == _resolution;
                    return GestureDetector(
                      onTap: () => setState(() => _resolution = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: sel ? _EC.primary : _EC.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? _EC.primary : _EC.border)),
                        child: Text(r,
                            style: TextStyle(
                                color: sel ? Colors.white : _EC.textMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Formato
                const Text('Formato',
                    style: TextStyle(color: _EC.textMid, fontSize: 10)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _formats.map((f) {
                    final sel = f == _format;
                    return GestureDetector(
                      onTap: () => setState(() => _format = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: sel ? _EC.purple : _EC.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? _EC.purple : _EC.border)),
                        child: Text(f,
                            style: TextStyle(
                                color: sel ? Colors.white : _EC.textMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // FPS
                Row(children: [
                  const Text('FPS',
                      style: TextStyle(color: _EC.textMid, fontSize: 10)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                          trackHeight: 2,
                          thumbColor: _EC.accent,
                          activeTrackColor: _EC.accent,
                          inactiveTrackColor: _EC.border,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6)),
                      child: Slider(
                          value: _fps,
                          min: 15,
                          max: 60,
                          divisions: 3,
                          onChanged: (v) => setState(() => _fps = v)),
                    ),
                  ),
                  Text('${_fps.toInt()} fps',
                      style: const TextStyle(color: _EC.textMid, fontSize: 10)),
                ]),
                const SizedBox(height: 12),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _EC.primaryLo,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _EC.primary.withOpacity(0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${widget.clips.length} clips  •  '
                          '$_resolution  •  ${_fps.toInt()} fps  •  '
                          '${_totalDuration.toStringAsFixed(1)}s',
                          style: const TextStyle(
                              color: _EC.textHi,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text(
                          '✅ Video real descargable (.webm) usando '
                          'canvas.captureStream() + MediaRecorder.\n'
                          'Chrome → WebM/VP9  •  Safari → MP4/H264\n'
                          'Compatible con VLC, navegadores y la mayoría '
                          'de reproductores.',
                          style: TextStyle(
                              color: _EC.textMid, fontSize: 10, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startExport,
                    icon: const Icon(Icons.movie_creation_rounded, size: 14),
                    label: const Text('Exportar video',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ],
              if (_exporting) ...[
                Row(children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFEC4899)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Renderizando video...',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: _EC.border,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFEC4899)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_statusMsg,
                    style: const TextStyle(color: _EC.textMid, fontSize: 11)),
              ],
              if (_done) ...[
                const Row(children: [
                  Icon(Icons.check_circle_rounded, size: 20, color: _EC.green),
                  SizedBox(width: 10),
                  Text('¡Video listo!',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _EC.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _EC.green.withOpacity(0.3))),
                  child: const Text(
                      'El video se descargó automáticamente a tu carpeta '
                      'de Descargas como archivo .webm.\n\n'
                      'Puedes abrirlo en Chrome, Firefox, VLC o '
                      'convertirlo a MP4 con Handbrake si lo necesitas.',
                      style: TextStyle(
                          color: _EC.textMid, fontSize: 11, height: 1.5)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _EC.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: const Text('Cerrar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startExport() async {
    if (widget.clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No hay clips para exportar'),
          backgroundColor: _EC.red));
      return;
    }

    setState(() {
      _exporting = true;
      _progress = 0;
      _statusMsg = 'Iniciando renderizado...';
    });

    try {
      await _renderAndDownload();
    } catch (e) {
      if (mounted) {
        setState(() => _exporting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al exportar: $e'), backgroundColor: _EC.red));
      }
    }
  }

  Future<void> _renderAndDownload() async {
    final totalSec = _totalDuration;
    final fpsInt = _fps.toInt();
    final totalFrames = (totalSec * fpsInt).ceil();
    final mimeType = html.MediaRecorder.isTypeSupported('video/webm;codecs=vp9')
        ? 'video/webm;codecs=vp9'
        : html.MediaRecorder.isTypeSupported('video/mp4')
            ? 'video/mp4'
            : 'video/webm';
    final ext = mimeType.contains('mp4') ? 'mp4' : 'webm';

    // ── 1. Crea un <canvas> oculto en el DOM ──────────────────────
    final canvas = html.CanvasElement(width: _width, height: _height);
    canvas.style
      ..position = 'fixed'
      ..top = '-9999px'
      ..left = '-9999px'
      ..opacity = '0'
      ..pointerEvents = 'none';
    html.document.body!.append(canvas);
    final ctx2d = canvas.context2D;

    // ── 2. Arranca MediaRecorder sobre el stream del canvas ────────
    final stream = canvas.captureStream(fpsInt.toDouble());
    final recorder =
        html.MediaRecorder(stream, <String, dynamic>{'mimeType': mimeType});
    final chunks = <html.Blob>[];

    recorder.addEventListener('dataavailable', (html.Event e) {
      final be = e as html.BlobEvent;
      if (be.data != null && be.data!.size > 0) chunks.add(be.data!);
    });

    final completer = Completer<void>();
    recorder.addEventListener('stop', (_) => completer.complete());
    recorder.start();

    // ── 3. Renderiza frame a frame ─────────────────────────────────
    for (int frame = 0; frame < totalFrames; frame++) {
      final timeSec = frame / fpsInt;

      // Fondo
      ctx2d.fillStyle = '#0A0F1E';
      ctx2d.fillRect(0, 0, _width, _height);

      // Clips activos en este instante
      final active = widget.clips
          .where((c) =>
              timeSec >= c.startSec && timeSec <= c.startSec + c.durationSec)
          .toList();

      for (final clip in active) {
        _renderClipToCanvas(ctx2d, clip, timeSec);
      }

      // Actualiza progreso cada 10 frames
      if (frame % 10 == 0 && mounted) {
        setState(() {
          _progress = frame / totalFrames;
          _statusMsg = 'Frame $frame / $totalFrames  '
              '(${(timeSec).toStringAsFixed(1)}s)';
        });
        // Cede el hilo para que Flutter pueda repintar
        await Future.delayed(Duration.zero);
      }
    }

    // ── 4. Para el recorder y espera el blob ──────────────────────
    recorder.stop();
    await completer.future;

    // ── 5. Descarga el archivo ─────────────────────────────────────
    final blob = html.Blob(chunks, mimeType);
    final url = html.Url.createObjectUrl(blob);
    final ts = DateTime.now().millisecondsSinceEpoch;
    html.AnchorElement(href: url)
      ..setAttribute('download', 'playlist_$ts.$ext')
      ..click();
    html.Url.revokeObjectUrl(url);

    // ── 6. Limpieza ───────────────────────────────────────────────
    canvas.remove();

    if (mounted)
      setState(() {
        _exporting = false;
        _done = true;
      });
  }

  /// Renderiza un EditorClip sobre el CanvasRenderingContext2D nativo
  void _renderClipToCanvas(
      html.CanvasRenderingContext2D ctx, EditorClip clip, double timeSec) {
    final sx = _width / 1280;
    final sy = _height / 720;
    final left = (clip.x - clip.width / 2) * sx;
    final top = (clip.y - clip.height / 2) * sy;
    final width = clip.width * sx;
    final height = clip.height * sy;

    ctx.save();
    ctx.globalAlpha = clip.opacity;

    switch (clip.type) {
      case EditorLayerType.text:
        // Fondo del texto si existe
        if (clip.backgroundColor != null) {
          ctx.fillStyle = clip.backgroundColor!;
          ctx.fillRect(left, top, width, height);
        }
        // Texto
        final color = clip.textColor != null
            ? '#${clip.textColor!.value.toRadixString(16).substring(2)}'
            : '#FFFFFF';
        final fSize = ((clip.fontSize ?? 48) * sx).toInt();
        final weight = (clip.bold ?? false) ? '900' : '400';
        ctx.font = '$weight ${fSize}px Inter, sans-serif';
        ctx.fillStyle = color;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';

        // Máquina de escribir: solo muestra chars hasta timeSec
        String displayText = clip.text ?? '';
        if (clip.label.startsWith('Máquina')) {
          final elapsed = timeSec - clip.startSec;
          final chars = (elapsed * 12).floor().clamp(0, displayText.length);
          displayText = displayText.substring(0, chars);
        }
        // Marquee: desplaza el texto horizontalmente
        if (clip.label.startsWith('Marquee')) {
          final elapsed = timeSec - clip.startSec;
          final offset = (elapsed / clip.durationSec) * (_width + width);
          ctx.translate(_width - offset, top + height / 2);
          ctx.fillText(displayText, 0, 0);
          ctx.restore();
          return;
        }

        // Fade in/out
        if (clip.label.startsWith('Fade In')) {
          final t =
              ((timeSec - clip.startSec) / math.min(clip.durationSec, 0.8))
                  .clamp(0.0, 1.0);
          ctx.globalAlpha = clip.opacity * t;
        }
        if (clip.label.startsWith('Fade Out')) {
          final elapsed = timeSec - clip.startSec;
          final t =
              (1.0 - elapsed / math.max(clip.durationSec, 0.1)).clamp(0.0, 1.0);
          ctx.globalAlpha = clip.opacity * t;
        }

        // Slide animations
        double offX = 0, offY = 0;
        final prog = math.min(1.0,
            (timeSec - clip.startSec) / math.min(clip.durationSec * 0.4, 1.0));
        final ease = 1.0 - math.pow(1.0 - prog, 3).toDouble();
        if (clip.label.startsWith('Slide ← ')) offX = (1.0 - ease) * -_width;
        if (clip.label.startsWith('Slide → ')) offX = (1.0 - ease) * _width;
        if (clip.label.startsWith('Slide ↑')) offY = (1.0 - ease) * _height;
        if (clip.label.startsWith('Slide ↓')) offY = (1.0 - ease) * -_height;

        // Zoom
        if (clip.label.startsWith('Zoom In')) {
          final s = 0.2 + ease * 0.8;
          ctx.translate(left + width / 2, top + height / 2);
          ctx.scale(s, s);
          ctx.fillText(displayText, 0, 0);
          ctx.restore();
          return;
        }
        if (clip.label.startsWith('Zoom Out')) {
          final s = 2.0 - ease * 1.0;
          ctx.translate(left + width / 2, top + height / 2);
          ctx.scale(s, s);
          ctx.fillText(displayText, 0, 0);
          ctx.restore();
          return;
        }

        // Bounce
        if (clip.label.startsWith('Bounce')) {
          final b = _bounceEase(prog);
          offY = -(1.0 - b) * height * 0.5;
        }
        // Pulse
        if (clip.label.startsWith('Pulse')) {
          final p = math.sin((timeSec - clip.startSec) * math.pi * 2).abs();
          ctx.translate(left + width / 2, top + height / 2);
          ctx.scale(0.95 + p * 0.1, 0.95 + p * 0.1);
          ctx.fillText(displayText, 0, 0);
          ctx.restore();
          return;
        }

        ctx.fillText(
            displayText, left + width / 2 + offX, top + height / 2 + offY);
        break;

      case EditorLayerType.image:
        // Dibuja imagen si hay URL cargada (blob: o https:)
        if (clip.url != null &&
            clip.url!.isNotEmpty &&
            !clip.url!.startsWith('file://')) {
          // Usamos un ImageElement ya cacheado
          final img = _imageCache.putIfAbsent(clip.url!, () {
            final el = html.ImageElement()
              ..src = clip.url!
              ..crossOrigin = 'anonymous';
            return el;
          });
          try {
            ctx.drawImageScaled(img, left, top, width, height);
          } catch (_) {
            // Imagen no cargada aún: placeholder
            ctx.fillStyle = '#1E3A5F';
            ctx.fillRect(left, top, width, height);
          }
        } else {
          ctx.fillStyle = '#0D2137';
          ctx.fillRect(left, top, width, height);
          ctx.fillStyle = '#38BDF8';
          ctx.font = '${(16 * sx).toInt()}px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText('🖼 ${clip.label}', left + width / 2, top + height / 2);
        }
        break;

      case EditorLayerType.video:
        // Placeholder visual (video real requiere servidor/FFmpeg)
        ctx.fillStyle = '#1A0A2E';
        ctx.fillRect(left, top, width, height);
        ctx.fillStyle = '#A855F7';
        ctx.font = '${(14 * sx).toInt()}px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('▶ ${clip.label}', left + width / 2, top + height / 2);
        break;

      case EditorLayerType.overlay:
        ctx.strokeStyle = '#F59E0B';
        ctx.lineWidth = 2 * sx;
        ctx.strokeRect(left, top, width, height);
        ctx.fillStyle = 'rgba(245,158,11,0.12)';
        ctx.fillRect(left, top, width, height);
        break;

      case EditorLayerType.audio:
        // El audio no tiene representación visual en el video
        break;
    }

    ctx.restore();
  }

  double _bounceEase(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    }
    if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    }
    t -= 2.625 / 2.75;
    return 7.5625 * t * t + 0.984375;
  }
}

// Cache global de imágenes para el renderizado
final _imageCache = <String, html.ImageElement>{};

// =============================================================================
// TV COLOMBIA EN VIVO — Dialog con canales nacionales
// =============================================================================

class _TVChannel {
  final String name;
  final String logo;
  final Color color;
  final String embedUrl; // URL directa para iframe
  final String youtubeChannelId;
  final String description;

  const _TVChannel({
    required this.name,
    required this.logo,
    required this.color,
    required this.embedUrl,
    required this.youtubeChannelId,
    required this.description,
  });
}

class _TVColombiaDialog extends ConsumerStatefulWidget {
  final void Function(EditorClip) onAdd;
  const _TVColombiaDialog({required this.onAdd});

  @override
  ConsumerState<_TVColombiaDialog> createState() => _TVColombiaDialogState();
}

class _TVColombiaDialogState extends ConsumerState<_TVColombiaDialog> {
  double _previewScale = 1.0; // nuevo campo de estado
  static const _channels = [
    _TVChannel(
      name: 'Señal Colombia',
      logo: '🇨🇴',
      color: Color(0xFF007A33),
      embedUrl:
          'https://streaming.rtvc.gov.co/TV_Senal_Colombia_live/smil:live.smil/playlist.m3u8',
      youtubeChannelId: 'UCY3WPKPVHM0xYsGqhGKkHcQ',
      description: 'Canal público cultural · RTVC',
    ),
    _TVChannel(
      name: 'Canal Institucional',
      logo: '🏛',
      color: Color(0xFF064E8C),
      embedUrl:
          'https://streaming.rtvc.gov.co/TV_CanalInstitucional_live/smil:live.smil/playlist.m3u8',
      youtubeChannelId: 'UCLpRFLGJNzFMzrp0A2KHDOQ',
      description: 'Canal público del Estado · RTVC',
    ),
    _TVChannel(
      name: 'RT En Español',
      logo: '🏙',
      color: Color(0xFF6B21A8),
      embedUrl: 'https://rt-esp.rttv.com/live/rtesp/playlist.m3u8',
      youtubeChannelId: 'UCO2yELJy1kMImYJhbwZzJqQ',
      description: 'RT En Español',
    ),
    _TVChannel(
      name: 'RedBull',
      logo: '🌊',
      color: Color(0xFF0EA5E9),
      embedUrl:
          'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      youtubeChannelId: '',
      description: 'RedBull TV Colombia',
    ),
  ];
  _TVChannel? _selected;
  double _start = 0;
  double _duration = 30;
  String _getViewId(_TVChannel ch) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'tv-yt-${ch.youtubeChannelId}-$ts';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _EC.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _EC.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 620,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(children: [
                  const Icon(Icons.tv_rounded,
                      size: 16, color: Color(0xFFEC4899)),
                  const SizedBox(width: 8),
                  const Text('TV Colombia en Vivo',
                      style: TextStyle(
                          color: _EC.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: _EC.textMid),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text(
                    'Selecciona un canal para previsualizar y agregarlo al timeline.',
                    style: TextStyle(color: _EC.textMid, fontSize: 11)),
                const SizedBox(height: 14),

                // ── Grid de canales ──────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _channels.map((ch) {
                    final sel = _selected?.name == ch.name;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = ch),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sel ? ch.color.withOpacity(0.15) : _EC.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel ? ch.color : _EC.border,
                              width: sel ? 2 : 1),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: ch.color.withOpacity(0.25),
                                      blurRadius: 10)
                                ]
                              : [],
                        ),
                        child: Row(children: [
                          Text(ch.logo, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ch.name,
                                  style: TextStyle(
                                      color: sel ? ch.color : _EC.textHi,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(ch.description,
                                  style: const TextStyle(
                                      color: _EC.textMid, fontSize: 8),
                                  maxLines: 2),
                            ],
                          )),
                          if (sel)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: ch.color, shape: BoxShape.circle),
                            ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),

                // ── Preview ──────────────────────────────────────────
                if (_selected != null) ...[
                  const SizedBox(height: 14),
                  // Preview: thumbnail + botón abrir YouTube
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _selected!.color.withOpacity(0.4),
                            width: 1.5)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _YoutubeEmbedView(
                          key: ValueKey(_selected!.name),
                          viewId: _getViewId(_selected!),
                          channelId: _selected!.youtubeChannelId,
                          channelName: _selected!.name,
                          embedUrl: _selected!.embedUrl, // ← agrega esto
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tiempos
                  Row(children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Inicio en timeline: ${_start.toStringAsFixed(1)}s',
                            style: const TextStyle(
                                color: _EC.textMid, fontSize: 10)),
                        Slider(
                          value: _start,
                          min: 0,
                          max: 120,
                          activeColor: _selected!.color,
                          inactiveColor: _EC.border,
                          onChanged: (v) => setState(() => _start = v),
                        ),
                      ],
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duración: ${_duration.toStringAsFixed(0)}s',
                            style: const TextStyle(
                                color: _EC.textMid, fontSize: 10)),
                        Slider(
                          value: _duration,
                          min: 5,
                          max: 3600,
                          activeColor: _selected!.color,
                          inactiveColor: _EC.border,
                          onChanged: (v) => setState(() => _duration = v),
                        ),
                      ],
                    )),
                  ]),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _EC.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _EC.amber.withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: _EC.amber),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(
                        'La señal en vivo requiere conexión a internet. '
                        'El clip abrirá YouTube al reproducirse.',
                        style: TextStyle(
                            color: _EC.amber, fontSize: 10, height: 1.4),
                      )),
                    ]),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Botones ──────────────────────────────────────────
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _EC.textMid,
                        side: const BorderSide(color: _EC.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: const Text('Cancelar'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton.icon(
                    // ← AQUÍ ESTÁ EL FIX PRINCIPAL
                    onPressed: _selected == null
                        ? null
                        : () {
                            final ch = _selected!;
                            final trackIdx =
                                _findOrCreateFreeTrack(ref, _start, _duration);
                            widget.onAdd(EditorClip(
                              id: _uuid.v4(),
                              type: EditorLayerType.video,
                              label: ch.name,
                              url: ch.embedUrl,
                              startSec: _start,
                              durationSec: _duration,
                              trackIndex: trackIdx,
                              x: 640,
                              y: 360,
                              width: 1280,
                              height: 720,
                            ));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('📺 ${ch.name} agregado al timeline'),
                              backgroundColor: ch.color.withOpacity(0.9),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Agregar al timeline',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selected?.color ?? const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reemplaza también _YoutubeEmbedView y _YoutubeEmbedViewState
// por esta versión simplificada (ya no se usa iframe, no se necesita) ──

// Reemplaza _YoutubeEmbedView y _getViewId completamente por esto:

// viewId único por canal + timestamp para forzar recreación
String _getViewId(_TVChannel ch) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  return 'tv-yt-${ch.youtubeChannelId}-$ts';
}

class _YoutubeEmbedView extends StatefulWidget {
  final String viewId;
  final String channelId;
  final String channelName;
  final String embedUrl; // ← nuevo campo

  const _YoutubeEmbedView({
    super.key,
    required this.viewId,
    required this.channelId,
    required this.channelName,
    required this.embedUrl,
  });

  @override
  State<_YoutubeEmbedView> createState() => _YoutubeEmbedViewState();
}

class _YoutubeEmbedViewState extends State<_YoutubeEmbedView> {
  @override
  void initState() {
    super.initState();

    final hlsUrl = widget.embedUrl; // ya es la URL M3U8 directa
    final channelName = widget.channelName;

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#000; width:100vw; height:100vh; overflow:hidden;
         font-family:sans-serif; display:flex; align-items:center; justify-content:center; }
  video { width:100%; height:100%; object-fit:contain; background:#000; }
  #msg { color:#fff; text-align:center; padding:24px; }
  .title { font-size:18px; font-weight:700; margin-bottom:8px; }
  .sub { font-size:12px; color:rgba(255,255,255,0.6); margin-bottom:16px; }
  .badge { display:inline-block; padding:4px 12px; background:#22C55E;
           border-radius:20px; font-size:11px; font-weight:700; margin-bottom:14px; }
  .err { background:#EF4444; }
  a.btn { display:inline-block; padding:8px 18px; margin:4px;
          background:rgba(255,255,255,0.15); border-radius:6px;
          color:#fff; text-decoration:none; font-size:12px;
          border:1px solid rgba(255,255,255,0.3); cursor:pointer; }
  a.btn:hover { background:rgba(255,255,255,0.28); }
</style>
</head>
<body>
<div id="root" style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;">
  <div id="msg">
    <div class="title">⏳ Cargando $channelName...</div>
    <div class="sub">Iniciando stream HLS</div>
  </div>
</div>

<script>
const HLS_URL = "$hlsUrl";
const CH_NAME = "$channelName";
const root    = document.getElementById('root');
const msg     = document.getElementById('msg');

function showError(detail) {
  msg.innerHTML = \`
    <span class="badge err">❌ Sin señal</span>
    <div class="title">\${CH_NAME}</div>
    <div class="sub">\${detail}</div>
    <a href="\${HLS_URL}" target="_blank" class="btn">🔗 Abrir stream directo</a>
  \`;
}

function startHLS() {
  const video = document.createElement('video');
  video.controls = true;
  video.autoplay = true;
  video.style.cssText = 'width:100%;height:100%;object-fit:contain;background:#000;';

  if (typeof Hls !== 'undefined' && Hls.isSupported()) {
    const hls = new Hls({
      enableWorker: false,
      lowLatencyMode: true,
      backBufferLength: 30,
    });
    hls.loadSource(HLS_URL);
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      video.play().catch(() => {});
      msg.style.display = 'none';
      root.innerHTML = '';
      root.appendChild(video);
    });
    hls.on(Hls.Events.ERROR, (_, data) => {
      if (data.fatal) {
        hls.destroy();
        showError('Error HLS: ' + data.type);
      }
    });
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    // Safari nativo
    video.src = HLS_URL;
    video.addEventListener('loadedmetadata', () => {
      video.play().catch(() => {});
      msg.style.display = 'none';
      root.innerHTML = '';
      root.appendChild(video);
    });
    video.addEventListener('error', () => showError('Error nativo HLS'));
  } else {
    showError('Tu navegador no soporta HLS. Usa Chrome o Firefox.');
  }
}

// Carga HLS.js desde CDN y arranca
const s = document.createElement('script');
s.src = 'https://cdn.jsdelivr.net/npm/hls.js@1.5.13/dist/hls.min.js';
s.onload = startHLS;
s.onerror = () => showError('No se pudo cargar el reproductor HLS.');
document.head.appendChild(s);
</script>
</body>
</html>
''';

    try {
      ui_web.platformViewRegistry.registerViewFactory(
        widget.viewId,
        (int id) {
          final iframe = html_lib.IFrameElement()
            ..srcdoc = htmlContent
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..setAttribute('allow', 'autoplay; encrypted-media; fullscreen')
            ..setAttribute('allowfullscreen', 'true')
            ..setAttribute('sandbox',
                'allow-scripts allow-same-origin allow-popups allow-forms');
          return iframe;
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: widget.viewId);
  }
}

// Widget que muestra un fondo con color del canal y el logo emoji
class _ThumbnailView extends StatefulWidget {
  final String viewId;
  final String channelId;
  final Color color;
  final String logo;
  final String name;
  const _ThumbnailView({
    required this.viewId,
    required this.channelId,
    required this.color,
    required this.logo,
    required this.name,
  });
  @override
  State<_ThumbnailView> createState() => _ThumbnailViewState();
}

class _ThumbnailViewState extends State<_ThumbnailView> {
  @override
  void initState() {
    super.initState();
    try {
      ui_web.platformViewRegistry.registerViewFactory(widget.viewId, (int id) {
        final img = html.ImageElement()
          ..src =
              'https://img.youtube.com/vi/${widget.channelId}/maxresdefault.jpg'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        // Fallback si la imagen no carga
        img.onError.listen((_) {
          img.style.display = 'none';
        });
        return img;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.8),
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        HtmlElementView(viewType: widget.viewId),
      ],
    );
  }
}

class _AudioLibraryCard extends StatefulWidget {
  final String url;
  final Color color;
  final String name;
  const _AudioLibraryCard(
      {required this.url, required this.color, required this.name});
  @override
  State<_AudioLibraryCard> createState() => _AudioLibraryCardState();
}

class _AudioLibraryCardState extends State<_AudioLibraryCard> {
  bool _playing = false;
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'audio-lib-${widget.url.hashCode}';
    try {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int id) {
        return html.IFrameElement()
          ..style.cssText = 'border:none;width:100%;height:100%;'
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin')
          ..srcdoc = '''<!DOCTYPE html><html><head>
<style>
  *{margin:0;padding:0;}
  body{background:#0a0f1e;width:100vw;height:100vh;display:flex;
       align-items:center;justify-content:center;overflow:hidden;}
  audio{width:90%;outline:none;}
</style></head><body>
<audio id="a" src="${widget.url}" preload="metadata" controls></audio>
</body></html>''';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.25),
                const Color(0xFF0A0F1E),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_rounded, color: widget.color, size: 28),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: HtmlElementView(viewType: _viewId),
            ),
          ],
        ),
      ],
    );
  }
}
