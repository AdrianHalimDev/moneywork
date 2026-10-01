import 'package:flutter/material.dart';
import 'package:moneywork/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/dialogs/debt_dialogs.dart';
import '../widgets/dialogs/receivable_dialogs.dart';
import 'debts_screen.dart';
import 'receivables_screen.dart';
import 'bill_splitter_screen.dart';

/// Halaman Tagihan yang menggabungkan Utang dan Piutang menggunakan TabBar.
class TagihanScreen extends ConsumerStatefulWidget {
  const TagihanScreen({super.key});

  @override
  ConsumerState<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends ConsumerState<TagihanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titleBills),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: AppLocalizations.of(context)!.tooltipSplitBill,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BillSplitterScreen()),
            ),
          ),
          // Tombol tambah yang menyesuaikan tab aktif
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: _tabCtrl.index == 0 ? AppLocalizations.of(context)!.tooltipAddDebt : AppLocalizations.of(context)!.tooltipAddReceivable,
            onPressed: () {
              if (_tabCtrl.index == 0) {
                showDebtDialog(context, ref);
              } else {
                showReceivableDialog(context, ref);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabDebts),
            Tab(text: AppLocalizations.of(context)!.tabReceivables),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          DebtsScreen(hideAppBar: true),
          ReceivablesScreen(hideAppBar: true),
        ],
      ),
    );
  }
}
