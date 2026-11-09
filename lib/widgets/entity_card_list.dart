import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        return Card(
          child: InkWell(
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
                        child: Text(
                          titleOf(item),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (isDeleted?.call(item) ?? false)
                        const Chip(label: Text('удалено')),
                    ],
                  ),
                  Text(subtitleOf(item)),
                  if (actions != null) OverflowBar(children: actions!(item)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
