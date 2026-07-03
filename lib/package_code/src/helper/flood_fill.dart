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
    double tolerance = 0.0,
  }) async {
    final int width = image.width;
    final int height = image.height;
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (data == null) return null;

    final Uint8List pixels = data.buffer.asUint8List();

    final int startX = startPoint.dx.toInt();
    final int startY = startPoint.dy.toInt();

    if (startX < 0 || startX >= width || startY < 0 || startY >= height) return null;

    final int startIndex = (startY * width + startX) * 4;
    final int startR = pixels[startIndex];
    final int startG = pixels[startIndex + 1];
    final int startB = pixels[startIndex + 2];
    final int startA = pixels[startIndex + 3];

    final int fillR = fillColor.red;
    final int fillG = fillColor.green;
    final int fillB = fillColor.blue;
    final int fillA = fillColor.alpha;

    // 如果起始位置颜色已经是填充颜色，则不需要填充
    if (_isSameColor(startR, startG, startB, startA, fillR, fillG, fillB, fillA)) {
      return null;
    }

    // 使用栈模式避免递归溢出
    final List<int> stack = <int>[];
    stack.add(startX);
    stack.add(startY);

    // 记录在该区域内的像素点
    final Uint8List filledPixels = Uint8List(width * height * 4);
    final Uint8List visited = Uint8List(width * height);

    while (stack.isNotEmpty) {
      final int y = stack.removeLast();
      final int x = stack.removeLast();

      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final int pos = y * width + x;
      if (visited[pos] == 1) continue;

      final int pixelIndex = pos * 4;
      final int r = pixels[pixelIndex];
      final int g = pixels[pixelIndex + 1];
      final int b = pixels[pixelIndex + 2];
      final int a = pixels[pixelIndex + 3];

      if (_isColorMatch(r, g, b, a, startR, startG, startB, startA, tolerance)) {
        visited[pos] = 1;

        // 设置到填充图中
        filledPixels[pixelIndex] = fillR;
        filledPixels[pixelIndex + 1] = fillG;
        filledPixels[pixelIndex + 2] = fillB;
        filledPixels[pixelIndex + 3] = fillA;

        // 4方向延伸
        stack.add(x + 1); stack.add(y);
        stack.add(x - 1); stack.add(y);
        stack.add(x); stack.add(y + 1);
        stack.add(x); stack.add(y - 1);
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

  static bool _isColorMatch(int r1, int g1, int b1, int a1, int r2, int g2, int b2, int a2, double tolerance) {
    if (tolerance <= 0) return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2;
    
    // 简单的颜色差异计算 (欧几里得距离)
    final double diffR = (r1 - r2).toDouble();
    final double diffG = (g1 - g2).toDouble();
    final double diffB = (b1 - b2).toDouble();
    final double diffA = (a1 - a2).toDouble();
    
    final double distance = (diffR * diffR + diffG * diffG + diffB * diffB + diffA * diffA);
    // 255 * 255 * 4 是最大可能距离的平方
    return distance <= tolerance * tolerance * 255 * 255 * 4;
  }
}
