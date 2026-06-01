import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatCard(
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

class BotCard extends StatelessWidget {
  final WAChatbot bot;
  final VoidCallback onTap;
  const BotCard({required this.bot, required this.onTap});

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

class BotListTile extends StatelessWidget {
  final WAChatbot bot;
  final WAService service;
  final VoidCallback onRefresh;
  final VoidCallback onTap;
  const BotListTile(
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
                ActionButton(
                  icon: bot.isActive ? Icons.pause_circle : Icons.play_circle,
                  label: bot.isActive ? 'Pausar IA' : 'Activar IA',
                  color: bot.isActive ? WAColors.warning : WAColors.green,
                  onTap: () async {
                    await service.toggleAI(bot.id);
                    onRefresh();
                  },
                ),
                const SizedBox(width: 6),
                ActionButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: 'Ver',
                  onTap: onTap,
                ),
                const SizedBox(width: 6),
                ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar',
                  color: WAColors.error,
                  onTap: () => confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void confirmDelete(BuildContext context) {
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
class DashboardView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  final Function(WAChatbot) onSelectBot;
  const DashboardView(
      {required this.service,
      required this.bots,
      required this.onSelectBot});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Panel de control de tus bots',
            icon: Icons.dashboard_rounded,
            iconColor: WAColors.green,
            actions: [
              HeaderBtn(
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
                            StatCard(
                              label: 'Total Bots',
                              value:
                                  '${_dashboard?['totalBots'] ?? widget.bots.length}',
                              icon: Icons.smart_toy_rounded,
                              color: WAColors.accent,
                            ),
                            const SizedBox(width: 16),
                            StatCard(
                              label: 'Bots Activos',
                              value:
                                  '${_dashboard?['activeBots'] ?? widget.bots.where((b) => b.isActive).length}',
                              icon: Icons.check_circle_rounded,
                              color: WAColors.green,
                            ),
                            const SizedBox(width: 16),
                            StatCard(
                              label: 'Conversaciones',
                              value:
                                  '${_dashboard?['totalConversations'] ?? 0}',
                              icon: Icons.chat_bubble_rounded,
                              color: WAColors.info,
                            ),
                            const SizedBox(width: 16),
                            StatCard(
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
                          EmptyState(
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
                            itemBuilder: (_, i) => BotCard(
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