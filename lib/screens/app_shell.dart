import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = ['/parts', '/brands', '/categories', '/cars', '/customers'];

  int _indexOf(String path) {
    for (var i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i] || path.startsWith('${_tabs[i]}/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexOf(path);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.build_outlined),
        selectedIcon: Icon(Icons.build),
        label: 'Запчасти',
      ),
      NavigationDestination(
        icon: Icon(Icons.factory_outlined),
        selectedIcon: Icon(Icons.factory),
        label: 'Бренды',
      ),
      NavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'Категории',
      ),
      NavigationDestination(
        icon: Icon(Icons.directions_car_outlined),
        selectedIcon: Icon(Icons.directions_car),
        label: 'Авто',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Клиенты',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Магазин автозапчастей')),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) => context.go(_tabs[value]),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
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
              onDestinationSelected: (value) => context.go(_tabs[value]),
              destinations: destinations,
            ),
    );
  }
}
