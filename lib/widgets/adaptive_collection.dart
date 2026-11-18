import 'package:flutter/material.dart';

import '../layout/app_layout.dart';
import 'entity_card_list.dart';
import 'entity_table.dart';

class AdaptiveCollection<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool>? onSelectAll;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<TableColumnSpec<T>> columns;
  final List<Widget> Function(T item)? actions;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;
  final bool Function(T item)? isDeleted;
  final ValueChanged<T>? onOpen;

  const AdaptiveCollection({
    super.key,
    required this.items,
    required this.idOf,
    required this.columns,
    required this.titleOf,
    required this.subtitleOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    if (layout.useTable) {
      return EntityTable<T>(
        items: items,
        idOf: idOf,
        selected: selected,
        onToggleSelect: onToggleSelect,
        onSelectAll: onSelectAll,
        sortField: sortField,
        sortAscending: sortAscending,
        onSort: onSort,
        columns: columns,
        actions: actions,
      );
    }
    return EntityCardList<T>(
      items: items,
      idOf: idOf,
      selected: selected,
      onToggleSelect: onToggleSelect,
      titleOf: titleOf,
      subtitleOf: subtitleOf,
      isDeleted: isDeleted,
      onOpen: onOpen,
      actions: actions,
      columns: layout.cardColumns,
    );
  }
}
