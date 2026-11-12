import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auto_part.dart';
import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/category.dart';
import '../queries/part_query.dart';
import '../repositories/brand_repository.dart';
import '../repositories/car_model_repository.dart';
import '../repositories/category_repository.dart';
import '../state/list_notifier.dart';
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
  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<CarModel> _cars = [];

  Map<int, String> get _brandNames => {for (final item in _brands) item.id: item.name};
  Map<int, String> get _categoryNames => {for (final item in _categories) item.id: item.name};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PartListNotifier>().applyQuery(widget.query);
    });
    _loadLookups();
  }

  @override
  void didUpdateWidget(covariant PartListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<PartListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadLookups() async {
    final brandRepo = context.read<BrandRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final carRepo = context.read<CarModelRepository>();
    final brands = await brandRepo.getAll(includeDeleted: true);
    final categories = await categoryRepo.getAll(includeDeleted: true);
    final cars = await carRepo.getAll(includeDeleted: true);
    if (!mounted) return;
    setState(() {
      _brands = brands;
      _categories = categories;
      _cars = cars;
    });
  }

  void _go(PartQuery query) {
    final params = query.toParams();
    context.go(Uri(path: '/parts', queryParameters: params.isEmpty ? null : params).toString());
  }

  Future<void> _delete(AutoPart part) async {
    final choice = await confirmDelete(context, 'Удалить «${part.name}»?');
    if (!mounted) return;
    final notifier = context.read<PartListNotifier>();
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(part.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(part.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<PartListNotifier>();
    final choice = await confirmDelete(context, 'Удалить выбранные (${notifier.selected.length})?');
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context, () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(AutoPart part) {
    final notifier = context.read<PartListNotifier>();
    return crudActions(
      onView: () => context.go('/parts/${part.id}'),
      onEdit: () => context.go('/parts/${part.id}/edit'),
      isDeleted: part.isDeleted,
      onDeleteOrRestore: part.isDeleted
          ? () async {
              if (await confirmRestore(context, part.name) && mounted) {
                await notifier.restore(part.id);
              }
            }
          : () => _delete(part),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PartListNotifier>();
    final query = widget.query;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final activeBrands = _brands.where((item) => !item.isDeleted);
    final activeCategories = _categories.where((item) => !item.isDeleted);
    final activeCars = _cars.where((item) => !item.isDeleted);

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
                      hintText: 'Поиск по названию или артикулу',
                      onChanged: (value) => _go(query.copyWith(search: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/parts/new'),
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
                  FilterDropdown<int?>(
                    label: 'Категория',
                    value: query.categoryId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in activeCategories)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (value) => _go(query.copyWith(categoryId: value)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Бренд',
                    value: query.brandId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in activeBrands)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (value) => _go(query.copyWith(brandId: value)),
                  ),
                  FilterDropdown<int?>(
                    label: 'Автомобиль',
                    value: query.carModelId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in activeCars)
                        DropdownMenuItem(value: item.id, child: Text(item.title)),
                    ],
                    onChanged: (value) => _go(query.copyWith(carModelId: value)),
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
                        TableColumnSpec(label: 'Бренд', build: (p) => Text(_brandNames[p.brandId] ?? '—')),
                        TableColumnSpec(label: 'Категории', build: (p) => Text(joinNames(p.categoryIds, _categoryNames))),
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
