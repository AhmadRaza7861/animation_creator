import 'dart:math';
import 'package:flutter/material.dart';

enum RulerType { none, line, circle, box, mirror }

/// 画板尺子指导线配置
/// Ruler configuration for guidelines
class RulerConfig {
  RulerConfig({
    this.type = RulerType.none,
    this.isLocked = false,
    this.center = const Offset(150, 150),
    this.scale = 100.0,
    this.scaleY = 100.0,
    this.angle = 0.0,
  });

  final RulerType type;
  final bool isLocked;
  final Offset center;
  
  /// 圆的半径、线或盒子的宽度(width / 2)
  /// Radius for circle, half-width for line or box
  final double scale;
  
  /// 盒子的高度(height / 2)
  /// Half-height for box
  final double scaleY;
  
  /// 旋转角度（弧度）
  /// Rotation angle in radians
  final double angle;

  RulerConfig copyWith({
    RulerType? type,
    bool? isLocked,
    Offset? center,
    double? scale,
    double? scaleY,
    double? angle,
  }) {
    return RulerConfig(
      type: type ?? this.type,
      isLocked: isLocked ?? this.isLocked,
      center: center ?? this.center,
      scale: scale ?? this.scale,
      scaleY: scaleY ?? this.scaleY,
      angle: angle ?? this.angle,
    );
  }

  /// 将输入坐标吸附到当前有效的尺子轨迹上
  /// Project input coordinates onto the active ruler trace
  Offset projectPoint(Offset p, Offset? startPoint) {
    if (type == RulerType.none || type == RulerType.mirror) return p;

    if (type == RulerType.line) {
      // Infinite line passing through `center` at `angle`
      final double dx = cos(angle);
      final double dy = sin(angle);
      final Offset dir = Offset(dx, dy);
      
      if (startPoint != null) {
        // Parallel mapping: line passes through the start point
        final Offset delta = p - startPoint;
        final double dot = delta.dx * dir.dx + delta.dy * dir.dy;
        return startPoint + dir * dot;
      } else {
        // Initialization: lock onto touch
        return p; 
      }
    } 
    else if (type == RulerType.circle) {
      if (startPoint != null) {
        // Concentric ellipse mapping
        final Offset vStart = startPoint - center;
        
        final double cosA = cos(-angle);
        final double sinA = sin(-angle);
        final double sx = vStart.dx * cosA - vStart.dy * sinA;
        final double sy = vStart.dx * sinA + vStart.dy * cosA;
        
        double k = 1.0;
        if (scale > 0 && scaleY > 0) {
          k = sqrt(pow(sx / scale, 2) + pow(sy / scaleY, 2));
        }
        
        final double finalScaleX = scale * k;
        final double finalScaleY = scaleY * k;
        
        final Offset v = p - center;
        final double px = v.dx * cosA - v.dy * sinA;
        final double py = v.dx * sinA + v.dy * cosA;
        
        final double rayAngle = atan2(py, px);
        
        final double a = finalScaleX;
        final double b = finalScaleY;
        
        double ptX = 0, ptY = 0;
        if (a > 0 && b > 0) {
          final double cosRay = cos(rayAngle);
          final double sinRay = sin(rayAngle);
          final double r = (a * b) / sqrt(pow(b * cosRay, 2) + pow(a * sinRay, 2));
          ptX = r * cosRay;
          ptY = r * sinRay;
        }
        
        final double cosA2 = cos(angle);
        final double sinA2 = sin(angle);
        final double prX = ptX * cosA2 - ptY * sinA2;
        final double prY = ptX * sinA2 + ptY * cosA2;
        
        return center + Offset(prX, prY);
      } else {
        return p;
      }
    } 
    else if (type == RulerType.box) {
      if (startPoint != null) {
        // True Closest Point mapping for perfectly crisp edges & corners
        final double sx = startPoint.dx - center.dx;
        final double sy = startPoint.dy - center.dy;
        final double sLocalX = sx * cos(-angle) - sy * sin(-angle);
        final double sLocalY = sx * sin(-angle) + sy * cos(-angle);
        
        final double ratio = max(1e-5, max(sLocalX.abs() / scale, sLocalY.abs() / scaleY));
        final double w = scale * ratio;
        final double h = scaleY * ratio;

        final double dx = p.dx - center.dx;
        final double dy = p.dy - center.dy;
        final double localX = dx * cos(-angle) - dy * sin(-angle);
        final double localY = dx * sin(-angle) + dy * cos(-angle);

        final double absX = localX.abs();
        final double absY = localY.abs();
        final double signX = localX >= 0 ? 1.0 : -1.0;
        final double signY = localY >= 0 ? 1.0 : -1.0;

        double snapX, snapY;

        if (absX >= w && absY >= h) {
          // Outside corner region: snap directly to the exact corner
          snapX = signX * w;
          snapY = signY * h;
        } else if (absX >= w && absY < h) {
          // Outside Left/Right edges: clamp cleanly to the vertical edge
          snapX = signX * w;
          snapY = localY;
        } else if (absX < w && absY >= h) {
          // Outside Top/Bottom edges: clamp cleanly to the horizontal edge
          snapX = localX;
          snapY = signY * h;
        } else {
          // Inside the box: snap to the geometrically nearest edge
          final double distRight = w - absX;
          final double distTop = h - absY;
          if (distRight < distTop) {
            snapX = signX * w;
            snapY = localY;
          } else {
            snapX = localX;
            snapY = signY * h;
          }
        }

        final double globalX = center.dx + snapX * cos(angle) - snapY * sin(angle);
        final double globalY = center.dy + snapX * sin(angle) + snapY * cos(angle);
        return Offset(globalX, globalY);
      } else {
        return p;
      }
    }

    return p;
  }

  /// 计算在绘制过程中，从 lastPoint 到 p 跨越的边界角点
  /// Project path points and complete sharp corners for rough/fast drawing
  List<Offset> projectRoute(Offset p, Offset? startPoint, Offset? lastPoint) {
    final Offset nowPaint = projectPoint(p, startPoint);
    if (type != RulerType.box || startPoint == null || lastPoint == null) {
      return [nowPaint];
    }

    final double sx = startPoint.dx - center.dx;
    final double sy = startPoint.dy - center.dy;
    final double sLocalX = sx * cos(-angle) - sy * sin(-angle);
    final double sLocalY = sx * sin(-angle) + sy * cos(-angle);
    
    final double ratio = max(1e-5, max(sLocalX.abs() / scale, sLocalY.abs() / scaleY));
    final double w = scale * ratio;
    final double h = scaleY * ratio;

    Offset localize(Offset pt) {
      final double dx = pt.dx - center.dx;
      final double dy = pt.dy - center.dy;
      return Offset(dx * cos(-angle) - dy * sin(-angle), dx * sin(-angle) + dy * cos(-angle));
    }

    final Offset localLast = localize(projectPoint(lastPoint, startPoint));
    final Offset localNow = localize(nowPaint);

    final List<Offset> cornersLocal = [
      Offset(w, h),
      Offset(-w, h),
      Offset(-w, -h),
      Offset(w, -h),
    ];

    double a1 = atan2(localLast.dy, localLast.dx);
    double a2 = atan2(localNow.dy, localNow.dx);

    double diff = a2 - a1;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;

    final List<MapEntry<double, Offset>> sweptCorners = [];
    for (final c in cornersLocal) {
      double aC = atan2(c.dy, c.dx);
      double dC = aC - a1;
      while (dC > pi) dC -= 2 * pi;
      while (dC < -pi) dC += 2 * pi;

      if (diff > 0) {
        if (dC > 1e-4 && dC < diff - 1e-4) sweptCorners.add(MapEntry(dC, c));
      } else {
        if (dC < -1e-4 && dC > diff + 1e-4) sweptCorners.add(MapEntry(dC, c));
      }
    }

    sweptCorners.sort((a, b) => a.key.abs().compareTo(b.key.abs()));

    final List<Offset> route = [];
    for (final c in sweptCorners) {
      final Offset localPt = c.value;
      final Offset cornerGlobal = Offset(
        center.dx + localPt.dx * cos(angle) - localPt.dy * sin(angle),
        center.dy + localPt.dx * sin(angle) + localPt.dy * cos(angle)
      );
      // Generate a microscopic 0.6px loop at the exact corner to completely bypass 
      // the `minPointDistance` (0.5) filter in FreehandLine, essentially tricking 
      // the Bezier interpolator into anchoring a mathematically zero-radius sharp corner.
      const double e = 0.6;
      route.add(cornerGlobal);
      route.add(cornerGlobal + const Offset(e, 0));
      route.add(cornerGlobal + const Offset(e, e));
      route.add(cornerGlobal + const Offset(0, e));
      route.add(cornerGlobal);
    }
    route.add(nowPaint);
    return route;
  }
}



