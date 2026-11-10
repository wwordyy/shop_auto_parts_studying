import 'package:flutter/material.dart';

enum DeleteChoice { cancel, soft, hard }

Future<DeleteChoice> confirmDelete(BuildContext context, String message) async {
  return await showDialog<DeleteChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить запись?'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, DeleteChoice.cancel),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, DeleteChoice.soft),
              child: const Text('Логически'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, DeleteChoice.hard),
              child: const Text('Навсегда'),
            ),
          ],
        ),
      ) ??
      DeleteChoice.cancel;
}

Future<bool> confirmRestore(BuildContext context, String name) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Восстановить запись?'),
          content: Text('«$name» снова появится в списке.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Восстановить'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> confirmDiscard(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Уйти без сохранения?'),
          content: const Text('На форме есть несохранённые изменения. Они будут потеряны.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Остаться'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Уйти'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showInfo(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}

List<Widget> crudActions({
  required VoidCallback onView,
  required VoidCallback onEdit,
  required VoidCallback onDeleteOrRestore,
  required bool isDeleted,
}) {
  return [
    IconButton(onPressed: onView, icon: const Icon(Icons.visibility_outlined)),
    IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
    IconButton(
      onPressed: onDeleteOrRestore,
      icon: Icon(isDeleted ? Icons.restore : Icons.delete_outline),
    ),
  ];
}

String joinNames(List<int> ids, Map<int, String> names) {
  if (ids.isEmpty) return '—';
  final values = [for (final id in ids) names[id] ?? '—'];
  return values.join(', ');
}

String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
