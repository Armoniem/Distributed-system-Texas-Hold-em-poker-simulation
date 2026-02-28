import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _railExpanded = true;

  static const _navItems = [
    _NavItem('/', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/evaluate', Icons.style_rounded, 'Hand Evaluator'),
    _NavItem('/compare', Icons.compare_arrows_rounded, 'Comparator'),
    _NavItem('/probability', Icons.analytics_rounded, 'Probability'),
    _NavItem('/health', Icons.monitor_heart_rounded, 'System Status'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (!isDesktop) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          destinations: _navItems
              .map(
                (n) => NavigationDestination(
                  icon: Icon(n.icon),
                  label: n.label.split(' ').first,
                ),
              )
              .toList(),
          selectedIndex: _navItems
              .indexWhere((n) => n.route == widget.currentRoute)
              .clamp(0, _navItems.length - 1),
          onDestinationSelected: (i) =>
              Navigator.of(context).pushReplacementNamed(_navItems[i].route),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: _railExpanded ? 220 : 72,
            child: _SideNav(
              items: _navItems,
              currentRoute: widget.currentRoute,
              expanded: _railExpanded,
              onToggle: () => setState(() => _railExpanded = !_railExpanded),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final String currentRoute;
  final bool expanded;
  final VoidCallback onToggle;

  const _SideNav({
    required this.items,
    required this.currentRoute,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (expanded) ...[
                  Row(
                    children: [
                      _logo(),
                      const SizedBox(width: 10),
                      Text(
                        'PokerEval',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ] else
                  _logo(),
                IconButton(
                  icon: Icon(
                    expanded
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...items.map(
            (item) => _NavTile(
              item: item,
              isSelected: currentRoute == item.route,
              expanded: expanded,
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(item.route),
            ),
          ),
          const Spacer(),
          Consumer<ThemeProvider>(
            builder: (ctx, tp, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: expanded
                  ? Row(
                      children: [
                        Icon(
                          tp.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tp.isDark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: tp.isDark,
                          onChanged: (_) => tp.toggle(),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    )
                  : IconButton(
                      icon: Icon(
                        tp.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: tp.toggle,
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _logo() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text('♠', style: TextStyle(color: Colors.white, fontSize: 18)),
  );
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;

  const _NavItem(this.route, this.icon, this.label);
}
