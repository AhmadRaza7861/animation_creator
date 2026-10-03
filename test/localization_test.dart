import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/localization/app_language.dart';
import 'package:dummy/core/localization/app_localizations.dart';
import 'package:dummy/core/localization/locale_provider.dart';
import 'package:dummy/core/localization/translations/translations.dart';
import 'package:dummy/core/localization/translations/en_translations.dart';
import 'package:dummy/features/settings/presentation/screens/language_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization System & Multi-Language Tests', () {
    test('All 15 supported languages are configured correctly', () {
      expect(AppLanguage.supportedLanguages.length, equals(15));

      final expectedCodes = [
        'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar', 'hi', 'tr', 'id', 'vi'
      ];

      for (final code in expectedCodes) {
        final lang = AppLanguage.fromCode(code);
        expect(lang.code, equals(code));
        expect(lang.name.isNotEmpty, isTrue);
        expect(lang.nativeName.isNotEmpty, isTrue);
        expect(lang.flagEmoji.isNotEmpty, isTrue);
        expect(lang.locale.languageCode, equals(code));
      }

      // Check Arabic RTL flag
      expect(AppLanguage.fromCode('ar').isRTL, isTrue);
      expect(AppLanguage.fromCode('en').isRTL, isFalse);
    });

    test('All 15 translation maps are registered in allTranslations and have 100% key parity', () {
      expect(allTranslations.length, equals(15));
      final enKeys = enTranslations.keys.toSet();

      for (final lang in AppLanguage.supportedLanguages) {
        final map = allTranslations[lang.code];
        expect(map, isNotNull, reason: 'Missing translation map for ${lang.code}');
        expect(map!.isNotEmpty, isTrue, reason: 'Empty translation map for ${lang.code}');
        
        // Exact key parity check against English reference
        final currentKeys = map.keys.toSet();
        final missingKeys = enKeys.difference(currentKeys);
        expect(missingKeys, isEmpty, reason: '${lang.code} is missing keys: $missingKeys');

        final extraKeys = currentKeys.difference(enKeys);
        expect(extraKeys, isEmpty, reason: '${lang.code} has extra keys: $extraKeys');
      }
    });

    test('AppLocalizations translation and parameter substitution work accurately', () {
      final loc = AppLocalizations(const Locale('en'));
      
      // Basic key lookup
      expect(loc.translate('home'), equals('Home'));
      expect(loc.translate('createProject'), equals('Create Project'));

      // Parameter replacement ({count}, {fps})
      expect(
        loc.translate('framesCount', {'count': '24'}),
        equals('24 frames'),
      );
      expect(
        loc.translate('fpsLabel', {'fps': '12'}),
        equals('12 FPS'),
      );

      // Fallback for non-existent key
      expect(
        loc.translate('non_existent_key_xyz'),
        equals('non_existent_key_xyz'),
      );
    });

    test('AppLocalizations correctly switches between languages', () {
      final enLoc = AppLocalizations(const Locale('en'));
      final esLoc = AppLocalizations(const Locale('es'));
      final frLoc = AppLocalizations(const Locale('fr'));
      final deLoc = AppLocalizations(const Locale('de'));
      final jaLoc = AppLocalizations(const Locale('ja'));
      final arLoc = AppLocalizations(const Locale('ar'));

      expect(enLoc.translate('settings'), equals('Settings'));
      expect(esLoc.translate('settings'), equals('Ajustes'));
      expect(frLoc.translate('settings'), equals('Paramètres'));
      expect(deLoc.translate('settings'), equals('Einstellungen'));
      expect(jaLoc.translate('settings'), equals('設定'));
      expect(arLoc.translate('settings'), equals('الإعدادات'));
    });

    test('Brush presets and tip shapes are correctly localized in Russian and Arabic', () {
      final ruLoc = AppLocalizations(const Locale('ru'));
      final arLoc = AppLocalizations(const Locale('ar'));

      // Brush preset names and descriptions in Russian
      expect(ruLoc.translate('brush_sketch_name'), equals('Грубый набросок'));
      expect(ruLoc.translate('brush_sketch_desc'), equals('Черновые эскизные линии от руки'));
      expect(ruLoc.translate('brush_crayon_name'), equals('Восковой мелок'));
      expect(ruLoc.translate('brush_crayon_desc'), equals('Восковая шероховатая текстура'));

      // Brush tip shapes in Russian
      expect(ruLoc.translate('tip_round_hard_label'), equals('Твердый круглый'));
      expect(ruLoc.translate('tip_round_soft_label'), equals('Мягкий круглый'));
      expect(ruLoc.translate('stamp_spray_label'), equals('Аэрограф'));

      // Brush preset names and descriptions in Arabic
      expect(arLoc.translate('brush_sketch_name'), equals('تخطيط أولي خشن'));
      expect(arLoc.translate('brush_crayon_name'), equals('قلم شمعي'));
      expect(arLoc.translate('tip_round_hard_label'), equals('دائري صلب'));
      expect(arLoc.translate('stamp_spray_label'), equals('بخاخ'));

      // Background templates and categories
      expect(ruLoc.translate('bgCatPaperGrid'), equals('Бумага и сетки'));
      expect(ruLoc.translate('bg_plain_name'), equals('Чистый лист'));
      expect(ruLoc.translate('bg_plain_desc'), equals('Чистый белый холст'));
      expect(ruLoc.translate('bg_grid_name'), equals('Клетка'));
      expect(ruLoc.translate('bg_grid_desc'), equals('Стандартная сетка в клетку'));

      // Color picker
      expect(ruLoc.translate('harmonicTonalPalette'), equals('Гармоничная тональная палитра'));
      expect(ruLoc.translate('curatedPresets'), equals('Коллекция цветов'));
      expect(ruLoc.translate('applyColor'), equals('Применить цвет'));
      expect(arLoc.translate('applyColor'), equals('تطبيق اللون'));
    });

    testWidgets('LanguageScreen renders all 15 languages and allows searching', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: LanguageScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen title and search input exist
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Check some language tiles rendered
      expect(find.text('English'), findsWidgets);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);

      // Search for "Japanese" or "日本語"
      await tester.enterText(find.byType(TextField), 'Japanese');
      await tester.pumpAndSettle();

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Español'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('Tapping a language in LanguageScreen updates the active Locale in provider', (tester) async {
      late WidgetRef ref;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, r, child) {
              ref = r;
              return const MaterialApp(
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: [Locale('en'), Locale('es')],
                home: LanguageScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default locale is 'en'
      expect(ref.read(localeProvider).languageCode, equals('en'));

      // Tap Español tile
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      // Provider locale should now be 'es'
      expect(ref.read(localeProvider).languageCode, equals('es'));
    });
  });
}
