import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/app_layout.dart';
import 'app_dialogs.dart';
import 'ellipsis_text.dart';

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
  final bool showEdit;
  final bool showDelete;
  final bool showRestore;
  final bool allowHardDelete;

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
    this.showEdit = true,
    this.showDelete = true,
    this.showRestore = true,
    this.allowHardDelete = true,
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Назад',
                  onPressed: () => _back(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: EllipsisText(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 2,
                  ),
                ),
                if (showEdit && !isDeleted)
                  IconButton(
                    tooltip: 'Изменить',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...fields,
            if (isDeleted)
              const ListTile(title: Text('Статус'), subtitle: Text('удалено')),
            if (extra.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...extra,
            ],
            const SizedBox(height: 16),
            if (isDeleted && showRestore)
              FilledButton.icon(
                onPressed: () async {
                  if (!await confirmRestore(context, title) ||
                      !context.mounted) {
                    return;
                  }
                  await onRestored();
                },
                icon: const Icon(Icons.restore),
                label: const Text('Восстановить'),
              )
            else if (!isDeleted && showDelete)
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (canDelete != null && !await canDelete!()) return;
                  if (!context.mounted) return;
                  final choice = await confirmDelete(
                    context,
                    'Запись «$title» будет удалена.',
                    allowHard: allowHardDelete,
                  );
                  if (!context.mounted || choice == DeleteChoice.cancel) return;
                  await onDeleted(choice == DeleteChoice.hard);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить'),
              ),
          ],
        ),
      ),
    );
  }
}
