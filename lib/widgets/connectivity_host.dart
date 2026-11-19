import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_monitor.dart';
import '../state/list_notifier.dart';

class ConnectivityHost extends StatefulWidget {
  final Widget child;

  const ConnectivityHost({super.key, required this.child});

  @override
  State<ConnectivityHost> createState() => _ConnectivityHostState();
}

class _ConnectivityHostState extends State<ConnectivityHost> {
  ConnectivityMonitor? _monitor;
  bool _wasOnline = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final monitor = context.read<ConnectivityMonitor>();
    if (!identical(_monitor, monitor)) {
      _monitor?.removeListener(_onChange);
      _monitor = monitor;
      _wasOnline = monitor.isOnline;
      _monitor!.addListener(_onChange);
    }
  }

  void _onChange() {
    final monitor = _monitor;
    if (monitor == null || !mounted) return;
    final online = monitor.isOnline;
    if (!_wasOnline && online) {
      _reload();
    }
    _wasOnline = online;
  }

  void _reload() {
    context.read<PartListNotifier>().load();
    context.read<BrandListNotifier>().load();
    context.read<CategoryListNotifier>().load();
    context.read<CarModelListNotifier>().load();
    context.read<CustomerListNotifier>().load();
    context.read<CardListNotifier>().load();
    context.read<SupplierListNotifier>().load();
    context.read<OrderListNotifier>().load();
  }

  @override
  void dispose() {
    _monitor?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityMonitor>().isOnline;
    return Stack(
      children: [
        widget.child,
        if (!online)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        semanticLabel: 'Нет сети',
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Нет соединения с сервером. Когда связь восстановится, данные загрузятся без перезагрузки страницы.',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<ConnectivityMonitor>().probe(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
