import '../utils/json_utils.dart';
import 'loyalty_card.dart';

export 'loyalty_card.dart';

class Customer {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LoyaltyCard card;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Customer copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    LoyaltyCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'];
    return Customer(
      id: jsonInt(json, 'id'),
      fullName: jsonString(json, 'fullName'),
      email: jsonString(json, 'email'),
      phone: jsonString(json, 'phone'),
      card: rawCard is Map<String, dynamic>
          ? LoyaltyCard.fromJson(rawCard)
          : LoyaltyCard.fromJson(<String, dynamic>{}),
      deletedAt: jsonDate(json, 'deletedAt'),
    );
  }
}
