import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/car_model.dart';
import '../queries/car_model_query.dart';
import '../repositories/car_model_repository.dart';
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
      if (mounted) {
        context.read<CarModelListNotifier>().applyQuery(widget.query);
      }
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
    final items =
        await context.read<CarModelRepository>().getAll(includeDeleted: true);
    if (!mounted) return;
    setState(() => _makers = uniqueSorted(items.map((item) => item.maker)));
  }

  void _go(CarModelQuery query) {
    final params = query.toParams();
    context.go(
        Uri(path: '/cars', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(CarModel item) async {
    final choice = await confirmDelete(
      context,
      'Удалить «${item.title}»?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted) return;
    final notifier = context.read<CarModelListNotifier>();
    if (choice == DeleteChoice.cancel) return;
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(item.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(item.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<CarModelListNotifier>();
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

  List<Widget> _actions(CarModel item) {
    final notifier = context.read<CarModelListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/cars/${item.id}'),
      onEdit: () => context.go('/cars/${item.id}/edit'),
      isDeleted: item.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          item.isDeleted ? perms.canRestore : perms.canSoftDelete,
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
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по марке или модели',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          onAdd: perms.canMutate ? () => context.go('/cars/new') : null,
          filters: [
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
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const CarModelQuery()),
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
              child: AdaptiveCollection<CarModel>(
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
                      label: 'Марка',
                      sortField: 'maker',
                      build: (item) => EllipsisText(item.maker)),
                  TableColumnSpec(
                      label: 'Модель',
                      sortField: 'name',
                      build: (item) => EllipsisText(item.name)),
                  TableColumnSpec(
                    label: 'Годы',
                    sortField: 'yearFrom',
                    numeric: true,
                    build: (item) => Text('${item.yearFrom}–${item.yearTo}'),
                  ),
                ],
                actions: _actions,
                titleOf: (item) => item.title,
                subtitleOf: (item) => '${item.yearFrom}–${item.yearTo}',
                isDeleted: (item) => item.isDeleted,
                onOpen: (item) => context.go('/cars/${item.id}'),
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
