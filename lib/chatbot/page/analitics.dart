
  
import 'dart:developer';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/config.dart';
import 'package:digitaltv/chatbot/page/globalAnalytics.dart';
import 'package:digitaltv/chatbot/page/kanva.dart';
import 'package:digitaltv/chatbot/page/page.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digitaltv/chatbot/page/widget.dart' as widget2;
// ─────────────────────────────────────────
  
// ─────────────────────────────────────────
// ANALYTICS VIEW — Embudo + Usuarios + Trazabilidad IA
// ─────────────────────────────────────────


class AnalyticsView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  const AnalyticsView({required this.bot, required this.service, required this.onBack});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WAConversation> _conversations = [];
  Map<String, List<WAMessage>> _messagesCache = {};
  bool _loading = true;
  String _selectedConvId = '';

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
    _conversations = await widget.service.getConversations(widget.bot.id);
    setState(() => _loading = false);
  }

  Future<List<WAMessage>> _getMessages(String convId) async {
    if (_messagesCache.containsKey(convId)) return _messagesCache[convId]!;
    final msgs = await widget.service.getMessages(convId);
    _messagesCache[convId] = msgs;
    return msgs;
  }

  // Estadísticas del embudo
  int get _totalUsers => _conversations.length;
  int get _activeUsers => _conversations.where((c) {
        final diff = DateTime.now().difference(c.lastMessageAt);
        return diff.inHours < 24;
      }).length;
  int get _humanControl => _conversations.where((c) => c.humanControl).length;
  int get _aiOnly => _totalUsers - _humanControl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Analytics — ${widget.bot.name}',
            subtitle: 'Embudo, usuarios y trazabilidad IA',
            icon: Icons.analytics_rounded,
            iconColor: WAColors.accent,
            onBack: widget.onBack,
            actions: [
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

  // ── TAB 1: EMBUDO ──
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
          const Text('Embudo de conversaciones',
              style: TextStyle(color: WAColors.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          WACard(
            child: Column(
              children: stages.asMap().entries.map((entry) {
                final i = entry.key;
                final stage = entry.value;
                final val = stage['value'] as int;
                final color = stage['color'] as Color;
                final pct = (val / maxVal).clamp(0.0, 1.0);
                final width = 1.0 - (i * 0.08);

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
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: WAColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: width,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: WACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Por semana',
                          style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      InfoRow('Nuevos esta semana',
                          '${_conversations.where((c) => DateTime.now().difference(c.lastMessageAt).inDays <= 7).length}'),
                      InfoRow('Activos esta semana',
                          '${_conversations.where((c) => DateTime.now().difference(c.lastMessageAt).inDays <= 7).length}'),
                      InfoRow('Tasa derivación humano',
                          _totalUsers > 0 ? '${(_humanControl / _totalUsers * 100).toStringAsFixed(1)}%' : '0%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estados',
                          style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      InfoRow('Modo IA activo', '$_aiOnly'),
                      InfoRow('Modo humano activo', '$_humanControl'),
                      InfoRow('Total usuarios únicos', '$_totalUsers'),
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

  // ── TAB 2: USUARIOS NUEVOS ──
  Widget _buildUsersTab() {
    final sorted = [..._conversations]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    final newUsers = sorted.where((c) {
      return DateTime.now().difference(c.lastMessageAt).inDays <= 7;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Usuarios nuevos (últimos 7 días)',
                  style: TextStyle(color: WAColors.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WAColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${newUsers.length} nuevos',
                    style: const TextStyle(color: WAColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (newUsers.isEmpty)
            EmptyState(
              icon: Icons.group_off_rounded,
              title: 'Sin usuarios nuevos',
              subtitle: 'No hay conversaciones en los últimos 7 días',
            )
          else
            ...newUsers.map((conv) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedConvId = conv.id;
                      _tabController.animateTo(2);
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: WACard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: WAColors.accent.withOpacity(0.2),
                            radius: 20,
                            child: Text(
                              conv.contactName.isNotEmpty ? conv.contactName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: WAColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(conv.contactName,
                                    style: const TextStyle(
                                        color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  conv.from.replaceAll('@c.us', ''),
                                  style: const TextStyle(color: WAColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDiff(conv.lastMessageAt),
                                style: const TextStyle(color: WAColors.textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: conv.humanControl
                                      ? WAColors.human.withOpacity(0.15)
                                      : WAColors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
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
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Ver traza',
                                      style: TextStyle(color: WAColors.accent, fontSize: 10)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios, size: 10, color: WAColors.accent),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ── TAB 3: TRAZABILIDAD IA ──
  Widget _buildTraceTab() {
    return Column(
      children: [
        // Selector de conversación
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
                  hint: const Text('Elige una conversación', style: TextStyle(color: WAColors.textMuted, fontSize: 13)),
                  dropdownColor: WAColors.card,
                  style: const TextStyle(color: WAColors.textPri, fontSize: 13),
                  items: _conversations
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.contactName} — ${c.from.replaceAll("@c.us", "")}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedConvId = val ?? ''),
                ),
              ),
            ],
          ),
        ),
        // Timeline de mensajes
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
                      return const Center(child: CircularProgressIndicator(color: WAColors.accent));
                    }
                    final msgs = snapshot.data ?? [];
                    if (msgs.isEmpty) {
                      return const Center(
                          child: Text('Sin mensajes', style: TextStyle(color: WAColors.textMuted)));
                    }

                    // Stats de esta conversación
                    final aiMsgs = msgs.where((m) => m.role == 'assistant').length;
                    final userMsgs = msgs.where((m) => m.role == 'user').length;
                    final agentMsgs = msgs.where((m) => m.role == 'agent').length;

                    return Column(
                      children: [
                        // Stats rápidas de la conversación
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
                        // Timeline
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
                              final roleLabel = isUser ? 'Usuario' : isAI ? 'IA (OpenAI)' : 'Agente';
                              final roleIcon = isUser
                                  ? Icons.person_rounded
                                  : isAI
                                      ? Icons.psychology_rounded
                                      : Icons.support_agent_rounded;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Línea de tiempo
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
                                              child: Container(
                                                width: 2,
                                                color: WAColors.border,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Contenido
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
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                    style: const TextStyle(color: WAColors.textMuted, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(msg.body,
                                                  style: const TextStyle(
                                                      color: WAColors.textPri, fontSize: 13, height: 1.4)),
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
