import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatefulWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool>? onSelectAll;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      for (final spec in widget.columns)
        DataColumn(
          label: Text(spec.label),
          numeric: spec.numeric,
          onSort: spec.sortField == null || widget.onSort == null
              ? null
              : (_, __) => widget.onSort!(spec.sortField!),
        ),
      if (widget.actions != null) const DataColumn(label: Text('Действия')),
    ];

    int? sortIndex;
    for (var i = 0; i < widget.columns.length; i++) {
      if (widget.columns[i].sortField == widget.sortField) {
        sortIndex = i;
        break;
      }
    }

    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vertical,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: (widget.columns.length + 2) * 140,
              ),
              child: DataTable(
                sortColumnIndex: sortIndex,
                sortAscending: widget.sortAscending,
                showCheckboxColumn: widget.onToggleSelect != null,
                onSelectAll: widget.onSelectAll == null
                    ? null
                    : (checked) => widget.onSelectAll!(checked ?? false),
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                columns: columns,
                rows: [
                  for (final item in widget.items)
                    DataRow(
                      selected: widget.selected.contains(widget.idOf(item)),
                      onSelectChanged: widget.onToggleSelect == null
                          ? null
                          : (_) => widget.onToggleSelect!(widget.idOf(item)),
                      cells: [
                        for (final spec in widget.columns)
                          DataCell(spec.build(item)),
                        if (widget.actions != null)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!(item),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
