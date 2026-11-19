import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/domain/order_pricing.dart';
import 'package:shop_auto_parts/domain/sales_report.dart';
import 'package:shop_auto_parts/models/shop_order.dart';

void main() {
  group('расчёт заказа со скидкой карты', () {
    const lines = [
      OrderLine(partId: 1, quantity: 2, unitPrice: 500),
      OrderLine(partId: 2, quantity: 1, unitPrice: 1000),
    ];

    test('сумма позиций без скидки', () {
      expect(OrderPricing.subtotal(lines), 2000);
    });

    test('скидка 10% уменьшает сумму к оплате', () {
      expect(
        OrderPricing.total(subtotal: 2000, discountPercent: 10),
        1800,
      );
    });

    test('скидка ограничена 50 процентами', () {
      expect(
        OrderPricing.total(subtotal: 2000, discountPercent: 90),
        1000,
      );
    });

    test('нулевая и отрицательная скидка не меняют сумму', () {
      expect(OrderPricing.total(subtotal: 2000, discountPercent: 0), 2000);
      expect(OrderPricing.total(subtotal: 2000, discountPercent: -5), 2000);
    });
  });

  group('отчёт по продажам', () {
    test('считает выручку и скидки только по оплаченным заказам', () {
      final report = SalesReport.fromOrders([
        const ShopOrder(
          id: 1,
          customerId: 1,
          status: 'paid',
          subtotal: 2000,
          discountPercent: 10,
          total: 1800,
        ),
        const ShopOrder(
          id: 2,
          customerId: 1,
          status: 'new',
          subtotal: 5000,
          total: 5000,
        ),
        const ShopOrder(
          id: 3,
          customerId: 2,
          status: 'cancelled',
          subtotal: 1000,
          total: 1000,
        ),
        ShopOrder(
          id: 4,
          customerId: 1,
          status: 'paid',
          subtotal: 1000,
          total: 1000,
          deletedAt: DateTime(2024),
        ),
      ]);
      expect(report.orderCount, 3);
      expect(report.paidCount, 1);
      expect(report.paidTotal, 1800);
      expect(report.discountAmount, 200);
      expect(report.averagePaidCheck, 1800);
    });
  });
}
