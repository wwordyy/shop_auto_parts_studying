import '../utils/json_utils.dart';

class CarModel {
  final int id;
  final String name;
  final String maker;
  final int yearFrom;
  final int yearTo;
  final DateTime? deletedAt;

  const CarModel({
    required this.id,
    required this.name,
    required this.maker,
    required this.yearFrom,
    required this.yearTo,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get title => '$maker $name';

  CarModel copyWith({
    int? id,
    String? name,
    String? maker,
    int? yearFrom,
    int? yearTo,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      maker: maker ?? this.maker,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'maker': maker,
        'yearFrom': yearFrom,
        'yearTo': yearTo,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        id: jsonInt(json, 'id'),
        name: jsonString(json, 'name'),
        maker: jsonString(json, 'maker'),
        yearFrom: jsonInt(json, 'yearFrom'),
        yearTo: jsonInt(json, 'yearTo'),
        deletedAt: jsonDate(json, 'deletedAt'),
      );
}
