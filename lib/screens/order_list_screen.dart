import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/shop_order.dart';
import '../queries/order_query.dart';
import '../repositories/customer_repository.dart';
import '../state/auth_notifier.dart';
import '../state/list_notifier.dart';
import '../widgets/adaptive_collection.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/ellipsis_text.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/list_toolbar.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class OrderListScreen extends StatefulWidget {
  final OrderQuery query;

  const OrderListScreen({super.key, required this.query});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderListNotifier>().applyQuery(widget.query);
    });
    _loadCustomers();
  }

  @override
  void didUpdateWidget(covariant OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<OrderListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadCustomers() async {
    if (!context.read<AuthNotifier>().permissions.canMutate) return;
    final items = await context.read<CustomerRepository>().getAll();
    if (!mounted) return;
    setState(() => _customers = items);
  }

  void _go(OrderQuery query) {
    final params = query.toParams();
    context.go(
        Uri(path: '/orders', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(ShopOrder order) async {
    final choice = await confirmDelete(
      context,
      'Удалить заказ №${order.id}?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    final notifier = context.read<OrderListNotifier>();
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(order.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(order.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<OrderListNotifier>();
    final choice = await confirmDelete(
      context,
      'Удалить выбранные (${notifier.selected.length})?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    await runMutation(context,
        () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(ShopOrder order) {
    final notifier = context.read<OrderListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/orders/${order.id}'),
      onEdit: () => context.go('/orders/${order.id}/edit'),
      isDeleted: order.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          order.isDeleted ? perms.canRestore : perms.canSoftDelete,
      onDeleteOrRestore: order.isDeleted
          ? () async {
              if (await confirmRestore(context, 'заказ №${order.id}') &&
                  mounted) {
                await notifier.restore(order.id);
              }
            }
          : () => _delete(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<OrderListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;
    final canCreate = perms.isAuthenticated;

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по номеру заказа',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          addLabel: 'Оформить',
          onAdd: canCreate ? () => context.go('/orders/new') : null,
          filters: [
            if (perms.canMutate)
              FilterDropdown<int?>(
                label: 'Клиент',
                value: query.customerId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все')),
                  for (final customer in _customers)
                    DropdownMenuItem(
                        value: customer.id, child: Text(customer.fullName)),
                ],
                onChanged: (value) => _go(query.copyWith(customerId: value)),
              ),
            FilterDropdown<String?>(
              label: 'Статус',
              value: query.status,
              items: const [
                DropdownMenuItem(value: null, child: Text('Все')),
                DropdownMenuItem(value: 'new', child: Text('Новый')),
                DropdownMenuItem(value: 'paid', child: Text('Оплачен')),
                DropdownMenuItem(value: 'cancelled', child: Text('Отменён')),
              ],
              onChanged: (value) => _go(query.copyWith(status: value)),
            ),
            FilterDropdown<int?>(
              label: 'Сумма от',
              value: query.minTotal,
              items: const [
                DropdownMenuItem(value: null, child: Text('Любая')),
                DropdownMenuItem(value: 1000, child: Text('1000 ₽')),
                DropdownMenuItem(value: 5000, child: Text('5000 ₽')),
              ],
              onChanged: (value) => _go(query.copyWith(minTotal: value)),
            ),
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const OrderQuery()),
              child: const Text('Сбросить'),
            ),
          ],
          selectionBar: notifier.hasSelection && perms.canSoftDelete
              ? SelectionBar(
                  count: notifier.selected.length, onDelete: _deleteSelected)
              : null,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoadStateView(
              status: notifier.status,
              error: notifier.error,
              isEmpty: notifier.result.items.isEmpty,
              emptyTitle: 'Заказов нет',
              onRetry: notifier.load,
              child: AdaptiveCollection<ShopOrder>(
                items: notifier.result.items,
                idOf: (item) => item.id,
                selected: notifier.selected,
                onToggleSelect:
                    perms.canSoftDelete ? notifier.toggleSelection : null,
                onSelectAll:
                    perms.canSoftDelete ? notifier.selectAllOnPage : null,
                sortField: query.sortField,
                sortAscending: query.sortAscending,
                onSort: (field) => _go(
                  query.copyWith(
                    sortField: field,
                    sortAscending:
                        field == query.sortField ? !query.sortAscending : true,
                  ),
                ),
                columns: [
                  TableColumnSpec(
                      label: '№',
                      sortField: 'id',
                      numeric: true,
                      build: (item) => Text('${item.id}')),
                  TableColumnSpec(
                      label: 'Клиент',
                      build: (item) => EllipsisText(item.customerName)),
                  TableColumnSpec(
                      label: 'Статус',
                      sortField: 'status',
                      build: (item) => Text(item.statusLabel)),
                  TableColumnSpec(
                      label: 'Итого',
                      sortField: 'total',
                      numeric: true,
                      build: (item) => Text('${item.total} ₽')),
                ],
                actions: _actions,
                titleOf: (item) => 'Заказ №${item.id}',
                subtitleOf: (item) =>
                    '${item.customerName} · ${item.statusLabel} · ${item.total} ₽',
                isDeleted: (item) => item.isDeleted,
                onOpen: (item) => context.go('/orders/${item.id}'),
              ),
            ),
          ),
        ),
        PaginationBar(
          result: notifier.result,
          onPageChanged: (page) => _go(query.copyWith(page: page)),
          onSizeChanged: (size) => _go(query.copyWith(size: size)),
        ),
      ],
    );
  }
}
