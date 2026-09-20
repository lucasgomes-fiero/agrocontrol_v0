import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/bi_models.dart';
import '../models/farm.dart';
import '../services/bi_service.dart';
import '../widgets/brand.dart';

class ReportsScreen extends StatefulWidget {
  final Farm farm;
  const ReportsScreen({super.key, required this.farm});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  BiSnapshot? _bi;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bi = await BiService().load(widget.farm.id);
      if (!mounted) return;
      setState(() {
        _bi = bi;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar o BI: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              const AgroWordmark(height: 46),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BI do rebanho', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Indicadores para decisão', style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_bi == null)
                const EmptyCard(
                  icon: Icons.analytics_outlined,
                  title: 'BI indisponível',
                  message: 'Atualize a tela para tentar novamente.',
                )
              else ...[
                _DecisionBanner(bi: _bi!),
                const SizedBox(height: 14),
                _KpiStrip(bi: _bi!),
                const SizedBox(height: 22),
                const SectionTitle('Evolução do peso médio'),
                const SizedBox(height: 10),
                _WeightChart(points: _bi!.weightSeries),
                const SizedBox(height: 22),
                const SectionTitle('Distribuição por categoria'),
                const SizedBox(height: 10),
                _CategoryChart(items: _bi!.categories),
                const SizedBox(height: 22),
                const SectionTitle('Desempenho por lote'),
                const SizedBox(height: 10),
                _LotTable(items: _bi!.lots),
                const SizedBox(height: 22),
                const SectionTitle('Leituras para decisão'),
                const SizedBox(height: 10),
                _Insights(bi: _bi!),
              ],
            ],
          ),
        ),
      );
}

class _DecisionBanner extends StatelessWidget {
  final BiSnapshot bi;
  const _DecisionBanner({required this.bi});

  @override
  Widget build(BuildContext context) {
    final treatmentRate = bi.stats.animals == 0 ? 0 : (bi.stats.treatment / bi.stats.animals * 100);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.forest, Color(0xFF357A4C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, color: Colors.white, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pulso da fazenda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(
                  bi.stats.animals == 0
                      ? 'Cadastre animais e medições para liberar análises.'
                      : '${bi.stats.active} ativos • ${treatmentRate.toStringAsFixed(1).replaceAll('.', ',')}% em tratamento • ${bi.stats.vaccinesDue} vacina(s) próximas.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .84), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final BiSnapshot bi;
  const _KpiStrip({required this.bi});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Kpi(label: 'Rebanho', value: '${bi.stats.animals}', icon: Icons.agriculture, color: AppColors.plantingGreen),
            _Kpi(label: 'Peso médio', value: AppFormatters.weight(bi.stats.avgWeight), icon: Icons.monitor_weight_outlined, color: AppColors.sky),
            _Kpi(label: 'Pesagens/mês', value: '${bi.stats.weighingsMonth}', icon: Icons.query_stats, color: AppColors.warning),
            _Kpi(label: 'Saúde/mês', value: '${bi.stats.healthMonth}', icon: Icons.health_and_safety_outlined, color: AppColors.earth),
            _Kpi(label: 'Vacinas 30d', value: '${bi.stats.vaccinesDue}', icon: Icons.vaccines_outlined, color: AppColors.forest),
          ],
        ),
      );
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 155,
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 9),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ],
        ),
      );
}

class _WeightChart extends StatelessWidget {
  final List<WeightPoint> points;
  const _WeightChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyCard(
        icon: Icons.show_chart,
        title: 'Sem histórico de peso',
        message: 'Registre pesagens para acompanhar a tendência mensal.',
      );
    }
    final maxY = points.map((e) => e.average).reduce((a, b) => a > b ? a : b);
    final minY = points.map((e) => e.average).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY).abs() < 10 ? 15.0 : (maxY - minY) * .18;
    return Card(
      child: SizedBox(
        height: 280,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 22, 18, 10),
          child: LineChart(
            LineChartData(
              minY: (minY - padding).clamp(0, double.infinity),
              maxY: maxY + padding,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.darkGreen.withValues(alpha: .08), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, _) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.round();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(AppFormatters.month(points[i].month), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].average)),
                  isCurved: true,
                  color: AppColors.plantingGreen,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: AppColors.plantingGreen.withValues(alpha: .10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<CategoryMetric> items;
  const _CategoryChart({required this.items});

  static const colors = [
    AppColors.darkGreen,
    AppColors.plantingGreen,
    AppColors.earth,
    AppColors.sky,
    AppColors.warning,
    AppColors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyCard(icon: Icons.pie_chart_outline, title: 'Sem categorias', message: 'Cadastre animais para visualizar a composição do rebanho.');
    }
    final total = items.fold<int>(0, (sum, e) => sum + e.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 37,
                  sectionsSpace: 2,
                  sections: List.generate(items.length, (i) {
                    final item = items[i];
                    return PieChartSectionData(
                      value: item.total.toDouble(),
                      color: colors[i % colors.length],
                      radius: 48,
                      title: total == 0 ? '' : '${(item.total / total * 100).round()}%',
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                        Text('${item.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LotTable extends StatelessWidget {
  final List<LotMetric> items;
  const _LotTable({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyCard(icon: Icons.grid_view_outlined, title: 'Sem lotes', message: 'Informe o lote dos animais para comparar desempenho.');
    }
    final max = items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.take(8).map((item) {
            final progress = max == 0 ? 0.0 : item.total / max;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Text('${item.total} animais', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 74,
                        child: Text(
                          item.averageWeight > 0 ? AppFormatters.weight(item.averageWeight) : '—',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: AppColors.lightGreen,
                    color: AppColors.plantingGreen,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  final BiSnapshot bi;
  const _Insights({required this.bi});

  @override
  Widget build(BuildContext context) {
    final insights = <_Insight>[];
    if (bi.stats.animals == 0) {
      insights.add(const _Insight(Icons.add_circle_outline, AppColors.plantingGreen, 'Cadastre o rebanho', 'O BI será preenchido conforme os registros da fazenda.'));
    } else {
      if (bi.stats.treatment > 0) {
        insights.add(_Insight(Icons.healing_outlined, AppColors.earth, 'Acompanhar tratamentos', '${bi.stats.treatment} animal(is) estão marcados como em tratamento.'));
      }
      if (bi.stats.vaccinesDue > 0) {
        insights.add(_Insight(Icons.vaccines_outlined, AppColors.warning, 'Planejar vacinação', '${bi.stats.vaccinesDue} reforço(s) ou dose(s) vencem nos próximos 30 dias.'));
      }
      if (bi.stats.weighingsMonth == 0) {
        insights.add(const _Insight(Icons.monitor_weight_outlined, AppColors.sky, 'Atualizar pesagens', 'Não há pesagens registradas neste mês; a tendência de ganho pode ficar desatualizada.'));
      }
      if (bi.weightSeries.length >= 2) {
        final delta = bi.weightSeries.last.average - bi.weightSeries[bi.weightSeries.length - 2].average;
        insights.add(_Insight(
          delta >= 0 ? Icons.trending_up : Icons.trending_down,
          delta >= 0 ? AppColors.plantingGreen : AppColors.earth,
          'Tendência de peso',
          'O peso médio mensal variou ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1).replaceAll('.', ',')} kg no último período com dados.',
        ));
      }
    }
    return Column(
      children: insights.map((i) => Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: i.color.withValues(alpha: .12), child: Icon(i.icon, color: i.color)),
              title: Text(i.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(i.text),
            ),
          )).toList(),
    );
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _Insight(this.icon, this.color, this.title, this.text);
}
