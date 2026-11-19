import '../utils/json_utils.dart';

class Supplier {
  final int id;
  final String name;
  final String country;
  final String phone;
  final String email;
  final int rating;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.country,
    required this.phone,
    this.email = '',
    this.rating = 3,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'phone': phone,
        'email': email,
        'rating': rating,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: jsonInt(json, 'id'),
        name: jsonString(json, 'name'),
        country: jsonString(json, 'country'),
        phone: jsonString(json, 'phone'),
        email: jsonString(json, 'email'),
        rating: jsonInt(json, 'rating', 3),
        deletedAt: jsonDate(json, 'deletedAt'),
      );
}
