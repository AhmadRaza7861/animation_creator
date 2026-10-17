import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// State representing the fast-scroll frame counter overlay
class FastScrollState {
  final bool isVisible;
  final int currentFrame;
  final int totalFrames;
  final int fps;

  const FastScrollState({
    this.isVisible = false,
    this.currentFrame = 1,
    this.totalFrames = 1,
    this.fps = 12,
  });

  FastScrollState copyWith({
    bool? isVisible,
    int? currentFrame,
    int? totalFrames,
    int? fps,
  }) {
    return FastScrollState(
      isVisible: isVisible ?? this.isVisible,
      currentFrame: currentFrame ?? this.currentFrame,
      totalFrames: totalFrames ?? this.totalFrames,
      fps: fps ?? this.fps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastScrollState &&
          runtimeType == other.runtimeType &&
          isVisible == other.isVisible &&
          currentFrame == other.currentFrame &&
          totalFrames == other.totalFrames &&
          fps == other.fps;

  @override
  int get hashCode =>
      isVisible.hashCode ^
      currentFrame.hashCode ^
      totalFrames.hashCode ^
      fps.hashCode;
}

/// Floating Fast-Scroll Frame Counter Overlay
/// Displays a large white card showing:
/// - Left column: CURRENT FRAME, large vibrant orange frame number, orange SECONDS capsule badge (ColorConstants.primary)
/// - Right column: TOTAL FRAMES, large dark slate frame number, dark SECONDS capsule badge
/// Appears only during rapid continuous scrolling and smoothly disappears when idle.
class FastScrollCounterOverlay extends StatefulWidget {
  final ValueNotifier<FastScrollState>? notifier;

  const FastScrollCounterOverlay({
    super.key,
    required this.notifier,
  });

  @override
  State<FastScrollCounterOverlay> createState() => _FastScrollCounterOverlayState();
}

class _FastScrollCounterOverlayState extends State<FastScrollCounterOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    widget.notifier?.addListener(_onStateChanged);
    if (widget.notifier?.value.isVisible == true) {
      _showAndScheduleDismiss();
    }
  }

  void _showAndScheduleDismiss() {
    if (_animController.status != AnimationStatus.forward &&
        _animController.status != AnimationStatus.completed) {
      _animController.forward();
    }
    _resetAutoDismissTimer();
  }

  void _resetAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    // Safety watchdog: always auto-dismiss after 1250ms of inactivity
    _autoDismissTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (_animController.status != AnimationStatus.reverse &&
        _animController.status != AnimationStatus.dismissed) {
      _animController.reverse();
    }
    if (widget.notifier?.value.isVisible == true) {
      widget.notifier?.value = widget.notifier!.value.copyWith(isVisible: false);
    }
  }

  @override
  void didUpdateWidget(covariant FastScrollCounterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier?.removeListener(_onStateChanged);
      widget.notifier?.addListener(_onStateChanged);
      _onStateChanged();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    widget.notifier?.removeListener(_onStateChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final isVisible = widget.notifier?.value.isVisible ?? false;
    if (isVisible) {
      _showAndScheduleDismiss();
    } else {
      _autoDismissTimer?.cancel();
      if (_animController.status != AnimationStatus.reverse &&
          _animController.status != AnimationStatus.dismissed) {
        _animController.reverse();
      }
    }
  }

  static String _formatDuration(int frames, int fps) {
    final int effectiveFps = fps > 0 ? fps : 12;
    final int totalSeconds = (frames / effectiveFps).floor();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifier == null) return const SizedBox.shrink();

    return ValueListenableBuilder<FastScrollState>(
      valueListenable: widget.notifier!,
      builder: (context, state, child) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final double animVal = _animController.value;
            if (animVal <= 0.001) {
              return const SizedBox.shrink();
            }

            final String currentSecFormatted = _formatDuration(state.currentFrame, state.fps);
            final String totalSecFormatted = _formatDuration(state.totalFrames, state.fps);

            return RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      key: const ValueKey('fast_scroll_counter_card'),
                    width: 320,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFF1F2F6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: ColorConstants.primary.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Column: CURRENT FRAME
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'CURRENT FRAME',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.primary,
                                  letterSpacing: 0.6,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${state.currentFrame}',
                                  style: const TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: ColorConstants.primary,
                                    letterSpacing: -1.0,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'SECONDS ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        currentSecFormatted,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Divider
                        Container(
                          width: 1.2,
                          height: 92,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: const Color(0xFFE5E7EB),
                        ),

                        // Right Column: TOTAL FRAMES
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'TOTAL FRAMES',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: ColorConstants.mediumText,
                                  letterSpacing: 0.6,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${state.totalFrames}',
                                  style: const TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: ColorConstants.darkText,
                                    letterSpacing: -1.0,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'SECONDS ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        totalSecFormatted,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          );
          },
        );
      },
    );
  }
}
