

import 'dart:developer';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:digitaltv/chatbot/chatbot.dart';
import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/config.dart';
import 'package:digitaltv/chatbot/page/connectView.dart';
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

// ──────────────────────────────────────
// ─────────────────────────────────────────
// DIALOGO CREAR BOT
// ─────────────────────────────────────────
class CreateBotDialog extends StatefulWidget {
  final WAService service;
  final VoidCallback onCreated;
  const CreateBotDialog({required this.service, required this.onCreated});

  @override
  State<CreateBotDialog> createState() => _CreateBotDialogState();
}

class _CreateBotDialogState extends State<CreateBotDialog> {
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
// STATS VIEW
// ─────────────────────────────────────────


class StatsView extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onBack;
  const StatsView(
      {required this.bot, required this.service, required this.onBack});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
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

