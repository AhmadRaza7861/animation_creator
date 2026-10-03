import 'dart:math';
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
        const SnackBar(content: Text('Current layer is locked.')),
      );
      return;
    }
    final text = await AppDialogs.showTextStickerDialog(
      context,
      title: 'Add Text Sticker',
    );
    if (text != null && text.trim().isNotEmpty) {
      controller.addTextSticker(text.trim(), position);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(editorControllerProvider(projectId));
    final activeSticker = controller.activeSticker;

    Widget buildBoard(BoxConstraints c) {
      return GestureDetector(
        onTapDown: (controller.isTextToolSelected && activeSticker == null)
            ? (details) {
                final renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPosition = details.localPosition;
                  final Matrix4 matrix = transformationController.value;
                  final Matrix4 inverse = Matrix4.inverted(matrix);
                  final Offset canvasPoint = MatrixUtils.transformPoint(inverse, localPosition);
                  _showAddTextStickerDialogAtPosition(context, controller, canvasPoint);
                }
              }
            : null,
        child: Stack(
          children: [
            DrawingBoard(
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
                if (controller.drawingController.isCurrentLayerLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current layer is locked.')),
                  );
                  return;
                }
              },
              boardPanEnabled: true,
              boardScaleEnabled: true,
              boardRotateEnabled: true,
              isDrawingEnabled: activeSticker == null && !controller.isTextToolSelected && !controller.drawingController.isCurrentLayerLocked,
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

                  return Container(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    color: PatternBackgroundHelper.getBaseColor(bg.pattern, bg.color),
                    child: Stack(
                      children: [
                        if (guideWidget != null) guideWidget,
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
                  );
                },
              ),
              foreground: activeSticker == null
                  ? null
                  : AnimatedBuilder(
                      animation: controller.drawingController,
                      builder: (context, child) {
                        final isNavigating = controller.drawingController.isNavigating ||
                            controller.drawingController.pointerCount >= 2 ||
                            controller.drawingController.isZooming ||
                            controller.drawingController.isPanning;
                        return IgnorePointer(
                          ignoring: isNavigating,
                          child: child,
                        );
                      },
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
                                controller.stampActiveSticker();
                              },
                            ),
                          ),
                          if (activeSticker is ActiveTextSticker)
                            TextStickerWidget(
                              key: ValueKey((activeSticker).id),
                              data: activeSticker,
                              onUpdate: (offset, scale, rotation) {
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
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: AspectRatio(
            aspectRatio: controller.aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints aspectConstraints) {
                    return buildBoard(aspectConstraints);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef CanvasPatternPainter = PreviewPatternPainter;

