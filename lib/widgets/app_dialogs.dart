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
