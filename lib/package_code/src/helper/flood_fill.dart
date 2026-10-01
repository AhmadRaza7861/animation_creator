import 'dart:typed_data';
import 'dart:ui' as ui;

/// Flood fill result containing the raster fill image and compositing placement
class FloodFillResult {
  final ui.Image image;
  final bool isUnderneath;

  const FloodFillResult({
    required this.image,
    required this.isUnderneath,
  });
}

/// 油漆桶填充工具辅助类
///
/// True paint-bucket flood fill for digital animation and drawing:
/// - Determines the connected enclosed region from composited line art
/// - Treats anti-aliased pixels of the outline as boundaries (prevents leaking across strokes)
/// - Expands the fill mask slightly underneath the anti-aliased boundary pixels (eliminates halos) for interior fills without bleeding into empty space
/// - For stroke re-coloring, accurately captures the stroke and its anti-aliasing without leaving old color halos
class FloodFill {
  /// 执行填充算法并返回结果（包含放置层级信息）
  static Future<FloodFillResult?> fillWithResult({
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

    // Strict boundary threshold for line art:
    // Any stroke pixel with opacity >= 3 is treated as a solid boundary so flood fill
    // never leaks through anti-aliased gaps, frame boundaries, or corners.
    const int boundaryAlphaThreshold = 3;

    // Helper: is pixel (x, y) a stroke boundary?
    bool isStrokeBoundary(int x, int y) {
      final int idx = (y * width + x) * 4;
      return pixels[idx + 3] >= boundaryAlphaThreshold;
    }

    // 1. SMART SEED RESOLUTION FOR NARROW / SMALL REGIONS
    // If the tap landed on a boundary/stroke pixel, check if the user was tapping
    // near/inside an enclosed interior loop (e.g. small spiral, narrow closed area).
    int effectiveStartX = startX;
    int effectiveStartY = startY;

    if (isStrokeBoundary(startX, startY)) {
      int bestSeedX = -1;
      int bestSeedY = -1;
      int minArea = 1 << 30;

      // Search expanding rings up to radius 16 for an enclosed interior seed
      for (int r = 1; r <= 16; r++) {
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            if (dx * dx + dy * dy > r * r || dx * dx + dy * dy <= (r - 1) * (r - 1)) continue;
            final int nx = startX + dx;
            final int ny = startY + dy;
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

            if (!isStrokeBoundary(nx, ny)) {
              final int area = _getEnclosedArea(
                pixels: pixels,
                width: width,
                height: height,
                seedX: nx,
                seedY: ny,
                boundaryAlphaThreshold: boundaryAlphaThreshold,
                maxArea: minArea,
              );
              if (area > 0 && area < minArea) {
                minArea = area;
                bestSeedX = nx;
                bestSeedY = ny;
              }
            }
          }
        }
        if (bestSeedX != -1) break;
      }

      if (bestSeedX != -1) {
        effectiveStartX = bestSeedX;
        effectiveStartY = bestSeedY;
      }
    }

    final int startIndex = (effectiveStartY * width + effectiveStartX) * 4;
    final int targetR = pixels[startIndex];
    final int targetG = pixels[startIndex + 1];
    final int targetB = pixels[startIndex + 2];
    final int targetA = pixels[startIndex + 3];

    final int fillR = (fillColor.r * 255.0).round().clamp(0, 255);
    final int fillG = (fillColor.g * 255.0).round().clamp(0, 255);
    final int fillB = (fillColor.b * 255.0).round().clamp(0, 255);
    final int fillA = (fillColor.a * 255.0).round().clamp(0, 255);

    // If start pixel is already the target fill color, no-op
    if (_isSameColor(targetR, targetG, targetB, targetA, fillR, fillG, fillB, fillA)) {
      return null;
    }

    final bool isTargetTransparent = targetA < 20;

    final double colorToleranceSq = (tolerance * 255.0) * (tolerance * 255.0) * 4.0;

    // Chromaticity for re-coloring mode
    final double tA = targetA.toDouble();
    final double targetUnpremulR = tA > 0 ? (targetR * 255.0 / tA) : targetR.toDouble();
    final double targetUnpremulG = tA > 0 ? (targetG * 255.0 / tA) : targetG.toDouble();
    final double targetUnpremulB = tA > 0 ? (targetB * 255.0 / tA) : targetB.toDouble();

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
        // Re-coloring mode: transparent background is a boundary
        if (pA == 0) return true;
        final double curA = pA.toDouble();
        final double curUnpremulR = curA > 0 ? (pixels[idx] * 255.0 / curA) : pixels[idx].toDouble();
        final double curUnpremulG = curA > 0 ? (pixels[idx + 1] * 255.0 / curA) : pixels[idx + 1].toDouble();
        final double curUnpremulB = curA > 0 ? (pixels[idx + 2] * 255.0 / curA) : pixels[idx + 2].toDouble();

        final double diffR = curUnpremulR - targetUnpremulR;
        final double diffG = curUnpremulG - targetUnpremulG;
        final double diffB = curUnpremulB - targetUnpremulB;
        final double distSq = diffR * diffR + diffG * diffG + diffB * diffB;
        return distSq > colorToleranceSq;
      }
    }

    // If starting point is directly on a boundary stroke and target is transparent, do not fill
    if (isBoundary(effectiveStartX, effectiveStartY)) {
      if (isTargetTransparent) {
        return null;
      }
    }

    // 2. Flood Fill using Fast Queue (4-way traversal strictly bounded by boundaries)
    final Uint8List mask = Uint8List(width * height);
    final Int32List queue = Int32List(width * height * 2);
    int head = 0;
    int tail = 0;

    mask[effectiveStartY * width + effectiveStartX] = 1;
    queue[tail++] = effectiveStartX;
    queue[tail++] = effectiveStartY;

    while (head < tail) {
      final int x = queue[head++];
      final int y = queue[head++];

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

    // 2. Build Output Image
    // For interior fills: Sub-pixel dilation ONLY expands underneath stroke boundary pixels (pA >= 3)
    // so no white halos exist and empty outer canvas remains 100% transparent.
    // For re-coloring: Traverses stroke pixels and recolors them smoothly with original anti-aliased alpha.
    final Uint8List filledPixels = Uint8List(width * height * 4);
    final int dilationRadius = isTargetTransparent ? expandRadius.ceil().clamp(1, 4) : 0;

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final int pos = rowOffset + x;
        final int pixelIndex = pos * 4;

        if (mask[pos] == 1) {
          if (isTargetTransparent) {
            // Pure interior pixel: 100% solid fill
            filledPixels[pixelIndex] = fillR;
            filledPixels[pixelIndex + 1] = fillG;
            filledPixels[pixelIndex + 2] = fillB;
            filledPixels[pixelIndex + 3] = fillA;
          } else {
            // Re-coloring mode: preserve original anti-aliased edge alpha
            final int origA = pixels[pixelIndex + 3];
            filledPixels[pixelIndex] = fillR;
            filledPixels[pixelIndex + 1] = fillG;
            filledPixels[pixelIndex + 2] = fillB;
            filledPixels[pixelIndex + 3] = ((origA / 255.0) * fillA).round().clamp(0, 255);
          }
        } else if (isTargetTransparent && dilationRadius > 0 && pixels[pixelIndex + 3] >= boundaryAlphaThreshold) {
          // Check if stroke boundary pixel is adjacent to the filled interior (within expandRadius)
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
            // Expand fill cleanly UNDERNEATH the stroke line art (pA >= 3)
            filledPixels[pixelIndex] = fillR;
            filledPixels[pixelIndex + 1] = fillG;
            filledPixels[pixelIndex + 2] = fillB;
            filledPixels[pixelIndex + 3] = fillA;
          }
        } else if (!isTargetTransparent && pixels[pixelIndex + 3] > 0) {
          // In re-coloring mode: include full anti-aliased fringe pixels touching the recolored stroke
          bool nearStroke = false;
          for (int dy = -3; dy <= 3 && !nearStroke; dy++) {
            final int ny = y + dy;
            if (ny < 0 || ny >= height) continue;
            for (int dx = -3; dx <= 3; dx++) {
              final int nx = x + dx;
              if (nx < 0 || nx >= width) continue;
              if (dx * dx + dy * dy <= 9) {
                if (mask[ny * width + nx] == 1) {
                  nearStroke = true;
                  break;
                }
              }
            }
          }

          if (nearStroke) {
            final int origA = pixels[pixelIndex + 3];
            final double curA = origA.toDouble();
            final double curUnpremulR = curA > 0 ? (pixels[pixelIndex] * 255.0 / curA) : pixels[pixelIndex].toDouble();
            final double curUnpremulG = curA > 0 ? (pixels[pixelIndex + 1] * 255.0 / curA) : pixels[pixelIndex + 1].toDouble();
            final double curUnpremulB = curA > 0 ? (pixels[pixelIndex + 2] * 255.0 / curA) : pixels[pixelIndex + 2].toDouble();

            final double diffR = curUnpremulR - targetUnpremulR;
            final double diffG = curUnpremulG - targetUnpremulG;
            final double diffB = curUnpremulB - targetUnpremulB;
            final double distSq = diffR * diffR + diffG * diffG + diffB * diffB;

            // Cover all pixels that match target color or are anti-aliased edge fringe
            if (distSq <= colorToleranceSq * 3.0 || origA < 80) {
              filledPixels[pixelIndex] = fillR;
              filledPixels[pixelIndex + 1] = fillG;
              filledPixels[pixelIndex + 2] = fillB;
              filledPixels[pixelIndex + 3] = ((origA / 255.0) * fillA).round().clamp(0, 255);
            }
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
    return FloodFillResult(
      image: frameInfo.image,
      isUnderneath: isTargetTransparent,
    );
  }

  /// 执行填充算法（兼容方法）
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
    final FloodFillResult? result = await fillWithResult(
      image: image,
      startPoint: startPoint,
      fillColor: fillColor,
      tolerance: tolerance,
      expandRadius: expandRadius,
    );
    return result?.image;
  }

  static bool _isSameColor(int r1, int g1, int b1, int a1, int r2, int g2, int b2, int a2) {
    return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2;
  }

  /// Calculates the area of an enclosed region starting at (seedX, seedY).
  /// Returns the pixel count if strictly enclosed, or -1 if the region touches canvas edges
  /// or exceeds maximum allowable area.
  static int _getEnclosedArea({
    required Uint8List pixels,
    required int width,
    required int height,
    required int seedX,
    required int seedY,
    required int boundaryAlphaThreshold,
    int maxArea = 1000000,
  }) {
    final int totalPixels = width * height;
    final int maxAllowableArea = (totalPixels * 0.45).toInt().clamp(500, maxArea);

    final Uint8List visited = Uint8List(totalPixels);
    final Int32List queue = Int32List(maxAllowableArea * 2 + 100);
    int head = 0;
    int tail = 0;

    visited[seedY * width + seedX] = 1;
    queue[tail++] = seedX;
    queue[tail++] = seedY;
    int count = 0;

    while (head < tail) {
      final int x = queue[head++];
      final int y = queue[head++];
      count++;

      if (count > maxAllowableArea) {
        return -1;
      }

      // If it touches the outer canvas borders, it's not strictly enclosed
      if (x <= 0 || x >= width - 1 || y <= 0 || y >= height - 1) {
        return -1;
      }

      // Right (x + 1, y)
      if (x + 1 < width) {
        final int rPos = y * width + (x + 1);
        if (visited[rPos] == 0 && pixels[rPos * 4 + 3] < boundaryAlphaThreshold) {
          visited[rPos] = 1;
          if (tail < queue.length - 2) {
            queue[tail++] = x + 1;
            queue[tail++] = y;
          } else {
            return -1;
          }
        }
      }

      // Left (x - 1, y)
      if (x - 1 >= 0) {
        final int lPos = y * width + (x - 1);
        if (visited[lPos] == 0 && pixels[lPos * 4 + 3] < boundaryAlphaThreshold) {
          visited[lPos] = 1;
          if (tail < queue.length - 2) {
            queue[tail++] = x - 1;
            queue[tail++] = y;
          } else {
            return -1;
          }
        }
      }

      // Down (x, y + 1)
      if (y + 1 < height) {
        final int dPos = (y + 1) * width + x;
        if (visited[dPos] == 0 && pixels[dPos * 4 + 3] < boundaryAlphaThreshold) {
          visited[dPos] = 1;
          if (tail < queue.length - 2) {
            queue[tail++] = x;
            queue[tail++] = y + 1;
          } else {
            return -1;
          }
        }
      }

      // Up (x, y - 1)
      if (y - 1 >= 0) {
        final int uPos = (y - 1) * width + x;
        if (visited[uPos] == 0 && pixels[uPos * 4 + 3] < boundaryAlphaThreshold) {
          visited[uPos] = 1;
          if (tail < queue.length - 2) {
            queue[tail++] = x;
            queue[tail++] = y - 1;
          } else {
            return -1;
          }
        }
      }
    }

    return count;
  }
}
