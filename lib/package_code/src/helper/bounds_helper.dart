import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../paint_contents/paint_content.dart';
import '../paint_contents/shape_sticker.dart';
import '../paint_contents/text.dart';
import '../paint_contents/image.dart';
import '../paint_contents/circle.dart';
import '../paint_contents/rectangle.dart';
import '../paint_contents/straight_line.dart';
import '../paint_contents/simple_line.dart';
import '../paint_contents/freehand_line.dart' as brush;
import '../paint_contents/smooth_line.dart';
import '../paint_contents/triangle.dart';
import '../paint_contents/group.dart';
import '../paint_contents/clipped.dart';

/// Calculates the bounding rectangle of any drawing element (shape, stroke, text, image, sticker).
Rect getShapeBounds(PaintContent c) {
  Rect bounds = _getRawShapeBounds(c);

  double strokeWidth = 0.0;
  try {
    strokeWidth = c.paint.strokeWidth;
  } catch (_) {}

  if (strokeWidth > 0) {
    bounds = bounds.inflate(strokeWidth / 2);
  }

  // Ensure minimum dimensions to prevent zero division
  if (bounds.width < 1.0 || bounds.height < 1.0) {
    final double w = bounds.width < 1.0 ? 1.0 : bounds.width;
    final double h = bounds.height < 1.0 ? 1.0 : bounds.height;
    bounds = Rect.fromLTWH(bounds.left, bounds.top, w, h);
  }

  return bounds;
}

Rect _getRawShapeBounds(PaintContent c) {
  if (c is ShapeStickerContent) {
    final double scaledWidth = c.size.width * c.scale;
    final double scaledHeight = c.size.height * c.scale;
    return Rect.fromCenter(
      center: c.offset,
      width: scaledWidth,
      height: scaledHeight,
    );
  }

  if (c is TextContent) {
    try {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: c.text,
          style: TextStyle(
            fontSize: c.fontSize * c.scale,
            fontFamily: c.fontFamily,
            fontWeight: c.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: c.isItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return Rect.fromCenter(
        center: c.offset,
        width: math.max(tp.width, 24.0),
        height: math.max(tp.height, 24.0),
      );
    } catch (_) {
      final double estW = math.max(c.fontSize * c.text.length * 0.6 * c.scale, 30.0);
      final double estH = math.max(c.fontSize * 1.2 * c.scale, 24.0);
      return Rect.fromCenter(center: c.offset, width: estW, height: estH);
    }
  }

  if (c is ImageContent) {
    return Rect.fromPoints(c.startPoint, c.startPoint + c.size);
  }

  if (c is Circle) {
    if (c.isEllipse) {
      return Rect.fromPoints(c.startPoint, c.endPoint);
    }
    final Offset center = c.startFromCenter ? c.startPoint : c.center;
    final double r = c.radius > 0 ? c.radius : 1.0;
    return Rect.fromCircle(center: center, radius: r);
  }

  if (c is Rectangle) {
    final Offset start = c.startPoint ?? Offset.zero;
    final Offset end = c.endPoint ?? start;
    return Rect.fromPoints(start, end);
  }

  if (c is StraightLine) {
    final Offset start = c.startPoint ?? Offset.zero;
    final Offset end = c.endPoint ?? start;
    return Rect.fromPoints(start, end);
  }

  if (c is SimpleLine) {
    final Offset start = c.startPoint ?? Offset.zero;
    final Offset end = c.endPoint ?? start;
    return Rect.fromPoints(start, end);
  }

  if (c is FreehandLine) {
    final points = c.points;
    if (points != null && points.isNotEmpty) {
      double minX = points.first.dx;
      double maxX = points.first.dx;
      double minY = points.first.dy;
      double maxY = points.first.dy;
      for (final p in points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }

  if (c is brush.FreehandLine) {
    final points = c.points;
    if (points.isNotEmpty) {
      double minX = points.first.dx;
      double maxX = points.first.dx;
      double minY = points.first.dy;
      double maxY = points.first.dy;
      for (final p in points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }

  if (c is SmoothLine) {
    final points = c.points;
    if (points.isNotEmpty) {
      double minX = points.first.dx;
      double maxX = points.first.dx;
      double minY = points.first.dy;
      double maxY = points.first.dy;
      for (final p in points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
  }

  if (c is Triangle) {
    final path = c.getPath();
    final b = path.getBounds();
    if (!b.isEmpty) return b;
    return Rect.fromPoints(c.startPoint, c.C);
  }

  if (c is ClippedHistoryContent) {
    return c.clipRect;
  }

  if (c is OffsetContent) {
    return getShapeBounds(c.child).shift(c.shiftOffset);
  }

  if (c is GroupContent) {
    if (c.children.isEmpty) return Rect.zero;
    Rect? combined;
    for (final child in c.children) {
      final b = getShapeBounds(child).shift(c.boundsOffset);
      combined = combined == null ? b : combined.expandToInclude(b);
    }
    return combined ?? Rect.zero;
  }

  // Fallback: use getPath()
  try {
    final Path path = c.getPath();
    final Rect b = path.getBounds();
    if (!b.isEmpty) return b;
  } catch (_) {}

  return Rect.zero;
}

/// Distance from point [p] to line segment ([a], [b]).
double distanceToSegment(Offset p, Offset a, Offset b) {
  final double l2 = (b - a).distanceSquared;
  if (l2 == 0) return (p - a).distance;
  final double t = math.max(
    0.0,
    math.min(1.0, ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2),
  );
  final Offset projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
  return (p - projection).distance;
}

/// Hit-tests a [PaintContent] at [tapPos] with user-friendly [touchTolerance].
bool hitTestPaintContent(PaintContent c, Offset tapPos, {double touchTolerance = 18.0}) {
  final Rect bounds = getShapeBounds(c);
  final double strokeRadius = (c.paint.strokeWidth / 2).clamp(0.0, 100.0);
  final double totalTolerance = math.max(strokeRadius + 12.0, touchTolerance);

  if (!bounds.inflate(totalTolerance).contains(tapPos)) {
    return false;
  }

  // 1. Sticker content
  if (c is ShapeStickerContent) {
    if (c.containsPoint(tapPos)) return true;
    final Path path = c.getPath();
    if (path.contains(tapPos)) return true;
    return bounds.inflate(touchTolerance).contains(tapPos);
  }

  // 2. Freehand strokes (standard pen, brush line, or smooth lines)
  final List<Offset>? points = c is FreehandLine
      ? c.points
      : (c is brush.FreehandLine
          ? c.points
          : (c is SmoothLine ? c.points : null));

  if (points != null) {
    if (points.isEmpty) return false;
    if (points.length == 1) {
      return (tapPos - points.first).distance <= totalTolerance;
    }
    for (int i = 0; i < points.length - 1; i++) {
      if (distanceToSegment(tapPos, points[i], points[i + 1]) <= totalTolerance) {
        return true;
      }
    }
    return false;
  }

  // 3. Straight & Simple lines
  if (c is StraightLine) {
    final start = c.startPoint;
    final end = c.endPoint;
    if (start != null && end != null) {
      return distanceToSegment(tapPos, start, end) <= totalTolerance;
    }
  }

  if (c is SimpleLine) {
    final start = c.startPoint;
    final end = c.endPoint;
    if (start != null && end != null) {
      return distanceToSegment(tapPos, start, end) <= totalTolerance;
    }
  }

  // 4. Grouped content
  if (c is GroupContent) {
    for (final child in c.children) {
      if (hitTestPaintContent(child, tapPos - c.boundsOffset, touchTolerance: touchTolerance)) {
        return true;
      }
    }
    return false;
  }

  // 5. Offset content
  if (c is OffsetContent) {
    return hitTestPaintContent(c.child, tapPos - c.shiftOffset, touchTolerance: touchTolerance);
  }

  // 6. Closed shapes with containsPoint
  if (c.containsPoint(tapPos)) return true;

  // 7. Path containment
  try {
    final path = c.getPath();
    if (path.contains(tapPos)) return true;
  } catch (_) {}

  // 8. Small shapes / dots / icons: bounds containment is hit if within touch tolerance
  if (bounds.width <= 32.0 && bounds.height <= 32.0) {
    return bounds.inflate(touchTolerance).contains(tapPos);
  }

  return false;
}

/// Checks whether [c] geometrically intersects or is inside [rect].
bool isContentInOrIntersectsRect(PaintContent c, Rect rect) {
  final Rect bounds = getShapeBounds(c);
  if (!rect.overlaps(bounds)) return false;

  // 1. If the shape bounding box is completely inside rect
  if (rect.contains(bounds.topLeft) && rect.contains(bounds.bottomRight)) {
    return true;
  }

  // 2. Freehand strokes: check if any point is in rect or any segment crosses rect
  final List<Offset>? strokePoints = c is FreehandLine
      ? c.points
      : (c is brush.FreehandLine
          ? c.points
          : (c is SmoothLine ? c.points : null));

  if (strokePoints != null) {
    if (strokePoints.isEmpty) return false;
    for (int i = 0; i < strokePoints.length; i++) {
      if (rect.contains(strokePoints[i])) return true;
    }
    for (int i = 0; i < strokePoints.length - 1; i++) {
      if (segmentIntersectsRect(strokePoints[i], strokePoints[i + 1], rect)) return true;
    }
    return false;
  }

  // 4. Straight & Simple lines
  if (c is StraightLine) {
    final start = c.startPoint;
    final end = c.endPoint;
    if (start != null && end != null) {
      return segmentIntersectsRect(start, end, rect);
    }
  }

  if (c is SimpleLine) {
    final start = c.startPoint;
    final end = c.endPoint;
    if (start != null && end != null) {
      return segmentIntersectsRect(start, end, rect);
    }
  }

  // 5. Grouped content
  if (c is GroupContent) {
    for (final child in c.children) {
      if (isContentInOrIntersectsRect(child, rect.shift(c.boundsOffset))) {
        return true;
      }
    }
    return false;
  }

  // 6. Offset content
  if (c is OffsetContent) {
    return isContentInOrIntersectsRect(c.child, rect.shift(-c.shiftOffset));
  }

  // 7. Sticker content
  if (c is ShapeStickerContent) {
    if (rect.contains(c.offset)) return true;
    return isContentInOrIntersectsRect(c.child, rect.shift(-c.offset + bounds.size.center(Offset.zero)));
  }

  // Fallback for solid closed shapes / images / text
  return rect.overlaps(bounds);
}

/// Checks whether the line segment from [a] to [b] intersects [rect].
bool segmentIntersectsRect(Offset a, Offset b, Rect rect) {
  if (rect.contains(a) || rect.contains(b)) return true;
  if (math.max(a.dx, b.dx) < rect.left || math.min(a.dx, b.dx) > rect.right) return false;
  if (math.max(a.dy, b.dy) < rect.top || math.min(a.dy, b.dy) > rect.bottom) return false;

  final p1 = rect.topLeft;
  final p2 = rect.topRight;
  final p3 = rect.bottomRight;
  final p4 = rect.bottomLeft;

  return _lineSegmentsCross(a, b, p1, p2) ||
      _lineSegmentsCross(a, b, p2, p3) ||
      _lineSegmentsCross(a, b, p3, p4) ||
      _lineSegmentsCross(a, b, p4, p1);
}

bool _lineSegmentsCross(Offset p1, Offset p2, Offset p3, Offset p4) {
  final d1 = _ccwCross(p3 - p1, p2 - p1);
  final d2 = _ccwCross(p4 - p1, p2 - p1);
  final d3 = _ccwCross(p1 - p3, p4 - p3);
  final d4 = _ccwCross(p2 - p3, p4 - p3);

  return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

double _ccwCross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

