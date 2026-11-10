import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_auto_parts/app.dart';

void main() {
  testWidgets('приложение открывает каталог запчастей', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ShopApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Магазин автозапчастей'), findsOneWidget);
    expect(find.text('Запчасти'), findsWidgets);
  });
}
