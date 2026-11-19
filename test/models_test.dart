import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/models/app_user.dart';
import 'package:shop_auto_parts/models/auto_part.dart';
import 'package:shop_auto_parts/models/brand.dart';
import 'package:shop_auto_parts/models/customer.dart';
import 'package:shop_auto_parts/models/shop_order.dart';
import 'package:shop_auto_parts/models/supplier.dart';

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

  group('Карта, поставщик и заказ', () {
    test('карта лояльности читает пустой JSON', () {
      final card = LoyaltyCard.fromJson(const {});
      expect(card.number, '');
      expect(card.active, isTrue);
      expect(card.discountPercent, 0);
    });

    test('поставщик заполняет поля из JSON', () {
      final supplier = Supplier.fromJson({
        'id': 4,
        'name': 'АвтоЕвро',
        'country': 'Россия',
        'phone': '+74951234567',
        'rating': 5,
      });
      expect(supplier.name, 'АвтоЕвро');
      expect(supplier.rating, 5);
      expect(supplier.isDeleted, isFalse);
    });

    test('заказ считает сумму позиции и подпись статуса', () {
      final order = ShopOrder.fromJson({
        'id': 1,
        'customerId': 2,
        'customerName': 'Мария',
        'status': 'paid',
        'subtotal': 1000,
        'discountPercent': 10,
        'total': 900,
        'items': [
          {
            'partId': 3,
            'name': 'Фильтр',
            'quantity': 2,
            'unitPrice': 500,
          }
        ],
      });
      expect(order.statusLabel, 'Оплачен');
      expect(order.items.single.lineTotal, 1000);
      expect(order.total, 900);
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
