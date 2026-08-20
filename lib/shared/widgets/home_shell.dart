import 'package:flutter/material.dart';

import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../responsive/breakpoints.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    TransactionsScreen(),
    InsightsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
  ];

  static const _items = [
    (icon: Icons.receipt_long_rounded, label: 'Home'),
    (icon: Icons.insights_rounded, label: 'Insights'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Accounts'),
    (icon: Icons.category_rounded, label: 'Categories'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = !isCompact(context);
    final body = IndexedStack(index: _index, children: _screens);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(
              items: _items,
              selected: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: _FloatingBottomNav(
        items: _items,
        selected: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<({IconData icon, String label})> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavButton(
                icon: items[i].icon,
                label: items[i].label,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// Vertical rail used on wide screens (tablets, landscape, foldables) instead
/// of squeezing a bottom bar meant for phone portrait widths.
class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<({IconData icon, String label})> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: selected,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary,
      selectedIconTheme: IconThemeData(color: scheme.onPrimary),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
