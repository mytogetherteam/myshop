import 'package:my_shop/core/localization/app_localizations.dart';

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

/// Picks the best display label from EN/MM/TH fields:
/// prefers the current app language, then falls back to the first non-empty name.
String localizedDisplayName({
  String? nameEn,
  String? nameMm,
  String? nameTh,
}) {
  final lang = LocalizationService.instance.localeNotifier.value.languageCode;
  final String? preferred = switch (lang) {
    'my' => nameMm,
    'th' => nameTh,
    _ => nameEn,
  };

  if (_hasText(preferred)) return preferred!.trim();
  for (final name in [nameEn, nameMm, nameTh]) {
    if (_hasText(name)) return name!.trim();
  }
  return '';
}
