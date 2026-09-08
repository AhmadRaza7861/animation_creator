import 'dart:async';
import '../domain/template_model.dart';
import 'tutorial_project_builder.dart';

class TutorialDefinition {
  final String id;
  final String name;
  final String subtitle;
  final String category;
  final TutorialDifficulty difficulty;
  final bool isPro;
  final bool isCompleted;
  final bool isInProgress;
  final int frameCount;
  final int estimatedMinutes;

  const TutorialDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    this.isPro = false,
    this.isCompleted = false,
    this.isInProgress = false,
    required this.frameCount,
    this.estimatedMinutes = 5,
  });
}

class TutorialsData {
  static const String categoryAnimationBasics = 'Animation Basics';
  static const String categoryThe12Principles = 'The 12 Principles';
  static const String categoryMasterPractice = 'Master Practice';

  static const List<TutorialDefinition> definitions = [
    // ==========================================
    // 1. ANIMATION BASICS (Simple, 12-16 frames)
    // ==========================================
    TutorialDefinition(
      id: 'bouncing_ball',
      name: 'Bouncing Ball',
      subtitle: 'Squash, stretch & gravity acceleration timing',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isInProgress: true,
      isCompleted: true,
      isPro: false,
      frameCount: 12,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'pendulum_swing',
      name: 'Pendulum Swing',
      subtitle: 'Circular motion arc and apex ease-in/out',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'shape_morphing',
      name: 'Shape Morphing',
      subtitle: 'Smoothly morph circle into a square with volume retention',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'spinning_star',
      name: 'Spinning Star',
      subtitle: 'Center-axis rotation with alignment guide rings',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'wave_motion',
      name: 'Wave Motion',
      subtitle: 'Sine wave fluid propagation and continuous ripples',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),
    TutorialDefinition(
      id: 'slow_in_slow_out',
      name: 'Slow In & Slow Out',
      subtitle: 'Spacing charts: gradual acceleration and deceleration',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'arcs_thrown_ball',
      name: 'Arcs: Thrown Ball',
      subtitle: 'Parabolic trajectory curve with ground rebound bounce',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 20,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'fire_flicker',
      name: 'Flame Flicker',
      subtitle: 'Organic upward flow with shape deformation',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),

    // ==========================================
    // 2. THE 12 PRINCIPLES (Classical Animation)
    // ==========================================
    TutorialDefinition(
      id: 'squash_and_stretch',
      name: 'Squash & Stretch',
      subtitle: 'Volume preservation: stretch in air, squash on impact',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'anticipation',
      name: 'Anticipation',
      subtitle: 'Pre-action windup: the crouch before a leap',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),
    TutorialDefinition(
      id: 'staging',
      name: 'Staging & Framing',
      subtitle: 'Clear composition guiding the audience gaze',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'straight_ahead_pose_to_pose',
      name: 'Straight Ahead Flow',
      subtitle: 'Spontaneous frame progression vs structured keys',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'follow_through_tail',
      name: 'Follow Through Tail',
      subtitle: 'Flexible parts lagging behind the primary movement',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),
    TutorialDefinition(
      id: 'secondary_action',
      name: 'Secondary Action',
      subtitle: 'Layering secondary details to enrich main motion',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'timing_is_weight',
      name: 'Timing & Weight',
      subtitle: 'Spacing determines mass: heavy iron vs floaty balloon',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'exaggeration',
      name: 'Exaggeration',
      subtitle: 'Pushing dynamic poses past realism for dramatic effect',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),
    TutorialDefinition(
      id: 'solid_drawing',
      name: 'Solid Drawing',
      subtitle: 'Balance, weight, depth and 3D volume in 2D space',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'appeal',
      name: 'Character Appeal',
      subtitle: 'Charisma, visual clarity, and pleasing silhouette design',
      category: categoryThe12Principles,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),

    // ==========================================
    // 3. MASTER PRACTICE (Advanced Techniques)
    // ==========================================
    TutorialDefinition(
      id: 'keys_and_inbetweens',
      name: 'Keys & Inbetweens',
      subtitle: 'Studio workflow: key poses first, breakdown inbetweens next',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 9,
    ),
    TutorialDefinition(
      id: 'arm_whip',
      name: 'The Kinetic Whip',
      subtitle: 'Energy wave propagating through shoulder, elbow, and hand',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'push_heavy_vs_light',
      name: 'Push: Heavy vs Light',
      subtitle: 'Body lean angles, foot bracing, and physical resistance',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 24,
      estimatedMinutes: 10,
    ),
    TutorialDefinition(
      id: 'pendulum_losing_energy',
      name: 'Damped Decay',
      subtitle: 'Natural friction dampening energy over consecutive swings',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 24,
      estimatedMinutes: 8,
    ),
  ];

  /// Loads the curated, non-repeating tutorial catalog
  static Future<List<TemplateModel>> loadAllTutorials() async {
    final List<TemplateModel> results = [];

    for (final def in definitions) {
      final projectState = TutorialProjectBuilder.buildProjectForTutorial(
        def.id,
        def.name,
        def.frameCount,
      );

      final int actualFrameCount = (projectState['canvases'] as List?)?.length ?? def.frameCount;

      results.add(TemplateModel(
        id: def.id,
        name: def.name,
        description: def.subtitle,
        category: def.category,
        difficulty: def.difficulty,
        frameCount: actualFrameCount,
        estimatedMinutes: def.estimatedMinutes,
        isPro: def.isPro,
        isCompleted: def.isCompleted,
        isInProgress: def.isInProgress,
        projectState: projectState,
      ));
    }

    return results;
  }
}
