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
  static const String categoryCharacterAndLocomotion = 'Character & Motion';
  static const String categoryVFXAndElements = 'VFX & Elements';
  static const String categoryMasterPractice = 'Master Practice';

  static const List<TutorialDefinition> definitions = [
    // =========================================================================
    // 1. ANIMATION BASICS (Fundamentals & Drawing Foundation)
    // =========================================================================
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
    TutorialDefinition(
      id: 'eye_blink',
      name: 'Eye Blink & Expression',
      subtitle: 'Natural eyelid arc, lash compression, and brow dip',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 12,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'mouth_shapes',
      name: 'Mouth Shapes & Lip Sync',
      subtitle: 'Phonemes (A, O, M, E, Smile) speaking cadence guide',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'hand_wave',
      name: 'Hand Wave & Gesture',
      subtitle: 'Wrist rotation, finger spread, and rhythmic hand wave',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'hair_in_wind',
      name: 'Hair in the Wind',
      subtitle: 'S-curve overlapping wave dynamics on flowing hair',
      category: categoryAnimationBasics,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),

    // =========================================================================
    // 2. THE 12 PRINCIPLES (Disney & Classical Animation Rules)
    // =========================================================================
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

    // =========================================================================
    // 3. CHARACTER & LOCOMOTION (Walks, Runs, Jumps & Poses)
    // =========================================================================
    TutorialDefinition(
      id: 'walk_cycle',
      name: 'Classic Walk Cycle',
      subtitle: '8-position contact, down, pass & up bipedal walk loop',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 9,
    ),
    TutorialDefinition(
      id: 'run_cycle',
      name: 'Dynamic Run Cycle',
      subtitle: 'High-speed sprint with airborne flight phase and forward lean',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 12,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'character_jump',
      name: 'Jump & Impact Landing',
      subtitle: 'Deep crouch, explosive launch, apex hang & squash landing',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 18,
      estimatedMinutes: 9,
    ),
    TutorialDefinition(
      id: 'sneak_walk',
      name: 'Sneak & Tip-Toe',
      subtitle: 'High-knee stealth lift, delicate footfall & comic pacing',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'ball_with_legs',
      name: 'Ball with Legs',
      subtitle: 'Combines squash/stretch body mass with step mechanics',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'head_turn_3d',
      name: '3/4 Head Turn',
      subtitle: 'Cross-axis volumetric rotation preserving facial symmetry',
      category: categoryCharacterAndLocomotion,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 8,
    ),

    // =========================================================================
    // 4. VFX & ELEMENTS (Fluids, Fire, Electricity & Particles)
    // =========================================================================
    TutorialDefinition(
      id: 'water_splash',
      name: 'Water Drop & Splash',
      subtitle: 'Droplet impact, crown splash rim and expanding ripple rings',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'explosion_puff',
      name: 'Explosion & Smoke Puff',
      subtitle: 'High-energy blast burst, mushrooming clouds & smoke drift',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),
    TutorialDefinition(
      id: 'lightning_strike',
      name: 'Lightning Bolt & Zap',
      subtitle: 'Electric leader zap, flash bloom & crackle dissipation',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 12,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'balloon_pop',
      name: 'Balloon Float & Pop',
      subtitle: 'Buoyant aerial float, needle contact & rubber burst pop',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 6,
    ),
    TutorialDefinition(
      id: 'falling_leaf',
      name: 'Fluttering Autumn Leaf',
      subtitle: 'Chaotic air-resistance drift with tumbling perspective flips',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 20,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'magic_sparkle',
      name: 'Magic Starburst & Twinkle',
      subtitle: '4-point star bloom, lens flare rays & shimmering sparkles',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.beginner,
      isPro: false,
      frameCount: 12,
      estimatedMinutes: 5,
    ),
    TutorialDefinition(
      id: 'liquid_flourish',
      name: 'Liquid Flourish Splash',
      subtitle: 'Organic fluid ribbon curling into trailing droplet beads',
      category: categoryVFXAndElements,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 7,
    ),

    // =========================================================================
    // 5. MASTER PRACTICE (Cinematics, Complex Physics & Sequencing)
    // =========================================================================
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
    TutorialDefinition(
      id: 'sword_slash',
      name: 'Sword Slash & Trail',
      subtitle: 'Kinetic blade swing with sweeping crescent speed-arc trail',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 14,
      estimatedMinutes: 8,
    ),
    TutorialDefinition(
      id: 'bird_flight',
      name: 'Bird Flight & Wing Flap',
      subtitle: 'Folded upstroke, powerful downward push & gliding air catch',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 9,
    ),
    TutorialDefinition(
      id: 'camera_parallax',
      name: '3D Depth Parallax',
      subtitle: 'Multi-plane foreground, midground & mountains depth scrolling',
      category: categoryMasterPractice,
      difficulty: TutorialDifficulty.intermediate,
      isPro: false,
      frameCount: 16,
      estimatedMinutes: 9,
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
