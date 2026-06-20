import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../services/report.dart';

/// Layar Laporan: ringkasan bulanan + grafik komposisi aset, arus kas, kategori.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider).valueOrNull ?? const AppState();
    final summary = Report.forMonth(state.transactions, _month);
    final categories = Report.expenseByCategory(state.transactions, _month);
    final series = Report.lastMonths(state.transactions, _month, count: 6);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _MonthPicker(
            month: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
          const SizedBox(height: 12),
          _SummaryCard(summary: summary),
          const SizedBox(height: 16),
          Text('Arus Kas 6 Bulan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _CashFlowChart(series: series),
          const SizedBox(height: 24),
          Text('Komposisi Aset', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AssetPie(state: state),
          const SizedBox(height: 24),
          Text('Pengeluaran per Kategori',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _CategoryBreakdown(categories: categories, total: summary.expense),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              onChanged(DateTime(month.year, month.month - 1)),
        ),
        Text(Fmt.monthYear(month),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          // Jangan melampaui bulan berjalan.
          onPressed: isCurrentMonth
              ? null
              : () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _stat(context, 'Pemasukan', summary.income,
                      AppTheme.income, Icons.south_west),
                ),
                Expanded(
                  child: _stat(context, 'Pengeluaran', summary.expense,
                      AppTheme.expense, Icons.north_east),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selisih',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  Fmt.rupiahSigned(summary.net),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: summary.net >= 0
                          ? AppTheme.income
                          : AppTheme.expense,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, double value, Color color,
      IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 4),
        Text(Fmt.rupiah(value),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Bar chart pemasukan vs pengeluaran selama beberapa bulan.
class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.series});
  final List<MonthlySummary> series;

  @override
  Widget build(BuildContext context) {
    final maxVal = series.fold<double>(
        0,
        (m, s) => [m, s.income, s.expense]
            .reduce((a, b) => a > b ? a : b));
    if (maxVal == 0) {
      return const _ChartEmpty(text: 'Belum ada arus kas untuk ditampilkan.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    Fmt.rupiahCompact(rod.toY),
                    const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= series.length) {
                        return const SizedBox.shrink();
                      }
                      // Inisial bulan: J, F, M, ...
                      final m = series[i].month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(Fmt.monthYear(m).substring(0, 3),
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < series.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: series[i].income,
                      color: AppTheme.income,
                      width: 7,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2)),
                    ),
                    BarChartRodData(
                      toY: series[i].expense,
                      color: AppTheme.expense,
                      width: 7,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pie komposisi aset: kas, investasi, piutang.
class _AssetPie extends StatelessWidget {
  const _AssetPie({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final data = <(String, double, Color)>[
      ('Kas', state.totalCash, AppTheme.income),
      ('Investasi', state.totalInvestment, AppTheme.investment),
      ('Piutang', state.totalReceivable, Colors.teal),
    ].where((e) => e.$2 > 0).toList();

    if (data.isEmpty) {
      return const _ChartEmpty(text: 'Belum ada aset untuk ditampilkan.');
    }
    final total = data.fold<double>(0, (s, e) => s + e.$2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    for (final e in data)
                      PieChartSectionData(
                        value: e.$2,
                        color: e.$3,
                        title: '${(e.$2 / total * 100).round()}%',
                        radius: 28,
                        titleStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in data)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: e.$3,
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.$1)),
                          Text(Fmt.rupiahCompact(e.$2),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories, required this.total});
  final List<CategorySlice> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _ChartEmpty(text: 'Tidak ada pengeluaran di bulan ini.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final c in categories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.label),
                        Text(Fmt.rupiah(c.amount),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : c.amount / total,
                        minHeight: 6,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: AppTheme.expense,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ),
      ),
    );
  }
}
