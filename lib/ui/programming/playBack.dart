import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:digitaltv/ui/programming/color.dart';
import 'package:digitaltv/ui/programming/helper/helper.dart';
import 'package:digitaltv/ui/programming/programing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SchedulePlaybackDialog extends StatefulWidget {
  final Schedule schedule;
  final String day;
  const SchedulePlaybackDialog({required this.schedule, required this.day});
  @override
  State<SchedulePlaybackDialog> createState() => _SchedulePlaybackDialogState();
}

class _SchedulePlaybackDialogState extends State<SchedulePlaybackDialog> {
  List<ProgramBlock>? _blocks;
  int CPurrentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  Future<void> _loadBlocks() async {
    final snap = await FirebaseFirestore.instance
        .collection('program_blocks')
        .where('scheduleId', isEqualTo: widget.schedule.id)
        .get();
    final all = snap.docs
        .map((d) =>
            ProgramBlock.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .where((b) => b.days.contains(widget.day) && b.isActive)
        .toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    if (mounted)
      setState(() {
        _blocks = all;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CP.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CP.border)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CP.divider))),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_rounded,
                      size: 18, color: CP.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.schedule.name,
                            style: const TextStyle(
                                color: CP.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        Text('Programación del ${dayLabels[widget.day]}',
                            style: const TextStyle(
                                color: CP.textMid, fontSize: 11)),
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
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: CP.green),
              )
            else if (_blocks == null || _blocks!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_rounded,
                        color: CP.textMid, size: 40),
                    const SizedBox(height: 12),
                    Text('Sin bloques el ${dayLabels[widget.day]}',
                        style: const TextStyle(
                            color: CP.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('No hay playlists programadas para este día',
                        style: TextStyle(color: CP.textMid, fontSize: 12)),
                  ],
                ),
              )
            else ...[
              // Lista de bloques del día
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_blocks!.length} bloques programados',
                        style: const TextStyle(
                            color: CP.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...List.generate(_blocks!.length, (i) {
                      final b = _blocks![i];
                      final isCurrent = i == CPurrentIndex;
                      return GestureDetector(
                        onTap: () => setState(() => CPurrentIndex = i),
                        child: AnimatedContainer(
                          duration: 130.ms,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: isCurrent
                                  ? b.color.withOpacity(0.15)
                                  : CP.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isCurrent
                                      ? b.color.withOpacity(0.6)
                                      : CP.border,
                                  width: isCurrent ? 1.5 : 1)),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: b.color,
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name,
                                        style: TextStyle(
                                            color:
                                                isCurrent ? b.color : CP.textHi,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                    Text(
                                        '${b.startTimeStr} — ${b.endTimeStr} · ${b.durationStr} · ${b.playlistName}',
                                        style: const TextStyle(
                                            color: CP.textMid, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: b.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('Seleccionado',
                                      style: TextStyle(
                                          color: b.color,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _playBlock(context, b),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: b.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: b.color.withOpacity(0.4))),
                                  child: Icon(Icons.play_arrow_rounded,
                                      size: 16, color: b.color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Botón reproducir seleccionado
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _playBlock(context, _blocks![CPurrentIndex]),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                        'Reproducir: ${_blocks![CPurrentIndex].playlistName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _blocks![CPurrentIndex].color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _playBlock(BuildContext ctx, ProgramBlock block) {
    FirebaseFirestore.instance
        .collection('playlists')
        .doc(block.playlistId)
        .get()
        .then((doc) {
      if (!doc.exists || !ctx.mounted) return;
      final data = doc.data() as Map<String, dynamic>;
      final rawClips = (data['clips'] as List? ?? []);

      final clips = rawClips.map((c) {
        try {
          return EditorClip.fromMap(c as Map<String, dynamic>);
        } catch (e) {
          return EditorClip(
            id: const Uuid().v4(),
            type: EditorLayerType.text,
            label: 'Clip',
            text: '',
            startSec: 0,
            durationSec: 5,
            trackIndex: 0,
          );
        }
      }).toList();
      DateTime _parseDate(dynamic raw) {
        if (raw == null) return DateTime.now();
        if (raw is Timestamp) return raw.toDate();
        if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
        return DateTime.now();
      }

      final playlist = SavedPlaylist(
        id: doc.id,
        name: data['name'] ?? block.playlistName,
        clips: clips,
        createdAt: _parseDate(data['createdAt']),
        viewLink: '',
      );

      showDialog(
        context: ctx,
        builder: (_) => PlaylistViewerDialog(playlist: playlist),
      );
    }).catchError((e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Error al cargar playlist: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    });
  }
}
