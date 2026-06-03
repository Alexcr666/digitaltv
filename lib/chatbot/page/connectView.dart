
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
                                  ConnectionStatusCard(
                                    label: 'Total Bots',
                                    value: '${widget.bots.length}',
                                    icon: Icons.smart_toy_rounded,
                                    color: WAColors.accent,
                                    sublabel: 'registrados',
                                  ),
                                  const SizedBox(width: 16),
                                  ConnectionStatusCard(
                                    label: 'Conectados',
                                    value: '${activeBots.length}',
                                    icon: Icons.check_circle_rounded,
                                    color: WAColors.green,
                                    sublabel: 'activos',
                                  ),
                                  const SizedBox(width: 16),
                                  ConnectionStatusCard(
                                    label: 'Desconectados',
                                    value: '${inactiveBots.length}',
                                    icon: Icons.cancel_rounded,
                                    color: WAColors.error,
                                    sublabel: 'inactivos',
                                  ),
                                  const SizedBox(width: 16),
                                  ConnectionStatusCard(
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
