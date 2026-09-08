import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../projects/data/project_repository.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../widgets/clipax_logo_painter.dart';

class SplashScreen extends StatefulWidget {
  final ProjectRepository repository;
  const SplashScreen({super.key, required this.repository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _shootingStarController;

  // Logo dynamic drawing animations
  late Animation<double> _logoStrokeProgress;
  late Animation<double> _logoPlayProgress;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;

  // Staggered letters for "clipax"
  late List<Animation<double>> _letterFades;
  late List<Animation<double>> _letterSlides;
  late List<Animation<double>> _letterScales;

  // Tagline animations
  late Animation<double> _taglineFade;
  late Animation<double> _taglineSpacing;

  // Progress animation
  late Animation<double> _progressAnimation;
  late Animation<double> _bottomFade;

  Timer? _navTimer;
  bool _hasNavigated = false;

  static const List<String> _letters = ['c', 'l', 'i', 'p', 'a', 'x'];

  @override
  void initState() {
    super.initState();

    // 1. Master timeline orchestration (3200ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 2. Orbiting stardust sparks loop
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // 3. Ambient nebula pulse loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // 4. Periodic shooting star effect
    _shootingStarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Stage 1: Film strip stroke drawing (0.0s -> 2.2s)
    _logoStrokeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.04, 0.35, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage 2: Logo overall scale & entrance
    _logoScale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.04, 0.38, curve: Curves.easeOutBack),
      ),
    );

    // Stage 3: Play button neon pop-in (2.0s -> 3.0s)
    _logoPlayProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.46, curve: Curves.elasticOut),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.48, curve: Curves.easeInOut),
      ),
    );

    // Stage 4: Staggered letter-by-letter reveal (2.8s -> 4.5s)
    _letterFades = [];
    _letterSlides = [];
    _letterScales = [];
    for (int i = 0; i < _letters.length; i++) {
      final double start = 0.38 + (i * 0.038);
      final double end = (start + 0.12).clamp(0.0, 1.0);

      _letterFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeIn),
          ),
        ),
      );

      _letterSlides.add(
        Tween<double>(begin: 30.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );

      _letterScales.add(
        Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    // Stage 5: Tagline reveal (4.2s -> 5.4s)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.60, 0.78, curve: Curves.easeIn),
      ),
    );

    _taglineSpacing = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Progress animation across full 7.5s duration
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.06, 0.98, curve: Curves.easeInOutCubic),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.18, 0.42, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // 3.6s Total Delay before smooth transition
    _navTimer = Timer(const Duration(milliseconds: 3600), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navTimer?.cancel();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectsScreen(repository: widget.repository),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _mainController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _shootingStarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _navigateToHome,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0B14),
        body: Stack(
          children: [
            // 1. Cinematic Universe Canvas: Shooting stars, Nebulae & Concentric shockwaves
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _orbitController,
                  _pulseController,
                  _shootingStarController,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CinematicUniversePainter(
                      mainProgress: _mainController.value,
                      orbitValue: _orbitController.value,
                      pulseValue: _pulseController.value,
                      shootingStarValue: _shootingStarController.value,
                    ),
                  );
                },
              ),
            ),

            // 2. Central Animated Brand Content with 3D Holographic Tilt
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _orbitController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  final double floatOffset =
                      math.sin(_pulseController.value * 2 * math.pi) * 5.0;
                  final double breatheScale =
                      1.0 + 0.025 * math.sin(_pulseController.value * 2 * math.pi);
                  final double tiltAngle =
                      math.sin(_pulseController.value * 2 * math.pi) * 0.03;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateZ(tiltAngle),
                          child: Transform.scale(
                          scale: _logoScale.value * breatheScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radiant Ambient Glow Disc
                              Container(
                                width: 185,
                                height: 185,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      ColorConstants.primary.withValues(
                                          alpha: 0.30 * _logoGlow.value),
                                      const Color(0xFF9D60CC).withValues(
                                          alpha: 0.15 * _logoGlow.value),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.65, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorConstants.primary.withValues(
                                          alpha: 0.25 * _logoGlow.value),
                                      blurRadius: 46,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              ),

                              // Real-time Dynamic Vector Logo Drawing
                              SizedBox(
                                width: 145,
                                height: 145,
                                child: CustomPaint(
                                  painter: ClipaxLogoPainter(
                                    strokeProgress: _logoStrokeProgress.value,
                                    playProgress: _logoPlayProgress.value,
                                    glowIntensity: _logoGlow.value,
                                    shimmerPhase: _orbitController.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                      const SizedBox(height: 34),

                      // B. Staggered Letter-by-Letter Typography ("c-l-i-p-a-x")
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: List.generate(_letters.length, (index) {
                          final String char = _letters[index];
                          final bool isOrange = index >= 4; // 'a' and 'x'

                          return Transform.translate(
                            offset: Offset(0, _letterSlides[index].value),
                            child: Opacity(
                              opacity: _letterFades[index].value,
                              child: Transform.scale(
                                scale: _letterScales[index].value,
                                child: isOrange
                                    ? ShaderMask(
                                        shaderCallback: (bounds) {
                                          return const LinearGradient(
                                            colors: [
                                              Color(0xFFFF9318),
                                              Color(0xFFFFB356),
                                              Color(0xFFFF6A00),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          char,
                                          style: const TextStyle(
                                            fontSize: 54,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -1.0,
                                            shadows: [
                                              Shadow(
                                                color: Color(0xFFFF9318),
                                                blurRadius: 28,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Text(
                                        char,
                                        style: const TextStyle(
                                          fontSize: 54,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 20,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // C. Tagline with Tracking Expansion & Glowing Jewels
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildJewelSpark(_pulseController.value),
                            const SizedBox(width: 12),
                            Text(
                              StringConstants.appTagline,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD4D0E2),
                                letterSpacing: _taglineSpacing.value,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFFFF9318),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildJewelSpark(_pulseController.value,
                                isReverse: true),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 4. Cinematic Studio Progress Capsule & Dynamic Phase Status
            Positioned(
              left: 36,
              right: 36,
              bottom: MediaQuery.of(context).padding.bottom + 42,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  final double progress = _progressAnimation.value;
                  final int percent = (progress * 100).toInt().clamp(0, 100);

                  String statusText = 'Tracing creative paths...';
                  if (progress > 0.28 && progress <= 0.58) {
                    statusText = 'Warming up 110+ studio brushes...';
                  } else if (progress > 0.58 && progress <= 0.88) {
                    statusText = 'Composing multi-layer animation engine...';
                  } else if (progress > 0.88) {
                    statusText = 'Welcome to Clipax Studio! ✨';
                  }

                  return Opacity(
                    opacity: _bottomFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar with live percentage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 5,
                              width: size.width * 0.54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF9318),
                                          Color(0xFFFF5E3A),
                                          Color(0xFF9D60CC),
                                          Color(0xFF4FACFE),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ColorConstants.primary
                                              .withValues(alpha: 0.60),
                                          blurRadius: 12,
                                          spreadRadius: 1.5,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Animated dynamic milestone text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          child: Text(
                            statusText,
                            key: ValueKey(statusText),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJewelSpark(double loopValue, {bool isReverse = false}) {
    final double phase = (loopValue + (isReverse ? 0.5 : 0.0)) * 2 * math.pi;
    final double scale = 0.75 + 0.45 * math.sin(phase);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primary.withValues(alpha: 0.95),
              blurRadius: 10,
              spreadRadius: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cinematic Universe Painter for shooting stars, cosmic nebulae, shockwave ripples & orbiting stardust
class _CinematicUniversePainter extends CustomPainter {
  final double mainProgress;
  final double orbitValue;
  final double pulseValue;
  final double shootingStarValue;

  _CinematicUniversePainter({
    required this.mainProgress,
    required this.orbitValue,
    required this.pulseValue,
    required this.shootingStarValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Dual-Core Cosmic Nebula Glows
    final double nebulaBreathe = 1.0 + 0.08 * math.sin(pulseValue * 2 * math.pi);

    // Amber Core (top-center)
    final amberGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9318).withValues(alpha: 0.18 * nebulaBreathe),
          const Color(0xFFFF5E3A).withValues(alpha: 0.08 * nebulaBreathe),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
          center: center + const Offset(-20, -30), radius: size.width * 0.9));
    canvas.drawCircle(center + const Offset(-20, -30), size.width * 0.9, amberGlow);

    // Violet Core (bottom-right)
    final violetGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9D60CC).withValues(alpha: 0.14 * nebulaBreathe),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60],
      ).createShader(Rect.fromCircle(
          center: center + const Offset(40, 60), radius: size.width * 0.8));
    canvas.drawCircle(center + const Offset(40, 60), size.width * 0.8, violetGlow);

    // 2. Shooting Star Celestial Trail
    if (shootingStarValue > 0.05 && shootingStarValue < 0.65) {
      final double starT = (shootingStarValue - 0.05) / 0.60;
      final double starX = size.width * (1.1 - starT * 1.3);
      final double starY = size.height * (0.12 + starT * 0.28);
      final double starAlpha = math.sin(starT * math.pi) * 0.85;

      final starPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: starAlpha),
            const Color(0xFFFF9318).withValues(alpha: starAlpha * 0.5),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Rect.fromPoints(
            Offset(starX + 50, starY - 25), Offset(starX, starY)))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
          Offset(starX + 50, starY - 25), Offset(starX, starY), starPaint);
    }

    // 3. Expanding Concentric Shockwave Ripple Waves
    if (mainProgress > 0.18) {
      final double rippleT = ((mainProgress - 0.18) / 0.82).clamp(0.0, 1.0);
      for (int i = 0; i < 3; i++) {
        final double ringProgress = (rippleT * 1.6 - (i * 0.32)).clamp(0.0, 1.0);
        if (ringProgress > 0.0 && ringProgress < 1.0) {
          final double ringRadius = 80.0 + ringProgress * (size.width * 0.68);
          final double ringAlpha = (1.0 - ringProgress) * 0.20;

          final ringPaint = Paint()
            ..shader = SweepGradient(
              colors: [
                const Color(0xFFFF9318).withValues(alpha: ringAlpha),
                const Color(0xFF9D60CC).withValues(alpha: ringAlpha * 0.7),
                const Color(0xFFFF9318).withValues(alpha: ringAlpha),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: ringRadius))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2;

          canvas.drawCircle(center, ringRadius, ringPaint);
        }
      }
    }

    // 4. Orbiting Stardust Sparks & Constellation Particles
    final particles = [
      _StarDef(orbitRadius: 105, speed: 1.0, baseRadius: 3.4, color: const Color(0xFFFF9318), phaseOffset: 0.0),
      _StarDef(orbitRadius: 115, speed: -0.85, baseRadius: 2.8, color: const Color(0xFF9D60CC), phaseOffset: 0.3),
      _StarDef(orbitRadius: 128, speed: 1.2, baseRadius: 2.5, color: const Color(0xFFFFB038), phaseOffset: 0.6),
      _StarDef(orbitRadius: 142, speed: -1.1, baseRadius: 3.2, color: const Color(0xFFFF5E3A), phaseOffset: 0.8),
      _StarDef(orbitRadius: 158, speed: 0.9, baseRadius: 2.4, color: const Color(0xFF4FACFE), phaseOffset: 0.45),
      _StarDef(orbitRadius: 95, speed: -1.3, baseRadius: 2.6, color: const Color(0xFFFF9318), phaseOffset: 0.15),
    ];

    for (final p in particles) {
      final double angle = (orbitValue * p.speed * 2 * math.pi) + (p.phaseOffset * 2 * math.pi);
      final double rad = p.orbitRadius * (0.95 + 0.05 * math.sin(pulseValue * 2 * math.pi));
      final pPos = center + Offset(rad * math.cos(angle), rad * math.sin(angle) * 0.85);

      final pGlow = Paint()
        ..color = p.color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pPos, p.baseRadius * 2.0, pGlow);

      final pCore = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pPos, p.baseRadius, pCore);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicUniversePainter oldDelegate) {
    return oldDelegate.orbitValue != orbitValue ||
        oldDelegate.mainProgress != mainProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.shootingStarValue != shootingStarValue;
  }
}

class _StarDef {
  final double orbitRadius;
  final double speed;
  final double baseRadius;
  final Color color;
  final double phaseOffset;

  const _StarDef({
    required this.orbitRadius,
    required this.speed,
    required this.baseRadius,
    required this.color,
    required this.phaseOffset,
  });
}
