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

  Map<int, String> get _brandNames =>
      {for (final item in _brands) item.id: item.name};
  Map<int, String> get _categoryNames =>
      {for (final item in _categories) item.id: item.name};

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
    context.go(
        Uri(path: '/parts', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(AutoPart part) async {
    final choice = await confirmDelete(
      context,
      'Удалить «${part.name}»?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
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
    final choice = await confirmDelete(
      context,
      'Удалить выбранные (${notifier.selected.length})?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context,
        () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(AutoPart part) {
    final notifier = context.read<PartListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/parts/${part.id}'),
      onEdit: () => context.go('/parts/${part.id}/edit'),
      isDeleted: part.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          part.isDeleted ? perms.canRestore : perms.canSoftDelete,
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
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;
    final activeBrands = _brands.where((item) => !item.isDeleted);
    final activeCategories = _categories.where((item) => !item.isDeleted);
    final activeCars = _cars.where((item) => !item.isDeleted);

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по названию или артикулу',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          onAdd: perms.canMutate ? () => context.go('/parts/new') : null,
          filters: [
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
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const PartQuery()),
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
              child: AdaptiveCollection<AutoPart>(
                items: notifier.result.items,
                idOf: (p) => p.id,
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
                      build: (p) => EllipsisText(p.name)),
                  TableColumnSpec(
                      label: 'Артикул',
                      sortField: 'sku',
                      build: (p) => EllipsisText(p.sku)),
                  TableColumnSpec(
                      label: 'Год',
                      sortField: 'year',
                      numeric: true,
                      build: (p) => Text('${p.year}')),
                  TableColumnSpec(
                      label: 'Цена',
                      sortField: 'price',
                      numeric: true,
                      build: (p) => Text('${p.price} ₽')),
                  TableColumnSpec(
                      label: 'Бренд',
                      build: (p) =>
                          EllipsisText(_brandNames[p.brandId] ?? '—')),
                  TableColumnSpec(
                    label: 'Категории',
                    build: (p) =>
                        EllipsisText(joinNames(p.categoryIds, _categoryNames)),
                  ),
                ],
                actions: _actions,
                titleOf: (p) => p.name,
                subtitleOf: (p) => '${p.sku} · ${p.year} · ${p.price} ₽',
                isDeleted: (p) => p.isDeleted,
                onOpen: (p) => context.go('/parts/${p.id}'),
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
