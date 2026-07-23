import 'package:flutter/painting.dart';
import '../draw_path/draw_path.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'circle.dart';
import 'rectangle.dart';
import 'empty_content.dart';
import 'eraser.dart';
import 'paint_content.dart';
import 'simple_line.dart';
import 'smooth_line.dart';
import 'straight_line.dart';
import 'text.dart';
import 'triangle.dart';
import 'shape_sticker.dart';
import 'group.dart';
import 'fill.dart';
import 'eraser_hole.dart';
import 'eyedropper.dart';
import 'blur.dart';
import 'smudge.dart';
import 'lasso.dart';
import 'image.dart';
import 'paint_content_decoder.dart';

/// Content wrapper that applies an offset to its child
class OffsetContent extends PaintContent {
  OffsetContent(this.child, this.shiftOffset) : super.paint(child.paint);

  final PaintContent child;
  final Offset shiftOffset;

  @override
  String get contentType => 'OffsetContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.save();
    canvas.translate(shiftOffset.dx, shiftOffset.dy);
    child.draw(canvas, size, deeper);
    canvas.restore();
  }

  @override
  OffsetContent copy() => OffsetContent(child.copy(), shiftOffset);

  @override
  Path getPath() => child.getPath().shift(shiftOffset);

  @override
  Map<String, dynamic> toContentJson() => {
    'child': child.toJson(),
    'shiftOffset': shiftOffset.toJson(),
  };

  @override
  Future<void> prepareExport() async {
    await child.prepareExport();
  }
}

/// Content wrapper that clips vector history to a specific path
class ClippedHistoryContent extends PaintContent {
  ClippedHistoryContent(
    this.history,
    this.clipPath,
    this.clipRect, {
    this.canvasSize,
    Paint? paint,
  }) : super.paint(paint ?? Paint());

  factory ClippedHistoryContent.fromJson(Map<String, dynamic> data) {
    final List<PaintContent> historyList = [];
    final List<dynamic> historyData = data['history'] as List<dynamic>? ?? [];
    
    for (final item in historyData) {
      if (item is Map<String, dynamic>) {
        final content = decodePaintContent(item['type'] as String, item);
        if (content != null) {
          historyList.add(content);
        }
      }
    }

    final double l = (data['clipRect_left'] as num?)?.toDouble() ?? 0;
    final double t = (data['clipRect_top'] as num?)?.toDouble() ?? 0;
    final double r = (data['clipRect_right'] as num?)?.toDouble() ?? 0;
    final double b = (data['clipRect_bottom'] as num?)?.toDouble() ?? 0;

    final double? csv = (data['canvasSize_width'] as num?)?.toDouble();
    final double? csh = (data['canvasSize_height'] as num?)?.toDouble();
    final Size? canvasSize = (csv != null && csh != null) ? Size(csv, csh) : null;

    return ClippedHistoryContent(
      historyList,
      DrawPath.fromJson(data['clipPath'] as Map<String, dynamic>),
      Rect.fromLTRB(l, t, r, b),
      canvasSize: canvasSize,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  final List<PaintContent> history;
  final DrawPath clipPath;
  final Rect clipRect;
  final Size? canvasSize;

  @override
  String get contentType => 'ClippedHistoryContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.save();
    
    // Shift the clip path to local sticker coordinates
    final Path localClipPath = clipPath.path.shift(Offset(-clipRect.topLeft.dx, -clipRect.topLeft.dy));
    
    // Create an isolated layer so BlendMode.clear (Eraser) within the history
    // only clears the strokes drawn on this sticker and not the UI background.
    // Using null for bounds and applying clip inside the layer is more robust on web.
    canvas.saveLayer(null, Paint());
    
    // Apply the local clipping path inside the layer
    canvas.clipPath(localClipPath);
    
    // Shift canvas to render global history elements relative to local 0,0
    canvas.translate(-clipRect.topLeft.dx, -clipRect.topLeft.dy);
    
    // Render the history elements with an unconstrained Size to prevent TextContent from wrapping 
    // to the sticker's narrow bounding box width.
    const Size unconstrainedSize = Size(100000, 100000);
    for (final content in history) {
      if (content is ImageContent) {
        content.draw(canvas, canvasSize ?? size, deeper);
      } else {
        content.draw(canvas, unconstrainedSize, deeper);
      }
    }
    
    // Restore saveLayer
    canvas.restore();

    // Restore save
    canvas.restore();
  }

  @override
  ClippedHistoryContent copy() => ClippedHistoryContent(
    history.map((e) => e.copy()).toList(), 
    clipPath.copy(), 
    clipRect, 
    canvasSize: canvasSize,
    paint: paint.copyWith(),
  );

  @override
  Path getPath() {
    return Path()..addRect(Rect.fromLTWH(0, 0, clipRect.width, clipRect.height));
  }

  @override
  Map<String, dynamic> toContentJson() {
    return {
      'history': history.map((e) => e.toJson()).toList(),
      'clipPath': clipPath.toJson(),
      'clipRect_left': clipRect.left,
      'clipRect_top': clipRect.top,
      'clipRect_right': clipRect.right,
      'clipRect_bottom': clipRect.bottom,
      'canvasSize_width': canvasSize?.width,
      'canvasSize_height': canvasSize?.height,
      'paint': paint.toJson(),
    };
  }

  @override
  Future<void> prepareExport() async {
    for (final content in history) {
      await content.prepareExport();
    }
  }
}

/// Content wrapper that clips the rendering of its child to a specific path
class ClippedContent extends PaintContent {
  ClippedContent(this.child, this.clipPath) : super.paint(child.paint);

  final PaintContent child;
  final Path clipPath;

  @override
  String get contentType => 'ClippedContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.save();
    canvas.clipPath(clipPath);
    child.draw(canvas, size, deeper);
    canvas.restore();
  }

  @override
  ClippedContent copy() => ClippedContent(child.copy(), Path.from(clipPath));

  @override
  Path getPath() {
    final Rect childBounds = child.getPath().getBounds();
    final Rect clipBounds = clipPath.getBounds();
    if (!childBounds.overlaps(clipBounds)) {
      return Path();
    }
    return Path()..addRect(childBounds.intersect(clipBounds));
  }

  @override
  Map<String, dynamic> toContentJson() => {
    'child': child.toJson(),
  };

  @override
  Future<void> prepareExport() async {
    await child.prepareExport();
  }
}
