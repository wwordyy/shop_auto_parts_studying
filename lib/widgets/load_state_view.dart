import 'package:flutter/material.dart';

import '../utils/load_status.dart';

class LoadStateView extends StatelessWidget {
  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onRetry;
  final Widget child;

  const LoadStateView({
    super.key,
    required this.status,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.emptyTitle = 'Ничего не найдено',
    this.emptySubtitle =
        'Измените поиск или фильтры — по текущим условиям записей нет.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loading || status == LoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == LoadStatus.error) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Неизвестная ошибка',
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(emptyTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(emptySubtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
