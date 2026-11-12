import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../utils/load_status.dart';
import '../repositories/part_repository.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
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
  int _partsCount = 0;

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
      final notifier = context.read<BrandListNotifier>();
      final partRepo = context.read<PartRepository>();
      final brand = await notifier.findById(widget.id);
      final count = brand == null ? 0 : await partRepo.countByBrand(brand.id);
      setState(() {
        _brand = brand;
        _partsCount = count;
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

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    final notifier = context.read<BrandListNotifier>();
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: brand == null,
      emptyTitle: 'Бренд не найден',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: brand == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: brand.name,
              fallbackPath: '/brands',
              isDeleted: brand.isDeleted,
              onEdit: () => context.go('/brands/${brand.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(brand.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(brand.id);
                    if (context.mounted) context.go('/brands');
                  } else {
                    await notifier.softDelete(brand.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(title: const Text('Страна'), subtitle: Text(brand.country)),
                ListTile(title: const Text('Год основания'), subtitle: Text('${brand.foundedYear}')),
                ListTile(title: const Text('Связанные запчасти'), subtitle: Text('$_partsCount')),
              ],
            ),
    );
  }
}
