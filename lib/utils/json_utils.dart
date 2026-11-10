int jsonInt(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String jsonString(Map<String, dynamic> json, String key, [String fallback = '']) {
  final value = json[key];
  if (value == null) return fallback;
  return value.toString();
}

bool jsonBool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return fallback;
}

List<int> jsonIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) return const [];
  final result = <int>[];
  for (final item in value) {
    if (item is int) {
      result.add(item);
    } else if (item is num) {
      result.add(item.toInt());
    } else if (item is String) {
      final parsed = int.tryParse(item);
      if (parsed != null) result.add(parsed);
    }
  }
  return result;
}

DateTime? jsonDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
