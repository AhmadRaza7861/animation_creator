import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProjectLoadingView extends StatefulWidget {
  final String title;
  final String? subtitle;
  final ValueNotifier<double>? progressNotifier;
  final ValueNotifier<String>? statusNotifier;
  final double? progress;

  const ProjectLoadingView({
    super.key,
    this.title = 'Opening Project',
    this.subtitle,
    this.progressNotifier,
    this.statusNotifier,
    this.progress,
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
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Only run status cycling timer if external statusNotifier is not provided
    if (widget.statusNotifier == null) {
      _statusTimer = Timer.periodic(const Duration(milliseconds: 1300), (timer) {
        if (mounted) {
          setState(() {
            _statusIndex = (_statusIndex + 1) % _statusMessages.length;
          });
        }
      });
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Soft Ambient Radial Light Aura (Primary warm amber glow)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double pulseVal = _pulseController.value;
              return Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorConstants.primary.withValues(alpha: 0.13 + pulseVal * 0.08),
                      const Color(0xFFFFE5CB).withValues(alpha: 0.32 + pulseVal * 0.14),
                      Colors.white.withValues(alpha: 0.0),
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
                // Animated Canvas Orbit & 3D Layer Stack
                SizedBox(
                  width: 156,
                  height: 156,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Glow Wave
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final double scale = 1.0 + _pulseController.value * 0.12;
                          final double alpha = 0.40 - _pulseController.value * 0.22;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorConstants.primary.withValues(alpha: alpha.clamp(0.0, 1.0)),
                                  width: 1.8,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Rotating Orbit Ring with Gradient Arc & Comet Bead
                      RotationTransition(
                        turns: _spinController,
                        child: CustomPaint(
                          size: const Size(130, 130),
                          painter: _OrbitRingPainter(),
                        ),
                      ),

                      // Floating Hero Card with 3D Layer Stack
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final double translateY = sin(_floatController.value * pi) * -5.0;
                          final double scale = 1.0 + sin(_floatController.value * pi) * 0.015;
                          return Transform.translate(
                            offset: Offset(0, translateY),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFFFDAB8),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorConstants.primary.withValues(alpha: 0.22),
                                      blurRadius: 24,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Layer 1 (Back Canvas Sheet, tilted -8 deg)
                                      Transform.rotate(
                                        angle: -0.12,
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: ColorConstants.primary.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: ColorConstants.primary.withValues(alpha: 0.28),
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Layer 2 (Middle Canvas Sheet, tilted +5 deg)
                                      Transform.rotate(
                                        angle: 0.08,
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: ColorConstants.primary.withValues(alpha: 0.32),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: ColorConstants.primary.withValues(alpha: 0.45),
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Layer 3 (Front Canvas Sheet with Creative Motif)
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: ColorConstants.primary,
                                            width: 1.6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: ColorConstants.primary.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.auto_awesome_motion_rounded,
                                            color: ColorConstants.primary,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      // Top-right dynamic active amber pulse indicator
                                      Positioned(
                                        top: 13,
                                        right: 13,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: ColorConstants.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ColorConstants.primary.withValues(alpha: 0.6),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),

                const SizedBox(height: 8),

                // Dynamic Status Subtitle with smooth transitions
                _buildStatusSubtitle(),

                const SizedBox(height: 22),

                // Sleek Smart Progress Capsule & HUD
                _buildProgressCapsule(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSubtitle() {
    if (widget.statusNotifier != null) {
      return ValueListenableBuilder<String>(
        valueListenable: widget.statusNotifier!,
        builder: (context, statusText, child) {
          return _buildAnimatedText(statusText);
        },
      );
    }

    final String currentStatus = widget.subtitle ?? _statusMessages[_statusIndex];
    return _buildAnimatedText(currentStatus);
  }

  Widget _buildAnimatedText(String text) {
    return SizedBox(
      height: 22,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey(text),
          style: const TextStyle(
            color: ColorConstants.mediumText,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCapsule() {
    if (widget.progressNotifier != null) {
      return ValueListenableBuilder<double>(
        valueListenable: widget.progressNotifier!,
        builder: (context, progress, child) {
          return _buildDeterminateProgress(progress.clamp(0.0, 1.0));
        },
      );
    }

    if (widget.progress != null) {
      return _buildDeterminateProgress(widget.progress!.clamp(0.0, 1.0));
    }

    // Fallback: Indeterminate Shimmer Capsule
    return _buildIndeterminateShimmer();
  }

  Widget _buildDeterminateProgress(double progress) {
    const double barWidth = 220.0;
    const double barHeight = 7.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4EC), width: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedValue,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFA940),
                            ColorConstants.primary,
                            Color(0xFFFF5E00),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primary.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: barWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: ColorConstants.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  progress >= 1.0 ? 'Ready!' : 'Loading assets...',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColorConstants.lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndeterminateShimmer() {
    const double barWidth = 220.0;
    const double barHeight = 7.5;

    return Container(
      width: barWidth,
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4EC), width: 0.8),
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
                    Color(0xFFFFA940),
                    ColorConstants.primary,
                    Color(0xFFFF5E00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the revolving orbit ring with smooth gradient arc and comet head
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2 - 4;

    // Track circle
    final Paint trackPaint = Paint()
      ..color = const Color(0xFFEDEDF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(Offset(center, center), radius, trackPaint);

    // Inner concentric studio guide circle
    final Paint innerGuidePaint = Paint()
      ..color = const Color(0xFFF5EBE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(center, center), radius - 10, innerGuidePaint);

    // Active Gradient Arc (Sweeping around 250 degrees)
    final Rect rect = Rect.fromCircle(center: Offset(center, center), radius: radius);
    final Paint arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFFC480),
          ColorConstants.primary,
          Color(0xFFFF6200),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.4;

    const double arcLength = pi * 1.38;
    canvas.drawArc(rect, 0, arcLength, false, arcPaint);

    // Orbiting Satellite Comet Bead
    final double beadX = center + radius * cos(arcLength);
    final double beadY = center + radius * sin(arcLength);

    final Paint beadGlowPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final Paint beadCorePaint = Paint()..color = const Color(0xFFFF6200);
    final Paint beadInnerDotPaint = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(beadX, beadY), 6.5, beadGlowPaint);
    canvas.drawCircle(Offset(beadX, beadY), 3.8, beadCorePaint);
    canvas.drawCircle(Offset(beadX, beadY), 1.6, beadInnerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
