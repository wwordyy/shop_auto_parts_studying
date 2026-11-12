import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_dialogs.dart';

class EntityDetail extends StatelessWidget {
  final String title;
  final String fallbackPath;
  final bool isDeleted;
  final List<Widget> fields;
  final VoidCallback onEdit;
  final Future<void> Function() onRestored;
  final Future<void> Function(bool hard) onDeleted;
  final Future<bool> Function()? canDelete;
  final List<Widget> extra;

  const EntityDetail({
    super.key,
    required this.title,
    required this.fallbackPath,
    required this.isDeleted,
    required this.fields,
    required this.onEdit,
    required this.onRestored,
    required this.onDeleted,
    this.canDelete,
    this.extra = const [],
  });

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            IconButton(onPressed: () => _back(context), icon: const Icon(Icons.arrow_back)),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        ...fields,
        if (isDeleted) const ListTile(title: Text('Статус'), subtitle: Text('удалено')),
        if (extra.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...extra,
        ],
        const SizedBox(height: 16),
        if (isDeleted)
          FilledButton.icon(
            onPressed: () async {
              if (!await confirmRestore(context, title) || !context.mounted) return;
              await onRestored();
            },
            icon: const Icon(Icons.restore),
            label: const Text('Восстановить'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: () async {
              if (canDelete != null && !await canDelete!()) return;
              if (!context.mounted) return;
              final choice = await confirmDelete(context, 'Запись «$title» будет удалена.');
              if (!context.mounted || choice == DeleteChoice.cancel) return;
              await onDeleted(choice == DeleteChoice.hard);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Удалить'),
          ),
      ],
    );
  }
}
