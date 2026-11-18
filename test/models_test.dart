import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/models/app_user.dart';
import 'package:shop_auto_parts/models/auto_part.dart';
import 'package:shop_auto_parts/models/brand.dart';
import 'package:shop_auto_parts/models/customer.dart';

void main() {
  group('Разбор модели AutoPart', () {
    test('отсутствующие поля не приводят к исключению', () {
      final part = AutoPart.fromJson({'id': 1});
      expect(part.name, '');
      expect(part.sku, '');
      expect(part.categoryIds, isEmpty);
      expect(part.carModelIds, isEmpty);
      expect(part.stockAvailable, 0);
      expect(part.isDeleted, isFalse);
    });

    test('принимает вложенные brand/categories/carModels', () {
      final part = AutoPart.fromJson({
        'id': 7,
        'name': 'Свеча Bosch',
        'sku': 'FR7DC+',
        'year': 2022,
        'price': 390,
        'brand': {'id': 1, 'name': 'Bosch'},
        'categories': [
          {'id': 1, 'name': 'Двигатель'},
        ],
        'carModels': [
          {'id': 6, 'name': 'Solaris', 'maker': 'Hyundai'},
        ],
        'stockTotal': 40,
        'stockAvailable': 28,
      });
      expect(part.brandId, 1);
      expect(part.categoryIds, [1]);
      expect(part.carModelIds, [6]);
    });
  });

  group('Разбор Brand и Customer', () {
    test('бренд читает пустой JSON без исключения', () {
      final brand = Brand.fromJson(const {});
      expect(brand.id, 0);
      expect(brand.name, '');
      expect(brand.foundedYear, 0);
    });

    test('клиент без карты получает пустую карту лояльности', () {
      final customer = Customer.fromJson({'id': 2, 'fullName': 'Иван'});
      expect(customer.fullName, 'Иван');
      expect(customer.card.number, '');
      expect(customer.card.active, isTrue);
    });
  });

  group('AppUser', () {
    test('неизвестная роль становится покупателем', () {
      final user =
          AppUser.fromJson({'id': 3, 'username': 'x', 'role': 'guest'});
      expect(user.role, Role.buyer);
      expect(user.displayName, 'x');
    });
  });
}
