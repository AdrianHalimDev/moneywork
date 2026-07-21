import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'screens/accounts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/receipt_scanner_screen.dart';
import 'screens/tagihan_screen.dart';
import 'services/receipt_scanner_service.dart';

/// Definisi tab navigasi utama.
class _Tab {
  const _Tab(this.path, this.icon, this.selectedIcon, this.labelGetter);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations loc) labelGetter;
}

final _tabs = <_Tab>[
  _Tab('/', Icons.dashboard_outlined, Icons.dashboard, (loc) => loc.navHome),
  _Tab('/akun', Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet, (loc) => loc.navAccounts),
  _Tab('/investasi', Icons.show_chart_outlined, Icons.show_chart, (loc) => loc.navInvestments),
  _Tab('/tagihan', Icons.receipt_long_outlined, Icons.receipt_long, (loc) => loc.navBills),
];

/// Kunci navigator root. Dipakai untuk menampilkan dialog global (mis. dialog
/// update OTA) dari widget yang berada di atas Navigator, seperti UpdateChecker
/// yang dipasang di `builder` MaterialApp.router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navShell) => _AppShell(navShell: navShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/akun', builder: (_, __) => const AccountsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/investasi',
              builder: (_, __) => const InvestmentsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/tagihan', builder: (_, __) => const TagihanScreen()),
        ]),
      ],
    ),
  ],
);

/// Cangkang aplikasi dengan navigasi adaptif:
/// BottomAppBar (bawah) di layar sempit, NavigationRail (samping) di lebar.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navShell});

  final StatefulNavigationShell navShell;

  void _go(int index) => navShell.goBranch(
        index,
        initialLocation: index == navShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: navShell.currentIndex,
                        onDestinationSelected: _go,
                        labelType: NavigationRailLabelType.all,
                        leading: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Icon(Icons.savings, size: 28),
                        ),
                        destinations: _tabs
                            .map((t) => NavigationRailDestination(
                                  icon: Icon(t.icon),
                                  selectedIcon: Icon(t.selectedIcon),
                                  label: Text(t.labelGetter(AppLocalizations.of(context)!)),
                                ))
                            .toList(),
                        trailing: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 12),
                          child: FloatingActionButton.small(
                            elevation: 0,
                            onPressed: () => _showScanOptions(context),
                            tooltip: AppLocalizations.of(context)!.scanButton,
                            child: const Icon(Icons.document_scanner_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navShell,
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // 2 tab di kiri
            for (var i = 0; i < 2; i++)
              Expanded(
                child: _NavBarItem(
                  tab: _tabs[i],
                  isSelected: navShell.currentIndex == i,
                  onTap: () => _go(i),
                ),
              ),
            // Tombol scan di tengah (menyatu dengan bar)
            Expanded(
              child: InkWell(
                onTap: () => _showScanOptions(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.scanButton,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 2 tab di kanan
            for (var i = 2; i < _tabs.length; i++)
              Expanded(
                child: _NavBarItem(
                  tab: _tabs[i],
                  isSelected: navShell.currentIndex == i,
                  onTap: () => _go(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// URL endpoint Cloudflare Worker OCR.
/// Ganti dengan URL worker yang sudah di-deploy.
const _ocrEndpoint =
    'https://moneywork-ocr.tompel-adrian-6ef.workers.dev/scan';

void _showScanOptions(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(l10n.scanFromCamera),
            onTap: () {
              Navigator.pop(ctx);
              _processImage(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(l10n.scanFromGallery),
            onTap: () {
              Navigator.pop(ctx);
              _processImage(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _processImage(BuildContext context, ImageSource source) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // 1. Ambil gambar
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source, imageQuality: 85);
  if (image == null) return; // User batal

  // 2. Tampilkan loading
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.receiptScanning)),
          ],
        ),
      ),
    ),
  );

  try {
    // 3. Kirim ke Cloudflare Worker
    final service = ReceiptScannerService(ocrEndpoint: _ocrEndpoint);
    final result = await service.scanReceipt(image);

    // 4. Tutup loading dan buka layar review
    if (context.mounted) Navigator.of(context).pop(); // tutup dialog
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(initialData: result),
      ),
    );
  } catch (e) {
    // Tutup loading
    if (context.mounted) Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.receiptScanFailed}: $e')),
    );
  }
}
class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _Tab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? tab.selectedIcon : tab.icon, color: color),
            const SizedBox(height: 4),
            Text(
              tab.labelGetter(AppLocalizations.of(context)!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
