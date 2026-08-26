import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedDashedBorder extends StatefulWidget {
  const AnimatedDashedBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFF2196F3),
    this.strokeWidth = 1.0,
    this.dashLength = 5.0,
    this.dashGap = 5.0,
    this.borderRadius,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double? borderRadius;

  @override
  State<AnimatedDashedBorder> createState() => _AnimatedDashedBorderState();
}

class _AnimatedDashedBorderState extends State<AnimatedDashedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
          painter: _DashedBorderPainter(
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            dashLength: widget.dashLength,
            dashGap: widget.dashGap,
            phase: _controller.value * (widget.dashLength + widget.dashGap),
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.phase,
    this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double phase;
  final double? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    if (borderRadius != null && borderRadius! > 0) {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius!),
      ));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final Path destPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = -phase;
      bool draw = true;
      while (distance < metric.length) {
        final double advance = draw ? dashLength : dashGap;
        if (draw) {
          final double start = distance.clamp(0.0, metric.length);
          final double end = (distance + advance).clamp(0.0, metric.length);
          if (end > start) {
            destPath.addPath(metric.extractPath(start, end), Offset.zero);
          }
        }
        distance += advance;
        draw = !draw;
      }
    }
    canvas.drawPath(destPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
