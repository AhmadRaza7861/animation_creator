import 'dart:typed_data';
import 'dart:ui' as ui;

/// 油漆桶填充工具辅助类
///
/// True paint-bucket flood fill for digital animation and drawing:
/// - Determines the connected enclosed region from composited line art
/// - Treats anti-aliased pixels of the outline as boundaries (prevents leaking across strokes)
/// - Expands the fill mask slightly underneath the anti-aliased boundary pixels (eliminates halos)
/// - Keeps the original line art visually on top without modifying or replacing stroke pixels
class FloodFill {
  /// 执行填充算法
  /// [image] 原始图片坐标数据 (所有可见图层的合成快照)
  /// [startPoint] 点击开始的位置 (逻辑坐标)
  /// [fillColor] 填充颜色
  /// [tolerance] 容差 (0.0 - 1.0)
  /// [expandRadius] 边缘抗锯齿扩展半径 (像素，默认 2.0，用于消除白边)
  static Future<ui.Image?> fill({
    required ui.Image image,
    required ui.Offset startPoint,
    required ui.Color fillColor,
    double tolerance = 0.15,
    double expandRadius = 2.0,
  }) async {
    final int width = image.width;
    final int height = image.height;
    if (width <= 0 || height <= 0) return null;

    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;

    final Uint8List pixels = data.buffer.asUint8List();

    final int startX = startPoint.dx.round().clamp(0, width - 1);
    final int startY = startPoint.dy.round().clamp(0, height - 1);

    final int startIndex = (startY * width + startX) * 4;
    final int targetR = pixels[startIndex];
    final int targetG = pixels[startIndex + 1];
    final int targetB = pixels[startIndex + 2];
    final int targetA = pixels[startIndex + 3];

    final int fillR = (fillColor.r * 255.0).round().clamp(0, 255);
    final int fillG = (fillColor.g * 255.0).round().clamp(0, 255);
    final int fillB = (fillColor.b * 255.0).round().clamp(0, 255);
    final int fillA = (fillColor.a * 255.0).round().clamp(0, 255);

    // 如果起始位置颜色已经是填充颜色，则不需要填充
    if (_isSameColor(targetR, targetG, targetB, targetA, fillR, fillG, fillB, fillA)) {
      return null;
    }

    final bool isTargetTransparent = targetA < 20;

    // Strict boundary threshold for anti-aliased line art:
    // Any pixel with stroke opacity >= boundaryAlphaThreshold is treated as a boundary.
    // This strictly stops the flood fill at the stroke edge so it never leaks across lines.
    final int boundaryAlphaThreshold;
    if (isTargetTransparent) {
      if (tolerance <= 0) {
        boundaryAlphaThreshold = 1;
      } else {
        // Clamped to a very tight threshold (default ~8-12) so even faint anti-aliasing blocks leaks
        boundaryAlphaThreshold = (tolerance * 255.0 * 0.25).round().clamp(4, 25);
      }
    } else {
      boundaryAlphaThreshold = 0;
    }

    final double colorToleranceSq = (tolerance * 255.0) * (tolerance * 255.0) * 4.0;

    // Helper: is pixel (x, y) a boundary?
    bool isBoundary(int x, int y) {
      final int idx = (y * width + x) * 4;
      final int pA = pixels[idx + 3];

      if (isTargetTransparent) {
        // Any stroke pixel (anti-aliased or solid) is a boundary
        if (pA >= boundaryAlphaThreshold) return true;
        if (pA > 0) {
          final int pR = pixels[idx];
          final int pG = pixels[idx + 1];
          final int pB = pixels[idx + 2];
          final double diffR = (pR - targetR).toDouble();
          final double diffG = (pG - targetG).toDouble();
          final double diffB = (pB - targetB).toDouble();
          final double diffA = (pA - targetA).toDouble();
          final double distSq = diffR * diffR + diffG * diffG + diffB * diffB + diffA * diffA;
          if (distSq > colorToleranceSq) return true;
        }
        return false;
      } else {
        // Re-coloring mode: boundary is where color differs from target
        final int pR = pixels[idx];
        final int pG = pixels[idx + 1];
        final int pB = pixels[idx + 2];
        final double diffR = (pR - targetR).toDouble();
        final double diffG = (pG - targetG).toDouble();
        final double diffB = (pB - targetB).toDouble();
        final double diffA = (pA - targetA).toDouble();
        final double distSq = diffR * diffR + diffG * diffG + diffB * diffB + diffA * diffA;
        return distSq > colorToleranceSq;
      }
    }

    // If starting point is directly on a boundary stroke and target is transparent, do not fill
    if (isBoundary(startX, startY)) {
      if (isTargetTransparent) {
        return null;
      }
    }

    // 1. Flood Fill using Fast Queue (4-way traversal strictly bounded by boundaries)
    final Uint8List mask = Uint8List(width * height);
    final Int32List queue = Int32List(width * height * 2);
    int head = 0;
    int tail = 0;

    mask[startY * width + startX] = 1;
    queue[tail++] = startX;
    queue[tail++] = startY;

    while (head < tail) {
      final int x = queue[head++];
      final int y = queue[head++];

      // 4-Neighbors
      // Right (x + 1, y)
      if (x + 1 < width) {
        final int rPos = y * width + (x + 1);
        if (mask[rPos] == 0 && !isBoundary(x + 1, y)) {
          mask[rPos] = 1;
          queue[tail++] = x + 1;
          queue[tail++] = y;
        }
      }

      // Left (x - 1, y)
      if (x - 1 >= 0) {
        final int lPos = y * width + (x - 1);
        if (mask[lPos] == 0 && !isBoundary(x - 1, y)) {
          mask[lPos] = 1;
          queue[tail++] = x - 1;
          queue[tail++] = y;
        }
      }

      // Down (x, y + 1)
      if (y + 1 < height) {
        final int dPos = (y + 1) * width + x;
        if (mask[dPos] == 0 && !isBoundary(x, y + 1)) {
          mask[dPos] = 1;
          queue[tail++] = x;
          queue[tail++] = y + 1;
        }
      }

      // Up (x, y - 1)
      if (y - 1 >= 0) {
        final int uPos = (y - 1) * width + x;
        if (mask[uPos] == 0 && !isBoundary(x, y - 1)) {
          mask[uPos] = 1;
          queue[tail++] = x;
          queue[tail++] = y - 1;
        }
      }
    }

    // 2. Build Output Image with Sub-Pixel Dilation
    // The fill mask is expanded underneath anti-aliased boundary pixels so when the line art
    // is rendered on top, there is no white/transparent halo, and the stroke remains 100% crisp.
    final Uint8List filledPixels = Uint8List(width * height * 4);
    final int dilationRadius = expandRadius.ceil().clamp(1, 4);

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final int pos = rowOffset + x;
        final int pixelIndex = pos * 4;

        if (mask[pos] == 1) {
          // Pure interior pixel: 100% solid fill
          filledPixels[pixelIndex] = fillR;
          filledPixels[pixelIndex + 1] = fillG;
          filledPixels[pixelIndex + 2] = fillB;
          filledPixels[pixelIndex + 3] = fillA;
        } else if (dilationRadius > 0) {
          // Check if boundary pixel is adjacent to the filled interior (within expandRadius)
          bool nearInterior = false;
          for (int dy = -dilationRadius; dy <= dilationRadius && !nearInterior; dy++) {
            final int ny = y + dy;
            if (ny < 0 || ny >= height) continue;
            for (int dx = -dilationRadius; dx <= dilationRadius; dx++) {
              final int nx = x + dx;
              if (nx < 0 || nx >= width) continue;
              if (dx * dx + dy * dy <= dilationRadius * dilationRadius) {
                if (mask[ny * width + nx] == 1) {
                  nearInterior = true;
                  break;
                }
              }
            }
          }

          if (nearInterior) {
            // Expand fill cleanly underneath the anti-aliased edge
            filledPixels[pixelIndex] = fillR;
            filledPixels[pixelIndex + 1] = fillG;
            filledPixels[pixelIndex + 2] = fillB;
            filledPixels[pixelIndex + 3] = fillA;
          }
        }
      }
    }

    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(filledPixels);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  static bool _isSameColor(int r1, int g1, int b1, int a1, int r2, int g2, int b2, int a2) {
    return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2;
  }
}
