import 'paint_content_decoder.dart';

import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';
import 'circle.dart';

/// Wraps an existing PaintContent (like a Circle) to support scaling, moving, and rotating.
class ShapeStickerContent extends PaintContent {
  ShapeStickerContent({
    required this.child,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.size,
  });

  ShapeStickerContent.data({
    required this.child,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.size,
    required Paint paint,
  }) : super.paint(paint);

  factory ShapeStickerContent.fromJson(Map<String, dynamic> data) {
    PaintContent? child = decodePaintContent(
      data['childType'] as String,
      data['child'] as Map<String, dynamic>,
    );
    child ??= Circle(); // fallback, though decodePaintContent should handle most cases

    return ShapeStickerContent.data(
      child: child,
      offset: jsonToOffset(data['offset'] as Map<String, dynamic>),
      scale: data['scale'] as double,
      rotation: data['rotation'] as double,
      size: Size(data['width'] as double, data['height'] as double),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  PaintContent child;
  Offset offset;
  double scale;
  double rotation;
  Size size;

  @override
  String get contentType => 'ShapeStickerContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size canvasSize, bool deeper) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    child.draw(canvas, size, deeper);

    canvas.restore();
  }

  @override
  Path getPath() {
    final Rect rect = Rect.fromCenter(center: offset, width: size.width, height: size.height);
    final Path path = Path()..addRect(rect);
    return path;
    // Note: To be perfectly accurate we could apply Matrix4 transform for rotation and scale,
    // but returning the loose bounded square around the offset ensures lasso roughly catches it!
  }

  @override
  ShapeStickerContent copy() => ShapeStickerContent.data(
    child: child.copy(),
    offset: offset,
    scale: scale,
    rotation: rotation,
    size: size,
    paint: paint.copyWith(),
  );

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'childType': child.contentType,
      'child': child.toContentJson(),
      'offset': offset.toJson(),
      'scale': scale,
      'rotation': rotation,
      'width': size.width,
      'height': size.height,
      'paint': paint.toJson(),
    };
  }

  @override
  Future<void> prepareExport() async {
    await child.prepareExport();
  }
}
