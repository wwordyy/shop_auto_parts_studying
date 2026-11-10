import '../utils/json_utils.dart';

class LoyaltyCard {
  final String number;
  final DateTime issuedAt;
  final int discountPercent;
  final bool active;

  const LoyaltyCard({
    required this.number,
    required this.issuedAt,
    required this.discountPercent,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'discountPercent': discountPercent,
        'active': active,
      };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
        number: jsonString(json, 'number'),
        issuedAt: jsonDate(json, 'issuedAt') ?? DateTime(2024, 1, 1),
        discountPercent: jsonInt(json, 'discountPercent'),
        active: jsonBool(json, 'active', true),
      );
}
