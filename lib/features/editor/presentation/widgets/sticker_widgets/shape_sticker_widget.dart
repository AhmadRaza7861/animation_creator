import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../package_code/paint_contents.dart';
import '../../../../../package_code/src/paint_extension/quad_homography.dart';

enum StickerTransformMode {
  transform,
  perspective,
}

class ActiveShapeSticker {
  ActiveShapeSticker({
    required this.id,
    required this.content,
    required this.size,
    this.offset = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipX = false,
    this.flipY = false,
    this.topLeftOffset = Offset.zero,
    this.topRightOffset = Offset.zero,
    this.bottomRightOffset = Offset.zero,
    this.bottomLeftOffset = Offset.zero,
    this.transformMode = StickerTransformMode.transform,
    this.isLassoSelection = false,
  });

  final String id;
  PaintContent content;
  Size size;
  Offset offset;
  double scale;
  double rotation;
  bool flipX;
  bool flipY;
  Offset topLeftOffset;
  Offset topRightOffset;
  Offset bottomRightOffset;
  Offset bottomLeftOffset;
  StickerTransformMode transformMode;
  bool isLassoSelection;

  bool get isLasso => isLassoSelection || content is ClippedHistoryContent;

  bool get hasPerspectiveDistortion =>
      topLeftOffset != Offset.zero ||
      topRightOffset != Offset.zero ||
      bottomRightOffset != Offset.zero ||
      bottomLeftOffset != Offset.zero;

  void resetAll() {
    scale = 1.0;
    rotation = 0.0;
    flipX = false;
    flipY = false;
    topLeftOffset = Offset.zero;
    topRightOffset = Offset.zero;
    bottomRightOffset = Offset.zero;
    bottomLeftOffset = Offset.zero;
    transformMode = StickerTransformMode.transform;
  }
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
  static const double _kPadH = 40.0;
  static const double _kPadV = 56.0;
  static const double _kMinTotalWidth = 140.0;

  late Offset _offset;
  late double _scale;
  late double _rotation;
  late bool _flipX;
  late bool _flipY;
  late Offset _topLeftOffset;
  late Offset _topRightOffset;
  late Offset _bottomRightOffset;
  late Offset _bottomLeftOffset;
  late StickerTransformMode _transformMode;

  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _focalPoint = Offset.zero;

  double _previousAngle = 0.0;
  double _previousDist = 0.0;
  final GlobalKey _centerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _offset = widget.data.offset;
    _scale = widget.data.scale;
    _rotation = widget.data.rotation;
    _flipX = widget.data.flipX;
    _flipY = widget.data.flipY;
    _topLeftOffset = widget.data.topLeftOffset;
    _topRightOffset = widget.data.topRightOffset;
    _bottomRightOffset = widget.data.bottomRightOffset;
    _bottomLeftOffset = widget.data.bottomLeftOffset;
    _transformMode = widget.data.transformMode;
  }

  @override
  void didUpdateWidget(covariant ShapeStickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _offset = widget.data.offset;
      _scale = widget.data.scale;
      _rotation = widget.data.rotation;
      _flipX = widget.data.flipX;
      _flipY = widget.data.flipY;
      _topLeftOffset = widget.data.topLeftOffset;
      _topRightOffset = widget.data.topRightOffset;
      _bottomRightOffset = widget.data.bottomRightOffset;
      _bottomLeftOffset = widget.data.bottomLeftOffset;
      _transformMode = widget.data.transformMode;
    });
  }

  /// Converts a global screen delta into the sticker's local (rotated, scaled, flipped) coordinate space.
  Offset _screenDeltaToLocal(Offset screenDelta) {
    final double s = _scale == 0 ? 1.0 : _scale;
    // Unrotate: R(-_rotation)
    final double cosR = math.cos(-_rotation);
    final double sinR = math.sin(-_rotation);
    double lx = (screenDelta.dx * cosR - screenDelta.dy * sinR) / s;
    double ly = (screenDelta.dx * sinR + screenDelta.dy * cosR) / s;

    // Handle flips
    if (_flipX) lx = -lx;
    if (_flipY) ly = -ly;

    return Offset(lx, ly);
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

  // Perspective Pin Handle (Glowing circular node for 4 corners)
  Widget _buildPerspectivePinHandle({
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Transform.scale(
      scale: 1.0 / (_scale == 0 ? 1 : _scale),
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 44,
          height: 44,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: ColorConstants.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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

  // Ultra-Clean Minimalist Floating Micro-Pill (Flip + Delete for regular shapes)
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
                  widget.data.flipX = _flipX;
                });
                widget.onUpdate(_offset, _scale, _rotation);
                widget.onUpdateEnd?.call();
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.15),
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

    if (_previousDist > 0) {
      final double factor = currentDist / _previousDist;
      setState(() {
        _scale = (_scale * factor).clamp(0.1, 10.0);
      });
      widget.onUpdate(_offset, _scale, _rotation);
    }
    _previousDist = currentDist;
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
    final bool isPerspective = _transformMode == StickerTransformMode.perspective;

    // Corner destination positions in local stack coordinates
    final Offset p0 = Offset(contentLeft, contentTop) + _topLeftOffset;
    final Offset p1 = Offset(contentLeft + w, contentTop) + _topRightOffset;
    final Offset p2 = Offset(contentLeft + w, contentTop + h) + _bottomRightOffset;
    final Offset p3 = Offset(contentLeft, contentTop + h) + _bottomLeftOffset;

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
                // 1. Center Content Box (Rendered with homography & gesture)
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
                        if (!isPerspective) {
                          _scale = (_startScale * details.scale).clamp(0.1, 10.0);
                          _rotation = _startRotation + details.rotation;
                        }
                      });
                      widget.onUpdate(_offset, _scale, _rotation);
                    },
                    onScaleEnd: (details) => widget.onUpdateEnd?.call(),
                    onDoubleTap: widget.onConfirm,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: isPerspective
                            ? null
                            : Border.all(
                                color: ColorConstants.primary,
                                width: 1.5 / (_scale == 0 ? 1 : _scale),
                              ),
                        boxShadow: isPerspective
                            ? null
                            : [
                                BoxShadow(
                                  color: ColorConstants.primary.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ],
                      ),
                      child: CustomPaint(
                        size: widget.data.size,
                        painter: _StickerPainter(
                          widget.data.content,
                          widget.canvasSize,
                          topLeftOffset: _topLeftOffset,
                          topRightOffset: _topRightOffset,
                          bottomRightOffset: _bottomRightOffset,
                          bottomLeftOffset: _bottomLeftOffset,
                          flipX: _flipX,
                          flipY: _flipY,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Perspective Quad Guidelines (in PERSP mode)
                if (isPerspective)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PerspectiveQuadPainter(
                          p0: p0,
                          p1: p1,
                          p2: p2,
                          p3: p3,
                          scale: _scale,
                        ),
                      ),
                    ),
                  ),

                // 3. Handles:
                // --- If PERSP mode: 4 Interactive Corner Pins ---
                if (isPerspective) ...[
                  Positioned(
                    left: p0.dx - 22,
                    top: p0.dy - 22,
                    child: _buildPerspectivePinHandle(
                      onPanUpdate: (details) {
                        final localDelta = _screenDeltaToLocal(details.delta);
                        setState(() {
                          _topLeftOffset += localDelta;
                          widget.data.topLeftOffset = _topLeftOffset;
                        });
                        widget.onUpdate(_offset, _scale, _rotation);
                      },
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: p1.dx - 22,
                    top: p1.dy - 22,
                    child: _buildPerspectivePinHandle(
                      onPanUpdate: (details) {
                        final localDelta = _screenDeltaToLocal(details.delta);
                        setState(() {
                          _topRightOffset += localDelta;
                          widget.data.topRightOffset = _topRightOffset;
                        });
                        widget.onUpdate(_offset, _scale, _rotation);
                      },
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: p2.dx - 22,
                    top: p2.dy - 22,
                    child: _buildPerspectivePinHandle(
                      onPanUpdate: (details) {
                        final localDelta = _screenDeltaToLocal(details.delta);
                        setState(() {
                          _bottomRightOffset += localDelta;
                          widget.data.bottomRightOffset = _bottomRightOffset;
                        });
                        widget.onUpdate(_offset, _scale, _rotation);
                      },
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: p3.dx - 22,
                    top: p3.dy - 22,
                    child: _buildPerspectivePinHandle(
                      onPanUpdate: (details) {
                        final localDelta = _screenDeltaToLocal(details.delta);
                        setState(() {
                          _bottomLeftOffset += localDelta;
                          widget.data.bottomLeftOffset = _bottomLeftOffset;
                        });
                        widget.onUpdate(_offset, _scale, _rotation);
                      },
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                ],

                // --- If TRSF mode: 4 Midpoints, 4 Corners, 1 Rotate Handle ---
                if (!isPerspective) ...[
                  // 4 Side Midpoint Pill Handles
                  Positioned(
                    left: contentLeft + w / 2 - 16,
                    top: contentTop - 16,
                    child: _buildHorizontalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: contentLeft + w / 2 - 16,
                    top: contentTop + h - 16,
                    child: _buildHorizontalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: contentLeft - 16,
                    top: contentTop + h / 2 - 16,
                    child: _buildVerticalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),
                  Positioned(
                    left: contentLeft + w - 16,
                    top: contentTop + h / 2 - 16,
                    child: _buildVerticalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    ),
                  ),

                  // 4 Corner Resize Nodes
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

                  // Top Rotate Handle
                  Positioned(
                    top: contentTop - 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildRotateHandle(),
                    ),
                  ),
                ],

                // 4. Floating Action Micro-Pill at Bottom (Only for standard shape stickers)
                if (!widget.data.isLasso)
                  Positioned(
                    top: math.max(p2.dy, p3.dy) + 12,
                    left: -200,
                    right: -200,
                    child: Center(
                      child: UnconstrainedBox(
                        child: _buildFloatingActionPill(),
                      ),
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

class _PerspectiveQuadPainter extends CustomPainter {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final Offset p3;
  final double scale;

  _PerspectiveQuadPainter({
    required this.p0,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = scale == 0 ? 1 : scale;
    final strokePaint = Paint()
      ..color = ColorConstants.primary
      ..strokeWidth = 1.6 / s
      ..style = PaintingStyle.stroke;

    final diagPaint = Paint()
      ..color = ColorConstants.primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.0 / s
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, strokePaint);
    canvas.drawLine(p0, p2, diagPaint);
    canvas.drawLine(p1, p3, diagPaint);
  }

  @override
  bool shouldRepaint(covariant _PerspectiveQuadPainter oldDelegate) =>
      oldDelegate.p0 != p0 ||
      oldDelegate.p1 != p1 ||
      oldDelegate.p2 != p2 ||
      oldDelegate.p3 != p3 ||
      oldDelegate.scale != scale;
}

class _StickerPainter extends CustomPainter {
  final PaintContent content;
  final Size? canvasSize;
  final Offset topLeftOffset;
  final Offset topRightOffset;
  final Offset bottomRightOffset;
  final Offset bottomLeftOffset;
  final bool flipX;
  final bool flipY;

  _StickerPainter(
    this.content,
    this.canvasSize, {
    this.topLeftOffset = Offset.zero,
    this.topRightOffset = Offset.zero,
    this.bottomRightOffset = Offset.zero,
    this.bottomLeftOffset = Offset.zero,
    this.flipX = false,
    this.flipY = false,
  });

  bool get hasPerspectiveDistortion =>
      topLeftOffset != Offset.zero ||
      topRightOffset != Offset.zero ||
      bottomRightOffset != Offset.zero ||
      bottomLeftOffset != Offset.zero;

  @override
  void paint(Canvas canvas, Size size) {
    if (flipX || flipY) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    if (hasPerspectiveDistortion) {
      final matrix = QuadHomography.fromRectToQuad(
        width: size.width,
        height: size.height,
        p0: Offset.zero + topLeftOffset,
        p1: Offset(size.width, 0) + topRightOffset,
        p2: Offset(size.width, size.height) + bottomRightOffset,
        p3: Offset(0, size.height) + bottomLeftOffset,
      );
      canvas.save();
      canvas.transform(matrix.storage);
    }

    content.draw(canvas, size, false);

    if (hasPerspectiveDistortion) {
      canvas.restore();
    }
    if (flipX || flipY) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StickerPainter oldDelegate) => true;
}
