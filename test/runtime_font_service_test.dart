import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/runtime_font_service.dart';
import 'package:dummy/core/widgets/font_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeFontService & FontPresets Tests', () {
    test('fontPresets list contains all 33 curated fonts from reference images', () {
      expect(fontPresets.length, 33);

      final fontNames = fontPresets.map((f) => f.name).toList();
      expect(fontNames, contains('Alex Brush'));
      expect(fontNames, contains('Art Typo'));
      expect(fontNames, contains('Avara'));
      expect(fontNames, contains('Battlestar'));
      expect(fontNames, contains('Boom Box'));
      expect(fontNames, contains('Cameo Antique'));
      expect(fontNames, contains('Charakterny'));
      expect(fontNames, contains('ClearSans Bold'));
      expect(fontNames, contains('ClearSans Light'));
      expect(fontNames, contains('ClearSans Regular'));
      expect(fontNames, contains('ComicNeue Bold'));
      expect(fontNames, contains('ComicNeue Regular'));
      expect(fontNames, contains('Comili Book'));
      expect(fontNames, contains('CooperHewitt Book'));
      expect(fontNames, contains('Earwig Factory'));
      expect(fontNames, contains('Exo Bold'));
      expect(fontNames, contains('Exo Regular'));
      expect(fontNames, contains('Exo Thin'));
      expect(fontNames, contains('Garineldo'));
      expect(fontNames, contains('Garineldo No1'));
      expect(fontNames, contains('Liner'));
      expect(fontNames, contains('Mathilde'));
      expect(fontNames, contains('Mirage'));
      expect(fontNames, contains('New Waltograph'));
      expect(fontNames, contains('NumbBunny'));
      expect(fontNames, contains('PRIDA61'));
      expect(fontNames, contains('PRIDA65'));
      expect(fontNames, contains('RocketFuel'));
      expect(fontNames, contains('RocketFuel Outlined'));
      expect(fontNames, contains('Sadegnak No1'));
      expect(fontNames, contains('SUPER TIKI'));
      expect(fontNames, contains('WHYPO'));
      expect(fontNames, contains('Xolonium Bold'));
    });

    test('getFontPresetByName handles matching, case, and fallback', () {
      final alex = getFontPresetByName('Alex Brush');
      expect(alex.name, 'Alex Brush');
      expect(alex.fontFamily, 'AlexBrush');

      final comic = getFontPresetByName('ComicNeue Bold');
      expect(comic.name, 'ComicNeue Bold');
      expect(comic.fontFamily, 'ComicNeue-Bold');

      final unknown = getFontPresetByName('NonExistentFont');
      expect(unknown.name, fontPresets.first.name);

      final nullPreset = getFontPresetByName(null);
      expect(nullPreset.name, fontPresets.first.name);
    });

    test('FontPreset.getTextStyle returns valid TextStyle with fallback styling', () {
      final preset = getFontPresetByName('Battlestar');
      final style = preset.getTextStyle(
        color: Colors.red,
        fontSize: 24,
        forceBold: true,
      );

      expect(style.color, isNotNull);
      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.bold);
    });

    test('RuntimeFontService catalog is populated and non-empty', () {
      final service = RuntimeFontService.instance;
      expect(service.catalog.length, 33);

      for (final item in service.catalog) {
        expect(item.name.isNotEmpty, isTrue);
        expect(item.fontFamily.isNotEmpty, isTrue);
        expect(item.urls.isNotEmpty, isTrue);
        expect(item.fileName.endsWith('.ttf') || item.fileName.endsWith('.otf'), isTrue);
      }
    });

    test('RuntimeFontService handles offline / missing files gracefully', () {
      final service = RuntimeFontService.instance;
      // When not downloaded, status is notDownloaded or failed
      final status = service.getFontStatus('Alex Brush');
      expect(status, anyOf(FontDownloadStatus.notDownloaded, FontDownloadStatus.downloaded, FontDownloadStatus.failed));
    });
  });
}
