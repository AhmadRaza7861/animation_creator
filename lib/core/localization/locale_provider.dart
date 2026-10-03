import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_path_provider.dart';
import 'app_language.dart';
import 'app_localizations.dart';

class LanguageService {
  static const String _fileName = 'app_language.json';
  static Locale _cachedLocale = const Locale('en');

  static Locale get currentLocale => _cachedLocale;

  /// Load persisted locale on app startup
  static Future<Locale> loadSavedLocale() async {
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final code = data['language_code'] as String?;
        if (code != null && code.isNotEmpty) {
          _cachedLocale = Locale(code);
          AppLocalizations(_cachedLocale);
          return _cachedLocale;
        }
      }
    } catch (e) {
      debugPrint('LanguageService loadSavedLocale error: $e');
    }
    _cachedLocale = const Locale('en');
    AppLocalizations(_cachedLocale);
    return _cachedLocale;
  }

  /// Save selected locale
  static Future<void> saveLocale(Locale locale) async {
    _cachedLocale = locale;
    AppLocalizations(locale);
    try {
      final dir = await AppPathProvider.getSafeDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonEncode({
        'language_code': locale.languageCode,
        'updated_at': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('LanguageService saveLocale error: $e');
    }
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(LanguageService.currentLocale) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await LanguageService.loadSavedLocale();
    state = loaded;
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    await LanguageService.saveLocale(newLocale);
  }

  Future<void> setLanguageCode(String code) async {
    final language = AppLanguage.fromCode(code);
    await setLocale(language.locale);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
