import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase/auth.dart';
import 'l10n/app_localizations.dart';
import 'screens/accounts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tagihan_screen.dart';
import 'screens/finance_tools_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = createAppRouter();

GoRouter createAppRouter({GlobalKey<NavigatorState>? navigatorKey}) => GoRouter(
      navigatorKey: navigatorKey ?? rootNavigatorKey,
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MoneyWorkShell(navShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, __) => const DashboardScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/akun', builder: (_, __) => const AccountsScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/investasi',
                  builder: (_, __) => const InvestmentsScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/tagihan', builder: (_, __) => const TagihanScreen())
            ]),
          ],
        )
      ],
    );

/// Satu aplikasi Flutter: sidebar desktop dan navigasi bawah di HP/tablet.
class MoneyWorkShell extends ConsumerWidget {
  const MoneyWorkShell({super.key, required this.navShell});
  final StatefulNavigationShell navShell;

  void _go(int index) =>
      navShell.goBranch(index, initialLocation: index == navShell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.navHome,
      l10n.navAccounts,
      l10n.assetsTitle,
      l10n.navBills
    ];
    const icons = [
      Icons.home_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.show_chart,
      Icons.receipt_long_outlined
    ];
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    if (!desktop) {
      return Scaffold(
        body: navShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navShell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (var i = 0; i < labels.length; i++)
              NavigationDestination(icon: Icon(icons[i]), label: labels[i])
          ],
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
        body: Row(children: [
      SizedBox(
          width: 208,
          child: Material(
            color: scheme.surfaceContainerLowest,
            child: SafeArea(
                child: Column(children: [
              Expanded(
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 32),
                    child: Row(children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(l10n.appTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700)))
                    ])),
                for (var i = 0; i < labels.length; i++)
                  _SidebarItem(
                      icon: icons[i],
                      label: labels[i],
                      selected: navShell.currentIndex == i,
                      onTap: () => _go(i)),
                const SizedBox(height: 24),
                _SidebarItem(
                    icon: Icons.grid_view_outlined,
                    label: l10n.financeTools,
                    onTap: () => _open(context, const FinanceToolsScreen())),
              ])),
              const Divider(height: 1),
              ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(user?.initials ?? 'MW')),
                  title: Text(
                      user == null || user.isLocal
                          ? l10n.profileTitle
                          : user.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(l10n.tooltipProfile,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _open(context, const ProfileScreen())),
            ])),
          )),
      VerticalDivider(width: 1, color: scheme.outlineVariant),
      Expanded(child: navShell),
    ]));
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          selected: selected,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(icon, color: color, size: 21),
          minLeadingWidth: 21,
          title: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          onTap: onTap,
        ),
      ),
    );
  }
}
