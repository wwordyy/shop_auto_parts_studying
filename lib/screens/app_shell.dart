import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../state/auth_notifier.dart';

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
      path: '/customers',
      visible: _customers,
      destination: NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Клиенты',
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
  static bool _customers(Permissions perms) => perms.canAccessCustomers;
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
    final tabs = [for (final tab in _tabs) if (tab.visible(perms)) tab];
    final path = GoRouterState.of(context).uri.path;
    final index = _indexOf(path, tabs);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин автозапчастей'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${user.displayName} · ${user.role.label}',
                  overflow: TextOverflow.ellipsis,
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
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) => context.go(tabs[value].path),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final tab in tabs)
                      NavigationRailDestination(
                        icon: tab.destination.icon,
                        selectedIcon: tab.destination.selectedIcon,
                        label: Text(tab.destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(tabs[value].path),
              destinations: [for (final tab in tabs) tab.destination],
            ),
    );
  }
}
