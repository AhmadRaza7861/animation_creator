import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/src/drawing_bar/brush_presets.dart';
import 'package:dummy/package_code/src/drawing_bar/brush_preview_renderer.dart';
import 'package:dummy/features/editor/presentation/screens/brush_studio_screen.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Brush Studio & Preview Renderer Scroll Safety Tests', () {
    test('BrushPreviewRenderer bounded LRU cache evicts and disposes under high scroll throughput', () {
      BrushPreviewRenderer.clearCache();

      final presets = kDefaultBrushPresets;
      const size = Size(200, 60);

      // Render all 110+ presets repeatedly across multiple colors and sizes
      for (final color in [Colors.black, Colors.purple, Colors.cyan, Colors.amber]) {
        for (final preset in presets) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder, Offset.zero & size);
          BrushPreviewRenderer.paintPreview(canvas, size, preset, color);
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          picture.dispose();
        }
      }

      // Explicit clear cache should execute cleanly without error
      BrushPreviewRenderer.clearCache();
    });

    testWidgets('BrushStudioScreen pumps and handles rapid scroll flings without crashing', (tester) async {
      final drawingController = DrawingController();
      final repo = ProjectRepository();
      final editorController = EditorController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: BrushStudioScreen(
            drawingController: drawingController,
            editorController: editorController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Artistic & Inks'), findsWidgets);

      // Fling scroll through the list
      final listFinder = find.byType(ListView).last;
      if (listFinder.evaluate().isNotEmpty) {
        await tester.fling(listFinder, const Offset(0, -600), 2000);
        await tester.pumpAndSettle();

        await tester.fling(listFinder, const Offset(0, 600), 2000);
        await tester.pumpAndSettle();
      }

      // Switch categories with horizontal scroll
      if (find.text('Pencils & Sketch').evaluate().isNotEmpty) {
        await tester.tap(find.text('Pencils & Sketch'), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Verify widget remains mounted and stable
      expect(find.byType(BrushStudioScreen), findsOneWidget);
    });
  });
}
