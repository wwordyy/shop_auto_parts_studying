import '../models/shop_order.dart';

/// Сводка продаж: выручка по оплаченным заказам и экономия по картам лояльности.
class SalesReport {
  final int orderCount;
  final int paidCount;
  final int newCount;
  final int cancelledCount;
  final int paidSubtotal;
  final int paidTotal;

  const SalesReport({
    required this.orderCount,
    required this.paidCount,
    required this.newCount,
    required this.cancelledCount,
    required this.paidSubtotal,
    required this.paidTotal,
  });

  int get discountAmount => paidSubtotal - paidTotal;

  int get averagePaidCheck =>
      paidCount == 0 ? 0 : (paidTotal / paidCount).round();

  factory SalesReport.fromOrders(Iterable<ShopOrder> orders) {
    var paidCount = 0;
    var newCount = 0;
    var cancelledCount = 0;
    var paidSubtotal = 0;
    var paidTotal = 0;
    var total = 0;
    for (final order in orders) {
      if (order.isDeleted) continue;
      total += 1;
      switch (order.status) {
        case 'paid':
          paidCount += 1;
          paidSubtotal += order.subtotal;
          paidTotal += order.total;
        case 'cancelled':
          cancelledCount += 1;
        default:
          newCount += 1;
      }
    }
    return SalesReport(
      orderCount: total,
      paidCount: paidCount,
      newCount: newCount,
      cancelledCount: cancelledCount,
      paidSubtotal: paidSubtotal,
      paidTotal: paidTotal,
    );
  }
}
