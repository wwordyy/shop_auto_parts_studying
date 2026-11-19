import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../layout/app_layout.dart';
import '../state/auth_notifier.dart';
import '../widgets/ellipsis_text.dart';

class _Tab {
  final String path;
  final NavigationDestination destination;
  final bool Function(Permissions perms) visible;

  const _Tab({
    required this.path,
    required this.destination,
    required this.visible,
  });
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    _Tab(
      path: '/parts',
      visible: _catalog,
      destination: NavigationDestination(
        icon: Icon(Icons.build_outlined),
        selectedIcon: Icon(Icons.build),
        label: 'Запчасти',
      ),
    ),
    _Tab(
      path: '/brands',
      visible: _catalog,
      destination: NavigationDestination(
        icon: Icon(Icons.factory_outlined),
        selectedIcon: Icon(Icons.factory),
        label: 'Бренды',
      ),
    ),
    _Tab(
      path: '/categories',
      visible: _catalog,
      destination: NavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'Категории',
      ),
    ),
    _Tab(
      path: '/cars',
      visible: _catalog,
      destination: NavigationDestination(
        icon: Icon(Icons.directions_car_outlined),
        selectedIcon: Icon(Icons.directions_car),
        label: 'Авто',
      ),
    ),
    _Tab(
      path: '/orders',
      visible: _orders,
      destination: NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Заказы',
      ),
    ),
    _Tab(
      path: '/customers',
      visible: _customers,
      destination: NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Клиенты',
      ),
    ),
    _Tab(
      path: '/cards',
      visible: _cards,
      destination: NavigationDestination(
        icon: Icon(Icons.loyalty_outlined),
        selectedIcon: Icon(Icons.loyalty),
        label: 'Карты',
      ),
    ),
    _Tab(
      path: '/suppliers',
      visible: _suppliers,
      destination: NavigationDestination(
        icon: Icon(Icons.local_shipping_outlined),
        selectedIcon: Icon(Icons.local_shipping),
        label: 'Поставщики',
      ),
    ),
    _Tab(
      path: '/cabinet',
      visible: _cabinet,
      destination: NavigationDestination(
        icon: Icon(Icons.badge_outlined),
        selectedIcon: Icon(Icons.badge),
        label: 'Кабинет',
      ),
    ),
    _Tab(
      path: '/admin/users',
      visible: _users,
      destination: NavigationDestination(
        icon: Icon(Icons.manage_accounts_outlined),
        selectedIcon: Icon(Icons.manage_accounts),
        label: 'Пользователи',
      ),
    ),
    _Tab(
      path: '/admin/stats',
      visible: _stats,
      destination: NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights),
        label: 'Статистика',
      ),
    ),
  ];

  static bool _catalog(Permissions perms) => perms.canViewCatalog;
  static bool _orders(Permissions perms) => perms.canAccessOrders;
  static bool _customers(Permissions perms) => perms.canAccessCustomers;
  static bool _cards(Permissions perms) => perms.canAccessCards;
  static bool _suppliers(Permissions perms) => perms.canAccessSuppliers;
  static bool _cabinet(Permissions perms) => perms.canAccessCabinet;
  static bool _users(Permissions perms) => perms.canManageUsers;
  static bool _stats(Permissions perms) => perms.canViewStats;

  int _indexOf(String path, List<_Tab> tabs) {
    for (var i = 0; i < tabs.length; i++) {
      if (path == tabs[i].path || path.startsWith('${tabs[i].path}/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final perms = auth.permissions;
    final tabs = [
      for (final tab in _tabs)
        if (tab.visible(perms)) tab
    ];
    final path = GoRouterState.of(context).uri.path;
    final index = _indexOf(path, tabs);
    final layout = AppLayout.of(context);
    final user = auth.user;
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Магазин автозапчастей'),
        actions: [
          if (user != null)
            layout.isCompact
                ? Tooltip(
                    message: '${user.displayName} · ${user.role.label}',
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.person_outline),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: EllipsisText(
                          '${user.displayName} · ${user.role.label}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: layout.useSideNav
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      context.go(tabs[value].path),
                  extended: layout.sideNavExtended,
                  labelType: layout.sideNavExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  destinations: [
                    for (final tab in tabs)
                      NavigationRailDestination(
                        icon: Tooltip(
                            message: tab.destination.label,
                            child: tab.destination.icon),
                        selectedIcon: Tooltip(
                          message: tab.destination.label,
                          child: tab.destination.selectedIcon ??
                              tab.destination.icon,
                        ),
                        label: Text(tab.destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: layout.useBottomNav
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(tabs[value].path),
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [for (final tab in tabs) tab.destination],
            )
          : null,
    );

    if (!layout.isUltrawide) return scaffold;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: scaffold,
        ),
      ),
    );
  }
}
