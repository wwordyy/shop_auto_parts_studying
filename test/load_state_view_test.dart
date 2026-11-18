import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/utils/load_status.dart';
import 'package:shop_auto_parts/widgets/load_state_view.dart';

void main() {
  testWidgets('отображает состояние загрузки', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoadStateView(
          status: LoadStatus.loading,
          child: Text('данные'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('данные'), findsNothing);
  });

  testWidgets('отображает пустой результат', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoadStateView(
          status: LoadStatus.success,
          isEmpty: true,
          emptyTitle: 'Запчастей не найдено',
          child: Text('таблица'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Запчастей не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('таблица'), findsNothing);
  });

  testWidgets('отображает ошибку с кнопкой повтора', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoadStateView(
          status: LoadStatus.error,
          error: 'Сервер недоступен. Проверьте соединение.',
          onRetry: () => retried = true,
          child: const Text('таблица'),
        ),
      ),
    );
    expect(find.textContaining('Сервер недоступен'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });
}
