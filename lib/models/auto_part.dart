import '../utils/json_utils.dart';

class AutoPart {
  final int id;
  final String name;
  final String sku;
  final int year;
  final int price;
  final int brandId;
  final List<int> categoryIds;
  final List<int> carModelIds;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  const AutoPart({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.price,
    required this.brandId,
    required this.categoryIds,
    required this.carModelIds,
    required this.stockTotal,
    required this.stockAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  AutoPart copyWith({
    int? id,
    String? name,
    String? sku,
    int? year,
    int? price,
    int? brandId,
    List<int>? categoryIds,
    List<int>? carModelIds,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return AutoPart(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      price: price ?? this.price,
      brandId: brandId ?? this.brandId,
      categoryIds: categoryIds ?? this.categoryIds,
      carModelIds: carModelIds ?? this.carModelIds,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'year': year,
        'price': price,
        'brandId': brandId,
        'categoryIds': categoryIds,
        'carModelIds': carModelIds,
        'stockTotal': stockTotal,
        'stockAvailable': stockAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory AutoPart.fromJson(Map<String, dynamic> json) {
    final categoryIds = jsonIntList(json, 'categoryIds');
    final legacyCategory = json['categoryId'];
    return AutoPart(
      id: jsonInt(json, 'id'),
      name: jsonString(json, 'name'),
      sku: jsonString(json, 'sku'),
      year: jsonInt(json, 'year'),
      price: jsonInt(json, 'price'),
      brandId: jsonInt(json, 'brandId'),
      categoryIds: categoryIds.isNotEmpty
          ? categoryIds
          : (legacyCategory == null ? const <int>[] : [jsonInt(json, 'categoryId')]),
      carModelIds: jsonIntList(json, 'carModelIds'),
      stockTotal: jsonInt(json, 'stockTotal'),
      stockAvailable: jsonInt(json, 'stockAvailable'),
      deletedAt: jsonDate(json, 'deletedAt'),
    );
  }
}
