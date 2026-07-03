import 'paint_content_decoder.dart';

import 'package:flutter/painting.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

class GroupContent extends PaintContent {
  GroupContent({
    required this.children,
    this.boundsOffset = Offset.zero,
    Paint? paint,
  }) : super.paint(paint ?? Paint());

  factory GroupContent.fromJson(Map<String, dynamic> data) {
    final List<dynamic> childrenData = data['children'] as List<dynamic>? ?? [];
    return GroupContent(
      children: childrenData
          .map((childData) => decodePaintContent(
                childData['type'] as String,
                childData as Map<String, dynamic>,
              ))
          .where((element) => element != null)
          .cast<PaintContent>()
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      boundsOffset: data['boundsOffset'] != null
          ? Offset(data['boundsOffset']['dx'] as double, data['boundsOffset']['dy'] as double)
          : Offset.zero,
    );
  }

  List<PaintContent> children;
  Offset boundsOffset;

  @override
  String get contentType => 'GroupContent';

  @override
  void startDraw(Offset startPoint) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    canvas.save();
    canvas.translate(boundsOffset.dx, boundsOffset.dy);
    for (PaintContent child in children) {
      child.draw(canvas, size, deeper);
    }
    canvas.restore();
  }

  @override
  Path getPath() {
    final Path path = Path();
    for (PaintContent child in children) {
      path.addPath(child.getPath(), boundsOffset);
    }
    return path;
  }

  @override
  GroupContent copy() => GroupContent(
    children: children.map((c) => c.copy()).toList(),
    boundsOffset: boundsOffset,
    paint: paint,
  );

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'children': children.map((e) => e.toJson()).toList(),
      'paint': paint.toJson(),
    };
  }

  @override
  Future<void> prepareExport() async {
    for (final child in children) {
      await child.prepareExport();
    }
  }
}
