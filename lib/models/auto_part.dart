class AutoPart {
  final int id;
  final String name;
  final String sku;
  final int year;
  final int price;
  final int brandId;
  final int categoryId;
  final DateTime? deletedAt;

  const AutoPart({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.price,
    required this.brandId,
    required this.categoryId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  AutoPart copyWith({
    String? name,
    String? sku,
    int? year,
    int? price,
    int? brandId,
    int? categoryId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return AutoPart(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      price: price ?? this.price,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
