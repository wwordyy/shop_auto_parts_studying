import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/validation/validators.dart';

void main() {
  group('Валидатор обязательного поля', () {
    test('пустая строка отклоняется', () {
      expect(Validators.required('', label: 'Название'), isNotNull);
      expect(Validators.required('   ', label: 'Название'), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(Validators.required('Свеча Bosch', label: 'Название'), isNull);
    });
  });

  group('артикул и имя', () {
    test('артикул обязателен и не длиннее 32 символов', () {
      expect(Validators.sku(''), isNotNull);
      expect(Validators.sku('FR7DC+'), isNull);
      expect(Validators.sku('A' * 33), isNotNull);
    });

    test('имя обрезается по длине', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('Колодки'), isNull);
      expect(Validators.name('A' * 81), isNotNull);
    });
  });

  group('числа', () {
    test('год должен попадать в диапазон', () {
      expect(Validators.range('1999', min: 2000, max: 2026, label: 'Год'),
          isNotNull);
      expect(
          Validators.range('2020', min: 2000, max: 2026, label: 'Год'), isNull);
    });

    test('цена должна быть положительной', () {
      expect(Validators.positive('0', label: 'Цена'), isNotNull);
      expect(Validators.positive('-1', label: 'Цена'), isNotNull);
      expect(Validators.positive('390', label: 'Цена'), isNull);
    });
  });

  group('контакты и пароль', () {
    test('email проверяет формат', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@shop.ru'), isNull);
    });

    test('телефон требует от 10 до 15 цифр', () {
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('+7 900 111-22-33'), isNull);
    });

    test('логин не короче трёх символов', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('buyer'), isNull);
    });
  });
}
