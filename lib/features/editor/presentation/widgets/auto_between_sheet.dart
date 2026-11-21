import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/custom_switch.dart';
import '../../../projects/presentation/widgets/preview_pattern_painter.dart';
import '../../services/auto_between_service.dart';
import '../controllers/editor_controller.dart';

class AutoBetweenSheet extends StatefulWidget {
  final EditorController controller;
  final int initialStartIndex;
  final int initialEndIndex;
  final double? bannerTopOffset;

  const AutoBetweenSheet({
    super.key,
    required this.controller,
    required this.initialStartIndex,
    required this.initialEndIndex,
    this.bannerTopOffset,
  });

  /// Opens the Auto Between modal sheet, or shows a prompt if fewer than 2 frames exist.
  static Future<void> show(
    BuildContext context,
    EditorController controller, {
    int? initialFrameIndex,
  }) async {
    final int total = controller.canvases.length;
    if (total < 2) {
      Fluttertoast.showToast(
        msg: context.tr('autoBetweenNeedTwoFrames'),
        backgroundColor: ColorConstants.darkText,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (controller.activeSticker != null) {
      controller.stampActiveSticker();
    }

    final int anchor = (initialFrameIndex ?? controller.currentIndex).clamp(
      0,
      total - 1,
    );
    final int startIdx = anchor < total - 1 ? anchor : anchor - 1;
    final int endIdx = startIdx + 1;

    // Ensure keyframe images (if any) are hydrated before previewing
    await controller.ensureCanvasImagesLoaded(startIdx);
    await controller.ensureCanvasImagesLoaded(endIdx);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return AutoBetweenSheet(
          controller: controller,
          initialStartIndex: startIdx,
          initialEndIndex: endIdx,
        );
      },
    );
  }

  @override
  State<AutoBetweenSheet> createState() => _AutoBetweenSheetState();
}

class _AutoBetweenSheetState extends State<AutoBetweenSheet>
    with SingleTickerProviderStateMixin {
  static const List<int> _quickCounts = [1, 3, 5, 8, 12, 24];

  late int _startIndex;
  late int _endIndex;
  int _betweenCount = 5;
  TweenEasing _easing = TweenEasing.easeInOut;
  bool _replaceExistingBetween = false;
  bool _fadeUnmatched = true;
  bool _isGenerating = false;
  bool _isPlayingPreview = true;

  late AutoBetweenPlan _plan;
  late final AnimationController _previewController;

  @override
  void initState() {
    super.initState();
    _startIndex = widget.initialStartIndex;
    _endIndex = widget.initialEndIndex;
    _rebuildPlan();

    _previewController = AnimationController(
      vsync: this,
      duration: _computePreviewDuration(),
    )..repeat();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  Duration _computePreviewDuration() {
    final int fps = widget.controller.fps.clamp(4, 30);
    final int totalSteps = _betweenCount + 2; // Key A + in-betweens + Key B
    final int ms = ((totalSteps / fps) * 1000).round().clamp(750, 3200);
    return Duration(milliseconds: ms);
  }

  void _rebuildPlan() {
    final canvases = widget.controller.canvases;
    _plan = AutoBetweenPlan.fromCanvases(
      canvases[_startIndex],
      canvases[_endIndex],
      fadeUnmatched: _fadeUnmatched,
    );
  }

  void _updatePair(int newStart, int newEnd) {
    final int maxIdx = widget.controller.canvases.length - 1;
    final int s = newStart.clamp(0, maxIdx - 1);
    final int e = newEnd.clamp(s + 1, maxIdx);
    setState(() {
      _startIndex = s;
      _endIndex = e;
      if (_endIndex <= _startIndex + 1) {
        _replaceExistingBetween = false;
      }
      _rebuildPlan();
    });
    Future.wait([
      widget.controller.ensureCanvasImagesLoaded(s),
      widget.controller.ensureCanvasImagesLoaded(e),
    ]).then((_) {
      if (mounted) {
        setState(() => _rebuildPlan());
      }
    });
  }

  Future<void> _pickFrameDialog({required bool isStart}) async {
    final int total = widget.controller.canvases.length;
    final int minIdx = isStart ? 0 : 1;
    final int maxIdx = isStart ? total - 2 : total - 1;
    final int selected = isStart ? _startIndex : _endIndex;
    if (minIdx > maxIdx) return;

    final int? picked = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isStart ? context.tr('fromFrame') : context.tr('toFrame'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SizedBox(
            width: 300,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: maxIdx - minIdx + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (ctx, i) {
                  final int idx = minIdx + i;
                  final bool isCurrent = idx == selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(dialogCtx).pop(idx),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? ColorConstants.primary
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? ColorConstants.primary
                              : ColorConstants.border,
                        ),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? Colors.white
                              : ColorConstants.darkText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      if (isStart) {
        final int nextEnd = _endIndex > picked ? _endIndex : picked + 1;
        _updatePair(picked, nextEnd);
      } else {
        final int nextStart = _startIndex < picked ? _startIndex : picked - 1;
        _updatePair(nextStart, picked);
      }
    }
  }

  void _updateBetweenCount(int count) {
    setState(() {
      _betweenCount = count.clamp(1, 30);
    });
    _previewController.duration = _computePreviewDuration();
    if (_isPlayingPreview) {
      _previewController.repeat();
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlayingPreview = !_isPlayingPreview;
      if (_isPlayingPreview) {
        _previewController.repeat();
      } else {
        _previewController.stop();
      }
    });
  }

  void _scrubTo(double rawValue) {
    if (_isPlayingPreview) {
      _isPlayingPreview = false;
      _previewController.stop();
    }
    setState(() {
      _previewController.value = rawValue.clamp(0.0, 1.0);
    });
  }

  Future<void> _onGenerate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final BuildContext metricContext = overlay?.context ?? context;
    final double statusTop = math.max(
      MediaQuery.viewPaddingOf(metricContext).top,
      MediaQuery.paddingOf(metricContext).top,
    );
    final double topOffset =
        widget.bannerTopOffset ?? (statusTop + kToolbarHeight + 12);
    final undoLabel = context.tr('undo');

    try {
      final int generated = await widget.controller.generateAutoBetweenFrames(
        startIndex: _startIndex,
        endIndex: _endIndex,
        betweenCount: _betweenCount,
        easing: _easing,
        replaceExistingBetween: _replaceExistingBetween,
        fadeUnmatched: _fadeUnmatched,
      );

      if (!mounted) return;
      final generatedMsg = context.tr('autoBetweenGenerated', {
        'count': '$generated',
      });
      Navigator.of(context).pop();

      if (generated > 0) {
        if (overlay != null) {
          _showAutoBetweenUndoBanner(
            overlay: overlay,
            topOffset: topOffset,
            message: generatedMsg,
            undoLabel: undoLabel,
            onUndo: widget.controller.canUndoLastAutoBetween
                ? () => widget.controller.undoLastAutoBetween()
                : null,
          );
        } else {
          Fluttertoast.showToast(
            msg: generatedMsg,
            backgroundColor: ColorConstants.primary,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalFrames = widget.controller.canvases.length;
    final int existingGap = _endIndex - _startIndex - 1;
    final double maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFA940), ColorConstants.primary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_motion_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('autoBetween'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: ColorConstants.darkText,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                context.tr('autoBetweenSubtitle'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: ColorConstants.mediumText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Live Vector Tween Preview
                    _buildPreviewCard(),

                    const SizedBox(height: 14),

                    // From / To Frame Picker
                    Row(
                      children: [
                        Expanded(
                          child: _buildFrameStepperCard(
                            label: context.tr('fromFrame'),
                            frameNumber: _startIndex + 1,
                            canDecrement: _startIndex > 0,
                            canIncrement: _startIndex + 1 < _endIndex,
                            onDecrement: () => _updatePair(_startIndex - 1, _endIndex),
                            onIncrement: () => _updatePair(_startIndex + 1, _endIndex),
                            onPickFrame: () => _pickFrameDialog(isStart: true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: ColorConstants.primary,
                          ),
                        ),
                        Expanded(
                          child: _buildFrameStepperCard(
                            label: context.tr('toFrame'),
                            frameNumber: _endIndex + 1,
                            canDecrement: _endIndex - 1 > _startIndex,
                            canIncrement: _endIndex < totalFrames - 1,
                            onDecrement: () => _updatePair(_startIndex, _endIndex - 1),
                            onIncrement: () => _updatePair(_startIndex, _endIndex + 1),
                            onPickFrame: () => _pickFrameDialog(isStart: false),
                          ),
                        ),
                      ],
                    ),

                    if (existingGap > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ColorConstants.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${context.tr('replaceBetweenFrames')} ($existingGap)',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.darkText,
                                ),
                              ),
                            ),
                            CustomSwitch(
                              value: _replaceExistingBetween,
                              onChanged: (val) {
                                setState(() => _replaceExistingBetween = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // In-Between Frame Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('inBetweenFrames'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '+$_betweenCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ColorConstants.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.5,
                        activeTrackColor: ColorConstants.primary,
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.5,
                          elevation: 2.5,
                        ),
                        overlayColor: ColorConstants.primary.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: _betweenCount.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        onChanged: (v) => _updateBetweenCount(v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickCounts.map((count) {
                        final bool selected = _betweenCount == count;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () => _updateBetweenCount(count),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? ColorConstants.primary
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.transparent
                                        : ColorConstants.border,
                                  ),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : ColorConstants.darkText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Motion Curve (Easing)
                    Text(
                      context.tr('motionCurve'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TweenEasing.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final TweenEasing curve = TweenEasing.values[idx];
                          final bool isSelected = _easing == curve;
                          return GestureDetector(
                            onTap: () => setState(() => _easing = curve),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 78,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstants.primary.withValues(alpha: 0.1)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorConstants.primary
                                      : ColorConstants.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 20,
                                    child: CustomPaint(
                                      painter: _EasingCurvePainter(
                                        easing: curve,
                                        color: isSelected
                                            ? ColorConstants.primary
                                            : ColorConstants.mediumText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      context.tr(curve.labelKey),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? ColorConstants.primary
                                            : ColorConstants.mediumText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Fade unmatched toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ColorConstants.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.opacity_rounded,
                            size: 18,
                            color: ColorConstants.mediumText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('fadeUnmatchedItems'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.darkText,
                              ),
                            ),
                          ),
                          CustomSwitch(
                            value: _fadeUnmatched,
                            onChanged: (val) {
                              setState(() {
                                _fadeUnmatched = val;
                                _rebuildPlan();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pinned Generate CTA Button so it's always reachable without scrolling
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ColorConstants.primary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_motion_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('generateFramesBtn', {
                                  'count': '$_betweenCount',
                                }),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildPreviewCard() {
    final double ratio = widget.controller.aspectRatio;
    final Size? canvasSize =
        widget.controller.canvases[_startIndex].drawConfig.value.size ??
        widget.controller.canvases[_endIndex].drawConfig.value.size ??
        widget.controller.drawingControllerSize;
    final Size logicalSize = (canvasSize != null && !canvasSize.isEmpty)
        ? canvasSize
        : (ratio >= 1.0 ? Size(1000, 1000 / ratio) : Size(1000 * ratio, 1000));
    final bg = widget.controller.globalBackground;
    final Color bgColor = PatternBackgroundHelper.getBaseColor(
      bg.pattern,
      bg.color,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstants.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: SizedBox(
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _previewController,
                              builder: (context, _) {
                                final double u = _rawToProgress(
                                  _previewController.value,
                                );
                                final double t = _easing.transform(u);
                                return CustomPaint(
                                  painter: _AutoBetweenPreviewPainter(
                                    plan: _plan,
                                    logicalCanvasSize: logicalSize,
                                    t: t,
                                    background: bg,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_plan.totalTrackCount == 0)
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorConstants.border),
                        ),
                        child: Text(
                          context.tr('autoBetweenEmptyHint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.mediumText,
                          ),
                        ),
                      ),
                    ),

                  // Top-left (start) Frame Pair badge
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ColorConstants.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'F${_startIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: ColorConstants.darkText,
                            ),
                          ),
                          Text(
                            'F${_endIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: ColorConstants.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-right (end) Play/Pause indicator
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorConstants.border),
                      ),
                      child: Icon(
                        _isPlayingPreview
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 16,
                        color: ColorConstants.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Compact interactive scrub bar for frame-by-frame inspection
          AnimatedBuilder(
            animation: _previewController,
            builder: (context, _) {
              final double u = _rawToProgress(_previewController.value);
              final int totalSteps = _betweenCount + 1;
              final int stepIdx = (u * totalSteps).round().clamp(0, totalSteps);
              final String stepLabel = stepIdx == 0
                  ? 'A'
                  : (stepIdx == totalSteps ? 'B' : '$stepIdx/$_betweenCount');
              return Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      stepLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ColorConstants.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        activeTrackColor: ColorConstants.primary,
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                        thumbColor: ColorConstants.primary,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5.5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: u,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _scrubTo(0.12 + val * 0.76);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _rawToProgress(double raw) {
    if (raw < 0.12) return 0.0;
    if (raw > 0.88) return 1.0;
    return ((raw - 0.12) / 0.76).clamp(0.0, 1.0);
  }

  Widget _buildFrameStepperCard({
    required String label,
    required int frameNumber,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onPickFrame,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: ColorConstants.mediumText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepperBtn(
                icon: Icons.chevron_left_rounded,
                enabled: canDecrement,
                onTap: onDecrement,
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onPickFrame,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_capitalizeWord(context.tr('frame'))} $frameNumber',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: ColorConstants.darkText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _stepperBtn(
                icon: Icons.chevron_right_rounded,
                enabled: canIncrement,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? ColorConstants.border : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? ColorConstants.darkText : ColorConstants.lightText,
        ),
      ),
    );
  }
}

class _AutoBetweenPreviewPainter extends CustomPainter {
  final AutoBetweenPlan plan;
  final Size logicalCanvasSize;
  final double t;
  final CanvasBackground background;

  _AutoBetweenPreviewPainter({
    required this.plan,
    required this.logicalCanvasSize,
    required this.t,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || logicalCanvasSize.isEmpty) return;

    if (background.image != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: background.image!,
        fit: BoxFit.cover,
        opacity: background.imageOpacity.clamp(0.0, 1.0),
      );
    }
    if (background.pattern != null && background.pattern != 'none') {
      PreviewPatternPainter(background.pattern!).paint(canvas, size);
    }

    final double sx = size.width / logicalCanvasSize.width;
    final double sy = size.height / logicalCanvasSize.height;
    final double scale = math.min(sx, sy);
    final double dx = (size.width - logicalCanvasSize.width * scale) / 2;
    final double dy = (size.height - logicalCanvasSize.height * scale) / 2;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    plan.paintPreview(canvas, logicalCanvasSize, t);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AutoBetweenPreviewPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.t != t ||
        oldDelegate.logicalCanvasSize != logicalCanvasSize;
  }
}

class _EasingCurvePainter extends CustomPainter {
  final TweenEasing easing;
  final Color color;

  const _EasingCurvePainter({
    required this.easing,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );

    final Path path = Path();
    const int steps = 20;
    for (int i = 0; i <= steps; i++) {
      final double u = i / steps;
      final double v = easing.transform(u).clamp(0.0, 1.0);
      final double x = u * size.width;
      final double y = size.height - (v * (size.height - 2) + 1);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint curvePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _EasingCurvePainter oldDelegate) {
    return oldDelegate.easing != easing || oldDelegate.color != color;
  }
}

String _capitalizeWord(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

OverlayEntry? _activeUndoBannerEntry;

void _showAutoBetweenUndoBanner({
  required OverlayState overlay,
  required double topOffset,
  required String message,
  required String undoLabel,
  VoidCallback? onUndo,
}) {
  try {
    _activeUndoBannerEntry?.remove();
  } catch (_) {}
  _activeUndoBannerEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AutoDismissUndoBanner(
      topOffset: topOffset,
      message: message,
      undoLabel: undoLabel,
      onUndo: onUndo,
      onDismissed: () {
        if (identical(_activeUndoBannerEntry, entry)) {
          _activeUndoBannerEntry = null;
        }
        try {
          entry.remove();
        } catch (_) {}
      },
    ),
  );
  _activeUndoBannerEntry = entry;
  overlay.insert(entry);
}

class _AutoDismissUndoBanner extends StatefulWidget {
  final double topOffset;
  final String message;
  final String undoLabel;
  final VoidCallback? onUndo;
  final VoidCallback onDismissed;

  const _AutoDismissUndoBanner({
    required this.topOffset,
    required this.message,
    required this.undoLabel,
    required this.onUndo,
    required this.onDismissed,
  });

  @override
  State<_AutoDismissUndoBanner> createState() => _AutoDismissUndoBannerState();
}

class _AutoDismissUndoBannerState extends State<_AutoDismissUndoBanner> {
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topOffset,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: ColorConstants.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onUndo != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        widget.onUndo?.call();
                        _dismiss();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          widget.undoLabel,
                          style: const TextStyle(
                            color: ColorConstants.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _dismiss,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
