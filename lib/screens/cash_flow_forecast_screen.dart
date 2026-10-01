import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/app_state.dart';
import '../models/transaction.dart';
import '../services/cash_flow_forecast_service.dart';

/// Read-only 30-day projection from current account balances and dated plans.
class CashFlowForecastScreen extends ConsumerWidget {
  const CashFlowForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = _ForecastText(Localizations.localeOf(context).languageCode);
    final async = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr.get('title'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (state) => _ForecastBody(
          state: state,
          forecast: CashFlowForecastService.build(state),
          tr: tr,
        ),
      ),
    );
  }
}

class _ForecastBody extends StatelessWidget {
  const _ForecastBody({
    required this.state,
    required this.forecast,
    required this.tr,
  });

  final AppState state;
  final CashFlowForecast forecast;
  final _ForecastText tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowest = forecast.lowestDay;
    final accountNames = {for (final a in state.accounts) a.id: a.name};
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            Text(tr.get('intro'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricCard(
                  label: tr.get('currentCash'),
                  value: Fmt.rupiah(forecast.openingCash),
                  color: theme.colorScheme.primary,
                ),
                _MetricCard(
                  label: tr.get('after30Days'),
                  value: Fmt.rupiah(forecast.closingAvailableCash),
                  color: forecast.closingAvailableCash < 0
                      ? AppTheme.expense
                      : theme.colorScheme.primary,
                ),
                if (lowest != null)
                  _MetricCard(
                    label: '${tr.get('lowest')} · ${Fmt.date(lowest.date)}',
                    value: Fmt.rupiah(lowest.availableAfterDebt),
                    color: lowest.availableAfterDebt < 0
                        ? AppTheme.expense
                        : AppTheme.debt,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.get('cashTrend'),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: _ForecastChart(days: forecast.days),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Fmt.date(forecast.days.first.date)),
                        Text(Fmt.date(forecast.days.last.date)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(tr.get('accountBalances'),
                        style: theme.textTheme.titleMedium),
                  ),
                  if (state.accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(tr.get('noAccounts')),
                    ),
                  for (final account in state.accounts)
                    ListTile(
                      title: Text(account.name),
                      subtitle: Text(
                        '${Fmt.rupiah(account.balance)} → '
                        '${Fmt.rupiah(forecast.days.last.accountBalances[account.id] ?? account.balance)}',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (forecast.unplannedRecurringCount > 0 ||
                forecast.unscheduledDebtCount > 0 ||
                forecast.overdueDebtCount > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.get('missingDates'),
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      if (forecast.unplannedRecurringCount > 0)
                        Text(tr.count('undatedTemplates',
                            forecast.unplannedRecurringCount)),
                      if (forecast.unscheduledDebtCount > 0)
                        Text(tr.count(
                            'undatedDebts', forecast.unscheduledDebtCount)),
                      if (forecast.overdueDebtCount > 0)
                        Text(tr.count(
                            'overdueDebts', forecast.overdueDebtCount)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(tr.get('plannedEvents'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(tr.get('plannedHint'), style: theme.textTheme.bodySmall),
            if (forecast.events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(tr.get('noEvents')),
              ),
            for (final event in forecast.events)
              _ForecastEventTile(
                event: event,
                accountNames: accountNames,
                tr: tr,
              ),
            const SizedBox(height: 18),
            Text(tr.get('postedEvents'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(tr.get('postedHint'), style: theme.textTheme.bodySmall),
            if (forecast.postedTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(tr.get('noPosted')),
              ),
            for (final tx in forecast.postedTransactions.take(5))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(tx.note.isEmpty ? tx.category : tx.note),
                subtitle:
                    Text('${Fmt.date(tx.date)} · ${tr.get('alreadyCounted')}'),
                trailing: Text(_postedAmount(tx)),
              ),
            const SizedBox(height: 16),
            Text(tr.get('assumptions'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(tr.get('assumptionsBody'), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _postedAmount(Transaction tx) {
    final prefix = switch (tx.type) {
      TxType.income => '+',
      TxType.expense => '−',
      TxType.transfer => '↔',
    };
    return '$prefix${Fmt.rupiah(tx.amount)}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.days});
  final List<ForecastDay> days;

  @override
  Widget build(BuildContext context) {
    final values = days.map((d) => d.availableAfterDebt).toList();
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final pad = math.max(1.0, (high - low).abs() * 0.15);
    final color = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days.length - 1).toDouble(),
        minY: low - pad,
        maxY: high + pad,
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: false,
            barWidth: 3,
            color: color,
            dotData: FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _ForecastEventTile extends StatelessWidget {
  const _ForecastEventTile({
    required this.event,
    required this.accountNames,
    required this.tr,
  });

  final ForecastEvent event;
  final Map<String, String> accountNames;
  final _ForecastText tr;

  @override
  Widget build(BuildContext context) {
    final (icon, color, type) = switch (event.kind) {
      ForecastEventKind.income => (
          Icons.south_west,
          AppTheme.income,
          tr.get('income')
        ),
      ForecastEventKind.expense => (
          Icons.north_east,
          AppTheme.expense,
          tr.get('expense')
        ),
      ForecastEventKind.transfer => (
          Icons.swap_horiz,
          AppTheme.investment,
          tr.get('transfer')
        ),
      ForecastEventKind.debtDue => (
          Icons.event_busy_outlined,
          AppTheme.debt,
          tr.get('debtDue')
        ),
    };
    final account = event.kind == ForecastEventKind.debtDue
        ? tr.get('unallocated')
        : event.kind == ForecastEventKind.transfer
            ? '${accountNames[event.accountId] ?? '?'} → ${accountNames[event.toAccountId] ?? '?'}'
            : accountNames[event.accountId] ?? '?';
    final prefix = switch (event.kind) {
      ForecastEventKind.income => '+',
      ForecastEventKind.expense || ForecastEventKind.debtDue => '−',
      ForecastEventKind.transfer => '↔',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(event.label),
      subtitle: Text('${Fmt.date(event.date)} · $type · $account'),
      trailing: Text('$prefix${Fmt.rupiah(event.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _ForecastText {
  const _ForecastText(this.language);
  final String language;

  String get(String key) {
    final labels = switch (language) {
      'en' => _english,
      'zh' => _chinese,
      _ => _indonesian,
    };
    return labels[key]!;
  }

  String count(String key, int count) => '$count ${get(key)}';
}

const _indonesian = <String, String>{
  'title': 'Proyeksi arus kas',
  'intro':
      'Perkiraan kas 30 hari ke depan dari saldo saat ini, transaksi rutin bertanggal, dan jatuh tempo utang.',
  'currentCash': 'Kas sekarang',
  'after30Days': 'Kas setelah rencana',
  'lowest': 'Titik terendah',
  'cashTrend': 'Perkiraan kas tersedia',
  'accountBalances': 'Proyeksi per rekening',
  'noAccounts': 'Belum ada rekening.',
  'missingDates': 'Belum masuk proyeksi',
  'undatedTemplates': 'template rutin tanpa tanggal bulanan',
  'undatedDebts': 'utang tanpa jatuh tempo',
  'overdueDebts': 'utang lewat jatuh tempo; perbarui tanggalnya',
  'plannedEvents': 'Perkiraan terjadwal',
  'plannedHint': 'Ini perkiraan, belum tercatat sebagai transaksi.',
  'noEvents': 'Belum ada rencana bertanggal dalam 30 hari.',
  'postedEvents': 'Transaksi yang sudah tercatat',
  'postedHint':
      'Sudah masuk saldo sekarang; transaksi yang cocok dengan rencana tidak ditambahkan lagi.',
  'noPosted': 'Belum ada transaksi tercatat dalam rentang ini.',
  'alreadyCounted': 'sudah masuk saldo',
  'assumptions': 'Cara membaca proyeksi',
  'assumptionsBody':
      'Tanggal rutin hanya untuk perkiraan; pencatatan tetap manual. Transaksi tercatat dikenali dari nama, nominal, dan rekening yang sama dalam bulan terkait. Jatuh tempo utang mengurangi kas total, bukan rekening tertentu karena rekening pembayar belum dipilih. Transaksi lain tidak dapat diprediksi.',
  'income': 'Pemasukan',
  'expense': 'Pengeluaran',
  'transfer': 'Transfer',
  'debtDue': 'Jatuh tempo utang',
  'unallocated': 'rekening belum ditentukan',
};

const _english = <String, String>{
  'title': 'Cash-flow forecast',
  'intro':
      'A 30-day estimate from current balances, dated recurring transactions, and debt due dates.',
  'currentCash': 'Cash now',
  'after30Days': 'Cash after plans',
  'lowest': 'Lowest point',
  'cashTrend': 'Estimated available cash',
  'accountBalances': 'Projected account balances',
  'noAccounts': 'No accounts yet.',
  'missingDates': 'Not included in forecast',
  'undatedTemplates': 'recurring templates without a monthly day',
  'undatedDebts': 'debts without a due date',
  'overdueDebts': 'overdue debts; update their dates',
  'plannedEvents': 'Scheduled estimates',
  'plannedHint': 'These are estimates, not posted transactions.',
  'noEvents': 'No dated plans in the next 30 days.',
  'postedEvents': 'Posted transactions',
  'postedHint':
      'Already in current balances; matching planned items are not added again.',
  'noPosted': 'No posted transactions in this range.',
  'alreadyCounted': 'already in balance',
  'assumptions': 'How to read this forecast',
  'assumptionsBody':
      'Recurring days are estimates only; posting remains manual. Posted items are matched by name, amount, and account in the same month. Debt due dates reduce total cash, not a specific account, because no funding account is selected. Other transactions cannot be predicted.',
  'income': 'Income',
  'expense': 'Expense',
  'transfer': 'Transfer',
  'debtDue': 'Debt due',
  'unallocated': 'funding account not selected',
};

const _chinese = <String, String>{
  'title': '现金流预测',
  'intro': '根据当前余额、定期交易日期和债务到期日估算未来 30 天的现金。',
  'currentCash': '当前现金',
  'after30Days': '计划后现金',
  'lowest': '最低点',
  'cashTrend': '预计可用现金',
  'accountBalances': '账户余额预测',
  'noAccounts': '暂无账户。',
  'missingDates': '未计入预测',
  'undatedTemplates': '个未设置每月日期的定期模板',
  'undatedDebts': '笔未设置到期日的债务',
  'overdueDebts': '笔已逾期债务；请更新日期',
  'plannedEvents': '计划估算',
  'plannedHint': '这些只是估算，尚未记为交易。',
  'noEvents': '未来 30 天暂无已设日期的计划。',
  'postedEvents': '已记录的交易',
  'postedHint': '已包含在当前余额中；匹配的计划项目不会再次计入。',
  'noPosted': '此范围内暂无已记录交易。',
  'alreadyCounted': '已计入余额',
  'assumptions': '预测说明',
  'assumptionsBody':
      '定期日期只用于估算，实际记账仍需手动操作。已记录交易按同月名称、金额和账户匹配。债务到期额仅从总现金中扣除，因为尚未指定付款账户。其他交易无法预测。',
  'income': '收入',
  'expense': '支出',
  'transfer': '转账',
  'debtDue': '债务到期',
  'unallocated': '未指定付款账户',
};
