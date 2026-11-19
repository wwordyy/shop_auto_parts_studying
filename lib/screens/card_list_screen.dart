import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../queries/card_query.dart';
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

class CardListScreen extends StatefulWidget {
  final CardQuery query;

  const CardListScreen({super.key, required this.query});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CardListNotifier>().applyQuery(widget.query);
    });
    _loadCustomers();
  }

  @override
  void didUpdateWidget(covariant CardListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<CardListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadCustomers() async {
    final items = await context.read<CustomerRepository>().getAll();
    if (!mounted) return;
    setState(() => _customers = items);
  }

  void _go(CardQuery query) {
    final params = query.toParams();
    context.go(
        Uri(path: '/cards', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(LoyaltyCard card) async {
    final choice = await confirmDelete(
      context,
      'Удалить карту «${card.number}»?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    final notifier = context.read<CardListNotifier>();
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(card.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(card.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<CardListNotifier>();
    final choice = await confirmDelete(
      context,
      'Удалить выбранные (${notifier.selected.length})?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    await runMutation(context,
        () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(LoyaltyCard card) {
    final notifier = context.read<CardListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/cards/${card.id}'),
      onEdit: () => context.go('/cards/${card.id}/edit'),
      isDeleted: card.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          card.isDeleted ? perms.canRestore : perms.canSoftDelete,
      onDeleteOrRestore: card.isDeleted
          ? () async {
              if (await confirmRestore(context, card.number) && mounted) {
                await notifier.restore(card.id);
              }
            }
          : () => _delete(card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CardListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по номеру карты',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          onAdd: perms.canMutate ? () => context.go('/cards/new') : null,
          filters: [
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
            FilterDropdown<bool?>(
              label: 'Статус',
              value: query.active,
              items: const [
                DropdownMenuItem(value: null, child: Text('Все')),
                DropdownMenuItem(value: true, child: Text('Активна')),
                DropdownMenuItem(value: false, child: Text('Неактивна')),
              ],
              onChanged: (value) => _go(query.copyWith(active: value)),
            ),
            FilterDropdown<int?>(
              label: 'Скидка от',
              value: query.minDiscount,
              items: const [
                DropdownMenuItem(value: null, child: Text('Любая')),
                DropdownMenuItem(value: 5, child: Text('5%')),
                DropdownMenuItem(value: 10, child: Text('10%')),
              ],
              onChanged: (value) => _go(query.copyWith(minDiscount: value)),
            ),
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const CardQuery()),
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
              onRetry: notifier.load,
              child: AdaptiveCollection<LoyaltyCard>(
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
                      label: 'Номер',
                      sortField: 'number',
                      build: (item) => EllipsisText(item.number)),
                  TableColumnSpec(
                      label: 'Клиент',
                      build: (item) => EllipsisText(item.customerName)),
                  TableColumnSpec(
                      label: 'Скидка',
                      sortField: 'discountPercent',
                      numeric: true,
                      build: (item) => Text('${item.discountPercent}%')),
                  TableColumnSpec(
                      label: 'Активна',
                      build: (item) => Text(item.active ? 'да' : 'нет')),
                ],
                actions: _actions,
                titleOf: (item) => item.number,
                subtitleOf: (item) =>
                    '${item.customerName} · ${item.discountPercent}%',
                isDeleted: (item) => item.isDeleted,
                onOpen: (item) => context.go('/cards/${item.id}'),
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
