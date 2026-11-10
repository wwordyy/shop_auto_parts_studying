import '../utils/json_utils.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: jsonInt(json, 'id'),
        name: jsonString(json, 'name'),
        description: jsonString(json, 'description'),
        deletedAt: jsonDate(json, 'deletedAt'),
      );
}
