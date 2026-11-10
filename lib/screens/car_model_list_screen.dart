import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/car_model.dart';
import '../queries/car_model_query.dart';
import '../repositories/car_model_repository.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class CarModelListScreen extends StatefulWidget {
  final CarModelQuery query;

  const CarModelListScreen({super.key, required this.query});

  @override
  State<CarModelListScreen> createState() => _CarModelListScreenState();
}

class _CarModelListScreenState extends State<CarModelListScreen> {
  List<String> _makers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CarModelListNotifier>().applyQuery(widget.query);
    });
    _loadMakers();
  }

  @override
  void didUpdateWidget(covariant CarModelListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<CarModelListNotifier>().applyQuery(widget.query);
    }
  }

  Future<void> _loadMakers() async {
    final items = await context.read<CarModelRepository>().getAll(includeDeleted: true);
    if (!mounted) return;
    setState(() => _makers = uniqueSorted(items.map((item) => item.maker)));
  }

  void _go(CarModelQuery query) {
    final params = query.toParams();
    context.go(Uri(path: '/cars', queryParameters: params.isEmpty ? null : params).toString());
  }

  Future<void> _delete(CarModel item) async {
    final choice = await confirmDelete(context, 'Удалить «${item.title}»?');
    if (!mounted) return;
    final notifier = context.read<CarModelListNotifier>();
    if (choice == DeleteChoice.soft) await notifier.softDelete(item.id);
    if (choice == DeleteChoice.hard) await notifier.hardDelete(item.id);
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<CarModelListNotifier>();
    final choice = await confirmDelete(context, 'Удалить выбранные (${notifier.selected.length})?');
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await notifier.deleteSelected(hard: choice == DeleteChoice.hard);
  }

  List<Widget> _actions(CarModel item) {
    final notifier = context.read<CarModelListNotifier>();
    return crudActions(
      onView: () => context.go('/cars/${item.id}'),
      onEdit: () => context.go('/cars/${item.id}/edit'),
      isDeleted: item.isDeleted,
      onDeleteOrRestore: item.isDeleted
          ? () async {
              if (await confirmRestore(context, item.title) && mounted) {
                await notifier.restore(item.id);
              }
            }
          : () => _delete(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CarModelListNotifier>();
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
                      hintText: 'Поиск по марке или модели',
                      onChanged: (value) => _go(query.copyWith(search: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/cars/new'),
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
                    label: 'Марка',
                    value: query.maker,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final maker in _makers)
                        DropdownMenuItem(value: maker, child: Text(maker)),
                    ],
                    onChanged: (value) => _go(query.copyWith(maker: value)),
                  ),
                  FilterChip(
                    label: const Text('Показать удалённые'),
                    selected: query.includeDeleted,
                    onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
                  ),
                  TextButton(
                    onPressed: () => _go(const CarModelQuery()),
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
                  ? EntityTable<CarModel>(
                      items: notifier.result.items,
                      idOf: (item) => item.id,
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
                        TableColumnSpec(label: 'Марка', sortField: 'maker', build: (item) => Text(item.maker)),
                        TableColumnSpec(label: 'Модель', sortField: 'name', build: (item) => Text(item.name)),
                        TableColumnSpec(
                          label: 'Годы',
                          sortField: 'yearFrom',
                          numeric: true,
                          build: (item) => Text('${item.yearFrom}–${item.yearTo}'),
                        ),
                      ],
                      actions: _actions,
                    )
                  : EntityCardList<CarModel>(
                      items: notifier.result.items,
                      idOf: (item) => item.id,
                      selected: notifier.selected,
                      onToggleSelect: notifier.toggleSelection,
                      titleOf: (item) => item.title,
                      subtitleOf: (item) => '${item.yearFrom}–${item.yearTo}',
                      isDeleted: (item) => item.isDeleted,
                      onOpen: (item) => context.go('/cars/${item.id}'),
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
