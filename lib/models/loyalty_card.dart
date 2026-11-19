import '../utils/json_utils.dart';

class LoyaltyCard {
  final int id;
  final int customerId;
  final String customerName;
  final String number;
  final DateTime issuedAt;
  final int discountPercent;
  final bool active;
  final DateTime? deletedAt;

  const LoyaltyCard({
    this.id = 0,
    this.customerId = 0,
    this.customerName = '',
    required this.number,
    required this.issuedAt,
    required this.discountPercent,
    required this.active,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  LoyaltyCard copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? number,
    DateTime? issuedAt,
    int? discountPercent,
    bool? active,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      discountPercent: discountPercent ?? this.discountPercent,
      active: active ?? this.active,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'discountPercent': discountPercent,
        'active': active,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        id: jsonInt(json, 'id'),
        customerId: jsonInt(json, 'customerId'),
        customerName: jsonString(json, 'customerName'),
        number: jsonString(json, 'number'),
        issuedAt: jsonDate(json, 'issuedAt') ?? DateTime(2024, 1, 1),
        discountPercent: jsonInt(json, 'discountPercent'),
        active: jsonBool(json, 'active', true),
        deletedAt: jsonDate(json, 'deletedAt'),
      );
}
