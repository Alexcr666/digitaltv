import 'dart:convert';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════
// MODELO DE PLANTILLA RICO
// ══════════════════════════════════════════════════════════
class WATemplate {
  final String id;
  final String name;
  final String category;
  final String status; // APPROVED, PENDING, REJECTED, LOCAL
  final String headerType; // NONE, TEXT, IMAGE, VIDEO, AUDIO, DOCUMENT
  final String headerText;
  final String headerMediaUrl;
  final String body;
  final String footer;
  final List<Map<String, dynamic>> buttons;
  final List<String> bodyVariables;
  final DateTime createdAt;
  final String? rejectionReason;

  WATemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.headerType,
    required this.headerText,
    required this.headerMediaUrl,
    required this.body,
    required this.footer,
    required this.buttons,
    required this.bodyVariables,
    required this.createdAt,
    this.rejectionReason,
  });

  factory WATemplate.fromJson(Map<String, dynamic> j) => WATemplate(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        category: j['category'] ?? 'MARKETING',
        status: j['status'] ?? 'LOCAL',
        headerType: j['headerType'] ?? 'NONE',
        headerText: j['headerText'] ?? '',
        headerMediaUrl: j['headerMediaUrl'] ?? '',
        body: j['body'] ?? '',
        footer: j['footer'] ?? '',
        buttons: List<Map<String, dynamic>>.from(j['buttons'] ?? []),
        bodyVariables: List<String>.from(j['bodyVariables'] ?? []),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        rejectionReason: j['rejectionReason'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'status': status,
        'headerType': headerType,
        'headerText': headerText,
        'headerMediaUrl': headerMediaUrl,
        'body': body,
        'footer': footer,
        'buttons': buttons,
        'bodyVariables': bodyVariables,
        'createdAt': createdAt.toIso8601String(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

  Color get statusColor => switch (status) {
        'APPROVED' => WAColors.green,
        'PENDING' => WAColors.warning,
        'REJECTED' => WAColors.error,
        _ => WAColors.textMuted,
      };

  String get statusLabel => switch (status) {
        'APPROVED' => 'Aprobada',
        'PENDING' => 'Pendiente',
        'REJECTED' => 'Rechazada',
        _ => 'Local',
      };

  IconData get statusIcon => switch (status) {
        'APPROVED' => Icons.check_circle_rounded,
        'PENDING' => Icons.hourglass_empty_rounded,
        'REJECTED' => Icons.cancel_rounded,
        _ => Icons.save_rounded,
      };
}

// ══════════════════════════════════════════════════════════
// VISTA PRINCIPAL
// ══════════════════════════════════════════════════════════
class MassSendView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  const MassSendView({required this.service, required this.bots});
  @override
  State<MassSendView> createState() => _MassSendViewState();
}

class _MassSendViewState extends State<MassSendView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WAChatbot? _selectedBot;
  List<WAConversation> _contacts = [];
  List<String> _selectedIds = [];
  bool _loadingContacts = false;
  bool _sending = false;
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = false;

  List<WATemplate> _templates = [];
  bool _loadingTemplates = false;
  WATemplate? _selectedTemplate;
  Map<String, String> _templateVarValues = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.bots.isNotEmpty) {
      _selectedBot = widget.bots.first;
      _loadAll();
    }
    _msgCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadContacts(), _loadTemplates(), _loadHistory()]);
  }

  Future<void> _loadContacts() async {
    if (_selectedBot == null) return;
    setState(() => _loadingContacts = true);
    final convs = await widget.service.getConversations(_selectedBot!.id);
    if (mounted)
      setState(() {
        _contacts = convs;
        _loadingContacts = false;
      });
  }

  Future<void> _loadTemplates() async {
    if (_selectedBot == null) return;
    setState(() => _loadingTemplates = true);
    final raw = await widget.service.getTemplatesRich(_selectedBot!.id);
    if (mounted)
      setState(() {
        _templates = raw;
        _loadingTemplates = false;
      });
  }

  Future<void> _loadHistory() async {
    if (_selectedBot == null) return;
    setState(() => _loadingHistory = true);
    final h = await widget.service.getMassSendHistory(_selectedBot!.id);
    if (mounted)
      setState(() {
        _history = h;
        _loadingHistory = false;
      });
  }

  bool get _canSend {
    if (_selectedIds.isEmpty) return false;
    if (_selectedTemplate != null) return true;
    return _msgCtrl.text.trim().isNotEmpty;
  }

  Future<void> _sendMass() async {
    if (_selectedBot == null || !_canSend) return;
    String text = '';
    if (_selectedTemplate != null) {
      text = _resolveTemplateBody(_selectedTemplate!.body, _templateVarValues);
    } else {
      text = _msgCtrl.text.trim();
    }

    setState(() => _sending = true);
    final result = await widget.service.sendMassMessage(
      botId: _selectedBot!.id,
      contactIds: _selectedIds,
      message: text,
      templateId: _selectedTemplate?.id,
    );
    setState(() => _sending = false);

    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Enviado a ${result['sent'] ?? _selectedIds.length} contactos'),
          backgroundColor: WAColors.green));
      setState(() {
        _selectedIds = [];
        _selectedTemplate = null;
        _templateVarValues = {};
        _msgCtrl.clear();
      });
      _loadHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Error al enviar'),
          backgroundColor: WAColors.error));
    }
  }

  String _resolveTemplateBody(String body, Map<String, String> vars) {
    String result = body;
    vars.forEach((k, v) {
      result = result.replaceAll('{{$k}}', v);
    });
    return result;
  }

  List<String> _extractVars(String body) {
    final rx = RegExp(r'\{\{(\d+)\}\}');
    return rx.allMatches(body).map((m) => m.group(1)!).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          Container(
            color: WAColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: WAColors.green,
              unselectedLabelColor: WAColors.textMuted,
              indicatorColor: WAColors.green,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                    icon: Icon(Icons.send_rounded, size: 15),
                    text: 'Envío Masivo'),
                Tab(
                    icon: Icon(Icons.description_rounded, size: 15),
                    text: 'Plantillas'),
                Tab(
                    icon: Icon(Icons.history_rounded, size: 15),
                    text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(),
                _buildTemplatesTab(),
                _buildHistoryTab()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: WAColors.surface,
        border: Border(bottom: BorderSide(color: WAColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WAColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.send_rounded, color: WAColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Envíos Masivos',
                  style: TextStyle(
                      color: WAColors.textPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              Text('WhatsApp masivo y plantillas',
                  style: TextStyle(color: WAColors.textMuted, fontSize: 12)),
            ],
          ),
          const Spacer(),
          if (widget.bots.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: WAColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WAColors.border),
              ),
              child: DropdownButton<String>(
                value: _selectedBot?.id,
                underline: const SizedBox(),
                dropdownColor: WAColors.card,
                style: const TextStyle(color: WAColors.textPri, fontSize: 13),
                items: widget.bots
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _selectedBot = widget.bots.firstWhere((b) => b.id == id);
                    _contacts = [];
                    _selectedIds = [];
                    _templates = [];
                    _history = [];
                  });
                  _loadAll();
                },
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB: ENVÍO MASIVO
  // ══════════════════════════════════════════════════════
  Widget _buildSendTab() {
    final allSelected =
        _selectedIds.length == _contacts.length && _contacts.isNotEmpty;
    return Row(
      children: [
        // Lista contactos
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: WAColors.surface,
            border: Border(right: BorderSide(color: WAColors.border)),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: WAColors.border)),
                ),
                child: Row(
                  children: [
                    Text('${_contacts.length} contactos',
                        style: const TextStyle(
                            color: WAColors.textSec,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const Spacer(),
                    if (_selectedIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: WAColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_selectedIds.length} sel.',
                            style: const TextStyle(
                                color: WAColors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedIds = allSelected
                            ? []
                            : _contacts.map((c) => c.from).toList();
                      }),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(allSelected ? 'Desel. todos' : 'Sel. todos',
                          style: const TextStyle(
                              color: WAColors.accent, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loadingContacts
                    ? const Center(
                        child: CircularProgressIndicator(color: WAColors.green))
                    : _contacts.isEmpty
                        ? const Center(
                            child: Text('Sin contactos',
                                style: TextStyle(color: WAColors.textMuted)))
                        : ListView.builder(
                            itemCount: _contacts.length,
                            itemBuilder: (_, i) {
                              final c = _contacts[i];
                              final sel = _selectedIds.contains(c.from);
                              return InkWell(
                                onTap: () => setState(() {
                                  if (sel)
                                    _selectedIds.remove(c.from);
                                  else
                                    _selectedIds.add(c.from);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 9),
                                  color: sel
                                      ? WAColors.green.withOpacity(0.08)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: sel,
                                          onChanged: (_) => setState(() {
                                            if (sel)
                                              _selectedIds.remove(c.from);
                                            else
                                              _selectedIds.add(c.from);
                                          }),
                                          activeColor: WAColors.green,
                                          side: const BorderSide(
                                              color: WAColors.border),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      CircleAvatar(
                                        backgroundColor:
                                            WAColors.accent.withOpacity(0.15),
                                        radius: 14,
                                        child: Text(
                                          c.contactName.isNotEmpty
                                              ? c.contactName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              color: WAColors.accent,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.contactName,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: sel
                                                        ? WAColors.textPri
                                                        : WAColors.textSec,
                                                    fontSize: 12,
                                                    fontWeight: sel
                                                        ? FontWeight.w600
                                                        : FontWeight.w400)),
                                            Text(c.from.replaceAll('@c.us', ''),
                                                style: const TextStyle(
                                                    color: WAColors.textMuted,
                                                    fontSize: 10)),
                                          ],
                                        ),
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
        // Panel mensaje
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contador seleccionados
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedIds.isNotEmpty
                            ? WAColors.green.withOpacity(0.15)
                            : WAColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _selectedIds.isNotEmpty
                                ? WAColors.green.withOpacity(0.4)
                                : WAColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_rounded,
                              size: 14,
                              color: _selectedIds.isNotEmpty
                                  ? WAColors.green
                                  : WAColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedIds.length} contactos seleccionados',
                            style: TextStyle(
                                color: _selectedIds.isNotEmpty
                                    ? WAColors.green
                                    : WAColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seleccionar plantilla aprobada
                if (_templates
                    .where((t) => t.status == 'APPROVED')
                    .isNotEmpty) ...[
                  const Text('Usar plantilla aprobada (opcional)',
                      style: TextStyle(
                          color: WAColors.textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _templates
                        .where((t) => t.status == 'APPROVED')
                        .map((t) {
                      final sel = _selectedTemplate?.id == t.id;
                      return InkWell(
                        onTap: () => setState(() {
                          if (sel) {
                            _selectedTemplate = null;
                            _templateVarValues = {};
                          } else {
                            _selectedTemplate = t;
                            _templateVarValues = {};
                            final vars = _extractVars(t.body);
                            for (final v in vars) _templateVarValues[v] = '';
                          }
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? WAColors.green.withOpacity(0.15)
                                : WAColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? WAColors.green : WAColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 12,
                                  color: sel
                                      ? WAColors.green
                                      : WAColors.textMuted),
                              const SizedBox(width: 6),
                              Text(t.name,
                                  style: TextStyle(
                                      color: sel
                                          ? WAColors.green
                                          : WAColors.textSec,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Vista previa plantilla seleccionada
                if (_selectedTemplate != null) ...[
                  _TemplatePreviewCard(
                    template: _selectedTemplate!,
                    varValues: _templateVarValues,
                    onVarChanged: (k, v) =>
                        setState(() => _templateVarValues[k] = v),
                    vars: _extractVars(_selectedTemplate!.body),
                  ),
                  const SizedBox(height: 16),
                ],

                // Mensaje libre (si no hay plantilla)
                if (_selectedTemplate == null)
                  WACard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Mensaje',
                                style: TextStyle(
                                    color: WAColors.textPri,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${_msgCtrl.text.length}/1024',
                                style: const TextStyle(
                                    color: WAColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _msgCtrl,
                          maxLines: 6,
                          maxLength: 1024,
                          style: const TextStyle(
                              color: WAColors.textPri, fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Escribe el mensaje para todos los contactos seleccionados...',
                            hintStyle: const TextStyle(
                                color: WAColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: WAColors.bg,
                            counterStyle: const TextStyle(
                                color: WAColors.textMuted, fontSize: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: WAColors.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: WAColors.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: WAColors.green)),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        // Formato rápido
                        Row(
                          children: [
                            _FormatBtn(
                                label: 'B', onTap: () => _insertFormat('*')),
                            _FormatBtn(
                                label: 'I',
                                italic: true,
                                onTap: () => _insertFormat('_')),
                            _FormatBtn(
                                label: '~', onTap: () => _insertFormat('~')),
                            _FormatBtn(
                                label: '```',
                                mono: true,
                                onTap: () => _insertFormat('```')),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Advertencia tokens
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WAColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: WAColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: WAColors.warning, size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los envíos masivos se envían directamente por WhatsApp. Solo plantillas aprobadas por Meta garantizan entrega.',
                          style:
                              TextStyle(color: WAColors.warning, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_sending || !_canSend) ? null : _sendMass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canSend ? WAColors.green : WAColors.border,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _selectedIds.isEmpty
                                    ? 'Selecciona contactos primero'
                                    : 'Enviar a ${_selectedIds.length} contactos',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _insertFormat(String marker) {
    final text = _msgCtrl.text;
    final sel = _msgCtrl.selection;
    if (sel.isValid && sel.start != sel.end) {
      final selected = text.substring(sel.start, sel.end);
      final newText =
          text.replaceRange(sel.start, sel.end, '$marker$selected$marker');
      _msgCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset:
                sel.start + marker.length + selected.length + marker.length),
      );
    } else {
      final cursor = sel.baseOffset < 0 ? text.length : sel.baseOffset;
      final newText =
          text.substring(0, cursor) + '$marker$marker' + text.substring(cursor);
      _msgCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + marker.length),
      );
    }
  }

  // ══════════════════════════════════════════════════════
  // TAB: PLANTILLAS
  // ══════════════════════════════════════════════════════
  Widget _buildTemplatesTab() {
    return Row(
      children: [
        // Lista plantillas
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Filtros de estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: WAColors.surface,
                child: Row(
                  children: [
                    const Text('Plantillas',
                        style: TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const Spacer(),
                    ...[
                      ('TODAS', null),
                      ('APPROVED', WAColors.green),
                      ('PENDING', WAColors.warning),
                      ('REJECTED', WAColors.error),
                      ('LOCAL', WAColors.textMuted),
                    ].map((e) => _StatusFilterChip(
                          label: e.$1 == 'TODAS'
                              ? 'Todas'
                              : _statusLabelShort(e.$1!),
                          color: e.$2 ?? WAColors.accent,
                          count: e.$1 == null || e.$1 == 'TODAS'
                              ? _templates.length
                              : _templates
                                  .where((t) => t.status == e.$1)
                                  .length,
                        )),
                    const SizedBox(width: 8),
                    HeaderBtn(
                        icon: Icons.refresh,
                        label: 'Sync Meta',
                        onTap: _syncMetaTemplates),
                  ],
                ),
              ),
              Expanded(
                child: _loadingTemplates
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: WAColors.accent))
                    : _templates.isEmpty
                        ? EmptyState(
                            icon: Icons.description_outlined,
                            title: 'Sin plantillas',
                            subtitle: 'Crea tu primera plantilla de mensaje',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _templates.length,
                            itemBuilder: (_, i) => _TemplateListItem(
                              template: _templates[i],
                              onDelete: () => _deleteTemplate(_templates[i].id),
                              onSync: () => _syncSingleTemplate(_templates[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
        // Panel crear plantilla
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: WAColors.surface,
            border: Border(left: BorderSide(color: WAColors.border)),
          ),
          child: _TemplateBuilderPanel(
            botId: _selectedBot?.id ?? '',
            onSaved: _loadTemplates,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTemplate(String id) async {
    if (_selectedBot == null) return;
    await widget.service.deleteTemplate(_selectedBot!.id, id);
    _loadTemplates();
  }

  Future<void> _syncMetaTemplates() async {
    if (_selectedBot == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronizando con Meta...')));
    await widget.service.syncMetaTemplates(_selectedBot!.id);
    _loadTemplates();
  }

  Future<void> _syncSingleTemplate(WATemplate t) async {
    if (_selectedBot == null) return;
    await widget.service.syncMetaTemplates(_selectedBot!.id);
    _loadTemplates();
  }

  String _statusLabelShort(String s) => switch (s) {
        'APPROVED' => '✓ Aprobadas',
        'PENDING' => '⏳ Pendientes',
        'REJECTED' => '✗ Rechazadas',
        _ => '💾 Locales',
      };

  // ══════════════════════════════════════════════════════
  // TAB: HISTORIAL
  // ══════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: WAColors.surface,
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: WAColors.accent, size: 16),
              const SizedBox(width: 8),
              Text('${_history.length} envíos masivos',
                  style: const TextStyle(
                      color: WAColors.textPri,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const Spacer(),
              HeaderBtn(
                  icon: Icons.refresh,
                  label: 'Actualizar',
                  onTap: _loadHistory),
            ],
          ),
        ),
        Expanded(
          child: _loadingHistory
              ? const Center(
                  child: CircularProgressIndicator(color: WAColors.accent))
              : _history.isEmpty
                  ? EmptyState(
                      icon: Icons.history_rounded,
                      title: 'Sin historial',
                      subtitle: 'Los envíos masivos aparecerán aquí',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (_, i) => _HistoryCard(
                        record: _history[i],
                        onExpand: () => _showHistoryDetail(_history[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  void _showHistoryDetail(Map<String, dynamic> record) {
    final results = List<Map<String, dynamic>>.from(record['results'] ?? []);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: WAColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Detalle del envío',
                      style: TextStyle(
                          color: WAColors.textPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: WAColors.textMuted, size: 18),
                  ),
                ],
              ),
              const Divider(color: WAColors.border),
              Row(
                children: [
                  _MiniChip('Total: ${record['total'] ?? 0}', WAColors.accent),
                  const SizedBox(width: 8),
                  _MiniChip('Enviados: ${record['sent'] ?? 0}', WAColors.green),
                  const SizedBox(width: 8),
                  _MiniChip(
                      'Fallidos: ${record['failed'] ?? 0}', WAColors.error),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: results.isEmpty
                    ? const Center(
                        child: Text('Sin detalles',
                            style: TextStyle(color: WAColors.textMuted)))
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: WAColors.border, height: 1),
                        itemBuilder: (_, i) {
                          final r = results[i];
                          final ok = r['status'] == 'sent';
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              ok
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: ok ? WAColors.green : WAColors.error,
                              size: 16,
                            ),
                            title: Text(
                                r['contactId']
                                        ?.toString()
                                        .replaceAll('@c.us', '') ??
                                    '',
                                style: const TextStyle(
                                    color: WAColors.textSec, fontSize: 12)),
                            trailing: Text(ok ? 'Enviado' : 'Fallido',
                                style: TextStyle(
                                    color: ok ? WAColors.green : WAColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET: PREVIEW DE PLANTILLA CON VARIABLES
// ══════════════════════════════════════════════════════════
class _TemplatePreviewCard extends StatelessWidget {
  final WATemplate template;
  final Map<String, String> varValues;
  final Function(String, String) onVarChanged;
  final List<String> vars;

  const _TemplatePreviewCard({
    required this.template,
    required this.varValues,
    required this.onVarChanged,
    required this.vars,
  });

  String _resolve(String text) {
    String r = text;
    varValues.forEach(
        (k, v) => r = r.replaceAll('{{$k}}', v.isEmpty ? '{{$k}}' : v));
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WAColors.green.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header plantilla seleccionada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WAColors.green.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: WAColors.green, size: 14),
                const SizedBox(width: 8),
                Text('Plantilla: ${template.name}',
                    style: const TextStyle(
                        color: WAColors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WAColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('APROBADA',
                      style: TextStyle(
                          color: WAColors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview del mensaje
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WAColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WAColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (template.headerType != 'NONE') ...[
                        _HeaderPreview(template: template),
                        const SizedBox(height: 8),
                      ],
                      Text(_resolve(template.body),
                          style: const TextStyle(
                              color: WAColors.textPri,
                              fontSize: 13,
                              height: 1.5)),
                      if (template.footer.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(template.footer,
                            style: const TextStyle(
                                color: WAColors.textMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                // Variables dinámicas
                if (vars.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Completa las variables:',
                      style: TextStyle(
                          color: WAColors.textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...vars.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: WAColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('{{$v}}',
                                  style: const TextStyle(
                                      color: WAColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(
                                    color: WAColors.textPri, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Valor para variable $v',
                                  hintStyle: const TextStyle(
                                      color: WAColors.textMuted, fontSize: 12),
                                  filled: true,
                                  fillColor: WAColors.bg,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: WAColors.border)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: WAColors.border)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: WAColors.accent)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                onChanged: (val) => onVarChanged(v, val),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPreview extends StatelessWidget {
  final WATemplate template;
  const _HeaderPreview({required this.template});

  @override
  Widget build(BuildContext context) {
    switch (template.headerType) {
      case 'TEXT':
        return Text(template.headerText,
            style: const TextStyle(
                color: WAColors.textPri,
                fontWeight: FontWeight.w700,
                fontSize: 15));
      case 'IMAGE':
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: WAColors.cardLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
              child: Icon(Icons.image_rounded,
                  color: WAColors.textMuted, size: 32)),
        );
      case 'VIDEO':
        return Container(
          height: 80,
          decoration: BoxDecoration(
              color: WAColors.cardLight,
              borderRadius: BorderRadius.circular(8)),
          child: const Center(
              child: Icon(Icons.play_circle_rounded,
                  color: WAColors.textMuted, size: 32)),
        );
      case 'AUDIO':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: WAColors.cardLight,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.audiotrack_rounded, color: WAColors.textMuted, size: 18),
            SizedBox(width: 8),
            Text('Audio adjunto',
                style: TextStyle(color: WAColors.textMuted, fontSize: 12)),
          ]),
        );
      case 'DOCUMENT':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: WAColors.cardLight,
              borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.attach_file_rounded,
                color: WAColors.textMuted, size: 18),
            SizedBox(width: 8),
            Text('Documento adjunto',
                style: TextStyle(color: WAColors.textMuted, fontSize: 12)),
          ]),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ══════════════════════════════════════════════════════════
// PANEL CONSTRUCTOR DE PLANTILLA
// ══════════════════════════════════════════════════════════
class _TemplateBuilderPanel extends StatefulWidget {
  final String botId;
  final VoidCallback onSaved;
  const _TemplateBuilderPanel({required this.botId, required this.onSaved});

  @override
  State<_TemplateBuilderPanel> createState() => _TemplateBuilderPanelState();
}

class _TemplateBuilderPanelState extends State<_TemplateBuilderPanel> {
  final _nameCtrl = TextEditingController();
  final _headerTextCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  String _category = 'MARKETING';
  String _headerType = 'NONE';
  bool _saving = false;
  List<Map<String, dynamic>> _buttons = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headerTextCtrl.dispose();
    _bodyCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  List<String> _extractVars(String body) {
    final rx = RegExp(r'\{\{(\d+)\}\}');
    return rx.allMatches(body).map((m) => m.group(1)!).toSet().toList()..sort();
  }

  void _insertVar() {
    final vars = _extractVars(_bodyCtrl.text);
    final next = (vars.isEmpty ? 1 : int.parse(vars.last) + 1).toString();
    final cursor = _bodyCtrl.selection.baseOffset;
    final text = _bodyCtrl.text;
    final pos = cursor < 0 ? text.length : cursor;
    _bodyCtrl.value = TextEditingValue(
      text: '${text.substring(0, pos)}{{$next}}${text.substring(pos)}',
      selection: TextSelection.collapsed(offset: pos + next.length + 4),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y cuerpo son requeridos')));
      return;
    }
    setState(() => _saving = true);

    // Llamar al service con datos ricos
    // ignore: use_build_context_synchronously
    final svc =
        context.findAncestorStateOfType<_MassSendViewState>()?.widget.service;
    if (svc != null) {
      await svc.saveTemplateRich(
        botId: widget.botId,
        name: _nameCtrl.text.trim(),
        category: _category,
        headerType: _headerType,
        headerText: _headerTextCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        footer: _footerCtrl.text.trim(),
        buttons: _buttons,
        bodyVariables: _extractVars(_bodyCtrl.text),
      );
    }

    setState(() => _saving = false);
    _nameCtrl.clear();
    _headerTextCtrl.clear();
    _bodyCtrl.clear();
    _footerCtrl.clear();
    setState(() {
      _buttons = [];
      _headerType = 'NONE';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Plantilla guardada'), backgroundColor: WAColors.green));
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nueva Plantilla',
              style: TextStyle(
                  color: WAColors.textPri,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 14),

          // Nombre
          _PanelLabel('Nombre de plantilla *'),
          const SizedBox(height: 5),
          _PanelInput(_nameCtrl, 'ej: promo_verano_2025'),
          const SizedBox(height: 12),

          // Categoría
          _PanelLabel('Categoría'),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: WAColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WAColors.border),
            ),
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: WAColors.card,
              style: const TextStyle(color: WAColors.textPri, fontSize: 13),
              items: const [
                DropdownMenuItem(
                    value: 'MARKETING', child: Text('🎯 Marketing')),
                DropdownMenuItem(value: 'UTILITY', child: Text('🔧 Utilidad')),
                DropdownMenuItem(
                    value: 'AUTHENTICATION', child: Text('🔐 Autenticación')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'MARKETING'),
            ),
          ),
          const SizedBox(height: 12),

          // Tipo de encabezado
          _PanelLabel('Encabezado'),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...['NONE', 'TEXT', 'IMAGE', 'VIDEO', 'AUDIO', 'DOCUMENT']
                  .map((t) {
                final icons = {
                  'NONE': Icons.block,
                  'TEXT': Icons.title,
                  'IMAGE': Icons.image,
                  'VIDEO': Icons.videocam,
                  'AUDIO': Icons.audiotrack,
                  'DOCUMENT': Icons.attach_file,
                };
                final labels = {
                  'NONE': 'Ninguno',
                  'TEXT': 'Texto',
                  'IMAGE': 'Imagen',
                  'VIDEO': 'Video',
                  'AUDIO': 'Audio',
                  'DOCUMENT': 'Doc',
                };
                final sel = _headerType == t;
                return InkWell(
                  onTap: () => setState(() => _headerType = t),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          sel ? WAColors.accent.withOpacity(0.15) : WAColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel ? WAColors.accent : WAColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[t]!,
                            size: 13,
                            color: sel ? WAColors.accent : WAColors.textMuted),
                        const SizedBox(width: 4),
                        Text(labels[t]!,
                            style: TextStyle(
                                color:
                                    sel ? WAColors.accent : WAColors.textMuted,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          if (_headerType == 'TEXT') ...[
            const SizedBox(height: 8),
            _PanelInput(_headerTextCtrl, 'Texto del encabezado'),
          ],
          if (['IMAGE', 'VIDEO', 'AUDIO', 'DOCUMENT']
              .contains(_headerType)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WAColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: WAColors.info, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'La URL del medio se especificará al enviar desde la API de Meta.',
                      style:
                          const TextStyle(color: WAColors.info, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Cuerpo
          Row(
            children: [
              const Expanded(
                child: Text('Cuerpo del mensaje *',
                    style: TextStyle(
                        color: WAColors.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              InkWell(
                onTap: _insertVar,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WAColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WAColors.accent.withOpacity(0.3)),
                  ),
                  child: const Text('+ Variable',
                      style: TextStyle(
                          color: WAColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _bodyCtrl,
            maxLines: 5,
            style: const TextStyle(color: WAColors.textPri, fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Hola {{1}}, tenemos una oferta especial para ti en {{2}}...',
              hintStyle:
                  const TextStyle(color: WAColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: WAColors.bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: WAColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: WAColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: WAColors.accent)),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          // Formato rápido
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              _SmallFormatBtn('*negrita*', () => _insertBodyFormat('*')),
              _SmallFormatBtn('_cursiva_', () => _insertBodyFormat('_')),
              _SmallFormatBtn('~tachado~', () => _insertBodyFormat('~')),
              _SmallFormatBtn('emoji 😊', () {
                final pos = _bodyCtrl.selection.baseOffset;
                final t = _bodyCtrl.text;
                final p = pos < 0 ? t.length : pos;
                _bodyCtrl.value = TextEditingValue(
                  text: '${t.substring(0, p)}😊${t.substring(p)}',
                  selection: TextSelection.collapsed(offset: p + 2),
                );
              }),
            ],
          ),
          // Variables detectadas
          if (_extractVars(_bodyCtrl.text).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WAColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.data_object_rounded,
                      color: WAColors.accent, size: 12),
                  const SizedBox(width: 6),
                  Wrap(
                    spacing: 4,
                    children: _extractVars(_bodyCtrl.text)
                        .map((v) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: WAColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('{{$v}}',
                                  style: const TextStyle(
                                      color: WAColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Footer
          _PanelLabel('Pie de página (opcional)'),
          const SizedBox(height: 5),
          _PanelInput(_footerCtrl, 'ej: Responde STOP para darte de baja'),
          const SizedBox(height: 12),

          // Botones
          Row(
            children: [
              const Expanded(
                  child: Text('Botones (opcional)',
                      style: TextStyle(
                          color: WAColors.textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
              if (_buttons.length < 3)
                InkWell(
                  onTap: () => setState(
                      () => _buttons.add({'type': 'QUICK_REPLY', 'text': ''})),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: WAColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('+ Botón',
                        style: TextStyle(
                            color: WAColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ..._buttons.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: WAColors.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WAColors.border),
                      ),
                      child: DropdownButton<String>(
                        value: e.value['type'],
                        underline: const SizedBox(),
                        dropdownColor: WAColors.card,
                        style: const TextStyle(
                            color: WAColors.textSec, fontSize: 11),
                        items: const [
                          DropdownMenuItem(
                              value: 'QUICK_REPLY', child: Text('Respuesta')),
                          DropdownMenuItem(value: 'URL', child: Text('URL')),
                          DropdownMenuItem(
                              value: 'PHONE', child: Text('Llamar')),
                        ],
                        onChanged: (v) =>
                            setState(() => _buttons[e.key]['type'] = v!),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                            color: WAColors.textPri, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Texto del botón',
                          hintStyle: const TextStyle(
                              color: WAColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: WAColors.bg,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: WAColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: WAColors.border)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                        onChanged: (v) => _buttons[e.key]['text'] = v,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _buttons.removeAt(e.key)),
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: WAColors.error, size: 16),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),

          // Info Meta
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WAColors.info.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.facebook, color: WAColors.info, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Esta plantilla se enviará a Meta para revisión. El proceso puede tomar 24-48h. Usa "Sync Meta" para actualizar el estado.',
                    style: TextStyle(
                        color: WAColors.info, fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: WAColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 14),
                        SizedBox(width: 6),
                        Text('Guardar y enviar a Meta',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _insertBodyFormat(String marker) {
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (sel.isValid && sel.start != sel.end) {
      final selected = text.substring(sel.start, sel.end);
      _bodyCtrl.value = TextEditingValue(
        text: text.replaceRange(sel.start, sel.end, '$marker$selected$marker'),
        selection: TextSelection.collapsed(
            offset:
                sel.start + marker.length + selected.length + marker.length),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET: ITEM DE PLANTILLA EN LISTA
// ══════════════════════════════════════════════════════════
class _TemplateListItem extends StatelessWidget {
  final WATemplate template;
  final VoidCallback onDelete;
  final VoidCallback onSync;

  const _TemplateListItem(
      {required this.template, required this.onDelete, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: template.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: template.statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(template.statusIcon,
                    color: template.statusColor, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(template.name,
                      style: const TextStyle(
                          color: WAColors.textPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                // Badge estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: template.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(template.statusLabel,
                      style: TextStyle(
                          color: template.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: WAColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(template.category,
                      style: const TextStyle(
                          color: WAColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                InkWell(
                    onTap: onSync,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.sync_rounded,
                            color: WAColors.info, size: 14))),
                InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            color: WAColors.error, size: 14))),
              ],
            ),
          ),
          // Cuerpo
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.headerType != 'NONE') ...[
                  _HeaderTypeBadge(type: template.headerType),
                  const SizedBox(height: 6),
                ],
                Text(template.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: WAColors.textSec, fontSize: 12, height: 1.4)),
                if (template.footer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(template.footer,
                      style: const TextStyle(
                          color: WAColors.textMuted, fontSize: 11)),
                ],
                if (template.buttons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: template.buttons
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: WAColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: WAColors.info.withOpacity(0.3)),
                              ),
                              child: Text(b['text'] ?? '',
                                  style: const TextStyle(
                                      color: WAColors.info, fontSize: 10)),
                            ))
                        .toList(),
                  ),
                ],
                if (template.status == 'REJECTED' &&
                    template.rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WAColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: WAColors.error, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Motivo: ${template.rejectionReason}',
                              style: const TextStyle(
                                  color: WAColors.error, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTypeBadge extends StatelessWidget {
  final String type;
  const _HeaderTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (type) {
      'TEXT' => (Icons.title, 'Texto', WAColors.textSec),
      'IMAGE' => (Icons.image_rounded, 'Imagen', WAColors.info),
      'VIDEO' => (Icons.videocam_rounded, 'Video', WAColors.accent),
      'AUDIO' => (Icons.audiotrack_rounded, 'Audio', WAColors.warning),
      'DOCUMENT' => (Icons.attach_file_rounded, 'Documento', WAColors.human),
      _ => (Icons.help_outline, type, WAColors.textMuted),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text('Encabezado: $label',
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET: CARD DE HISTORIAL
// ══════════════════════════════════════════════════════════
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onExpand;

  const _HistoryCard({required this.record, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final sent = record['sent'] ?? 0;
    final failed = record['failed'] ?? 0;
    final total = record['total'] ?? 0;
    final pct = total > 0 ? (sent / total * 100).toStringAsFixed(0) : '0';
    final date = record['createdAt'] != null
        ? DateFormat('dd/MM/yy HH:mm').format(
            DateTime.tryParse(record['createdAt'].toString()) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WAColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send_rounded,
                        color: WAColors.green, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record['message'] != null
                            ? (record['message'] as String).length > 70
                                ? '${(record['message'] as String).substring(0, 70)}...'
                                : record['message']
                            : 'Envío masivo',
                        style: const TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    Text(date,
                        style: const TextStyle(
                            color: WAColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? sent / total : 0,
                    backgroundColor: WAColors.error.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(WAColors.green),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniChip('$pct% éxito', WAColors.green),
                    const SizedBox(width: 6),
                    _MiniChip('$sent enviados', WAColors.info),
                    const SizedBox(width: 6),
                    if (failed > 0)
                      _MiniChip('$failed fallidos', WAColors.error),
                    const Spacer(),
                    InkWell(
                      onTap: onExpand,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WAColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: WAColors.accent.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ver detalle',
                                style: TextStyle(
                                    color: WAColors.accent, fontSize: 11)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: WAColors.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════
class _PanelLabel extends StatelessWidget {
  final String text;
  const _PanelLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: WAColors.textSec, fontSize: 12, fontWeight: FontWeight.w500));
}

class _PanelInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _PanelInput(this.ctrl, this.hint, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: WAColors.textPri, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: WAColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: WAColors.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WAColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WAColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: WAColors.accent)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      );
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool italic;
  final bool mono;
  const _FormatBtn(
      {required this.label,
      required this.onTap,
      this.italic = false,
      this.mono = false});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.only(right: 4, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: WAColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: TextStyle(
                  color: WAColors.textSec,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  fontFamily: mono ? 'monospace' : null)),
        ),
      );
}

class _SmallFormatBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallFormatBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.only(right: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: WAColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(color: WAColors.textMuted, fontSize: 10)),
        ),
      );
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _StatusFilterChip(
      {required this.label, required this.color, required this.count});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}
