// =============================================================================
// SCHEDULES SCREEN — Programación horaria de playlists
// =============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:digitaltv/ui/panel/panel.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final devicesAsync   = ref.watch(devicesStreamProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(
            title: 'Programación',
            subtitle: 'Programa cuándo y dónde se reproduce cada playlist',
            action: _AddButton(
              label: '+ Nueva programación',
              onTap: () => _showAddSchedule(context),
            ),
          ),
          Expanded(
            child: playlistsAsync.when(
              loading: () => const _SkeletonList(),
              error: (e, _) => _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error', subtitle: e.toString()),
              data: (playlists) => devicesAsync.when(
                loading: () => const _SkeletonList(),
                error: (e, _) => _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error', subtitle: e.toString()),
                data: (devices) => _ScheduleBody(
                  playlists: playlists,
                  devices: devices,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSchedule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddScheduleSheet(),
    );
  }
}

class _ScheduleBody extends ConsumerWidget {
  final List<PlaylistModel> playlists;
  final List<DeviceModel> devices;
  const _ScheduleBody({required this.playlists, required this.devices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('schedules')
        .orderBy('createdAt', descending: true)
        .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const _SkeletonList();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.schedule_rounded,
            title: 'Sin programaciones',
            subtitle: 'Crea una programación para automatizar tu contenido.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _ScheduleCard(
              id:           docs[i].id,
              data:         d,
              playlists:    playlists,
              devices:      devices,
            ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
          },
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final List<PlaylistModel> playlists;
  final List<DeviceModel> devices;
  const _ScheduleCard({
    required this.id,
    required this.data,
    required this.playlists,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final playlistName = data['playlistName'] ?? '—';
    final deviceName   = data['deviceName']   ?? 'Todos';
    final startTime    = data['startTime']     ?? '00:00';
    final endTime      = data['endTime']       ?? '23:59';
    final days         = List<String>.from(data['days'] ?? []);
    final isActive     = data['isActive'] ?? true;

    final dayLabels = {
      'mon': 'L', 'tue': 'M', 'wed': 'X',
      'thu': 'J', 'fri': 'V', 'sat': 'S', 'sun': 'D',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isActive ? _C.greenLo : _C.redLo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded,
              color: isActive ? _C.green : _C.red, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playlistName,
                  style: const TextStyle(
                    color: _C.textHi, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tv_rounded, size: 11, color: _C.textMid),
                    const SizedBox(width: 4),
                    Text(deviceName,
                      style: const TextStyle(color: _C.textMid, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded, size: 11, color: _C.textMid),
                    const SizedBox(width: 4),
                    Text('$startTime — $endTime',
                      style: const TextStyle(color: _C.textMid, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: dayLabels.entries.map((e) {
                    final active = days.contains(e.key);
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 22, height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? _C.primaryLo : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: active ? _C.primary.withOpacity(0.4) : _C.border),
                      ),
                      child: Text(e.value,
                        style: TextStyle(
                          color: active ? _C.primary : _C.textLo,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: isActive,
                activeColor: _C.green,
                onChanged: (v) {
                  FirebaseFirestore.instance
                    .collection('schedules').doc(id)
                    .update({'isActive': v});
                },
              ),
              _IconBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Eliminar',
                color: _C.red,
                size: 16,
                onTap: () {
                  FirebaseFirestore.instance
                    .collection('schedules').doc(id).delete();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
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
class _AddScheduleSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends ConsumerState<_AddScheduleSheet> {
  String? _selectedPlaylistId;
  String? _selectedPlaylistName;
  String? _selectedDeviceId;
  String? _selectedDeviceName;
  TimeOfDay _startTime = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 20, minute: 0);
  final Set<String> _days = {'mon','tue','wed','thu','fri'};
  bool _loading = false;

  final _dayLabels = {
    'mon': 'Lun', 'tue': 'Mar', 'wed': 'Mié',
    'thu': 'Jue', 'fri': 'Vie', 'sat': 'Sáb', 'sun': 'Dom',
  };

  String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  Future<void> _save() async {
    if (_selectedPlaylistId == null) return;
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('schedules').add({
      'playlistId':   _selectedPlaylistId,
      'playlistName': _selectedPlaylistName,
      'deviceId':     _selectedDeviceId,
      'deviceName':   _selectedDeviceName ?? 'Todos los dispositivos',
      'startTime':    _fmt(_startTime),
      'endTime':      _fmt(_endTime),
      'days':         _days.toList(),
      'isActive':     true,
      'createdAt':    FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final devicesAsync   = ref.watch(devicesStreamProvider);

    return _Sheet(
      title: 'Nueva programación',
      subtitle: 'Programa cuándo se reproduce el contenido',
      icon: Icons.schedule_rounded,
      iconColor: _C.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Contenido'),
          _SheetLabel('Playlist *'),
          playlistsAsync.when(
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (e, _) => Text(e.toString()),
            data: (playlists) => _DropdownField<String>(
              value: _selectedPlaylistId ?? '',
              items: ['', ...playlists.map((p) => p.id)],
              icon: Icons.playlist_play_rounded,
              onChanged: (v) {
                final pl = playlists.firstWhere((p) => p.id == v,
                  orElse: () => playlists.first);
                setState(() {
                  _selectedPlaylistId   = v;
                  _selectedPlaylistName = pl.name;
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          _SheetLabel('Dispositivo (opcional)'),
          devicesAsync.when(
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (e, _) => Text(e.toString()),
            data: (devices) => _DropdownField<String>(
              value: _selectedDeviceId ?? '',
              items: ['', ...devices.map((d) => d.id)],
              icon: Icons.tv_rounded,
              onChanged: (v) {
                final dv = devices.firstWhere((d) => d.id == v,
                  orElse: () => devices.first);
                setState(() {
                  _selectedDeviceId   = v;
                  _selectedDeviceName = dv.name;
                });
              },
            ),
          ),

          const SizedBox(height: 20),
          _SectionTitle('Horario'),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context, initialTime: _startTime);
                    if (t != null) setState(() => _startTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                          size: 16, color: _C.green),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Inicio',
                              style: TextStyle(color: _C.textLo, fontSize: 10)),
                            Text(_fmt(_startTime),
                              style: const TextStyle(
                                color: _C.textHi, fontWeight: FontWeight.w700,
                                fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context, initialTime: _endTime);
                    if (t != null) setState(() => _endTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stop_rounded,
                          size: 16, color: _C.red),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fin',
                              style: TextStyle(color: _C.textLo, fontSize: 10)),
                            Text(_fmt(_endTime),
                              style: const TextStyle(
                                color: _C.textHi, fontWeight: FontWeight.w700,
                                fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _SheetLabel('Días de la semana'),
          const SizedBox(height: 8),
          Row(
            children: _dayLabels.entries.map((e) {
              final selected = _days.contains(e.key);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    selected ? _days.remove(e.key) : _days.add(e.key);
                  }),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _C.primaryLo : _C.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                          ? _C.primary.withOpacity(0.5) : _C.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? _C.primary : _C.textMid,
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _SheetSubmitButton(
            label: 'Crear programación',
            loading: _loading,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ANALYTICS SCREEN — Estadísticas de reproducción
// =============================================================================

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync   = ref.watch(devicesStreamProvider);
    final playlistsAsync = ref.watch(playlistsStreamProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(
            title: 'Analytics',
            subtitle: 'Estadísticas de tus dispositivos y contenido',
            action: _AddButton(
              label: '↓ Exportar',
              onTap: () {},
            ),
          ),
          Expanded(
            child: devicesAsync.when(
              loading: () => const _SkeletonList(),
              error: (e, _) => _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error', subtitle: e.toString()),
              data: (devices) => playlistsAsync.when(
                loading: () => const _SkeletonList(),
                error: (e, _) => _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error', subtitle: e.toString()),
                data: (playlists) => _AnalyticsBody(
                  devices: devices,
                  playlists: playlists,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final List<DeviceModel> devices;
  final List<PlaylistModel> playlists;
  const _AnalyticsBody({required this.devices, required this.playlists});

  @override
  Widget build(BuildContext context) {
    final online  = devices.where((d) => d.status == DeviceStatus.online).length;
    final offline = devices.where((d) => d.status == DeviceStatus.offline).length;
    final totalItems = playlists.fold(0, (sum, p) => sum + p.items.length);
    final totalDuration = playlists.fold(0, (sum, p) =>
      sum + p.items.fold(0, (s, i) => s + i.durationSeconds));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiCard(
                label: 'Total dispositivos',
                value: '${devices.length}',
                icon: Icons.tv_rounded,
                color: _C.primary,
              ),
              _KpiCard(
                label: 'En línea',
                value: '$online',
                icon: Icons.circle,
                color: _C.green,
              ),
              _KpiCard(
                label: 'Playlists activas',
                value: '${playlists.where((p) => p.isActive).length}',
                icon: Icons.playlist_play_rounded,
                color: _C.accent,
              ),
              _KpiCard(
                label: 'Contenido total',
                value: '$totalItems items',
                icon: Icons.photo_library_rounded,
                color: _C.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SectionTitle('Estado de dispositivos'),
          const SizedBox(height: 12),

          // ── Device status list ────────────────────────────────────────────
          ...devices.map((d) {
            final isOnline = d.status == DeviceStatus.online;
            final lastSeen = d.lastSeen;
            String lastSeenStr = '—';
            if (lastSeen != null) {
              final diff = DateTime.now().difference(lastSeen);
              if (diff.inMinutes < 1)       lastSeenStr = 'Ahora';
              else if (diff.inHours < 1)    lastSeenStr = 'Hace ${diff.inMinutes}m';
              else if (diff.inDays < 1)     lastSeenStr = 'Hace ${diff.inHours}h';
              else                          lastSeenStr = 'Hace ${diff.inDays}d';
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? _C.green : _C.textLo,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.tv_rounded, size: 16, color: _C.textMid),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.name,
                      style: const TextStyle(
                        color: _C.textHi, fontWeight: FontWeight.w500,
                        fontSize: 13)),
                  ),
                  if (d.currentPlaylistName != null) ...[
                    const Icon(Icons.playlist_play_rounded,
                      size: 13, color: _C.textMid),
                    const SizedBox(width: 4),
                    Text(d.currentPlaylistName!,
                      style: const TextStyle(color: _C.textMid, fontSize: 12)),
                    const SizedBox(width: 16),
                  ],
                  Text(lastSeenStr,
                    style: const TextStyle(color: _C.textLo, fontSize: 11)),
                  const SizedBox(width: 12),
                  _Badge(
                    label: isOnline ? 'Online' : 'Offline',
                    color: isOnline ? _C.green : _C.textLo,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          _SectionTitle('Resumen de playlists'),
          const SizedBox(height: 12),

          // ── Playlist summary ──────────────────────────────────────────────
          ...playlists.map((p) {
            final dur = p.items.fold(0, (s, i) => s + i.durationSeconds);
            final mins = dur ~/ 60;
            final secs = dur % 60;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
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
                        Text(p.name,
                          style: const TextStyle(
                            color: _C.textHi, fontWeight: FontWeight.w500,
                            fontSize: 13)),
                        Text('${p.items.length} elementos',
                          style: const TextStyle(
                            color: _C.textMid, fontSize: 11)),
                      ],
                    ),
                  ),
                  _Badge(
                    label: mins > 0 ? '${mins}m ${secs}s' : '${secs}s',
                    color: _C.accent,
                  ),
                  const SizedBox(width: 8),
                  _ActiveBadge(active: p.isActive),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                  style: TextStyle(
                    color: color, fontWeight: FontWeight.w800,
                    fontSize: 20)),
                Text(label,
                  style: const TextStyle(
                    color: _C.textMid, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MEDIA LIBRARY SCREEN — Biblioteca centralizada de archivos
// =============================================================================

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreenHeader(
            title: 'Biblioteca de medios',
            subtitle: 'Gestiona todas tus imágenes, videos y recursos',
            action: _AddButton(
              label: '+ Agregar URL',
              onTap: () => _showAddMedia(context),
            ),
          ),

          // Search + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: _C.textHi, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Buscar medios...',
                        hintStyle: TextStyle(color: _C.textLo, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                          size: 16, color: _C.textMid),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterTabs(
                  selected: _filter,
                  tabs: [
                    ('all',   'Todos',    0),
                    ('image', 'Imágenes', 0),
                    ('video', 'Videos',   0),
                    ('url',   'URLs',     0),
                  ],
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('media_library')
                .orderBy('createdAt', descending: true)
                .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const _SkeletonList();
                var docs = snap.data!.docs;

                // Filter
                if (_filter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['type'] == _filter;
                  }).toList();
                }
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['name'] ?? '')
                      .toString().toLowerCase()
                      .contains(_search.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _EmptyState(
                    icon: Icons.photo_library_rounded,
                    title: 'Sin medios',
                    subtitle: 'Agrega URLs de imágenes y videos a tu biblioteca.',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 200,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _MediaCard(
                      id:   docs[i].id,
                      data: d,
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedia(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMediaSheet(),
    );
  }
}

class _MediaCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  const _MediaCard({required this.id, required this.data});

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Sin nombre';
    final type = widget.data['type'] ?? 'image';
    final url  = widget.data['url']  ?? '';

    final typeColor = type == 'image' ? _C.accent
                    : type == 'video' ? _C.purple : _C.amber;
    final typeIcon  = type == 'image' ? Icons.image_rounded
                    : type == 'video' ? Icons.videocam_rounded
                    : Icons.language_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 150.ms,
        decoration: BoxDecoration(
          color: _hovered ? _C.cardHover : _C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? _C.border.withOpacity(0.8) : _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11)),
                child: type == 'image'
                  ? Image.network(
                      'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=200&h=120&fit=cover',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.surface,
                        child: Center(
                          child: Icon(typeIcon, color: typeColor, size: 32)),
                      ),
                    )
                  : Container(
                      color: _C.surface,
                      child: Center(
                        child: Icon(typeIcon, color: typeColor, size: 32)),
                    ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _C.textHi, fontWeight: FontWeight.w500,
                            fontSize: 12)),
                        _Badge(label: type, color: typeColor),
                      ],
                    ),
                  ),
                  _IconBtn(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copiar URL',
                    color: _C.accent,
                    size: 14,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        _snack('URL copiada'));
                    },
                  ),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Eliminar',
                    color: _C.red,
                    size: 14,
                    onTap: () {
                      FirebaseFirestore.instance
                        .collection('media_library').doc(widget.id).delete();
                    },
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

class _AddMediaSheet extends ConsumerStatefulWidget {
  const _AddMediaSheet();

  @override
  ConsumerState<_AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends ConsumerState<_AddMediaSheet> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl  = TextEditingController();
  String _type    = 'image';
  bool _loading   = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _urlCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nombre y URL son obligatorios');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await FirebaseFirestore.instance.collection('media_library').add({
      'name':      _nameCtrl.text.trim(),
      'url':       _urlCtrl.text.trim(),
      'type':      _type,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Agregar a biblioteca',
      subtitle: 'Guarda una URL de imagen, video o sitio web',
      icon: Icons.photo_library_rounded,
      iconColor: _C.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          const _SheetLabel('Tipo de medio'),
          const SizedBox(height: 8),
          Row(
            children: [
              _OrientationChip(
                label: 'Imagen',
                icon: Icons.image_rounded,
                selected: _type == 'image',
                onTap: () => setState(() => _type = 'image'),
              ),
              const SizedBox(width: 8),
              _OrientationChip(
                label: 'Video',
                icon: Icons.videocam_rounded,
                selected: _type == 'video',
                onTap: () => setState(() => _type = 'video'),
              ),
              const SizedBox(width: 8),
              _OrientationChip(
                label: 'URL',
                icon: Icons.language_rounded,
                selected: _type == 'url',
                onTap: () => setState(() => _type = 'url'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SheetLabel('Nombre *'),
          _SheetField(
            controller: _nameCtrl,
            hint: 'Ej: Banner principal, Logo empresa',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 16),
          const _SheetLabel('URL *'),
          _SheetField(
            controller: _urlCtrl,
            hint: 'https://...',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          _SheetSubmitButton(
            label: 'Guardar en biblioteca',
            loading: _loading,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}