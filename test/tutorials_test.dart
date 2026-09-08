import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/templates/domain/template_model.dart';
import 'package:dummy/features/templates/data/tutorials_data.dart';
import 'package:dummy/features/templates/data/tutorial_project_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tutorials Catalog Tests', () {
    test('Tutorial definitions contain valid categories and difficulty mappings', () {
      expect(TutorialsData.definitions.isNotEmpty, isTrue);
      expect(TutorialsData.definitions.length, 42);

      // Verify no duplicate IDs exist
      final ids = TutorialsData.definitions.map((t) => t.id).toSet();
      expect(ids.length, TutorialsData.definitions.length);

      final beginnerLessons = TutorialsData.definitions
          .where((t) => t.difficulty == TutorialDifficulty.beginner)
          .toList();
      final intermediateLessons = TutorialsData.definitions
          .where((t) => t.difficulty == TutorialDifficulty.intermediate)
          .toList();

      expect(beginnerLessons.isNotEmpty, isTrue);
      expect(intermediateLessons.isNotEmpty, isTrue);

      // Verify essential beginner lessons exist
      expect(beginnerLessons.any((t) => t.name == 'Bouncing Ball'), isTrue);
      expect(beginnerLessons.any((t) => t.name == 'Pendulum Swing'), isTrue);
      expect(beginnerLessons.any((t) => t.name == 'Shape Morphing'), isTrue);
      expect(beginnerLessons.any((t) => t.name == 'Eye Blink & Expression'), isTrue);
      expect(beginnerLessons.any((t) => t.name == 'Water Drop & Splash'), isTrue);

      // Verify all 5 categories exist and are populated
      final basics = TutorialsData.definitions
          .where((t) => t.category == TutorialsData.categoryAnimationBasics)
          .toList();
      final principles = TutorialsData.definitions
          .where((t) => t.category == TutorialsData.categoryThe12Principles)
          .toList();
      final character = TutorialsData.definitions
          .where((t) => t.category == TutorialsData.categoryCharacterAndLocomotion)
          .toList();
      final vfx = TutorialsData.definitions
          .where((t) => t.category == TutorialsData.categoryVFXAndElements)
          .toList();
      final master = TutorialsData.definitions
          .where((t) => t.category == TutorialsData.categoryMasterPractice)
          .toList();

      expect(basics.length, 12);
      expect(principles.length, 10);
      expect(character.length, 6);
      expect(vfx.length, 7);
      expect(master.length, 7);
    });

    test('TutorialProjectBuilder generates unique, valid vector project data for all 42 lessons', () {
      final generatedTitles = <String>{};

      for (final def in TutorialsData.definitions) {
        final project = TutorialProjectBuilder.buildProjectForTutorial(def.id, def.name, def.frameCount);
        expect(project['projectName'], def.name);
        expect(project['fps'], 12);
        final canvases = project['canvases'] as List;
        expect(canvases.length, def.frameCount, reason: 'Frame count for ${def.id} should match definition');

        // Check canvas structure
        final firstCanvas = canvases.first as Map<String, dynamic>;
        expect(firstCanvas['layers'], isNotEmpty);
        final layers = firstCanvas['layers'] as List;
        expect(layers.length, 1); // Standard unified drawing layer matching app native projects
        expect(layers[0]['id'], 'layer_0');
        expect(layers[0]['name'], 'Background');
        expect(firstCanvas['activeLayerId'], 'layer_0');

        // Verify drawing history is non-empty
        final history = layers[0]['history'] as List;
        expect(history.isNotEmpty, isTrue, reason: '${def.id} drawing layer must not be empty');

        generatedTitles.add(def.name);
      }

      expect(generatedTitles.length, TutorialsData.definitions.length);
    });

    test('TemplateModel copyWith and getters work properly', () {
      final projectState = TutorialProjectBuilder.buildBouncingBallProject();

      final model = TemplateModel(
        id: 'bouncing_ball',
        name: 'Bouncing Ball',
        description: 'The classic first animation exercise',
        category: 'Animation Basics',
        difficulty: TutorialDifficulty.beginner,
        folder: 'bouncy_ball',
        extension: '.webp',
        frameCount: 12,
        frameAssets: const ['assets/templates/bouncy_ball/b1.webp'],
        isInProgress: true,
        isCompleted: true,
        projectState: projectState,
      );

      expect(model.previewAsset, 'assets/templates/bouncy_ball/b1.webp');
      expect(model.difficulty.label, 'Beginner');
      expect(model.getCanvasForFrame(0), isNotNull);
      expect(model.getCanvasForFrame(99), isNull);

      final updated = model.copyWith(
        difficulty: TutorialDifficulty.intermediate,
        frameCount: 24,
      );

      expect(updated.difficulty.label, 'Intermediate');
      expect(updated.frameCount, 24);
      expect(updated.id, 'bouncing_ball');
    });
  });
}
