import 'package:flutter/material.dart';

import 'ellipsis_text.dart';

class EntityCardList<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;
  final bool Function(T item)? isDeleted;
  final ValueChanged<T>? onOpen;
  final List<Widget> Function(T item)? actions;
  final int columns;

  const EntityCardList({
    super.key,
    required this.items,
    required this.idOf,
    required this.titleOf,
    required this.subtitleOf,
    this.selected = const {},
    this.onToggleSelect,
    this.isDeleted,
    this.onOpen,
    this.actions,
    this.columns = 1,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = columns.clamp(1, 4);
    final rowCount = (items.length / columnCount).ceil();
    return ListView.separated(
      itemCount: rowCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, row) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < columnCount; col++) ...[
              if (col > 0) const SizedBox(width: 8),
              Expanded(child: _cell(context, row * columnCount + col)),
            ],
          ],
        );
      },
    );
  }

  Widget _cell(BuildContext context, int index) {
    if (index >= items.length) return const SizedBox.shrink();
    return _card(context, items[index]);
  }

  Widget _card(BuildContext context, T item) {
    final id = idOf(item);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        canRequestFocus: onOpen != null,
        onTap: onOpen == null ? null : () => onOpen!(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onToggleSelect != null)
                    Checkbox(
                      value: selected.contains(id),
                      onChanged: (_) => onToggleSelect!(id),
                    ),
                  Expanded(
                    child: EllipsisText(
                      titleOf(item),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isDeleted?.call(item) ?? false)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(label: Text('удалено')),
                    ),
                ],
              ),
              EllipsisText(subtitleOf(item), maxLines: 2),
              if (actions != null) OverflowBar(children: actions!(item)),
            ],
          ),
        ),
      ),
    );
  }
}
