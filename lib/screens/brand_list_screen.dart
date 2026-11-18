import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/brand.dart';
import '../queries/brand_query.dart';
import '../repositories/brand_repository.dart';
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
    final brands =
        await context.read<BrandRepository>().getAll(includeDeleted: true);
    if (!mounted) return;
    setState(
        () => _countries = uniqueSorted(brands.map((item) => item.country)));
  }

  void _go(BrandQuery query) {
    final params = query.toParams();
    context.go(
        Uri(path: '/brands', queryParameters: params.isEmpty ? null : params)
            .toString());
  }

  Future<void> _delete(Brand brand) async {
    final choice = await confirmDelete(
      context,
      'Удалить «${brand.name}»?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    final notifier = context.read<BrandListNotifier>();
    await runMutation(context, () async {
      if (choice == DeleteChoice.soft) await notifier.softDelete(brand.id);
      if (choice == DeleteChoice.hard) await notifier.hardDelete(brand.id);
    });
  }

  Future<void> _deleteSelected() async {
    final notifier = context.read<BrandListNotifier>();
    final choice = await confirmDelete(
      context,
      'Удалить выбранные (${notifier.selected.length})?',
      allowHard: context.read<AuthNotifier>().permissions.canHardDelete,
    );
    if (!mounted || choice == DeleteChoice.cancel) return;
    await runMutation(context,
        () => notifier.deleteSelected(hard: choice == DeleteChoice.hard));
  }

  List<Widget> _actions(Brand brand) {
    final notifier = context.read<BrandListNotifier>();
    final perms = context.read<AuthNotifier>().permissions;
    return crudActions(
      onView: () => context.go('/brands/${brand.id}'),
      onEdit: () => context.go('/brands/${brand.id}/edit'),
      isDeleted: brand.isDeleted,
      canEdit: perms.canMutate,
      canDeleteOrRestore:
          brand.isDeleted ? perms.canRestore : perms.canSoftDelete,
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
    final perms = context.watch<AuthNotifier>().permissions;
    final query = widget.query;

    return Column(
      children: [
        ListToolbar(
          search: DebouncedSearchField(
            value: query.search,
            hintText: 'Поиск по названию или стране',
            onChanged: (value) => _go(query.copyWith(search: value)),
          ),
          onAdd: perms.canMutate ? () => context.go('/brands/new') : null,
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
            if (perms.canViewDeleted)
              FilterChip(
                label: const Text('Показать удалённые'),
                selected: query.includeDeleted,
                onSelected: (value) =>
                    _go(query.copyWith(includeDeleted: value)),
              ),
            TextButton(
              onPressed: () => _go(const BrandQuery()),
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
              child: AdaptiveCollection<Brand>(
                items: notifier.result.items,
                idOf: (b) => b.id,
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
                      build: (b) => EllipsisText(b.name)),
                  TableColumnSpec(
                      label: 'Страна',
                      sortField: 'country',
                      build: (b) => EllipsisText(b.country)),
                  TableColumnSpec(
                    label: 'Год основания',
                    sortField: 'foundedYear',
                    numeric: true,
                    build: (b) => Text('${b.foundedYear}'),
                  ),
                ],
                actions: _actions,
                titleOf: (b) => b.name,
                subtitleOf: (b) => '${b.country} · ${b.foundedYear}',
                isDeleted: (b) => b.isDeleted,
                onOpen: (b) => context.go('/brands/${b.id}'),
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
