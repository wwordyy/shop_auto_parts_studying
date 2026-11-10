import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../utils/load_status.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int id;

  const CustomerDetailScreen({super.key, required this.id});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  Customer? _item;

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
      final item = await context.read<CustomerListNotifier>().findById(widget.id);
      setState(() {
        _item = item;
        _status = item == null ? LoadStatus.error : LoadStatus.success;
        _error = item == null ? 'Клиент не найден' : null;
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
    final notifier = context.read<CustomerListNotifier>();
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: item == null,
      emptyTitle: 'Клиент не найден',
      emptySubtitle: 'Запись отсутствует или была удалена навсегда.',
      onRetry: _load,
      child: item == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: item.fullName,
              fallbackPath: '/customers',
              isDeleted: item.isDeleted,
              onEdit: () => context.go('/customers/${item.id}/edit'),
              onRestored: () async {
                await notifier.restore(item.id);
                await _load();
              },
              onDeleted: (hard) async {
                if (hard) {
                  await notifier.hardDelete(item.id);
                  if (context.mounted) context.go('/customers');
                } else {
                  await notifier.softDelete(item.id);
                  await _load();
                }
              },
              fields: [
                ListTile(title: const Text('Email'), subtitle: Text(item.email)),
                ListTile(title: const Text('Телефон'), subtitle: Text(item.phone)),
                const Divider(),
                ListTile(
                  title: Text('Дисконтная карта', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(title: const Text('Номер'), subtitle: Text(item.card.number)),
                ListTile(title: const Text('Дата выдачи'), subtitle: Text(formatDate(item.card.issuedAt))),
                ListTile(title: const Text('Скидка'), subtitle: Text('${item.card.discountPercent}%')),
                ListTile(
                  title: const Text('Статус карты'),
                  subtitle: Text(item.card.active ? 'активна' : 'неактивна'),
                ),
              ],
            ),
    );
  }
}
