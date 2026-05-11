import 'package:digitaltv/ui/panel/panel3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
abstract class _EC {
  static const bg       = Color(0xFF070B12);
  static const surface  = Color(0xFF0C1018);
  static const card     = Color(0xFF111827);
  static const cardHi   = Color(0xFF151E2F);
  static const border   = Color(0xFF1F2D45);
  static const primary  = Color(0xFF6366F1);
  static const primaryLo= Color(0x1A6366F1);
  static const accent   = Color(0xFF38BDF8);
  static const green    = Color(0xFF22C55E);
  static const amber    = Color(0xFFF59E0B);
  static const red      = Color(0xFFEF4444);
  static const purple   = Color(0xFFA855F7);
  static const purpleLo = Color(0x1AA855F7);
  static const textHi   = Color(0xFFF1F5FF);
  static const textMid  = Color(0xFF7B8DB0);
  static const textLo   = Color(0xFF2E3D5C);
  static const divider  = Color(0xFF141E30);
  static const track1   = Color(0xFF6366F1);
  static const track2   = Color(0xFF38BDF8);
  static const track3   = Color(0xFF22C55E);
  static const track4   = Color(0xFFF59E0B);
  static const track5   = Color(0xFFA855F7);
}
class PlaylistsListDialog extends StatefulWidget {
  final WidgetRef ref;
  const PlaylistsListDialog({required this.ref});

  @override
  State<PlaylistsListDialog> createState() => _PlaylistsListDialogState();
}

class _PlaylistsListDialogState extends State<PlaylistsListDialog> {
  String? _confirmDeleteId;
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/'
    '${d.month.toString().padLeft(2,'0')}/'
    '${d.year}  '
    '${d.hour.toString().padLeft(2,'0')}:'
    '${d.minute.toString().padLeft(2,'0')}';

  @override
Widget build(BuildContext context) {
  final playlists = widget.ref.watch(savedPlaylistsProvider);
  final screenW   = MediaQuery.of(context).size.width;
  final isNarrow  = screenW < 700;

  var filtered = playlists.where((p) {
    if (_filter == 'clips0') return p.clips.isEmpty;
    if (_filter == 'clips+') return p.clips.isNotEmpty;
    return true;
  }).where((p) =>
    _search.isEmpty ||
    p.name.toLowerCase().contains(_search.toLowerCase())
  ).toList();

  return Scaffold(
    backgroundColor: _EC.bg,
    body: Column(
      children: [
        // ── Header ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          decoration: const BoxDecoration(
            color: _EC.surface,
            border: Border(bottom: BorderSide(color: _EC.divider))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _EC.primaryLo,
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.video_library_rounded,
                      color: _EC.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mis playlists guardadas1',
                          style: TextStyle(color: _EC.textHi,
                            fontWeight: FontWeight.w800, fontSize: 18,
                            letterSpacing: -0.3)),
                        Text(
                          '${playlists.length} playlist${playlists.length != 1 ? 's' : ''} guardadas',
                          style: const TextStyle(
                            color: _EC.textMid, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search + Filtros
              if (isNarrow) ...[
                _searchBox(),
                const SizedBox(height: 10),
                _filterRow(playlists),
              ] else
                Row(
                  children: [
                    Expanded(child: _searchBox()),
                    const SizedBox(width: 14),
                    _filterRow(playlists),
                  ],
                ),
            ],
          ),
        ),

        // ── Lista ─────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: _EC.primaryLo,
                        shape: BoxShape.circle,
                        border: Border.all(color: _EC.primary.withOpacity(0.2))),
                      child: const Icon(Icons.inbox_rounded,
                        color: _EC.primary, size: 30)),
                    const SizedBox(height: 16),
                    const Text('Sin playlists',
                      style: TextStyle(color: _EC.textHi,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('No hay playlists que coincidan',
                      style: TextStyle(color: _EC.textMid, fontSize: 13)),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 24,
                  vertical: 16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final pl = filtered[i];
                  final isConfirming = _confirmDeleteId == pl.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlaylistRow(
                      playlist: pl,
                      isNarrow: isNarrow,
                      isConfirming: isConfirming,
                      fmtDate: _fmtDate,
                      onVisualize: () => _visualize(context, pl),
                      onEdit: () => _loadInEditor(context, pl),
                      onCopyLink: () {
                        Clipboard.setData(ClipboardData(text: pl.viewLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackEC('Link copiado'));
                      },
                      onDelete: () =>
                        setState(() => _confirmDeleteId = pl.id),
                      onConfirmDelete: () {
                        widget.ref.read(savedPlaylistsProvider.notifier)
                          .remove(pl.id);
                        setState(() => _confirmDeleteId = null);
                      },
                      onCancelDelete: () =>
                        setState(() => _confirmDeleteId = null),
                    ),
                  );
                },
              ),
        ),

        // ── Footer ────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
            MediaQuery.of(context).padding.bottom + 16),
          decoration: const BoxDecoration(
            color: _EC.surface,
            border: Border(top: BorderSide(color: _EC.divider))),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _EC.textMid,
                side: const BorderSide(color: _EC.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              child: const Text('Cerrar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _searchBox() => Container(
    height: 38,
    decoration: BoxDecoration(
      color: _EC.card,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _EC.border)),
    child: TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: _EC.textHi, fontSize: 12),
      decoration: const InputDecoration(
        hintText: 'Buscar playlists...',
        hintStyle: TextStyle(color: _EC.textLo, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded,
          size: 16, color: _EC.textMid),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 9),
      ),
      onChanged: (v) => setState(() => _search = v),
    ),
  );

  Widget _filterRow(List<SavedPlaylist> all) {
    final tabs = [
      ('all',   'Todas',     all.length),
      ('clips+','Con clips', all.where((p) => p.clips.isNotEmpty).length),
      ('clips0','Vacías',    all.where((p) => p.clips.isEmpty).length),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tabs.map((t) {
        final (id, label, count) = t;
        final sel = _filter == id;
        return GestureDetector(
          onTap: () => setState(() => _filter = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? _EC.primaryLo : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? _EC.primary.withOpacity(0.5) : _EC.border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                  style: TextStyle(
                    color: sel ? _EC.primary : _EC.textMid,
                    fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: sel
                      ? _EC.primary.withOpacity(0.2) : _EC.border,
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('$count',
                    style: TextStyle(
                      color: sel ? _EC.primary : _EC.textLo,
                      fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

 void _visualize(BuildContext context, SavedPlaylist pl) {
  // Navigator.pop(context);  ← ESTO ERA EL CRASH, eliminarlo
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _EC.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _EC.border)),
      title: Text(pl.name,
        style: const TextStyle(color: _EC.textHi, fontSize: 15)),
      content: Text('Visualizador próximamente',
        style: const TextStyle(color: _EC.textMid)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar',
            style: TextStyle(color: _EC.primary))),
      ],
    ),
  );
}

  void _loadInEditor(BuildContext context, SavedPlaylist pl) {
    final notifier = widget.ref.read(editorClipsProvider.notifier);
    for (final c in notifier.state.toList()) notifier.remove(c.id);
    for (final c in pl.clips) notifier.add(c);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      _snackEC('"${pl.name}" cargada en el editor'));
  }

  SnackBar _snackEC(String msg) => SnackBar(
    content: Text(msg, style: const TextStyle(color: _EC.textHi)),
    backgroundColor: _EC.card,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: _EC.border)),
    duration: const Duration(seconds: 2),
  );
}

// ── Fila de playlist ──────────────────────────────────────────────────────────

class _PlaylistRow extends StatefulWidget {
  final SavedPlaylist playlist;
  final bool isNarrow;
  final bool isConfirming;
  final String Function(DateTime) fmtDate;
  final VoidCallback onVisualize;
  final VoidCallback onEdit;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;
  final VoidCallback onConfirmDelete;
  final VoidCallback onCancelDelete;

  const _PlaylistRow({
    required this.playlist,
    required this.isNarrow,
    required this.isConfirming,
    required this.fmtDate,
    required this.onVisualize,
    required this.onEdit,
    required this.onCopyLink,
    required this.onDelete,
    required this.onConfirmDelete,
    required this.onCancelDelete,
  });

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pl = widget.playlist;
    final clipsCount = pl.clips.length;
    final hasClips = clipsCount > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: EdgeInsets.symmetric(
          vertical: widget.isNarrow ? 14 : 16,
          horizontal: 4),
        color: _hovered
          ? _EC.primary.withOpacity(0.04) : Colors.transparent,
        child: widget.isNarrow
          ? _narrowLayout(pl, hasClips, clipsCount)
          : _wideLayout(pl, hasClips, clipsCount),
      ),
    );
  }

Widget _wideLayout(SavedPlaylist pl, bool hasClips, int clipsCount) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _hovered ? _EC.cardHi : _EC.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _hovered ? _EC.primary.withOpacity(0.4) : _EC.border)),
    child: Row(
      children: [
        // Ícono
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _EC.primaryLo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _EC.primary.withOpacity(0.25))),
          child: const Icon(Icons.video_library_rounded,
            color: _EC.primary, size: 20),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pl.name,
                style: TextStyle(
                  color: _hovered ? _EC.primary : _EC.textHi,
                  fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasClips
                        ? _EC.primaryLo : _EC.border.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '$clipsCount clip${clipsCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: hasClips ? _EC.primary : _EC.textLo,
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_rounded,
                    size: 10, color: _EC.textLo),
                  const SizedBox(width: 3),
                  Text(widget.fmtDate(pl.createdAt),
                    style: const TextStyle(color: _EC.textMid, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),

        // Link badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _EC.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _EC.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded, size: 11, color: _EC.textMid),
              const SizedBox(width: 4),
              SizedBox(
                width: 90,
                child: Text(pl.viewLink,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _EC.textMid, fontSize: 9,
                    fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Acciones
        if (widget.isConfirming)
          _confirmDelete()
        else
          _actionBtns(),
      ],
    ),
  );
}

Widget _narrowLayout(SavedPlaylist pl, bool hasClips, int clipsCount) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _EC.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _EC.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _EC.primaryLo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _EC.primary.withOpacity(0.25))),
              child: const Icon(Icons.video_library_rounded,
                color: _EC.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pl.name,
                    style: const TextStyle(
                      color: _EC.textHi,
                      fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$clipsCount clips • ${widget.fmtDate(pl.createdAt)}',
                    style: const TextStyle(color: _EC.textMid, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.isConfirming)
          _confirmDelete()
        else
          _actionBtns(),
      ],
    ),
  );
}

  Widget _actionBtns() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _ActionIcon(
        icon: Icons.play_arrow_rounded,
        color: _EC.accent,
        tooltip: 'Visualizar',
        onTap: widget.onVisualize),
      const SizedBox(width: 6),
      _ActionIcon(
        icon: Icons.edit_rounded,
        color: _EC.primary,
        tooltip: 'Cargar en editor',
        onTap: widget.onEdit),
      const SizedBox(width: 6),
      _ActionIcon(
        icon: Icons.link_rounded,
        color: _EC.green,
        tooltip: 'Copiar link',
        onTap: widget.onCopyLink),
      const SizedBox(width: 6),
      _ActionIcon(
        icon: Icons.delete_outline_rounded,
        color: _EC.red,
        tooltip: 'Eliminar',
        onTap: widget.onDelete),
    ],
  );

  Widget _confirmDelete() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('¿Eliminar?',
        style: TextStyle(color: _EC.red, fontSize: 11,
          fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: widget.onConfirmDelete,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _EC.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _EC.red.withOpacity(0.4))),
          child: const Text('Sí, eliminar',
            style: TextStyle(color: _EC.red,
              fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: widget.onCancelDelete,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _EC.card,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _EC.border)),
          child: const Text('Cancelar',
            style: TextStyle(color: _EC.textMid, fontSize: 11)),
        ),
      ),
    ],
  );
}

// Botón de acción reutilizable
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon, required this.color,
    required this.tooltip, required this.onTap});

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _hovered
              ? widget.color.withOpacity(0.15) : _EC.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                ? widget.color.withOpacity(0.5) : _EC.border)),
          child: Icon(widget.icon, size: 15, color: widget.color),
        ),
      ),
    ),
  );
}