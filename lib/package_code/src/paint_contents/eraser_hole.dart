import 'package:flutter/painting.dart';
import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class EraserHole extends PaintContent {
  EraserHole({required this.path, required Paint paint}) : super.paint(paint);

  factory EraserHole.fromJson(Map<String, dynamic> data) {
    return EraserHole(
      path: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  final DrawPath path;

  @override
  String get contentType => 'EraserHole';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.drawPath(path.path, paint);
  }

  @override
  EraserHole copy() => EraserHole(path: path.copy(), paint: paint.copyWith());

  @override
  Path getPath() => path.path;

  @override
  Map<String, dynamic> toContentJson() => {
    'path': path.toJson(),
    'paint': paint.toJson(),
  };
}
