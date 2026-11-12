import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../queries/category_query.dart';
import '../state/list_notifier.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_view.dart';
import '../widgets/pagination_bar.dart';

class CategoryListScreen extends StatefulWidget {
  final CategoryQuery query;

  const CategoryListScreen({super.key, required this.query});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryListNotifier>().applyQuery(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant CategoryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      context.read<CategoryListNotifier>().applyQuery(widget.query);
    }
  }

  void _go(CategoryQuery query) {
    final params = query.toParams();
    context.go(Uri(path: '/categories', queryParameters: params.isEmpty ? null : params).toString());
  }

  Future<void> _delete(Category item) async {
    final choice = await confirmDelete(context, 'Удалить «${item.name}»?');
    if (!mounted) return;
    final notifier = context.read<CategoryListNotifier>();
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(item.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(item.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<CategoryListNotifier>();
    final choice = await confirmDelete(context, 'Удалить выбранные (${notifier.selected.length})?');
    if (!mounted) return;
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context, () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(Category item) {
    final notifier = context.read<CategoryListNotifier>();
    return crudActions(
      onView: () => context.go('/categories/${item.id}'),
      onEdit: () => context.go('/categories/${item.id}/edit'),
      isDeleted: item.isDeleted,
      onDeleteOrRestore: item.isDeleted
          ? () async {
              if (await confirmRestore(context, item.name) && mounted) {
                await notifier.restore(item.id);
              }
            }
          : () => _delete(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CategoryListNotifier>();
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
                      hintText: 'Поиск по названию или описанию',
                      onChanged: (value) => _go(query.copyWith(search: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/categories/new'),
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
                  FilterChip(
                    label: const Text('Показать удалённые'),
                    selected: query.includeDeleted,
                    onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
                  ),
                  TextButton(
                    onPressed: () => _go(const CategoryQuery()),
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
                  ? EntityTable<Category>(
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
                        TableColumnSpec(label: 'Название', sortField: 'name', build: (item) => Text(item.name)),
                        TableColumnSpec(label: 'Описание', build: (item) => Text(item.description)),
                      ],
                      actions: _actions,
                    )
                  : EntityCardList<Category>(
                      items: notifier.result.items,
                      idOf: (item) => item.id,
                      selected: notifier.selected,
                      onToggleSelect: notifier.toggleSelection,
                      titleOf: (item) => item.name,
                      subtitleOf: (item) => item.description,
                      isDeleted: (item) => item.isDeleted,
                      onOpen: (item) => context.go('/categories/${item.id}'),
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
