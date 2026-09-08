import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ClipaxLogoPainter extends CustomPainter {
  final double strokeProgress;
  final double playProgress;
  final double glowIntensity;
  final double shimmerPhase;

  const ClipaxLogoPainter({
    this.strokeProgress = 1.0,
    this.playProgress = 1.0,
    this.glowIntensity = 1.0,
    this.shimmerPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.19;

    final outerRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // 1. Ambient Dual-Color Radial Glow behind the logo
    if (glowIntensity > 0.01) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            ColorConstants.primary.withValues(alpha: 0.40 * glowIntensity),
            const Color(0xFF9D60CC).withValues(alpha: 0.20 * glowIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
      canvas.drawCircle(center, radius * 1.5, glowPaint);
    }

    // 2. Animated Gradient Film-Strip Arc with Neon Aura & Comet Trail
    if (strokeProgress > 0.0) {
      final sweepAngle = 1.55 * math.pi * strokeProgress.clamp(0.0, 1.0);

      // A. Outer Neon Glow Underlayer
      final glowArcPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFF9318),
            Color(0xFFFF5E3A),
            Color(0xFF9D60CC),
            Color(0xFFFF9318),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
          startAngle: 0.6 * math.pi,
          endAngle: 2.2 * math.pi,
          transform: GradientRotation(shimmerPhase * 2 * math.pi),
        ).createShader(outerRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.45
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(
        outerRect,
        0.6 * math.pi,
        sweepAngle,
        false,
        glowArcPaint,
      );

      // B. Main Sharp Gradient Film-Strip Arc
      final arcPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFF9318),
            Color(0xFFFF5E3A),
            Color(0xFF9D60CC),
            Color(0xFFFF9318),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
          startAngle: 0.6 * math.pi,
          endAngle: 2.2 * math.pi,
          transform: GradientRotation(shimmerPhase * 2 * math.pi),
        ).createShader(outerRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        outerRect,
        0.6 * math.pi,
        sweepAngle,
        false,
        arcPaint,
      );

      // C. Comet Spark Head & Glowing Trail
      if (strokeProgress < 0.99) {
        final currentAngle = 0.6 * math.pi + sweepAngle;
        final tipPos = center +
            Offset(
              (radius - strokeWidth / 2) * math.cos(currentAngle),
              (radius - strokeWidth / 2) * math.sin(currentAngle),
            );

        // Trailing micro-sparks
        for (int i = 1; i <= 4; i++) {
          final trailAngle = currentAngle - (i * 0.08);
          final trailPos = center +
              Offset(
                (radius - strokeWidth / 2) * math.cos(trailAngle),
                (radius - strokeWidth / 2) * math.sin(trailAngle),
              );
          final trailPaint = Paint()
            ..color = Colors.white.withValues(alpha: (1.0 - (i * 0.22)).clamp(0.0, 1.0))
            ..style = PaintingStyle.fill;
          canvas.drawCircle(trailPos, strokeWidth * (0.28 - (i * 0.05)), trailPaint);
        }

        // Intense glowing comet head
        final sparkGlow = Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(tipPos, strokeWidth * 0.55, sparkGlow);

        final sparkCore = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tipPos, strokeWidth * 0.30, sparkCore);
      }
    }

    // 3. Sprocket Holes popping in along the film strip
    final holeAngles = [
      0.8 * math.pi,
      1.1 * math.pi,
      1.4 * math.pi,
      1.7 * math.pi,
    ];

    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < holeAngles.length; i++) {
      final angle = holeAngles[i];
      final triggerThreshold = (angle - 0.6 * math.pi) / (1.55 * math.pi);

      if (strokeProgress >= triggerThreshold) {
        final double holeT =
            ((strokeProgress - triggerThreshold) / 0.12).clamp(0.0, 1.0);
        final double holeScale = Curves.easeOutBack.transform(holeT);

        final holeCenter = center +
            Offset(
              (radius - strokeWidth / 2) * math.cos(angle),
              (radius - strokeWidth / 2) * math.sin(angle),
            );

        canvas.save();
        canvas.translate(holeCenter.dx, holeCenter.dy);
        canvas.rotate(angle + math.pi / 2);
        canvas.scale(holeScale, holeScale);

        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: strokeWidth * 0.52,
          height: strokeWidth * 0.26,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.025)),
          holePaint,
        );
        canvas.restore();
      }
    }

    // 4. Play Button Triangle with Neon Glow & Fill
    if (playProgress > 0.01) {
      final double triScale =
          Curves.easeOutBack.transform(playProgress.clamp(0.0, 1.0));
      final triangleCenter = center + Offset(size.width * 0.08, 0);
      final triSize = size.width * 0.36 * triScale;

      final path = Path();
      path.moveTo(
          triangleCenter.dx - triSize * 0.35, triangleCenter.dy - triSize * 0.6);
      path.lineTo(
          triangleCenter.dx - triSize * 0.35, triangleCenter.dy + triSize * 0.6);
      path.lineTo(triangleCenter.dx + triSize * 0.65, triangleCenter.dy);
      path.close();

      // Soft purple glow shadow behind play triangle
      final shadowPaint = Paint()
        ..color = const Color(0xFF9D60CC).withValues(alpha: 0.65 * playProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawPath(path, shadowPaint);

      // Dark obsidian-purple gradient fill
      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF2C2433),
            Color(0xFF19141F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCenter(
            center: triangleCenter, width: triSize, height: triSize))
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Golden accent border around play triangle
      final borderPaint = Paint()
        ..color = ColorConstants.primary.withValues(alpha: 0.85 * playProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ClipaxLogoPainter oldDelegate) {
    return oldDelegate.strokeProgress != strokeProgress ||
        oldDelegate.playProgress != playProgress ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.shimmerPhase != shimmerPhase;
  }
}
