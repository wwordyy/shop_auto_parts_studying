import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_auto_parts/app.dart';
import 'package:shop_auto_parts/core/api_client.dart';
import 'package:shop_auto_parts/core/auth_api.dart';
import 'package:shop_auto_parts/state/auth_notifier.dart';

import 'support/scripted_adapter.dart';

void main() {
  testWidgets('без сессии открывается экран входа', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthNotifier(prefs);
    final dio = buildDio(auth: auth);
    auth.attachApi(AuthApi(dio));
    dio.httpClientAdapter = ScriptedAdapter((options) async {
      return jsonResponse({'message': 'Требуется вход'}, 401);
    });

    await tester.pumpWidget(ShopApp(dio: dio, auth: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
