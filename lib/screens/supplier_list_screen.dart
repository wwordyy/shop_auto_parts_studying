import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/supplier.dart';
import '../queries/supplier_query.dart';
import '../repositories/supplier_repository.dart';
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

class SupplierListScreen extends StatefulWidget {
  final SupplierQuery query;

  const SupplierListScreen({super.key, required this.query});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierListNotifier>().applyQuery(widget.query);
      }
    });
    _loadCountries();
  }

  @override
  void didUpdateWidget(covariant SupplierListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<SupplierListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadCountries() async {
    final items =
        await context.read<SupplierRepository>().getAll(includeDeleted: true);
    if (!mounted) return;
    setState(
        () => _countries = uniqueSorted(items.map((item) => item.country)));
  }

  void _go(SupplierQuery query) {
    final params = query.toParams();
    context.go(
        Uri(path: '/suppliers', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(Supplier supplier) async {
    final choice = await confirmDelete(
      context,
      'Удалить «${supplier.name}»?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    final notifier = context.read<SupplierListNotifier>();
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(supplier.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(supplier.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<SupplierListNotifier>();
    final choice = await confirmDelete(
      context,
      'Удалить выбранные (${notifier.selected.length})?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    await runMutation(context,
        () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(Supplier supplier) {
    final notifier = context.read<SupplierListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/suppliers/${supplier.id}'),
      onEdit: () => context.go('/suppliers/${supplier.id}/edit'),
      isDeleted: supplier.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          supplier.isDeleted ? perms.canRestore : perms.canSoftDelete,
      onDeleteOrRestore: supplier.isDeleted
          ? () async {
              if (await confirmRestore(context, supplier.name) && mounted) {
                await notifier.restore(supplier.id);
              }
            }
          : () => _delete(supplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SupplierListNotifier>();
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по названию, стране или почте',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          onAdd: perms.canMutate ? () => context.go('/suppliers/new') : null,
          filters: [
            FilterDropdown<String?>(
              label: 'Страна',
              value: query.country,
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                for (final country in _countries)
                  DropdownMenuItem(value: country, child: Text(country)),
              ],
              onChanged: (value) => _go(query.copyWith(country: value)),
            ),
            FilterDropdown<int?>(
              label: 'Рейтинг от',
              value: query.minRating,
              items: [
                const DropdownMenuItem(value: null, child: Text('Любой')),
                for (final rating in [3, 4, 5])
                  DropdownMenuItem(value: rating, child: Text('$rating+')),
              ],
              onChanged: (value) => _go(query.copyWith(minRating: value)),
            ),
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const SupplierQuery()),
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
              child: AdaptiveCollection<Supplier>(
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
                      label: 'Название',
                      sortField: 'name',
                      build: (item) => EllipsisText(item.name)),
                  TableColumnSpec(
                      label: 'Страна',
                      sortField: 'country',
                      build: (item) => EllipsisText(item.country)),
                  TableColumnSpec(
                      label: 'Рейтинг',
                      sortField: 'rating',
                      numeric: true,
                      build: (item) => Text('${item.rating}')),
                ],
                actions: _actions,
                titleOf: (item) => item.name,
                subtitleOf: (item) =>
                    '${item.country} · рейтинг ${item.rating}',
                isDeleted: (item) => item.isDeleted,
                onOpen: (item) => context.go('/suppliers/${item.id}'),
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
