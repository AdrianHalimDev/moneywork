import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/accounts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/receivables_screen.dart';
import 'screens/wishlist_screen.dart';

/// Definisi tab navigasi utama.
class _Tab {
  const _Tab(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = <_Tab>[
  _Tab('/', 'Beranda', Icons.dashboard_outlined, Icons.dashboard),
  _Tab('/akun', 'Akun', Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet),
  _Tab('/investasi', 'Investasi', Icons.show_chart_outlined, Icons.show_chart),
  _Tab('/utang', 'Utang', Icons.credit_card_outlined, Icons.credit_card),
  _Tab('/piutang', 'Piutang', Icons.handshake_outlined, Icons.handshake),
  _Tab('/wishlist', 'Wishlist', Icons.favorite_outline, Icons.favorite),
];

final appRouter = GoRouter(
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
          GoRoute(path: '/utang', builder: (_, __) => const DebtsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/piutang',
              builder: (_, __) => const ReceivablesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/wishlist', builder: (_, __) => const WishlistScreen()),
        ]),
      ],
    ),
  ],
);

/// Cangkang aplikasi dengan navigasi adaptif:
/// NavigationBar (bawah) di layar sempit, NavigationRail (samping) di lebar.
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
            NavigationRail(
              selectedIndex: navShell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Icon(Icons.savings, size: 28),
              ),
              destinations: [
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
