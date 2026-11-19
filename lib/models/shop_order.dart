import '../domain/order_pricing.dart';
import '../utils/json_utils.dart';

class OrderItem {
  final int partId;
  final String name;
  final String sku;
  final int quantity;
  final int unitPrice;

  const OrderItem({
    required this.partId,
    required this.name,
    this.sku = '',
    required this.quantity,
    required this.unitPrice,
  });

  int get lineTotal => quantity * unitPrice;

  OrderLine get asLine =>
      OrderLine(partId: partId, quantity: quantity, unitPrice: unitPrice);

  Map<String, dynamic> toJson() => {
        'partId': partId,
        'name': name,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        partId: jsonInt(json, 'partId'),
        name: jsonString(json, 'name'),
        sku: jsonString(json, 'sku'),
        quantity: jsonInt(json, 'quantity', 1),
        unitPrice: jsonInt(json, 'unitPrice'),
      );
}

class ShopOrder {
  final int id;
  final int customerId;
  final String customerName;
  final String status;
  final List<OrderItem> items;
  final int subtotal;
  final int discountPercent;
  final int total;
  final DateTime? deletedAt;

  const ShopOrder({
    required this.id,
    required this.customerId,
    this.customerName = '',
    this.status = 'new',
    this.items = const [],
    this.subtotal = 0,
    this.discountPercent = 0,
    this.total = 0,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get statusLabel => switch (status) {
        'paid' => 'Оплачен',
        'cancelled' => 'Отменён',
        _ => 'Новый',
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'status': status,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <OrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(OrderItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ShopOrder(
      id: jsonInt(json, 'id'),
      customerId: jsonInt(json, 'customerId'),
      customerName: jsonString(json, 'customerName'),
      status: jsonString(json, 'status', 'new'),
      items: items,
      subtotal: jsonInt(json, 'subtotal'),
      discountPercent: jsonInt(json, 'discountPercent'),
      total: jsonInt(json, 'total'),
      deletedAt: jsonDate(json, 'deletedAt'),
    );
  }
}
