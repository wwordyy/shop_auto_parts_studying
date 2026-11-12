import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../utils/load_status.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class CategoryDetailScreen extends StatefulWidget {
  final int id;

  const CategoryDetailScreen({super.key, required this.id});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  Category? _item;

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
      final item = await context.read<CategoryListNotifier>().findById(widget.id);
      setState(() {
        _item = item;
        _status = item == null ? LoadStatus.error : LoadStatus.success;
        _error = item == null ? 'Категория не найдена' : null;
      });
    } catch (e) {
      setState(() {
        _status = LoadStatus.error;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final notifier = context.read<CategoryListNotifier>();
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: item == null,
      emptyTitle: 'Категория не найдена',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: item == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: item.name,
              fallbackPath: '/categories',
              isDeleted: item.isDeleted,
              onEdit: () => context.go('/categories/${item.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(item.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(item.id);
                    if (context.mounted) context.go('/categories');
                  } else {
                    await notifier.softDelete(item.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(
                  title: const Text('Описание'),
                  subtitle: Text(item.description.isEmpty ? '—' : item.description),
                ),
              ],
            ),
    );
  }
}
