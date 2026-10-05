import 'dart:ui' as ui;

/// Supported Merchant UI locales.
final supportedLanguageCodes = ['fr', 'ar'];

/// Sanitize a language code to `fr` or `ar`.
String sanitizeLanguageCode(String? code) => code == 'ar' ? 'ar' : 'fr';

/// When no saved preference exists, use a supported platform locale or French.
String resolveInitialLanguageCode({String? stored, ui.Locale? platform}) {
  if (stored == 'ar' || stored == 'fr') return stored!;
  final device = platform ?? ui.PlatformDispatcher.instance.locale;
  final code = device.languageCode.toLowerCase();
  if (code == 'ar') return 'ar';
  if (code == 'fr') return 'fr';
  return 'fr';
}
