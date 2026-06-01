
  
  
// ─────────────────────────────────────────
// GLOBAL ANALYTICS VIEW
// ─────────────────────────────────────────
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GlobalAnalyticsView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final Function(WAChatbot) onSelectBot;
  const GlobalAnalyticsView({
    required this.service,
    required this.bots,
    required this.onSelectBot,
  });

  @override
  State<GlobalAnalyticsView> createState() => _GlobalAnalyticsViewState();
}

class _GlobalAnalyticsViewState extends State<GlobalAnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // botId -> lista de conversaciones
  Map<String, List<WAConversation>> _convsByBot = {};
  Map<String, List<WAMessage>> _messagesCache = {};
  bool _loading = true;
  String _selectedConvId = '';
  String _selectedBotFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    for (final bot in widget.bots) {
      final convs = await widget.service.getConversations(bot.id);
      _convsByBot[bot.id] = convs;
    }
    setState(() => _loading = false);
  }

  List<WAConversation> get _allConversations {
    if (_selectedBotFilter == 'all') {
      return _convsByBot.values.expand((e) => e).toList();
    }
    return _convsByBot[_selectedBotFilter] ?? [];
  }

  Future<List<WAMessage>> _getMessages(String convId) async {
    if (_messagesCache.containsKey(convId)) return _messagesCache[convId]!;
    final msgs = await widget.service.getMessages(convId);
    _messagesCache[convId] = msgs;
    return msgs;
  }

  int get _totalUsers => _allConversations.length;
  int get _activeUsers => _allConversations.where((c) {
        return DateTime.now().difference(c.lastMessageAt).inHours < 24;
      }).length;
  int get _humanControl => _allConversations.where((c) => c.humanControl).length;
  int get _aiOnly => _totalUsers - _humanControl;

  String _botNameForConv(String botId) {
    try {
      return widget.bots.firstWhere((b) => b.id == botId).name;
    } catch (_) {
      return botId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Analytics Global',
            subtitle: 'Todos los bots — embudo, usuarios y trazabilidad',
            icon: Icons.analytics_rounded,
            iconColor: WAColors.accent,
            actions: [
              // Filtro por bot
              if (widget.bots.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: WAColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WAColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedBotFilter,
                    underline: const SizedBox(),
                    dropdownColor: WAColors.card,
                    style: const TextStyle(color: WAColors.textPri, fontSize: 13),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Todos los bots')),
                      ...widget.bots.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedBotFilter = v ?? 'all';
                      _selectedConvId = '';
                    }),
                  ),
                ),
              const SizedBox(width: 8),
              HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
            ],
          ),
          Container(
            color: WAColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: WAColors.accent,
              unselectedLabelColor: WAColors.textMuted,
              indicatorColor: WAColors.accent,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(icon: Icon(Icons.filter_alt_rounded, size: 16), text: 'Embudo'),
                Tab(icon: Icon(Icons.group_rounded, size: 16), text: 'Usuarios'),
                Tab(icon: Icon(Icons.psychology_rounded, size: 16), text: 'Trazabilidad IA'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: WAColors.accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFunnelTab(),
                      _buildUsersTab(),
                      _buildTraceTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelTab() {
    final stages = [
      {'label': 'Total contactos', 'value': _totalUsers, 'color': WAColors.accent, 'icon': Icons.people_rounded},
      {'label': 'Activos últimas 24h', 'value': _activeUsers, 'color': WAColors.green, 'icon': Icons.online_prediction},
      {'label': 'Solo IA (sin humano)', 'value': _aiOnly, 'color': WAColors.info, 'icon': Icons.psychology_rounded},
      {'label': 'Derivados a humano', 'value': _humanControl, 'color': WAColors.human, 'icon': Icons.support_agent_rounded},
    ];
    final maxVal = _totalUsers == 0 ? 1 : _totalUsers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen por bot
          const Text('Resumen por bot',
              style: TextStyle(color: WAColors.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...widget.bots.map((bot) {
            final convs = _convsByBot[bot.id] ?? [];
            final active = convs.where((c) => DateTime.now().difference(c.lastMessageAt).inHours < 24).length;
            final human = convs.where((c) => c.humanControl).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => widget.onSelectBot(bot),
                borderRadius: BorderRadius.circular(12),
                child: WACard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bot.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.smart_toy_rounded, color: bot.statusColor, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bot.name,
                                style: const TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(bot.phoneNumber.isNotEmpty ? bot.phoneNumber : 'Sin número',
                                style: const TextStyle(color: WAColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    CompactStat('Total', '${convs.length}', WAColors.accent),
    const SizedBox(width: 20),
    CompactStat('Activos', '$active', WAColors.green),
    const SizedBox(width: 20),
    CompactStat('Humano', '$human', WAColors.human),
  ],
),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: WAColors.textMuted),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          // Embudo global
          const Text('Embudo global',
              style: TextStyle(color: WAColors.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          WACard(
            child: Column(
              children: stages.asMap().entries.map((entry) {
                final i = entry.key;
                final stage = entry.value;
                final val = stage['value'] as int;
                final color = stage['color'] as Color;
                final pct = (val / maxVal).clamp(0.0, 1.0);
                final widthFactor = 1.0 - (i * 0.08);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(stage['icon'] as IconData, color: color, size: 16),
                          const SizedBox(width: 8),
                          Text(stage['label'] as String,
                              style: const TextStyle(color: WAColors.textSec, fontSize: 13)),
                          const Spacer(),
                          Text('$val',
                              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(width: 8),
                          Text('${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: WAColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: widthFactor,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: WAColors.border,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: pct,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: color,
                                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final allConvs = [..._allConversations]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return Column(
      children: [
        // Cabecera con conteo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: WAColors.surface,
          child: Row(
            children: [
              const Icon(Icons.group_rounded, color: WAColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('${allConvs.length} usuarios totales',
                  style: const TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WAColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_activeUsers activos hoy',
                  style: const TextStyle(color: WAColors.green, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WAColors.human.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_humanControl en humano',
                  style: const TextStyle(color: WAColors.human, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        // Tabla de usuarios
        Expanded(
          child: allConvs.isEmpty
              ? EmptyState(
                  icon: Icons.group_off_rounded,
                  title: 'Sin usuarios',
                  subtitle: 'No hay conversaciones registradas',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allConvs.length,
                  itemBuilder: (_, i) {
                    final conv = allConvs[i];
                    final isActive = DateTime.now().difference(conv.lastMessageAt).inHours < 24;
                    final isNew = DateTime.now().difference(conv.lastMessageAt).inDays <= 7;
                    final botName = _botNameForConv(conv.botId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedConvId = conv.id;
                          _tabController.animateTo(2);
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: WAColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? WAColors.green.withOpacity(0.3)
                                  : WAColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar con número de orden
                              Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: WAColors.accent.withOpacity(0.15),
                                    radius: 22,
                                    child: Text(
                                      conv.contactName.isNotEmpty
                                          ? conv.contactName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: WAColors.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                  ),
                                  if (isActive)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: WAColors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: WAColors.card, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Info del usuario
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(conv.contactName,
                                            style: const TextStyle(
                                                color: WAColors.textPri,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        if (isNew) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: WAColors.accent.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('NUEVO',
                                                style: TextStyle(
                                                    color: WAColors.accent,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      conv.from.replaceAll('@c.us', ''),
                                      style: const TextStyle(color: WAColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              // Bot asignado
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bot',
                                        style: TextStyle(color: WAColors.textMuted, fontSize: 10)),
                                    Text(botName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: WAColors.textSec, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              // Último mensaje
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Último mensaje',
                                        style: TextStyle(color: WAColors.textMuted, fontSize: 10)),
                                    Text(
                                      conv.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: WAColors.textSec, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Estado y tiempo
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: conv.humanControl
                                          ? WAColors.human.withOpacity(0.15)
                                          : WAColors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      conv.humanControl ? 'Humano' : 'IA',
                                      style: TextStyle(
                                        color: conv.humanControl ? WAColors.human : WAColors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDiff(conv.lastMessageAt),
                                    style: const TextStyle(color: WAColors.textMuted, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Ver traza',
                                          style: TextStyle(color: WAColors.accent, fontSize: 10)),
                                      SizedBox(width: 2),
                                      Icon(Icons.arrow_forward_ios, size: 9, color: WAColors.accent),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTraceTab() {
    final allConvs = _allConversations;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: WAColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona usuario:',
                  style: TextStyle(color: WAColors.textSec, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: WAColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WAColors.border),
                ),
                child: DropdownButton<String>(
                  value: _selectedConvId.isEmpty ? null : _selectedConvId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Elige un usuario',
                      style: TextStyle(color: WAColors.textMuted, fontSize: 13)),
                  dropdownColor: WAColors.card,
                  style: const TextStyle(color: WAColors.textPri, fontSize: 13),
                  items: allConvs
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                                '${c.contactName} — ${c.from.replaceAll("@c.us", "")} [${_botNameForConv(c.botId)}]'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedConvId = val ?? ''),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedConvId.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timeline, size: 48, color: WAColors.textMuted),
                      SizedBox(height: 12),
                      Text('Selecciona un usuario para ver su trazabilidad',
                          style: TextStyle(color: WAColors.textSec, fontSize: 13)),
                    ],
                  ),
                )
              : FutureBuilder<List<WAMessage>>(
                  future: _getMessages(_selectedConvId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: WAColors.accent));
                    }
                    final msgs = snapshot.data ?? [];
                    if (msgs.isEmpty) {
                      return const Center(
                          child: Text('Sin mensajes',
                              style: TextStyle(color: WAColors.textMuted)));
                    }
                    final aiMsgs = msgs.where((m) => m.role == 'assistant').length;
                    final userMsgs = msgs.where((m) => m.role == 'user').length;
                    final agentMsgs = msgs.where((m) => m.role == 'agent').length;

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: WAColors.surface,
                          child: Row(
                            children: [
                              MiniStat('Usuario', '$userMsgs', WAColors.accent),
                              MiniStat('Resp. IA', '$aiMsgs', WAColors.green),
                              MiniStat('Agente', '$agentMsgs', WAColors.human),
                              MiniStat('Total', '${msgs.length}', WAColors.textSec),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: msgs.length,
                            itemBuilder: (_, i) {
                              final msg = msgs[i];
                              final isUser = msg.role == 'user';
                              final isAI = msg.role == 'assistant';
                              final color = isUser
                                  ? WAColors.accent
                                  : isAI
                                      ? WAColors.green
                                      : WAColors.human;
                              final roleLabel =
                                  isUser ? 'Usuario' : isAI ? 'IA (OpenAI)' : 'Agente';
                              final roleIcon = isUser
                                  ? Icons.person_rounded
                                  : isAI
                                      ? Icons.psychology_rounded
                                      : Icons.support_agent_rounded;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: color.withOpacity(0.4)),
                                            ),
                                            child: Icon(roleIcon, size: 14, color: color),
                                          ),
                                          if (i < msgs.length - 1)
                                            Expanded(
                                              child: Container(width: 2, color: WAColors.border),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: color.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(roleLabel,
                                                        style: TextStyle(
                                                            color: color,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700)),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    DateFormat('dd/MM HH:mm').format(msg.timestamp),
                                                    style: const TextStyle(
                                                        color: WAColors.textMuted, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(msg.body,
                                                  style: const TextStyle(
                                                      color: WAColors.textPri,
                                                      fontSize: 13,
                                                      height: 1.4)),
                                            ],
                                          ),
                                        ),
                                      ),
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
        ),
      ],
    );
  }

  String _formatDiff(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}