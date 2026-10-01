import 'package:flutter/material.dart';
import 'paint_content.dart';
import 'empty_content.dart';
import 'shape_sticker.dart';

/// Shape Fill Content
///
/// Records an in-place interior fill or recolor of an existing closed shape on the layer.
/// This allows vector shapes (circles, rectangles, triangles, polygons, shape stickers)
/// to maintain crisp vector boundaries, independent fill colors, and proper stacking
/// even when touching or overlapping other shapes.
class ShapeFillContent extends PaintContent {
  ShapeFillContent({
    required this.targetShape,
    required this.oldFillColor,
    required this.newFillColor,
    this.targetIndex = -1,
  });

  PaintContent targetShape;
  final Color? oldFillColor;
  final Color newFillColor;
  int targetIndex;

  void revert() {
    targetShape.fillColor = oldFillColor;
    if (targetShape is ShapeStickerContent) {
      (targetShape as ShapeStickerContent).child.fillColor = oldFillColor;
    }
  }

  void apply() {
    targetShape.fillColor = newFillColor;
    if (targetShape is ShapeStickerContent) {
      (targetShape as ShapeStickerContent).child.fillColor = newFillColor;
    }
  }

  @override
  String get contentType => 'ShapeFillContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // The target shape is drawn directly at its position in history with its updated fillColor.
  }

  @override
  ShapeFillContent copy() => ShapeFillContent(
        targetShape: targetShape,
        oldFillColor: oldFillColor,
        newFillColor: newFillColor,
        targetIndex: targetIndex,
      );

  @override
  Map<String, dynamic> toContentJson() => {
        'targetIndex': targetIndex,
        'oldFillColor': oldFillColor?.toARGB32(),
        'newFillColor': newFillColor.toARGB32(),
      };

  factory ShapeFillContent.fromJson(
    Map<String, dynamic> data, [
    List<PaintContent>? history,
  ]) {
    final int idx = (data['targetIndex'] as num?)?.toInt() ?? -1;
    final int? oldVal = (data['oldFillColor'] as num?)?.toInt();
    final int newVal = (data['newFillColor'] as num?)?.toInt() ?? 0xFF000000;
    final PaintContent target =
        (history != null && idx >= 0 && idx < history.length)
            ? history[idx]
            : EmptyContent();
    return ShapeFillContent(
      targetShape: target,
      oldFillColor: oldVal != null ? Color(oldVal) : null,
      newFillColor: Color(newVal),
      targetIndex: idx,
    );
  }
}
