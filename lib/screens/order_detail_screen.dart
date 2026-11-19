import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/shop_order.dart';
import '../state/auth_notifier.dart';
import '../state/list_notifier.dart';
import '../utils/load_status.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/entity_detail.dart';
import '../widgets/load_state_view.dart';

class OrderDetailScreen extends StatefulWidget {
  final int id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  String? _error;
  ShopOrder? _order;

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
      final order = await context.read<OrderListNotifier>().findById(widget.id);
      setState(() {
        _order = order;
        _status = order == null ? LoadStatus.error : LoadStatus.success;
        _error = order == null ? 'Заказ не найден' : null;
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
    final order = _order;
    final notifier = context.read<OrderListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    return LoadStateView(
      status: _status,
      error: _error,
      isEmpty: order == null,
      emptyTitle: 'Заказ не найден',
      onRetry: _load,
      child: order == null
          ? const SizedBox.shrink()
          : EntityDetail(
              title: 'Заказ №${order.id}',
              fallbackPath: '/orders',
              isDeleted: order.isDeleted,
              showEdit: perms.canMutate,
              showDelete: perms.canSoftDelete,
              showRestore: perms.canRestore,
              allowHardDelete: perms.canHardDelete,
              onEdit: () => context.go('/orders/${order.id}/edit'),
              onRestored: () async {
                await runMutation(context, () async {
                  await notifier.restore(order.id);
                  await _load();
                });
              },
              onDeleted: (hard) async {
                await runMutation(context, () async {
                  if (hard) {
                    await notifier.hardDelete(order.id);
                    if (context.mounted) context.go('/orders');
                  } else {
                    await notifier.softDelete(order.id);
                    await _load();
                  }
                });
              },
              fields: [
                ListTile(
                    title: const Text('Клиент'),
                    subtitle: Text(order.customerName)),
                ListTile(
                    title: const Text('Статус'),
                    subtitle: Text(order.statusLabel)),
                ListTile(
                    title: const Text('Сумма'),
                    subtitle: Text('${order.subtotal} ₽')),
                ListTile(
                    title: const Text('Скидка карты'),
                    subtitle: Text('${order.discountPercent}%')),
                ListTile(
                    title: const Text('К оплате'),
                    subtitle: Text('${order.total} ₽')),
                for (final item in order.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.quantity} × ${item.unitPrice} ₽ = ${item.lineTotal} ₽'),
                  ),
              ],
            ),
    );
  }
}
