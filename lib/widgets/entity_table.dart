import 'dart:math' as math;

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headingStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    final showCheckbox = widget.onToggleSelect != null;
    final showActions = widget.actions != null;
    final columnCount =
        (showCheckbox ? 1 : 0) + widget.columns.length + (showActions ? 1 : 0);

    final allSelected = widget.items.isNotEmpty &&
        widget.items.every((item) => widget.selected.contains(widget.idOf(item)));
    final someSelected =
        widget.items.any((item) => widget.selected.contains(widget.idOf(item)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = (showCheckbox ? 56.0 : 0) +
            widget.columns.length * 140.0 +
            (showActions ? 168.0 : 0);
        final parentWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth;
        final tableWidth = math.max(parentWidth, minWidth);
        final divider = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5));

        Widget cell({
          required Widget child,
          AlignmentGeometry alignment = Alignment.centerLeft,
          bool heading = false,
        }) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: heading ? 14 : 8),
            child: Align(alignment: alignment, child: child),
          );
        }

        final header = TableRow(
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          children: [
            if (showCheckbox)
              cell(
                heading: true,
                alignment: Alignment.center,
                child: Checkbox(
                  tristate: true,
                  value: allSelected ? true : (someSelected ? null : false),
                  onChanged: widget.onSelectAll == null
                      ? null
                      : (value) => widget.onSelectAll!(value ?? false),
                ),
              ),
            for (final spec in widget.columns)
              TableRowInkWell(
                onTap: spec.sortField == null || widget.onSort == null
                    ? null
                    : () => widget.onSort!(spec.sortField!),
                child: cell(
                  heading: true,
                  alignment: spec.numeric ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(spec.label, style: headingStyle),
                      if (spec.sortField != null && spec.sortField == widget.sortField) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (showActions)
              cell(
                heading: true,
                child: Text('Действия', style: headingStyle),
              ),
          ],
        );

        final rows = [
          for (final item in widget.items)
            TableRow(
              decoration: BoxDecoration(
                color: widget.selected.contains(widget.idOf(item))
                    ? scheme.primary.withValues(alpha: 0.08)
                    : null,
              ),
              children: [
                if (showCheckbox)
                  cell(
                    alignment: Alignment.center,
                    child: Checkbox(
                      value: widget.selected.contains(widget.idOf(item)),
                      onChanged: (_) => widget.onToggleSelect!(widget.idOf(item)),
                    ),
                  ),
                for (final spec in widget.columns)
                  TableRowInkWell(
                    onTap: widget.onToggleSelect == null
                        ? null
                        : () => widget.onToggleSelect!(widget.idOf(item)),
                    child: cell(
                      alignment: spec.numeric ? Alignment.centerRight : Alignment.centerLeft,
                      child: spec.build(item),
                    ),
                  ),
                if (showActions)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.actions!(item),
                      ),
                    ),
                  ),
              ],
            ),
        ];

        final table = SizedBox(
          width: tableWidth,
          child: Table(
            columnWidths: {
              if (showCheckbox) 0: const FixedColumnWidth(56),
              if (showActions) columnCount - 1: const FixedColumnWidth(168),
            },
            defaultColumnWidth: const FlexColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(horizontalInside: divider, bottom: divider),
            children: [header, ...rows],
          ),
        );

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
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }
}
