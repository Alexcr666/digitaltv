// ══════════════════════════════════════════════════════════════════
// WHATSAPP AI CHATBOT — Flutter Web
// lib/whatsapp_chatbot_page.dart
//
// DEPENDENCIAS en pubspec.yaml:
//   http: ^1.1.0
//   fl_chart: ^0.66.0
//   intl: ^0.19.0
//   qr_flutter: ^4.1.0
// ══════════════════════════════════════════════════════════════════
import 'dart:developer';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────
const String kWABaseUrl = 'https://gettranscribeai.onrender.com';

// ─────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────

class WAChatbot {
  final String id;
  String name;
  String description;
  String companyName;
  String phoneNumber;
  String phoneNumberId;
  String accessToken;
  String systemPrompt;
  String instructions;
  String aiModel;
  double temperature;
  int maxTokens;
  int contextMessages;
  bool isActive;
  List<String> humanKeywords;
  String humanTransferMessage;
  String errorMessage;
  Map<String, dynamic> stats;
  DateTime? createdAt;

  WAChatbot({
    required this.id,
    required this.name,
    this.description = '',
    this.companyName = '',
    this.phoneNumber = '',
    this.phoneNumberId = '',
    this.accessToken = '',
    this.systemPrompt = '',
    this.instructions = '',
    this.aiModel = 'gpt-4o-mini',
    this.temperature = 0.7,
    this.maxTokens = 500,
    this.contextMessages = 10,
    this.isActive = true,
    this.humanKeywords = const [],
    this.humanTransferMessage = '',
    this.errorMessage = '',
    this.stats = const {},
    this.createdAt,
  });

  factory WAChatbot.fromJson(Map<String, dynamic> j) => WAChatbot(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        companyName: j['companyName'] ?? '',
        phoneNumber: j['phoneNumber'] ?? '',
        phoneNumberId: j['phoneNumberId'] ?? '',
        accessToken: j['accessToken'] ?? '',
        systemPrompt: j['systemPrompt'] ?? '',
        instructions: j['instructions'] ?? '',
        aiModel: j['aiModel'] ?? 'gpt-4o-mini',
        temperature: (j['temperature'] ?? 0.7).toDouble(),
        maxTokens: j['maxTokens'] ?? 500,
        contextMessages: j['contextMessages'] ?? 10,
        isActive: j['isActive'] ?? true,
        humanKeywords: List<String>.from(j['humanKeywords'] ?? []),
        humanTransferMessage: j['humanTransferMessage'] ?? '',
        errorMessage: j['errorMessage'] ?? '',
        stats: Map<String, dynamic>.from(j['stats'] ?? {}),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );

  String get statusLabel => isActive ? 'Activo' : 'Inactivo';
  Color get statusColor =>
      isActive ? const Color(0xFF25D366) : const Color(0xFF6B7280);
}

class WAConversation {
  final String id;
  final String botId;
  final String from;
  final String contactName;
  final String lastMessage;
  final int unreadCount;
  final bool humanControl;
  final DateTime lastMessageAt;

  WAConversation({
    required this.id,
    required this.botId,
    required this.from,
    required this.contactName,
    required this.lastMessage,
    this.unreadCount = 0,
    this.humanControl = false,
    required this.lastMessageAt,
  });

  factory WAConversation.fromJson(Map<String, dynamic> j) => WAConversation(
        id: j['id'] ?? '',
        botId: j['botId'] ?? '',
        from: j['from'] ?? '',
        contactName: j['contactName'] ?? j['from'] ?? 'Desconocido',
        lastMessage: j['lastMessage'] ?? '',
        unreadCount: j['unreadCount'] ?? 0,
        humanControl: j['humanControl'] ?? false,
        lastMessageAt: _parseDate(j['lastMessageAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Map && v['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(v['_seconds'] * 1000);
    }
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

class WAMessage {
  final String id;
  final String body;
  final String role;
  final String contactName;
  final DateTime timestamp;

  WAMessage({
    required this.id,
    required this.body,
    required this.role,
    required this.contactName,
    required this.timestamp,
  });

  factory WAMessage.fromJson(Map<String, dynamic> j) => WAMessage(
        id: j['id'] ?? '',
        body: j['body'] ?? '',
        role: j['role'] ?? 'user',
        contactName: j['contactName'] ?? '',
        timestamp: WAConversation._parseDate(j['timestamp']),
      );
}

// ─────────────────────────────────────────
// SERVICIO API
// ─────────────────────────────────────────

class WAService {
  final String userId;
  WAService(this.userId);

  Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'});
        log("message12: "+Uri.parse('$kWABaseUrl$path').toString());
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
            log("message123: "+Uri.parse('$kWABaseUrl$path').toString());
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(
      String path, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final r = await http.delete(Uri.parse('$kWABaseUrl$path'),
        headers: {'Content-Type': 'application/json'});
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<WAChatbot>> getChatbots() async {
    final res = await _get('/api/wa/chatbots/$userId');
    if (res['success'] == true) {
      return (res['data']['chatbots'] as List)
          .map((e) => WAChatbot.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<String?> createChatbot(Map<String, dynamic> config) async {
    final res =
        await _post('/api/wa/chatbots', {'userId': userId, 'chatbot': config});
    return res['success'] == true ? res['data']['id'] as String : null;
  }

  Future<bool> updateChatbot(String botId, Map<String, dynamic> updates) async {
    final res = await _patch('/api/wa/chatbots/$userId/$botId', updates);
    return res['success'] == true;
  }

  Future<bool> deleteChatbot(String botId) async {
    final res = await _delete('/api/wa/chatbots/$userId/$botId');
    return res['success'] == true;
  }

  Future<bool> toggleAI(String botId) async {
    final res =
        await _post('/api/wa/chatbots/$userId/$botId/toggle-ai', {});
    return res['success'] == true;
  }

  Future<Map<String, dynamic>?> getBotStatus(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/status');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> getBotSummary(String botId) async {
    final res = await _get('/api/wa/chatbots/$userId/$botId/summary');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> getBotStats(String botId,
      {String period = '7d'}) async {
    final res =
        await _get('/api/wa/chatbots/$userId/$botId/stats?period=$period');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }

  Future<List<WAConversation>> getConversations(String botId) async {
    final res =
        await _get('/api/wa/chatbots/$userId/$botId/conversations');
    if (res['success'] == true) {
      return (res['data']['conversations'] as List)
          .map((e) => WAConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<WAMessage>> getMessages(String conversationId) async {
    final res =
        await _get('/api/wa/conversations/$conversationId/messages');
    if (res['success'] == true) {
      return (res['data']['messages'] as List)
          .map((e) => WAMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<bool> sendMessage(
      String conversationId, String text, String agentName) async {
    final res = await _post('/api/wa/conversations/$conversationId/send',
        {'text': text, 'agentName': agentName});
    return res['success'] == true;
  }

  Future<bool> setHumanControl(
      String conversationId, bool enable) async {
    final res = await _post(
        '/api/wa/conversations/$conversationId/human-control',
        {'enable': enable});
    return res['success'] == true;
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    final res = await _get('/api/wa/dashboard/$userId');
    return res['success'] == true
        ? res['data'] as Map<String, dynamic>
        : null;
  }
}

// ─────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────

class WAColors {
  static const bg = Color(0xFF0B0E14);
  static const surface = Color(0xFF131720);
  static const card = Color(0xFF1A1F2E);
  static const cardLight = Color(0xFF1F2535);
  static const border = Color(0xFF252D3D);
  static const green = Color(0xFF25D366);
  static const greenDark = Color(0xFF128C7E);
  static const accent = Color(0xFF6C63FF);
  static const textPri = Color(0xFFEEEFF5);
  static const textSec = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const human = Color(0xFFF97316);
}

// ─────────────────────────────────────────
// PÁGINA PRINCIPAL
// ─────────────────────────────────────────

class WhatsappChatbotPage extends StatefulWidget {
  final String userId;
  const WhatsappChatbotPage({super.key, required this.userId});

  @override
  State<WhatsappChatbotPage> createState() => _WhatsappChatbotPageState();
}

class _WhatsappChatbotPageState extends State<WhatsappChatbotPage> {
  late WAService _service;
  List<WAChatbot> _bots = [];
  bool _loading = true;
  String _currentView = 'dashboard';
  WAChatbot? _selectedBot;

  @override
  void initState() {
    super.initState();
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
      body: Row(
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
      case 'dashboard':
        return _DashboardView(
          service: _service,
          bots: _bots,
          onSelectBot: (bot) =>
              setState(() {
                _selectedBot = bot;
                _currentView = 'botDetail';
              }),
        );
        case 'analyticsGlobal':
  return _GlobalAnalyticsView(
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
  return _AnalyticsView(
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
        return _ConfigView(
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
class _DashboardView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final Function(WAChatbot) onSelectBot;
  const _DashboardView(
      {required this.service,
      required this.bots,
      required this.onSelectBot});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
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
    return Container(
      color: WAColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Dashboard',
            subtitle: 'Panel de control de tus bots',
            icon: Icons.dashboard_rounded,
            iconColor: WAColors.green,
            actions: [
              _HeaderBtn(
                  icon: Icons.refresh,
                  label: 'Actualizar',
                  onTap: _load),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: WAColors.green))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatCard(
                              label: 'Total Bots',
                              value:
                                  '${_dashboard?['totalBots'] ?? widget.bots.length}',
                              icon: Icons.smart_toy_rounded,
                              color: WAColors.accent,
                            ),
                            const SizedBox(width: 16),
                            _StatCard(
                              label: 'Bots Activos',
                              value:
                                  '${_dashboard?['activeBots'] ?? widget.bots.where((b) => b.isActive).length}',
                              icon: Icons.check_circle_rounded,
                              color: WAColors.green,
                            ),
                            const SizedBox(width: 16),
                            _StatCard(
                              label: 'Conversaciones',
                              value:
                                  '${_dashboard?['totalConversations'] ?? 0}',
                              icon: Icons.chat_bubble_rounded,
                              color: WAColors.info,
                            ),
                            const SizedBox(width: 16),
                            _StatCard(
                              label: 'Atención Humana',
                              value:
                                  '${_dashboard?['pendingHumanControl'] ?? 0}',
                              icon: Icons.person_rounded,
                              color: WAColors.human,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text('Tus Bots',
                            style: TextStyle(
                                color: WAColors.textPri,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        if (widget.bots.isEmpty)
                          _EmptyState(
                            icon: Icons.smart_toy_outlined,
                            title: 'Sin bots creados',
                            subtitle:
                                'Ve a "Mis Bots" para crear tu primer chatbot',
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: widget.bots.length,
                            itemBuilder: (_, i) => _BotCard(
                              bot: widget.bots[i],
                              onTap: () => widget.onSelectBot(widget.bots[i]),
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
          _PageHeader(
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
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.add, size: 16),
      SizedBox(width: 8),
      Text('Nuevo Bot'),
    ],
  ),
),
            ],
          ),
          Expanded(
            child: bots.isEmpty
                ? _EmptyState(
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
                    itemBuilder: (_, i) => _BotListTile(
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
          _PageHeader(
            title: widget.bot.name,
            subtitle: widget.bot.companyName.isNotEmpty
                ? widget.bot.companyName
                : widget.bot.description,
            icon: Icons.smart_toy_rounded,
            iconColor: widget.bot.statusColor,
            onBack: widget.onBack,
            actions: [
              _StatusBadge(
                  label: widget.bot.statusLabel,
                  color: widget.bot.statusColor),
              const SizedBox(width: 8),
              _ActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Estadísticas',
                  onTap: widget.onOpenStats),
              const SizedBox(width: 8),
              _ActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Editar',
                  onTap: widget.onEdit),
              const SizedBox(width: 8),
              _ActionButton(
                  icon: Icons.chat_rounded,
                  label: 'Chat',
                  onTap: widget.onOpenChat),

      _ActionButton(
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
                        _WACard(
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
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Acciones rápidas',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              _QuickAction(
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
                              _QuickAction(
                                icon: Icons.chat_rounded,
                                label: 'Ver Conversaciones',
                                color: WAColors.info,
                                onTap: widget.onOpenChat,
                              ),
                              const SizedBox(height: 8),
                              _QuickAction(
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
                          _WACard(
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
                                    _MiniStat(
                                        'Total convs.',
                                        '${_summary!['totalConversations'] ?? 0}',
                                        WAColors.accent),
                                    _MiniStat(
                                        'Activas 24h',
                                        '${_summary!['activeConversations24h'] ?? 0}',
                                        WAColors.green),
                                    _MiniStat(
                                        'Activas 7d',
                                        '${_summary!['activeConversations7d'] ?? 0}',
                                        WAColors.info),
                                    _MiniStat(
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
                                    _MiniStat(
                                        'Msgs recibidos',
                                        '${(_summary!['weekStats'] as Map?)?['messagesReceived'] ?? 0}',
                                        WAColors.textSec),
                                    _MiniStat(
                                        'Msgs enviados',
                                        '${(_summary!['weekStats'] as Map?)?['messagesSent'] ?? 0}',
                                        WAColors.textSec),
                                    _MiniStat(
                                        'Resp. IA',
                                        '${(_summary!['weekStats'] as Map?)?['aiReplies'] ?? 0}',
                                        WAColors.accent),
                                    _MiniStat(
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
                        _WACard(
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
                              _ConfigRow('Modelo IA', widget.bot.aiModel),
                              _ConfigRow('Temperatura',
                                  '${widget.bot.temperature}'),
                              _ConfigRow(
                                  'Max tokens', '${widget.bot.maxTokens}'),
                              _ConfigRow('Contexto msgs',
                                  '${widget.bot.contextMessages}'),
                              _ConfigRow('Número WA',
                                  widget.bot.phoneNumber.isNotEmpty ? widget.bot.phoneNumber : 'No configurado'),
                              if (widget.bot.humanKeywords.isNotEmpty)
                                _ConfigRow('Palabras clave',
                                    widget.bot.humanKeywords.join(', ')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.bot.systemPrompt.isNotEmpty)
                          _WACard(
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

 Future<void> _loadConversations(String botId) async {
  if (!mounted) return; // AGREGA ESTA LÍNEA
  setState(() => _loadingConvs = true);
  _conversations = await widget.service.getConversations(botId);
  if (!mounted) return; // AGREGA ESTA LÍNEA
  setState(() => _loadingConvs = false);
}
Future<void> _refreshMessages() async {
  if (_selectedConv == null) return;
  final msgs = await widget.service.getMessages(_selectedConv!.id);
  if (mounted && msgs.length != _messages.length) { // ya tiene mounted, está bien
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
          _PageHeader(
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
                                          _MessageBubble(msg: _messages[i]),
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
          _PageHeader(
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
                                _StatCard(
                                    label: 'Msgs Recibidos',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['messagesReceived'] ?? 0}',
                                    icon: Icons.download_rounded,
                                    color: WAColors.info),
                                const SizedBox(width: 16),
                                _StatCard(
                                    label: 'Msgs Enviados',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['messagesSent'] ?? 0}',
                                    icon: Icons.upload_rounded,
                                    color: WAColors.green),
                                const SizedBox(width: 16),
                                _StatCard(
                                    label: 'Respuestas IA',
                                    value:
                                        '${(_stats!['totals'] as Map?)?['aiReplies'] ?? 0}',
                                    icon: Icons.psychology_rounded,
                                    color: WAColors.accent),
                                const SizedBox(width: 16),
                                _StatCard(
                                    label: 'Tasa Respuesta',
                                    value:
                                        '${_stats!['responseRate'] ?? '0.0'}%',
                                    icon: Icons.speed_rounded,
                                    color: WAColors.warning),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _WACard(
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
                                  child: _WACard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Conversaciones',
                                            style: TextStyle(
                                                color: WAColors.textPri,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 16),
                                        _InfoRow('Total',
                                            '${_stats!['totalConversations'] ?? 0}'),
                                        _InfoRow('Activas 24h',
                                            '${_stats!['activeConversations'] ?? 0}'),
                                        _InfoRow('Control humano',
                                            '${_stats!['humanControlCount'] ?? 0}'),
                                        _InfoRow('% IA',
                                            '${_stats!['aiRate'] ?? '0.0'}%'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _WACard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rendimiento',
                                            style: TextStyle(
                                                color: WAColors.textPri,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 16),
                                        _InfoRow(
                                            'Recibidos',
                                            '${(_stats!['totals'] as Map?)?['messagesReceived'] ?? 0}'),
                                        _InfoRow(
                                            'Enviados',
                                            '${(_stats!['totals'] as Map?)?['messagesSent'] ?? 0}'),
                                        _InfoRow(
                                            'Resp. IA',
                                            '${(_stats!['totals'] as Map?)?['aiReplies'] ?? 0}'),
                                        _InfoRow(
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
// CONFIG VIEW
// ─────────────────────────────────────────
class _ConfigView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _ConfigView(
      {required this.bot,
      required this.service,
      required this.onBack,
      required this.onSaved});

  @override
  State<_ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<_ConfigView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _phoneIdCtrl;
  late TextEditingController _tokenCtrl;
  late TextEditingController _promptCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _errorMsgCtrl;
  late TextEditingController _transferMsgCtrl;
  late TextEditingController _keywordsCtrl;
  String _model = 'gpt-4o-mini';
  double _temperature = 0.7;
  int _maxTokens = 500;
  int _contextMessages = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bot;
    _nameCtrl = TextEditingController(text: b.name);
    _descCtrl = TextEditingController(text: b.description);
    _companyCtrl = TextEditingController(text: b.companyName);
    _phoneCtrl = TextEditingController(text: b.phoneNumber);
    _phoneIdCtrl = TextEditingController(text: b.phoneNumberId);
    _tokenCtrl = TextEditingController(text: b.accessToken);
    _promptCtrl = TextEditingController(text: b.systemPrompt);
    _instructionsCtrl = TextEditingController(text: b.instructions);
    _errorMsgCtrl = TextEditingController(
        text: b.errorMessage.isNotEmpty
            ? b.errorMessage
            : 'Lo siento, hubo un error. Intenta de nuevo.');
    _transferMsgCtrl = TextEditingController(
        text: b.humanTransferMessage.isNotEmpty
            ? b.humanTransferMessage
            : 'Te conecto con un agente. Un momento por favor.');
    _keywordsCtrl =
        TextEditingController(text: b.humanKeywords.join(', '));
    _model = b.aiModel;
    _temperature = b.temperature;
    _maxTokens = b.maxTokens;
    _contextMessages = b.contextMessages;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneIdCtrl.dispose();
    _tokenCtrl.dispose();
    _promptCtrl.dispose();
    _instructionsCtrl.dispose();
    _errorMsgCtrl.dispose();
    _transferMsgCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await widget.service.updateChatbot(widget.bot.id, {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'companyName': _companyCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'phoneNumberId': _phoneIdCtrl.text.trim(),
      'accessToken': _tokenCtrl.text.trim(),
      'systemPrompt': _promptCtrl.text.trim(),
      'instructions': _instructionsCtrl.text.trim(),
      'aiModel': _model,
      'temperature': _temperature,
      'maxTokens': _maxTokens,
      'contextMessages': _contextMessages,
      'humanKeywords': keywords,
      'errorMessage': _errorMsgCtrl.text.trim(),
      'humanTransferMessage': _transferMsgCtrl.text.trim(),
    });

    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          _PageHeader(
            title: 'Configurar Bot',
            subtitle: widget.bot.name,
            icon: Icons.settings_rounded,
            iconColor: WAColors.accent,
            onBack: widget.onBack,
            actions: [
          ElevatedButton(
  onPressed: _saving ? null : _save,
  style: ElevatedButton.styleFrom(
    backgroundColor: WAColors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    minimumSize: Size.zero, // ✅
    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _saving
          ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 16),
      const SizedBox(width: 8),
      Text(_saving ? 'Guardando...' : 'Guardar'),
    ],
  ),
),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Col 1
                  Expanded(
                    child: Column(
                      children: [
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Información básica',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              _FormField(
                                  label: 'Nombre del bot',
                                  controller: _nameCtrl),
                              const SizedBox(height: 12),
                              _FormField(
                                  label: 'Descripción',
                                  controller: _descCtrl,
                                  maxLines: 2),
                              const SizedBox(height: 12),
                              _FormField(
                                  label: 'Empresa / Negocio',
                                  controller: _companyCtrl),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Configuración WhatsApp',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Datos de tu cuenta de WhatsApp Business (Meta)',
                                  style: TextStyle(
                                      color: WAColors.textMuted,
                                      fontSize: 12)),
                              const SizedBox(height: 14),
                              _FormField(
                                label: 'Número de WhatsApp',
                                controller: _phoneCtrl,
                                hint: 'Ej: +573001234567',
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Phone Number ID (Meta)',
                                controller: _phoneIdCtrl,
                                hint: 'ID del número en Meta Business',
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Access Token (Meta)',
                                controller: _tokenCtrl,
                                hint: 'Token de acceso de Meta',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prompt del sistema',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'System Prompt',
                                controller: _promptCtrl,
                                maxLines: 6,
                                hint:
                                    'Eres un asistente de WhatsApp para {empresa}...',
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Instrucciones adicionales',
                                controller: _instructionsCtrl,
                                maxLines: 4,
                                hint:
                                    'Reglas específicas: horarios, precios...',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Col 2
                  Expanded(
                    child: Column(
                      children: [
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Configuración IA',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              const Text('Modelo',
                                  style: TextStyle(
                                      color: WAColors.textSec,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: WAColors.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: WAColors.border),
                                ),
                                child: DropdownButton<String>(
                                  value: _model,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  dropdownColor: WAColors.card,
                                  style: const TextStyle(
                                      color: WAColors.textPri,
                                      fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'gpt-4o-mini',
                                        child: Text('GPT-4o Mini (rápido)')),
                                    DropdownMenuItem(
                                        value: 'gpt-4o',
                                        child: Text('GPT-4o (potente)')),
                                    DropdownMenuItem(
                                        value: 'gpt-3.5-turbo',
                                        child: Text('GPT-3.5 Turbo')),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _model = v!),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Creatividad (Temperatura)',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text(_temperature.toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: WAColors.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _temperature,
                                min: 0,
                                max: 1,
                                divisions: 10,
                                activeColor: WAColors.green,
                                inactiveColor: WAColors.border,
                                onChanged: (v) =>
                                    setState(() => _temperature = v),
                              ),
                              Row(
                                children: [
                                  const Text('Máx. tokens',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text('$_maxTokens',
                                      style: const TextStyle(
                                          color: WAColors.accent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _maxTokens.toDouble(),
                                min: 100,
                                max: 2000,
                                divisions: 19,
                                activeColor: WAColors.accent,
                                inactiveColor: WAColors.border,
                                onChanged: (v) =>
                                    setState(() => _maxTokens = v.toInt()),
                              ),
                              Row(
                                children: [
                                  const Text('Mensajes de contexto',
                                      style: TextStyle(
                                          color: WAColors.textSec,
                                          fontSize: 12)),
                                  const Spacer(),
                                  Text('$_contextMessages',
                                      style: const TextStyle(
                                          color: WAColors.info,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _contextMessages.toDouble(),
                                min: 3,
                                max: 20,
                                divisions: 17,
                                activeColor: WAColors.info,
                                inactiveColor: WAColors.border,
                                onChanged: (v) => setState(
                                    () => _contextMessages = v.toInt()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _WACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Control Humano',
                                  style: TextStyle(
                                      color: WAColors.textPri,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Palabras que activan el traspaso al agente',
                                  style: TextStyle(
                                      color: WAColors.textMuted,
                                      fontSize: 12)),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Palabras clave (separadas por coma)',
                                controller: _keywordsCtrl,
                                hint: 'humano, agente, persona, help',
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Mensaje de transferencia',
                                controller: _transferMsgCtrl,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Mensaje de error',
                                controller: _errorMsgCtrl,
                                maxLines: 2,
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
              _FormField(label: 'Nombre del bot *', controller: _nameCtrl, hint: 'Ej: Soporte Ventas'),
              const SizedBox(height: 12),
              _FormField(label: 'Empresa / Negocio', controller: _companyCtrl, hint: 'Ej: Mi Empresa S.A.'),
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

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onBack,
    this.actions = const [],
  });

  @override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: const BoxDecoration(
      color: WAColors.surface,
      border: Border(bottom: BorderSide(color: WAColors.border)),
    ),
    child: Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: WAColors.textSec),
          ),
          const SizedBox(width: 4),
        ],
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: WAColors.textPri,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: const TextStyle(
                      color: WAColors.textMuted, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
      ],
    ),
  );
}
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: WAColors.textSec),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WACard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _WACard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WAColors.border),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WAColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WAColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: WAColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _BotCard extends StatelessWidget {
  final WAChatbot bot;
  final VoidCallback onTap;
  const _BotCard({required this.bot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WAColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WAColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bot.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat, size: 18, color: WAColors.green),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: bot.statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: bot.statusColor.withOpacity(0.5),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(bot.name,
                style: const TextStyle(
                    color: WAColors.textPri,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
                overflow: TextOverflow.ellipsis),
            Text(
                bot.companyName.isNotEmpty
                    ? bot.companyName
                    : bot.aiModel,
                style: const TextStyle(
                    color: WAColors.textMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bot.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(bot.statusLabel,
                  style: TextStyle(
                      color: bot.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotListTile extends StatelessWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onRefresh;
  final VoidCallback onTap;
  const _BotListTile(
      {required this.bot,
      required this.service,
      required this.onRefresh,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WAColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WAColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: bot.statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat, color: WAColors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(bot.name,
                          style: const TextStyle(
                              color: WAColors.textPri,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bot.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: bot.statusColor,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(bot.statusLabel,
                                style: TextStyle(
                                    color: bot.statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bot.phoneNumber.isNotEmpty
                        ? '${bot.phoneNumber} • ${bot.aiModel}'
                        : bot.aiModel,
                    style: const TextStyle(
                        color: WAColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: bot.isActive ? Icons.pause_circle : Icons.play_circle,
                  label: bot.isActive ? 'Pausar IA' : 'Activar IA',
                  color: bot.isActive ? WAColors.warning : WAColors.green,
                  onTap: () async {
                    await service.toggleAI(bot.id);
                    onRefresh();
                  },
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: 'Ver',
                  onTap: onTap,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar',
                  color: WAColors.error,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WAColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar Bot',
            style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w700)),
        content: Text(
          '¿Seguro que quieres eliminar "${bot.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: WAColors.textSec, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: WAColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteChatbot(bot.id);
              onRefresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WAColors.error,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final WAMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isBot = msg.role == 'assistant';
    final isAgent = msg.role == 'agent';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: WAColors.cardLight,
              child: Text(
                msg.contactName.isNotEmpty
                    ? msg.contactName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: WAColors.textPri,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? WAColors.cardLight
                    : isBot
                        ? WAColors.green.withOpacity(0.18)
                        : WAColors.human.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 4 : 16),
                  bottomRight: Radius.circular(isUser ? 16 : 4),
                ),
                border: Border.all(
                  color: isUser
                      ? WAColors.border
                      : isBot
                          ? WAColors.green.withOpacity(0.25)
                          : WAColors.human.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.body,
                      style: const TextStyle(
                          color: WAColors.textPri,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUser) ...[
                        Icon(
                          isBot ? Icons.psychology : Icons.person,
                          size: 10,
                          color: isBot ? WAColors.green : WAColors.human,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBot ? 'IA' : 'Agente',
                          style: TextStyle(
                              color:
                                  isBot ? WAColors.green : WAColors.human,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: const TextStyle(
                            color: WAColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: isBot
                  ? WAColors.green.withOpacity(0.2)
                  : WAColors.human.withOpacity(0.2),
              child: Icon(
                isBot ? Icons.psychology : Icons.person,
                size: 14,
                color: isBot ? WAColors.green : WAColors.human,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: WAColors.card, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: WAColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: WAColors.textPri,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: WAColors.textMuted, fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  const _FormField(
      {required this.label,
      required this.controller,
      this.maxLines = 1,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: WAColors.textSec,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style:
              const TextStyle(color: WAColors.textPri, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: WAColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: WAColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: WAColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: WAColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: WAColors.green),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? WAColors.accent).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: (color ?? WAColors.accent).withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? WAColors.accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color ?? WAColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: WAColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfigRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: WAColors.textMuted, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: WAColors.textSec,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: WAColors.textSec, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: WAColors.textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

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
          _PageHeader(
            title: 'Conexión Facebook',
            subtitle: 'Estado de integración con WhatsApp Business',
            icon: Icons.link_rounded,
            iconColor: const Color(0xFF1877F2),
            actions: [
              _HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
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
                        _WACard(
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
                              child: _WACard(
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
                                        _StatusBadge(
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
                        _WACard(
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
                              _InfoRow('Total conversaciones',
                                  '${_dashboard?['totalConversations'] ?? 0}'),
                              _InfoRow('Conversaciones activas (24h)',
                                  '${_dashboard?['activeConversations'] ?? 0}'),
                              _InfoRow('Pendientes atención humana',
                                  '${_dashboard?['pendingHumanControl'] ?? 0}'),
                              _InfoRow('Bots con número configurado',
                                  '${widget.bots.where((b) => b.phoneNumber.isNotEmpty).length}'),
                              _InfoRow('Bots con Phone ID',
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

// ─────────────────────────────────────────
// ANALYTICS VIEW — Embudo + Usuarios + Trazabilidad IA
// ─────────────────────────────────────────
class _AnalyticsView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  const _AnalyticsView({required this.bot, required this.service, required this.onBack});

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView>
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
          _PageHeader(
            title: 'Analytics — ${widget.bot.name}',
            subtitle: 'Embudo, usuarios y trazabilidad IA',
            icon: Icons.analytics_rounded,
            iconColor: WAColors.accent,
            onBack: widget.onBack,
            actions: [
              _HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
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
          _WACard(
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
                child: _WACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Por semana',
                          style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      _InfoRow('Nuevos esta semana',
                          '${_conversations.where((c) => DateTime.now().difference(c.lastMessageAt).inDays <= 7).length}'),
                      _InfoRow('Activos esta semana',
                          '${_conversations.where((c) => DateTime.now().difference(c.lastMessageAt).inDays <= 7).length}'),
                      _InfoRow('Tasa derivación humano',
                          _totalUsers > 0 ? '${(_humanControl / _totalUsers * 100).toStringAsFixed(1)}%' : '0%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _WACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estados',
                          style: TextStyle(color: WAColors.textPri, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      _InfoRow('Modo IA activo', '$_aiOnly'),
                      _InfoRow('Modo humano activo', '$_humanControl'),
                      _InfoRow('Total usuarios únicos', '$_totalUsers'),
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
            _EmptyState(
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
                    child: _WACard(
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
                              _MiniStat('Usuario', '$userMsgs', WAColors.accent),
                              _MiniStat('Resp. IA', '$aiMsgs', WAColors.green),
                              _MiniStat('Agente', '$agentMsgs', WAColors.human),
                              _MiniStat('Total', '${msgs.length}', WAColors.textSec),
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


// ─────────────────────────────────────────
// GLOBAL ANALYTICS VIEW
// ─────────────────────────────────────────
class _GlobalAnalyticsView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final Function(WAChatbot) onSelectBot;
  const _GlobalAnalyticsView({
    required this.service,
    required this.bots,
    required this.onSelectBot,
  });

  @override
  State<_GlobalAnalyticsView> createState() => _GlobalAnalyticsViewState();
}

class _GlobalAnalyticsViewState extends State<_GlobalAnalyticsView>
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
          _PageHeader(
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
              _HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
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
                child: _WACard(
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
    _CompactStat('Total', '${convs.length}', WAColors.accent),
    const SizedBox(width: 20),
    _CompactStat('Activos', '$active', WAColors.green),
    const SizedBox(width: 20),
    _CompactStat('Humano', '$human', WAColors.human),
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
          _WACard(
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
              ? _EmptyState(
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
                              _MiniStat('Usuario', '$userMsgs', WAColors.accent),
                              _MiniStat('Resp. IA', '$aiMsgs', WAColors.green),
                              _MiniStat('Agente', '$agentMsgs', WAColors.human),
                              _MiniStat('Total', '${msgs.length}', WAColors.textSec),
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

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CompactStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: WAColors.textMuted, fontSize: 10)),
      ],
    );
  }
}