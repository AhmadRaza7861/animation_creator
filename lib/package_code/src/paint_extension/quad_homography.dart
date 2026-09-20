import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

/// Utility class to compute 4-point Projective Homography transformations.
/// Maps a source rectangle [0, w] x [0, h] to an arbitrary destination quadrilateral (P0, P1, P2, P3).
class QuadHomography {
  QuadHomography._();

  /// Computes a 4x4 [Matrix4] mapping a source rectangle of [width] x [height] (with origin at 0,0)
  /// to destination points [p0] (Top-Left), [p1] (Top-Right), [p2] (Bottom-Right), [p3] (Bottom-Left).
  static Matrix4 fromRectToQuad({
    required double width,
    required double height,
    required Offset p0,
    required Offset p1,
    required Offset p2,
    required Offset p3,
  }) {
    if (width <= 0 || height <= 0) {
      return Matrix4.identity();
    }

    final double x0 = p0.dx;
    final double y0 = p0.dy;
    final double x1 = p1.dx;
    final double y1 = p1.dy;
    final double x2 = p2.dx;
    final double y2 = p2.dy;
    final double x3 = p3.dx;
    final double y3 = p3.dy;

    final double dx1 = x1 - x2;
    final double dx2 = x3 - x2;
    final double sumX = x0 - x1 + x2 - x3;

    final double dy1 = y1 - y2;
    final double dy2 = y3 - y2;
    final double sumY = y0 - y1 + y2 - y3;

    double a, b, c, d, e, f, g, h;

    if (sumX.abs() < 1e-9 && sumY.abs() < 1e-9) {
      // Affine mapping (parallelogram)
      a = x1 - x0;
      b = x3 - x0;
      c = x0;
      d = y1 - y0;
      e = y3 - y0;
      f = y0;
      g = 0.0;
      h = 0.0;
    } else {
      // General Projective mapping (Paul Heckbert homography)
      final double det = dx1 * dy2 - dx2 * dy1;
      if (det.abs() < 1e-9) {
        // Degenerate/collinear points fallback: use affine fallback
        a = x1 - x0;
        b = x3 - x0;
        c = x0;
        d = y1 - y0;
        e = y3 - y0;
        f = y0;
        g = 0.0;
        h = 0.0;
      } else {
        g = (sumX * dy2 - sumY * dx2) / det;
        h = (dx1 * sumY - dy1 * sumX) / det;
        a = x1 - x0 + g * x1;
        b = x3 - x0 + h * x3;
        c = x0;
        d = y1 - y0 + g * y1;
        e = y3 - y0 + h * y3;
        f = y0;
      }
    }

    // Pre-scale by 1/w and 1/h so inputs in [0, w] x [0, h] are mapped accurately
    final Float64List storage = Float64List(16);
    // Column 0
    storage[0] = a / width;
    storage[1] = d / width;
    storage[2] = 0.0;
    storage[3] = g / width;

    // Column 1
    storage[4] = b / height;
    storage[5] = e / height;
    storage[6] = 0.0;
    storage[7] = h / height;

    // Column 2
    storage[8] = 0.0;
    storage[9] = 0.0;
    storage[10] = 1.0;
    storage[11] = 0.0;

    // Column 3
    storage[12] = c;
    storage[13] = f;
    storage[14] = 0.0;
    storage[15] = 1.0;

    return Matrix4.fromFloat64List(storage);
  }

  /// Transforms a 2D [point] using projective 4x4 [matrix].
  static Offset transformPoint(Matrix4 matrix, Offset point) {
    final Vector4 vec = matrix.transform(Vector4(point.dx, point.dy, 0.0, 1.0));
    final double w = vec.w.abs() < 1e-9 ? 1.0 : vec.w;
    return Offset(vec.x / w, vec.y / w);
  }
}
