class Validators {
  static String? required(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) return 'Заполните поле «$label»';
    return null;
  }

  static String? minLength(String? value, int min, {String label = 'Поле'}) {
    if (value == null || value.trim().length < min) {
      return '«$label»: минимум $min символов';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String label = 'Поле'}) {
    if (value != null && value.trim().length > max) {
      return '«$label»: максимум $max символов';
    }
    return null;
  }

  static String? integer(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) return 'Заполните поле «$label»';
    if (int.tryParse(value.trim()) == null) return '«$label»: введите целое число';
    return null;
  }

  static String? range(String? value, {required int min, required int max, String label = 'Поле'}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '«$label»: введите число';
    if (parsed < min || parsed > max) return '«$label»: от $min до $max';
    return null;
  }

  static String? positive(String? value, {String label = 'Поле'}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '«$label»: введите число';
    if (parsed <= 0) return '«$label» должно быть больше 0';
    return null;
  }

  static String? nonNegative(String? value, {String label = 'Поле'}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '«$label»: введите число';
    if (parsed < 0) return '«$label» не может быть отрицательным';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Заполните поле «Email»';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) return 'Некорректный формат email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Заполните поле «Телефон»';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return '«Телефон»: от 10 до 15 цифр';
    }
    return null;
  }

  static String? sku(String? value) {
    return required(value, label: 'Артикул') ?? maxLength(value, 32, label: 'Артикул');
  }

  static String? name(String? value, {String label = 'Название', int max = 80}) {
    return required(value, label: label) ?? maxLength(value, max, label: label);
  }
}
