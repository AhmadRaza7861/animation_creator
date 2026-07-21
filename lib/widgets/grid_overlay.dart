import 'package:flutter/material.dart';

class GridOverlay extends StatelessWidget {
  const GridOverlay({
    super.key,
    required this.opacity,
    required this.verticalSpacing,
    required this.horizontalSpacing,
  });

  final double opacity;
  final double verticalSpacing;
  final double horizontalSpacing;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(
          opacity: opacity,
          verticalSpacing: verticalSpacing,
          horizontalSpacing: horizontalSpacing,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.opacity,
    required this.verticalSpacing,
    required this.horizontalSpacing,
  });

  final double opacity;
  final double verticalSpacing;
  final double horizontalSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0 || verticalSpacing <= 0.0 || horizontalSpacing <= 0.0) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFFE91E63).withOpacity(opacity) // Pink color matching competitor
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0.0; x <= size.width; x += verticalSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0.0; y <= size.height; y += horizontalSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.verticalSpacing != verticalSpacing ||
        oldDelegate.horizontalSpacing != horizontalSpacing;
  }
}
