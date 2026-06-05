import 'package:digitaltv/chatbot/color.dart';
import 'package:digitaltv/chatbot/models/waConversations.dart';
import 'package:digitaltv/chatbot/page/widget.dart';
import 'package:digitaltv/chatbot/service/service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TokenUsageView extends StatefulWidget {
  final WAService service;
  final List<WAChatbot> bots;
  const TokenUsageView({required this.service, required this.bots});
  @override
  State<TokenUsageView> createState() => _TokenUsageViewState();
}

class _TokenUsageViewState extends State<TokenUsageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _usage;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  // Filtros
  String _period = '7d';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _botFilter = 'all';
  String _modelFilter = 'all';

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
    final params = <String, String>{'period': _period};
    if (_dateFrom != null)
      params['from'] = DateFormat('yyyy-MM-dd').format(_dateFrom!);
    if (_dateTo != null)
      params['to'] = DateFormat('yyyy-MM-dd').format(_dateTo!);
    if (_botFilter != 'all') params['botId'] = _botFilter;

    final result = await widget.service.getTokenUsageAdvanced(params);
    setState(() {
      _usage = result;
      _history = List<Map<String, dynamic>>.from(result?['daily'] ?? []);
      _loading = false;
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: WAColors.warning,
            surface: WAColors.card,
            onSurface: WAColors.textPri,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _dateFrom = picked;
        else
          _dateTo = picked;
        _period = 'custom';
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Container(
            color: WAColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: WAColors.warning,
              unselectedLabelColor: WAColors.textMuted,
              indicatorColor: WAColors.warning,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                    icon: Icon(Icons.bar_chart_rounded, size: 15),
                    text: 'Resumen'),
                Tab(
                    icon: Icon(Icons.show_chart_rounded, size: 15),
                    text: 'Gráficas'),
                Tab(
                    icon: Icon(Icons.table_rows_rounded, size: 15),
                    text: 'Detalle'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: WAColors.warning))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildChartsTab(),
                      _buildDetailTab(),
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
              color: WAColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.token_rounded,
                color: WAColors.warning, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Uso de Tokens',
                  style: TextStyle(
                      color: WAColors.textPri,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              Text('Consumo de IA por interacciones',
                  style: TextStyle(color: WAColors.textMuted, fontSize: 12)),
            ],
          ),
          const Spacer(),
          HeaderBtn(icon: Icons.refresh, label: 'Actualizar', onTap: _load),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: WAColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Periodos rápidos
            ...['1d', '7d', '30d'].map((p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _period = p;
                        _dateFrom = null;
                        _dateTo = null;
                      });
                      _load();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _period == p ? WAColors.warning : WAColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _period == p
                                ? WAColors.warning
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
            const SizedBox(width: 8),
            // Fecha desde
            _DateFilterBtn(
              label: _dateFrom != null
                  ? DateFormat('dd/MM/yy').format(_dateFrom!)
                  : 'Desde',
              active: _dateFrom != null,
              color: WAColors.warning,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(width: 6),
            _DateFilterBtn(
              label: _dateTo != null
                  ? DateFormat('dd/MM/yy').format(_dateTo!)
                  : 'Hasta',
              active: _dateTo != null,
              color: WAColors.warning,
              onTap: () => _pickDate(false),
            ),
            if (_dateFrom != null || _dateTo != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                    _period = '7d';
                  });
                  _load();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: WAColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: WAColors.error),
                ),
              ),
            ],
            const SizedBox(width: 12),
            // Filtro por bot
            if (widget.bots.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: WAColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WAColors.border),
                ),
                child: DropdownButton<String>(
                  value: _botFilter,
                  underline: const SizedBox(),
                  dropdownColor: WAColors.card,
                  style: const TextStyle(color: WAColors.textPri, fontSize: 12),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('Todos los bots')),
                    ...widget.bots.map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name))),
                  ],
                  onChanged: (v) {
                    setState(() => _botFilter = v ?? 'all');
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Filtro por modelo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: WAColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WAColors.border),
              ),
              child: DropdownButton<String>(
                value: _modelFilter,
                underline: const SizedBox(),
                dropdownColor: WAColors.card,
                style: const TextStyle(color: WAColors.textPri, fontSize: 12),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Todos los modelos')),
                  DropdownMenuItem(
                      value: 'gpt-4o-mini', child: Text('GPT-4o Mini')),
                  DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
                  DropdownMenuItem(
                      value: 'gpt-3.5-turbo', child: Text('GPT-3.5 Turbo')),
                ],
                onChanged: (v) => setState(() => _modelFilter = v ?? 'all'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB: RESUMEN
  // ══════════════════════════════════════════════════════
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards resumen
          Row(
            children: [
              _TokenCard(
                label: 'Tokens totales',
                value: _fmt(_usage?['totalTokens'] ?? 0),
                icon: Icons.token_rounded,
                color: WAColors.warning,
                sub: 'en el período',
              ),
              const SizedBox(width: 12),
              _TokenCard(
                label: 'Tokens entrada',
                value: _fmt(_usage?['promptTokens'] ?? 0),
                icon: Icons.input_rounded,
                color: WAColors.info,
                sub:
                    '${_pct(_usage?['promptTokens'], _usage?['totalTokens'])}% del total',
              ),
              const SizedBox(width: 12),
              _TokenCard(
                label: 'Tokens salida',
                value: _fmt(_usage?['completionTokens'] ?? 0),
                icon: Icons.output_rounded,
                color: WAColors.accent,
                sub:
                    '${_pct(_usage?['completionTokens'], _usage?['totalTokens'])}% del total',
              ),
              const SizedBox(width: 12),
              _TokenCard(
                label: 'Costo estimado',
                value:
                    '\$${(_usage?['estimatedCost'] ?? 0.0).toStringAsFixed(4)}',
                icon: Icons.attach_money_rounded,
                color: WAColors.green,
                sub: 'USD aproximado',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TokenCard(
                label: 'Total llamadas',
                value: '${_usage?['totalCalls'] ?? 0}',
                icon: Icons.api_rounded,
                color: WAColors.human,
                sub: 'requests a OpenAI',
              ),
              const SizedBox(width: 12),
              _TokenCard(
                label: 'Promedio/llamada',
                value:
                    _usage?['totalCalls'] != null && _usage!['totalCalls'] > 0
                        ? _fmt((_usage!['totalTokens'] / _usage!['totalCalls'])
                            .round())
                        : '0',
                icon: Icons.analytics_rounded,
                color: WAColors.accent,
                sub: 'tokens por request',
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 20),
          // Por bot
          const Text('Consumo por bot',
              style: TextStyle(
                  color: WAColors.textPri,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_usage?['byBot'] != null)
            ...(_usage!['byBot'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((b) => _BotUsageCard(data: b)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB: GRÁFICAS
  // ══════════════════════════════════════════════════════
  Widget _buildChartsTab() {
    if (_history.isEmpty) {
      return const Center(
          child: Text('Sin datos para graficar',
              style: TextStyle(color: WAColors.textMuted)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gráfica tokens por día
          WACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.show_chart_rounded,
                        color: WAColors.warning, size: 16),
                    SizedBox(width: 8),
                    Text('Tokens consumidos por día',
                        style: TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: 200, child: _buildTokensLineChart()),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                        color: WAColors.warning, label: 'Tokens totales'),
                    const SizedBox(width: 16),
                    _LegendDot(color: WAColors.info, label: 'Tokens entrada'),
                    const SizedBox(width: 16),
                    _LegendDot(color: WAColors.accent, label: 'Tokens salida'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Gráfica llamadas por día
          WACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: WAColors.accent, size: 16),
                    SizedBox(width: 8),
                    Text('Llamadas a la API por día',
                        style: TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: 180, child: _buildCallsBarChart()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Gráfica costo por día
          WACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.attach_money_rounded,
                        color: WAColors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Costo estimado por día (USD)',
                        style: TextStyle(
                            color: WAColors.textPri,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: 180, child: _buildCostLineChart()),
              ],
            ),
          ),
          // Gráfica por bot (si hay datos)
          if (_usage?['byBot'] != null &&
              (_usage!['byBot'] as List).length > 1) ...[
            const SizedBox(height: 16),
            WACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_rounded,
                          color: WAColors.human, size: 16),
                      SizedBox(width: 8),
                      Text('Distribución por bot',
                          style: TextStyle(
                              color: WAColors.textPri,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildBotPieChart()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTokensLineChart() {
    final data = _history;
    if (data.isEmpty) return const SizedBox();
    final spots = data
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), (e.value['totalTokens'] ?? 0).toDouble()))
        .toList();
    final spotsIn = data
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), (e.value['promptTokens'] ?? 0).toDouble()))
        .toList();
    final spotsOut = data
        .asMap()
        .entries
        .map((e) => FlSpot(
            e.key.toDouble(), (e.value['completionTokens'] ?? 0).toDouble()))
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
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text(_fmt(v.toInt()),
                style: const TextStyle(color: WAColors.textMuted, fontSize: 9)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              final date = data[idx]['date']?.toString() ?? '';
              return Text(date.length >= 10 ? date.substring(5) : date,
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 9));
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _lineBar(spots, WAColors.warning, 2.5),
        _lineBar(spotsIn, WAColors.info, 1.5),
        _lineBar(spotsOut, WAColors.accent, 1.5),
      ],
    ));
  }

  Widget _buildCallsBarChart() {
    final data = _history;
    if (data.isEmpty) return const SizedBox();
    final bars = data
        .asMap()
        .entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['calls'] ?? 0).toDouble(),
                  color: WAColors.accent,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (data
                            .map((d) => (d['calls'] ?? 0) as num)
                            .reduce((a, b) => a > b ? a : b)).toDouble() +
                        1,
                    color: WAColors.border,
                  ),
                ),
              ],
            ))
        .toList();

    return BarChart(BarChartData(
      barGroups: bars,
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
            reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: const TextStyle(color: WAColors.textMuted, fontSize: 9)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              final date = data[idx]['date']?.toString() ?? '';
              return Text(date.length >= 10 ? date.substring(5) : date,
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 9));
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} llamadas',
            const TextStyle(color: WAColors.textPri, fontSize: 11),
          ),
        ),
      ),
    ));
  }

  Widget _buildCostLineChart() {
    final data = _history;
    if (data.isEmpty) return const SizedBox();
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(),
            ((e.value['estimatedCost'] ?? 0.0) as num).toDouble()))
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
            reservedSize: 48,
            getTitlesWidget: (v, _) => Text('\$${v.toStringAsFixed(4)}',
                style: const TextStyle(color: WAColors.textMuted, fontSize: 8)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              final date = data[idx]['date']?.toString() ?? '';
              return Text(date.length >= 10 ? date.substring(5) : date,
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 9));
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [_lineBar(spots, WAColors.green, 2.5)],
    ));
  }

  Widget _buildBotPieChart() {
    final byBot =
        (_usage!['byBot'] as List<dynamic>).cast<Map<String, dynamic>>();
    final total = byBot.fold<num>(0, (s, b) => s + (b['totalTokens'] ?? 0));
    final colors = [
      WAColors.warning,
      WAColors.accent,
      WAColors.info,
      WAColors.human,
      WAColors.green
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: byBot.asMap().entries.map((e) {
              final pct =
                  total > 0 ? (e.value['totalTokens'] ?? 0) / total * 100 : 0.0;
              return PieChartSectionData(
                color: colors[e.key % colors.length],
                value: (e.value['totalTokens'] ?? 0).toDouble(),
                title: '${pct.toStringAsFixed(1)}%',
                radius: 70,
                titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          )),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: byBot
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(e.value['botName'] ?? '',
                            style: const TextStyle(
                                color: WAColors.textSec, fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(_fmt(e.value['totalTokens'] ?? 0),
                            style: TextStyle(
                                color: colors[e.key % colors.length],
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color, double width) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: width,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.07)),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB: DETALLE
  // ══════════════════════════════════════════════════════
  Widget _buildDetailTab() {
    if (_history.isEmpty) {
      return const Center(
          child:
              Text('Sin datos', style: TextStyle(color: WAColors.textMuted)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: WACard(
        child: Column(
          children: [
            // Encabezado tabla
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: WAColors.border))),
              child: Row(
                children: [
                  const Expanded(
                      flex: 2,
                      child: Text('Fecha',
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  const Expanded(
                      child: Text('Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  const Expanded(
                      child: Text('Entrada',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  const Expanded(
                      child: Text('Salida',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  const Expanded(
                      child: Text('Llamadas',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  const Expanded(
                      child: Text('Costo USD',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: WAColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            ..._history.map((d) => Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: WAColors.border, width: 0.5))),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(d['date'] ?? '',
                              style: const TextStyle(
                                  color: WAColors.textSec, fontSize: 12))),
                      Expanded(
                          child: Text(_fmt(d['totalTokens'] ?? 0),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: WAColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12))),
                      Expanded(
                          child: Text(_fmt(d['promptTokens'] ?? 0),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: WAColors.info, fontSize: 12))),
                      Expanded(
                          child: Text(_fmt(d['completionTokens'] ?? 0),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: WAColors.accent, fontSize: 12))),
                      Expanded(
                          child: Text('${d['calls'] ?? 0}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: WAColors.human, fontSize: 12))),
                      Expanded(
                          child: Text(
                              '\$${((d['estimatedCost'] ?? 0.0) as num).toStringAsFixed(5)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: WAColors.green, fontSize: 12))),
                    ],
                  ),
                )),
            // Totales
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: WAColors.warning.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                      flex: 2,
                      child: Text('TOTAL',
                          style: TextStyle(
                              color: WAColors.textPri,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text(_fmt(_usage?['totalTokens'] ?? 0),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: WAColors.warning,
                              fontWeight: FontWeight.w800,
                              fontSize: 12))),
                  Expanded(
                      child: Text(_fmt(_usage?['promptTokens'] ?? 0),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: WAColors.info,
                              fontWeight: FontWeight.w700,
                              fontSize: 12))),
                  Expanded(
                      child: Text(_fmt(_usage?['completionTokens'] ?? 0),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: WAColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12))),
                  Expanded(
                      child: Text('${_usage?['totalCalls'] ?? 0}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: WAColors.human,
                              fontWeight: FontWeight.w700,
                              fontSize: 12))),
                  Expanded(
                      child: Text(
                          '\$${(_usage?['estimatedCost'] ?? 0.0).toStringAsFixed(4)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: WAColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic n) {
    final num v = n is num ? n : 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  String _pct(dynamic part, dynamic total) {
    if (part == null || total == null || total == 0) return '0';
    return ((part as num) / (total as num) * 100).toStringAsFixed(0);
  }
}

// ══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════
class _TokenCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _TokenCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.sub});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WAColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 11)),
              Text(sub,
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _BotUsageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BotUsageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WAColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WAColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WAColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: WAColors.warning, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['botName'] ?? '',
                    style: const TextStyle(
                        color: WAColors.textPri,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(data['model'] ?? '',
                    style: const TextStyle(
                        color: WAColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt(data['totalTokens'] ?? 0)} tokens',
                  style: const TextStyle(
                      color: WAColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Text(
                  '\$${((data['estimatedCost'] ?? 0.0) as num).toStringAsFixed(5)}',
                  style: const TextStyle(color: WAColors.green, fontSize: 12)),
              Text('${data['calls'] ?? 0} llamadas',
                  style:
                      const TextStyle(color: WAColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic n) {
    final num v = n is num ? n : 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _DateFilterBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _DateFilterBtn(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.12) : WAColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? color.withOpacity(0.4) : WAColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: active ? color : WAColors.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: active ? color : WAColors.textMuted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: WAColors.textMuted, fontSize: 11)),
        ],
      );
}
