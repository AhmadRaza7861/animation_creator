import 'dart:math';
import 'package:flutter/material.dart';

/// Helper to provide the ideal background base color for each preset pattern.
class PatternBackgroundHelper {
  static Color getBaseColor(String? pattern, [Color defaultColor = Colors.white]) {
    if (pattern == null || pattern == 'none') return defaultColor;
    switch (pattern) {
      case 'blueprint':
        return const Color(0xFF1E3D59);
      case 'graph':
        return const Color(0xFFF1F8F6);
      case 'animation_field':
        return const Color(0xFFFAF7F2);
      case 'dark_cyber':
        return const Color(0xFF0B0F19);
      case 'chalkboard':
        return const Color(0xFF1B2A32);
      case 'parchment':
        return const Color(0xFFF6EEDA);
      case 'safe_area':
        return const Color(0xFF141A24);
      case 'cinematic':
        return const Color(0xFF10141D);
      case 'storyboard':
        return const Color(0xFFF1F3F5);
      case 'pixel_grid':
        return const Color(0xFFF0F4F8);
      case 'halftone':
        return const Color(0xFFFCFCFB);
      case 'perspective_1p':
      case 'perspective_2p':
      case 'perspective_3p':
      case 'speed_lines':
      case 'iso_cubes':
      case 'rule_of_thirds':
      case 'golden_spiral':
        return const Color(0xFFF8FAFC);
      default:
        return defaultColor;
    }
  }
}

/// CustomPainter for all Background Presets, providing clean, high-performance
/// vector renderings for previews, editor canvas, and video/GIF exports.
class PreviewPatternPainter extends CustomPainter {
  final String pattern;
  const PreviewPatternPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final defaultPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.0;

    switch (pattern) {
      case 'grid':
        _paintGrid(canvas, size, defaultPaint);
        break;
      case 'dots':
        _paintDots(canvas, size);
        break;
      case 'lines':
        _paintLines(canvas, size);
        break;
      case 'checkboard':
        _paintCheckerboard(canvas, size);
        break;
      case 'isometric':
        _paintIsometric(canvas, size, defaultPaint);
        break;
      case 'blueprint':
        _paintBlueprint(canvas, size);
        break;
      case 'graph':
        _paintGraph(canvas, size);
        break;
      case 'polar':
        _paintPolar(canvas, size, defaultPaint);
        break;
      case 'brick':
        _paintBrick(canvas, size, defaultPaint);
        break;
      case 'music':
        _paintMusic(canvas, size, defaultPaint);
        break;
      case 'hex':
        _paintHex(canvas, size, defaultPaint);
        break;
      case 'cross':
        _paintCross(canvas, size, defaultPaint);
        break;
      case 'animation_field':
        _paintAnimationField(canvas, size);
        break;
      case 'perspective_1p':
        _paintPerspective1P(canvas, size);
        break;
      case 'perspective_2p':
        _paintPerspective2P(canvas, size);
        break;
      case 'perspective_3p':
        _paintPerspective3P(canvas, size);
        break;
      case 'speed_lines':
        _paintSpeedLines(canvas, size);
        break;
      case 'halftone':
        _paintHalftone(canvas, size);
        break;
      case 'storyboard':
        _paintStoryboard(canvas, size);
        break;
      case 'rule_of_thirds':
        _paintRuleOfThirds(canvas, size);
        break;
      case 'safe_area':
        _paintSafeArea(canvas, size);
        break;
      case 'dark_cyber':
        _paintDarkCyber(canvas, size);
        break;
      case 'parchment':
        _paintParchment(canvas, size);
        break;
      case 'chalkboard':
        _paintChalkboard(canvas, size);
        break;
      case 'pixel_grid':
        _paintPixelGrid(canvas, size);
        break;
      case 'iso_cubes':
        _paintIsoCubes(canvas, size);
        break;
      case 'cinematic':
        _paintCinematic(canvas, size);
        break;
      case 'golden_spiral':
        _paintGoldenSpiral(canvas, size);
        break;
      default:
        break;
    }
  }

  void _paintGrid(Canvas canvas, Size size, Paint paint) {
    final double spacing = (size.width < 300) ? 15.0 : 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final double spacing = (size.width < 300) ? 15.0 : 20.0;
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.16);
    final double dotRadius = (size.width < 300) ? 1.0 : 1.5;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size) {
    final double spacing = (size.width < 300) ? 18.0 : 24.0;
    final linePaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.12)
      ..strokeWidth = 1.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final double marginX = (size.width < 300) ? 30.0 : 40.0;
    final marginPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.25)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
  }

  void _paintCheckerboard(Canvas canvas, Size size) {
    final double spacing = (size.width < 300) ? 20.0 : 28.0;
    final cellPaint = Paint()..color = Colors.black.withOpacity(0.04);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if (((x / spacing).floor() + (y / spacing).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, spacing, spacing), cellPaint);
        }
      }
    }
  }

  void _paintIsometric(Canvas canvas, Size size, Paint paint) {
    final double spacing = (size.width < 300) ? 16.0 : 24.0;
    final double h = spacing * 0.866025;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final double slope = 0.57735;
    for (double y = -size.width * slope; y < size.height + size.width * slope; y += h * 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * slope), paint);
      canvas.drawLine(Offset(0, y + size.width * slope), Offset(size.width, y), paint);
    }
  }

  void _paintBlueprint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = const Color(0xFF64B5F6).withOpacity(0.28)
      ..strokeWidth = 1.0;
    final minorPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 0.5;

    final double minorSpacing = (size.width < 300) ? 8.0 : 12.0;
    final double majorSpacing = minorSpacing * 4;

    for (double x = 0; x < size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }
    for (double y = 0; y < size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }
  }

  void _paintGraph(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.09)
      ..strokeWidth = 0.5;
    final majorPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.24)
      ..strokeWidth = 1.0;

    final double minorSpacing = (size.width < 300) ? 8.0 : 10.0;
    final double majorSpacing = minorSpacing * 5;

    for (double x = 0; x < size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }
    for (double y = 0; y < size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }
  }

  void _paintPolar(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
    final double step = (size.width < 300) ? 20.0 : 35.0;

    for (double r = step; r < maxRadius; r += step) {
      canvas.drawCircle(center, r, paint);
    }
    for (int angle = 0; angle < 360; angle += 30) {
      final rad = angle * pi / 180;
      final end = center + Offset(cos(rad) * maxRadius, sin(rad) * maxRadius);
      canvas.drawLine(center, end, paint);
    }
  }

  void _paintBrick(Canvas canvas, Size size, Paint paint) {
    final double brickW = (size.width < 300) ? 30.0 : 40.0;
    final double brickH = brickW / 2;
    int rowIndex = 0;
    for (double y = 0; y < size.height + brickH; y += brickH) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      final double offset = (rowIndex % 2 == 0) ? 0 : brickW / 2;
      for (double x = -offset; x < size.width + brickW; x += brickW) {
        canvas.drawLine(Offset(x, y), Offset(x, y + brickH), paint);
      }
      rowIndex++;
    }
  }

  void _paintMusic(Canvas canvas, Size size, Paint paint) {
    final double lineSpacing = (size.width < 300) ? 6.0 : 8.0;
    final double groupSpacing = (size.width < 300) ? 28.0 : 40.0;
    double y = (size.width < 300) ? 15.0 : 25.0;
    while (y < size.height - 20.0) {
      for (int i = 0; i < 5; i++) {
        final double py = y + i * lineSpacing;
        canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
      }
      y += 4 * lineSpacing + groupSpacing;
    }
  }

  void _paintHex(Canvas canvas, Size size, Paint paint) {
    final double r = (size.width < 300) ? 12.0 : 18.0;
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
  }

  void _paintCross(Canvas canvas, Size size, Paint paint) {
    final double spacing = (size.width < 300) ? 18.0 : 25.0;
    final double crossSize = (size.width < 300) ? 2.5 : 3.5;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), paint);
        canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), paint);
      }
    }
  }

  // ==================== NEW CREATIVE & ATTRACTIVE PRESETS ====================

  /// 1. Classic Disney / Anime 12-Field Animation Chart
  void _paintAnimationField(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final guidePaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final majorPaint = Paint()
      ..color = const Color(0xFF1E40AF).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Center Crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), majorPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), majorPaint);
    canvas.drawCircle(center, 4.0, majorPaint);
    canvas.drawCircle(center, (size.width < 300) ? 12.0 : 20.0, guidePaint);

    // 12-Field nested framing boxes (Fields: 12, 10, 8, 6, 4)
    final double marginX = size.width * 0.06;
    final double marginY = size.height * 0.06;
    final double fieldW = (size.width - 2 * marginX) / 12;
    final double fieldH = (size.height - 2 * marginY) / 12;

    for (int f in [12, 10, 8, 6, 4]) {
      final double halfW = (f / 2) * fieldW;
      final double halfH = (f / 2) * fieldH;
      final rect = Rect.fromCenter(center: center, width: halfW * 2, height: halfH * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(f == 12 ? 8 : 4)),
        f == 12 ? majorPaint : guidePaint,
      );
    }

    // Traditional Top & Bottom Peg registration markings
    final pegPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double pegOffset = (size.width < 300) ? 10.0 : 16.0;
    final double pegRadius = (size.width < 300) ? 3.0 : 5.0;

    // Top Pegs (Center Round Peg + Left/Right oblong pegs)
    canvas.drawCircle(Offset(center.dx, pegOffset), pegRadius, pegPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - size.width * 0.28, pegOffset), width: pegRadius * 2.8, height: pegRadius * 1.6),
        const Radius.circular(2),
      ),
      pegPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + size.width * 0.28, pegOffset), width: pegRadius * 2.8, height: pegRadius * 1.6),
        const Radius.circular(2),
      ),
      pegPaint,
    );

    // Bottom Pegs
    canvas.drawCircle(Offset(center.dx, size.height - pegOffset), pegRadius, pegPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - size.width * 0.28, size.height - pegOffset), width: pegRadius * 2.8, height: pegRadius * 1.6),
        const Radius.circular(2),
      ),
      pegPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + size.width * 0.28, size.height - pegOffset), width: pegRadius * 2.8, height: pegRadius * 1.6),
        const Radius.circular(2),
      ),
      pegPaint,
    );
  }

  /// 2. 1-Point Central Perspective Guide
  void _paintPerspective1P(Canvas canvas, Size size) {
    final horizonY = size.height * 0.52;
    final vp = Offset(size.width * 0.5, horizonY);

    final horizonPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.4)
      ..strokeWidth = 1.5;
    final rayPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.18)
      ..strokeWidth = 1.0;
    final groundPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.15)
      ..strokeWidth = 0.8;

    // Horizon line
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    // Vanishing Point indicator
    canvas.drawCircle(vp, 3.5, Paint()..color = const Color(0xFF3B82F6).withOpacity(0.6));

    // Radiating rays to top, bottom, left, right edges
    const int rayCount = 20;
    for (int i = 0; i <= rayCount; i++) {
      final double t = i / rayCount;
      // Bottom edge rays
      canvas.drawLine(vp, Offset(t * size.width, size.height), rayPaint);
      // Top edge rays
      canvas.drawLine(vp, Offset(t * size.width, 0), rayPaint);
    }
    for (int i = 1; i < 8; i++) {
      final double t = i / 8;
      canvas.drawLine(vp, Offset(0, t * size.height), rayPaint);
      canvas.drawLine(vp, Offset(size.width, t * size.height), rayPaint);
    }

    // Foreshortened horizontal ground perspective rungs
    for (int i = 1; i <= 8; i++) {
      final double norm = pow(i / 8, 2.2).toDouble();
      final double y = horizonY + (size.height - horizonY) * norm;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), groundPaint);
    }
  }

  /// 3. 2-Point Perspective Guide (Dual Vanishing Points)
  void _paintPerspective2P(Canvas canvas, Size size) {
    final horizonY = size.height * 0.55;
    final vp1 = Offset(-size.width * 0.15, horizonY);
    final vp2 = Offset(size.width * 1.15, horizonY);

    final horizonPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.4)
      ..strokeWidth = 1.4;
    final vp1Paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.15)
      ..strokeWidth = 0.9;
    final vp2Paint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.15)
      ..strokeWidth = 0.9;
    final vertPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 0.8;

    // Horizon
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    // Rays from Left VP1
    for (double y = 0; y <= size.height; y += size.height / 10) {
      canvas.drawLine(vp1, Offset(size.width, y), vp1Paint);
    }
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(vp1, Offset(x, size.height), vp1Paint);
    }

    // Rays from Right VP2
    for (double y = 0; y <= size.height; y += size.height / 10) {
      canvas.drawLine(vp2, Offset(0, y), vp2Paint);
    }
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(vp2, Offset(x, size.height), vp2Paint);
    }

    // Vertical pillars for architectural scale
    for (double x = size.width * 0.2; x < size.width; x += size.width * 0.2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vertPaint);
    }
  }

  /// 4. 3-Point Dynamic Perspective (Cinematic Bird's / Worm's Eye View)
  void _paintPerspective3P(Canvas canvas, Size size) {
    final horizonY = size.height * 0.25;
    final vp1 = Offset(-size.width * 0.2, horizonY);
    final vp2 = Offset(size.width * 1.2, horizonY);
    final vp3 = Offset(size.width * 0.5, size.height * 1.4);

    final horizonPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.35)
      ..strokeWidth = 1.2;
    final rayPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.14)
      ..strokeWidth = 0.8;
    final vertRayPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.18)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);

    // Rays towards VP3 (vertical convergence)
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), vp3, vertRayPaint);
    }

    // Left and Right VP rays
    for (double y = horizonY; y <= size.height; y += (size.height - horizonY) / 7) {
      canvas.drawLine(vp1, Offset(size.width, y), rayPaint);
      canvas.drawLine(vp2, Offset(0, y), rayPaint);
    }
  }

  /// 5. Manga Speed Lines / Anime Action Burst Focus
  void _paintSpeedLines(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
    final innerRadius = min(size.width, size.height) * 0.24;

    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    const int rayCount = 48;
    for (int i = 0; i < rayCount; i++) {
      final double angle = (i * 2 * pi / rayCount) + (i % 3 == 0 ? 0.02 : -0.01);
      final double cosA = cos(angle);
      final double sinA = sin(angle);

      final double currentInner = innerRadius + (i % 4) * 6.0;
      final start = center + Offset(cosA * currentInner, sinA * currentInner);
      final end = center + Offset(cosA * maxRadius, sinA * maxRadius);

      linePaint.strokeWidth = (i % 3 == 0) ? 1.8 : 1.0;
      linePaint.color = Colors.black.withOpacity((i % 2 == 0) ? 0.16 : 0.08);
      canvas.drawLine(start, end, linePaint);
    }

    // Subtle inner focal ring
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  /// 6. Manga Screentone (45-degree Comic Halftone Dots)
  void _paintHalftone(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.14);
    final double spacing = (size.width < 300) ? 10.0 : 14.0;
    final double dotRadius = (size.width < 300) ? 1.2 : 1.6;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(pi / 4);

    final double diag = sqrt(size.width * size.width + size.height * size.height);
    for (double x = -diag; x < diag; x += spacing) {
      for (double y = -diag; y < diag; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
    canvas.restore();
  }

  /// 7. Storyboard 6-Panel Layout with Dialogue Margins
  void _paintStoryboard(Canvas canvas, Size size) {
    const int cols = 2;
    const int rows = 3;
    final double paddingX = size.width * 0.04;
    final double paddingY = size.height * 0.04;
    final double gapX = size.width * 0.04;
    final double gapY = size.height * 0.03;

    final double cellW = (size.width - 2 * paddingX - (cols - 1) * gapX) / cols;
    final double cellH = (size.height - 2 * paddingY - (rows - 1) * gapY) / rows;
    final double frameH = cellH * 0.72;

    final frameBg = Paint()..color = Colors.white;
    final frameBorder = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final noteLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    final badgePaint = Paint()..color = const Color(0xFF64748B).withOpacity(0.25);

    int panelNum = 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = paddingX + c * (cellW + gapX);
        final double y = paddingY + r * (cellH + gapY);

        // Frame Screen
        final frameRect = Rect.fromLTWH(x, y, cellW, frameH);
        canvas.drawRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(5)), frameBg);
        canvas.drawRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(5)), frameBorder);

        // Panel Number Badge
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, y + 4, 14, 10), const Radius.circular(3)),
          badgePaint,
        );

        // Action / Dialogue Note lines below screen
        final double line1Y = y + frameH + (cellH - frameH) * 0.35;
        final double line2Y = y + frameH + (cellH - frameH) * 0.70;
        canvas.drawLine(Offset(x + 4, line1Y), Offset(x + cellW - 4, line1Y), noteLinePaint);
        canvas.drawLine(Offset(x + 4, line2Y), Offset(x + cellW * 0.7, line2Y), noteLinePaint);

        panelNum++;
      }
    }
  }

  /// 8. Cinematic Rule of Thirds & Golden Power Points
  void _paintRuleOfThirds(Canvas canvas, Size size) {
    final thirdLinePaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.4)
      ..strokeWidth = 1.2;
    final diagonalPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.18)
      ..strokeWidth = 0.8;
    final powerPointPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), diagonalPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagonalPaint);

    final double x1 = size.width / 3;
    final double x2 = 2 * size.width / 3;
    final double y1 = size.height / 3;
    final double y2 = 2 * size.height / 3;

    // 1/3 and 2/3 vertical & horizontal lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), thirdLinePaint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), thirdLinePaint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), thirdLinePaint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), thirdLinePaint);

    // 4 Golden Intersection Power Points
    final double ringRadius = (size.width < 300) ? 6.0 : 9.0;
    for (final pt in [
      Offset(x1, y1),
      Offset(x2, y1),
      Offset(x1, y2),
      Offset(x2, y2),
    ]) {
      canvas.drawCircle(pt, ringRadius, powerPointPaint);
      canvas.drawCircle(pt, 2.0, Paint()..color = const Color(0xFFF59E0B));
    }
  }

  /// 9. Broadcast Action Safe & Title Safe Area
  void _paintSafeArea(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final actionSafePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final titleSafePaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.0;

    // Action Safe (90% boundary)
    final actionRect = Rect.fromCenter(center: center, width: size.width * 0.90, height: size.height * 0.90);
    canvas.drawRect(actionRect, actionSafePaint);

    // Title Safe (80% boundary)
    final titleRect = Rect.fromCenter(center: center, width: size.width * 0.80, height: size.height * 0.80);
    canvas.drawRect(titleRect, titleSafePaint);

    // Corner L-Brackets on 90% boundary
    final double tick = (size.width < 300) ? 8.0 : 14.0;
    final tickPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.8)
      ..strokeWidth = 2.0;

    // Top-Left
    canvas.drawLine(actionRect.topLeft, actionRect.topLeft + Offset(tick, 0), tickPaint);
    canvas.drawLine(actionRect.topLeft, actionRect.topLeft + Offset(0, tick), tickPaint);
    // Top-Right
    canvas.drawLine(actionRect.topRight, actionRect.topRight - Offset(tick, 0), tickPaint);
    canvas.drawLine(actionRect.topRight, actionRect.topRight + Offset(0, tick), tickPaint);
    // Bottom-Left
    canvas.drawLine(actionRect.bottomLeft, actionRect.bottomLeft + Offset(tick, 0), tickPaint);
    canvas.drawLine(actionRect.bottomLeft, actionRect.bottomLeft - Offset(0, tick), tickPaint);
    // Bottom-Right
    canvas.drawLine(actionRect.bottomRight, actionRect.bottomRight - Offset(tick, 0), tickPaint);
    canvas.drawLine(actionRect.bottomRight, actionRect.bottomRight - Offset(0, tick), tickPaint);

    // Center Crosshair
    final double crossLen = (size.width < 300) ? 12.0 : 18.0;
    canvas.drawLine(center - Offset(crossLen, 0), center + Offset(crossLen, 0), crosshairPaint);
    canvas.drawLine(center - Offset(0, crossLen), center + Offset(0, crossLen), crosshairPaint);
    canvas.drawCircle(center, crossLen * 0.6, crosshairPaint..style = PaintingStyle.stroke);
  }

  /// 10. Dark Cyber Neon Grid (Cyberpunk / Sci-Fi Matrix)
  void _paintDarkCyber(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.14)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.35)
      ..strokeWidth = 1.2;
    final magentaDot = Paint()..color = const Color(0xFFEC4899).withOpacity(0.7);

    final double minorSpacing = (size.width < 300) ? 14.0 : 20.0;
    final double majorSpacing = minorSpacing * 4;

    for (double x = 0; x < size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }
    for (double y = 0; y < size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing).abs() < 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }

    // Glowing magenta nodes at major intersections
    for (double x = 0; x < size.width; x += majorSpacing) {
      for (double y = 0; y < size.height; y += majorSpacing) {
        canvas.drawCircle(Offset(x, y), 2.2, magentaDot);
      }
    }
  }

  /// 11. Vintage Parchment (Antique Manuscript & Calligraphy Guides)
  void _paintParchment(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final innerBorderPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final rulePaint = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.12)
      ..strokeWidth = 0.8;

    final double margin = (size.width < 300) ? 10.0 : 16.0;
    final double innerMargin = margin + ((size.width < 300) ? 4.0 : 6.0);

    // Double ornamental perimeter frame
    canvas.drawRect(Rect.fromLTWH(margin, margin, size.width - 2 * margin, size.height - 2 * margin), borderPaint);
    canvas.drawRect(Rect.fromLTWH(innerMargin, innerMargin, size.width - 2 * innerMargin, size.height - 2 * innerMargin), innerBorderPaint);

    // Corner decorative diamond marks
    final diamondPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    for (final pt in [
      Offset(margin, margin),
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      Offset(size.width - margin, size.height - margin),
    ]) {
      final path = Path()
        ..moveTo(pt.dx, pt.dy - 3)
        ..lineTo(pt.dx + 3, pt.dy)
        ..lineTo(pt.dx, pt.dy + 3)
        ..lineTo(pt.dx - 3, pt.dy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }

    // Horizontal antique ruling lines
    final double spacing = (size.width < 300) ? 18.0 : 26.0;
    for (double y = innerMargin + spacing; y < size.height - innerMargin - 10; y += spacing) {
      canvas.drawLine(Offset(innerMargin, y), Offset(size.width - innerMargin, y), rulePaint);
    }
  }

  /// 12. Chalkboard Slate (Matte Blackboard & Chalk Grid)
  void _paintChalkboard(Canvas canvas, Size size) {
    final chalkGrid = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0;
    final chalkBorder = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double spacing = (size.width < 300) ? 18.0 : 25.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), chalkGrid);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), chalkGrid);
    }

    // Outer chalk frame
    final double margin = (size.width < 300) ? 6.0 : 10.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(margin, margin, size.width - 2 * margin, size.height - 2 * margin), const Radius.circular(6)),
      chalkBorder,
    );
  }

  /// 13. Retro Pixel Art Grid (8-bit micro grid + 8x8 character cell guides)
  void _paintPixelGrid(Canvas canvas, Size size) {
    final subPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.08)
      ..strokeWidth = 0.5;
    final blockPaint = Paint()
      ..color = const Color(0xFF4F46E5).withOpacity(0.25)
      ..strokeWidth = 1.2;

    const double subSpacing = 8.0;
    const double blockSpacing = subSpacing * 8; // 64px character block

    for (double x = 0; x < size.width; x += subSpacing) {
      final isBlock = (x % blockSpacing).abs() < 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isBlock ? blockPaint : subPaint);
    }
    for (double y = 0; y < size.height; y += subSpacing) {
      final isBlock = (y % blockSpacing).abs() < 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isBlock ? blockPaint : subPaint);
    }
  }

  /// 14. 3D Isometric Tumbling Cubes Wireframe
  void _paintIsoCubes(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = const Color(0xFF475569).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double s = (size.width < 300) ? 22.0 : 32.0;
    final double dx = s * cos(pi / 6);
    final double dy = s * sin(pi / 6);

    for (double y = 0; y < size.height + 2 * s; y += 3 * dy) {
      for (double x = 0; x < size.width + 2 * s; x += 2 * dx) {
        final center = Offset(x, y);

        // Top vertex, bottom vertex, left vertex, right vertex
        final top = center - Offset(0, s);
        final bottom = center + Offset(0, s);
        final leftTop = center + Offset(-dx, -dy);
        final leftBottom = center + Offset(-dx, dy);
        final rightTop = center + Offset(dx, -dy);
        final rightBottom = center + Offset(dx, dy);

        // Draw 3D Cube lines
        canvas.drawLine(center, top, edgePaint);
        canvas.drawLine(center, leftBottom, edgePaint);
        canvas.drawLine(center, rightBottom, edgePaint);

        canvas.drawLine(top, rightTop, edgePaint);
        canvas.drawLine(rightTop, rightBottom, edgePaint);
        canvas.drawLine(rightBottom, bottom, edgePaint);
        canvas.drawLine(bottom, leftBottom, edgePaint);
        canvas.drawLine(leftBottom, leftTop, edgePaint);
        canvas.drawLine(leftTop, top, edgePaint);
      }
    }
  }

  /// 15. Cinematic 2.39:1 Anamorphic Widescreen Letterbox
  void _paintCinematic(Canvas canvas, Size size) {
    // 2.39:1 aperture window
    final double windowH = min(size.height, size.width / 2.39);
    final double letterboxH = (size.height - windowH) / 2;

    final matPaint = Paint()..color = const Color(0xFF030712).withOpacity(0.85);
    final frameBorder = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final crossPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Top and Bottom Letterbox Bars
    if (letterboxH > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, letterboxH), matPaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height - letterboxH, size.width, letterboxH), matPaint);
    }

    // Active 2.39:1 frame border
    final activeRect = Rect.fromLTWH(0, letterboxH, size.width, windowH);
    canvas.drawRect(activeRect, frameBorder);

    // Center crosshair in frame
    final center = Offset(size.width / 2, size.height / 2);
    final double cl = (size.width < 300) ? 10.0 : 16.0;
    canvas.drawLine(center - Offset(cl, 0), center + Offset(cl, 0), crossPaint);
    canvas.drawLine(center - Offset(0, cl), center + Offset(0, cl), crossPaint);
  }

  /// 16. Golden Spiral (Fibonacci Logarithmic Spiral & Proportions)
  void _paintGoldenSpiral(Canvas canvas, Size size) {
    final rectPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final spiralPaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    // Outer frame
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), rectPaint);

    // Construct recursive golden rectangles and spiral arcs
    double x = 0;
    double y = 0;
    double w = size.width;
    double h = size.height;

    final spiralPath = Path();
    bool isFirst = true;

    for (int i = 0; i < 7; i++) {
      if (w < 4 || h < 4) break;

      if (i % 4 == 0) {
        // Square on left
        final double sq = min(w, h);
        final rect = Rect.fromLTWH(x, y, sq, sq);
        canvas.drawRect(rect, rectPaint);
        if (isFirst) {
          spiralPath.moveTo(x, y + sq);
          isFirst = false;
        }
        spiralPath.arcTo(rect, pi / 2, pi / 2, false);
        x += sq;
        w -= sq;
      } else if (i % 4 == 1) {
        // Square on top
        final double sq = min(w, h);
        final rect = Rect.fromLTWH(x, y, sq, sq);
        canvas.drawRect(rect, rectPaint);
        spiralPath.arcTo(rect, pi, pi / 2, false);
        y += sq;
        h -= sq;
      } else if (i % 4 == 2) {
        // Square on right
        final double sq = min(w, h);
        final rect = Rect.fromLTWH(x + w - sq, y, sq, sq);
        canvas.drawRect(rect, rectPaint);
        spiralPath.arcTo(rect, 3 * pi / 2, pi / 2, false);
        w -= sq;
      } else {
        // Square on bottom
        final double sq = min(w, h);
        final rect = Rect.fromLTWH(x, y + h - sq, sq, sq);
        canvas.drawRect(rect, rectPaint);
        spiralPath.arcTo(rect, 0, pi / 2, false);
        h -= sq;
      }
    }

    canvas.drawPath(spiralPath, spiralPaint);
  }

  @override
  bool shouldRepaint(covariant PreviewPatternPainter oldDelegate) => oldDelegate.pattern != pattern;
}
