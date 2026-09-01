import 'dart:typed_data';
import 'dart:ui' as ui;

/// 油漆桶填充工具辅助类
class FloodFill {
  /// 执行填充算法
  /// [image] 原始图片坐标数据
  /// [startPoint] 点击开始的位置
  /// [fillColor] 填充颜色
  /// [tolerance] 容差 (0-1)
  static Future<ui.Image?> fill({
    required ui.Image image,
    required ui.Offset startPoint,
    required ui.Color fillColor,
    double tolerance = 0.15,
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

    final Uint8List filledPixels = Uint8List(width * height * 4);
    final Uint8List visited = Uint8List(width * height);

    // Fast stack for flood fill
    final List<int> stack = <int>[startX, startY];
    visited[startY * width + startX] = 1;

    while (stack.isNotEmpty) {
      final int y = stack.removeLast();
      final int x = stack.removeLast();

      final int pos = y * width + x;
      final int pixelIndex = pos * 4;

      filledPixels[pixelIndex] = fillR;
      filledPixels[pixelIndex + 1] = fillG;
      filledPixels[pixelIndex + 2] = fillB;
      filledPixels[pixelIndex + 3] = fillA;

      // 4 neighbors: Right, Left, Down, Up
      final int right = x + 1;
      if (right < width) {
        final int rPos = y * width + right;
        if (visited[rPos] == 0) {
          visited[rPos] = 1;
          final int rIdx = rPos * 4;
          if (_isColorMatch(
            pixels[rIdx], pixels[rIdx + 1], pixels[rIdx + 2], pixels[rIdx + 3],
            targetR, targetG, targetB, targetA,
            tolerance,
          )) {
            stack.add(right);
            stack.add(y);
          }
        }
      }

      final int left = x - 1;
      if (left >= 0) {
        final int lPos = y * width + left;
        if (visited[lPos] == 0) {
          visited[lPos] = 1;
          final int lIdx = lPos * 4;
          if (_isColorMatch(
            pixels[lIdx], pixels[lIdx + 1], pixels[lIdx + 2], pixels[lIdx + 3],
            targetR, targetG, targetB, targetA,
            tolerance,
          )) {
            stack.add(left);
            stack.add(y);
          }
        }
      }

      final int down = y + 1;
      if (down < height) {
        final int dPos = down * width + x;
        if (visited[dPos] == 0) {
          visited[dPos] = 1;
          final int dIdx = dPos * 4;
          if (_isColorMatch(
            pixels[dIdx], pixels[dIdx + 1], pixels[dIdx + 2], pixels[dIdx + 3],
            targetR, targetG, targetB, targetA,
            tolerance,
          )) {
            stack.add(x);
            stack.add(down);
          }
        }
      }

      final int up = y - 1;
      if (up >= 0) {
        final int uPos = up * width + x;
        if (visited[uPos] == 0) {
          visited[uPos] = 1;
          final int uIdx = uPos * 4;
          if (_isColorMatch(
            pixels[uIdx], pixels[uIdx + 1], pixels[uIdx + 2], pixels[uIdx + 3],
            targetR, targetG, targetB, targetA,
            tolerance,
          )) {
            stack.add(x);
            stack.add(up);
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

  static bool _isColorMatch(
    int r1, int g1, int b1, int a1,
    int r2, int g2, int b2, int a2,
    double tolerance,
  ) {
    if (a1 == 0 && a2 == 0) return true;
    if (tolerance <= 0) return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2;

    final double diffR = (r1 - r2).toDouble();
    final double diffG = (g1 - g2).toDouble();
    final double diffB = (b1 - b2).toDouble();
    final double diffA = (a1 - a2).toDouble();

    final double distanceSq = diffR * diffR + diffG * diffG + diffB * diffB + diffA * diffA;
    final double maxDist = tolerance * 255.0;
    return distanceSq <= maxDist * maxDist * 4.0;
  }
}
