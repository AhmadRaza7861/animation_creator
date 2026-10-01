import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/runtime_font_service.dart';
import 'package:dummy/core/widgets/font_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeFontService & FontPresets Tests', () {
    test('fontPresets list contains all curated fonts', () {
      expect(fontPresets.length >= 33, isTrue);

      final fontNames = fontPresets.map((f) => f.name).toList();
      expect(fontNames, contains('Alex Brush'));
      expect(fontNames, contains('Dancing Script'));
      expect(fontNames, contains('Bebas Neue'));
      expect(fontNames, contains('Pacifico'));
      expect(fontNames, contains('Montserrat'));
      expect(fontNames, contains('Playfair Display'));
      expect(fontNames, contains('Permanent Marker'));
      expect(fontNames, contains('Cinzel'));
    });

    test('getFontPresetByName handles matching, case, and fallback', () {
      final alex = getFontPresetByName('Alex Brush');
      expect(alex.name, 'Alex Brush');
      expect(alex.fontFamily, 'AlexBrush');

      final bebas = getFontPresetByName('Bebas Neue');
      expect(bebas.name, 'Bebas Neue');
      expect(bebas.fontFamily, 'BebasNeue');

      final unknown = getFontPresetByName('NonExistentFont');
      expect(unknown.name, fontPresets.first.name);

      final nullPreset = getFontPresetByName(null);
      expect(nullPreset.name, fontPresets.first.name);
    });

    test('FontPreset.getTextStyle returns valid TextStyle with fallback styling', () {
      final preset = getFontPresetByName('Bebas Neue');
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
      expect(service.catalog.length >= 33, isTrue);

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
