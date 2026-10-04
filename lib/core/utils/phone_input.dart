class PhoneInput {
  const PhoneInput._();

  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static String formatLocal(String raw) {
    final digits = digitsOnly(raw);
    final local = _localNine(digits);
    final buffer = StringBuffer();
    for (var i = 0; i < local.length && i < 9; i++) {
      if (i == 3 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(local[i]);
    }
    return buffer.toString();
  }

  static bool isValid(String raw) => _localNine(digitsOnly(raw)).length == 9;

  static String toIdentifier(String raw) {
    final local = _localNine(digitsOnly(raw));
    return '0$local';
  }

  static String maskInternational(String raw) {
    final local = _localNine(digitsOnly(raw));
    if (local.length < 9) return '+213 $local';
    return '+213 ${local.substring(0, 3)} ** ** ${local.substring(7)}';
  }

  static String _localNine(String digits) {
    if (digits.startsWith('213') && digits.length >= 12) {
      return digits.substring(3, 12);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return digits.substring(1, 10);
    }
    return digits.length > 9 ? digits.substring(0, 9) : digits;
  }
}
