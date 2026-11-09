import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../models/load_status.dart';
import '../state/brand_list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/load_state_view.dart';

class BrandDetailScreen extends StatefulWidget {
  final int id;

  const BrandDetailScreen({super.key, required this.id});

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  Brand? _brand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final brand = await context.read<BrandListNotifier>().findById(widget.id);
      setState(() {
        _brand = brand;
        _status = brand == null ? LoadStatus.error : LoadStatus.success;
        _error = brand == null ? 'Бренд не найден' : null;
      });
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/brands');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: brand == null,
      emptyTitle: 'Бренд не найден',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: brand == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: Text(brand.name, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(title: const Text('Страна'), subtitle: Text(brand.country)),
                ListTile(title: const Text('Год основания'), subtitle: Text('${brand.foundedYear}')),
                if (brand.isDeleted) const ListTile(title: Text('Статус'), subtitle: Text('удалено')),
                const SizedBox(height: 16),
                if (brand.isDeleted)
                  FilledButton.icon(
                    onPressed: () async {
                      final notifier = context.read<BrandListNotifier>();
                      final ok = await confirmRestore(context, brand.name);
                      if (!ok || !mounted) return;
                      await notifier.restore(brand.id);
                      await _load();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final notifier = context.read<BrandListNotifier>();
                      final router = GoRouter.of(context);
                      final choice = await confirmDelete(context, '«${brand.name}» будет удалён.');
                      if (!mounted) return;
                      if (choice == DeleteChoice.soft) {
                        await notifier.softDelete(brand.id);
                        await _load();
                      } else if (choice == DeleteChoice.hard) {
                        await notifier.hardDelete(brand.id);
                        router.go('/brands');
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
              ],
            ),
    );
  }
}
