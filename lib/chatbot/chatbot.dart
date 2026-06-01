
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
  return _ConnectionView(
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
        return _ChatView(
          bot: _selectedBot,
          bots: _bots,
          service: _service,
          onSelectBot: (bot) => setState(() => _selectedBot = bot),
          onBack: () => setState(() =>
              _currentView = _selectedBot != null ? 'botDetail' : 'bots'),
        );
      case 'stats':
        if (_selectedBot == null) return const SizedBox();
        return _StatsView(
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
          _CreateBotDialog(service: service, onCreated: onRefresh),
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

// ─────────────────────────────────────────
// CHAT VIEW
// ─────────────────────────────────────────
class _ChatView extends StatefulWidget {
  final WAChatbot? bot;
  final List<WAChatbot> bots;
  final WAService service;
  final Function(WAChatbot) onSelectBot;
  final VoidCallback onBack;
  const _ChatView(
      {this.bot,
      required this.bots,
      required this.service,
      required this.onSelectBot,
      required this.onBack});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  WAChatbot? _activeBot;
  List<WAConversation> _conversations = [];
  WAConversation? _selectedConv;
  List<WAMessage> _messages = [];
  bool _loadingConvs = false;
  bool _loadingMsgs = false;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _humanMode = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _activeBot =
        widget.bot ?? (widget.bots.isNotEmpty ? widget.bots.first : null);
    if (_activeBot != null) _loadConversations(_activeBot!.id);
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_activeBot != null && mounted) _loadConversations(_activeBot!.id);
      if (_selectedConv != null && mounted) _refreshMessages();
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

 // REEMPLAZA estos dos métodos completos en _ChatViewState:

Future<void> _loadConversations(String botId) async {
  if (!mounted) return;
  setState(() => _loadingConvs = true);
  final result = await widget.service.getConversations(botId);
  if (!mounted) return;
  setState(() {
    _conversations = result;
    _loadingConvs = false;
  });
}

Future<void> _refreshMessages() async {
  if (_selectedConv == null || !mounted) return;
  final msgs = await widget.service.getMessages(_selectedConv!.id);
  if (!mounted) return;
  if (msgs.length != _messages.length) {
    setState(() => _messages = msgs);
    _scrollToBottom();
  }
}

  Future<void> _selectConversation(WAConversation conv) async {
    setState(() {
      _selectedConv = conv;
      _loadingMsgs = true;
      _humanMode = conv.humanControl;
    });
    _messages = await widget.service.getMessages(conv.id);
    setState(() => _loadingMsgs = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _selectedConv == null) return;
    _msgController.clear();
    await widget.service.sendMessage(_selectedConv!.id, text, 'Agente');
    await _refreshMessages();
  }

  Future<void> _toggleHumanControl() async {
    if (_selectedConv == null) return;
    final newMode = !_humanMode;
    await widget.service.setHumanControl(_selectedConv!.id, newMode);
    setState(() => _humanMode = newMode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Conversaciones',
            subtitle: _activeBot != null
                ? 'Bot: ${_activeBot!.name}'
                : 'Selecciona un bot',
            icon: Icons.chat_bubble_rounded,
            iconColor: WAColors.green,
            onBack: widget.onBack,
            actions: [
              if (widget.bots.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: WAColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WAColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _activeBot?.id,
                    underline: const SizedBox(),
                    dropdownColor: WAColors.card,
                    style: const TextStyle(
                        color: WAColors.textPri, fontSize: 13),
                    items: widget.bots
                        .map((b) => DropdownMenuItem(
                            value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final bot = widget.bots.firstWhere((b) => b.id == id);
                      setState(() {
                        _activeBot = bot;
                        _selectedConv = null;
                        _messages = [];
                      });
                      widget.onSelectBot(bot);
                      _loadConversations(id);
                    },
                  ),
                ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                // Lista conversaciones
                Container(
                  width: 300,
                  decoration: const BoxDecoration(
                    color: WAColors.surface,
                    border:
                        Border(right: BorderSide(color: WAColors.border)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          style: const TextStyle(
                              color: WAColors.textPri, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Buscar conversación...',
                            hintStyle: const TextStyle(
                                color: WAColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: WAColors.textMuted, size: 18),
                            filled: true,
                            fillColor: WAColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _loadingConvs
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: WAColors.green))
                            : _conversations.isEmpty
                                ? const Center(
                                    child: Text('Sin conversaciones',
                                        style: TextStyle(
                                            color: WAColors.textMuted,
                                            fontSize: 13)))
                                : ListView.builder(
                                    itemCount: _conversations.length,
                                    itemBuilder: (_, i) {
                                      final conv = _conversations[i];
                                      final isSelected =
                                          _selectedConv?.id == conv.id;
                                      return InkWell(
                                        onTap: () =>
                                            _selectConversation(conv),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          color: isSelected
                                              ? WAColors.green
                                                  .withOpacity(0.1)
                                              : Colors.transparent,
                                          child: Row(
                                            children: [
                                              Stack(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        WAColors.cardLight,
                                                    radius: 22,
                                                    child: Text(
                                                      conv.contactName
                                                              .isNotEmpty
                                                          ? conv.contactName[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                          color:
                                                              WAColors.textPri,
                                                          fontWeight:
                                                              FontWeight.w700),
                                                    ),
                                                  ),
                                                  if (conv.humanControl)
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        width: 14,
                                                        height: 14,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: WAColors.human,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color: WAColors
                                                                  .surface,
                                                              width: 2),
                                                        ),
                                                        child: const Icon(
                                                            Icons.person,
                                                            size: 8,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            conv.contactName,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: WAColors
                                                                  .textPri,
                                                              fontWeight: conv
                                                                          .unreadCount >
                                                                      0
                                                                  ? FontWeight
                                                                      .w700
                                                                  : FontWeight
                                                                      .w500,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatTime(
                                                              conv.lastMessageAt),
                                                          style: const TextStyle(
                                                              color: WAColors
                                                                  .textMuted,
                                                              fontSize: 10),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      conv.lastMessage,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: const TextStyle(
                                                          color:
                                                              WAColors.textSec,
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (conv.unreadCount > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: WAColors.green,
                                                          shape:
                                                              BoxShape.circle),
                                                  child: Text(
                                                      '${conv.unreadCount}',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                // Panel chat
                Expanded(
                  child: _selectedConv == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: WAColors.textMuted),
                              SizedBox(height: 12),
                              Text('Selecciona una conversación',
                                  style: TextStyle(
                                      color: WAColors.textSec, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('para ver los mensajes',
                                  style: TextStyle(
                                      color: WAColors.textMuted,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Header del chat
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: const BoxDecoration(
                                color: WAColors.surface,
                                border: Border(
                                    bottom: BorderSide(
                                        color: WAColors.border)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: WAColors.cardLight,
                                    radius: 18,
                                    child: Text(
                                      _selectedConv!.contactName.isNotEmpty
                                          ? _selectedConv!.contactName[0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: WAColors.textPri,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedConv!.contactName,
                                          style: const TextStyle(
                                              color: WAColors.textPri,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          _selectedConv!.from
                                              .replaceAll('@c.us', ''),
                                          style: const TextStyle(
                                              color: WAColors.textMuted,
                                              fontSize: 11)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        _humanMode
                                            ? Icons.person
                                            : Icons.psychology_rounded,
                                        size: 14,
                                        color: _humanMode
                                            ? WAColors.human
                                            : WAColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _humanMode ? 'Modo Humano' : 'Modo IA',
                                        style: TextStyle(
                                            color: _humanMode
                                                ? WAColors.human
                                                : WAColors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: _humanMode,
                                        onChanged: (_) =>
                                            _toggleHumanControl(),
                                        activeColor: WAColors.human,
                                        inactiveTrackColor:
                                            WAColors.green.withOpacity(0.3),
                                        thumbColor:
                                            MaterialStateProperty.all(
                                                Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Mensajes
                            Expanded(
                              child: _loadingMsgs
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: WAColors.green))
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _messages.length,
                                      itemBuilder: (_, i) =>
                                          MessageBubble(msg: _messages[i]),
                                    ),
                            ),
                            // Input agente humano
                            if (_humanMode)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: WAColors.surface,
                                  border: const Border(
                                      top: BorderSide(
                                          color: WAColors.border)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            WAColors.human.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text('Agente',
                                          style: TextStyle(
                                              color: WAColors.human,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _msgController,
                                        style: const TextStyle(
                                            color: WAColors.textPri,
                                            fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Escribe como agente humano...',
                                          hintStyle: const TextStyle(
                                              color: WAColors.textMuted),
                                          filled: true,
                                          fillColor: WAColors.card,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: _sendMessage,
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: WAColors.human,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.send,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: WAColors.surface,
                                child: Row(
                                  children: [
                                    const Icon(Icons.psychology,
                                        color: WAColors.green, size: 16),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                          'La IA está respondiendo automáticamente',
                                          style: TextStyle(
                                              color: WAColors.textSec,
                                              fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: _toggleHumanControl,
                                      child: const Text('Tomar control',
                                          style: TextStyle(
                                              color: WAColors.human,
                                              fontSize: 12)),
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
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('dd/MM').format(dt);
  }
}

// ─────────────────────────────────────────
// STATS VIEW
// ─────────────────────────────────────────
class _StatsView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  const _StatsView(
      {required this.bot, required this.service, required this.onBack});

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  Map<String, dynamic>? _stats;
  String _period = '7d';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _stats =
        await widget.service.getBotStats(widget.bot.id, period: _period);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          PageHeader(
            title: 'Estadísticas — ${widget.bot.name}',
            subtitle: 'Rendimiento del chatbot',
            icon: Icons.bar_chart_rounded,
            iconColor: WAColors.accent,
            onBack: widget.onBack,
            actions: [
              ...['1d', '7d', '30d'].map((p) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() => _period = p);
                        _load();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _period == p
                              ? WAColors.accent
                              : WAColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _period == p
                                  ? WAColors.accent
                                  : WAColors.border),
                        ),
                        child: Text(p,
                            style: TextStyle(
                                color: _period == p
                                    ? Colors.white
                                    : WAColors.textSec,
                                fontSize: 12)),
                      ),
                    ),
                  )),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: WAColors.accent))
                : _stats == null
                    ? const Center(
                        child: Text('Sin datos',
                            style: TextStyle(color: WAColors.textSec)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatCard(
                                    label: 'Msgs Recibidos',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['messagesReceived'] ?? 0}',
                                    icon: Icons.download_rounded,
                                    color: WAColors.info),
                                const SizedBox(width: 16),
                                StatCard(
                                    label: 'Msgs Enviados',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['messagesSent'] ?? 0}',
                                    icon: Icons.upload_rounded,
                                    color: WAColors.green),
                                const SizedBox(width: 16),
                                StatCard(
                                    label: 'Respuestas IA',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['aiReplies'] ?? 0}',
                                    icon: Icons.psychology_rounded,
                                    color: WAColors.accent),
                                const SizedBox(width: 16),
                                StatCard(
                                    label: 'Tasa Respuesta',
                                    value:
                                        '${_stats!['responseRate'] ?? '0.0'}%',
                                    icon: Icons.speed_rounded,
                                    color: WAColors.warning),
                              ],
                            ),
                            const SizedBox(height: 28),
                            WACard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mensajes por día',
                                      style: TextStyle(
                                          color: WAColors.textPri,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                      height: 200,
                                      child: _buildChart()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: WACard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Conversaciones',
                                            style: TextStyle(
                                                color: WAColors.textPri,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 16),
                                        InfoRow('Total',
                                            '${_stats!['totalConversations'] ?? 0}'),
                                        InfoRow('Activas 24h',
                                            '${_stats!['activeConversations'] ?? 0}'),
                                        InfoRow('Control humano',
                                            '${_stats!['humanControlCount'] ?? 0}'),
                                        InfoRow('% IA',
                                            '${_stats!['aiRate'] ?? '0.0'}%'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: WACard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rendimiento',
                                            style: TextStyle(
                                                color: WAColors.textPri,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 16),
                                        InfoRow(
                                            'Recibidos',
                                            '${(_stats!['totals'] as Map?)?['messagesReceived'] ?? 0}'),
                                        InfoRow(
                                            'Enviados',
                                            '${(_stats!['totals'] as Map?)?['messagesSent'] ?? 0}'),
                                        InfoRow(
                                            'Resp. IA',
                                            '${(_stats!['totals'] as Map?)?['aiReplies'] ?? 0}'),
                                        InfoRow(
                                            'Resp. Humano',
                                            '${(_stats!['totals'] as Map?)?['humanReplies'] ?? 0}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final daily = (_stats?['daily'] as List? ?? []).cast<Map>();
    if (daily.isEmpty) {
      return const Center(
          child: Text('Sin datos diarios',
              style: TextStyle(color: WAColors.textMuted)));
    }
    final spots = daily
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(),
            (e.value['messagesReceived'] ?? 0).toDouble()))
        .toList();
    final spotsOut = daily
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(),
            (e.value['messagesSent'] ?? 0).toDouble()))
        .toList();

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: WAColors.border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (v, _) => Text('${v.toInt()}',
              style: const TextStyle(
                  color: WAColors.textMuted, fontSize: 10)),
        )),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 20,
          getTitlesWidget: (v, _) {
            final idx = v.toInt();
            if (idx < 0 || idx >= daily.length) return const SizedBox();
            return Text(
                daily[idx]['date']?.toString().substring(5) ?? '',
                style: const TextStyle(
                    color: WAColors.textMuted, fontSize: 9));
          },
        )),
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: WAColors.green,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true,
              color: WAColors.green.withOpacity(0.08)),
        ),
        LineChartBarData(
          spots: spotsOut,
          isCurved: true,
          color: WAColors.accent,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true,
              color: WAColors.accent.withOpacity(0.08)),
        ),
      ],
    ));
  }
}


// ─────────────────────────────────────────
// DIALOGO CREAR BOT
// ─────────────────────────────────────────
class _CreateBotDialog extends StatefulWidget {
  final WAService service;
  final VoidCallback onCreated;
  const _CreateBotDialog({required this.service, required this.onCreated});

  @override
  State<_CreateBotDialog> createState() => _CreateBotDialogState();
}

class _CreateBotDialogState extends State<_CreateBotDialog> {
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _saving = false;
  bool _fbLoading = false;
  String? _accessToken;
  List<Map<String, dynamic>> _phones = [];
  Map<String, dynamic>? _selectedPhone;
  String _step = 'fb'; // 'fb' | 'phone' | 'name'

  // ─── TU Facebook App ID aquí ───
  static const _fbAppId = '1673571300005129';
  static const _fbRedirectUri = 'https://gettranscribeai.onrender.com/api/wa/facebook/exchange-token';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

void _loginWithFacebook() {
  final scope = 'whatsapp_business_management,whatsapp_business_messaging,business_management';
  final url =
      'https://www.facebook.com/v19.0/dialog/oauth'
      '?client_id=$_fbAppId'
      '&redirect_uri=${Uri.encodeComponent('https://gettranscribeai.onrender.com/oauth/facebook/callback')}'
      '&scope=${Uri.encodeComponent(scope)}'
      '&response_type=code';

  html.window.open(url, 'fb_login', 'width=600,height=700');

  html.window.onMessage.listen((event) async {
    final data = event.data;
    if (data is! Map) return;
    if (data['type'] != 'fb_code') return;
    final code = data['code'] as String?;
    if (code == null) return;

    if (!mounted) return;
    setState(() => _fbLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$kWABaseUrl/api/wa/facebook/exchange-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'redirectUri': 'https://gettranscribeai.onrender.com/oauth/facebook/callback',
        }),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        if (!mounted) return;
        setState(() {
          _accessToken = body['data']['accessToken'];
          _phones = List<Map<String, dynamic>>.from(body['data']['phones']);
          _step = 'phone';
        });
      } else {
        if (!mounted) return;
        _showError(body['error'] ?? 'Error al conectar');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _fbLoading = false);
    }
  });
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: WAColors.error));
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedPhone == null) return;
    setState(() => _saving = true);
    await widget.service.createChatbot({
      'name': _nameCtrl.text.trim(),
      'companyName': _companyCtrl.text.trim(),
      'phoneNumber': _selectedPhone!['phoneNumber'],
      'phoneNumberId': _selectedPhone!['phoneNumberId'],
      'accessToken': _accessToken ?? '',
      'systemPrompt': '',
    });
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: WAColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WAColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: WAColors.green, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Conectar WhatsApp',
                    style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: WAColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // STEP 1: Login Facebook
            if (_step == 'fb') ...[
              const Text(
                'Conecta tu cuenta de Facebook Business para vincular tu número de WhatsApp automáticamente.',
                style: TextStyle(color: WAColors.textSec, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _fbLoading ? null : _loginWithFacebook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _fbLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.facebook, size: 20),
                            SizedBox(width: 10),
                            Text('Continuar con Facebook', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WAColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WAColors.info.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: WAColors.info, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se abrirá un popup de Facebook. Autoriza los permisos de WhatsApp Business.',
                        style: TextStyle(color: WAColors.textSec, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // STEP 2: Seleccionar número
            if (_step == 'phone') ...[
              const Text('Selecciona el número de WhatsApp a conectar:',
                  style: TextStyle(color: WAColors.textSec, fontSize: 13)),
              const SizedBox(height: 12),
              if (_phones.isEmpty)
                const Text('No se encontraron números. Verifica tu cuenta de WhatsApp Business.',
                    style: TextStyle(color: WAColors.error, fontSize: 12))
              else
                ..._phones.map((phone) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedPhone = phone;
                          _step = 'name';
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: WAColors.cardLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: WAColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_android, color: WAColors.green, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(phone['verifiedName'] ?? '',
                                      style: const TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600)),
                                  Text(phone['phoneNumber'] ?? '',
                                      style: const TextStyle(color: WAColors.textMuted, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: WAColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    )),
            ],

            // STEP 3: Nombre del bot
            if (_step == 'name') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WAColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WAColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: WAColors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedPhone!['verifiedName']} — ${_selectedPhone!['phoneNumber']}',
                      style: const TextStyle(color: WAColors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
           widget2.   FormField(label: 'Nombre del bot *', controller: _nameCtrl, hint: 'Ej: Soporte Ventas'),
              const SizedBox(height: 12),
               widget2. FormField(label: 'Empresa / Negocio', controller: _companyCtrl, hint: 'Ej: Mi Empresa S.A.'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WAColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Crear Bot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// WIDGETS REUTILIZABLES
// ─────────────────────────────────────────



// ─────────────────────────────────────────
// CONNECTION VIEW
// ─────────────────────────────────────────
class _ConnectionView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  const _ConnectionView({required this.service, required this.bots});

  @override
  State<_ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<_ConnectionView> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _dashboard = await widget.service.getDashboard();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeBots = widget.bots.where((b) => b.isActive).toList();
    final inactiveBots = widget.bots.where((b) => !b.isActive).toList();

    return Container(
      color: WAColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Conexión Facebook',
            subtitle: 'Estado de integración con WhatsApp Business',
            icon: Icons.link_rounded,
            iconColor: const Color(0xFF1877F2),
            actions: [
              HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: WAColors.green))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado general conexión Facebook
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22),
                                  SizedBox(width: 10),
                                  Text('Estado de Conexión Facebook',
                                      style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w700, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _ConnectionStatusCard(
                                    label: 'Total Bots',
                                    value: '${widget.bots.length}',
                                    icon: Icons.smart_toy_rounded,
                                    color: WAColors.accent,
                                    sublabel: 'registrados',
                                  ),
                                  const SizedBox(width: 16),
                                  _ConnectionStatusCard(
                                    label: 'Conectados',
                                    value: '${activeBots.length}',
                                    icon: Icons.check_circle_rounded,
                                    color: WAColors.green,
                                    sublabel: 'activos',
                                  ),
                                  const SizedBox(width: 16),
                                  _ConnectionStatusCard(
                                    label: 'Desconectados',
                                    value: '${inactiveBots.length}',
                                    icon: Icons.cancel_rounded,
                                    color: WAColors.error,
                                    sublabel: 'inactivos',
                                  ),
                                  const SizedBox(width: 16),
                                  _ConnectionStatusCard(
                                    label: 'Con Token',
                                    value: '${widget.bots.where((b) => b.accessToken.isNotEmpty).length}',
                                    icon: Icons.vpn_key_rounded,
                                    color: WAColors.warning,
                                    sublabel: 'configurados',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Lista de bots con su estado de conexión
                        const Text('Detalle por Bot',
                            style: TextStyle(color: WAColors.textPri, fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ...widget.bots.map((bot) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WACard(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: bot.isActive
                                            ? WAColors.green.withOpacity(0.15)
                                            : WAColors.error.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        bot.isActive ? Icons.link_rounded : Icons.link_off_rounded,
                                        color: bot.isActive ? WAColors.green : WAColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(bot.name,
                                              style: const TextStyle(
                                                  color: WAColors.textPri, fontWeight: FontWeight.w700, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(
                                            bot.phoneNumber.isNotEmpty ? bot.phoneNumber : 'Sin número configurado',
                                            style: const TextStyle(color: WAColors.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusBadge(
                                            label: bot.isActive ? 'Conectado' : 'Desconectado',
                                            color: bot.isActive ? WAColors.green : WAColors.error),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              bot.accessToken.isNotEmpty ? Icons.vpn_key : Icons.vpn_key_off,
                                              size: 12,
                                              color: bot.accessToken.isNotEmpty ? WAColors.warning : WAColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              bot.accessToken.isNotEmpty ? 'Token OK' : 'Sin token',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: bot.accessToken.isNotEmpty ? WAColors.warning : WAColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),

                        const SizedBox(height: 20),

                        // Info de última actividad
                        WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.history_rounded, color: WAColors.accent, size: 18),
                                  SizedBox(width: 8),
                                  Text('Resumen del Sistema',
                                      style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              InfoRow('Total conversaciones',
                                  '${_dashboard?['totalConversations'] ?? 0}'),
                              InfoRow('Conversaciones activas (24h)',
                                  '${_dashboard?['activeConversations'] ?? 0}'),
                              InfoRow('Pendientes atención humana',
                                  '${_dashboard?['pendingHumanControl'] ?? 0}'),
                              InfoRow('Bots con número configurado',
                                  '${widget.bots.where((b) => b.phoneNumber.isNotEmpty).length}'),
                              InfoRow('Bots con Phone ID',
                                  '${widget.bots.where((b) => b.phoneNumberId.isNotEmpty).length}'),
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

class _ConnectionStatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sublabel;
  const _ConnectionStatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: WAColors.textPri, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(sublabel, style: const TextStyle(color: WAColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

