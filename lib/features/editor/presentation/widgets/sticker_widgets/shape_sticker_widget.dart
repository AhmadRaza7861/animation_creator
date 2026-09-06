import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../package_code/paint_contents.dart';

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
  static const double _kPadH = 24.0;
  static const double _kPadV = 48.0;
  static const double _kMinTotalWidth = 120.0;

  late Offset _offset;
  late double _scale;
  late double _rotation;

  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _focalPoint = Offset.zero;

  double _previousAngle = 0.0;
  double _previousDist = 0.0;
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

  // Corner resize node (Figma/Apple Freeform style circular handle with App Primary Theme)
  Widget _buildCornerHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 36,
          height: 36,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ColorConstants.primary, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Horizontal side pill handle (Top & Bottom midpoints)
  Widget _buildHorizontalSideHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 32,
          height: 32,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 15,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ColorConstants.primary, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Vertical side pill handle (Left & Right midpoints)
  Widget _buildVerticalSideHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 32,
          height: 32,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 6,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ColorConstants.primary, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Top rotate handle (Pro styling with hairline stem & circular rotation badge)
  Widget _buildRotateHandle() {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onRotateStart,
        onPanUpdate: _onRotateUpdate,
        onPanEnd: (details) => widget.onUpdateEnd?.call(),
        child: Container(
          width: 44,
          height: 44,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorConstants.primary, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primary.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rotate_right_rounded,
                  size: 15,
                  color: ColorConstants.primary,
                ),
              ),
              Container(
                width: 1.5,
                height: 10,
                color: ColorConstants.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ultra-Clean Minimalist Floating Micro-Pill (Flip + Delete)
  Widget _buildFloatingActionPill() {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.topCenter,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE181724),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flip horizontal button
            _buildPillButton(
              icon: Icons.flip_rounded,
              tooltip: 'Flip Horizontal',
              onTap: () {
                setState(() {
                  _flipX = !_flipX;
                });
              },
            ),
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            // Delete button
            _buildPillButton(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFFF5252),
              tooltip: 'Delete',
              onTap: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    Color color = Colors.white,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  void _onScaleHandleStart(DragStartDetails details) {
    final RenderBox? renderBox = _centerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final pos = details.globalPosition;
    _previousDist = (pos - center).distance;
  }

  void _onScaleHandleUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _centerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final pos = details.globalPosition;
    final double currentDist = (pos - center).distance;
    if (_previousDist > 5 && currentDist > 5) {
      final double scaleRatio = currentDist / _previousDist;
      setState(() {
        _scale = (_scale * scaleRatio).clamp(0.1, 10.0);
      });
      _previousDist = currentDist;
      widget.onUpdate(_offset, _scale, _rotation);
    }
  }

  void _onRotateStart(DragStartDetails details) {
    final RenderBox? renderBox = _centerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final pos = details.globalPosition;
    _previousAngle = math.atan2(pos.dy - center.dy, pos.dx - center.dx);
  }

  void _onRotateUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _centerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final pos = details.globalPosition;
    final double currentAngle = math.atan2(pos.dy - center.dy, pos.dx - center.dx);
    double delta = currentAngle - _previousAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _previousAngle = currentAngle;
    setState(() {
      _rotation += delta;
    });
    widget.onUpdate(_offset, _scale, _rotation);
  }

  @override
  Widget build(BuildContext context) {
    final double w = widget.data.size.width;
    final double h = widget.data.size.height;
    final double totalWidth = math.max(w + _kPadH * 2, _kMinTotalWidth);
    final double totalHeight = h + _kPadV * 2;
    final double contentLeft = (totalWidth - w) / 2;
    final double contentTop = _kPadV;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform(
          transform: Matrix4.diagonal3Values(_scale, _scale, 1.0)
            ..rotateZ(_rotation),
          alignment: Alignment.center,
          child: SizedBox(
            key: _centerKey,
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Center Content Box (snug border + gesture in App Theme Primary)
                Positioned(
                  left: contentLeft,
                  top: contentTop,
                  width: w,
                  height: h,
                  child: GestureDetector(
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: ColorConstants.primary,
                          width: 1.5 / (_scale == 0 ? 1 : _scale),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primary.withValues(alpha: 0.12),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: Transform(
                        transform: Matrix4.diagonal3Values(_flipX ? -1.0 : 1.0, 1.0, 1.0),
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: widget.data.size,
                          painter: _StickerPainter(widget.data.content, widget.canvasSize),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. 4 Side Midpoint Pill Handles
                // Top side midpoint
                Positioned(
                  left: contentLeft + w / 2 - 16,
                  top: contentTop - 16,
                  child: _buildHorizontalSideHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                // Bottom side midpoint
                Positioned(
                  left: contentLeft + w / 2 - 16,
                  top: contentTop + h - 16,
                  child: _buildHorizontalSideHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                // Left side midpoint
                Positioned(
                  left: contentLeft - 16,
                  top: contentTop + h / 2 - 16,
                  child: _buildVerticalSideHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                // Right side midpoint
                Positioned(
                  left: contentLeft + w - 16,
                  top: contentTop + h / 2 - 16,
                  child: _buildVerticalSideHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),

                // 3. 4 Corner Resize Nodes
                Positioned(
                  left: contentLeft - 18,
                  top: contentTop - 18,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                Positioned(
                  left: contentLeft + w - 18,
                  top: contentTop - 18,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                Positioned(
                  left: contentLeft - 18,
                  top: contentTop + h - 18,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),
                Positioned(
                  left: contentLeft + w - 18,
                  top: contentTop + h - 18,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                  ),
                ),

                // 4. Rotate Handle at Top
                Positioned(
                  top: contentTop - 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildRotateHandle(),
                  ),
                ),

                // 5. Floating Action Bar at Bottom (Ultra-compact Flip + Delete)
                Positioned(
                  top: contentTop + h + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildFloatingActionPill(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
