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

  static AppLanguage fromCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }
}
