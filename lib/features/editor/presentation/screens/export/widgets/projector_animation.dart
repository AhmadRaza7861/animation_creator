import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class ProjectorAnimation extends StatefulWidget {
  final double size;

  const ProjectorAnimation({
    super.key,
    this.size = 200,
  });

  @override
  State<ProjectorAnimation> createState() => _ProjectorAnimationState();
}

class _ProjectorAnimationState extends State<ProjectorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size * 1.3, widget.size),
          painter: _ClipaxStudioPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ClipaxStudioPainter extends CustomPainter {
  final double progress;

  _ClipaxStudioPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double scale = h / 200.0;

    final Offset center = Offset(w * 0.55, h * 0.52);

    // 1. Warm Golden Light Beam emanating forward (to left)
    final double pulse = 0.88 + 0.12 * math.sin(progress * math.pi * 4);
    final Path beamPath = Path();
    final Offset lensTip = center + Offset(-62 * scale, 6 * scale);

    beamPath.moveTo(lensTip.dx, lensTip.dy - 10 * scale);
    beamPath.lineTo(0, h * 0.12);
    beamPath.lineTo(0, h * 0.88);
    beamPath.lineTo(lensTip.dx, lensTip.dy + 10 * scale);
    beamPath.close();

    final Paint beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          ColorConstants.primary.withValues(alpha: 0.35 * pulse),
          ColorConstants.primaryLight.withValues(alpha: 0.15 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, lensTip.dx, h));

    canvas.drawPath(beamPath, beamPaint);

    // 2. Soft Ambient Shadow under studio camera
    final Rect shadowRect = Rect.fromCenter(
      center: center + Offset(0, 56 * scale),
      width: 130 * scale,
      height: 20 * scale,
    );
    final Paint shadowPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(shadowRect, shadowPaint);

    // 3. Film Reels (Top Left Reel & Top Right Reel)
    _drawFilmReel(
      canvas,
      center: center + Offset(-24 * scale, -42 * scale),
      radius: 28 * scale,
      rotation: progress * math.pi * 2,
      scale: scale,
    );

    _drawFilmReel(
      canvas,
      center: center + Offset(34 * scale, -36 * scale),
      radius: 24 * scale,
      rotation: -progress * math.pi * 2,
      scale: scale,
    );

    // 4. Connecting Film Ribbon
    final Path ribbonPath = Path();
    ribbonPath.moveTo(center.dx - 24 * scale, center.dy - 16 * scale);
    ribbonPath.cubicTo(
      center.dx + 4 * scale, center.dy - 30 * scale,
      center.dx + 16 * scale, center.dy - 20 * scale,
      center.dx + 34 * scale, center.dy - 12 * scale,
    );

    final Paint ribbonPaint = Paint()
      ..color = ColorConstants.darkText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    canvas.drawPath(ribbonPath, ribbonPaint);

    // 5. Studio Camera Body (Modern rounded body with brand accent)
    final RRect bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + Offset(0, 10 * scale),
        width: 82 * scale,
        height: 64 * scale,
      ),
      Radius.circular(16 * scale),
    );

    // Body Fill
    final Paint bodyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4A3E54),
          ColorConstants.darkText,
        ],
      ).createShader(bodyRRect.outerRect);
    canvas.drawRRect(bodyRRect, bodyFill);

    // Body Accent Stripe (Clipax Orange)
    final RRect accentStripe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - 41 * scale,
        center.dy + 8 * scale,
        82 * scale,
        6 * scale,
      ),
      Radius.circular(3 * scale),
    );
    final Paint stripePaint = Paint()..color = ColorConstants.primary;
    canvas.drawRRect(accentStripe, stripePaint);

    // Body Outer Stroke
    final Paint bodyStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRRect(bodyRRect, bodyStroke);

    // 6. Camera Lens (Left side)
    final Path lensPath = Path();
    final double lensLeft = center.dx - 41 * scale;
    final double lensTop = center.dy - 2 * scale;
    lensPath.moveTo(lensLeft, lensTop - 12 * scale);
    lensPath.lineTo(lensLeft - 18 * scale, lensTop - 18 * scale);
    lensPath.lineTo(lensLeft - 22 * scale, lensTop + 24 * scale);
    lensPath.lineTo(lensLeft, lensTop + 18 * scale);
    lensPath.close();

    final Paint lensPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5A4C66),
          ColorConstants.darkText,
        ],
      ).createShader(Rect.fromLTWH(lensLeft - 22 * scale, lensTop - 18 * scale, 22 * scale, 42 * scale));
    canvas.drawPath(lensPath, lensPaint);

    // Lens Ring Accent
    final Paint lensRingPaint = Paint()
      ..color = ColorConstants.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;
    canvas.drawLine(
      Offset(lensLeft - 22 * scale, lensTop - 18 * scale),
      Offset(lensLeft - 22 * scale, lensTop + 24 * scale),
      lensRingPaint,
    );

    // Glowing Lens Center
    final Paint lensGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(lensLeft - 20 * scale, lensTop + 3 * scale), 4 * scale, lensGlow);

    // 7. Tripod / Stand Base
    final Paint tripodPaint = Paint()
      ..color = ColorConstants.darkText
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    final Offset baseCenter = center + Offset(0, 42 * scale);
    canvas.drawLine(baseCenter, baseCenter + Offset(-24 * scale, 26 * scale), tripodPaint);
    canvas.drawLine(baseCenter, baseCenter + Offset(0, 28 * scale), tripodPaint);
    canvas.drawLine(baseCenter, baseCenter + Offset(24 * scale, 26 * scale), tripodPaint);

    // Tripod Joint Knob (Orange Accent)
    final Paint jointPaint = Paint()..color = ColorConstants.primary;
    canvas.drawCircle(baseCenter, 4.5 * scale, jointPaint);

    // 8. Animated Sparkles / Motion Particles
    _drawSparkle(canvas, center + Offset(-70 * scale, -28 * scale), progress, 0.0, scale);
    _drawSparkle(canvas, center + Offset(-85 * scale, 22 * scale), progress, 0.33, scale);
    _drawSparkle(canvas, center + Offset(-45 * scale, 48 * scale), progress, 0.66, scale);
  }

  void _drawFilmReel(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double scale,
  }) {
    // Outer Wheel
    final Paint outerPaint = Paint()
      ..color = ColorConstants.darkText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Orange Inner Rim
    final Paint rimPaint = Paint()
      ..color = ColorConstants.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    canvas.drawCircle(center, radius - 2 * scale, rimPaint);

    // Reel Holes (Rotating with controller)
    const int holeCount = 5;
    final double holeRadius = radius * 0.52;
    final double holeSize = radius * 0.22;

    for (int i = 0; i < holeCount; i++) {
      final double angle = rotation + (i * 2 * math.pi / holeCount);
      final Offset holeCenter = center + Offset(
        holeRadius * math.cos(angle),
        holeRadius * math.sin(angle),
      );

      final Paint holePaint = Paint()..color = Colors.white;
      canvas.drawCircle(holeCenter, holeSize, holePaint);
    }

    // Center Hub
    final Paint hubPaint = Paint()..color = ColorConstants.primary;
    canvas.drawCircle(center, radius * 0.24, hubPaint);
    final Paint hubCenter = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.1, hubCenter);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double progress, double offset, double scale) {
    final double t = (progress + offset) % 1.0;
    final double opacity = (1.0 - (2 * t - 1.0).abs()).clamp(0.0, 1.0);
    final double sparkleScale = (0.5 + 0.5 * math.sin(t * math.pi)) * scale * 5.0;

    final Paint paint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pos + Offset(-sparkleScale, 0), pos + Offset(sparkleScale, 0), paint);
    canvas.drawLine(pos + Offset(0, -sparkleScale), pos + Offset(0, sparkleScale), paint);
  }

  @override
  bool shouldRepaint(covariant _ClipaxStudioPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
