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
import 'package:digitaltv/chatbot/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digitaltv/chatbot/page/widget.dart' as widget2;

class ConnectionView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  const ConnectionView({required this.service, required this.bots});

  @override
  State<ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<ConnectionView> {
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
    return SizedBox.expand(
      child: ColoredBox(
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
                HeaderBtn(
                    icon: Icons.refresh, label: 'Actualizar', onTap: _load),
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
                          WACard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.facebook,
                                        color: Color(0xFF1877F2), size: 22),
                                    SizedBox(width: 10),
                                    Text('Estado de Conexión Facebook',
                                        style: TextStyle(
                                            color: WAColors.textPri,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Flexible(
                                        child: ConnectionStatusCard(
                                      label: 'Total Bots',
                                      value: '${widget.bots.length}',
                                      icon: Icons.smart_toy_rounded,
                                      color: WAColors.accent,
                                      sublabel: 'registrados',
                                    )),
                                    const SizedBox(width: 16),
                                    Flexible(
                                        child: ConnectionStatusCard(
                                      label: 'Conectados',
                                      value: '${activeBots.length}',
                                      icon: Icons.check_circle_rounded,
                                      color: WAColors.green,
                                      sublabel: 'activos',
                                    )),
                                    const SizedBox(width: 16),
                                    Flexible(
                                        child: ConnectionStatusCard(
                                      label: 'Desconectados',
                                      value: '${inactiveBots.length}',
                                      icon: Icons.cancel_rounded,
                                      color: WAColors.error,
                                      sublabel: 'inactivos',
                                    )),
                                    const SizedBox(width: 16),
                                    Flexible(
                                        child: ConnectionStatusCard(
                                      label: 'Con Token',
                                      value:
                                          '${widget.bots.where((b) => b.accessToken.isNotEmpty).length}',
                                      icon: Icons.vpn_key_rounded,
                                      color: WAColors.warning,
                                      sublabel: 'configurados',
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Vinculación y Verificación por Empresa',
                              style: TextStyle(
                                  color: WAColors.textPri,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          ...widget.bots.map((bot) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _BotPhoneVerificationCard(
                                  bot: bot,
                                  service: widget.service,
                                ),
                              )),
                          const SizedBox(height: 20),
                          const Text('Detalle por Bot',
                              style: TextStyle(
                                  color: WAColors.textPri,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
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
                                              : WAColors.error
                                                  .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          bot.isActive
                                              ? Icons.link_rounded
                                              : Icons.link_off_rounded,
                                          color: bot.isActive
                                              ? WAColors.green
                                              : WAColors.error,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(bot.name,
                                                style: const TextStyle(
                                                    color: WAColors.textPri,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                              bot.phoneNumber.isNotEmpty
                                                  ? bot.phoneNumber
                                                  : 'Sin número configurado',
                                              style: const TextStyle(
                                                  color: WAColors.textMuted,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          StatusBadge(
                                              label: bot.isActive
                                                  ? 'Conectado'
                                                  : 'Desconectado',
                                              color: bot.isActive
                                                  ? WAColors.green
                                                  : WAColors.error),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                bot.accessToken.isNotEmpty
                                                    ? Icons.vpn_key
                                                    : Icons.vpn_key_off,
                                                size: 12,
                                                color:
                                                    bot.accessToken.isNotEmpty
                                                        ? WAColors.warning
                                                        : WAColors.textMuted,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                bot.accessToken.isNotEmpty
                                                    ? 'Token OK'
                                                    : 'Sin token',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: bot.accessToken
                                                            .isNotEmpty
                                                        ? WAColors.warning
                                                        : WAColors.textMuted),
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
                          WACard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.history_rounded,
                                        color: WAColors.accent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Resumen del Sistema',
                                        style: TextStyle(
                                            color: WAColors.textPri,
                                            fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}

class _BotPhoneVerificationCard extends StatefulWidget {
  final WAChatbot bot;
  final WAService service;
  const _BotPhoneVerificationCard({required this.bot, required this.service});
  @override
  State<_BotPhoneVerificationCard> createState() =>
      _BotPhoneVerificationCardState();
}

class _BotPhoneVerificationCardState extends State<_BotPhoneVerificationCard> {
  Map<String, dynamic>? _phoneStatus;
  bool _loading = false;
  bool _verifying = false;
  final _displayNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _displayNameCtrl.text = widget.bot.companyName;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final s = await widget.service.getPhoneStatus(widget.bot.id);
    setState(() {
      _phoneStatus = s;
      _loading = false;
    });
  }

  Future<void> _verify() async {
    if (_displayNameCtrl.text.trim().isEmpty) return;
    setState(() => _verifying = true);
    final result = await widget.service
        .verifyPhoneNumber(widget.bot.id, _displayNameCtrl.text.trim());
    setState(() => _verifying = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Solicitud enviada a Meta'),
          backgroundColor: WAColors.green));
      _loadStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Error al verificar'),
          backgroundColor: WAColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bot.phoneNumber.isEmpty && widget.bot.phoneNumberId.isEmpty) {
      return const SizedBox();
    }

    final verified = _phoneStatus?['verified'] == true;
    final displayName = _phoneStatus?['displayName'] ?? widget.bot.companyName;
    final quality = _phoneStatus?['quality'] ?? 'UNKNOWN';

    Color qualityColor = WAColors.textMuted;
    if (quality == 'GREEN') qualityColor = WAColors.green;
    if (quality == 'YELLOW') qualityColor = WAColors.warning;
    if (quality == 'RED') qualityColor = WAColors.error;

    return WACard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WAColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_rounded,
                    color: WAColors.info, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.bot.name,
                        style: const TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(
                        widget.bot.phoneNumber.isNotEmpty
                            ? widget.bot.phoneNumber
                            : 'Sin número',
                        style: const TextStyle(
                            color: WAColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: WAColors.info))
              else ...[
                StatusBadge(
                    label: verified ? 'Verificado' : 'Sin verificar',
                    color: verified ? WAColors.green : WAColors.warning),
                if (_phoneStatus != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: qualityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Calidad: $quality',
                        style: TextStyle(
                            color: qualityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: WAColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre para clientes (Meta)',
                        style: TextStyle(
                            color: WAColors.textSec,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _displayNameCtrl,
                      style: const TextStyle(
                          color: WAColors.textPri, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nombre de tu empresa',
                        hintStyle: const TextStyle(
                            color: WAColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: WAColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: WAColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: WAColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: WAColors.info),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WAColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Verificar en Meta',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
            ],
          ),
          if (displayName.isNotEmpty && _phoneStatus != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WAColors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WAColors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded,
                      size: 14, color: WAColors.green),
                  const SizedBox(width: 8),
                  Text('Nombre registrado: $displayName',
                      style:
                          const TextStyle(color: WAColors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
