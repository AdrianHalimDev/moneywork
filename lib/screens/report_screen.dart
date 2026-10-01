import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../services/export_service.dart';
import '../services/report.dart';
import '../widgets/responsive_layout.dart';

/// Layar Laporan: ringkasan bulanan + grafik komposisi aset, arus kas, kategori.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _showExportSheet(BuildContext context, AppState state,
      MonthlySummary summary, List<CategorySlice> categories) {
    DateTime selectedMonth = _month;
    String selectedFormat = 'pdf'; // 'pdf', 'xlsx', or 'xlsx_all'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(ctx)!.exportReportTitle,
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (selectedFormat != 'xlsx_all') ...[
                    Text(AppLocalizations.of(ctx)!.exportPeriodLabel, style: Theme.of(ctx).textTheme.titleSmall),
                    _MonthPicker(
                      month: selectedMonth,
                      onChanged: (m) => setSheetState(() => selectedMonth = m),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(AppLocalizations.of(ctx)!.exportTypeFormatLabel, style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(ctx)!.exportMonthlyPdf),
                    value: 'pdf',
                    groupValue: selectedFormat,
                    onChanged: (v) => setSheetState(() => selectedFormat = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(ctx)!.exportMonthlyExcel),
                    value: 'xlsx',
                    groupValue: selectedFormat,
                    onChanged: (v) => setSheetState(() => selectedFormat = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: Text(AppLocalizations.of(ctx)!.exportAllExcel),
                    subtitle: Text(AppLocalizations.of(ctx)!.exportAllExcelSubtitle),
                    value: 'xlsx_all',
                    groupValue: selectedFormat,
                    onChanged: (v) => setSheetState(() => selectedFormat = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(AppLocalizations.of(ctx)!.exportNowBtn),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        
                        if (selectedFormat == 'xlsx_all') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(ctx)!.snackPrepBackup)),
                          );
                          await ExportService.exportAllToExcel(state, AppLocalizations.of(context)!);
                          return;
                        }

                        final monthStr = Fmt.monthYear(selectedMonth);
                        final filteredTx = state.transactions
                            .where((t) =>
                                t.date.year == selectedMonth.year &&
                                t.date.month == selectedMonth.month)
                            .toList();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(ctx)!.snackPrepMonth(monthStr))),
                        );

                        if (selectedFormat == 'pdf') {
                          await ExportService.exportTransactionsToPDF(
                            transactions: filteredTx,
                            accounts: state.accounts,
                            periodName: monthStr,
                            summary: summary,
                            categories: categories,
                            l10n: AppLocalizations.of(context)!,
                          );
                        } else {
                          await ExportService.exportTransactionsToExcel(
                            transactions: filteredTx,
                            accounts: state.accounts,
                            periodName: monthStr,
                            l10n: AppLocalizations.of(context)!,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider).valueOrNull ?? const AppState();
    final summary = Report.forMonth(state.transactions, _month);
    final categories = Report.expenseByCategory(state.transactions, _month, categoryFallback: AppLocalizations.of(context)!.categoryOther);
    final series = Report.lastMonths(state.transactions, _month, count: 6);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tabReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: AppLocalizations.of(context)!.tooltipExport,
            onPressed: () =>
                _showExportSheet(context, state, summary, categories),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _MonthPicker(
              month: _month,
              onChanged: (m) => setState(() => _month = m),
            ),
            const SizedBox(height: 12),
            _SummaryCard(summary: summary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.cashFlow6Months,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _CashFlowChart(series: series),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.assetComposition,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _AssetPie(state: state),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.expenseByCategory,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _CategoryBreakdown(categories: categories, total: summary.expense),
          ],
        ),
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
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
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
                  child: _stat(context, AppLocalizations.of(context)!.summaryIncome, summary.income,
                      AppTheme.income, Icons.south_west),
                ),
                Expanded(
                  child: _stat(context, AppLocalizations.of(context)!.summaryExpense, summary.expense,
                      AppTheme.expense, Icons.north_east),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.summaryNet, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  Fmt.rupiahSigned(summary.net),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          summary.net >= 0 ? AppTheme.income : AppTheme.expense,
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
        0, (m, s) => [m, s.income, s.expense].reduce((a, b) => a > b ? a : b));
    if (maxVal == 0) {
      return _ChartEmpty(text: AppLocalizations.of(context)!.emptyCashFlow);
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
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                    BarChartRodData(
                      toY: series[i].expense,
                      color: AppTheme.expense,
                      width: 7,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
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
      (AppLocalizations.of(context)!.pieAssetCash, state.totalCash, AppTheme.income),
      (AppLocalizations.of(context)!.pieAssetInvestment, state.totalInvestment, AppTheme.investment),
      (AppLocalizations.of(context)!.pieAssetReceivable, state.totalReceivable, Colors.teal),
    ].where((e) => e.$2 > 0).toList();

    if (data.isEmpty) {
      return _ChartEmpty(text: AppLocalizations.of(context)!.emptyAsset);
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
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
      return _ChartEmpty(text: AppLocalizations.of(context)!.emptyCategory);
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
