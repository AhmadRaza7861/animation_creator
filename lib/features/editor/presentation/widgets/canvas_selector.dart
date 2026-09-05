import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/editor_controller.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';

class CanvasSelector extends StatefulWidget {
  final List<ui.Image?> thumbnails;
  final int currentIndex;
  final Function(int) onSelect;
  final VoidCallback onAdd;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenFrames;
  final VoidCallback onImportVideo;
  final VoidCallback onPlay;
  final void Function(String action, int index) onFrameAction;
  final List<Key> canvasKeys;
  final void Function(int oldIndex, int newIndex) onReorder;
  final CanvasBackground? globalBackground;

  const CanvasSelector({
    super.key,
    required this.thumbnails,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onOpenGallery,
    required this.onOpenFrames,
    required this.onImportVideo,
    required this.onPlay,
    required this.onFrameAction,
    required this.canvasKeys,
    required this.onReorder,
    this.globalBackground,
  });

  @override
  State<CanvasSelector> createState() => _CanvasSelectorState();
}

class _CanvasSelectorState extends State<CanvasSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToCurrentIndex(animate: false);
  }

  @override
  void didUpdateWidget(covariant CanvasSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrentIndex(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentIndex({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      const double itemWidth = 68.0;
      final double targetOffset = widget.currentIndex * itemWidth;
      final double currentOffset = _scrollController.offset;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double viewport = _scrollController.position.viewportDimension;

      if (targetOffset < currentOffset || (targetOffset + itemWidth) > (currentOffset + viewport)) {
        final double centeredOffset = (targetOffset - (viewport / 2) + (itemWidth / 2)).clamp(0.0, maxScroll);
        if (animate) {
          _scrollController.animateTo(
            centeredOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(centeredOffset);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: ColorConstants.border_color,
        border: Border(top: BorderSide(color: ColorConstants.border_color_2, width: 1)),
      ),
      child: Row(
        children: [
          // Layers Button
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.layers_rounded, size: 26, color: ColorConstants.darkText),
                onPressed: widget.onOpenFrames,
                tooltip: 'Layers',
              ),
            ),
          ),
          // Video Import Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.video_library_rounded, size: 24, color: ColorConstants.darkText),
                onPressed: widget.onImportVideo,
                tooltip: 'Import Video',
              ),
            ),
          ),
          // Play Button
          Padding(
            padding: const EdgeInsets.only(left: 2.0, right: 6.0),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 28, color: ColorConstants.darkText),
                onPressed: widget.onPlay,
                tooltip: 'Play Animation',
              ),
            ),
          ),
          // Reorderable Frame Thumbnails list
          Expanded(
            child: ReorderableListView.builder(
              key: const PageStorageKey('timeline_canvas_selector_scroll'),
              scrollController: _scrollController,
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                    return Material(color: Colors.transparent, child: child);
                  },
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: widget.thumbnails.length,
              onReorder: widget.onReorder,
              itemBuilder: (context, index) {
                return ReorderableDelayedDragStartListener(
                  key: widget.canvasKeys[index],
                  index: index,
                  child: _buildThumbnailItem(context, index),
                );
              },
            ),
          ),
          // Dashed Add Frame Button
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: _buildDashedAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedAddButton() {
    return GestureDetector(
      onTap: widget.onAdd,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.grey.shade400,
          strokeWidth: 1.5,
          gap: 4.0,
          radius: 12,
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 24, color: ColorConstants.darkText),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailItem(BuildContext context, int index) {
    final isSelected = index == widget.currentIndex;

    return GestureDetector(
      onTap: () => widget.onSelect(index),
      onLongPress: () => _showFrameActionsSheet(context, index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? ColorConstants.primary : Colors.black.withValues(alpha: 0.08),
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? ColorConstants.primary.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnailBackground(),
                  if (widget.thumbnails[index] != null)
                    RawImage(image: widget.thumbnails[index], fit: BoxFit.contain)
                  else
                    const Center(
                      child: Icon(
                        Icons.palette_outlined,
                        color: Colors.black26,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showFrameActionsSheet(context, index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorConstants.primary
                      : Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFrameActionsSheet(BuildContext context, int index) {
    final bool isOnlyFrame = widget.thumbnails.length <= 1;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with Thumbnail Preview & Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail Preview
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: index == widget.currentIndex
                                  ? ColorConstants.primary
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildThumbnailBackground(),
                                if (widget.thumbnails[index] != null)
                                  RawImage(
                                    image: widget.thumbnails[index],
                                    fit: BoxFit.contain,
                                  )
                                else
                                  const Center(
                                    child: Icon(
                                      Icons.palette_outlined,
                                      color: Colors.black26,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Frame ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstants.darkText,
                                    ),
                                  ),
                                  if (index == widget.currentIndex) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorConstants.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.thumbnails.length} total frames in animation',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ColorConstants.mediumText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Action Grid (Copy, Paste, Duplicate)
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionTile(
                          icon: Icons.copy_rounded,
                          iconColor: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          title: 'Copy',
                          subtitle: 'To clipboard',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('copy', index);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionTile(
                          icon: Icons.paste_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF),
                          title: 'Paste',
                          subtitle: 'From copy',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('paste', index);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionTile(
                          icon: Icons.control_point_duplicate_rounded,
                          iconColor: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFF0FDF4),
                          title: 'Duplicate',
                          subtitle: 'Clone frame',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('duplicate', index);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'TIMELINE INSERTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: ColorConstants.mediumText,
                      ),
                    ),
                  ),

                  // Add Left & Add Right Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildListActionTile(
                          icon: Icons.arrow_back_rounded,
                          iconColor: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFFFBEB),
                          title: 'Add Left',
                          subtitle: 'Insert blank before',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('left', index);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildListActionTile(
                          icon: Icons.arrow_forward_rounded,
                          iconColor: ColorConstants.accent,
                          bgColor: const Color(0xFFFFF7ED),
                          title: 'Add Right',
                          subtitle: 'Insert blank after',
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('right', index);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Delete Frame Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onFrameAction('delete', index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isOnlyFrame ? Colors.grey.shade100 : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOnlyFrame ? Colors.grey.shade200 : const Color(0xFFFEE2E2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOnlyFrame ? Colors.grey.shade200 : const Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: isOnlyFrame ? Colors.grey : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete Frame ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isOnlyFrame ? Colors.grey : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  Text(
                                    isOnlyFrame
                                        ? 'Cannot delete the only remaining frame'
                                        : 'Remove this frame from the animation',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOnlyFrame
                                          ? Colors.grey.shade500
                                          : const Color(0xFF991B1B).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: ColorConstants.mediumText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.darkText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: ColorConstants.mediumText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailBackground() {
    final bg = widget.globalBackground;
    if (bg == null) {
      return Container(color: Colors.white);
    }

    final Color bgColor = bg.pattern == 'blueprint'
        ? const Color(0xFF1E3D59)
        : (bg.pattern == 'graph' ? const Color(0xFFF1F8F6) : bg.color);

    return Container(
      color: bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
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
                painter: PreviewPatternPainter(bg.pattern!),
              ),
            ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    bool draw = true;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = gap;
        final nextDistance = distance + length;
        if (draw) {
          dashedPath.addPath(
            pathMetric.extractPath(distance, nextDistance.clamp(0.0, pathMetric.length)),
            Offset.zero,
          );
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}

class CheckerboardBackground extends StatelessWidget {
  const CheckerboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: CheckerboardPainter());
  }
}

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 8.0;
    final Paint lightPaint = Paint()..color = Colors.grey.shade100;
    final Paint darkPaint = Paint()..color = Colors.grey.shade200;

    for (double i = 0; i < size.width; i += squareSize) {
      for (double j = 0; j < size.height; j += squareSize) {
        final Rect rect = Rect.fromLTWH(i, j, squareSize, squareSize);
        canvas.drawRect(
          rect,
          ((i / squareSize).floor() + (j / squareSize).floor()) % 2 == 0
              ? lightPaint
              : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
