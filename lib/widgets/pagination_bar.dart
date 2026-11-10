import 'package:flutter/material.dart';

import '../utils/page_result.dart';

class PaginationBar extends StatelessWidget {
  static const pageSizes = [10, 25, 50];

  final PageResult<dynamic> result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Первая страница',
              onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              tooltip: 'Предыдущая',
              onPressed: result.hasPrevious
                  ? () => onPageChanged(result.page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Страница ${result.page} из ${result.totalPages} · ${result.total} записей',
            ),
            IconButton(
              tooltip: 'Следующая',
              onPressed:
                  result.hasNext ? () => onPageChanged(result.page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Последняя страница',
              onPressed: result.hasNext
                  ? () => onPageChanged(result.totalPages)
                  : null,
              icon: const Icon(Icons.last_page),
            ),
            const SizedBox(width: 12),
            const Text('На странице:'),
            DropdownButton<int>(
              value: pageSizes.contains(result.size) ? result.size : 10,
              items: [
                for (final size in pageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (value) {
                if (value != null) onSizeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
