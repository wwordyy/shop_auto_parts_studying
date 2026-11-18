import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/layout/app_layout.dart';

void main() {
  test('360: одна колонка, нижняя навигация, карточки', () {
    const layout = AppLayout(360);
    expect(layout.isCompact, isTrue);
    expect(layout.useBottomNav, isTrue);
    expect(layout.useTable, isFalse);
    expect(layout.cardColumns, 1);
    expect(layout.sideNavExtended, isFalse);
  });

  test('768: боковая навигация и две колонки карточек', () {
    const layout = AppLayout(768);
    expect(layout.useSideNav, isTrue);
    expect(layout.useBottomNav, isFalse);
    expect(layout.useTable, isFalse);
    expect(layout.cardColumns, 2);
    expect(layout.sideNavExtended, isFalse);
  });

  test('1280: таблицы и развёрнутая навигация', () {
    const layout = AppLayout(1280);
    expect(layout.useTable, isTrue);
    expect(layout.sideNavExtended, isTrue);
    expect(layout.useBottomNav, isFalse);
  });

  test('1920: сверхширокий режим с ограничением ширины', () {
    const layout = AppLayout(1920);
    expect(layout.isUltrawide, isTrue);
    expect(layout.useTable, isTrue);
    expect(AppLayout.maxContentWidth, lessThan(1920));
  });
}
