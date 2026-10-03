import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_language.dart';
import 'translations/translations.dart';
import 'translations/en_translations.dart';

class AppLocalizations {
  final Locale locale;
  static AppLocalizations? _current;

  AppLocalizations(this.locale) {
    _current = this;
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static AppLocalizations get current {
    return _current ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static List<Locale> get supportedLocales {
    return AppLanguage.supportedLanguages.map((lang) => lang.locale).toList();
  }

  /// Translate a key into the active language with optional parameter substitution (e.g. {count}, {fps})
  String translate(String key, [Map<String, String>? args]) {
    final languageCode = locale.languageCode.toLowerCase();
    final translations = allTranslations[languageCode] ?? enTranslations;
    String value = translations[key] ?? enTranslations[key] ?? key;

    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }

  /// Global static translation shortcut with current active locale
  static String tr(String key, [Map<String, String>? args]) {
    return current.translate(key, args);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.supportedLanguages.any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  /// Convenient syntax: `context.tr('myKey', {'count': '5'})`
  String tr(String key, [Map<String, String>? args]) {
    final loc = AppLocalizations.of(this);
    if (loc != null) {
      return loc.translate(key, args);
    }
    return AppLocalizations.tr(key, args);
  }

  AppLocalizations get l10n => AppLocalizations.of(this) ?? AppLocalizations.current;
}
