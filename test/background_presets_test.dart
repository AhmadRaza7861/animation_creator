import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/projects/presentation/widgets/preview_pattern_painter.dart';
import 'package:dummy/features/editor/presentation/screens/background_presets_screen.dart';

void main() {
  group('Background Presets & Painter Tests', () {
    test('PatternBackgroundHelper returns appropriate base colors', () {
      expect(PatternBackgroundHelper.getBaseColor(null), Colors.white);
      expect(PatternBackgroundHelper.getBaseColor('none'), Colors.white);
      expect(PatternBackgroundHelper.getBaseColor('blueprint'), const Color(0xFF1E3D59));
      expect(PatternBackgroundHelper.getBaseColor('graph'), const Color(0xFFF1F8F6));
      expect(PatternBackgroundHelper.getBaseColor('dark_cyber'), const Color(0xFF0B0F19));
      expect(PatternBackgroundHelper.getBaseColor('animation_field'), const Color(0xFFFAF7F2));
      expect(PatternBackgroundHelper.getBaseColor('chalkboard'), const Color(0xFF1B2A32));
      expect(PatternBackgroundHelper.getBaseColor('parchment'), const Color(0xFFF6EEDA));
      expect(PatternBackgroundHelper.getBaseColor('safe_area'), const Color(0xFF141A24));
      expect(PatternBackgroundHelper.getBaseColor('cinematic'), const Color(0xFF10141D));
      expect(PatternBackgroundHelper.getBaseColor('storyboard'), const Color(0xFFF1F3F5));
      expect(PatternBackgroundHelper.getBaseColor('pixel_grid'), const Color(0xFFF0F4F8));
      expect(PatternBackgroundHelper.getBaseColor('halftone'), const Color(0xFFFCFCFB));
    });

    test('PreviewPatternPainter paints all 28 patterns without errors across multiple canvas sizes', () {
      final patterns = [
        'grid',
        'dots',
        'lines',
        'checkboard',
        'isometric',
        'blueprint',
        'graph',
        'polar',
        'brick',
        'music',
        'hex',
        'cross',
        'animation_field',
        'perspective_1p',
        'perspective_2p',
        'perspective_3p',
        'speed_lines',
        'halftone',
        'storyboard',
        'rule_of_thirds',
        'safe_area',
        'dark_cyber',
        'parchment',
        'chalkboard',
        'pixel_grid',
        'iso_cubes',
        'cinematic',
        'golden_spiral',
      ];

      final sizes = [
        const Size(150, 150),
        const Size(512, 512),
        const Size(1080, 1920),
        const Size(1920, 1080),
      ];

      for (final pattern in patterns) {
        final painter = PreviewPatternPainter(pattern);
        for (final size in sizes) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder, Offset.zero & size);
          expect(() => painter.paint(canvas, size), returnsNormally);
          final picture = recorder.endRecording();
          picture.dispose();
        }
      }
    });

    testWidgets('BackgroundPresetsScreen renders with filter categories and preset selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    selectedResult = await Navigator.push<Map<String, dynamic>?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackgroundPresetsScreen(initialPattern: 'grid'),
                      ),
                    );
                  },
                  child: const Text('Open Presets'),
                ),
              );
            },
          ),
        ),
      );

      // Open presets
      await tester.tap(find.text('Open Presets'));
      await tester.pumpAndSettle();

      // Verify category tabs exist
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Perspective'), findsOneWidget);
      expect(find.text('Manga & Comic'), findsOneWidget);

      // Verify original presets are visible at the start
      expect(find.text('Plain'), findsOneWidget);
      expect(find.text('Grid Paper'), findsOneWidget);

      // Tap on Animation category
      await tester.tap(find.text('Animation'));
      await tester.pumpAndSettle();

      expect(find.text('12-Field Chart'), findsOneWidget);
      expect(find.text('Storyboard 6-Panel'), findsOneWidget);
      expect(find.text('Rule of Thirds'), findsOneWidget);

      // Select '12-Field Chart'
      await tester.tap(find.text('12-Field Chart'));
      await tester.pumpAndSettle();

      // Tap 'Select Preset'
      await tester.tap(find.text('Select Preset'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!['pattern'], 'animation_field');
    });
  });
}
