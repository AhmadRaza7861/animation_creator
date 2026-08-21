import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ClipaxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Orange Film Strip Arc on the left
    final orangePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.2
      ..strokeCap = StrokeCap.round;

    final outerRect = Rect.fromCircle(
      center: center,
      radius: radius - orangePaint.strokeWidth / 2,
    );

    // Arc covering left, top, bottom, leaving right side open (approx from 100 deg to 260 deg, i.e. 160 deg sweep)
    // In radians: start from 0.55 * pi, sweep 1.5 * pi
    canvas.drawArc(
      outerRect,
      0.6 * math.pi,
      1.55 * math.pi,
      false,
      orangePaint,
    );

    // 2. Draw sprocket holes in the film strip
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw 4 rounded sprocket holes along the arc
    // We place them at specific angles along the left side: 0.8*pi, 1.1*pi, 1.4*pi, 1.7*pi
    final holeRadius = radius - orangePaint.strokeWidth / 2;
    final holeWidth = orangePaint.strokeWidth * 0.5;
    final holeHeight = orangePaint.strokeWidth * 0.25;
    final holeAngles = [0.8 * math.pi, 1.1 * math.pi, 1.4 * math.pi, 1.7 * math.pi];

    for (final angle in holeAngles) {
      final holeCenter = center + Offset(
        holeRadius * math.cos(angle),
        holeRadius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(holeCenter.dx, holeCenter.dy);
      // Rotate the hole to align with the tangent of the circle
      canvas.rotate(angle + math.pi / 2);
      
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: holeWidth,
        height: holeHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.02)),
        holePaint,
      );
      canvas.restore();
    }

    // 3. Draw Dark Purple Play Button on the right
    final darkPurplePaint = Paint()
      ..color = AppColors.darkText
      ..style = PaintingStyle.fill;

    // Vertices of the triangle play icon
    final path = Path();
    
    // Shift slightly to the right of the center
    final triangleCenter = center + Offset(size.width * 0.08, 0);
    final triSize = size.width * 0.35;

    // Draw equilateral triangle pointing right
    path.moveTo(triangleCenter.dx - triSize * 0.35, triangleCenter.dy - triSize * 0.6);
    path.lineTo(triangleCenter.dx - triSize * 0.35, triangleCenter.dy + triSize * 0.6);
    path.lineTo(triangleCenter.dx + triSize * 0.65, triangleCenter.dy);
    path.close();

    // Use a nice rounded join path to make it look smooth and premium
    final trianglePaint = Paint()
      ..color = AppColors.darkText
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    // We can draw it as a filled path
    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
