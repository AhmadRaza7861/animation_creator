import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../package_code/src/drawing_board.dart';
import '../../../../../package_code/src/drawing_controller.dart';
import '../../../../../package_code/src/ruler/ruler_config.dart';
import '../controllers/editor_providers.dart';
import '../controllers/editor_controller.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';
import '../widgets/sticker_widgets/shape_sticker_widget.dart';
import '../widgets/sticker_widgets/straight_line_sticker_widget.dart';
import '../widgets/sticker_widgets/freehand_line_sticker_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';

class CanvasArea extends ConsumerWidget {
  final String? projectId;
  final TransformationController transformationController;

  const CanvasArea({
    super.key,
    required this.projectId,
    required this.transformationController,
  });

  void _showAddTextStickerDialogAtPosition(
    BuildContext context,
    EditorController controller,
    Offset position,
  ) async {
    if (controller.drawingController.isCurrentLayerLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('currentLayerLocked'))),
      );
      return;
    }
    final text = await AppDialogs.showTextStickerDialog(context);
    if (text != null && text.trim().isNotEmpty) {
      controller.addTextSticker(text.trim(), position);
    } else {
      controller.isTextToolSelected = false;
      controller.activeCategory = 'Brush';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(editorControllerProvider(projectId));
    final activeSticker = controller.activeSticker;

    Widget buildBoard(Size canvasSize, Size viewportSize) {
      return GestureDetector(
        onTapDown: (controller.isTextToolSelected && activeSticker == null)
            ? (details) {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPosition = details.localPosition;
                  final Matrix4 matrix = transformationController.value;
                  final Matrix4 inverse = Matrix4.inverted(matrix);
                  final Offset transformedPoint = MatrixUtils.transformPoint(inverse, localPosition);
                  final Offset origin = Offset(
                    (viewportSize.width - canvasSize.width) / 2,
                    (viewportSize.height - canvasSize.height) / 2,
                  );
                  final Offset canvasPoint = transformedPoint - origin;
                  if (canvasPoint.dx >= 0 &&
                      canvasPoint.dx <= canvasSize.width &&
                      canvasPoint.dy >= 0 &&
                      canvasPoint.dy <= canvasSize.height) {
                    _showAddTextStickerDialogAtPosition(context, controller, canvasPoint);
                  }
                }
              }
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DrawingBoard(
              enablePalmRejection: true,
              transformationController: transformationController,
              alignment: Alignment.center,
              controller: controller.drawingController,
              isGridEnabled: controller.isGridEnabled,
              gridOpacity: controller.gridOpacity,
              gridVerticalSpacing: controller.gridVerticalSpacing,
              gridHorizontalSpacing: controller.gridHorizontalSpacing,
              isOnionEnabled: controller.isOnionEnabled,
              onionColorMode: controller.onionColorMode,
              onionLoop: controller.onionLoop,
              onionBefore: controller.onionBefore,
              onionAfter: controller.onionAfter,
              allControllers: controller.canvases,
              currentIndex: controller.currentIndex,
              onPointerDown: (e) {
                if (controller.activeCategory == 'Select' && activeSticker == null) {
                  controller.onSelectPointerDown(e.localPosition);
                  return;
                }
                if (controller.drawingController.isCurrentLayerLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('layerLocked'))),
                  );
                  return;
                }
              },
              onPointerMove: (e) {
                if (controller.activeCategory == 'Select' && activeSticker == null) {
                  controller.onSelectPointerMove(e.localPosition);
                }
              },
              onPointerUp: (e) {
                if (controller.activeCategory == 'Select' && activeSticker == null) {
                  controller.onSelectPointerUp(e.localPosition, context);
                }
              },
              boardPanEnabled: activeSticker is! ActiveShapeSticker &&
                  activeSticker is! ActiveTextSticker,
              boardScaleEnabled: activeSticker is! ActiveShapeSticker &&
                  activeSticker is! ActiveTextSticker,
              boardRotateEnabled: activeSticker is! ActiveShapeSticker &&
                  activeSticker is! ActiveTextSticker,
              isDrawingEnabled: activeSticker == null &&
                  !controller.isTextToolSelected &&
                  controller.activeCategory != 'Select' &&
                  !controller.drawingController.isCurrentLayerLocked,
              background: ValueListenableBuilder<DrawConfig>(
                valueListenable: controller.drawingController.drawConfig,
                builder: (context, config, child) {
                  Widget? guideWidget;
                  if (controller.templateMode == 'drawAccordingTemplate' &&
                      controller.currentIndex < controller.templateFrameAssets.length) {
                    final String assetPath = controller.templateFrameAssets[controller.currentIndex];
                    guideWidget = Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }

                  final bg = controller.globalBackground;

                  return SizedBox(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: AspectRatio(
                      aspectRatio: controller.aspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PatternBackgroundHelper.getBaseColor(bg.pattern, bg.color),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              ?guideWidget,
                              if (bg.image != null)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: bg.imageOpacity,
                                    child: RawImage(
                                      image: bg.image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (bg.pattern != null && bg.pattern != 'none')
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: PreviewPatternPainter(
                                      bg.pattern!,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              foreground: (activeSticker == null && controller.selectMarqueeRect == null)
                  ? null
                  : (activeSticker == null && controller.selectMarqueeRect != null)
                      ? CustomPaint(
                          size: Size.infinite,
                          painter: _SelectMarqueePainter(controller.selectMarqueeRect!),
                        )
                      : AnimatedBuilder(
                      animation: controller.drawingController,
                      builder: (context, child) {
                        final isTransformableSticker =
                            activeSticker is ActiveShapeSticker ||
                            activeSticker is ActiveTextSticker;
                        final isNavigating = !isTransformableSticker &&
                            (controller.drawingController.isNavigating ||
                                controller.drawingController.pointerCount >= 2 ||
                                controller.drawingController.isZooming ||
                                controller.drawingController.isPanning);
                        return IgnorePointer(
                          ignoring: isNavigating,
                          child: child,
                        );
                      },
                      child: _StickerMultiTouchRegion(
                        controller: controller,
                        canvasSize: controller.drawingController.drawConfig.value.size ?? canvasSize,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  final createdAt = controller.activeStickerCreatedAt;
                                  if (createdAt != null &&
                                      DateTime.now().difference(createdAt).inMilliseconds < 450) {
                                    return;
                                  }
                                  if (_StickerMultiTouchRegion.wasRecentlyMultiTouch) {
                                    return;
                                  }
                                  controller.stampActiveSticker();
                                },
                              ),
                            ),
                            if (activeSticker is ActiveTextSticker)
                              TextStickerWidget(
                                key: ValueKey((activeSticker).id),
                                data: activeSticker,
                                canvasSize: controller.drawingController.drawConfig.value.size,
                                onUpdate: (offset, scale, rotation) {
                                  if (controller.drawingController.pointerCount >= 2) return;
                                  (activeSticker).offset = offset;
                                  (activeSticker).scale = scale;
                                  (activeSticker).rotation = rotation;
                                  controller.updateSnapshot();
                                },
                                onUpdateEnd: () => controller.recordActiveStickerState(),
                                onDelete: () {
                                  controller.activeSticker = null;
                                  controller.updateSnapshot();
                                },
                                onConfirm: () {
                                  controller.stampActiveSticker();
                                },
                              ),
                            if (activeSticker is ActiveFreehandLineSticker)
                              FreehandLineStickerWidget(
                                key: ValueKey((activeSticker).id),
                                data: activeSticker,
                                onSnap: (raw, anchor) {
                                  if (controller.showRulerMenu &&
                                      controller.drawingController.rulerConfig.value.type != RulerType.none) {
                                    return controller.drawingController.rulerConfig.value.projectPoint(raw, anchor);
                                  }
                                  return raw;
                                },
                                onUpdate: () {
                                  controller.updateSnapshot();
                                },
                                onUpdateEnd: () => controller.recordActiveStickerState(),
                                onDelete: () {
                                  controller.activeSticker = null;
                                  controller.updateSnapshot();
                                },
                                onConfirm: () {
                                  controller.stampActiveSticker();
                                },
                              ),
                            if (activeSticker is ActiveShapeSticker)
                              ShapeStickerWidget(
                                key: ValueKey((activeSticker).id),
                                data: activeSticker,
                                canvasSize: controller.drawingController.drawConfig.value.size,
                                onUpdate: (offset, scale, rotation) {
                                  if (controller.drawingController.pointerCount >= 2) return;
                                  (activeSticker).offset = offset;
                                  (activeSticker).scale = scale;
                                  (activeSticker).rotation = rotation;
                                  controller.updateSnapshot();
                                },
                                onUpdateEnd: () => controller.recordActiveStickerState(),
                                onDelete: () {
                                  controller.activeSticker = null;
                                  controller.updateSnapshot();
                                },
                                onConfirm: () {
                                  controller.stampActiveSticker();
                                },
                              ),
                            if (activeSticker is ActiveStraightLineSticker)
                              StraightLineStickerWidget(
                                key: ValueKey((activeSticker).id),
                                data: activeSticker,
                                onSnap: (raw, anchor) {
                                  if (controller.showRulerMenu &&
                                      controller.drawingController.rulerConfig.value.type != RulerType.none) {
                                    return controller.drawingController.rulerConfig.value.projectPoint(raw, anchor);
                                  }
                                  return raw;
                                },
                                onUpdate: (start, end) {
                                  (activeSticker).startPoint = start;
                                  (activeSticker).endPoint = end;
                                  controller.updateSnapshot();
                                },
                                onUpdateEnd: () => controller.recordActiveStickerState(),
                                onDelete: () {
                                  controller.activeSticker = null;
                                  controller.updateSnapshot();
                                },
                                onConfirm: () {
                                  controller.stampActiveSticker();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (activeSticker != null &&
                !controller.hasShownStickerHint &&
                controller.activeCategory == 'Brush')
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Drag handles to edit • Tap to stamp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              controller.markStickerHintShown();
                              controller.stampActiveSticker();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ColorConstants.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 13),
                                  SizedBox(width: 3),
                                  Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (controller.activeCategory == 'Select' && activeSticker == null)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            AssetConstants.select_icon,
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('selectToolHint'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final double maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
        final double ratio = controller.aspectRatio;

        double canvasWidth;
        double canvasHeight;

        if (maxW / maxH > ratio) {
          canvasHeight = maxH;
          canvasWidth = maxH * ratio;
        } else {
          canvasWidth = maxW;
          canvasHeight = maxW / ratio;
        }

        final Size currentCanvasSize = Size(canvasWidth, canvasHeight);
        controller.checkAndScaleLegacyCanvasSize(currentCanvasSize);

        return SizedBox(
          width: maxW,
          height: maxH,
          child: buildBoard(
            currentCanvasSize,
            Size(maxW, maxH),
          ),
        );
      },
    );
  }
}

typedef CanvasPatternPainter = PreviewPatternPainter;

class _SelectMarqueePainter extends CustomPainter {
  final Rect rect;

  _SelectMarqueePainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fillPaint);

    final path = Path()..addRect(rect);
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final Path extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, borderPaint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelectMarqueePainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}

class _StickerMultiTouchRegion extends StatefulWidget {
  final EditorController controller;
  final Size canvasSize;
  final Widget child;

  const _StickerMultiTouchRegion({
    required this.controller,
    required this.canvasSize,
    required this.child,
  });

  static DateTime? _lastMultiTouchAt;

  static bool get wasRecentlyMultiTouch {
    final last = _lastMultiTouchAt;
    if (last == null) return false;
    return DateTime.now().difference(last).inMilliseconds < 350;
  }

  @override
  State<_StickerMultiTouchRegion> createState() => _StickerMultiTouchRegionState();
}

class _StickerMultiTouchRegionState extends State<_StickerMultiTouchRegion> {
  final Map<int, Offset> _activePointers = <int, Offset>{};
  Map<int, Offset> _lastPointers = <int, Offset>{};
  bool _hadMultiTouch = false;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length >= 2) {
      _hadMultiTouch = true;
      _StickerMultiTouchRegion._lastMultiTouchAt = DateTime.now();
      _lastPointers = Map<int, Offset>.from(_activePointers);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length < 2) {
      _lastPointers = Map<int, Offset>.from(_activePointers);
      return;
    }

    _hadMultiTouch = true;
    _StickerMultiTouchRegion._lastMultiTouchAt = DateTime.now();

    if (_lastPointers.length < 2) {
      _lastPointers = Map<int, Offset>.from(_activePointers);
      return;
    }

    final sticker = widget.controller.activeSticker;
    if (sticker is! ActiveShapeSticker && sticker is! ActiveTextSticker) {
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
    final Offset panDelta = centerCurr - centerPrev;

    final double distCurr = (p2Curr - p1Curr).distance;
    final double distPrev = (p2Prev - p1Prev).distance;
    double scaleDelta = 1.0;
    if (distPrev > 4.0 && distCurr > 4.0) {
      scaleDelta = distCurr / distPrev;
    }

    final double angleCurr = math.atan2(p2Curr.dy - p1Curr.dy, p2Curr.dx - p1Curr.dx);
    final double anglePrev = math.atan2(p2Prev.dy - p1Prev.dy, p2Prev.dx - p1Prev.dx);
    double rotDelta = angleCurr - anglePrev;
    while (rotDelta > math.pi) {
      rotDelta -= 2 * math.pi;
    }
    while (rotDelta < -math.pi) {
      rotDelta += 2 * math.pi;
    }

    if (sticker is ActiveShapeSticker) {
      Offset newOffset = sticker.offset + panDelta;
      final cs = widget.canvasSize;
      if (cs.width > 0 && cs.height > 0) {
        final double w = sticker.size.width;
        final double h = sticker.size.height;
        newOffset = Offset(
          newOffset.dx.clamp(-w * 0.5, cs.width + w * 0.5),
          newOffset.dy.clamp(-h * 0.5, cs.height + h * 0.5),
        );
      }
      sticker.offset = newOffset;
      if (sticker.transformMode != StickerTransformMode.perspective) {
        sticker.scale = (sticker.scale * scaleDelta).clamp(0.1, 10.0);
        sticker.rotation += rotDelta;
      }
      widget.controller.updateSnapshot();
    } else if (sticker is ActiveTextSticker) {
      sticker.offset += panDelta;
      sticker.scale = (sticker.scale * scaleDelta).clamp(0.1, 10.0);
      sticker.rotation += rotDelta;
      widget.controller.updateSnapshot();
    }

    _lastPointers = Map<int, Offset>.from(_activePointers);
  }

  void _onPointerUpOrCancel(int pointer) {
    _activePointers.remove(pointer);
    _lastPointers = Map<int, Offset>.from(_activePointers);
    if (_hadMultiTouch) {
      _StickerMultiTouchRegion._lastMultiTouchAt = DateTime.now();
      if (_activePointers.length < 2) {
        _hadMultiTouch = false;
        widget.controller.recordActiveStickerState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: (e) => _onPointerUpOrCancel(e.pointer),
      onPointerCancel: (e) => _onPointerUpOrCancel(e.pointer),
      child: widget.child,
    );
  }
}
