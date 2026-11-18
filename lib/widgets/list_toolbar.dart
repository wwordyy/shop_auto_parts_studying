import 'package:flutter/material.dart';

import '../layout/app_layout.dart';

class ListToolbar extends StatelessWidget {
  final Widget search;
  final VoidCallback? onAdd;
  final String addLabel;
  final List<Widget> filters;
  final Widget? selectionBar;

  const ListToolbar({
    super.key,
    required this.search,
    required this.filters,
    this.onAdd,
    this.addLabel = 'Добавить',
    this.selectionBar,
  });

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.of(context).isCompact;
    final addButton = onAdd == null
        ? null
        : FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            search,
            if (addButton != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: addButton),
            ],
          ] else
            Row(
              children: [
                Expanded(child: search),
                if (addButton != null) ...[
                  const SizedBox(width: 12),
                  addButton,
                ],
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: filters,
          ),
          if (selectionBar != null) selectionBar!,
        ],
      ),
    );
  }
}

class SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;

  const SelectionBar({super.key, required this.count, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text('Выбрано: $count'),
          TextButton(
            onPressed: onDelete,
            child: const Text('Удалить выбранные'),
          ),
        ],
      ),
    );
  }
}
