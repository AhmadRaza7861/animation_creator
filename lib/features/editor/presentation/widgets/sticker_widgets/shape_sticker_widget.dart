import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../package_code/paint_contents.dart';
import '../../../../../core/widgets/animated_dashed_border.dart';

class ActiveShapeSticker {
  ActiveShapeSticker({
    required this.id,
    required this.content,
    required this.size,
    this.offset = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  final String id;
  PaintContent content;
  Size size;
  Offset offset;
  double scale;
  double rotation;
}

class ShapeStickerWidget extends StatefulWidget {
  const ShapeStickerWidget({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
    required this.onConfirm,
    this.onUpdateEnd,
    this.canvasSize,
  });

  final ActiveShapeSticker data;
  final Function(Offset, double, double) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final VoidCallback? onUpdateEnd;
  final Size? canvasSize;

  @override
  State<ShapeStickerWidget> createState() => _ShapeStickerWidgetState();
}

class _ShapeStickerWidgetState extends State<ShapeStickerWidget> {
  late Offset _offset;
  late double _scale;
  late double _rotation;

  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _focalPoint = Offset.zero;

  double _startPanRotation = 0.0;
  final GlobalKey _centerKey = GlobalKey();
  bool _flipX = false;

  @override
  void initState() {
    super.initState();
    _offset = widget.data.offset;
    _scale = widget.data.scale;
    _rotation = widget.data.rotation;
  }

  @override
  void didUpdateWidget(covariant ShapeStickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.offset != oldWidget.data.offset ||
        widget.data.scale != oldWidget.data.scale ||
        widget.data.rotation != oldWidget.data.rotation) {
      _offset = widget.data.offset;
      _scale = widget.data.scale;
      _rotation = widget.data.rotation;
    }
  }

  // Corner Action Icon
  Widget _buildCornerIcon(IconData icon, Color bg, Color color,
      {GestureDragStartCallback? onPanStart,
      GestureDragUpdateCallback? onPanUpdate,
      GestureDragEndCallback? onPanEnd,
      VoidCallback? onTap}) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // Rotate handle with line
  Widget _buildRotateHandle({
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
  }) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Icon(Icons.sync, size: 14, color: Color(0xFF2196F3)),
            ),
            Container(
              width: 1.5,
              height: 24,
              color: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF2196F3);

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform(
          transform: Matrix4.identity()
            ..scale(_scale, _scale, 1.0)
            ..rotateZ(_rotation),
          alignment: Alignment.center,
          child: Stack(
            key: _centerKey,
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bounding Box and Content
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _startOffset = _offset;
                  _startScale = _scale;
                  _startRotation = _rotation;
                  _focalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _offset = _startOffset + (details.focalPoint - _focalPoint);
                    _scale = (_startScale * details.scale).clamp(0.1, 10.0);
                    _rotation = _startRotation + details.rotation;
                  });
                  widget.onUpdate(_offset, _scale, _rotation);
                },
                onScaleEnd: (details) => widget.onUpdateEnd?.call(),
                onDoubleTap: widget.onConfirm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  child: AnimatedDashedBorder(
                    color: activeColor,
                    strokeWidth: 1.5 / (_scale == 0 ? 1 : _scale),
                    child: Transform(
                      transform: Matrix4.identity()..scale(_flipX ? -1.0 : 1.0, 1.0, 1.0),
                      alignment: Alignment.center,
                      child: CustomPaint(
                        size: widget.data.size,
                        painter: _StickerPainter(widget.data.content, widget.canvasSize),
                      ),
                    ),
                  ),
                ),
              ),
              // Side Border Hit Zones
              Positioned(
                top: 50,
                left: 40,
                right: 40,
                height: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onScaleStart,
                  onPanUpdate: _onScaleUpdate,
                  onPanEnd: _onScaleEnd,
                  child: Container(),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 40,
                right: 40,
                height: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onScaleStart,
                  onPanUpdate: _onScaleUpdate,
                  onPanEnd: _onScaleEnd,
                  child: Container(),
                ),
              ),
              Positioned(
                top: 60,
                bottom: 60,
                left: 30,
                width: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onScaleStart,
                  onPanUpdate: _onScaleUpdate,
                  onPanEnd: _onScaleEnd,
                  child: Container(),
                ),
              ),
              Positioned(
                top: 60,
                bottom: 60,
                right: 30,
                width: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onScaleStart,
                  onPanUpdate: _onScaleUpdate,
                  onPanEnd: _onScaleEnd,
                  child: Container(),
                ),
              ),

              // Top-Left: Delete
              Positioned(
                top: 46,
                left: 26,
                child: _buildCornerIcon(
                  Icons.close,
                  Colors.white,
                  Colors.red,
                  onTap: widget.onDelete,
                ),
              ),
              // Top-Right: Confirm
              Positioned(
                top: 46,
                right: 26,
                child: _buildCornerIcon(
                  Icons.check,
                  const Color(0xFF2196F3),
                  Colors.white,
                  onTap: widget.onConfirm,
                ),
              ),
              // Bottom-Left: Flip
              Positioned(
                bottom: 46,
                left: 26,
                child: _buildCornerIcon(
                  Icons.flip,
                  Colors.white,
                  const Color(0xFF2196F3),
                  onTap: () {
                    setState(() {
                      _flipX = !_flipX;
                    });
                  },
                ),
              ),
              // Bottom-Right: Expand
              Positioned(
                bottom: 46,
                right: 26,
                child: _buildCornerIcon(
                  Icons.open_in_full,
                  Colors.white,
                  const Color(0xFF2196F3),
                  onPanStart: _onScaleStart,
                  onPanUpdate: _onScaleUpdate,
                  onPanEnd: _onScaleEnd,
                ),
              ),

              // Rotate Line & Handle
              Positioned(
                top: 12,
                child: _buildRotateHandle(
                  onPanStart: (details) {
                    final RenderBox renderBox =
                        _centerKey.currentContext!.findRenderObject() as RenderBox;
                    final Offset center = renderBox.localToGlobal(
                      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
                    );
                    final pos = details.globalPosition;
                    _startPanRotation =
                        math.atan2(pos.dy - center.dy, pos.dx - center.dx) - _rotation;
                  },
                  onPanUpdate: (details) {
                    final RenderBox renderBox =
                        _centerKey.currentContext!.findRenderObject() as RenderBox;
                    final Offset center = renderBox.localToGlobal(
                      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
                    );
                    final pos = details.globalPosition;
                    final angle = math.atan2(pos.dy - center.dy, pos.dx - center.dx);

                    setState(() {
                      _rotation = angle - _startPanRotation;
                    });
                    widget.onUpdate(_offset, _scale, _rotation);
                  },
                  onPanEnd: (details) => widget.onUpdateEnd?.call(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onScaleStart(DragStartDetails details) {
    _startScale = _scale;
    _focalPoint = details.globalPosition;
  }

  void _onScaleUpdate(DragUpdateDetails details) {
    final RenderBox renderBox =
        _centerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final pos = details.globalPosition;
    final double initialDist = (_focalPoint - center).distance;
    final double currentDist = (pos - center).distance;
    final double scaleFactor =
        initialDist > 5 ? (currentDist / initialDist) : 1.0;

    setState(() {
      _scale = (_startScale * scaleFactor).clamp(0.1, 10.0);
    });
    widget.onUpdate(_offset, _scale, _rotation);
  }

  void _onScaleEnd(DragEndDetails details) {
    widget.onUpdateEnd?.call();
  }
}

class _StickerPainter extends CustomPainter {
  final PaintContent content;
  final Size? canvasSize;
  _StickerPainter(this.content, this.canvasSize);

  @override
  void paint(Canvas canvas, Size size) {
    content.draw(canvas, canvasSize ?? size, false);
  }

  @override
  bool shouldRepaint(covariant _StickerPainter oldDelegate) => true;
}
