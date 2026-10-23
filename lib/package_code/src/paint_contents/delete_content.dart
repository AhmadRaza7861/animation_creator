import 'dart:ui';
import 'paint_content.dart';

/// A non-destructive deletion marker that hides a target drawing element in layer history.
/// It doesn't draw anything itself, but is used by the controller and layers to skip drawing the target.
class DeleteContent extends PaintContent {
  final String targetId;

  DeleteContent({required this.targetId, super.id});

  factory DeleteContent.fromJson(Map<String, dynamic> data) {
    return DeleteContent(
      targetId: data['targetId'] as String? ?? (data['targetUuid'] as String? ?? ''),
      id: data['id'] as String?,
    );
  }

  @override
  String get contentType => 'DeleteContent';

  @override
  DeleteContent copy() => DeleteContent(targetId: targetId, id: id);

  @override
  void draw(Canvas canvas, Size size, bool deeper) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void startDraw(Offset startPoint) {}

  @override
  Map<String, dynamic> toContentJson() => {
    'targetId': targetId,
  };
}
