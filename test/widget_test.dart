import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/app.dart';

void main() {
  testWidgets('приложение открывает каталог запчастей', (tester) async {
    await tester.pumpWidget(const ShopApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Магазин автозапчастей'), findsOneWidget);
    expect(find.text('Запчасти'), findsWidgets);
  });
}
