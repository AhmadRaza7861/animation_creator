import 'dart:math';
import 'package:flutter/material.dart';

class PreviewPatternPainter extends CustomPainter {
  final String pattern;
  const PreviewPatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    if (pattern == 'grid') {
      const double spacing = 15.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pattern == 'dots') {
      const double spacing = 15.0;
      final dotPaint = Paint()..color = Colors.black.withOpacity(0.15);
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    } else if (pattern == 'lines') {
      const double spacing = 18.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.2)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(30, 0), Offset(30, size.height), marginPaint);
    } else if (pattern == 'checkboard') {
      const double spacing = 20.0;
      final cellPaint = Paint()..color = Colors.black.withOpacity(0.04);
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          if (((x / spacing).floor() + (y / spacing).floor()) % 2 == 0) {
            canvas.drawRect(Rect.fromLTWH(x, y, spacing, spacing), cellPaint);
          }
        }
      }
    } else if (pattern == 'isometric') {
      const double spacing = 16.0;
      final double h = spacing * 0.866025;
      for (double x = 0; x < size.width + spacing; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      final double slope = 0.57735;
      for (double y = -size.width * slope; y < size.height; y += h * 2) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * slope), paint);
        canvas.drawLine(Offset(0, y + size.width * slope), Offset(size.width, y), paint);
      }
    } else if (pattern == 'blueprint') {
      final bpPaint = Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..strokeWidth = 1.0;
      const double spacing = 16.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), bpPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), bpPaint);
      }
    } else if (pattern == 'graph') {
      final minorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.08)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = const Color(0xFF81B214).withOpacity(0.2)
        ..strokeWidth = 1.0;
      const double minorSpacing = 6.0;
      const double majorSpacing = 30.0;
      for (double x = 0; x < size.width; x += minorSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % majorSpacing == 0) ? majorPaint : minorPaint);
      }
      for (double y = 0; y < size.height; y += minorSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), (y % majorSpacing == 0) ? majorPaint : minorPaint);
      }
    } else if (pattern == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
      for (double r = 20.0; r < maxRadius; r += 20.0) {
        canvas.drawCircle(center, r, paint);
      }
      for (int angle = 0; angle < 360; angle += 30) {
        final rad = angle * pi / 180;
        final end = center + Offset(cos(rad) * maxRadius, sin(rad) * maxRadius);
        canvas.drawLine(center, end, paint);
      }
    } else if (pattern == 'brick') {
      const double brickW = 30.0;
      const double brickH = 15.0;
      int rowIndex = 0;
      for (double y = 0; y < size.height + brickH; y += brickH) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        final double offset = (rowIndex % 2 == 0) ? 0 : brickW / 2;
        for (double x = -offset; x < size.width + brickW; x += brickW) {
          canvas.drawLine(Offset(x, y), Offset(x, y + brickH), paint);
        }
        rowIndex++;
      }
    } else if (pattern == 'music') {
      const double lineSpacing = 6.0;
      const double groupSpacing = 28.0;
      double y = 15.0;
      while (y < size.height - 20.0) {
        for (int i = 0; i < 5; i++) {
          final double py = y + i * lineSpacing;
          canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
        }
        y += 4 * lineSpacing + groupSpacing;
      }
    } else if (pattern == 'hex') {
      const double r = 12.0;
      final double h = r * sin(pi / 3);
      final path = Path();
      for (double x = 0; x < size.width + r * 2; x += r * 3) {
        int col = 0;
        for (double y = 0; y < size.height + r * 2; y += h) {
          final double ox = (col % 2 == 0) ? 0 : r * 1.5;
          path.moveTo(ox + x, y);
          path.lineTo(ox + x + r / 2, y + h);
          path.lineTo(ox + x + r * 1.5, y + h);
          path.lineTo(ox + x + r * 2, y);
          col++;
        }
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    } else if (pattern == 'cross') {
      const double spacing = 18.0;
      const double crossSize = 2.0;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), paint);
          canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
