import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProjectorAnimation extends StatefulWidget {
  final double size;

  const ProjectorAnimation({
    super.key,
    this.size = 220,
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
          painter: _ProjectorPainter(rotationProgress: _controller.value),
        );
      },
    );
  }
}

class _ProjectorPainter extends CustomPainter {
  final double rotationProgress;

  _ProjectorPainter({required this.rotationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Offset projectorCenter = Offset(w * 0.58, h * 0.58);
    final double scale = h / 200.0;

    // 1. Draw light beam from lens (towards left)
    final double pulse = 0.85 + 0.15 * math.sin(rotationProgress * math.pi * 4);
    final Path beamPath = Path();
    final Offset lensTip = projectorCenter + Offset(-65 * scale, 8 * scale);
    beamPath.moveTo(lensTip.dx, lensTip.dy - 6 * scale);
    beamPath.lineTo(0, h * 0.15);
    beamPath.lineTo(0, h * 0.85);
    beamPath.lineTo(lensTip.dx, lensTip.dy + 6 * scale);
    beamPath.close();

    final Paint beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.grey.shade300.withValues(alpha: 0.45 * pulse),
          Colors.grey.shade100.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, lensTip.dx, h));

    canvas.drawPath(beamPath, beamPaint);

    // 2. Soft Shadow under projector
    final Rect shadowRect = Rect.fromCenter(
      center: projectorCenter + Offset(0, 52 * scale),
      width: 120 * scale,
      height: 18 * scale,
    );
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(shadowRect, shadowPaint);

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF4A4E53)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint bodyPaint = Paint()
      ..color = const Color(0xFFD6DCE0)
      ..style = PaintingStyle.fill;

    final Paint darkDetailPaint = Paint()
      ..color = const Color(0xFF8B9298)
      ..style = PaintingStyle.fill;

    // 3. Film strip connector between reels and body
    final Path filmLine = Path();
    final Offset leftReelCenter = projectorCenter + Offset(-24 * scale, -44 * scale);
    final Offset rightReelCenter = projectorCenter + Offset(34 * scale, -32 * scale);

    filmLine.moveTo(leftReelCenter.dx, leftReelCenter.dy);
    filmLine.quadraticBezierTo(
      projectorCenter.dx - 10 * scale,
      projectorCenter.dy - 20 * scale,
      rightReelCenter.dx,
      rightReelCenter.dy,
    );
    canvas.drawPath(
      filmLine,
      Paint()
        ..color = const Color(0xFF5A6066)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale,
    );

    // 4. Large Left Reel
    _drawFilmReel(
      canvas: canvas,
      center: leftReelCenter,
      radius: 32 * scale,
      angle: rotationProgress * math.pi * 2,
      scale: scale,
      strokePaint: strokePaint,
      bodyPaint: bodyPaint,
    );

    // 5. Smaller Right Reel
    _drawFilmReel(
      canvas: canvas,
      center: rightReelCenter,
      radius: 24 * scale,
      angle: rotationProgress * math.pi * 2 * 1.3,
      scale: scale,
      strokePaint: strokePaint,
      bodyPaint: bodyPaint,
    );

    // 6. Projector Main Body
    final Path bodyPath = Path();
    final double bx = projectorCenter.dx - 48 * scale;
    final double by = projectorCenter.dy - 8 * scale;
    final double bw = 96 * scale;
    final double bh = 56 * scale;

    bodyPath.moveTo(bx + 16 * scale, by);
    bodyPath.quadraticBezierTo(bx + bw * 0.5, by - 12 * scale, bx + bw - 14 * scale, by + 4 * scale);
    bodyPath.quadraticBezierTo(bx + bw + 4 * scale, by + bh * 0.5, bx + bw - 8 * scale, by + bh);
    bodyPath.lineTo(bx + 14 * scale, by + bh);
    bodyPath.quadraticBezierTo(bx - 8 * scale, by + bh * 0.7, bx, by + 18 * scale);
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // 7. Lens barrel (on left)
    final Rect lensRect = Rect.fromLTWH(
      bx - 16 * scale,
      by + 16 * scale,
      18 * scale,
      22 * scale,
    );
    final RRect lensRRect = RRect.fromRectAndRadius(lensRect, Radius.circular(4 * scale));
    canvas.drawRRect(lensRRect, Paint()..color = const Color(0xFFBAC0C5));
    canvas.drawRRect(lensRRect, strokePaint);

    final Rect lensTipRect = Rect.fromLTWH(
      bx - 20 * scale,
      by + 14 * scale,
      6 * scale,
      26 * scale,
    );
    final RRect lensTipRRect = RRect.fromRectAndRadius(lensTipRect, Radius.circular(3 * scale));
    canvas.drawRRect(lensTipRRect, Paint()..color = const Color(0xFF7A8187));
    canvas.drawRRect(lensTipRRect, strokePaint);

    // 8. Body Details (Knobs, vent slits, side dial)
    // Dial circles
    canvas.drawCircle(projectorCenter + Offset(-12 * scale, 6 * scale), 5 * scale, darkDetailPaint);
    canvas.drawCircle(projectorCenter + Offset(-12 * scale, 6 * scale), 5 * scale, strokePaint);
    canvas.drawCircle(projectorCenter + Offset(6 * scale, 6 * scale), 5 * scale, darkDetailPaint);
    canvas.drawCircle(projectorCenter + Offset(6 * scale, 6 * scale), 5 * scale, strokePaint);

    // Bottom dials
    canvas.drawCircle(projectorCenter + Offset(-18 * scale, 24 * scale), 4 * scale, bodyPaint);
    canvas.drawCircle(projectorCenter + Offset(-18 * scale, 24 * scale), 4 * scale, strokePaint);
    canvas.drawCircle(projectorCenter + Offset(-5 * scale, 24 * scale), 4 * scale, bodyPaint);
    canvas.drawCircle(projectorCenter + Offset(-5 * scale, 24 * scale), 4 * scale, strokePaint);

    // Vent slits (vertical bars on right side of body)
    for (int i = 0; i < 5; i++) {
      final double sx = projectorCenter.dx + (16 + i * 5) * scale;
      final double sy = projectorCenter.dy + 18 * scale;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx, sy + 12 * scale),
        Paint()
          ..color = const Color(0xFF5A6066)
          ..strokeWidth = 2.0 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawFilmReel({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double angle,
    required double scale,
    required Paint strokePaint,
    required Paint bodyPaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Outer ring
    canvas.drawCircle(Offset.zero, radius, bodyPaint);
    canvas.drawCircle(Offset.zero, radius, strokePaint);

    // Inner rim
    canvas.drawCircle(
      Offset.zero,
      radius * 0.78,
      Paint()
        ..color = const Color(0xFF5A6066)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );

    // Center hub
    canvas.drawCircle(Offset.zero, radius * 0.28, Paint()..color = const Color(0xFF7A8187));
    canvas.drawCircle(Offset.zero, radius * 0.28, strokePaint);
    canvas.drawCircle(Offset.zero, radius * 0.12, Paint()..color = Colors.white);

    // Cutout oval holes / spokes around reel
    const int holes = 5;
    for (int i = 0; i < holes; i++) {
      final double holeAngle = (i * 2 * math.pi / holes);
      final double hx = math.cos(holeAngle) * radius * 0.52;
      final double hy = math.sin(holeAngle) * radius * 0.52;

      canvas.save();
      canvas.translate(hx, hy);
      canvas.rotate(holeAngle);

      final Rect ovalRect = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.22,
        height: radius * 0.32,
      );
      canvas.drawOval(ovalRect, Paint()..color = Colors.white);
      canvas.drawOval(
        ovalRect,
        Paint()
          ..color = const Color(0xFF5A6066)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProjectorPainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress;
  }
}
