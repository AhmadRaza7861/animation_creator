import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectLoadingView extends StatefulWidget {
  final String title;
  final String? subtitle;

  const ProjectLoadingView({
    super.key,
    this.title = 'Opening Project',
    this.subtitle,
  });

  @override
  State<ProjectLoadingView> createState() => _ProjectLoadingViewState();
}

class _ProjectLoadingViewState extends State<ProjectLoadingView> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;

  Timer? _statusTimer;
  int _statusIndex = 0;

  final List<String> _statusMessages = [
    'Restoring drawing layers...',
    'Preparing animation frames...',
    'Initializing vector canvas...',
    'Loading creative tools...',
  ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _spinController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentStatus = widget.subtitle ?? _statusMessages[_statusIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Soft Ambient Radial Light Aura
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double pulseVal = _pulseController.value;
              return Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorConstants.accent.withOpacity(0.12 + pulseVal * 0.08),
                      const Color(0xFFFFEAD4).withOpacity(0.35 + pulseVal * 0.15),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              );
            },
          ),

          // 2. Central Animated Hero Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Canvas Orbit & Icon Stack
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Glow Wave
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final double scale = 1.0 + _pulseController.value * 0.12;
                          final double alpha = 0.45 - _pulseController.value * 0.25;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorConstants.accent.withOpacity(alpha.clamp(0.0, 1.0)),
                                  width: 2.0,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Rotating Orbit Ring with Gradient Arc
                      RotationTransition(
                        turns: _spinController,
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: _OrbitRingPainter(),
                        ),
                      ),

                      // Floating Center Card
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final double translateY = sin(_floatController.value * pi) * -4.0;
                          return Transform.translate(
                            offset: Offset(0, translateY),
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFFFDAB3),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstants.accent.withOpacity(0.22),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_motion_rounded,
                                      color: ColorConstants.accent.withOpacity(0.9),
                                      size: 34,
                                    ),
                                    Positioned(
                                      top: 14,
                                      right: 14,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: ColorConstants.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: ColorConstants.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle / Dynamic Status Messages
                SizedBox(
                  height: 22,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      currentStatus,
                      key: ValueKey(currentStatus),
                      style: const TextStyle(
                        color: ColorConstants.mediumText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Shimmering Linear Progress Capsule
                Container(
                  width: 160,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5ED), width: 0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment(
                          -1.0 + (_shimmerController.value * 2.0),
                          0.0,
                        ),
                        widthFactor: 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFBE6A),
                                Color(0xFFFF9114),
                                Color(0xFFFF6E00),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.accent.withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the revolving orbit ring
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2 - 4;

    // Track circle
    final Paint trackPaint = Paint()
      ..color = const Color(0xFFEDEDF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(center, center), radius, trackPaint);

    // Active Gradient Arc
    final Rect rect = Rect.fromCircle(center: Offset(center, center), radius: radius);
    final Paint arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFFBE6A),
          Color(0xFFFF9114),
          Color(0xFFFF6E00),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    canvas.drawArc(rect, 0, pi * 1.3, false, arcPaint);

    // Orbiting Satellite Bead
    final double beadAngle = pi * 1.3;
    final double beadX = center + radius * cos(beadAngle);
    final double beadY = center + radius * sin(beadAngle);

    final Paint beadPaint = Paint()..color = const Color(0xFFFF6E00);
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFF9114).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(beadX, beadY), 5, glowPaint);
    canvas.drawCircle(Offset(beadX, beadY), 3.2, beadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
