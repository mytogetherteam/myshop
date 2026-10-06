import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/localization/language_policy_client.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'my', 'th'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class LocalizationService {
  static final LocalizationService instance = LocalizationService._();

  LocalizationService._();

  final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('en'));

  Timer? _policyTimer;
  int _policyGeneration = 0;

  Future<void> init() async {
    final savedLang = await StorageService.instance.getLanguage();
    localeNotifier.value = Locale(savedLang);
    await refreshLanguagePolicy();
    _policyTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      refreshLanguagePolicy();
    });
  }

  /// When an admin turns this app's switch on, remember the current language
  /// and set Thai. People can change it afterward. Turning the switch off
  /// restores the language from before that switch was turned on.
  /// A failed request leaves the current language alone.
  Future<void> refreshLanguagePolicy() async {
    final generation = ++_policyGeneration;
    final push = await LanguagePolicyClient.fetch('shop');
    if (generation != _policyGeneration || push == null) return;
    final storage = StorageService.instance;
    try {
      if (!push.enabled) {
        final before = await storage.getLanguageBeforeForce();
        if (generation != _policyGeneration || before == null) return;
        if (before != 'en' && before != 'my' && before != 'th') return;
        if (localeNotifier.value.languageCode != before) {
          localeNotifier.value = Locale(before);
        }
        await storage.saveLanguage(before);
        await storage.clearLanguageForce();
        return;
      }
      final token = push.at;
      if (token == null || token.isEmpty) return;
      final seen = await storage.getLanguageForceToken();
      if (generation != _policyGeneration || seen == token) return;
      if (await storage.getLanguageBeforeForce() == null) {
        await storage.setLanguageBeforeForce(await storage.getLanguage());
      }
      if (localeNotifier.value.languageCode != 'th') {
        localeNotifier.value = const Locale('th');
      }
      await storage.saveLanguage('th');
      await storage.setLanguageForceToken(token);
    } catch (_) {}
  }

  Future<void> changeLanguage(String langCode) async {
    await StorageService.instance.saveLanguage(langCode);
    localeNotifier.value = Locale(langCode);
  }
}
