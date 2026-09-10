import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_providers.dart';
import 'package:dummy/features/editor/presentation/widgets/canvas_area.dart';
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
  });
}
