import 'package:flutter/material.dart';

/// Model representing a supported language in Clipax.
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final bool isRTL;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    this.isRTL = false,
  });

  Locale get locale => Locale(code);

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
    ),
    AppLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flagEmoji: '🇪🇸',
    ),
    AppLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
    ),
    AppLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flagEmoji: '🇩🇪',
    ),
    AppLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flagEmoji: '🇮🇹',
    ),
    AppLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flagEmoji: '🇵🇹',
    ),
    AppLanguage(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flagEmoji: '🇷🇺',
    ),
    AppLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
    ),
    AppLanguage(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
    ),
    AppLanguage(
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
      flagEmoji: '🇨🇳',
    ),
    AppLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flagEmoji: '🇸🇦',
      isRTL: true,
    ),
    AppLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flagEmoji: '🇮🇳',
    ),
    AppLanguage(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      flagEmoji: '🇹🇷',
    ),
    AppLanguage(
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flagEmoji: '🇮🇩',
    ),
    AppLanguage(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
    ),
  ];

  static bool isSupported(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    final normalized = code.trim().toLowerCase().split('_').first.split('-').first;
    return supportedLanguages.any((lang) => lang.code.toLowerCase() == normalized);
  }

  static AppLanguage fromCode(String code) {
    final normalized = code.trim().toLowerCase().split('_').first.split('-').first;
    return supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == normalized,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Resolves the device locale to a supported AppLanguage locale.
  /// If the device locale is supported in our app, uses it.
  /// If not localized in our app, falls back to English ('en').
  static Locale resolveLocale(Locale? locale) {
    if (locale == null) return const Locale('en');
    final code = locale.languageCode.trim().toLowerCase().split('_').first.split('-').first;
    final match = supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code,
      orElse: () => supportedLanguages.first,
    );
    return match.locale;
  }
}
