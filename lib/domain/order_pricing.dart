class OrderLine {
  final int partId;
  final int quantity;
  final int unitPrice;

  const OrderLine({
    required this.partId,
    required this.quantity,
    required this.unitPrice,
  });

  int get lineTotal => quantity * unitPrice;
}

class OrderPricing {
  static int subtotal(Iterable<OrderLine> items) {
    return items.fold(0, (sum, line) => sum + line.lineTotal);
  }

  static int total({required int subtotal, required int discountPercent}) {
    final discount = discountPercent.clamp(0, 50);
    return ((subtotal * (100 - discount)) / 100).round();
  }
}
