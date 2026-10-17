import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../package_code/src/drawing_controller.dart';
import '../controllers/editor_controller.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';
import '../../../../core/widgets/safe_thumbnail_widget.dart';
import 'fast_scroll_counter_overlay.dart';

class CanvasSelector extends StatefulWidget {
  final double aspectRatio;
  final List<ui.Image?> thumbnails;
  final List<String?>? frameImagePaths;
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
  final int? layerCount;
  final DrawingController? drawingController;
  final VoidCallback? onOpenAudioStudio;
  final int? audioClipCount;
  final void Function(int index)? onRequestThumbnail;
  final bool Function(int index)? frameHasCustomStrokes;
  final int fps;
  final ValueNotifier<FastScrollState>? fastScrollNotifier;

  const CanvasSelector({
    super.key,
    this.aspectRatio = 1.0,
    required this.thumbnails,
    this.frameImagePaths,
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
    this.layerCount,
    this.drawingController,
    this.onOpenAudioStudio,
    this.audioClipCount,
    this.onRequestThumbnail,
    this.frameHasCustomStrokes,
    this.fps = 12,
    this.fastScrollNotifier,
  });

  @override
  State<CanvasSelector> createState() => _CanvasSelectorState();
}

class _CanvasSelectorState extends State<CanvasSelector> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _scrollProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isFastScrollingNotifier = ValueNotifier<bool>(false);

  // Scrubber animation & state
  late final AnimationController _scrubberAnimController;
  late final Animation<double> _scrubberScaleAnim;
  late final Animation<double> _scrubberFadeAnim;
  Timer? _hideScrubberTimer;
  double _dragStartGlobalX = 0.0;
  double _dragStartHandleLeft = 0.0;
  double _currentDragHandleLeft = 0.0;
  bool _isScrubFrameScheduled = false;
  double _pendingScrubOffset = 0.0;
  int _lastHapticIndex = -1;
  double _accumulatedUserScrollDelta = 0.0;
  DateTime? _lastUserDragTime;
  bool _isFastContinuousScrolling = false;
  bool _isUserScrollingTimeline = false;

  DateTime? _lastHapticTime;

  bool get _isDraggingScrubber => _isDraggingNotifier.value;

  void _triggerSelectionHaptic(int targetIndex) {
    if (targetIndex != _lastHapticIndex) {
      _lastHapticIndex = targetIndex;
      final now = DateTime.now();
      if (_lastHapticTime == null || now.difference(_lastHapticTime!).inMilliseconds >= 50) {
        _lastHapticTime = now;
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrubberAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scrubberScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrubberAnimController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _scrubberFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scrubberAnimController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    _scrollToCurrentIndex(animate: false);
  }

  @override
  void didUpdateWidget(covariant CanvasSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.thumbnails.length != widget.thumbnails.length) {
      // Do not fight the user when they are actively scrolling or dragging the timeline
      if (!_isDraggingScrubber && !_isUserScrollingTimeline && !_isFastContinuousScrolling) {
        _scrollToCurrentIndex(animate: true);
      }
    }
  }

  @override
  void dispose() {
    _dismissScrubberAndOverlay(immediate: true);
    _scrollController.dispose();
    _scrubberAnimController.dispose();
    _hideScrubberTimer?.cancel();
    _isDraggingNotifier.dispose();
    _scrollProgressNotifier.dispose();
    _isFastScrollingNotifier.dispose();
    super.dispose();
  }

  void _showScrubber() {
    if (widget.thumbnails.length <= 4) return;
    if (!_scrubberAnimController.isAnimating && _scrubberAnimController.value < 1.0) {
      _scrubberAnimController.forward();
    }
  }

  void _dismissScrubberAndOverlay({bool immediate = true}) {
    _hideScrubberTimer?.cancel();
    _isFastContinuousScrolling = false;
    _isFastScrollingNotifier.value = false;
    if (immediate) {
      if (_scrubberAnimController.status != AnimationStatus.reverse &&
          _scrubberAnimController.status != AnimationStatus.dismissed) {
        _scrubberAnimController.reverse();
      }
      if (widget.fastScrollNotifier?.value.isVisible == true) {
        widget.fastScrollNotifier?.value = widget.fastScrollNotifier!.value.copyWith(
          isVisible: false,
        );
      }
    } else {
      _scheduleHideScrubber();
    }
  }

  void _scheduleHideScrubber() {
    _hideScrubberTimer?.cancel();
    _hideScrubberTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        if (!_isDraggingScrubber) {
          _isFastContinuousScrolling = false;
          _isFastScrollingNotifier.value = false;
          if (_scrubberAnimController.status != AnimationStatus.reverse &&
              _scrubberAnimController.status != AnimationStatus.dismissed) {
            _scrubberAnimController.reverse();
          }
        }
        // Always dismiss the floating counter overlay when timer expires
        if (widget.fastScrollNotifier?.value.isVisible == true) {
          widget.fastScrollNotifier?.value = widget.fastScrollNotifier!.value.copyWith(
            isVisible: false,
          );
        }
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final double maxScroll = notification.metrics.maxScrollExtent;
    // If frames easily fit on screen without scrolling, never show scrubber or overlay
    if (maxScroll <= 40.0 || widget.thumbnails.length <= 4) {
      return false;
    }

    if (maxScroll > 0) {
      final double p = (notification.metrics.pixels / maxScroll).clamp(0.0, 1.0);
      if ((_scrollProgressNotifier.value - p).abs() > 0.0005) {
        _scrollProgressNotifier.value = p;
      }
    }

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _isUserScrollingTimeline = true;
        _accumulatedUserScrollDelta = 0.0;
        _lastUserDragTime = DateTime.now();
      }
      _scheduleHideScrubber();
    } else if (notification is ScrollUpdateNotification) {
      final double delta = notification.scrollDelta?.abs() ?? 0.0;
      final now = DateTime.now();
      final int elapsedMs = _lastUserDragTime != null
          ? now.difference(_lastUserDragTime!).inMilliseconds
          : 16;
      _lastUserDragTime = now;

      // Speed in logical pixels per second
      final int safeElapsedMs = elapsedMs.clamp(8, 500);
      final double instantaneousSpeed = (delta / safeElapsedMs) * 1000;

      // Active finger drag
      if (notification.dragDetails != null) {
        _isUserScrollingTimeline = true;
        if (elapsedMs > 300) {
          _accumulatedUserScrollDelta = 0.0;
        }
        _accumulatedUserScrollDelta += delta;

        // Display ONLY when scrolling faster and continuously past at least 1 frame (60 px):
        final bool isFast = _accumulatedUserScrollDelta >= 60.0 && instantaneousSpeed >= 380.0;

        if (isFast) {
          _isFastContinuousScrolling = true;
          _isFastScrollingNotifier.value = true;
          _showScrubber();

          final double viewportWidth = notification.metrics.viewportDimension;
          final double centerOffset = notification.metrics.pixels + (viewportWidth / 2);
          final int targetIndex = ((centerOffset - 32.0) / 68.0).round().clamp(0, widget.thumbnails.length - 1);

          widget.fastScrollNotifier?.value = FastScrollState(
            isVisible: true,
            currentFrame: targetIndex + 1,
            totalFrames: widget.thumbnails.length,
            fps: widget.fps,
          );

          _scheduleHideScrubber();
        }
      } else if (_isFastContinuousScrolling) {
        // While ballistic flinging after a rapid swipe
        _isFastScrollingNotifier.value = true;
        final double viewportWidth = notification.metrics.viewportDimension;
        final double centerOffset = notification.metrics.pixels + (viewportWidth / 2);
        final int targetIndex = ((centerOffset - 32.0) / 68.0).round().clamp(0, widget.thumbnails.length - 1);

        widget.fastScrollNotifier?.value = FastScrollState(
          isVisible: true,
          currentFrame: targetIndex + 1,
          totalFrames: widget.thumbnails.length,
          fps: widget.fps,
        );

        _scheduleHideScrubber();
      }
    } else if (notification is OverscrollNotification) {
      _scheduleHideScrubber();
    } else if (notification is ScrollEndNotification) {
      _isUserScrollingTimeline = false;
      _accumulatedUserScrollDelta = 0.0;
      _lastUserDragTime = null;
      _isFastContinuousScrolling = false;
      _isFastScrollingNotifier.value = false;
      _scheduleHideScrubber();
    }
    return false;
  }

  void _onHandleDragStart(DragStartDetails details, double currentHandleLeft, double minLeft, double maxLeft) {
    _isDraggingNotifier.value = true;
    _isFastScrollingNotifier.value = true;
    _hideScrubberTimer?.cancel();
    _dragStartGlobalX = details.globalPosition.dx;
    _dragStartHandleLeft = currentHandleLeft;
    _currentDragHandleLeft = currentHandleLeft;

    final double trackWidth = maxLeft - minLeft;
    final double progress = trackWidth > 0 ? ((currentHandleLeft - minLeft) / trackWidth).clamp(0.0, 1.0) : 0.0;
    final int totalFrames = widget.thumbnails.length;
    final int targetIndex = (progress * (totalFrames - 1)).round().clamp(0, totalFrames - 1);
    _triggerSelectionHaptic(targetIndex);
    HapticFeedback.lightImpact();

    widget.fastScrollNotifier?.value = FastScrollState(
      isVisible: true,
      currentFrame: targetIndex + 1,
      totalFrames: totalFrames,
      fps: widget.fps,
    );
  }

  void _onHandleDragUpdate(DragUpdateDetails details, double minLeft, double maxLeft) {
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) return;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double trackWidth = maxLeft - minLeft;
    if (maxScroll <= 0 || trackWidth <= 0) return;

    final double dragDelta = details.globalPosition.dx - _dragStartGlobalX;
    final double newHandleLeft = (_dragStartHandleLeft + dragDelta).clamp(minLeft, maxLeft);
    _currentDragHandleLeft = newHandleLeft;
    final double newProgress = ((newHandleLeft - minLeft) / trackWidth).clamp(0.0, 1.0);
    final double newOffset = (newProgress * maxScroll).clamp(0.0, maxScroll);
    _pendingScrubOffset = newOffset;

    // Schedule scroll jump at display refresh rate (max 60fps) to prevent 120Hz thread choke & ANR
    if (!_isScrubFrameScheduled) {
      _isScrubFrameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        _isScrubFrameScheduled = false;
        if (mounted && _scrollController.hasClients && _isDraggingScrubber) {
          _scrollController.jumpTo(_pendingScrubOffset);
          final double p = (maxScroll > 0) ? (_pendingScrubOffset / maxScroll).clamp(0.0, 1.0) : 0.0;
          _scrollProgressNotifier.value = p;
        }
      });
    }

    final int totalFrames = widget.thumbnails.length;
    final int newIndex = (newProgress * (totalFrames - 1)).round().clamp(0, totalFrames - 1);
    _triggerSelectionHaptic(newIndex);

    widget.fastScrollNotifier?.value = FastScrollState(
      isVisible: true,
      currentFrame: newIndex + 1,
      totalFrames: totalFrames,
      fps: widget.fps,
    );
  }

  void _onHandleDragEnd([DragEndDetails? details]) {
    _isDraggingNotifier.value = false;
    _isFastScrollingNotifier.value = false;
    _isScrubFrameScheduled = false;
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
      _scrollController.jumpTo(_pendingScrubOffset);
      final double maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _scrollProgressNotifier.value = (_pendingScrubOffset / maxScroll).clamp(0.0, 1.0);
      }
    }
    // NEVER automatically select a frame when user scrolls or drags!
    // Frame selection only occurs when the user explicitly taps a frame thumbnail.
    _scheduleHideScrubber();
    HapticFeedback.mediumImpact();
  }

  void _onHandleDragCancel() {
    _isDraggingNotifier.value = false;
    _isFastScrollingNotifier.value = false;
    _isScrubFrameScheduled = false;
    _scheduleHideScrubber();
  }

  void _scrollToCurrentIndex({bool animate = false}) {
    if (_isDraggingScrubber || _isUserScrollingTimeline || _isFastContinuousScrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _isDraggingScrubber || _isUserScrollingTimeline || _isFastContinuousScrolling) return;

      const double itemWidth = 68.0;
      final double targetOffset = widget.currentIndex * itemWidth;
      final double currentOffset = _scrollController.offset;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double viewport = _scrollController.position.viewportDimension;

      // Only scroll if the target frame is outside the visible viewport
      if (targetOffset < currentOffset || (targetOffset + itemWidth) > (currentOffset + viewport)) {
        final double centeredOffset = (targetOffset - (viewport / 2) + (itemWidth / 2)).clamp(0.0, maxScroll);
        // SAFETY: Only animate if distance is small (<1200px); jumpTo prevents ANR / crashes over large lists
        if (animate && (currentOffset - centeredOffset).abs() < 1200.0) {
          _scrollController.animateTo(
            centeredOffset,
            duration: const Duration(milliseconds: 250),
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
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: ColorConstants.border_color,
        border: Border(top: BorderSide(color: ColorConstants.border_color_2, width: 1)),
      ),
      child: Row(
        children: [
          // Unified Compact Control Dock (Layers, Audio, Play)
          _buildToolsDock(),
          // Reorderable Frame Thumbnails list with Fast-Scrub Handle
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool useFixedExtent = widget.thumbnails.length > 100;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: useFixedExtent
                          ? ListView.builder(
                              key: const PageStorageKey('timeline_canvas_selector_scroll'),
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              itemExtent: 68.0,
                              itemCount: widget.thumbnails.length,
                              itemBuilder: (context, index) {
                                return RepaintBoundary(
                                  key: (index < widget.canvasKeys.length)
                                      ? widget.canvasKeys[index]
                                      : ValueKey('canvas_frame_key_$index'),
                                  child: _buildThumbnailItem(context, index),
                                );
                              },
                            )
                          : ReorderableListView.builder(
                              key: const PageStorageKey('timeline_canvas_selector_scroll'),
                              scrollController: _scrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              proxyDecorator:
                                  (Widget child, int index, Animation<double> animation) {
                                    return Material(color: Colors.transparent, child: child);
                                  },
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              itemCount: widget.thumbnails.length,
                              // ignore: deprecated_member_use
                              onReorder: widget.onReorder,
                              itemBuilder: (context, index) {
                                final Key itemKey = (index < widget.canvasKeys.length)
                                    ? widget.canvasKeys[index]
                                    : ValueKey('canvas_frame_key_$index');
                                return ReorderableDelayedDragStartListener(
                                  key: itemKey,
                                  index: index,
                                  child: RepaintBoundary(
                                    child: _buildThumbnailItem(context, index),
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 0.0,
                      left: 0.0,
                      right: 0.0,
                      height: 24.0,
                      child: RepaintBoundary(
                        child: _buildFastScrubOverlay(constraints),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Dashed Add Frame Button
          Padding(
            padding: const EdgeInsets.only(right: 14.0, left: 6.0),
            child: _buildDashedAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildFastScrubOverlay(BoxConstraints constraints) {
    if (widget.thumbnails.length <= 4) return const SizedBox.shrink();

    final double viewportWidth = constraints.maxWidth;
    const double handleWidth = 40.0;
    const double handleHeight = 20.0;
    const double minLeft = 4.0;
    final double maxLeft = (viewportWidth - handleWidth - 4.0).clamp(4.0, 4000.0);
    final double trackWidth = (maxLeft - minLeft).clamp(1.0, 4000.0);

    return AnimatedBuilder(
      animation: _scrubberAnimController,
      builder: (context, child) {
        final double animVal = _scrubberAnimController.value;
        if (animVal <= 0.001) {
          return const SizedBox.shrink();
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Dotted Track Guideline across the timeline behind scrubber
            Positioned(
              top: 10.0,
              left: minLeft,
              right: minLeft,
              height: 4.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _scrubberFadeAnim.value * 0.75,
                  child: CustomPaint(
                    painter: const _DottedTrackPainter(
                      color: Color(0xFFCBD5E1),
                      dotRadius: 1.1,
                      spacing: 5.5,
                    ),
                  ),
                ),
              ),
            ),

            // Fast-Scrub Pill Handle (straddles the top border of the active frame, styled with app theme)
            ValueListenableBuilder<bool>(
              valueListenable: _isDraggingNotifier,
              builder: (context, isDragging, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: _scrollProgressNotifier,
                  builder: (context, progress, _) {
                    final double handleLeft = isDragging
                        ? _currentDragHandleLeft.clamp(minLeft, maxLeft)
                        : (minLeft + (progress * trackWidth)).clamp(minLeft, maxLeft);

                    return Positioned(
                      top: 0.0,
                      left: handleLeft - 6.0,
                      child: Opacity(
                        opacity: _scrubberFadeAnim.value,
                        child: Transform.scale(
                          scale: _scrubberScaleAnim.value,
                          child: AnimatedScale(
                            scale: isDragging ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutBack,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (details) => _onHandleDragStart(details, handleLeft, minLeft, maxLeft),
                              onHorizontalDragUpdate: (details) => _onHandleDragUpdate(details, minLeft, maxLeft),
                              onHorizontalDragEnd: _onHandleDragEnd,
                              onHorizontalDragCancel: _onHandleDragCancel,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _dismissScrubberAndOverlay(immediate: true);
                              },
                          child: Container(
                            padding: const EdgeInsets.only(top: 2.0, bottom: 8.0, left: 6.0, right: 6.0),
                            color: Colors.transparent,
                            child: Container(
                              key: const ValueKey('timeline_fast_scrub_handle'),
                              width: handleWidth,
                              height: handleHeight,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFA940),
                                    ColorConstants.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ColorConstants.primary.withValues(alpha: isDragging ? 0.60 : 0.40),
                                    blurRadius: isDragging ? 9 : 6,
                                    spreadRadius: isDragging ? 1.0 : 0.5,
                                    offset: const Offset(0, 2),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGripBar(height: 8.5),
                                  const SizedBox(width: 3.0),
                                  _buildGripBar(height: 11.5),
                                  const SizedBox(width: 3.0),
                                  _buildGripBar(height: 8.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGripBar({double height = 11.0}) {
    return Container(
      width: 2.2,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsDock() {
    final int layerCount = widget.drawingController != null
        ? (widget.drawingController!.layers.isNotEmpty ? widget.drawingController!.layers.length : 1)
        : (widget.layerCount ?? 1);
    final int audioCount = widget.audioClipCount ?? 0;

    return Container(
      height: 52,
      margin: const EdgeInsets.only(left: 8.0, right: 6.0, top: 14.0, bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Layers Button
          Tooltip(
            message: '${context.tr('layers')} ($layerCount)',
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              onTap: () {
                _dismissScrubberAndOverlay(immediate: true);
                widget.onOpenFrames();
              },
              child: SizedBox(
                width: 38,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      AssetConstants.layer_icon,
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        ColorConstants.darkText,
                        BlendMode.srcIn,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$layerCount',
                          style: const TextStyle(
                            fontSize: 8.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Subtle Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.black.withValues(alpha: 0.07),
          ),

          // 2. Audio Studio Button
          if (widget.onOpenAudioStudio != null) ...[
            Tooltip(
              message: '${context.tr('audioStudio')}${audioCount > 0 ? " ($audioCount)" : ""}',
              child: InkWell(
                onTap: () {
                  _dismissScrubberAndOverlay(immediate: true);
                  widget.onOpenAudioStudio?.call();
                },
                child: SizedBox(
                  width: 38,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 21,
                        color: audioCount > 0
                            ? const Color(0xFFFF9318)
                            : const Color(0xFF6E6E78),
                      ),
                      if (audioCount > 0)
                        Positioned(
                          top: 5,
                          right: 3,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9318),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9318).withValues(alpha: 0.4),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$audioCount',
                              style: const TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Subtle Divider
            Container(
              width: 1,
              height: 20,
              color: Colors.black.withValues(alpha: 0.07),
            ),
          ],

          // 3. Play / Preview Animation Button
          Tooltip(
            message: context.tr('previewAnimation'),
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
              onTap: () {
                _dismissScrubberAndOverlay(immediate: true);
                widget.onPlay();
              },
              child: Container(
                width: 42,
                height: 50,
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9318),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedAddButton() {
    return GestureDetector(
      onTap: () {
        _dismissScrubberAndOverlay(immediate: true);
        widget.onAdd();
      },
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
      onTap: () {
        _dismissScrubberAndOverlay(immediate: true);
        widget.onSelect(index);
      },
      onLongPress: () {
        _dismissScrubberAndOverlay(immediate: true);
        _showFrameActionsSheet(context, index);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                      ? ColorConstants.primary.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: (widget.aspectRatio > 0.05 && widget.aspectRatio.isFinite)
                        ? widget.aspectRatio
                        : 1.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildThumbnailBackground(),
                        _TimelineThumbnailContent(
                          key: ValueKey('thumb_$index'),
                          index: index,
                          aspectRatio: widget.aspectRatio,
                          thumbnail: (index < widget.thumbnails.length) ? widget.thumbnails[index] : null,
                          frameImagePath: (widget.frameImagePaths != null && index < widget.frameImagePaths!.length)
                              ? widget.frameImagePaths![index]
                              : null,
                          hasCustomStrokes: widget.frameHasCustomStrokes,
                          onRequestThumbnail: widget.onRequestThumbnail,
                          isFastScrollingNotifier: _isFastScrollingNotifier,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _dismissScrubberAndOverlay(immediate: true);
                _showFrameActionsSheet(context, index);
              },
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

          // Frame Number Badge
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorConstants.primary
                    : Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFrameActionsSheet(BuildContext context, int index) {
    _dismissScrubberAndOverlay(immediate: true);
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
                color: Color(0x1A0F172A),
                blurRadius: 24,
                offset: Offset(0, -6),
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
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header with Thumbnail Preview & Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail Preview
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: index == widget.currentIndex
                                  ? ColorConstants.primary
                                  : const Color(0xFFCBD5E1),
                              width: index == widget.currentIndex ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: index == widget.currentIndex
                                    ? ColorConstants.primary.withValues(alpha: 0.20)
                                    : const Color(0x0A0F172A),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              color: Colors.white,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: (widget.aspectRatio > 0.05 && widget.aspectRatio.isFinite)
                                      ? widget.aspectRatio
                                      : 1.0,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _buildThumbnailBackground(),
                                      _TimelineThumbnailContent(
                                        key: ValueKey('sheet_thumb_${index}_${widget.frameImagePaths != null && index < widget.frameImagePaths!.length ? widget.frameImagePaths![index] : index}'),
                                        index: index,
                                        aspectRatio: widget.aspectRatio,
                                        thumbnail: (index < widget.thumbnails.length) ? widget.thumbnails[index] : null,
                                        frameImagePath: (widget.frameImagePaths != null && index < widget.frameImagePaths!.length)
                                            ? widget.frameImagePaths![index]
                                            : null,
                                        hasCustomStrokes: widget.frameHasCustomStrokes,
                                        onRequestThumbnail: widget.onRequestThumbnail,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${context.tr('frame')} ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
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
                                        color: ColorConstants.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        context.tr('active'),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: ColorConstants.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.tr('totalFramesInAnimation', {'total': '${widget.thumbnails.length}'}),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
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
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: Color(0xFF64748B),
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
                          title: context.tr('copy'),
                          subtitle: context.tr('toClipboard'),
                          accentBg: const Color(0xFFEFF6FF),
                          accentColor: const Color(0xFF2563EB),
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
                          title: context.tr('paste'),
                          subtitle: context.tr('fromClipboard'),
                          accentBg: const Color(0xFFF0FDF4),
                          accentColor: const Color(0xFF16A34A),
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
                          title: context.tr('duplicate'),
                          subtitle: context.tr('cloneFrame'),
                          accentBg: const Color(0xFFFFF7ED),
                          accentColor: const Color(0xFFEA580C),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            widget.onFrameAction('duplicate', index);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Section Title with decorative line
                  Row(
                    children: [
                      Text(
                        context.tr('timelineInsertion'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Add Left & Add Right Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildListActionTile(
                          icon: Icons.arrow_back_rounded,
                          title: context.tr('addLeft'),
                          subtitle: context.tr('insertBlankBefore'),
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
                          title: context.tr('addRight'),
                          subtitle: context.tr('insertBlankAfter'),
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
                      borderRadius: BorderRadius.circular(16),
                      onTap: isOnlyFrame
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              widget.onFrameAction('delete', index);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isOnlyFrame ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOnlyFrame ? const Color(0xFFE2E8F0) : const Color(0xFFFEE2E2),
                            width: 1.2,
                          ),
                          boxShadow: isOnlyFrame
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isOnlyFrame ? const Color(0xFFF1F5F9) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOnlyFrame ? Colors.transparent : const Color(0xFFFECACA),
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: isOnlyFrame ? const Color(0xFF94A3B8) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('deleteFrameTitle', {'num': '${index + 1}'}),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isOnlyFrame ? const Color(0xFF94A3B8) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 1.5),
                                  Text(
                                    isOnlyFrame
                                        ? context.tr('cannotDeleteOnlyFrame')
                                        : context.tr('removeFrameFromAnimation'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isOnlyFrame
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.8),
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
    required String title,
    required String subtitle,
    required Color accentBg,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
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
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: Center(
                  child: Icon(icon, size: 16, color: const Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
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

    final Color bgColor = PatternBackgroundHelper.getBaseColor(bg.pattern, bg.color);

    return Container(
      color: bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bg.image != null)
            Positioned.fill(
              child: Opacity(
                opacity: bg.imageOpacity,
                child: SafeThumbnailWidget(
                  image: bg.image!,
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

class _TimelineThumbnailContent extends StatefulWidget {
  final int index;
  final double aspectRatio;
  final ui.Image? thumbnail;
  final String? frameImagePath;
  final bool Function(int index)? hasCustomStrokes;
  final void Function(int index)? onRequestThumbnail;
  final ValueNotifier<bool>? isFastScrollingNotifier;

  const _TimelineThumbnailContent({
    super.key,
    required this.index,
    this.aspectRatio = 1.0,
    required this.thumbnail,
    required this.frameImagePath,
    this.hasCustomStrokes,
    required this.onRequestThumbnail,
    this.isFastScrollingNotifier,
  });

  @override
  State<_TimelineThumbnailContent> createState() => _TimelineThumbnailContentState();
}

class _TimelineThumbnailContentState extends State<_TimelineThumbnailContent> {
  @override
  void initState() {
    super.initState();
    widget.isFastScrollingNotifier?.addListener(_onFastScrollChanged);
    _checkRequest();
  }

  @override
  void didUpdateWidget(covariant _TimelineThumbnailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFastScrollingNotifier != widget.isFastScrollingNotifier) {
      oldWidget.isFastScrollingNotifier?.removeListener(_onFastScrollChanged);
      widget.isFastScrollingNotifier?.addListener(_onFastScrollChanged);
    }
    if (widget.thumbnail == null && (oldWidget.thumbnail != null || widget.index != oldWidget.index || widget.frameImagePath != oldWidget.frameImagePath)) {
      _checkRequest();
    }
  }

  @override
  void dispose() {
    widget.isFastScrollingNotifier?.removeListener(_onFastScrollChanged);
    super.dispose();
  }

  void _onFastScrollChanged() {
    if (mounted) {
      setState(() {});
      if (!(widget.isFastScrollingNotifier?.value ?? false)) {
        _checkRequest();
      }
    }
  }

  void _checkRequest() {
    if (widget.thumbnail != null) return;
    if (widget.isFastScrollingNotifier?.value ?? false) return;
    final bool hasPath = widget.frameImagePath != null && widget.frameImagePath!.isNotEmpty;
    final bool hasStrokes = widget.hasCustomStrokes?.call(widget.index) ?? false;
    if (hasPath && !hasStrokes) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.thumbnail == null && !(widget.isFastScrollingNotifier?.value ?? false)) {
        widget.onRequestThumbnail?.call(widget.index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thumbnail != null) {
      return SafeThumbnailWidget(image: widget.thumbnail, fit: BoxFit.contain);
    }

    final bool isFastScrolling = widget.isFastScrollingNotifier?.value ?? false;
    if (isFastScrolling) {
      return const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.black12,
          size: 18,
        ),
      );
    }

    final path = widget.frameImagePath;
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        key: ValueKey(path),
        fit: BoxFit.contain,
        cacheHeight: 120,
        cacheWidth: 120,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !(widget.isFastScrollingNotifier?.value ?? false)) {
              widget.onRequestThumbnail?.call(widget.index);
            }
          });
          return const Center(
            child: Icon(
              Icons.palette_outlined,
              color: Colors.black26,
              size: 20,
            ),
          );
        },
      );
    }

    return const Center(
      child: Icon(
        Icons.palette_outlined,
        color: Colors.black26,
        size: 20,
      ),
    );
  }
}

class _DottedTrackPainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  const _DottedTrackPainter({
    this.color = const Color(0xFFCBD5E1),
    this.dotRadius = 1.1,
    this.spacing = 5.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double y = size.height / 2;
    double currentX = 0.0;
    while (currentX < size.width) {
      canvas.drawCircle(Offset(currentX, y), dotRadius, paint);
      currentX += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTrackPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.spacing != spacing;
  }
}

