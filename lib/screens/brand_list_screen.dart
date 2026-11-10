import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/brand.dart';
import '../queries/brand_query.dart';
import '../repositories/brand_repository.dart';
import '../repositories/part_repository.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class BrandListScreen extends StatefulWidget {
  final BrandQuery query;

  const BrandListScreen({super.key, required this.query});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BrandListNotifier>().applyQuery(widget.query);
    });
    _loadCountries();
  }

  @override
  void didUpdateWidget(covariant BrandListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<BrandListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadCountries() async {
    final brands = await context.read<BrandRepository>().getAll(includeDeleted: true);
    if (!mounted) return;
    setState(() => _countries = uniqueSorted(brands.map((item) => item.country)));
  }

  void _go(BrandQuery query) {
    final params = query.toParams();
    context.go(Uri(path: '/brands', queryParameters: params.isEmpty ? null : params).toString());
  }

  Future<bool> _canDelete(Brand brand) async {
    final count = await context.read<PartRepository>().countByBrand(brand.id);
    if (count == 0) return true;
    if (mounted) {
      await showInfo(
        context,
        'Удаление невозможно',
        'Бренд «${brand.name}» нельзя удалить: на него ссылаются $count запчастей.',
      );
    }
    return false;
  }

  Future<void> _delete(Brand brand) async {
    if (!await _canDelete(brand)) return;
    if (!mounted) return;
    final choice = await confirmDelete(context, 'Удалить «${brand.name}»?');
    if (!mounted) return;
    final notifier = context.read<BrandListNotifier>();
    if (choice == DeleteChoice.soft) await notifier.softDelete(brand.id);
    if (choice == DeleteChoice.hard) await notifier.hardDelete(brand.id);
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<BrandListNotifier>();
    final selected = notifier.result.items.where((item) => notifier.selected.contains(item.id)).toList();
    for (final brand in selected) {
      if (!await _canDelete(brand)) return;
      if (!mounted) return;
    }
    final choice = await confirmDelete(context, 'Удалить выбранные (${notifier.selected.length})?');
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await notifier.deleteSelected(hard: choice == DeleteChoice.hard);
  }

  List<Widget> _actions(Brand brand) {
    final notifier = context.read<BrandListNotifier>();
    return crudActions(
      onView: () => context.go('/brands/${brand.id}'),
      onEdit: () => context.go('/brands/${brand.id}/edit'),
      isDeleted: brand.isDeleted,
      onDeleteOrRestore: brand.isDeleted
          ? () async {
              if (await confirmRestore(context, brand.name) && mounted) {
                await notifier.restore(brand.id);
              }
            }
          : () => _delete(brand),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BrandListNotifier>();
    final query = widget.query;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DebouncedSearchField(
                      value: query.search,
                      hintText: 'Поиск по названию или стране',
                      onChanged: (value) => _go(query.copyWith(search: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/brands/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
                  FilterChip(
                    label: const Text('Показать удалённые'),
                    selected: query.includeDeleted,
                    onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
                  ),
                  TextButton(
                    onPressed: () => _go(const BrandQuery()),
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
                  ? EntityTable<Brand>(
                      items: notifier.result.items,
                      idOf: (b) => b.id,
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
                        TableColumnSpec(label: 'Название', sortField: 'name', build: (b) => Text(b.name)),
                        TableColumnSpec(label: 'Страна', sortField: 'country', build: (b) => Text(b.country)),
                        TableColumnSpec(
                          label: 'Год основания',
                          sortField: 'foundedYear',
                          numeric: true,
                          build: (b) => Text('${b.foundedYear}'),
                        ),
                      ],
                      actions: _actions,
                    )
                  : EntityCardList<Brand>(
                      items: notifier.result.items,
                      idOf: (b) => b.id,
                      selected: notifier.selected,
                      onToggleSelect: notifier.toggleSelection,
                      titleOf: (b) => b.name,
                      subtitleOf: (b) => '${b.country} · ${b.foundedYear}',
                      isDeleted: (b) => b.isDeleted,
                      onOpen: (b) => context.go('/brands/${b.id}'),
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
