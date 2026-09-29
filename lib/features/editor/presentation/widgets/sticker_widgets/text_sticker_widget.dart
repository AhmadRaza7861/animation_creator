import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/font_presets.dart';

class ActiveTextSticker {
  ActiveTextSticker({
    required this.id,
    required this.text,
    required this.color,
    required this.fontSize,
    this.offset = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isBold = true,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = TextAlign.left,
    this.opacity = 1.0,
    this.fontFamily,
    this.flipX = false,
  });

  final String id;
  String text;
  Color color;
  double fontSize;
  Offset offset;
  double scale;
  double rotation;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  TextAlign textAlign;
  double opacity;
  String? fontFamily;
  bool flipX;

  void resetAll() {
    scale = 1.0;
    rotation = 0.0;
    flipX = false;
  }
}

class TextStickerWidget extends StatefulWidget {
  const TextStickerWidget({
    super.key,
    required this.data,
    required this.onUpdate,
    required this.onDelete,
    required this.onConfirm,
    this.onUpdateEnd,
  });

  final ActiveTextSticker data;
  final Function(Offset, double, double) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final VoidCallback? onUpdateEnd;

  @override
  State<TextStickerWidget> createState() => _TextStickerWidgetState();
}

class _TextStickerWidgetState extends State<TextStickerWidget> {
  late Offset _offset;
  late double _scale;
  late double _rotation;
  late bool _flipX;

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
  }

  @override
  void didUpdateWidget(covariant TextStickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _offset = widget.data.offset;
      _scale = widget.data.scale;
      _rotation = widget.data.rotation;
      _flipX = widget.data.flipX;
    });
  }

  Size _measureText(String text, TextStyle style, TextAlign textAlign) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout();
    // Provide generous padding so text never wraps or clips
    return Size(
      (tp.width + 32).ceilToDouble(),
      (tp.height + 16).ceilToDouble(),
    );
  }

  // Corner resize node (Figma/Apple Freeform style circular handle with App Primary Theme)
  Widget _buildCornerHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
    required double invS,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: invS,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 36,
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
      ),
    );
  }

  // Horizontal side pill handle (Top & Bottom midpoints)
  Widget _buildHorizontalSideHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
    required double invS,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: invS,
          alignment: Alignment.center,
          child: Container(
            width: 32,
            height: 32,
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
      ),
    );
  }

  // Vertical side pill handle (Left & Right midpoints)
  Widget _buildVerticalSideHandle({
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
    required double invS,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: invS,
          alignment: Alignment.center,
          child: Container(
            width: 32,
            height: 32,
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
      ),
    );
  }

  // Top rotate handle (Pro styling with hairline stem & circular rotation badge)
  Widget _buildRotateHandle({required double invS}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onRotateStart,
      onPanUpdate: _onRotateUpdate,
      onPanEnd: (details) => widget.onUpdateEnd?.call(),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: invS,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorConstants.primary, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rotate_right_rounded,
                    size: 16,
                    color: ColorConstants.primary,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 14,
                  color: ColorConstants.primary,
                ),
              ],
            ),
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
    final textStyle = getFontPresetByName(widget.data.fontFamily).getTextStyle(
      color: widget.data.color,
      fontSize: widget.data.fontSize,
      opacity: widget.data.opacity,
      forceBold: widget.data.isBold,
      forceItalic: widget.data.isItalic,
      forceUnderline: widget.data.isUnderline,
    );
    final Size textSize = _measureText(widget.data.text, textStyle, widget.data.textAlign);
    final double w = textSize.width;
    final double h = textSize.height;
    final double scaleSafe = _scale <= 0.001 ? 1.0 : _scale;
    final double padV = (64.0 / scaleSafe) + 24.0;
    final double padH = (44.0 / scaleSafe) + 24.0;
    final double totalWidth = w + padH * 2;
    final double totalHeight = h + padV * 2;
    final double contentLeft = padH;
    final double contentTop = padV;

    final double scaledW = w * scaleSafe;
    final double scaledH = h * scaleSafe;
    final bool showHorizontalMidpoints = scaledW >= 56.0;
    final bool showVerticalMidpoints = scaledH >= 56.0;

    final double invS = 1.0 / scaleSafe;
    final double cornerTouchSize = 36.0 * invS;
    final double halfCorner = cornerTouchSize / 2;
    final double sideTouchSize = 32.0 * invS;
    final double halfSide = sideTouchSize / 2;
    final double rotateTouchW = 44.0 * invS;
    final double rotateTouchH = 44.0 * invS;

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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      alignment: Alignment.center,
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
                        child: Text(
                          widget.data.text,
                          style: textStyle,
                          textAlign: widget.data.textAlign,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Side Midpoint Pill Handles (hidden if dimensions too narrow)
                if (showHorizontalMidpoints) ...[
                  Positioned(
                    left: contentLeft + w / 2 - halfSide,
                    top: contentTop - halfSide,
                    width: sideTouchSize,
                    height: sideTouchSize,
                    child: _buildHorizontalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                      invS: invS,
                    ),
                  ),
                  Positioned(
                    left: contentLeft + w / 2 - halfSide,
                    top: contentTop + h - halfSide,
                    width: sideTouchSize,
                    height: sideTouchSize,
                    child: _buildHorizontalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                      invS: invS,
                    ),
                  ),
                ],
                if (showVerticalMidpoints) ...[
                  Positioned(
                    left: contentLeft - halfSide,
                    top: contentTop + h / 2 - halfSide,
                    width: sideTouchSize,
                    height: sideTouchSize,
                    child: _buildVerticalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                      invS: invS,
                    ),
                  ),
                  Positioned(
                    left: contentLeft + w - halfSide,
                    top: contentTop + h / 2 - halfSide,
                    width: sideTouchSize,
                    height: sideTouchSize,
                    child: _buildVerticalSideHandle(
                      onPanStart: _onScaleHandleStart,
                      onPanUpdate: _onScaleHandleUpdate,
                      onPanEnd: (_) => widget.onUpdateEnd?.call(),
                      invS: invS,
                    ),
                  ),
                ],

                // 3. 4 Corner Resize Nodes
                Positioned(
                  left: contentLeft - halfCorner,
                  top: contentTop - halfCorner,
                  width: cornerTouchSize,
                  height: cornerTouchSize,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    invS: invS,
                  ),
                ),
                Positioned(
                  left: contentLeft + w - halfCorner,
                  top: contentTop - halfCorner,
                  width: cornerTouchSize,
                  height: cornerTouchSize,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    invS: invS,
                  ),
                ),
                Positioned(
                  left: contentLeft - halfCorner,
                  top: contentTop + h - halfCorner,
                  width: cornerTouchSize,
                  height: cornerTouchSize,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    invS: invS,
                  ),
                ),
                Positioned(
                  left: contentLeft + w - halfCorner,
                  top: contentTop + h - halfCorner,
                  width: cornerTouchSize,
                  height: cornerTouchSize,
                  child: _buildCornerHandle(
                    onPanStart: _onScaleHandleStart,
                    onPanUpdate: _onScaleHandleUpdate,
                    onPanEnd: (_) => widget.onUpdateEnd?.call(),
                    invS: invS,
                  ),
                ),

                // 4. Rotate Handle at Top (Always positioned cleanly above the top edge)
                Positioned(
                  left: contentLeft + (w - rotateTouchW) / 2,
                  top: contentTop - rotateTouchH,
                  width: rotateTouchW,
                  height: rotateTouchH,
                  child: _buildRotateHandle(invS: invS),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
