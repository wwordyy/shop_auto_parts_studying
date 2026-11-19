import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../state/auth_notifier.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int id;

  const SupplierDetailScreen({super.key, required this.id});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  Supplier? _supplier;

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
      final supplier =
          await context.read<SupplierListNotifier>().findById(widget.id);
      setState(() {
        _supplier = supplier;
        _status = supplier == null ? LoadStatus.error : LoadStatus.success;
        _error = supplier == null ? 'Поставщик не найден' : null;
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
    final supplier = _supplier;
    final notifier = context.read<SupplierListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: supplier == null,
      emptyTitle: 'Поставщик не найден',
      onRetry: _load,
      child: supplier == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: supplier.name,
              fallbackPath: '/suppliers',
              isDeleted: supplier.isDeleted,
              showEdit: perms.canMutate,
              showDelete: perms.canSoftDelete,
              showRestore: perms.canRestore,
              allowHardDelete: perms.canHardDelete,
              onEdit: () => context.go('/suppliers/${supplier.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(supplier.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(supplier.id);
                    if (context.mounted) context.go('/suppliers');
                  } else {
                    await notifier.softDelete(supplier.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(
                    title: const Text('Страна'),
                    subtitle: Text(supplier.country)),
                ListTile(
                    title: const Text('Телефон'),
                    subtitle: Text(supplier.phone)),
                ListTile(
                    title: const Text('Email'),
                    subtitle: Text(
                        supplier.email.isEmpty ? 'не указан' : supplier.email)),
                ListTile(
                    title: const Text('Рейтинг'),
                    subtitle: Text('${supplier.rating}')),
              ],
            ),
    );
  }
}
