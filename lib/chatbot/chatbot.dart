
import 'dart:developer';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/chat.dart';
import 'package:digitaltv/chatbot/page/config.dart';
import 'package:digitaltv/chatbot/page/connectView.dart';
import 'package:digitaltv/chatbot/page/createChatbot.dart';
import 'package:digitaltv/chatbot/page/globalAnalytics.dart';
import 'package:digitaltv/chatbot/page/kanva.dart';
import 'package:digitaltv/chatbot/page/page.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:digitaltv/chatbot/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digitaltv/chatbot/page/widget.dart' as widget2;

import 'page/analitics.dart';
// ─────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────
const String kWABaseUrl = 'https://gettranscribeai.onrender.com';


class WhatsappChatbotPage extends StatefulWidget {
  final String userId;
  final String initialView;
  const WhatsappChatbotPage({
    super.key,
    required this.userId,
    this.initialView = 'dashboard',
  });

  @override
  State<WhatsappChatbotPage> createState() => _WhatsappChatbotPageState();
}

class _WhatsappChatbotPageState extends State<WhatsappChatbotPage> {
  late WAService _service;
  List<WAChatbot> _bots = [];
  bool _loading = true;
  late String _currentView;
  WAChatbot? _selectedBot;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _service = WAService(widget.userId);
    _loadBots();
  }
 

  Future<void> _loadBots() async {
    setState(() => _loading = true);
    _bots = await _service.getChatbots();
    setState(() => _loading = false);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: WAColors.bg,
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: WAColors.green))
        : Row(
            children: [
              _buildSidebar(),
              Expanded(child: _buildContent()),
            ],
          ),
  );
}

  Widget _buildSidebar() {
final items = [
  {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'view': 'dashboard'},
  {'icon': Icons.smart_toy_rounded, 'label': 'Mis Bots', 'view': 'bots'},
  {'icon': Icons.chat_bubble_rounded, 'label': 'Conversaciones', 'view': 'chat'},
  {'icon': Icons.link_rounded, 'label': 'Conexión', 'view': 'connection'},
  {'icon': Icons.analytics_rounded, 'label': 'Analytics', 'view': 'analyticsGlobal'}, // NUEVO

  {'icon': Icons.view_kanban_rounded, 'label': 'Kanban Ventas', 'view': 'kanban'},
];

    return Container(
      width: 220,
      color: WAColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WAColors.green, WAColors.greenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WA Chatbot',
                          style: TextStyle(
                              color: WAColors.textPri,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('AI Manager',
                          style: TextStyle(
                              color: WAColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: WAColors.border, height: 1),
          const SizedBox(height: 8),
          ...items.map((item) {
            final isActive = _currentView == item['view'] ||
                (_currentView == 'botDetail' && item['view'] == 'bots') ||
                (_currentView == 'stats' && item['view'] == 'bots') ||
                (_currentView == 'config' && item['view'] == 'bots');
            return _SidebarItem(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              isActive: isActive,
              onTap: () {
                setState(() {
                  _currentView = item['view'] as String;
                  if (item['view'] != 'botDetail') _selectedBot = null;
                });
                _loadBots();
              },
            );
          }),
          const Spacer(),
          if (_bots.isNotEmpty) ...[
            const Divider(color: WAColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('BOTS ACTIVOS',
                  style: TextStyle(
                      color: WAColors.textMuted.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
            ),
            ..._bots.where((b) => b.isActive).take(4).map((bot) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: WAColors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: WAColors.green.withOpacity(0.5),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(bot.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: WAColors.textSec, fontSize: 12))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: WAColors.green));
    }
    switch (_currentView) {
      case 'kanban':
  return KanbanView(
    service: _service,
    bots: _bots,
    onOpenTrace: (convId, botId) => setState(() {
      _selectedBot = _bots.firstWhere((b) => b.id == botId, orElse: () => _bots.first);
      _currentView = 'analytics';
    }),
  );
      case 'dashboard':
        return DashboardView(
          service: _service,
          bots: _bots,
          onSelectBot: (bot) =>
              setState(() {
                _selectedBot = bot;
                _currentView = 'botDetail';
              }),
        );
        case 'analyticsGlobal':
  return GlobalAnalyticsView(
    service: _service,
    bots: _bots,
    onSelectBot: (bot) => setState(() {
      _selectedBot = bot;
      _currentView = 'analytics';
    }),
  );
      case 'bots':
        return _BotsListView(
          service: _service,
          bots: _bots,
          onRefresh: _loadBots,
          onSelectBot: (bot) =>
              setState(() {
                _selectedBot = bot;
                _currentView = 'botDetail';
              }),
        );
      case 'botDetail':
        if (_selectedBot == null) {
          setState(() => _currentView = 'bots');
          return const SizedBox();
        }
        return _BotDetailView(
          bot: _selectedBot!,
          service: _service,
          onBack: () => setState(() {
            _currentView = 'bots';
            _selectedBot = null;
          }),
          onOpenChat: () => setState(() => _currentView = 'chat'),
          onOpenStats: () => setState(() => _currentView = 'stats'),
            onOpenAnalytics: () => setState(() => _currentView = 'analytics'),
          onEdit: () => setState(() => _currentView = 'config'),
          onRefresh: () async {
            await _loadBots();
            if (_selectedBot != null) {
              setState(() {
                _selectedBot = _bots.firstWhere((b) => b.id == _selectedBot!.id,
                    orElse: () => _selectedBot!);
              });
            }
          },
        );
        case 'connection':
  return ConnectionView(
    service: _service,
    bots: _bots,
  );

  case 'analytics':
  if (_selectedBot == null) return const SizedBox();
  return AnalyticsView(
    bot: _selectedBot!,
    service: _service,
    onBack: () => setState(() => _currentView = 'botDetail'),
  );
      case 'chat':
        return ChatView(
          bot: _selectedBot,
          bots: _bots,
          service: _service,
          onSelectBot: (bot) => setState(() => _selectedBot = bot),
          onBack: () => setState(() =>
              _currentView = _selectedBot != null ? 'botDetail' : 'bots'),
        );
      case 'stats':
        if (_selectedBot == null) return const SizedBox();
        return StatsView(
          bot: _selectedBot!,
          service: _service,
          onBack: () => setState(() => _currentView = 'botDetail'),
        );
      case 'config':
        if (_selectedBot == null) return const SizedBox();
        return ConfigView(
          bot: _selectedBot!,
          service: _service,
          onBack: () => setState(() => _currentView = 'botDetail'),
          onSaved: () async {
            await _loadBots();
            setState(() => _currentView = 'botDetail');
          },
        );
      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────
// SIDEBAR ITEM
// ─────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? WAColors.green.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: WAColors.green.withOpacity(0.25))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive ? WAColors.green : WAColors.textMuted),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: isActive ? WAColors.green : WAColors.textSec,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DASHBOARD VIEW
// ─────────────────────────────────────────


// ─────────────────────────────────────────
// BOTS LIST VIEW
// ─────────────────────────────────────────
class _BotsListView extends StatelessWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final VoidCallback onRefresh;
  final Function(WAChatbot) onSelectBot;
  const _BotsListView(
      {required this.service,
      required this.bots,
      required this.onRefresh,
      required this.onSelectBot});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Mis Bots',
            subtitle: '${bots.length} chatbots configurados',
            icon: Icons.smart_toy_rounded,
            iconColor: WAColors.accent,
            actions: [
           ElevatedButton(
  onPressed: () => _showCreateDialog(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: WAColors.green,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    minimumSize: Size.zero, // ✅
    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅
  ),
  child:Container(padding: EdgeInsets.all(10),child:  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.add, size: 16),
      SizedBox(width: 8),
      Text('Nuevo Bot'),
    ],
  )),
),
            ],
          ),
          Expanded(
            child: bots.isEmpty
                ? EmptyState(
                    icon: Icons.smart_toy_outlined,
                    title: 'No tienes bots aún',
                    subtitle: 'Crea tu primer chatbot de WhatsApp con IA',
                    action: ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Bot'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: WAColors.green,
                          foregroundColor: Colors.white),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: bots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => BotListTile(
                      bot: bots[i],
                      service: service,
                      onRefresh: onRefresh,
                      onTap: () => onSelectBot(bots[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          CreateBotDialog(service: service, onCreated: onRefresh),
    );
  }
}

// ─────────────────────────────────────────
// BOT DETAIL VIEW
// ─────────────────────────────────────────
class _BotDetailView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  const _BotDetailView({
    required this.bot,
    required this.service,
    required this.onBack,
    required this.onOpenChat,
    required this.onOpenStats,
    required this.onOpenAnalytics,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  State<_BotDetailView> createState() => _BotDetailViewState();
}

class _BotDetailViewState extends State<_BotDetailView> {
  Map<String, dynamic>? _summary;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadSummary();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final s = await widget.service.getBotSummary(widget.bot.id);
    if (mounted) setState(() => _summary = s);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: widget.bot.name,
            subtitle: widget.bot.companyName.isNotEmpty
                ? widget.bot.companyName
                : widget.bot.description,
            icon: Icons.smart_toy_rounded,
            iconColor: widget.bot.statusColor,
            onBack: widget.onBack,
            actions: [
              StatusBadge(
                  label: widget.bot.statusLabel,
                  color: widget.bot.statusColor),
              const SizedBox(width: 8),
              ActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Estadísticas',
                  onTap: widget.onOpenStats),
              const SizedBox(width: 8),
              ActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Editar',
                  onTap: widget.onEdit),
              const SizedBox(width: 8),
              ActionButton(
                  icon: Icons.chat_rounded,
                  label: 'Chat',
                  onTap: widget.onOpenChat),

      ActionButton(
    icon: Icons.analytics_rounded,
    label: 'Analytics',
    onTap: widget.onOpenAnalytics), // en el padre
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel izquierdo
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // QR para chatear con el bot
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_rounded,
                                      color: WAColors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text('Chatear con el Bot',
                                      style: TextStyle(
                                          color: WAColors.textPri,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (widget.bot.phoneNumber.isNotEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: QrImageView(
                                          data:
                                              'https://wa.me/${widget.bot.phoneNumber.replaceAll('+', '').replaceAll(' ', '')}',
                                          version: QrVersions.auto,
                                          size: 180,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('Escanea para chatear',
                                          style: TextStyle(
                                              color: WAColors.textSec,
                                              fontSize: 13)),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text:
                                                  'https://wa.me/${widget.bot.phoneNumber.replaceAll('+', '').replaceAll(' ', '')}'));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Link copiado')));
                                        },
                                        child: Text(
                                          'wa.me/${widget.bot.phoneNumber}',
                                          style: const TextStyle(
                                              color: WAColors.green,
                                              fontSize: 11,
                                              decoration:
                                                  TextDecoration.underline),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 40,
                                            color: WAColors.textMuted),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Agrega el número de WhatsApp\nen la configuración del bot',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: WAColors.textSec,
                                                fontSize: 13)),
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: widget.onEdit,
                                          child: const Text('Configurar',
                                              style: TextStyle(
                                                  color: WAColors.green)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Acciones rápidas
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Acciones rápidas',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              QuickAction(
                                icon: Icons.psychology_rounded,
                                label:
                                    'IA ${widget.bot.isActive ? "Activada" : "Desactivada"}',
                                color: widget.bot.isActive
                                    ? WAColors.green
                                    : WAColors.textMuted,
                                onTap: () async {
                                  await widget.service
                                      .toggleAI(widget.bot.id);
                                  widget.onRefresh();
                                },
                              ),
                              const SizedBox(height: 8),
                              QuickAction(
                                icon: Icons.chat_rounded,
                                label: 'Ver Conversaciones',
                                color: WAColors.info,
                                onTap: widget.onOpenChat,
                              ),
                              const SizedBox(height: 8),
                              QuickAction(
                                icon: Icons.bar_chart_rounded,
                                label: 'Ver Estadísticas',
                                color: WAColors.accent,
                                onTap: widget.onOpenStats,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Panel derecho
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        if (_summary != null) ...[
                          WACard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resumen',
                                    style: TextStyle(
                                        color: WAColors.textPri,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    MiniStat(
                                        'Total convs.',
                                        '${_summary!['totalConversations'] ?? 0}',
                                        WAColors.accent),
                                    MiniStat(
                                        'Activas 24h',
                                        '${_summary!['activeConversations24h'] ?? 0}',
                                        WAColors.green),
                                    MiniStat(
                                        'Activas 7d',
                                        '${_summary!['activeConversations7d'] ?? 0}',
                                        WAColors.info),
                                    MiniStat(
                                        'Humano',
                                        '${_summary!['pendingHumanControl'] ?? 0}',
                                        WAColors.human),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: WAColors.border),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    MiniStat(
                                        'Msgs recibidos',
                                        '${(_summary!['weekStats'] as Map?)?['messagesReceived'] ?? 0}',
                                        WAColors.textSec),
                                    MiniStat(
                                        'Msgs enviados',
                                        '${(_summary!['weekStats'] as Map?)?['messagesSent'] ?? 0}',
                                        WAColors.textSec),
                                    MiniStat(
                                        'Resp. IA',
                                        '${(_summary!['weekStats'] as Map?)?['aiReplies'] ?? 0}',
                                        WAColors.accent),
                                    MiniStat(
                                        'Tasa resp.',
                                        '${_summary!['responseRate'] ?? '0%'}',
                                        WAColors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Configuración IA',
                                      style: TextStyle(
                                          color: WAColors.textPri,
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: widget.onEdit,
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 14),
                                    label: const Text('Editar',
                                        style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                        foregroundColor: WAColors.accent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ConfigRow('Modelo IA', widget.bot.aiModel),
                              ConfigRow('Temperatura',
                                  '${widget.bot.temperature}'),
                              ConfigRow(
                                  'Max tokens', '${widget.bot.maxTokens}'),
                              ConfigRow('Contexto msgs',
                                  '${widget.bot.contextMessages}'),
                              ConfigRow('Número WA',
                                  widget.bot.phoneNumber.isNotEmpty ? widget.bot.phoneNumber : 'No configurado'),
                              if (widget.bot.humanKeywords.isNotEmpty)
                                ConfigRow('Palabras clave',
                                    widget.bot.humanKeywords.join(', ')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.bot.systemPrompt.isNotEmpty)
                          WACard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Prompt del Sistema',
                                    style: TextStyle(
                                        color: WAColors.textPri,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: WAColors.bg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.bot.systemPrompt,
                                    style: const TextStyle(
                                        color: WAColors.textSec,
                                        fontSize: 12,
                                        fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


