import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/auto_part.dart';
import '../models/load_status.dart';
import '../state/part_list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/load_state_view.dart';

class PartDetailScreen extends StatefulWidget {
  final int id;

  const PartDetailScreen({super.key, required this.id});

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  AutoPart? _part;

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
      final part = await context.read<PartListNotifier>().findById(widget.id);
      setState(() {
        _part = part;
        _status = part == null ? LoadStatus.error : LoadStatus.success;
        _error = part == null ? 'Запчасть не найдена' : null;
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
      context.go('/parts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final part = _part;
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: part == null,
      emptyTitle: 'Запчасть не найдена',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: part == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
                    Expanded(
                      child: Text(part.name, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(title: const Text('Артикул'), subtitle: Text(part.sku)),
                ListTile(title: const Text('Год'), subtitle: Text('${part.year}')),
                ListTile(title: const Text('Цена'), subtitle: Text('${part.price} ₽')),
                ListTile(title: const Text('Бренд'), subtitle: Text(brandById(part.brandId)?.name ?? '—')),
                ListTile(title: const Text('Категория'), subtitle: Text(categoryById(part.categoryId)?.name ?? '—')),
                if (part.isDeleted) const ListTile(title: Text('Статус'), subtitle: Text('удалено')),
                const SizedBox(height: 16),
                if (part.isDeleted)
                  FilledButton.icon(
                    onPressed: () async {
                      final notifier = context.read<PartListNotifier>();
                      final ok = await confirmRestore(context, part.name);
                      if (!ok || !mounted) return;
                      await notifier.restore(part.id);
                      await _load();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final notifier = context.read<PartListNotifier>();
                      final router = GoRouter.of(context);
                      final choice = await confirmDelete(context, '«${part.name}» будет удалена.');
                      if (!mounted) return;
                      if (choice == DeleteChoice.soft) {
                        await notifier.softDelete(part.id);
                        await _load();
                      } else if (choice == DeleteChoice.hard) {
                        await notifier.hardDelete(part.id);
                        router.go('/parts');
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
