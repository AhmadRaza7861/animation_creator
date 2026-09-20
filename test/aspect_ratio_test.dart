import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_providers.dart';
import 'package:dummy/features/editor/presentation/widgets/canvas_area.dart';
import 'package:dummy/features/editor/presentation/screens/export/make_movie_screen.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aspect Ratio Tests', () {
    test('EditorController defaults to 1:1 aspect ratio', () {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);
      expect(controller.aspectRatio, closeTo(1.0, 0.001));
    });

    test('EditorController safely parses integer and double aspect ratios', () async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);

      controller.aspectRatio = 16.0 / 9.0;
      expect(controller.aspectRatio, closeTo(16.0 / 9.0, 0.001));

      controller.aspectRatio = null;
      expect(controller.aspectRatio, closeTo(1.0, 0.001));
    });

    testWidgets('CanvasArea enforces AspectRatio widget with 1:1 ratio by default', (tester) async {
      final repo = ProjectRepository();
      final controller = EditorController(repository: repo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorControllerProvider('test_project').overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: CanvasArea(
                  projectId: 'test_project',
                  transformationController: TransformationController(),
                ),
              ),
            ),
          ),
        ),
      );

      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsWidgets);

      final AspectRatio aspectRatioWidget = tester.widget(aspectRatioFinder.first);
      expect(aspectRatioWidget.aspectRatio, closeTo(1.0, 0.001));

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('MakeMovieScreen automatically defaults output size to match canvas aspect ratio', (tester) async {
      // 1. Test 16:9 Canvas Aspect Ratio -> Full HD 1080p (1920 x 1080)
      await tester.pumpWidget(
        MaterialApp(
          home: MakeMovieScreen(
            key: const ValueKey('test_16_9'),
            canvases: const [],
            globalBackground: CanvasBackground(),
            initialMovieName: '16:9 Test Animation',
            initialFormat: 'Mp4',
            fps: 14,
            projectAspectRatio: 16.0 / 9.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Full HD 1080p (1920 x 1080)'), findsOneWidget);

      // 2. Test 1:1 Canvas Aspect Ratio -> Square Post (1080 x 1080)
      await tester.pumpWidget(
        MaterialApp(
          home: MakeMovieScreen(
            key: const ValueKey('test_1_1'),
            canvases: const [],
            globalBackground: CanvasBackground(),
            initialMovieName: '1:1 Test Animation',
            initialFormat: 'Mp4',
            fps: 14,
            projectAspectRatio: 1.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Square Post (1080 x 1080)'), findsOneWidget);

      // 3. Test 9:16 Canvas Aspect Ratio -> Shorts / TikTok (1080 x 1920)
      await tester.pumpWidget(
        MaterialApp(
          home: MakeMovieScreen(
            key: const ValueKey('test_9_16'),
            canvases: const [],
            globalBackground: CanvasBackground(),
            initialMovieName: '9:16 Test Animation',
            initialFormat: 'Mp4',
            fps: 14,
            projectAspectRatio: 9.0 / 16.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shorts / TikTok (1080 x 1920)'), findsOneWidget);

      // 4. Test 4:3 Canvas Aspect Ratio -> Tablet / Presentation (1440 x 1080)
      await tester.pumpWidget(
        MaterialApp(
          home: MakeMovieScreen(
            key: const ValueKey('test_4_3'),
            canvases: const [],
            globalBackground: CanvasBackground(),
            initialMovieName: '4:3 Test Animation',
            initialFormat: 'Mp4',
            fps: 14,
            projectAspectRatio: 4.0 / 3.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tablet / Presentation (1440 x 1080)'), findsOneWidget);

      // 5. Test 3:4 Canvas Aspect Ratio -> Tablet Portrait (1080 x 1440)
      await tester.pumpWidget(
        MaterialApp(
          home: MakeMovieScreen(
            key: const ValueKey('test_3_4'),
            canvases: const [],
            globalBackground: CanvasBackground(),
            initialMovieName: '3:4 Test Animation',
            initialFormat: 'Mp4',
            fps: 14,
            projectAspectRatio: 3.0 / 4.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tablet Portrait (1080 x 1440)'), findsOneWidget);

      // 6. Test opening output size bottom sheet and picking another preset
      await tester.tap(find.text('Output Size'));
      await tester.pumpAndSettle();

      expect(find.text('Select Output Size'), findsOneWidget);
      await tester.tap(find.text('Square Post'));
      await tester.pumpAndSettle();

      expect(find.text('Square Post (1080 x 1080)'), findsOneWidget);
    });
  });
}

