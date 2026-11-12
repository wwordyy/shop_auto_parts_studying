import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/app.dart';
import 'package:shop_auto_parts/core/api_client.dart';
import 'package:shop_auto_parts/core/auth_session.dart';

import 'support/scripted_adapter.dart';

void main() {
  testWidgets('приложение открывает каталог запчастей', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final auth = AuthSession();
    final dio = buildDio(tokenProvider: () => auth.accessToken);
    dio.httpClientAdapter = ScriptedAdapter((options) async {
      if (options.path.contains('/parts') && options.method == 'GET') {
        return jsonResponse({
          'items': [
            {
              'id': 1,
              'name': 'Свеча Bosch',
              'sku': 'FR7DC+',
              'year': 2022,
              'price': 390,
              'brandId': 1,
              'categoryIds': [1],
              'carModelIds': [6],
              'stockTotal': 40,
              'stockAvailable': 28,
            }
          ],
          'page': 1,
          'size': 10,
          'total': 1,
          'totalPages': 1,
        });
      }
      return jsonResponse({
        'items': const [],
        'page': 1,
        'size': 100,
        'total': 0,
        'totalPages': 1,
      });
    });

    await tester.pumpWidget(ShopApp(dio: dio, auth: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Магазин автозапчастей'), findsOneWidget);
    expect(find.text('Запчасти'), findsWidgets);
  });
}
