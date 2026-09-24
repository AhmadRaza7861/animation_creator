import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'paint_content.dart';
import 'empty_content.dart';

/// Stroke Recolor Content
///
/// Records an in-place recoloring of an existing stroke or shape on the layer.
/// This allows vector line art to be recolored with 100% native crisp anti-aliasing
/// without any raster blur, dirty edge fringing, or black speckle artifacts.
class StrokeRecolorContent extends PaintContent {
  StrokeRecolorContent({
    required this.targetItem,
    required this.oldColor,
    required this.newColor,
    this.targetIndex = -1,
  });

  PaintContent targetItem;
  final Color oldColor;
  final Color newColor;
  int targetIndex;

  void revert() {
    targetItem.paint.color = oldColor;
  }

  void apply() {
    targetItem.paint.color = newColor;
  }

  @override
  String get contentType => 'StrokeRecolorContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // The target item is drawn directly at its position in history with its updated color.
  }

  @override
  StrokeRecolorContent copy() => StrokeRecolorContent(
        targetItem: targetItem,
        oldColor: oldColor,
        newColor: newColor,
        targetIndex: targetIndex,
      );

  @override
  Map<String, dynamic> toContentJson() => {
        'targetIndex': targetIndex,
        'oldColor': oldColor.toARGB32(),
        'newColor': newColor.toARGB32(),
      };

  factory StrokeRecolorContent.fromJson(
    Map<String, dynamic> data, [
    List<PaintContent>? history,
  ]) {
    final int idx = (data['targetIndex'] as num?)?.toInt() ?? -1;
    final int oldVal = (data['oldColor'] as num?)?.toInt() ?? 0xFF000000;
    final int newVal = (data['newColor'] as num?)?.toInt() ?? 0xFF000000;
    final PaintContent target =
        (history != null && idx >= 0 && idx < history.length)
            ? history[idx]
            : EmptyContent();
    return StrokeRecolorContent(
      targetItem: target,
      oldColor: Color(oldVal),
      newColor: Color(newVal),
      targetIndex: idx,
    );
  }
}
