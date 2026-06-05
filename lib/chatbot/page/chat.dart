import 'dart:developer';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
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

// ─────────────────────────────────────────
// CHAT VIEW
// ─────────────────────────────────────────
class ChatView extends StatefulWidget {
  final WAChatbot? bot;
  final List<WAChatbot> bots;
  final WAService service;
  final Function(WAChatbot) onSelectBot;
  final VoidCallback onBack;
  const ChatView(
      {this.bot,
      required this.bots,
      required this.service,
      required this.onSelectBot,
      required this.onBack});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
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
                    style:
                        const TextStyle(color: WAColors.textPri, fontSize: 13),
                    items: widget.bots
                        .map((b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)))
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
                    border: Border(right: BorderSide(color: WAColors.border)),
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
                                        onTap: () => _selectConversation(conv),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          color: isSelected
                                              ? WAColors.green.withOpacity(0.1)
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
                                                              fontWeight:
                                                                  conv.unreadCount >
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
                                                          _formatTime(conv
                                                              .lastMessageAt),
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
                                      color: WAColors.textMuted, fontSize: 13)),
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
                                    bottom: BorderSide(color: WAColors.border)),
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
                                        onChanged: (_) => _toggleHumanControl(),
                                        activeColor: WAColors.human,
                                        inactiveTrackColor:
                                            WAColors.green.withOpacity(0.3),
                                        thumbColor: MaterialStateProperty.all(
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
                                      top: BorderSide(color: WAColors.border)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: WAColors.human.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
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
                                                  horizontal: 16, vertical: 10),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: _sendMessage,
                                      borderRadius: BorderRadius.circular(24),
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
