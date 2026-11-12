import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/car_model.dart';
import '../utils/load_status.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class CarModelDetailScreen extends StatefulWidget {
  final int id;

  const CarModelDetailScreen({super.key, required this.id});

  @override
  State<CarModelDetailScreen> createState() => _CarModelDetailScreenState();
}

class _CarModelDetailScreenState extends State<CarModelDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  CarModel? _item;

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
      final item = await context.read<CarModelListNotifier>().findById(widget.id);
      setState(() {
        _item = item;
        _status = item == null ? LoadStatus.error : LoadStatus.success;
        _error = item == null ? 'Автомобиль не найден' : null;
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
    final notifier = context.read<CarModelListNotifier>();
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: item == null,
      emptyTitle: 'Автомобиль не найден',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: item == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: item.title,
              fallbackPath: '/cars',
              isDeleted: item.isDeleted,
              onEdit: () => context.go('/cars/${item.id}/edit'),
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
                    if (context.mounted) context.go('/cars');
                  } else {
                    await notifier.softDelete(item.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(title: const Text('Марка'), subtitle: Text(item.maker)),
                ListTile(title: const Text('Модель'), subtitle: Text(item.name)),
                ListTile(title: const Text('Годы выпуска'), subtitle: Text('${item.yearFrom}–${item.yearTo}')),
              ],
            ),
    );
  }
}
