import 'package:digitaltv/provider/app_providers.dart' as current2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// =============================================================================
// SECTION 1 — ENUMS & ENTITIES
// =============================================================================

enum DeviceStatus { online, offline, warning }

enum ContentType { image, video, text, playlist }

// ── DeviceEntity ──────────────────────────────────────────────────────────────

class DeviceEntity {
  final String id;
  final String name;
  final String uniqueDeviceId;
  final DeviceStatus status;
  final String? groupId;
  final String? groupName;
  final DateTime lastSeen;
  final String? currentContentId;
  final Map<String, dynamic> metadata;

  const DeviceEntity({
    required this.id,
    required this.name,
    required this.uniqueDeviceId,
    required this.status,
    this.groupId,
    this.groupName,
    required this.lastSeen,
    this.currentContentId,
    this.metadata = const {},
  });

  static DeviceStatus _parseStatus(String? s) {
    switch (s) {
      case 'online':
        return DeviceStatus.online;
      case 'warning':
        return DeviceStatus.warning;
      default:
        return DeviceStatus.offline;
    }
  }

  factory DeviceEntity.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final lastSeen = (d['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now();
    final diffMinutes = DateTime.now().difference(lastSeen).inMinutes;

    // Si visto hace menos de 3 minutos → online, independientemente del campo status
    DeviceStatus computedStatus;
    if (diffMinutes < 3) {
      computedStatus = DeviceStatus.online;
    } else if (diffMinutes < 10) {
      computedStatus = DeviceStatus.warning;
    } else {
      computedStatus = DeviceStatus.offline;
    }

    return DeviceEntity(
      id: doc.id,
      name: d['name'] as String? ?? 'Unknown Device',
      uniqueDeviceId: d['uniqueDeviceId'] as String? ?? doc.id,
      status: computedStatus, // <-- usa el computado, no el campo
      groupId: d['groupId'] as String?,
      groupName: d['groupName'] as String?,
      lastSeen: lastSeen,
      currentContentId: d['currentContentId'] as String?,
      metadata: (d['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'uniqueDeviceId': uniqueDeviceId,
        'status': status.name,
        'groupId': groupId,
        'groupName': groupName,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'currentContentId': currentContentId,
        'metadata': metadata,
      };
}

// ── ContentEntity ─────────────────────────────────────────────────────────────

class ContentEntity {
  final String id;
  final ContentType type;
  final String? url;
  final String? textContent;
  final int durationSeconds;
  final DateTime createdAt;
  final String? ownerId;
  final List<String> tags;

  const ContentEntity({
    required this.id,
    required this.type,
    this.url,
    this.textContent,
    this.durationSeconds = 10,
    required this.createdAt,
    this.ownerId,
    this.tags = const [],
  });

  static ContentType _parseType(String? s) {
    switch (s) {
      case 'video':
        return ContentType.video;
      case 'text':
        return ContentType.text;
      case 'playlist':
        return ContentType.playlist;
      default:
        return ContentType.image;
    }
  }

  factory ContentEntity.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContentEntity(
      id: doc.id,
      type: _parseType(d['type'] as String?),
      url: d['url'] as String?,
      textContent: d['textContent'] as String?,
      durationSeconds: d['duration'] as int? ?? 10,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerId: d['ownerId'] as String?,
      tags: List<String>.from(d['tags'] as List? ?? []),
    );
  }
}

// =============================================================================
// SECTION 2 — APP COLORS
// =============================================================================

abstract class AppColors {
  // Primaries
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDim = Color(0xFF4F46E5);

  // Status
  static const Color online = Color(0xFF22C55E); // Green
  static const Color offline = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Neutrals
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

// =============================================================================
// SECTION 3 — THEME
// =============================================================================

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.surfaceLight,
    cardTheme: const CardTheme(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondaryLight,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.8,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    cardTheme: const CardTheme(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderDark),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondaryDark,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryDark,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// =============================================================================
// SECTION 4 — RIVERPOD PROVIDERS (Firestore Streams)
// =============================================================================

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final devicesStreamProvider = StreamProvider<List<DeviceEntity>>((ref) {
  final user = ref.watch(current2.currentUserProvider).valueOrNull;
  final companyId = user?.isSuperAdmin == true ? null : user?.companyId;

  Stream<QuerySnapshot> stream;

  if (companyId != null) {
    stream = FirebaseFirestore.instance
        .collection('devices')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance.collection('devices').snapshots();
  }

  return stream.map((snap) {
    final list = snap.docs.map(DeviceEntity.fromFirestore).toList();
    list.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return list;
  });
});

final contentStreamProvider = StreamProvider<List<ContentEntity>>((ref) {
  final user = ref.watch(current2.currentUserProvider).valueOrNull;
  final companyId = user?.isSuperAdmin == true ? null : user?.companyId;

  Stream<QuerySnapshot> stream;

  if (companyId != null) {
    stream = FirebaseFirestore.instance
        .collection('content')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  } else {
    stream = FirebaseFirestore.instance.collection('content').snapshots();
  }

  return stream.map((snap) {
    final list = snap.docs.map(ContentEntity.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

/// Stream de un dispositivo individual (para detail screens)
final singleDeviceProvider =
    StreamProvider.family<DeviceEntity?, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection('devices')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? DeviceEntity.fromFirestore(doc) : null);
});

// =============================================================================
// SECTION 5 — SHARED WIDGETS
// =============================================================================

// ── SkeletonCard ──────────────────────────────────────────────────────────────

class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 90,
    this.width,
    this.borderRadius = 12,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: isDark
              ? Color.lerp(
                  const Color(0xFF1E293B), const Color(0xFF334155), _anim.value)
              : Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF1F5F9),
                  _anim.value),
        ),
      ),
    );
  }
}

// ── StatCard ──────────────────────────────────────────────────────────────────

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final bool trendPositive;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendPositive,
    this.valueColor,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 1.0,
      upperBound: 1.018,
    );
    _scale = _hoverCtrl;
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(widget.icon, size: 18, color: widget.iconColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.trendPositive
                            ? AppColors.online.withOpacity(0.1)
                            : AppColors.offline.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trendPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 10,
                            color: widget.trendPositive
                                ? AppColors.online
                                : AppColors.offline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.trend,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.trendPositive
                                  ? AppColors.online
                                  : AppColors.offline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: widget.valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(widget.label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DeviceStatusChip ──────────────────────────────────────────────────────────

class DeviceStatusChip extends StatefulWidget {
  final DeviceEntity device;
  final bool showLabel;

  const DeviceStatusChip({
    super.key,
    required this.device,
    this.showLabel = false,
  });

  @override
  State<DeviceStatusChip> createState() => _DeviceStatusChipState();
}

class _DeviceStatusChipState extends State<DeviceStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.device.status == DeviceStatus.online) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (widget.device.status) {
      DeviceStatus.online => (AppColors.online, 'Online', Icons.tv_rounded),
      DeviceStatus.offline => (
          AppColors.offline,
          'Offline',
          Icons.tv_off_rounded
        ),
      DeviceStatus.warning => (
          AppColors.warning,
          'Warning',
          Icons.warning_amber_rounded
        ),
    };

    if (widget.showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    widget.device.status == DeviceStatus.online
                        ? 0.5 + _pulseCtrl.value * 0.5
                        : 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      );
    }

    // Compact chip (for status map grid)
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(
            widget.device.status == DeviceStatus.online
                ? 0.08 + _pulseCtrl.value * 0.08
                : 0.08,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// =============================================================================
// SECTION 6 — DASHBOARD SCREEN
// =============================================================================

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final contentAsync = ref.watch(contentStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WhatsappChatbotPage(
                                userId: 'G1R2jhY2dQa1TNg1Lg2kQJB6BDp1'

//  FirebaseAuth.instance.currentUser?.uid ?? '',
                                ),
                          ),
                        );
                      },
                      child: Text(
                        'Panel de control',
                        style: Theme.of(context).textTheme.headlineMedium,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat(
                      'EEEE d \'de\' MMMM',
                      'es_CO',
                    ).format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stat Cards ───────────────────────────────────────────────────────
          devicesAsync.when(
            loading: () => const _StatGridSkeleton(),
            error: (e, _) => _ErrorBox(message: e.toString()),
            data: (devices) {
              final online =
                  devices.where((d) => d.status == DeviceStatus.online).length;
              final offline =
                  devices.where((d) => d.status == DeviceStatus.offline).length;
              final warning =
                  devices.where((d) => d.status == DeviceStatus.warning).length;
              final uptimePct =
                  devices.isEmpty ? 0.0 : online / devices.length * 100;

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Dispositivos',
                      value: devices.length.toString(),
                      icon: Icons.tv_outlined,
                      iconColor: AppColors.primary,
                      trend: '',
                      trendPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Encendidos',
                      value: online.toString(),
                      icon: Icons.circle,
                      iconColor: AppColors.online,
                      trend: '${uptimePct.toStringAsFixed(1)}% uptime',
                      trendPositive: true,
                      valueColor: AppColors.online,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Apagados',
                      value: offline.toString(),
                      icon: Icons.power_off_outlined,
                      iconColor: AppColors.offline,
                      trend: warning > 0 ? '$warning warnings' : 'All clear',
                      trendPositive: warning == 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  contentAsync.when(
                    loading: () =>
                        const Expanded(child: SkeletonCard(height: 90)),
                    error: (_, __) => const SizedBox(),
                    data: (content) => Expanded(
                      child: StatCard(
                        label: 'Total Contenidos',
                        value: content.length.toString(),
                        icon: Icons.perm_media_outlined,
                        iconColor: AppColors.warning,
                        trend:
                            '${content.where((c) => c.type == ContentType.video).length} videos',
                        trendPositive: true,
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          ),

          const SizedBox(height: 28),

          // ── Device Map + Activity Feed ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Lista de dispositivos'),
                    const SizedBox(height: 12),
                    _DeviceStatusMap(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Actividad reciente'),
                    const SizedBox(height: 12),
                    _ActivityFeed(),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 28),

          // ── Quick Table ───────────────────────────────────────────────────
          const _SectionTitle('Todos'),
          const SizedBox(height: 12),
          _DevicesQuickList().animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 7 — DASHBOARD PRIVATE WIDGETS
// =============================================================================

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

// ── Error Box ─────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offline.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.offline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.offline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.offline, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Stat Grid Skeleton ────────────────────────────────────────────────────────

class _StatGridSkeleton extends StatelessWidget {
  const _StatGridSkeleton();

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
              child: const SkeletonCard(height: 90),
            ),
          ),
        ),
      );
}

// ── Device Status Map ─────────────────────────────────────────────────────────

class _DeviceStatusMap extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: devicesAsync.when(
          loading: () => const SkeletonCard(height: 160),
          error: (e, _) => _ErrorBox(message: e.toString()),
          data: (devices) {
            if (devices.isEmpty) {
              return const _EmptyState(
                icon: Icons.tv_off_rounded,
                label: 'No devices registered yet',
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: devices
                  .map(
                    (device) => Tooltip(
                      message:
                          '${device.name}\nID: ${device.uniqueDeviceId}\nLast seen: ${_relTime(device.lastSeen)}',
                      child: DeviceStatusChip(device: device),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  static String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Activity Feed ─────────────────────────────────────────────────────────────

class _ActivityFeed extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: devicesAsync.when(
          loading: () => Column(
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SkeletonCard(height: 48),
              ),
            ),
          ),
          error: (e, _) => _ErrorBox(message: e.toString()),
          data: (devices) {
            if (devices.isEmpty) {
              return const _EmptyState(
                icon: Icons.history_rounded,
                label: 'No activity yet',
              );
            }
            final sorted = [...devices]
              ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
            return Column(
              children:
                  sorted.take(6).map((d) => _ActivityItem(device: d)).toList(),
            );
          },
        ),
      ),
    );
  }
}

// ── Activity Item ─────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final DeviceEntity device;
  const _ActivityItem({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(device.lastSeen);
    final timeStr = diff.inSeconds < 60
        ? '${diff.inSeconds}s ago'
        : diff.inMinutes < 60
            ? '${diff.inMinutes}m ago'
            : '${diff.inHours}h ago';

    final (icon, color, label) = switch (device.status) {
      DeviceStatus.online => (Icons.tv_rounded, AppColors.online, 'Online'),
      DeviceStatus.offline => (
          Icons.power_off_outlined,
          AppColors.offline,
          'Offline'
        ),
      DeviceStatus.warning => (
          Icons.warning_amber_rounded,
          AppColors.warning,
          'Warning'
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                Text(
                  '$label · $timeStr',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Devices Quick List (Table) ────────────────────────────────────────────────

class _DevicesQuickList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesStreamProvider);
    final theme = Theme.of(context);
    final divColor = theme.dividerTheme.color ?? Colors.grey.withOpacity(0.2);

    return Card(
      child: devicesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: _ErrorBox(message: e.toString()),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: _EmptyState(
                icon: Icons.devices_rounded,
                label:
                    'No devices registered yet.\nAdd your first TV to get started.',
              ),
            );
          }

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: divColor)),
                ),
                children: ['Dispositivo', 'Estado', 'Grupo', 'Ultima conexión']
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(h.toUpperCase(),
                            style: theme.textTheme.labelSmall),
                      ),
                    )
                    .toList(),
              ),
              // Data rows
              ...devices.take(8).map((d) {
                final diff = DateTime.now().difference(d.lastSeen);
                final timeStr = diff.inSeconds < 60
                    ? '${diff.inSeconds}s ago'
                    : diff.inMinutes < 60
                        ? '${diff.inMinutes}m ago'
                        : '${diff.inHours}h ago';

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: divColor.withOpacity(0.5))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                          Text(d.uniqueDeviceId,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: DeviceStatusChip(device: d, showLabel: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(d.groupName ?? d.groupId ?? '—',
                          style: theme.textTheme.bodyMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(timeStr, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
