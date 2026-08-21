import 'package:flutter/material.dart';
import '../../../core/widgets/font_presets.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 文本绘制内容
///
/// Text Drawing Content
class TextContent extends PaintContent {
  TextContent({
    this.text = '',
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontSize = 24.0,
    this.isBold = true,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = TextAlign.left,
    this.opacity = 1.0,
    this.fontFamily,
  });

  TextContent.data({
    required this.offset,
    required this.text,
    required this.scale,
    required this.rotation,
    required this.fontSize,
    required this.isBold,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = TextAlign.left,
    this.opacity = 1.0,
    this.fontFamily,
    required Paint paint,
  }) : super.paint(paint);

  factory TextContent.fromJson(Map<String, dynamic> data) {
    return TextContent.data(
      offset: jsonToOffset(data['offset'] as Map<String, dynamic>),
      text: data['text'] as String,
      scale: data['scale'] as double,
      rotation: data['rotation'] as double,
      fontSize: data['fontSize'] as double,
      isBold: data['isBold'] as bool? ?? true,
      isItalic: data['isItalic'] as bool? ?? false,
      isUnderline: data['isUnderline'] as bool? ?? false,
      textAlign: data['textAlign'] != null
          ? TextAlign.values[data['textAlign'] as int]
          : TextAlign.left,
      opacity: (data['opacity'] as num?)?.toDouble() ?? 1.0,
      fontFamily: data['fontFamily'] as String?,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 绘制位置 (中心点)
  ///
  /// Center point coordinates
  Offset offset = Offset.zero;

  /// 缩放
  double scale = 1.0;

  /// 旋转角度
  double rotation = 0.0;

  /// 字体大小
  double fontSize = 24.0;

  /// 是否加粗
  bool isBold = true;

  /// 是否斜体
  bool isItalic = false;

  /// 是否下划线
  bool isUnderline = false;

  /// 对齐方式
  TextAlign textAlign = TextAlign.left;

  /// 透明度
  double opacity = 1.0;

  /// 字体
  String? fontFamily;

  /// 文本内容
  ///
  /// Text content
  String text = '';

  @override
  String get contentType => 'TextContent';

  @override
  void startDraw(Offset startPoint) => offset = startPoint;

  @override
  void drawing(Offset nowPoint) => offset = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (text.isEmpty) {
      return;
    }

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: getFontPresetByName(fontFamily).getTextStyle(
          color: paint.color,
          fontSize: fontSize,
          opacity: opacity,
          forceBold: isBold,
          forceItalic: isItalic,
          forceUnderline: isUnderline,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale, scale);
    canvas.rotate(rotation);

    // Draw centered on the offset
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  Path getPath() {
    final Rect rect = Rect.fromCenter(center: offset, width: 100 * scale, height: 50 * scale);
    return Path()..addRect(rect);
  }

  @override
  TextContent copy() => TextContent.data(
    offset: offset,
    text: text,
    scale: scale,
    rotation: rotation,
    fontSize: fontSize,
    isBold: isBold,
    isItalic: isItalic,
    isUnderline: isUnderline,
    textAlign: textAlign,
    opacity: opacity,
    fontFamily: fontFamily,
    paint: paint.copyWith(),
  );

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'offset': offset.toJson(),
      'text': text,
      'scale': scale,
      'rotation': rotation,
      'fontSize': fontSize,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'textAlign': textAlign.index,
      'opacity': opacity,
      'fontFamily': fontFamily,
      'paint': paint.toJson(),
    };
  }
}
