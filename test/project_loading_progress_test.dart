import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/widgets/project_loading_view.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProjectRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('project_loading_test_');
    repository = ProjectRepository();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Project Loading Progress & Responsive UI Tests', () {
    test('EditorController reports real-time loading progress and status for multi-frame projects', () async {
      // 1. Create a mock 30-frame project
      final canvasesList = List.generate(
        30,
        (i) => {
          'backgroundColor': 0xFFFFFFFF,
          'size': {'width': 1080.0, 'height': 1080.0},
          'layers': [
            {
              'id': 'layer_$i',
              'name': 'Layer 1',
              'isVisible': true,
              'isLocked': false,
              'opacity': 1.0,
              'blendMode': 3,
              'currentIndex': 0,
              'history': [],
            }
          ],
          'activeLayerId': 'layer_$i',
        },
      );

      final projectId = await repository.saveProject(
        title: '30 Frame Progress Test',
        state: {
          'aspectRatio': 1.0,
          'fps': 12,
          'canvases': canvasesList,
        },
      );

      final controller = EditorController(
        projectId: projectId,
        repository: repository,
      );

      final List<double> progressUpdates = [];
      controller.loadingProgressNotifier.addListener(() {
        progressUpdates.add(controller.loadingProgressNotifier.value);
      });

      await controller.loadProjectData();

      // Progress should advance smoothly and reach 1.0
      expect(progressUpdates, isNotEmpty);
      expect(controller.loadingProgressNotifier.value, 1.0);
      expect(controller.loadingStatusNotifier.value, 'Ready!');
      expect(controller.canvases.length, 30);
      expect(controller.isLoadingProject, isFalse);

      controller.dispose();
    });

    testWidgets('ProjectLoadingView renders determinate progress and percentage HUD without crash', (tester) async {
      final progressNotifier = ValueNotifier<double>(0.45);
      final statusNotifier = ValueNotifier<String>('Restoring frame 45 of 100...');

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectLoadingView(
            title: 'Opening Project',
            progressNotifier: progressNotifier,
            statusNotifier: statusNotifier,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify title, status text, and percentage badge are rendered
      expect(find.text('Opening Project'), findsOneWidget);
      expect(find.text('Restoring frame 45 of 100...'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);

      // Advance progress to 100%
      progressNotifier.value = 1.0;
      statusNotifier.value = 'Ready!';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Ready!'), findsWidgets);

      progressNotifier.dispose();
      statusNotifier.dispose();
    });

    testWidgets('ProjectLoadingView renders indeterminate fallback without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProjectLoadingView(
            title: 'Loading Video',
            subtitle: 'Preparing video frames for preview...',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Loading Video'), findsOneWidget);
      expect(find.text('Preparing video frames for preview...'), findsOneWidget);
    });
  });
}
