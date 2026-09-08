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

  // Progress & bottom indicator
  late Animation<double> _progressAnimation;
  late Animation<double> _bottomFade;

  Timer? _navTimer;

  static const List<String> _letters = ['c', 'l', 'i', 'p', 'a', 'x'];

  @override
  void initState() {
    super.initState();

    // 1. Master timeline orchestration (5200ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    // 2. Orbiting stardust sparks loop
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    // 3. Ambient nebula pulse loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Stage 1: Film strip stroke drawing (0.0s -> 1.8s)
    _logoStrokeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.04, 0.36, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage 2: Logo overall scale & initial entry
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.04, 0.40, curve: Curves.easeOutBack),
      ),
    );

    // Stage 3: Play button neon pop-in (1.6s -> 2.4s)
    _logoPlayProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.48, curve: Curves.elasticOut),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.10, 0.50, curve: Curves.easeInOut),
      ),
    );

    // Stage 4: Staggered letter-by-letter reveal (2.2s -> 3.6s)
    _letterFades = [];
    _letterSlides = [];
    _letterScales = [];
    for (int i = 0; i < _letters.length; i++) {
      final double start = 0.40 + (i * 0.035);
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
        Tween<double>(begin: 28.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );

      _letterScales.add(
        Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    // Stage 5: Tagline reveal (3.4s -> 4.2s)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.80, curve: Curves.easeIn),
      ),
    );

    _taglineSpacing = Tween<double>(begin: 1.0, end: 4.2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    // Progress animation across full 6.0s duration
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.98, curve: Curves.easeInOutCubic),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.20, 0.45, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // 6.0s Total Delay before smooth transition
    _navTimer = Timer(const Duration(milliseconds: 6000), () {
      if (mounted) {
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
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _mainController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: Stack(
        children: [
          // 1. Cinematic Background Nebula & Concentric Shockwaves Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _orbitController,
                _pulseController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _CinematicUniversePainter(
                    mainProgress: _mainController.value,
                    orbitValue: _orbitController.value,
                    pulseValue: _pulseController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Central Animated Brand Content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _orbitController,
                _pulseController,
              ]),
              builder: (context, child) {
                final double floatOffset =
                    math.sin(_pulseController.value * 2 * math.pi) * 4.5;
                final double breatheScale =
                    1.0 + 0.02 * math.sin(_pulseController.value * 2 * math.pi);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A. Animated Vector Drawing Logo Card with Glassmorphic Halo
                    Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Transform.scale(
                        scale: _logoScale.value * breatheScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing Glassmorphic Background Disk
                            Container(
                              width: 175,
                              height: 175,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    ColorConstants.primary.withValues(alpha: 0.25 * _logoGlow.value),
                                    const Color(0xFF9D60CC).withValues(alpha: 0.12 * _logoGlow.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.65, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstants.primary.withValues(alpha: 0.20 * _logoGlow.value),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            // Dynamic Real-time Logo Drawing Custom Painter
                            SizedBox(
                              width: 140,
                              height: 140,
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

                    const SizedBox(height: 32),

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
                                          fontSize: 52,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xFFFF9318),
                                              blurRadius: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Text(
                                      char,
                                      style: const TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 16,
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
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFC7C3D4),
                              letterSpacing: _taglineSpacing.value,
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFFF9318),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildJewelSpark(_pulseController.value, isReverse: true),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Cinematic Studio Progress Capsule & Dynamic Phase Status
          Positioned(
            left: 36,
            right: 36,
            bottom: MediaQuery.of(context).padding.bottom + 42,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                final double progress = _progressAnimation.value;

                String statusText = 'Tracing animation paths...';
                if (progress > 0.30 && progress <= 0.60) {
                  statusText = 'Calibrating studio brushes...';
                } else if (progress > 0.60 && progress <= 0.88) {
                  statusText = 'Composing canvas layers...';
                } else if (progress > 0.88) {
                  statusText = 'Ready to create!';
                }

                return Opacity(
                  opacity: _bottomFade.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sleek glowing progress capsule
                      Container(
                        height: 5,
                        width: size.width * 0.52,
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
                                    color: ColorConstants.primary.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                            color: Colors.white.withValues(alpha: 0.60),
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
    );
  }

  Widget _buildJewelSpark(double loopValue, {bool isReverse = false}) {
    final double phase = (loopValue + (isReverse ? 0.5 : 0.0)) * 2 * math.pi;
    final double scale = 0.75 + 0.45 * math.sin(phase);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 6.5,
        height: 6.5,
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primary.withValues(alpha: 0.9),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cinematic Universe Painter for ambient glowing nebula, concentric shockwave ripples & orbiting stardust
class _CinematicUniversePainter extends CustomPainter {
  final double mainProgress;
  final double orbitValue;
  final double pulseValue;

  _CinematicUniversePainter({
    required this.mainProgress,
    required this.orbitValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Deep Radiant Nebula Glow in Center
    final double nebulaBreathe = 1.0 + 0.08 * math.sin(pulseValue * 2 * math.pi);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9318).withValues(alpha: 0.16 * nebulaBreathe),
          const Color(0xFF9D60CC).withValues(alpha: 0.10 * nebulaBreathe),
          const Color(0xFF0D0B14).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.95));

    canvas.drawCircle(center, size.width * 0.95, glowPaint);

    // 2. Expanding Concentric Shockwave Ripple Waves
    if (mainProgress > 0.20) {
      final double rippleT = ((mainProgress - 0.20) / 0.80).clamp(0.0, 1.0);
      for (int i = 0; i < 3; i++) {
        final double ringProgress = (rippleT * 1.6 - (i * 0.32)).clamp(0.0, 1.0);
        if (ringProgress > 0.0 && ringProgress < 1.0) {
          final double ringRadius = 80.0 + ringProgress * (size.width * 0.65);
          final double ringAlpha = (1.0 - ringProgress) * 0.18;

          final ringPaint = Paint()
            ..shader = SweepGradient(
              colors: [
                const Color(0xFFFF9318).withValues(alpha: ringAlpha),
                const Color(0xFF9D60CC).withValues(alpha: ringAlpha * 0.7),
                const Color(0xFFFF9318).withValues(alpha: ringAlpha),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: ringRadius))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          canvas.drawCircle(center, ringRadius, ringPaint);
        }
      }
    }

    // 3. Orbiting Stardust Sparks & Constellation Particles
    final particles = [
      _StarDef(orbitRadius: 105, speed: 1.0, baseRadius: 3.2, color: const Color(0xFFFF9318), phaseOffset: 0.0),
      _StarDef(orbitRadius: 115, speed: -0.85, baseRadius: 2.8, color: const Color(0xFF9D60CC), phaseOffset: 0.3),
      _StarDef(orbitRadius: 128, speed: 1.2, baseRadius: 2.4, color: const Color(0xFFFFB038), phaseOffset: 0.6),
      _StarDef(orbitRadius: 140, speed: -1.1, baseRadius: 3.0, color: const Color(0xFFFF5E3A), phaseOffset: 0.8),
      _StarDef(orbitRadius: 155, speed: 0.9, baseRadius: 2.2, color: const Color(0xFF4FACFE), phaseOffset: 0.45),
      _StarDef(orbitRadius: 95, speed: -1.3, baseRadius: 2.6, color: const Color(0xFFFF9318), phaseOffset: 0.15),
    ];

    for (final p in particles) {
      final double angle = (orbitValue * p.speed * 2 * math.pi) + (p.phaseOffset * 2 * math.pi);
      final double rad = p.orbitRadius * (0.95 + 0.05 * math.sin(pulseValue * 2 * math.pi));
      final pPos = center + Offset(rad * math.cos(angle), rad * math.sin(angle) * 0.85);

      final pGlow = Paint()
        ..color = p.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(pPos, p.baseRadius * 1.8, pGlow);

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
        oldDelegate.pulseValue != pulseValue;
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
