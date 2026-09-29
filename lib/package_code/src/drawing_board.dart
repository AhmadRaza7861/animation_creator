import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'drawing_controller.dart';

import '../paint_contents.dart';
import 'helper/ex_value_builder.dart';
import 'helper/get_size.dart';
import 'painter.dart';
import 'ruler/ruler_overlay.dart';
import '../../features/editor/presentation/widgets/grid_overlay.dart';

/// 画板组件
///
/// 提供交互式绘图功能的核心Widget，支持多种绘制内容（线条、形状等）
/// 内置缩放、旋转、平移等交互功能，支持多指手势画布变换与单指安全绘制
///
/// Drawing Board Widget
///
/// A core widget that provides interactive drawing functionality, supporting various
/// drawing content (lines, shapes, etc.). Built-in zoom, rotation, pan multi-touch interactions
/// with strict single-finger drawing safety and palm rejection.
class DrawingBoard extends StatefulWidget {
  const DrawingBoard({
    super.key,
    required this.background,
    required this.controller,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.clipBehavior = Clip.antiAlias,
    this.boardClipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boardBoundaryMargin,
    this.boardConstrained = false,
    this.maxScale = 20,
    this.minScale = 0.2,
    this.boardPanEnabled = true,
    this.boardScaleEnabled = true,
    this.boardRotateEnabled = true,
    this.boardScaleFactor = 200.0,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.transformationController,
    this.alignment = Alignment.center,
    this.enablePalmRejection = false,
    this.foreground,
    this.isDrawingEnabled = true,
    this.isGridEnabled = false,
    this.gridOpacity = 0.25,
    this.gridVerticalSpacing = 80.0,
    this.gridHorizontalSpacing = 80.0,
    this.isOnionEnabled = false,
    this.onionColorMode = false,
    this.onionLoop = false,
    this.onionBefore = 1,
    this.onionAfter = 0,
    this.allControllers,
    this.currentIndex = 0,
  });

  /// 画板背景控件
  final Widget background;

  /// 画板前景控件 (例如用于文字贴纸)
  final Widget? foreground;

  /// 画板控制器
  final DrawingController controller;

  /// 手指按下回调
  final void Function(PointerDownEvent pde)? onPointerDown;

  /// 手指移动回调
  final void Function(PointerMoveEvent pme)? onPointerMove;

  /// 手指抬起回调
  final void Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 画板容器的裁剪方式
  final Clip boardClipBehavior;

  /// 画板平移轴向限制
  final PanAxis panAxis;

  /// 画板边界边距
  final EdgeInsets? boardBoundaryMargin;

  /// 是否限制画板尺寸
  final bool boardConstrained;

  /// 最大缩放比例
  final double maxScale;

  /// 最小缩放比例
  final double minScale;

  /// 缩放交互结束回调
  final void Function(ScaleEndDetails)? onInteractionEnd;

  /// 缩放交互开始回调
  final void Function(ScaleStartDetails)? onInteractionStart;

  /// 缩放交互更新回调
  final void Function(ScaleUpdateDetails)? onInteractionUpdate;

  /// 是否启用画板平移
  final bool boardPanEnabled;

  /// 是否启用画板缩放
  final bool boardScaleEnabled;

  /// 是否启用画板旋转
  final bool boardRotateEnabled;

  /// 画板缩放因子
  final double boardScaleFactor;

  /// 变换控制器
  final TransformationController? transformationController;

  /// 画板对齐方式
  final AlignmentGeometry alignment;

  /// 启用手掌拒绝功能
  final bool enablePalmRejection;

  /// 是否允许绘制
  final bool isDrawingEnabled;

  final bool isGridEnabled;
  final double gridOpacity;
  final double gridVerticalSpacing;
  final double gridHorizontalSpacing;

  final bool isOnionEnabled;
  final bool onionColorMode;
  final bool onionLoop;
  final int onionBefore;
  final int onionAfter;
  final List<DrawingController>? allControllers;
  final int currentIndex;

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();

  /// 构建默认操作栏，包含笔刷粗细调节、撤销、重做、旋转、清空等功能
  static Widget buildDefaultActions(DrawingController controller) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          builder: (BuildContext context, DrawConfig dc, Widget? child) {
            return Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 160,
                  child: Slider(
                    value: dc.strokeWidth,
                    max: 50,
                    min: 1,
                    onChanged: (double v) =>
                        controller.setStyle(strokeWidth: v),
                  ),
                ),
                if (dc.contentType == BlurContent || dc.contentType == SmudgeContent)
                  SizedBox(
                    height: 24,
                    width: 100,
                    child: Slider(
                      value: dc.strength,
                      max: 1.0,
                      min: 0.1,
                      onChanged: (double v) =>
                          controller.setStyle(strength: v),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.arrow_turn_up_left,
                    color: controller.canUndo() ? null : Colors.grey,
                  ),
                  onPressed: () => controller.undo(),
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.arrow_turn_up_right,
                    color: controller.canRedo() ? null : Colors.grey,
                  ),
                  onPressed: () => controller.redo(),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.rotate_right),
                  onPressed: () => controller.turn(),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () => controller.clear(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawingBoardState extends State<DrawingBoard> {
  late TransformationController _internalTransformController;
  final Map<int, Offset> _activePointers = <int, Offset>{};
  Map<int, Offset> _lastPointers = <int, Offset>{};
  bool _isNavigating = false;

  TransformationController get _effectiveTransformController =>
      widget.transformationController ?? _internalTransformController;

  @override
  void initState() {
    super.initState();
    _internalTransformController = TransformationController();
  }

  @override
  void dispose() {
    _internalTransformController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    widget.controller.addFingerCount(event.localPosition);

    if (_activePointers.length >= 2) {
      _isNavigating = true;
      widget.controller.isNavigating = true;
      if (widget.controller.hasPaintingContent) {
        widget.controller.cancelDraw();
      }
      _lastPointers = Map<int, Offset>.from(_activePointers);
      widget.onInteractionStart?.call(ScaleStartDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
        pointerCount: _activePointers.length,
      ));
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.localPosition;

    if (_isNavigating && _activePointers.length >= 2) {
      _handleMultiTouchTransform();
      widget.onInteractionUpdate?.call(ScaleUpdateDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
        pointerCount: _activePointers.length,
      ));
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    widget.controller.reduceFingerCount(event.localPosition);

    if (_activePointers.isEmpty) {
      _isNavigating = false;
      widget.controller.isNavigating = false;
      widget.controller.resetFingerCount();
      _lastPointers.clear();
      widget.onInteractionEnd?.call(ScaleEndDetails(pointerCount: 0));
    } else {
      _lastPointers = Map<int, Offset>.from(_activePointers);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    widget.controller.reduceFingerCount(event.localPosition);

    if (_activePointers.isEmpty) {
      _isNavigating = false;
      widget.controller.isNavigating = false;
      widget.controller.resetFingerCount();
      _lastPointers.clear();
      widget.onInteractionEnd?.call(ScaleEndDetails(pointerCount: 0));
    } else {
      _lastPointers = Map<int, Offset>.from(_activePointers);
    }
  }

  void _handleMultiTouchTransform() {
    if (!widget.boardPanEnabled && !widget.boardScaleEnabled && !widget.boardRotateEnabled) {
      _lastPointers = Map<int, Offset>.from(_activePointers);
      return;
    }

    if (_activePointers.length < 2 || _lastPointers.length < 2) {
      _lastPointers = Map<int, Offset>.from(_activePointers);
      return;
    }

    final List<int> keys = _activePointers.keys.toList();
    final Offset p1Curr = _activePointers[keys[0]]!;
    final Offset p2Curr = _activePointers[keys[1]]!;

    final Offset p1Prev = _lastPointers[keys[0]] ?? p1Curr;
    final Offset p2Prev = _lastPointers[keys[1]] ?? p2Curr;

    final Offset centerCurr = (p1Curr + p2Curr) / 2.0;
    final Offset centerPrev = (p1Prev + p2Prev) / 2.0;

    final double distCurr = (p2Curr - p1Curr).distance;
    final double distPrev = (p2Prev - p1Prev).distance;

    double scaleDelta = 1.0;
    if (widget.boardScaleEnabled && distPrev > 2.0 && distCurr > 2.0) {
      scaleDelta = distCurr / distPrev;
    }

    double rotDelta = 0.0;
    if (widget.boardRotateEnabled) {
      final double angleCurr = math.atan2(p2Curr.dy - p1Curr.dy, p2Curr.dx - p1Curr.dx);
      final double anglePrev = math.atan2(p2Prev.dy - p1Prev.dy, p2Prev.dx - p1Prev.dx);
      rotDelta = angleCurr - anglePrev;
      while (rotDelta > math.pi) rotDelta -= 2 * math.pi;
      while (rotDelta < -math.pi) rotDelta += 2 * math.pi;
    }

    final Matrix4 currentMatrix = _effectiveTransformController.value;

    final double curScale = math.sqrt(
      currentMatrix.storage[0] * currentMatrix.storage[0] +
      currentMatrix.storage[1] * currentMatrix.storage[1],
    );

    if (curScale * scaleDelta < widget.minScale) {
      scaleDelta = widget.minScale / (curScale > 0 ? curScale : 1.0);
    } else if (curScale * scaleDelta > widget.maxScale) {
      scaleDelta = widget.maxScale / (curScale > 0 ? curScale : 1.0);
    }

    final Matrix4 delta = Matrix4.identity()
      ..translate(centerCurr.dx, centerCurr.dy)
      ..rotateZ(rotDelta)
      ..scale(scaleDelta, scaleDelta, 1.0)
      ..translate(-centerPrev.dx, -centerPrev.dy);

    final Matrix4 newMatrix = delta * currentMatrix;
    _effectiveTransformController.value = newMatrix;

    _lastPointers = Map<int, Offset>.from(_activePointers);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ClipRect(
        clipBehavior: widget.boardClipBehavior,
        child: AnimatedBuilder(
          animation: _effectiveTransformController,
          builder: (BuildContext context, Widget? child) {
            return Transform(
              transform: _effectiveTransformController.value,
              child: child,
            );
          },
          child: Align(
            alignment: widget.alignment,
            child: _buildBoard,
          ),
        ),
      ),
    );
  }

  /// 构建画板主体，包含旋转和尺寸处理
  Widget get _buildBoard {
    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) =>
          p.angle != n.angle || p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        Widget c = child!;

        if (dc.size != null) {
          final bool isHorizontal = dc.angle.toDouble() % 2 == 0;
          final double max = dc.size!.longestSide;

          if (!isHorizontal) {
            c = SizedBox(width: max, height: max, child: c);
          }
        }

        return Transform.rotate(angle: dc.angle * math.pi / 2, child: c);
      },
      child: Center(
        child: RepaintBoundary(
          key: widget.controller.painterKey,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              _buildImage,
              RepaintBoundary(
                key: widget.controller.drawingLayerKey,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _buildPainter,
                    if (widget.foreground != null) _buildForeground,
                  ],
                ),
              ),
              if (widget.isGridEnabled)
                Positioned.fill(
                  child: GridOverlay(
                    opacity: widget.gridOpacity,
                    verticalSpacing: widget.gridVerticalSpacing,
                    horizontalSpacing: widget.gridHorizontalSpacing,
                  ),
                ),
              Positioned.fill(child: RulerOverlay(controller: widget.controller)),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建前景层
  Widget get _buildForeground {
    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: widget.foreground,
    );
  }

  /// 构建背景层，并监听尺寸变化
  Widget get _buildImage => GetSize(
    onChange: (Size? size) => widget.controller.setBoardSize(size),
    child: widget.background,
  );

  /// 构建绘制层，包含实际的绘图canvas
  Widget get _buildPainter {
    return ExValueBuilder<DrawConfig>(
      valueListenable: widget.controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: Painter(
        drawingController: widget.controller,
        onPointerDown: widget.onPointerDown,
        onPointerMove: widget.onPointerMove,
        onPointerUp: widget.onPointerUp,
        enablePalmRejection: widget.enablePalmRejection,
        isDrawingEnabled: widget.isDrawingEnabled,
        isOnionEnabled: widget.isOnionEnabled,
        onionColorMode: widget.onionColorMode,
        onionLoop: widget.onionLoop,
        onionBefore: widget.onionBefore,
        onionAfter: widget.onionAfter,
        allControllers: widget.allControllers,
        currentIndex: widget.currentIndex,
      ),
    );
  }
}
