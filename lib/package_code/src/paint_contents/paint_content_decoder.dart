import 'paint_content.dart';
import 'simple_line.dart';
import 'smooth_line.dart';
import 'straight_line.dart';
import 'rectangle.dart';
import 'circle.dart';
import 'triangle.dart';
import 'eraser.dart';
import 'lasso.dart';
import 'text.dart';
import 'shape_sticker.dart';
import 'group.dart';
import 'fill.dart';
import 'clipped.dart';
import 'eraser_hole.dart';
import 'eyedropper.dart';
import 'blur.dart';
import 'smudge.dart';
import 'image.dart';
import 'empty_content.dart';
import '../ruler/mirror_content.dart';
import 'extra_shapes.dart';

PaintContent? decodePaintContent(String type, Map<String, dynamic> data) {
  switch (type) {
    case 'SimpleLine':
      // Backward compatibility: check if it's the old freehand SimpleLine
      if (data.containsKey('points') || data.containsKey('path')) {
        return FreehandLine.fromJson(data);
      }
      return SimpleLine.fromJson(data);
    case 'FreehandLine':
      return FreehandLine.fromJson(data);
    case 'SmoothLine':
      return SmoothLine.fromJson(data);
    case 'StraightLine':
      return StraightLine.fromJson(data);
    case 'Rectangle':
      return Rectangle.fromJson(data);
    case 'Circle':
      return Circle.fromJson(data);
    case 'Triangle':
      return Triangle.fromJson(data);
    case 'Eraser':
      return Eraser.fromJson(data);
    case 'Lasso':
      return Lasso.fromJson(data);
    case 'TextContent':
      return TextContent.fromJson(data);
    case 'ImageContent':
      return ImageContent.fromJson(data);
    case 'ShapeStickerContent':
      return ShapeStickerContent.fromJson(data);
    case 'GroupContent':
      return GroupContent.fromJson(data);
    case 'FillContent':
      return FillContent.fromJson(data);
    case 'ClippedHistoryContent':
      return ClippedHistoryContent.fromJson(data);
    case 'EraserHole':
      return EraserHole.fromJson(data);
    case 'Eyedropper':
      return Eyedropper.fromJson(data);
    case 'BlurContent':
      return BlurContent.fromJson(data);
    case 'SmudgeContent':
      return SmudgeContent.fromJson(data);
    case 'EmptyContent':
      return EmptyContent.fromJson(data);
    case 'Mirror':
      return MirrorContent.fromJson(data);
    case 'Pentagon':
      return Pentagon.fromJson(data);
    case 'Heart':
      return Heart.fromJson(data);
    case 'CubeShape':
      return CubeShape.fromJson(data);
    case 'CylinderShape':
      return CylinderShape.fromJson(data);
    default:
      return null;
  }
}
