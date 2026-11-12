import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auto_part.dart';
import '../utils/load_status.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_model_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/part_repository.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
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
  String _brandName = '—';
  String _categories = '—';
  String _cars = '—';

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
      final partNotifier = context.read<PartListNotifier>();
      final brandRepo = context.read<BrandRepository>();
      final categoryRepo = context.read<CategoryRepository>();
      final carRepo = context.read<CarModelRepository>();
      final part = await partNotifier.findById(widget.id);
      if (part == null) {
        setState(() {
          _part = null;
          _status = LoadStatus.error;
          _error = 'Запчасть не найдена';
        });
        return;
      }
      final brand = await brandRepo.findById(part.brandId);
      final categories = await categoryRepo.getAll(includeDeleted: true);
      final cars = await carRepo.getAll(includeDeleted: true);
      setState(() {
        _part = part;
        _brandName = brand?.name ?? '—';
        _categories = joinNames(part.categoryIds, {for (final item in categories) item.id: item.name});
        _cars = joinNames(part.carModelIds, {for (final item in cars) item.id: item.title});
        _status = LoadStatus.success;
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
    final part = _part;
    final notifier = context.read<PartListNotifier>();
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: part == null,
      emptyTitle: 'Запчасть не найдена',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: part == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: part.name,
              fallbackPath: '/parts',
              isDeleted: part.isDeleted,
              onEdit: () => context.go('/parts/${part.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(part.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(part.id);
                    if (context.mounted) context.go('/parts');
                  } else {
                    await notifier.softDelete(part.id);
                    await _load();
                  }
                });
              },
              extra: [
                FilledButton.icon(
                  onPressed: part.isDeleted
                      ? null
                      : () async {
                          await runMutation(context, () async {
                            await context.read<PartRepository>().sell(part.id);
                            await notifier.load();
                            await _load();
                          });
                        },
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: const Text('Продать 1 шт'),
                ),
              ],
              fields: [
                ListTile(title: const Text('Артикул'), subtitle: Text(part.sku)),
                ListTile(title: const Text('Год'), subtitle: Text('${part.year}')),
                ListTile(title: const Text('Цена'), subtitle: Text('${part.price} ₽')),
                ListTile(title: const Text('Склад'), subtitle: Text('${part.stockAvailable} из ${part.stockTotal}')),
                ListTile(title: const Text('Бренд'), subtitle: Text(_brandName)),
                ListTile(title: const Text('Категории'), subtitle: Text(_categories)),
                ListTile(title: const Text('Совместимые автомобили'), subtitle: Text(_cars)),
              ],
            ),
    );
  }
}
