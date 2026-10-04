/// Exact DZD display from integer minor units (centimes).
///
/// Contract: 100 minor units = 1 DZD. Example: `220000` → `2 200 DZD`,
/// `220050` → `2 200,50 DZD`.
/// JSON transport remains the integer decimal string; this class only formats.
/// Never uses [double] or [num] arithmetic.
class MoneyFormat {
  MoneyFormat._();

  static final _nonNegative = RegExp(r'^[0-9]+$');

  /// 100 centimes per DZD (DOMAIN_MODEL / TECH_STACK / ERD).
  static final centimesPerDzd = BigInt.from(100);

  static bool isMinorString(String raw) => _nonNegative.hasMatch(raw);

  /// Whole amounts omit the centimes: `1200` → `12 DZD`;
  /// `220000` → `2 200 DZD`; `220005` → `2 200,05 DZD`.
  static String dzd(String minor) {
    if (!isMinorString(minor)) {
      throw FormatException('Invalid money minor string', minor);
    }
    final value = BigInt.parse(minor);
    final whole = value ~/ centimesPerDzd;
    final fraction = value.remainder(centimesPerDzd);
    if (fraction == BigInt.zero) return '${_group(whole.toString())} DZD';
    return '${_group(whole.toString())},${_twoDigits(fraction)} DZD';
  }

  static final _signed = RegExp(r'^-?[0-9]+$');

  /// Signed minor units: `-250000` → `- 2 500 DZD`; `0` → `0 DZD`.
  /// Invalid input returns an empty label.
  static String dzdSigned(String? minor) {
    if (minor == null || !_signed.hasMatch(minor)) return '';
    if (!minor.startsWith('-')) return dzd(minor);
    final magnitude = minor.substring(1);
    if (BigInt.parse(magnitude) == BigInt.zero) return dzd('0');
    return '- ${dzd(magnitude)}';
  }

  /// Negated display of a non-negative deduction: `296100` → `- 2 961 DZD`.
  static String dzdDeduction(String? minor) {
    if (minor == null || !isMinorString(minor)) return '';
    if (BigInt.parse(minor) == BigInt.zero) return dzd('0');
    return '- ${dzd(minor)}';
  }

  /// Basis points → French percent label without float math:
  /// `700` → `7%`, `750` → `7,5%`, `725` → `7,25%`.
  static String basisPointsPercent(int bps) {
    final whole = bps ~/ 100;
    final rest = bps.remainder(100);
    if (rest == 0) return '$whole%';
    final digits = rest.toString().padLeft(2, '0');
    final trimmed = digits.endsWith('0') ? digits.substring(0, 1) : digits;
    return '$whole,$trimmed%';
  }

  /// Safe display helper: invalid minor strings return an empty label.
  static String dzdOrEmpty(String? minor) {
    if (minor == null || minor.isEmpty || !isMinorString(minor)) return '';
    return dzd(minor);
  }

  /// Parses a user major-unit DZD string (`12`, `12,5`, `12.50`) to minor units.
  /// Returns null when the input is empty or invalid. Uses no floating math.
  static int? majorInputToMinor(String input) {
    final raw = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final parts = raw.split('.');
    if (parts.length > 2) return null;
    final wholePart = parts[0];
    if (wholePart.isEmpty || !_nonNegative.hasMatch(wholePart)) return null;
    var fraction = '00';
    if (parts.length == 2) {
      final f = parts[1];
      if (f.isEmpty || !_nonNegative.hasMatch(f) || f.length > 2) return null;
      fraction = f.padRight(2, '0');
    }
    final whole = BigInt.parse(wholePart);
    final frac = BigInt.parse(fraction);
    return (whole * centimesPerDzd + frac).toInt();
  }

  /// Formats minor units for an editable major-unit field (`12,50`).
  static String minorToMajorInput(String minor) {
    if (!isMinorString(minor)) return '';
    final value = BigInt.parse(minor);
    final whole = value ~/ centimesPerDzd;
    final fraction = value.remainder(centimesPerDzd);
    if (fraction == BigInt.zero) return whole.toString();
    return '$whole,${_twoDigits(fraction)}';
  }

  static String _twoDigits(BigInt fraction) {
    final raw = fraction.toString();
    if (raw.length >= 2) {
      return raw;
    }
    return raw.padLeft(2, '0');
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
