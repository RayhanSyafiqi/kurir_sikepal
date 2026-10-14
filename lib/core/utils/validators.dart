class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    if (!value.contains('@') || !value.contains('.')) {
      return 'Email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? positiveInt(String? value, {int? max}) {
    if (value == null || value.isEmpty) return 'Wajib diisi';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Harus angka positif';
    if (max != null && n > max) return 'Maksimal $max';
    return null;
  }
}
