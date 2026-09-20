import 'paint_content_decoder.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import '../paint_extension/quad_homography.dart';
import 'paint_content.dart';
import 'circle.dart';

/// Wraps an existing PaintContent (like a Circle or ClippedHistoryContent)
/// to support scaling, moving, rotating, horizontal/vertical flipping, and 4-corner perspective warping.
class ShapeStickerContent extends PaintContent {
  ShapeStickerContent({
    required this.child,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.size,
    this.flipX = false,
    this.flipY = false,
    this.topLeftOffset = Offset.zero,
    this.topRightOffset = Offset.zero,
    this.bottomRightOffset = Offset.zero,
    this.bottomLeftOffset = Offset.zero,
  });

  ShapeStickerContent.data({
    required this.child,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.size,
    this.flipX = false,
    this.flipY = false,
    this.topLeftOffset = Offset.zero,
    this.topRightOffset = Offset.zero,
    this.bottomRightOffset = Offset.zero,
    this.bottomLeftOffset = Offset.zero,
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
      scale: (data['scale'] as num).toDouble(),
      rotation: (data['rotation'] as num).toDouble(),
      size: Size((data['width'] as num).toDouble(), (data['height'] as num).toDouble()),
      flipX: data['flipX'] as bool? ?? false,
      flipY: data['flipY'] as bool? ?? false,
      topLeftOffset: data['topLeftOffset'] != null
          ? jsonToOffset(data['topLeftOffset'] as Map<String, dynamic>)
          : Offset.zero,
      topRightOffset: data['topRightOffset'] != null
          ? jsonToOffset(data['topRightOffset'] as Map<String, dynamic>)
          : Offset.zero,
      bottomRightOffset: data['bottomRightOffset'] != null
          ? jsonToOffset(data['bottomRightOffset'] as Map<String, dynamic>)
          : Offset.zero,
      bottomLeftOffset: data['bottomLeftOffset'] != null
          ? jsonToOffset(data['bottomLeftOffset'] as Map<String, dynamic>)
          : Offset.zero,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  PaintContent child;
  Offset offset;
  double scale;
  double rotation;
  Size size;
  bool flipX;
  bool flipY;
  Offset topLeftOffset;
  Offset topRightOffset;
  Offset bottomRightOffset;
  Offset bottomLeftOffset;

  /// Returns true if any 4-corner perspective distortion offset is non-zero
  bool get hasPerspectiveDistortion =>
      topLeftOffset != Offset.zero ||
      topRightOffset != Offset.zero ||
      bottomRightOffset != Offset.zero ||
      bottomLeftOffset != Offset.zero;

  /// Computes the 4x4 matrix mapping local bounds [0, w] x [0, h] to the distorted quadrilateral.
  Matrix4 getPerspectiveMatrix() {
    return QuadHomography.fromRectToQuad(
      width: size.width,
      height: size.height,
      p0: Offset.zero + topLeftOffset,
      p1: Offset(size.width, 0) + topRightOffset,
      p2: Offset(size.width, size.height) + bottomRightOffset,
      p3: Offset(0, size.height) + bottomLeftOffset,
    );
  }

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

    // Apply flip around the center
    if (flipX || flipY) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    // Apply 4-corner perspective distortion matrix if present
    if (hasPerspectiveDistortion) {
      final Matrix4 matrix = getPerspectiveMatrix();
      canvas.transform(matrix.storage);
    }

    child.draw(canvas, size, deeper);

    canvas.restore();
  }

  @override
  Path getPath() {
    final Rect rect = Rect.fromCenter(center: offset, width: size.width, height: size.height);
    final Path path = Path()..addRect(rect);
    return path;
  }

  @override
  ShapeStickerContent copy() => ShapeStickerContent.data(
    child: child,
    offset: offset,
    scale: scale,
    rotation: rotation,
    size: size,
    flipX: flipX,
    flipY: flipY,
    topLeftOffset: topLeftOffset,
    topRightOffset: topRightOffset,
    bottomRightOffset: bottomRightOffset,
    bottomLeftOffset: bottomLeftOffset,
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
      'flipX': flipX,
      'flipY': flipY,
      if (topLeftOffset != Offset.zero) 'topLeftOffset': topLeftOffset.toJson(),
      if (topRightOffset != Offset.zero) 'topRightOffset': topRightOffset.toJson(),
      if (bottomRightOffset != Offset.zero) 'bottomRightOffset': bottomRightOffset.toJson(),
      if (bottomLeftOffset != Offset.zero) 'bottomLeftOffset': bottomLeftOffset.toJson(),
      'paint': paint.toJson(),
    };
  }

  @override
  Future<void> prepareExport() async {
    await child.prepareExport();
  }
}
