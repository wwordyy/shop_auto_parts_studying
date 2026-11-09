import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/auto_part.dart';
import '../models/part_query.dart';
import '../state/part_list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class PartListScreen extends StatefulWidget {
  final PartQuery query;

  const PartListScreen({super.key, required this.query});

  @override
  State<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends State<PartListScreen> {
  static final _years = List<int>.generate(10, (i) => 2015 + i);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PartListNotifier>().applyQuery(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant PartListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<PartListNotifier>().applyQuery(widget.query);
    }
  }

  void _go(PartQuery query) {
    final params = query.toParams();
    context.go(Uri(path: '/parts', queryParameters: params.isEmpty ? null : params).toString());
  }

  Future<void> _delete(AutoPart part) async {
    final choice = await confirmDelete(context, 'Удалить «${part.name}»?');
    if (!mounted) return;
    final notifier = context.read<PartListNotifier>();
    if (choice == DeleteChoice.soft) await notifier.softDelete(part.id);
    if (choice == DeleteChoice.hard) await notifier.hardDelete(part.id);
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<PartListNotifier>();
    final choice = await confirmDelete(context, 'Удалить выбранные (${notifier.selected.length})?');
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await notifier.deleteSelected(hard: choice == DeleteChoice.hard);
  }

  List<Widget> _actions(AutoPart part) {
    final notifier = context.read<PartListNotifier>();
    return [
      IconButton(
        onPressed: () => context.go('/parts/${part.id}'),
        icon: const Icon(Icons.visibility_outlined),
      ),
      IconButton(
        onPressed: part.isDeleted
            ? () async {
                if (await confirmRestore(context, part.name) && mounted) {
                  await notifier.restore(part.id);
                }
              }
            : () => _delete(part),
        icon: Icon(part.isDeleted ? Icons.restore : Icons.delete_outline),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PartListNotifier>();
    final query = widget.query;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DebouncedSearchField(
                value: query.search,
                hintText: 'Поиск по названию или артикулу',
                onChanged: (value) => _go(query.copyWith(search: value)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterDropdown<int?>(
                    label: 'Категория',
                    value: query.categoryId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in seedCategories)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (value) => _go(query.copyWith(categoryId: value)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Бренд',
                    value: query.brandId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in seedBrands)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (value) => _go(query.copyWith(brandId: value)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Год от',
                    value: query.yearFrom,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Любой')),
                      for (final year in _years)
                        DropdownMenuItem(value: year, child: Text('$year')),
                    ],
                    onChanged: (value) => _go(query.copyWith(yearFrom: value)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Год до',
                    value: query.yearTo,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Любой')),
                      for (final year in _years)
                        DropdownMenuItem(value: year, child: Text('$year')),
                    ],
                    onChanged: (value) => _go(query.copyWith(yearTo: value)),
                  ),
                  FilterChip(
                    label: const Text('Показать удалённые'),
                    selected: query.includeDeleted,
                    onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
                  ),
                  TextButton(
                    onPressed: () => _go(const PartQuery()),
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
              if (notifier.hasSelection)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Text('Выбрано: ${notifier.selected.length}'),
                      const Spacer(),
                      TextButton(onPressed: _deleteSelected, child: const Text('Удалить выбранные')),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoadStateView(
              status: notifier.status,
              error: notifier.error,
              isEmpty: notifier.result.items.isEmpty,
              onRetry: notifier.load,
              child: wide
                  ? EntityTable<AutoPart>(
                      items: notifier.result.items,
                      idOf: (p) => p.id,
                      selected: notifier.selected,
                      onToggleSelect: notifier.toggleSelection,
                      onSelectAll: notifier.selectAllOnPage,
                      sortField: query.sortField,
                      sortAscending: query.sortAscending,
                      onSort: (field) => _go(
                        query.copyWith(
                          sortField: field,
                          sortAscending: field == query.sortField ? !query.sortAscending : true,
                        ),
                      ),
                      columns: [
                        TableColumnSpec(label: 'Название', sortField: 'name', build: (p) => Text(p.name)),
                        TableColumnSpec(label: 'Артикул', sortField: 'sku', build: (p) => Text(p.sku)),
                        TableColumnSpec(label: 'Год', sortField: 'year', numeric: true, build: (p) => Text('${p.year}')),
                        TableColumnSpec(label: 'Цена', sortField: 'price', numeric: true, build: (p) => Text('${p.price} ₽')),
                        TableColumnSpec(label: 'Бренд', build: (p) => Text(brandById(p.brandId)?.name ?? '—')),
                        TableColumnSpec(label: 'Категория', build: (p) => Text(categoryById(p.categoryId)?.name ?? '—')),
                      ],
                      actions: _actions,
                    )
                  : EntityCardList<AutoPart>(
                      items: notifier.result.items,
                      idOf: (p) => p.id,
                      selected: notifier.selected,
                      onToggleSelect: notifier.toggleSelection,
                      titleOf: (p) => p.name,
                      subtitleOf: (p) => '${p.sku} · ${p.year} · ${p.price} ₽',
                      isDeleted: (p) => p.isDeleted,
                      onOpen: (p) => context.go('/parts/${p.id}'),
                      actions: _actions,
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
