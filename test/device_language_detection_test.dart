import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/localization/app_language.dart';
import 'package:dummy/core/localization/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Device Language Detection & Fallback Tests', () {
    test('Supported language codes are recognized correctly', () {
      expect(AppLanguage.isSupported('en'), isTrue);
      expect(AppLanguage.isSupported('es'), isTrue);
      expect(AppLanguage.isSupported('fr'), isTrue);
      expect(AppLanguage.isSupported('de'), isTrue);
      expect(AppLanguage.isSupported('ar'), isTrue);
      expect(AppLanguage.isSupported('zh'), isTrue);
      expect(AppLanguage.isSupported('ja'), isTrue);
      expect(AppLanguage.isSupported('ko'), isTrue);
      expect(AppLanguage.isSupported('pt'), isTrue);
      expect(AppLanguage.isSupported('ru'), isTrue);
      expect(AppLanguage.isSupported('hi'), isTrue);
      expect(AppLanguage.isSupported('tr'), isTrue);
      expect(AppLanguage.isSupported('id'), isTrue);
      expect(AppLanguage.isSupported('vi'), isTrue);
      expect(AppLanguage.isSupported('it'), isTrue);
    });

    test('Unsupported language codes return false', () {
      expect(AppLanguage.isSupported('el'), isFalse); // Greek
      expect(AppLanguage.isSupported('pl'), isFalse); // Polish
      expect(AppLanguage.isSupported('sv'), isFalse); // Swedish
      expect(AppLanguage.isSupported('nl'), isFalse); // Dutch
      expect(AppLanguage.isSupported(''), isFalse);
      expect(AppLanguage.isSupported(null), isFalse);
    });

    test('resolveLocale maps supported locales directly', () {
      expect(AppLanguage.resolveLocale(const Locale('es', 'ES')), const Locale('es'));
      expect(AppLanguage.resolveLocale(const Locale('fr', 'FR')), const Locale('fr'));
      expect(AppLanguage.resolveLocale(const Locale('ar', 'SA')), const Locale('ar'));
      expect(AppLanguage.resolveLocale(const Locale('de', 'DE')), const Locale('de'));
      expect(AppLanguage.resolveLocale(const Locale('ja', 'JP')), const Locale('ja'));
    });

    test('resolveLocale falls back to en for unsupported locales', () {
      expect(AppLanguage.resolveLocale(const Locale('el', 'GR')), const Locale('en'));
      expect(AppLanguage.resolveLocale(const Locale('pl', 'PL')), const Locale('en'));
      expect(AppLanguage.resolveLocale(const Locale('sv', 'SE')), const Locale('en'));
      expect(AppLanguage.resolveLocale(const Locale('nl', 'NL')), const Locale('en'));
      expect(AppLanguage.resolveLocale(null), const Locale('en'));
    });

    test('fromCode maps unknown code to English default', () {
      final lang = AppLanguage.fromCode('xyz_unknown');
      expect(lang.code, 'en');
      expect(lang.name, 'English');
    });
  });
}
