import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/programming/color.dart';
import 'package:digitaltv/ui/programming/helper/helper.dart';
import 'package:digitaltv/ui/programming/playBack.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// =============================================================================
// MODELOS
// =============================================================================

class ProgramBlock {
  final String? scheduleId;
  final String id;
  final String name;
  final String playlistId;
  final String playlistName;
  final List<String> days; // 'mon','tue','wed','thu','fri','sat','sun'
  final int startMinute; // minutos desde medianoche (0-1439)
  final int durationMinutes; // duración en minutos
  final bool isActive;
  final Color color;
  final String? description;
  final String? companyId;
  final DateTime? createdAt;

  const ProgramBlock({
    this.scheduleId,
    required this.id,
    required this.name,
    required this.playlistId,
    required this.playlistName,
    required this.days,
    required this.startMinute,
    required this.durationMinutes,
    this.isActive = true,
    this.color = CP.primary,
    this.description,
    this.companyId,
    this.createdAt,
  });

  int get endMinute => startMinute + durationMinutes;

  String get startTimeStr {
    final h = startMinute ~/ 60;
    final m = startMinute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endTimeStr {
    final end = endMinute;
    final h = (end ~/ 60) % 24;
    final m = end % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get durationStr {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}min';
    }
    return '${durationMinutes}min';
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'scheduleId': scheduleId,
        'name': name,
        'playlistId': playlistId,
        'playlistName': playlistName,
        'days': days,
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'colorValue': color.value,
        'description': description,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ProgramBlock fromFirestore(Map<String, dynamic> d, String docId) {
    return ProgramBlock(
      id: docId,
      scheduleId: d['scheduleId'],
      name: d['name'] ?? 'Sin nombre',
      playlistId: d['playlistId'] ?? '',
      playlistName: d['playlistName'] ?? '—',
      days: List<String>.from(d['days'] ?? []),
      startMinute: (d['startMinute'] as num?)?.toInt() ?? 0,
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 60,
      isActive: d['isActive'] ?? true,
      color: Color((d['colorValue'] as num?)?.toInt() ?? CP.primary.value),
      description: d['description'],
      companyId: d['companyId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  ProgramBlock copyWith({
    String? name,
    String? playlistId,
    String? playlistName,
    List<String>? days,
    int? startMinute,
    int? durationMinutes,
    bool? isActive,
    Color? color,
    String? description,
  }) =>
      ProgramBlock(
        scheduleId: scheduleId ?? this.scheduleId,
        id: id,
        name: name ?? this.name,
        playlistId: playlistId ?? this.playlistId,
        playlistName: playlistName ?? this.playlistName,
        days: days ?? this.days,
        startMinute: startMinute ?? this.startMinute,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
        color: color ?? this.color,
        description: description ?? this.description,
        companyId: companyId,
        createdAt: createdAt,
      );
}

class Schedule {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String? companyId;
  final DateTime? createdAt;

  const Schedule({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.companyId,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'isActive': isActive,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static Schedule fromFirestore(Map<String, dynamic> d, String docId) =>
      Schedule(
        id: docId,
        name: d['name'] ?? 'Sin nombre',
        description: d['description'],
        isActive: d['isActive'] ?? true,
        companyId: d['companyId'],
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      );

  Schedule copyWith({String? name, String? description, bool? isActive}) =>
      Schedule(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        companyId: companyId,
        createdAt: createdAt,
      );
}

// Modelo simple de playlist para el selector
class _PlaylistItem {
  final String id;
  final String name;
  final int itemCount;
  final int totalSeconds;
  const _PlaylistItem({
    required this.id,
    required this.name,
    this.itemCount = 0,
    this.totalSeconds = 0,
  });
}

// =============================================================================
// PROVIDERS
// =============================================================================
final _schedulesProvider =
    StreamProvider.autoDispose<List<Schedule>>((ref) async* {
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
        .collection('schedules')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance.collection('schedules').snapshots();
  }

  yield* stream.map((snap) {
    final list = snap.docs
        .map((d) =>
            Schedule.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
    list.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });
    return list;
  });
});

final _programBlocksProvider =
    StreamProvider.autoDispose<List<ProgramBlock>>((ref) async* {
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
        .collection('program_blocks')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream =
        FirebaseFirestore.instance.collection('program_blocks').snapshots();
  }

  yield* stream.map((snap) {
    final list = snap.docs
        .map((d) =>
            ProgramBlock.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
    list.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return list;
  });
});

// Provider para bloques de una programación específica
final _selectedScheduleIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);
final _blocksForScheduleProvider = StreamProvider.autoDispose
    .family<List<ProgramBlock>, String>((ref, scheduleId) async* {
  yield* FirebaseFirestore.instance
      .collection('program_blocks')
      .where('scheduleId', isEqualTo: scheduleId)
      .snapshots()
      .map((snap) {
    final list = snap.docs
        .map((d) =>
            ProgramBlock.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
    list.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return list;
  });
});

final _playlistsForProgProvider =
    StreamProvider.autoDispose<List<_PlaylistItem>>((ref) async* {
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
        .collection('playlists')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance.collection('playlists').snapshots();
  }

  yield* stream.map((snap) {
    final list = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final clips = (data['clips'] as List?)?.length ?? 0;
      final seconds = (data['clips'] as List? ?? []).fold<int>(
          0, (s, c) => s + ((c['durationSec'] as num?)?.toInt() ?? 0));
      return _PlaylistItem(
          id: d.id,
          name: data['name'] ?? 'Sin nombre',
          itemCount: clips,
          totalSeconds: seconds);
    }).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  });
});
// Día seleccionado para vista de grilla
final _selectedDayProvider = StateProvider.autoDispose<String>((ref) {
  final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final now = DateTime.now();
  return days[now.weekday - 1];
});

// =============================================================================
// MAIN SCREEN
// =============================================================================

class ProgrammingScreen extends ConsumerStatefulWidget {
  const ProgrammingScreen({super.key});
  @override
  ConsumerState<ProgrammingScreen> createState() => _ProgrammingScreenState();
}

class _ProgrammingScreenState extends ConsumerState<ProgrammingScreen> {
  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(_schedulesProvider);
    return Scaffold(
      backgroundColor: CP.bg,
      body: Column(
        children: [
          _buildHeader(schedulesAsync),
          Expanded(
            child: schedulesAsync.when(
              loading: () => const _SkeletonScreen(),
              error: (e, _) => _EmptyWidget(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (schedules) => schedules.isEmpty
                  ? _EmptyWidget(
                      icon: Icons.calendar_view_week_rounded,
                      title: 'Sin programaciones',
                      subtitle:
                          'Crea tu primera programación semanal con el botón de arriba',
                    )
                  : _ScheduleListView(schedules: schedules),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Schedule>> schedulesAsync) {
    final total = schedulesAsync.valueOrNull?.length ?? 0;
    final active =
        schedulesAsync.valueOrNull?.where((s) => s.isActive).length ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
          color: CP.surface,
          border: Border(bottom: BorderSide(color: CP.divider))),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [CP.primary, Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_view_week_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Programaciones1',
                  style: TextStyle(
                      color: CP.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('$total programaciones · $active activas',
                  style: const TextStyle(color: CP.textMid, fontSize: 13)),
            ],
          ),
          const Spacer(),
          _StatPill(
              label: 'Total',
              value: '$total',
              color: CP.primary,
              icon: Icons.view_week_rounded),
          const SizedBox(width: 8),
          _StatPill(
              label: 'Activas',
              value: '$active',
              color: CP.green,
              icon: Icons.check_circle_rounded),
          const SizedBox(width: 16),
          _PrimaryBtn(
            label: '+ Nueva programación',
            onTap: () => _showCreateScheduleSheet(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _showCreateScheduleSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CPreateScheduleSheet(),
    );
  }
}

// =============================================================================
// VISTA SEMANAL / GRID
// =============================================================================

class _GridView extends ConsumerStatefulWidget {
  final List<ProgramBlock> blocks;
  const _GridView({required this.blocks});
  @override
  ConsumerState<_GridView> createState() => _GridViewState();
}

class _GridViewState extends ConsumerState<_GridView> {
  final ScrollController _vScroll = ScrollController();
  // Hora de inicio de la vista (por defecto 0 = medianoche)
  int _viewStartHour = 6;
  int _viewHours = 18; // cuántas horas mostrar (6 a 24)
  static const double _hourHeight = 80.0;
  static const double _labelW = 54.0;

  @override
  void dispose() {
    _vScroll.dispose();
    super.dispose();
  }

  List<ProgramBlock> get _dayBlocks {
    final day = ref.watch(_selectedDayProvider);
    return widget.blocks
        .where((b) => b.days.contains(day) && b.isActive)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(_selectedDayProvider);
    final dayBlocks = _dayBlocks;
    final now = TimeOfDay.now();
    final nowMinute = now.hour * 60 + now.minute;

    return Column(
      children: [
        // ── Toolbar de vista ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
          color: CP.surface,
          child: Row(
            children: [
              // Selector de día
              const Text('Día:',
                  style: TextStyle(
                      color: CP.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              ...orderedDays.map((d) {
                final sel = d == selectedDay;
                final hasBl = widget.blocks.any((b) => b.days.contains(d));
                return GestureDetector(
                  onTap: () =>
                      ref.read(_selectedDayProvider.notifier).state = d,
                  child: AnimatedContainer(
                    duration: 130.ms,
                    margin: const EdgeInsets.only(right: 5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? CP.primary : CP.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel
                              ? CP.primary
                              : hasBl
                                  ? CP.border.withOpacity(0.8)
                                  : CP.border,
                          width: sel ? 0 : 1),
                    ),
                    child: Row(
                      children: [
                        Text(dayShort[d]!,
                            style: TextStyle(
                                color: sel ? Colors.white : CP.textMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        if (hasBl && !sel) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: CP.accent, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Control horas visibles
              const Text('Horas visibles:',
                  style: TextStyle(color: CP.textMid, fontSize: 11)),
              const SizedBox(width: 8),
              ...[8, 12, 16, 24].map((h) {
                final sel = _viewHours == h;
                return GestureDetector(
                  onTap: () => setState(() {
                    _viewHours = h;
                  }),
                  child: AnimatedContainer(
                    duration: 130.ms,
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: sel ? CP.primaryLo : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color:
                                sel ? CP.primary.withOpacity(0.5) : CP.border)),
                    child: Text('${h}h',
                        style: TextStyle(
                            color: sel ? CP.primary : CP.textMid,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }),
              const SizedBox(width: 12),
              // Ir a ahora
              GestureDetector(
                onTap: () {
                  final targetOffset = ((nowMinute / 60) - _viewStartHour)
                          .clamp(0.0, _viewHours.toDouble()) *
                      _hourHeight;
                  _vScroll.animateTo(
                      targetOffset.clamp(0, _vScroll.position.maxScrollExtent),
                      duration: 400.ms,
                      curve: Curves.easeOut);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: CP.redLo,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: CP.red.withOpacity(0.4))),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location_rounded, size: 11, color: CP.red),
                      SizedBox(width: 4),
                      Text('Ahora',
                          style: TextStyle(
                              color: CP.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Info del día seleccionado ─────────────────────────────
        if (dayBlocks.isEmpty)
          Expanded(
            child: _EmptyWidget(
              icon: Icons.event_available_rounded,
              title: 'Sin programación el ${dayLabels[selectedDay]}',
              subtitle:
                  'Crea un bloque para este día con el botón + Nueva programación',
              compact: true,
            ),
          )
        else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Timeline principal ──────────────────────────────
                Expanded(
                  child: Scrollbar(
                    controller: _vScroll,
                    child: SingleChildScrollView(
                      controller: _vScroll,
                      child: _buildTimeline(dayBlocks, nowMinute),
                    ),
                  ),
                ),
                // ── Panel lateral: resumen del día ──────────────────
                _DaySummaryPanel(
                  blocks: dayBlocks,
                  dayLabel: dayLabels[selectedDay]!,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeline(List<ProgramBlock> dayBlocks, int nowMinute) {
    final totalH = _hourHeight * _viewHours;
    final startMin = _viewStartHour * 60;
    final endMin = startMin + _viewHours * 60;

    // Agrupar overlapping blocks en columnas
    final positioned = _resolveOverlaps(dayBlocks);

    return SizedBox(
      height: totalH + 40,
      child: Stack(
        children: [
          // ── Fondo con líneas de hora ──────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _TimelineGridPainter(
                startHour: _viewStartHour,
                totalHours: _viewHours,
                hourHeight: _hourHeight,
                labelWidth: _labelW,
              ),
            ),
          ),

          // ── Labels de hora ─────────────────────────────────────────
          ...List.generate(_viewHours + 1, (i) {
            final hour = _viewStartHour + i;
            if (hour > 24) return const SizedBox.shrink();
            return Positioned(
              top: i * _hourHeight - 8,
              left: 0,
              width: _labelW,
              child: Text(fmtMinutes(hour * 60),
                  style: TextStyle(
                      color: CP.textLo.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            );
          }),

          // ── Bloques de programación ─────────────────────────────────
          ...positioned.map((entry) {
            final block = entry.$1;
            final col = entry.$2;
            final totalCols = entry.$3;
            final blockStartMin = block.startMinute;
            final blockEndMin = block.endMinute;
            if (blockEndMin <= startMin || blockStartMin >= endMin) {
              return const SizedBox.shrink();
            }
            final topMin = math.max(blockStartMin, startMin) - startMin;
            final botMin = math.min(blockEndMin, endMin) - startMin;
            final top = (topMin / 60) * _hourHeight;
            final height = ((botMin - topMin) / 60) * _hourHeight;
            final colW =
                (MediaQuery.of(context).size.width - _labelW - 280) / totalCols;

            return Positioned(
              top: top,
              left: _labelW + 4 + col * colW,
              width: colW - 4,
              height: math.max(height, 24),
              child: _BlockTile(block: block),
            );
          }),

          // ── Línea de "ahora" ──────────────────────────────────────
          if (nowMinute >= startMin && nowMinute <= endMin)
            Positioned(
              top: ((nowMinute - startMin) / 60) * _hourHeight,
              left: _labelW - 6,
              right: 0,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: CP.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: CP.red.withOpacity(0.5), blurRadius: 6)
                        ]),
                  ),
                  Expanded(
                      child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [CP.red, CP.red.withOpacity(0)]),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Resolver solapamientos para columnas
  List<(ProgramBlock, int, int)> _resolveOverlaps(List<ProgramBlock> blocks) {
    final sorted = [...blocks]
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final result = <(ProgramBlock, int, int)>[];
    final cols = <List<ProgramBlock>>[];

    for (final block in sorted) {
      int placed = -1;
      for (int c = 0; c < cols.length; c++) {
        if (cols[c].last.endMinute <= block.startMinute) {
          cols[c].add(block);
          placed = c;
          break;
        }
      }
      if (placed == -1) {
        cols.add([block]);
        placed = cols.length - 1;
      }
    }

    for (int c = 0; c < cols.length; c++) {
      for (final block in cols[c]) {
        // contar cuántas columnas se solapan con este bloque
        int maxOverlap = cols.length;
        result.add((block, c, maxOverlap));
      }
    }
    return result;
  }
}

// Grid painter
class _TimelineGridPainter extends CustomPainter {
  final int startHour, totalHours;
  final double hourHeight, labelWidth;

  _TimelineGridPainter({
    required this.startHour,
    required this.totalHours,
    required this.hourHeight,
    required this.labelWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF121C2E)
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = const Color(0xFF0D1525)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= totalHours; i++) {
      final y = i * hourHeight;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), gridPaint);
      // Línea de media hora
      if (i < totalHours) {
        final yHalf = y + hourHeight / 2;
        canvas.drawLine(
            Offset(labelWidth, yHalf), Offset(size.width, yHalf), halfPaint);
      }
    }

    // Sombra del panel de labels
    final labelBg = Paint()..color = const Color(0xFF080D16);
    canvas.drawRect(Rect.fromLTWH(0, 0, labelWidth, size.height), labelBg);
  }

  @override
  bool shouldRepaint(_TimelineGridPainter old) => false;
}

// =============================================================================
// BLOQUE EN EL TIMELINE (draggable)
// =============================================================================

class _BlockTile extends StatefulWidget {
  final ProgramBlock block;
  const _BlockTile({required this.block});
  @override
  State<_BlockTile> createState() => _BlockTileState();
}

class _BlockTileState extends State<_BlockTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final color = b.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: AnimatedContainer(
          duration: 120.ms,
          decoration: BoxDecoration(
            color: _hovered ? color.withOpacity(0.28) : color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _hovered ? color : color.withOpacity(0.5),
                width: _hovered ? 2 : 1),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Barra izquierda de color
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del bloque
                    Text(b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    // Playlist
                    Text(b.playlistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: CP.textMid, fontSize: 9)),
                    // Horario
                    Text('${b.startTimeStr} — ${b.endTimeStr}',
                        style: const TextStyle(color: CP.textLo, fontSize: 8)),
                    // Duración badge
                    if (b.durationMinutes >= 30)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(b.durationStr,
                            style: TextStyle(
                                color: color,
                                fontSize: 7,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              // Botón edit hover
              if (_hovered)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _showEdit(context),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: color.withOpacity(0.4))),
                      child: Icon(Icons.edit_rounded, size: 11, color: color),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext ctx) {
    showDialog(
        context: ctx, builder: (_) => _BlockDetailDialog(block: widget.block));
  }

  void _showEdit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CPreateProgramSheet(editing: widget.block),
    );
  }
}

// =============================================================================
// PANEL LATERAL RESUMEN DEL DÍA
// =============================================================================

class _DaySummaryPanel extends StatelessWidget {
  final List<ProgramBlock> blocks;
  final String dayLabel;
  const _DaySummaryPanel({required this.blocks, required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    final totalMin = blocks.fold(0, (s, b) => s + b.durationMinutes);
    final covered = (totalMin / 1440 * 100).clamp(0, 100);
    final playlists = blocks.map((b) => b.playlistName).toSet();

    return Container(
      width: 260,
      decoration: const BoxDecoration(
          color: CP.surface,
          border: Border(left: BorderSide(color: CP.divider))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: CP.divider))),
            child: Row(
              children: [
                const Icon(Icons.summarize_rounded,
                    size: 14, color: CP.primary),
                const SizedBox(width: 8),
                Text('Resumen · $dayLabel',
                    style: const TextStyle(
                        color: CP.textHi,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coverage del día
                  _SummaryStatCard(
                    label: 'Cobertura del día',
                    value: '${covered.toStringAsFixed(1)}%',
                    subtitle: '${_fmtHoursMin(totalMin)} programadas',
                    color: covered > 80
                        ? CP.green
                        : covered > 40
                            ? CP.amber
                            : CP.red,
                    icon: Icons.pie_chart_rounded,
                  ),
                  const SizedBox(height: 8),
                  // Barra de cobertura visual
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: CP.card,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CP.border)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: covered / 100,
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              covered > 80
                                  ? CP.green
                                  : covered > 40
                                      ? CP.amber
                                      : CP.red,
                              (covered > 80
                                      ? CP.green
                                      : covered > 40
                                          ? CP.amber
                                          : CP.red)
                                  .withOpacity(0.6),
                            ]),
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SummaryStatCard(
                    label: 'Bloques hoy',
                    value: '${blocks.length}',
                    subtitle:
                        '${blocks.where((b) => b.isActive).length} activos',
                    color: CP.accent,
                    icon: Icons.view_agenda_rounded,
                  ),
                  const SizedBox(height: 8),
                  _SummaryStatCard(
                    label: 'Playlists únicas',
                    value: '${playlists.length}',
                    subtitle: playlists.take(2).join(', '),
                    color: CP.purple,
                    icon: Icons.playlist_play_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Lista compacta de bloques
                  const _SectionTitle('Bloques del día'),
                  ...blocks.map((b) => _MiniBlockItem(block: b)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtHoursMin(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  final IconData icon;
  const _SummaryStatCard(
      {required this.label,
      required this.value,
      required this.subtitle,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: CP.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CP.border)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text(label,
                      style: const TextStyle(color: CP.textMid, fontSize: 10)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: const TextStyle(color: CP.textLo, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MiniBlockItem extends StatelessWidget {
  final ProgramBlock block;
  const _MiniBlockItem({required this.block});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: block.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: block.color.withOpacity(0.2))),
        child: Row(
          children: [
            Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                    color: block.color,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.name,
                      style: const TextStyle(
                          color: CP.textHi,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                      '${block.startTimeStr} — ${block.endTimeStr} · ${block.durationStr}',
                      style: const TextStyle(color: CP.textLo, fontSize: 9)),
                ],
              ),
            ),
            if (!block.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: CP.redLo,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: CP.red.withOpacity(0.3))),
                child: const Text('Off',
                    style: TextStyle(
                        color: CP.red,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      );
}

// =============================================================================
// VISTA DE LISTA
// =============================================================================

class _ListView extends ConsumerStatefulWidget {
  final List<ProgramBlock> blocks;
  const _ListView({required this.blocks});
  @override
  ConsumerState<_ListView> createState() => _ListViewState();
}

class _ListViewState extends ConsumerState<_ListView> {
  String _filterDay = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProgramBlock> get _filtered {
    return widget.blocks.where((b) {
      if (_filterDay != 'all' && !b.days.contains(_filterDay)) return false;
      if (_search.isNotEmpty &&
          !b.name.toLowerCase().contains(_search.toLowerCase()) &&
          !b.playlistName.toLowerCase().contains(_search.toLowerCase()))
        return false;
      return true;
    }).toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          color: CP.surface,
          child: Row(
            children: [
              // Búsqueda
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                      color: CP.card,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: CP.border)),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: CP.textHi, fontSize: 12),
                    decoration: const InputDecoration(
                        hintText: 'Buscar bloque o playlist...',
                        hintStyle: TextStyle(color: CP.textLo, fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 16, color: CP.textMid),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filtro por día
              ...[
                ('all', 'Todos'),
                ...orderedDays.map((d) => (d, dayShort[d]!))
              ].map((t) {
                final (id, label) = t;
                final sel = _filterDay == id;
                return GestureDetector(
                  onTap: () => setState(() => _filterDay = id),
                  child: AnimatedContainer(
                    duration: 130.ms,
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: sel ? CP.primaryLo : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color:
                                sel ? CP.primary.withOpacity(0.5) : CP.border)),
                    child: Text(label,
                        style: TextStyle(
                            color: sel ? CP.primary : CP.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: filtered.isEmpty
              ? _EmptyWidget(
                  icon: Icons.search_off_rounded,
                  title: 'Sin resultados',
                  subtitle: 'Prueba con otro filtro o crea un nuevo bloque',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _BlockListCard(
                    block: filtered[i],
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 30)),
                ),
        ),
      ],
    );
  }
}

class _BlockListCard extends StatefulWidget {
  final ProgramBlock block;
  const _BlockListCard({required this.block});
  @override
  State<_BlockListCard> createState() => _BlockListCardState();
}

class _BlockListCardState extends State<_BlockListCard> {
  bool _hovered = false;
  bool CPonfirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final color = b.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        CPonfirmDelete = false;
      }),
      child: AnimatedContainer(
        duration: 130.ms,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: _hovered ? CP.cardHover : CP.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _hovered ? color.withOpacity(0.4) : CP.border)),
        child: Row(
          children: [
            // Barra de color
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14))),
            ),
            const SizedBox(width: 14),
            // Ícono
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.view_timeline_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(b.name,
                            style: const TextStyle(
                                color: CP.textHi,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(width: 8),
                        _ActiveBadge(active: b.isActive),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.playlist_play_rounded,
                            size: 12, color: CP.textMid),
                        const SizedBox(width: 4),
                        Text(b.playlistName,
                            style: const TextStyle(
                                color: CP.textMid, fontSize: 12)),
                        const SizedBox(width: 14),
                        const Icon(Icons.schedule_rounded,
                            size: 12, color: CP.textMid),
                        const SizedBox(width: 4),
                        Text(
                            '${b.startTimeStr} — ${b.endTimeStr}  (${b.durationStr})',
                            style: const TextStyle(
                                color: CP.textMid, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Días
                    Row(
                      children: orderedDays.map((d) {
                        final active = b.days.contains(d);
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: active
                                  ? color.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: active
                                      ? color.withOpacity(0.5)
                                      : CP.border)),
                          child: Text(dayShort[d]!,
                              style: TextStyle(
                                  color: active ? color : CP.textLo,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Acciones
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CPonfirmDelete
                  ? Row(
                      children: [
                        const Text('¿Eliminar?',
                            style: TextStyle(color: CP.red, fontSize: 11)),
                        const SizedBox(width: 8),
                        _SmallBtn(
                          label: 'Sí',
                          color: CP.red,
                          onTap: () => _delete(context),
                        ),
                        const SizedBox(width: 4),
                        _SmallBtn(
                          label: 'No',
                          color: CP.textMid,
                          onTap: () => setState(() => CPonfirmDelete = false),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Switch(
                          value: b.isActive,
                          activeColor: CP.green,
                          onChanged: (v) => _toggleActive(context, v),
                        ),
                        _IconBtnCard(
                          icon: Icons.edit_rounded,
                          color: CP.primary,
                          tooltip: 'Editar',
                          onTap: () => _edit(context),
                        ),
                        const SizedBox(width: 4),
                        _IconBtnCard(
                          icon: Icons.visibility_rounded,
                          color: CP.accent,
                          tooltip: 'Ver detalle',
                          onTap: () => showDialog(
                              context: context,
                              builder: (_) => _BlockDetailDialog(block: b)),
                        ),
                        const SizedBox(width: 4),
                        _IconBtnCard(
                          icon: Icons.delete_outline_rounded,
                          color: CP.red,
                          tooltip: 'Eliminar',
                          onTap: () => setState(() => CPonfirmDelete = true),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx) async {
    await FirebaseFirestore.instance
        .collection('program_blocks')
        .doc(widget.block.id)
        .delete();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(snack('Bloque eliminado', bg: CP.red));
    }
  }

  Future<void> _toggleActive(BuildContext ctx, bool val) async {
    await FirebaseFirestore.instance
        .collection('program_blocks')
        .doc(widget.block.id)
        .update({'isActive': val});
  }

  void _edit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CPreateProgramSheet(editing: widget.block),
    );
  }
}

// =============================================================================
// SHEET CREAR / EDITAR BLOQUE
// =============================================================================

class CPreateProgramSheet extends ConsumerStatefulWidget {
  final ProgramBlock? editing;
  final String? scheduleId; // <-- agrega esto
  const CPreateProgramSheet(
      {this.editing, this.scheduleId}); // <-- modifica esto
  //const CPreateProgramSheet({this.editing});
  @override
  ConsumerState<CPreateProgramSheet> createState() =>
      CPreateProgramSheetState();
}

class CPreateProgramSheetState extends ConsumerState<CPreateProgramSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedPlaylistId;
  String? _selectedPlaylistName;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 2;
  int _durationMinutes = 0;
  bool _useCustomEnd = false;
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final Set<String> _days = {'mon', 'tue', 'wed', 'thu', 'fri'};
  Color _selectedColor = CP.blockColors[0];
  bool _loading = false;
  String? _error;

  int get _startMinute => _startTime.hour * 60 + _startTime.minute;
  int get _totalDurationMinutes => _durationHours * 60 + _durationMinutes;
  int get _endMinute => _useCustomEnd
      ? _endTime.hour * 60 + _endTime.minute
      : _startMinute + _totalDurationMinutes;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description ?? '';
      _selectedPlaylistId = e.playlistId;
      _selectedPlaylistName = e.playlistName;
      _startTime =
          TimeOfDay(hour: e.startMinute ~/ 60, minute: e.startMinute % 60);
      _durationHours = e.durationMinutes ~/ 60;
      _durationMinutes = e.durationMinutes % 60;
      _days.clear();
      _days.addAll(e.days);
      _selectedColor = e.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // Detecta conflictos con otros bloques existentes
  bool _hasConflict(List<ProgramBlock> existing) {
    final start = _startMinute;
    final end = _endMinute;
    for (final b in existing) {
      if (widget.editing?.id == b.id) continue;
      // Si comparten algún día
      if (!_days.any((d) => b.days.contains(d))) continue;
      // Si se solapan en tiempo
      if (start < b.endMinute && end > b.startMinute) return true;
    }
    return false;
  }

  Future<void> _save(List<ProgramBlock> existing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlaylistId == null) {
      setState(() => _error = 'Selecciona una playlist');
      return;
    }
    if (_days.isEmpty) {
      setState(() => _error = 'Selecciona al menos un día');
      return;
    }
    if (_endMinute <= _startMinute) {
      setState(() => _error = 'La hora de fin debe ser mayor que la de inicio');
      return;
    }
    if (_hasConflict(existing)) {
      setState(() => _error =
          'Existe un conflicto de horario en uno de los días seleccionados');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companyId = await getCompanyId();
      final duration = _endMinute - _startMinute;
      final data = {
        'name': _nameCtrl.text.trim(),
        'playlistId': _selectedPlaylistId,
        'playlistName': _selectedPlaylistName,
        'days': _days.toList(),
        'startMinute': _startMinute,
        'durationMinutes': duration,
        'isActive': true,
        'colorValue': _selectedColor.value,
        'description': _descCtrl.text.trim(),
        'companyId': companyId,
        'updatedAt': FieldValue.serverTimestamp(),
        'scheduleId': widget.scheduleId ?? widget.editing?.scheduleId,
      };
      if (widget.editing != null) {
        await FirebaseFirestore.instance
            .collection('program_blocks')
            .doc(widget.editing!.id)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('program_blocks').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(_playlistsForProgProvider);
    final blocksAsync = ref.watch(_programBlocksProvider);
    final existing = blocksAsync.valueOrNull ?? [];
    final isEdit = widget.editing != null;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: CP.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: CP.border)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: CP.border, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: CP.primaryLo,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today_rounded,
                        size: 18, color: CP.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isEdit ? 'Editar programación' : 'Nueva programación',
                          style: const TextStyle(
                              color: CP.textHi,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const Text('Configura cuándo se reproduce cada playlist',
                          style: TextStyle(color: CP.textMid, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: CP.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CP.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: CP.textMid),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: CP.divider, height: 1),

            // Contenido scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_error != null) _ErrorBanner(message: _error!),

                    // Nombre
                    _FormSection(title: 'Información básica', children: [
                      _SheetLabel('Nombre del bloque *'),
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: CP.textHi, fontSize: 13),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'El nombre es obligatorio'
                            : null,
                        decoration: _fieldDeco(
                            'Ej: Prime Time, Matinal, Medianoche',
                            Icons.label_outline_rounded),
                      ),
                      const SizedBox(height: 12),
                      _SheetLabel('Descripción (opcional)'),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: CP.textHi, fontSize: 13),
                        decoration: _fieldDeco(
                            'Notas sobre esta programación...',
                            Icons.notes_rounded),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Playlist
                    _FormSection(title: 'Contenido', children: [
                      _SheetLabel('Playlist a reproducir *'),
                      playlistsAsync.when(
                        loading: () => const _LoadingField(),
                        error: (e, _) => Text('Error: $e',
                            style:
                                const TextStyle(color: CP.red, fontSize: 11)),
                        data: (playlists) => playlists.isEmpty
                            ? _NoDataField(
                                msg:
                                    'No hay playlists disponibles. Crea una primero.')
                            : _PlaylistPicker(
                                playlists: playlists,
                                selectedId: _selectedPlaylistId,
                                onSelect: (id, name) => setState(() {
                                  _selectedPlaylistId = id;
                                  _selectedPlaylistName = name;
                                }),
                              ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Horario
                    _FormSection(title: 'Horario', children: [
                      Row(
                        children: [
                          // Hora inicio
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SheetLabel('Hora de inicio'),
                                _TimePicker(
                                  time: _startTime,
                                  label: 'Inicio',
                                  icon: Icons.play_arrow_rounded,
                                  color: CP.green,
                                  onPick: (t) => setState(() {
                                    _startTime = t;
                                    // Actualizar endTime si usamos modo manual
                                    if (!_useCustomEnd) {
                                      final endMin = _startTime.hour * 60 +
                                          _startTime.minute +
                                          _totalDurationMinutes;
                                      _endTime = TimeOfDay(
                                          hour: (endMin ~/ 60) % 24,
                                          minute: endMin % 60);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Duración o hora fin
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const _SheetLabel('Hora de fin'),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _useCustomEnd = !_useCustomEnd),
                                      child: Text(
                                          _useCustomEnd
                                              ? '← Usar duración'
                                              : 'Hora exacta →',
                                          style: const TextStyle(
                                              color: CP.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                _TimePicker(
                                  time: TimeOfDay(
                                      hour: (_endMinute ~/ 60) % 24,
                                      minute: _endMinute % 60),
                                  label: 'Fin',
                                  icon: Icons.stop_rounded,
                                  color: CP.red,
                                  onPick: _useCustomEnd
                                      ? (t) => setState(() => _endTime = t)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Control de duración (si no es hora exacta)
                      if (!_useCustomEnd) ...[
                        const SizedBox(height: 14),
                        const _SheetLabel('Duración del bloque'),
                        _DurationPicker(
                          hours: _durationHours,
                          minutes: _durationMinutes,
                          onChanged: (h, m) => setState(() {
                            _durationHours = h;
                            _durationMinutes = m;
                          }),
                        ),
                      ],

                      // Resumen de tiempo
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: CP.primaryLo,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: CP.primary.withOpacity(0.2))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 14, color: CP.primary),
                            const SizedBox(width: 8),
                            Text(
                                '${_fmt(_startTime)} → ${fmtMinutes(_endMinute % 1440)}'
                                '  ·  ${_fmtDur(_endMinute - _startMinute)}',
                                style: const TextStyle(
                                    color: CP.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Días de la semana
                    _FormSection(title: 'Días de emisión', children: [
                      const _SheetLabel('Selecciona los días *'),
                      const SizedBox(height: 8),
                      // Quick selects
                      Row(
                        children: [
                          _QuickDayBtn(
                              label: 'L-V',
                              onTap: () => setState(() {
                                    _days
                                      ..clear()
                                      ..addAll(
                                          ['mon', 'tue', 'wed', 'thu', 'fri']);
                                  })),
                          const SizedBox(width: 6),
                          _QuickDayBtn(
                              label: 'Fin de semana',
                              onTap: () => setState(() {
                                    _days
                                      ..clear()
                                      ..addAll(['sat', 'sun']);
                                  })),
                          const SizedBox(width: 6),
                          _QuickDayBtn(
                              label: 'Todos',
                              onTap: () => setState(() {
                                    _days
                                      ..clear()
                                      ..addAll(orderedDays);
                                  })),
                          const SizedBox(width: 6),
                          _QuickDayBtn(
                              label: 'Ninguno',
                              onTap: () => setState(() {
                                    _days.clear();
                                  }),
                              danger: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: orderedDays.map((d) {
                          final sel = _days.contains(d);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => sel ? _days.remove(d) : _days.add(d)),
                              child: AnimatedContainer(
                                duration: 130.ms,
                                margin: const EdgeInsets.only(right: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? _selectedColor.withOpacity(0.15)
                                        : CP.card,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: sel
                                            ? _selectedColor.withOpacity(0.6)
                                            : CP.border,
                                        width: sel ? 1.5 : 1)),
                                child: Column(
                                  children: [
                                    Text(dayShort[d]!,
                                        style: TextStyle(
                                            color: sel
                                                ? _selectedColor
                                                : CP.textMid,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 2),
                                    Text(dayLabels[d]!.substring(0, 3),
                                        style: TextStyle(
                                            color: sel
                                                ? _selectedColor
                                                    .withOpacity(0.7)
                                                : CP.textLo,
                                            fontSize: 8),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Color
                    _FormSection(title: 'Color identificador', children: [
                      const _SheetLabel('Elige un color para este bloque'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CP.blockColors.map((c) {
                          final sel = c == _selectedColor;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: AnimatedContainer(
                              duration: 120.ms,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        sel ? Colors.white : Colors.transparent,
                                    width: sel ? 3 : 0),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: c.withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 2)
                                      ]
                                    : [],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _save(existing),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CP.primary,
                            disabledBackgroundColor: CP.card,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                isEdit
                                    ? 'Actualizar programación'
                                    : 'Crear programación',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.08, duration: 280.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }

  String _fmtDur(int minutes) {
    if (minutes <= 0) return '0 min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  InputDecoration _fieldDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CP.textLo, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: CP.textMid),
        filled: true,
        fillColor: CP.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CP.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CP.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CP.borderFocus, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CP.red)),
        errorStyle: const TextStyle(color: CP.red, fontSize: 10),
      );
}

// =============================================================================
// PLAYLIST PICKER
// =============================================================================

class _PlaylistPicker extends StatefulWidget {
  final List<_PlaylistItem> playlists;
  final String? selectedId;
  final void Function(String id, String name) onSelect;
  const _PlaylistPicker(
      {required this.playlists,
      required this.selectedId,
      required this.onSelect});
  @override
  State<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<_PlaylistPicker> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.playlists.where((p) => p.id == widget.selectedId).firstOrNull;

    return Column(
      children: [
        // Display / trigger
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: CP.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected != null
                        ? CP.primary.withOpacity(0.5)
                        : CP.border,
                    width: selected != null ? 1.5 : 1)),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: selected != null ? CP.primaryLo : CP.surface,
                      borderRadius: BorderRadius.circular(7)),
                  child: Icon(Icons.playlist_play_rounded,
                      size: 16,
                      color: selected != null ? CP.primary : CP.textLo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: selected != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selected.name,
                                style: const TextStyle(
                                    color: CP.textHi,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                                '${selected.itemCount} clips · '
                                '${_fmtDurSec(selected.totalSeconds)}',
                                style: const TextStyle(
                                    color: CP.textMid, fontSize: 10)),
                          ],
                        )
                      : const Text('Selecciona una playlist...',
                          style: TextStyle(color: CP.textLo, fontSize: 12)),
                ),
                Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: CP.textMid,
                    size: 18),
              ],
            ),
          ),
        ),
        // Lista desplegable
        AnimatedCrossFade(
          duration: 200.ms,
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
                color: CP.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CP.border)),
            child: Column(
              children: widget.playlists.map((p) {
                final sel = p.id == widget.selectedId;
                return GestureDetector(
                  onTap: () {
                    widget.onSelect(p.id, p.name);
                    setState(() => _expanded = false);
                  },
                  child: AnimatedContainer(
                    duration: 100.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: sel ? CP.primaryLo : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: sel ? CP.primary : CP.textLo,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: TextStyle(
                                      color: sel ? CP.primary : CP.textHi,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '${p.itemCount} clips · '
                                  '${_fmtDurSec(p.totalSeconds)}',
                                  style: const TextStyle(
                                      color: CP.textMid, fontSize: 10)),
                            ],
                          ),
                        ),
                        if (sel)
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: CP.primary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDurSec(int s) {
    if (s == 0) return '—';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}

// =============================================================================
// DURATION PICKER
// =============================================================================

class _DurationPicker extends StatelessWidget {
  final int hours, minutes;
  final void Function(int h, int m) onChanged;
  const _DurationPicker(
      {required this.hours, required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: CP.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CP.border)),
      child: Column(
        children: [
          // Horas
          Row(
            children: [
              const SizedBox(
                  width: 70,
                  child: Text('Horas',
                      style: TextStyle(color: CP.textMid, fontSize: 12))),
              Expanded(
                child: SliderTheme(
                  data: _sliderTheme(CP.primary),
                  child: Slider(
                    value: hours.toDouble(),
                    min: 0,
                    max: 23,
                    onChanged: (v) => onChanged(v.toInt(), minutes),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('$hours h',
                    style: const TextStyle(
                        color: CP.textHi,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          // Minutos (en pasos de 5)
          Row(
            children: [
              const SizedBox(
                  width: 70,
                  child: Text('Minutos',
                      style: TextStyle(color: CP.textMid, fontSize: 12))),
              Expanded(
                child: SliderTheme(
                  data: _sliderTheme(CP.accent),
                  child: Slider(
                    value: (minutes ~/ 5 * 5).toDouble(),
                    min: 0,
                    max: 55,
                    divisions: 11,
                    onChanged: (v) => onChanged(hours, v.toInt()),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('$minutes m',
                    style: const TextStyle(
                        color: CP.textHi,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          // Quick durations
          Wrap(
            spacing: 6,
            children: [30, 60, 90, 120, 180, 240, 360, 480].map((min) {
              final sel = hours * 60 + minutes == min;
              final label = min < 60
                  ? '${min}min'
                  : min % 60 == 0
                      ? '${min ~/ 60}h'
                      : '${min ~/ 60}h${min % 60}m';
              return GestureDetector(
                onTap: () => onChanged(min ~/ 60, min % 60),
                child: AnimatedContainer(
                  duration: 120.ms,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: sel
                          ? CP.accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel ? CP.accent.withOpacity(0.5) : CP.border)),
                  child: Text(label,
                      style: TextStyle(
                          color: sel ? CP.accent : CP.textMid,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme(Color c) => SliderThemeData(
        trackHeight: 3,
        thumbColor: c,
        activeTrackColor: c,
        inactiveTrackColor: CP.border,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      );
}

// =============================================================================
// TIME PICKER WIDGET
// =============================================================================

class _TimePicker extends StatelessWidget {
  final TimeOfDay time;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(TimeOfDay)? onPick;
  const _TimePicker(
      {required this.time,
      required this.label,
      required this.icon,
      required this.color,
      this.onPick});

  @override
  Widget build(BuildContext context) {
    final disabled = onPick == null;
    return GestureDetector(
      onTap: disabled
          ? null
          : () async {
              final t = await showTimePicker(
                  context: context,
                  initialTime: time,
                  builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: CP.primary, surface: CP.card)),
                        child: child!,
                      ));
              if (t != null) onPick!(t);
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: disabled ? CP.surface : CP.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: disabled ? CP.divider : CP.border)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: disabled ? CP.textLo : color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: disabled ? CP.textLo : CP.textLo, fontSize: 10)),
                Text(
                    '${time.hour.toString().padLeft(2, '0')}'
                    ':${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        color: disabled ? CP.textMid : CP.textHi,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
              ],
            ),
            if (!disabled) ...[
              const Spacer(),
              Icon(Icons.edit_rounded, size: 13, color: color.withOpacity(0.6)),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIALOG DETALLE DEL BLOQUE
// =============================================================================

class _BlockDetailDialog extends StatelessWidget {
  final ProgramBlock block;
  const _BlockDetailDialog({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = block.color;
    return Dialog(
      backgroundColor: CP.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CP.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3))),
                    child: Icon(Icons.view_timeline_rounded,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(block.name,
                            style: const TextStyle(
                                color: CP.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        _ActiveBadge(active: block.isActive),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: CP.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: CP.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: CP.textMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: CP.divider, height: 1),
              const SizedBox(height: 16),

              // Playlist — clickeable
              GestureDetector(
                onTap: () => _openPlaylist(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: CP.primaryLo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CP.primary.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: CP.primaryLo,
                              borderRadius: BorderRadius.circular(7)),
                          child: const Icon(Icons.playlist_play_rounded,
                              size: 14, color: CP.primary)),
                      const SizedBox(width: 10),
                      const SizedBox(
                          width: 70,
                          child: Text('Playlist',
                              style:
                                  TextStyle(color: CP.textMid, fontSize: 12))),
                      Expanded(
                        child: Text(block.playlistName,
                            style: const TextStyle(
                                color: CP.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: CP.primary),
                    ],
                  ),
                ),
              ),

              _DetailRow(
                  icon: Icons.play_arrow_rounded,
                  label: 'Inicio',
                  value: block.startTimeStr),
              _DetailRow(
                  icon: Icons.stop_rounded,
                  label: 'Fin',
                  value: block.endTimeStr),
              _DetailRow(
                  icon: Icons.timelapse_rounded,
                  label: 'Duración',
                  value: block.durationStr),

              // Días
              const SizedBox(height: 10),
              _DetailLabel('Días de emisión'),
              const SizedBox(height: 6),
              Row(
                children: orderedDays.map((d) {
                  final active = block.days.contains(d);
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: active ? color.withOpacity(0.15) : CP.card,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color:
                                active ? color.withOpacity(0.4) : CP.border)),
                    child: Column(
                      children: [
                        Text(dayShort[d]!,
                            style: TextStyle(
                                color: active ? color : CP.textLo,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        Text(dayLabels[d]!.substring(0, 3),
                            style: TextStyle(
                                color:
                                    active ? color.withOpacity(0.7) : CP.textLo,
                                fontSize: 8)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (block.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _DetailLabel('Descripción'),
                Text(block.description!,
                    style: const TextStyle(
                        color: CP.textMid, fontSize: 12, height: 1.5)),
              ],

              const SizedBox(height: 20),

              // Acciones
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CPreateProgramSheet(
                          editing: block,
                          scheduleId: block.scheduleId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: CP.primary,
                        side: const BorderSide(color: CP.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9))),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('program_blocks')
                          .doc(block.id)
                          .update({'isActive': !block.isActive});
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: Icon(
                        block.isActive
                            ? Icons.pause_circle_rounded
                            : Icons.play_circle_rounded,
                        size: 14),
                    label: Text(block.isActive ? 'Desactivar' : 'Activar'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: block.isActive ? CP.amber : CP.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9))),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => _PlaylistPreviewDialog(
        playlistId: block.playlistId,
        playlistName: block.playlistName,
      ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: CP.textHi,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: CP.divider)),
              ],
            ),
          ),
          ...children,
        ],
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: CP.textMid,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                color: CP.textMid,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatPill(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: const TextStyle(color: CP.textLo, fontSize: 9)),
              ],
            ),
          ],
        ),
      );
}

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: active ? CP.greenLo : CP.redLo,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active
                    ? CP.green.withOpacity(0.3)
                    : CP.red.withOpacity(0.3))),
        child: Text(active ? 'Activa' : 'Inactiva',
            style: TextStyle(
                color: active ? CP.green : CP.red,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: CP.redLo,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CP.red.withOpacity(0.3))),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 14, color: CP.red),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: CP.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w500))),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
}

class _EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool compact;
  const _EmptyWidget(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.compact = false});
  @override
  Widget build(BuildContext ctx) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                  color: CP.primaryLo,
                  shape: BoxShape.circle,
                  border: Border.all(color: CP.primary.withOpacity(0.2))),
              child: Icon(icon, color: CP.primary, size: compact ? 26 : 34),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(title,
                style: TextStyle(
                    color: CP.textHi,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 14 : 17)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(subtitle,
                  style: const TextStyle(color: CP.textMid, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );
}

class _SkeletonScreen extends StatefulWidget {
  const _SkeletonScreen();
  @override
  State<_SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends State<_SkeletonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController CPtrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    CPtrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.6)
        .animate(CurvedAnimation(parent: CPtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    CPtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: List.generate(
                5,
                (i) => Container(
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: Color.lerp(CP.card, CP.cardHover, _anim.value),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CP.border)),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 60))),
          ),
        ),
      );
}

class _LoadingField extends StatelessWidget {
  const _LoadingField();
  @override
  Widget build(BuildContext ctx) => Container(
        height: 46,
        decoration: BoxDecoration(
            color: CP.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CP.border)),
        child: const Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: CP.primary))),
      );
}

class _NoDataField extends StatelessWidget {
  final String msg;
  const _NoDataField({required this.msg});
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: CP.amberLo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CP.amber.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: CP.amber),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: CP.amber, fontSize: 11))),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: CP.primaryLo,
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 14, color: CP.primary)),
            const SizedBox(width: 10),
            SizedBox(
                width: 70,
                child: Text(label,
                    style: const TextStyle(color: CP.textMid, fontSize: 12))),
            Text(value,
                style: const TextStyle(
                    color: CP.textHi,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _DetailLabel extends StatelessWidget {
  final String text;
  const _DetailLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: const TextStyle(
          color: CP.textMid,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3));
}

class _QuickDayBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _QuickDayBtn(
      {required this.label, required this.onTap, this.danger = false});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: danger ? CP.redLo : CP.accentLo,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: danger
                      ? CP.red.withOpacity(0.3)
                      : CP.accent.withOpacity(0.3))),
          child: Text(label,
              style: TextStyle(
                  color: danger ? CP.red : CP.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withOpacity(0.4))),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      );
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext ctx) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: 150.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _hovered
                      ? [const Color(0xFF5254F0), const Color(0xFF7C7EF7)]
                      : [CP.primary, const Color(0xFF818CF8)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                          color: CP.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Text(widget.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      );
}

class _IconBtnCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtnCard(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});
  @override
  State<_IconBtnCard> createState() => _IconBtnCardState();
}

class _IconBtnCardState extends State<_IconBtnCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext ctx) => Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: 120.ms,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _hovered
                      ? widget.color.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: _hovered
                          ? widget.color.withOpacity(0.4)
                          : Colors.transparent)),
              child: Icon(widget.icon, size: 15, color: widget.color),
            ),
          ),
        ),
      );
}

class _ScheduleListView extends StatelessWidget {
  final List<Schedule> schedules;
  const _ScheduleListView({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: schedules.length,
      itemBuilder: (_, i) => _ScheduleCard(schedule: schedules[i])
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 40)),
    );
  }
}

class _ScheduleCard extends ConsumerStatefulWidget {
  final Schedule schedule;
  const _ScheduleCard({required this.schedule});
  @override
  ConsumerState<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends ConsumerState<_ScheduleCard> {
  bool _hovered = false;
  bool CPonfirmDelete = false;
  void _showDayPicker(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => _ScheduleDayPickerDialog(schedule: widget.schedule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        CPonfirmDelete = false;
      }),
      child: GestureDetector(
        onTap: () => _open(context),
        child: AnimatedContainer(
          duration: 130.ms,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: _hovered ? CP.cardHover : CP.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _hovered ? CP.primary.withOpacity(0.5) : CP.border)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 14, 14),
            child: Row(
              children: [
                // Barra izquierda
                Container(
                  width: 5,
                  height: 54,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                      color: s.isActive ? CP.primary : CP.textLo,
                      borderRadius: BorderRadius.circular(4)),
                ),
                // Ícono
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: CP.primaryLo,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_view_week_rounded,
                      color: CP.primary, size: 22),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  color: CP.textHi,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(width: 8),
                          _ActiveBadge(active: s.isActive),
                        ],
                      ),
                      if (s.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(s.description!,
                            style: const TextStyle(
                                color: CP.textMid, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      _ScheduleBlocksPreview(scheduleId: s.id),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Acciones
                CPonfirmDelete
                    ? Row(children: [
                        const Text('¿Eliminar?',
                            style: TextStyle(color: CP.red, fontSize: 11)),
                        const SizedBox(width: 8),
                        _SmallBtn(
                            label: 'Sí',
                            color: CP.red,
                            onTap: () => _delete(context)),
                        const SizedBox(width: 4),
                        _SmallBtn(
                            label: 'No',
                            color: CP.textMid,
                            onTap: () =>
                                setState(() => CPonfirmDelete = false)),
                      ])
                    : Row(children: [
                        Switch(
                          value: s.isActive,
                          activeColor: CP.green,
                          onChanged: (v) => _toggleActive(v),
                        ),
                        _IconBtnCard(
                          icon: Icons.play_circle_rounded,
                          color: CP.green,
                          tooltip: 'Visualizar programación',
                          onTap: () => _showDayPicker(context),
                        ),
                        const SizedBox(width: 4),
                        _IconBtnCard(
                          icon: Icons.edit_rounded,
                          color: CP.primary,
                          tooltip: 'Editar nombre',
                          onTap: () => _edit(context),
                        ),
                        const SizedBox(width: 4),
                        _IconBtnCard(
                          icon: Icons.open_in_full_rounded,
                          color: CP.accent,
                          tooltip: 'Ver programación',
                          onTap: () => _open(context),
                        ),
                        const SizedBox(width: 4),
                        _IconBtnCard(
                          icon: Icons.delete_outline_rounded,
                          color: CP.red,
                          tooltip: 'Eliminar',
                          onTap: () => setState(() => CPonfirmDelete = true),
                        ),
                      ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(FirebaseFirestore.instance
        .collection('schedules')
        .doc(widget.schedule.id));
    final blocks = await FirebaseFirestore.instance
        .collection('program_blocks')
        .where('scheduleId', isEqualTo: widget.schedule.id)
        .get();
    for (final doc in blocks.docs) batch.delete(doc.reference);
    await batch.commit();
    if (ctx.mounted)
      ScaffoldMessenger.of(ctx)
          .showSnackBar(snack('Programación eliminada', bg: CP.red));
  }

  Future<void> _toggleActive(bool val) async {
    await FirebaseFirestore.instance
        .collection('schedules')
        .doc(widget.schedule.id)
        .update({'isActive': val});
  }

  void _edit(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CPreateScheduleSheet(editing: widget.schedule),
    );
  }

  void _open(BuildContext ctx) {
    Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => _ScheduleDetailScreen(schedule: widget.schedule),
        ));
  }
}

class _ScheduleBlocksPreview extends ConsumerWidget {
  final String scheduleId;
  const _ScheduleBlocksPreview({required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream directo para preview
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('program_blocks')
          .where('scheduleId', isEqualTo: scheduleId)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 20);
        final blocks = snap.data!.docs
            .map((d) => ProgramBlock.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList();
        final totalMin = blocks.fold(0, (s, b) => s + b.durationMinutes);
        final daysWithBlocks = <String>{};
        for (final b in blocks) {
          daysWithBlocks.addAll(b.days);
        }
        return Row(
          children: [
            // Chips de días
            ...orderedDays.map((d) {
              final has = daysWithBlocks.contains(d);
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: has ? CP.primaryMid : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: has ? CP.primary.withOpacity(0.5) : CP.border)),
                child: Text(dayShort[d]!,
                    style: TextStyle(
                        color: has ? CP.primary : CP.textLo,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              );
            }),
            const SizedBox(width: 10),
            Text('${blocks.length} bloques',
                style: const TextStyle(color: CP.textMid, fontSize: 10)),
            const SizedBox(width: 6),
            if (totalMin > 0)
              Text('· ${_fmtMinTot(totalMin)}',
                  style: const TextStyle(color: CP.textLo, fontSize: 10)),
          ],
        );
      },
    );
  }

  String _fmtMinTot(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${min}min';
    if (min == 0) return '${h}h';
    return '${h}h ${min}min';
  }
}

class _ScheduleDetailScreen extends ConsumerStatefulWidget {
  final Schedule schedule;
  const _ScheduleDetailScreen({required this.schedule});
  @override
  ConsumerState<_ScheduleDetailScreen> createState() =>
      _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<_ScheduleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    final blocksAsync =
        ref.watch(_blocksForScheduleProvider(widget.schedule.id));
    return Scaffold(
      backgroundColor: CP.bg,
      body: Column(
        children: [
          _buildHeader(blocksAsync),
          _buildTabBar(),
          Expanded(
            child: blocksAsync.when(
              loading: () => const _SkeletonScreen(),
              error: (e, _) => _EmptyWidget(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (blocks) => TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GridView(blocks: blocks),
                  _ListView(blocks: blocks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<ProgramBlock>> blocksAsync) {
    final total = blocksAsync.valueOrNull?.length ?? 0;
    final active =
        blocksAsync.valueOrNull?.where((b) => b.isActive).length ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
          color: CP.surface,
          border: Border(bottom: BorderSide(color: CP.divider))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: CP.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CP.border)),
              child: const Icon(Icons.arrow_back_rounded,
                  color: CP.textMid, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [CP.primary, Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_view_week_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.schedule.name,
                  style: const TextStyle(
                      color: CP.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('$total bloques · $active activos',
                  style: const TextStyle(color: CP.textMid, fontSize: 13)),
            ],
          ),
          const Spacer(),
          _StatPill(
              label: 'Semana',
              value: '$total bloques',
              color: CP.primary,
              icon: Icons.view_week_rounded),
          const SizedBox(width: 8),
          _StatPill(
              label: 'Activos',
              value: '$active',
              color: CP.green,
              icon: Icons.check_circle_rounded),
          const SizedBox(width: 16),
          _PrimaryBtn(
            label: '+ Nueva programación',
            onTap: () => _showCreateSheet(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTabBar() {
    return Container(
      color: CP.surface,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: CP.primary,
            unselectedLabelColor: CP.textMid,
            indicatorColor: CP.primary,
            indicatorWeight: 2,
            dividerColor: CP.divider,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: '📅 Vista Semanal'),
              Tab(text: '📋 Lista de bloques'),
            ],
          ),
          const Spacer(),
          ...orderedDays.map((d) {
            final sel = ref.watch(_selectedDayProvider) == d;
            return GestureDetector(
              onTap: () {
                ref.read(_selectedDayProvider.notifier).state = d;
                _tabs.animateTo(0);
              },
              child: AnimatedContainer(
                duration: 130.ms,
                margin: const EdgeInsets.only(left: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: sel ? CP.primaryMid : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: sel ? CP.primary.withOpacity(0.6) : CP.border)),
                child: Text(dayShort[d]!,
                    style: TextStyle(
                        color: sel ? CP.primary : CP.textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CPreateProgramSheet(scheduleId: widget.schedule.id),
    );
  }
}

class CPreateScheduleSheet extends ConsumerStatefulWidget {
  final Schedule? editing;
  const CPreateScheduleSheet({this.editing});
  @override
  ConsumerState<CPreateScheduleSheet> createState() =>
      CPreateScheduleSheetState();
}

class CPreateScheduleSheetState extends ConsumerState<CPreateScheduleSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _descCtrl.text = widget.editing!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companyId = await getCompanyId();
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'isActive': true,
        'companyId': companyId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.editing != null) {
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(widget.editing!.id)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('schedules').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(
        color: CP.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: CP.border)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: CP.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: CP.primaryLo,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_view_week_rounded,
                        size: 18, color: CP.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isEdit ? 'Editar programación' : 'Nueva programación',
                          style: const TextStyle(
                              color: CP.textHi,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const Text('Asigna un nombre a esta programación semanal',
                          style: TextStyle(color: CP.textMid, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: CP.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CP.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: CP.textMid),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: CP.divider, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) _ErrorBanner(message: _error!),
                    const _SheetLabel('Nombre de la programación *'),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: CP.textHi, fontSize: 13),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'El nombre es obligatorio'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Ej: Programación Principal, Verano 2025...',
                        hintStyle:
                            const TextStyle(color: CP.textLo, fontSize: 12),
                        prefixIcon: const Icon(Icons.label_outline_rounded,
                            size: 16, color: CP.textMid),
                        filled: true,
                        fillColor: CP.card,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: CP.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: CP.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: CP.borderFocus, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SheetLabel('Descripción (opcional)'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: CP.textHi, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Notas sobre esta programación...',
                        hintStyle:
                            const TextStyle(color: CP.textLo, fontSize: 12),
                        prefixIcon: const Icon(Icons.notes_rounded,
                            size: 16, color: CP.textMid),
                        filled: true,
                        fillColor: CP.card,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: CP.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: CP.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: CP.borderFocus, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CP.primary,
                            disabledBackgroundColor: CP.card,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(isEdit ? 'Actualizar' : 'Crear programación',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.08, duration: 280.ms, curve: Curves.easeOut)
        .fadeIn(duration: 200.ms);
  }
}

class _PlaylistPreviewDialog extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  const _PlaylistPreviewDialog(
      {required this.playlistId, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CP.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CP.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: CP.primaryLo,
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.playlist_play_rounded,
                        color: CP.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(playlistName,
                            style: const TextStyle(
                                color: CP.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const Text('Contenido de la playlist',
                            style: TextStyle(color: CP.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: CP.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: CP.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: CP.textMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: CP.divider, height: 1),
              const SizedBox(height: 12),

              // Clips de la playlist desde Firestore
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('playlists')
                    .doc(playlistId)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: CP.primary),
                      ),
                    );
                  }
                  if (!snap.hasData || !snap.data!.exists) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Playlist no encontrada',
                          style: TextStyle(color: CP.textMid, fontSize: 13)),
                    );
                  }
                  final data = snap.data!.data() as Map<String, dynamic>;
                  final clips = (data['clips'] as List?) ?? [];
                  final totalSec = clips.fold<int>(0,
                      (s, c) => s + ((c['durationSec'] as num?)?.toInt() ?? 0));

                  if (clips.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Esta playlist no tiene clips',
                            style: TextStyle(color: CP.textMid, fontSize: 13)),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats
                      Row(
                        children: [
                          _StatPill(
                              label: 'Clips',
                              value: '${clips.length}',
                              color: CP.primary,
                              icon: Icons.video_library_rounded),
                          const SizedBox(width: 8),
                          _StatPill(
                              label: 'Duración total',
                              value: _fmtSec(totalSec),
                              color: CP.accent,
                              icon: Icons.timer_rounded),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Lista de clips
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: clips.length,
                          itemBuilder: (_, i) {
                            final clip = clips[i] as Map<String, dynamic>;
                            final name =
                                clip['name'] ?? clip['title'] ?? 'Sin nombre';
                            final dur =
                                (clip['durationSec'] as num?)?.toInt() ?? 0;
                            final type = clip['type'] ?? 'video';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                  color: CP.card,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: CP.border)),
                              child: Row(
                                children: [
                                  // Número
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                        color: CP.primaryLo,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: const TextStyle(
                                              color: CP.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Ícono tipo
                                  Icon(
                                      type == 'image'
                                          ? Icons.image_rounded
                                          : type == 'url'
                                              ? Icons.language_rounded
                                              : Icons.video_file_rounded,
                                      size: 14,
                                      color: CP.textMid),
                                  const SizedBox(width: 8),
                                  // Nombre
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            color: CP.textHi,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  // Duración
                                  if (dur > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: CP.accentLo,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Text(_fmtSec(dur),
                                          style: const TextStyle(
                                              color: CP.accent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: CP.textMid,
                      side: const BorderSide(color: CP.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9))),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtSec(int s) {
    if (s == 0) return '—';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}min';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }
}

class _ScheduleDayPickerDialog extends StatefulWidget {
  final Schedule schedule;
  const _ScheduleDayPickerDialog({required this.schedule});
  @override
  State<_ScheduleDayPickerDialog> createState() =>
      _ScheduleDayPickerDialogState();
}

class _ScheduleDayPickerDialogState extends State<_ScheduleDayPickerDialog> {
  String _selectedDay = orderedDays[DateTime.now().weekday - 1];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CP.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CP.border)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: CP.greenLo,
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.play_circle_rounded,
                        color: CP.green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.schedule.name,
                            style: const TextStyle(
                                color: CP.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        const Text('¿Qué día deseas visualizar?',
                            style: TextStyle(color: CP.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: CP.card,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: CP.border)),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: CP.textMid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: CP.divider, height: 1),
              const SizedBox(height: 16),

              // Selector de días
              const Text('Selecciona el día',
                  style: TextStyle(
                      color: CP.textMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: orderedDays.map((d) {
                  final sel = d == _selectedDay;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = d),
                      child: AnimatedContainer(
                        duration: 130.ms,
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: sel ? CP.greenLo : CP.card,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color:
                                    sel ? CP.green.withOpacity(0.6) : CP.border,
                                width: sel ? 1.5 : 1)),
                        child: Column(
                          children: [
                            Text(dayShort[d]!,
                                style: TextStyle(
                                    color: sel ? CP.green : CP.textMid,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 2),
                            Text(dayLabels[d]!.substring(0, 3),
                                style: TextStyle(
                                    color: sel
                                        ? CP.green.withOpacity(0.7)
                                        : CP.textLo,
                                    fontSize: 8),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Botón reproducir
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => SchedulePlaybackDialog(
                        schedule: widget.schedule,
                        day: _selectedDay,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Ver programación del ${dayLabels[_selectedDay]}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CP.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
