
import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/enums.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class KanbanConv {
  final WAConversation conv;
  final String botId;
  SalesStage stage;
  KanbanConv({required this.conv, required this.botId, required this.stage});
}



class _KanbanColumn extends StatelessWidget {
  final SalesStage stage;
  final List<KanbanConv> cards;
  final List<SalesStage> allStages;
  final Function(KanbanConv, SalesStage) onMove;
  final Function(String convId, String botId) onOpenTrace;
  final String Function(String botId) botName;

  const _KanbanColumn({
    required this.stage,
    required this.cards,
    required this.allStages,
    required this.onMove,
    required this.onOpenTrace,
    required this.botName,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanConv>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) => onMove(details.data, stage),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 230,
          margin: const EdgeInsets.only(right: 12),
          decoration: isHovering
              ? BoxDecoration(
                  color: stage.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stage.color.withOpacity(0.5),
                    width: 2,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: stage.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: stage.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(stage.icon, size: 15, color: stage.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(stage.label,
                          style: TextStyle(
                              color: stage.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: stage.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${cards.length}',
                          style: TextStyle(
                              color: stage.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...cards.map((item) => KanbanCard(
                    item: item,
                    allStages: allStages,
                    onMove: onMove,
                    onOpenTrace: onOpenTrace,
                    botName: botName(item.botId),
                  )),
              if (cards.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? stage.color.withOpacity(0.08)
                        : WAColors.card.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHovering
                          ? stage.color.withOpacity(0.4)
                          : WAColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(isHovering ? Icons.add_circle_rounded : stage.icon,
                          size: 24,
                          color: isHovering
                              ? stage.color
                              : WAColors.textMuted.withOpacity(0.4)),
                      const SizedBox(height: 6),
                      Text(
                        isHovering ? 'Soltar aquí' : 'Sin contactos',
                        style: TextStyle(
                          color: isHovering
                              ? stage.color
                              : WAColors.textMuted.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: isHovering ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}



class KanbanView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final Function(String convId, String botId) onOpenTrace;

  const KanbanView({
    required this.service,
    required this.bots,
    required this.onOpenTrace,
  });

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  List<KanbanConv> _all = [];
  bool _loading = true;

  // Filtros
  String _botFilter = 'all';
  String _searchText = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _modeFilter = 'all'; // all | ai | human

  final _searchCtrl = TextEditingController();

  // Almacenamiento local de stages (simula persistencia en memoria)
  final Map<String, SalesStage> _stageMap = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

// Agrega este método en _KanbanViewState para preservar stages entre recargas:

Future<void> _load() async {
  setState(() => _loading = true);
  final List<KanbanConv> result = [];
  for (final bot in widget.bots) {
    final convs = await widget.service.getConversations(bot.id);
    for (final conv in convs) {
      // Preserva el stage ya asignado si existe, si no usa inicial
      final stage = _stageMap[conv.id] ?? SalesStage.inicial;
      result.add(KanbanConv(conv: conv, botId: bot.id, stage: stage));
    }
  }
  if (mounted) {
    setState(() {
      _all = result;
      _loading = false;
    });
  }
}

  List<KanbanConv> get _filtered {
    return _all.where((k) {
      if (_botFilter != 'all' && k.botId != _botFilter) return false;
      if (_modeFilter == 'ai' && k.conv.humanControl) return false;
      if (_modeFilter == 'human' && !k.conv.humanControl) return false;
      if (_searchText.isNotEmpty) {
        final q = _searchText.toLowerCase();
        if (!k.conv.contactName.toLowerCase().contains(q) &&
            !k.conv.from.toLowerCase().contains(q) &&
            !k.conv.lastMessage.toLowerCase().contains(q)) return false;
      }
      if (_dateFrom != null) {
        if (k.conv.lastMessageAt.isBefore(_dateFrom!)) return false;
      }
      if (_dateTo != null) {
        final end = _dateTo!.add(const Duration(days: 1));
        if (k.conv.lastMessageAt.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  Map<SalesStage, List<KanbanConv>> get _grouped {
    final map = <SalesStage, List<KanbanConv>>{};
    for (final s in SalesStage.values) map[s] = [];
    for (final k in _filtered) map[k.stage]!.add(k);
    return map;
  }

  void _moveStage(KanbanConv item, SalesStage newStage) {
    setState(() {
      item.stage = newStage;
      _stageMap[item.conv.id] = newStage;
    });
  }

  String _botName(String botId) {
    try { return widget.bots.firstWhere((b) => b.id == botId).name; }
    catch (_) { return botId; }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: WAColors.green,
            surface: WAColors.card,
            onSurface: WAColors.textPri,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _dateFrom = picked;
        else _dateTo = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Kanban de Ventas',
            subtitle: 'Gestión visual del estado de cada contacto',
            icon: Icons.view_kanban_rounded,
            iconColor: WAColors.accent,
            actions: [
              HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
            ],
          ),
          // ── Barra de filtros ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: WAColors.surface,
            child: Row(
              children: [
                // Búsqueda
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: WAColors.textPri, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Buscar contacto...',
                      hintStyle: const TextStyle(color: WAColors.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: WAColors.textMuted, size: 16),
                      filled: true,
                      fillColor: WAColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _searchText = v),
                  ),
                ),
                const SizedBox(width: 10),
                // Filtro Bot
                if (widget.bots.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: WAColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: WAColors.border),
                    ),
                    child: DropdownButton<String>(
                      value: _botFilter,
                      underline: const SizedBox(),
                      dropdownColor: WAColors.card,
                      style: const TextStyle(color: WAColors.textPri, fontSize: 12),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Todos los bots')),
                        ...widget.bots.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                      ],
                      onChanged: (v) => setState(() => _botFilter = v ?? 'all'),
                    ),
                  ),
                const SizedBox(width: 10),
                // Filtro modo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: WAColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WAColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _modeFilter,
                    underline: const SizedBox(),
                    dropdownColor: WAColors.card,
                    style: const TextStyle(color: WAColors.textPri, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('IA + Humano')),
                      DropdownMenuItem(value: 'ai', child: Text('Solo IA')),
                      DropdownMenuItem(value: 'human', child: Text('Solo Humano')),
                    ],
                    onChanged: (v) => setState(() => _modeFilter = v ?? 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                // Fecha desde
                InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _dateFrom != null ? WAColors.accent.withOpacity(0.15) : WAColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dateFrom != null ? WAColors.accent.withOpacity(0.4) : WAColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 13,
                            color: _dateFrom != null ? WAColors.accent : WAColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          _dateFrom != null
                              ? DateFormat('dd/MM/yy').format(_dateFrom!)
                              : 'Desde',
                          style: TextStyle(
                            color: _dateFrom != null ? WAColors.accent : WAColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Fecha hasta
                InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _dateTo != null ? WAColors.accent.withOpacity(0.15) : WAColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dateTo != null ? WAColors.accent.withOpacity(0.4) : WAColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 13,
                            color: _dateTo != null ? WAColors.accent : WAColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          _dateTo != null
                              ? DateFormat('dd/MM/yy').format(_dateTo!)
                              : 'Hasta',
                          style: TextStyle(
                            color: _dateTo != null ? WAColors.accent : WAColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Limpiar fechas
                if (_dateFrom != null || _dateTo != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() { _dateFrom = null; _dateTo = null; }),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: WAColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: WAColors.error),
                    ),
                  ),
                ],
                const Spacer(),
                // Conteo total
                Text(
                  '${_filtered.length} contactos',
                  style: const TextStyle(color: WAColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // ── Tablero Kanban ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: WAColors.green))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: SalesStage.values.map((stage) {
                        final cards = grouped[stage] ?? [];
                        return _KanbanColumn(
                          stage: stage,
                          cards: cards,
                          allStages: SalesStage.values.toList(),
                          onMove: _moveStage,
                          onOpenTrace: widget.onOpenTrace,
                          botName: _botName,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class KanbanCard extends StatelessWidget {
  final KanbanConv item;
  final List<SalesStage> allStages;
  final Function(KanbanConv, SalesStage) onMove;
  final Function(String convId, String botId) onOpenTrace;
  final String botName;

  const KanbanCard({
    required this.item,
    required this.allStages,
    required this.onMove,
    required this.onOpenTrace,
    required this.botName,
  });

  @override
  Widget build(BuildContext context) {
    final conv = item.conv;
    final isActive = DateTime.now().difference(conv.lastMessageAt).inHours < 24;
    final stage = item.stage;

    return Draggable<KanbanConv>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 210,
            child: _buildCard(conv, isActive, stage),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(conv, isActive, stage),
      ),
      child: GestureDetector(
        onTap: () => onOpenTrace(conv.id, item.botId),
        child: _buildCard(conv, isActive, stage),
      ),
    );
  }

  Widget _buildCard(WAConversation conv, bool isActive, SalesStage stage) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? stage.color.withOpacity(0.35) : WAColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: stage.color.withOpacity(0.2),
                    child: Text(
                      conv.contactName.isNotEmpty ? conv.contactName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: stage.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: WAColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: WAColors.card, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conv.contactName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    Text(conv.from.replaceAll('@c.us', ''),
                        style: const TextStyle(color: WAColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.drag_indicator_rounded,
                  size: 14, color: WAColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(conv.lastMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: WAColors.textSec, fontSize: 11, height: 1.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, size: 10, color: WAColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(botName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WAColors.textMuted, fontSize: 10)),
              ),
              Text(_fmt(conv.lastMessageAt),
                  style: const TextStyle(color: WAColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: conv.humanControl
                      ? WAColors.human.withOpacity(0.15)
                      : WAColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  conv.humanControl ? 'Humano' : 'IA',
                  style: TextStyle(
                    color: conv.humanControl ? WAColors.human : WAColors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<SalesStage>(
                onSelected: (s) => onMove(item, s),
                color: WAColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: WAColors.border),
                ),
                itemBuilder: (_) => allStages
                    .where((s) => s != item.stage)
                    .map((s) => PopupMenuItem<SalesStage>(
                          value: s,
                          child: Row(
                            children: [
                              Icon(s.icon, size: 14, color: s.color),
                              const SizedBox(width: 8),
                              Text(s.label,
                                  style: TextStyle(
                                      color: s.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: WAColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WAColors.accent.withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Mover', style: TextStyle(color: WAColors.accent, fontSize: 10)),
                      SizedBox(width: 3),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: WAColors.accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('dd/MM').format(dt);
  }
}