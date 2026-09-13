import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/project_loading_view.dart';
import 'video_processing_screen.dart';

class VideoTrimmingScreen extends StatefulWidget {
  final File videoFile;

  const VideoTrimmingScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmingScreen> createState() => _VideoTrimmingScreenState();
}

class _VideoTrimmingScreenState extends State<VideoTrimmingScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  double _startValue = 0.0;
  double _endValue = 0.0;
  final double _minDurationMs = 1000.0; // 1 second minimum

  int _selectedFps = 10; // Default animation FPS (rotoscoping standard)
  final List<int> _fpsOptions = [6, 10, 12, 24];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
          _endValue = _controller.value.duration.inMilliseconds.toDouble();
        });
        _controller.addListener(_videoListener);
        _controller.play();
      });
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final pos = _controller.value.position.inMilliseconds.toDouble();
    if (_controller.value.isPlaying && pos >= _endValue) {
      _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    _controller.pause();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoProcessingScreen(
          videoFile: widget.videoFile,
          startMs: _startValue.toInt(),
          endMs: _endValue.toInt(),
          fps: _selectedFps,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    int millis = (duration.inMilliseconds % 1000) ~/ 10;
    return "$minutes:$seconds.${millis.toString().padLeft(2, '0')}";
  }

  void _stepFrame(int deltaFrames) {
    HapticFeedback.selectionClick();
    final double frameMs = 1000.0 / _selectedFps;
    final double currentPos = _controller.value.position.inMilliseconds.toDouble();
    final double targetPos = (currentPos + deltaFrames * frameMs).clamp(_startValue, _endValue);
    _controller.seekTo(Duration(milliseconds: targetPos.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const ProjectLoadingView(
        title: 'Loading Video',
        subtitle: 'Preparing video frames for preview...',
      );
    }

    final double totalDurationMs = _controller.value.duration.inMilliseconds.toDouble();
    final double selectedDurationSec = (_endValue - _startValue) / 1000.0;
    final int totalFrames = (selectedDurationSec * _selectedFps).round().clamp(1, 9999);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: ColorConstants.darkText, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Import Video',
              style: TextStyle(color: ColorConstants.darkText, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Select range & frame rate for animation',
              style: TextStyle(color: ColorConstants.mediumText, fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Cinematic Video Preview Container (Light Card with letterboxed video)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Player
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),

                      // Floating Glass Badges on Top
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Resolution badge
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam_outlined, color: Colors.white.withOpacity(0.9), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_controller.value.size.width.toInt()}x${_controller.value.size.height.toInt()}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Duration & Source badge
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatDuration(_controller.value.duration),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.accent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'SOURCE',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overlay Play/Pause Tap Target
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              if (value.isPlaying) return const SizedBox.shrink();
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14),
                                  ],
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              );
                            },
                          ),
                        ),
                      ),

                      // Bottom Floating Current Playhead Timecode
                      Positioned(
                        bottom: 10,
                        child: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, VideoPlayerValue value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  color: Colors.black.withOpacity(0.6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: value.isPlaying ? const Color(0xFF00E676) : Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDuration(value.position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Playback Transport Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Jump to start
                  _buildTransportButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Start of Range',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
                    },
                  ),
                  const SizedBox(width: 14),

                  // Step back 1 frame
                  _buildTransportButton(
                    icon: Icons.replay_5_rounded,
                    tooltip: 'Step Back',
                    onTap: () => _stepFrame(-1),
                  ),
                  const SizedBox(width: 16),

                  // Main Play / Pause Button with Accent Glow
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final bool isPlaying = value.isPlaying;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          isPlaying ? _controller.pause() : _controller.play();
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF9E24), Color(0xFFFF6E00)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8500).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // Step forward 1 frame
                  _buildTransportButton(
                    icon: Icons.forward_5_rounded,
                    tooltip: 'Step Forward',
                    onTap: () => _stepFrame(1),
                  ),
                  const SizedBox(width: 14),

                  // Jump to end
                  _buildTransportButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'End of Range',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _controller.seekTo(Duration(milliseconds: _endValue.toInt()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 3. Professional Filmstrip Timeline Trimmer (Light Theme)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8EE)),
                ),
                child: Column(
                  children: [
                    // Time Range Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeChip(
                          label: 'START',
                          timeStr: _formatDuration(Duration(milliseconds: _startValue.toInt())),
                          color: const Color(0xFFFF9E24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E2EA)),
                          ),
                          child: Text(
                            'Duration: ${selectedDurationSec.toStringAsFixed(1)}s',
                            style: const TextStyle(color: ColorConstants.darkText, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _buildTimeChip(
                          label: 'END',
                          timeStr: _formatDuration(Duration(milliseconds: _endValue.toInt())),
                          color: const Color(0xFFFF6E00),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Custom Tactile Filmstrip Trimmer Track
                    SizedBox(
                      height: 52,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double trackWidth = constraints.maxWidth;
                          final double startFraction = totalDurationMs > 0 ? (_startValue / totalDurationMs).clamp(0.0, 1.0) : 0.0;
                          final double endFraction = totalDurationMs > 0 ? (_endValue / totalDurationMs).clamp(0.0, 1.0) : 1.0;

                          return ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              final double currentPos = value.position.inMilliseconds.toDouble();
                              final double playheadFraction = totalDurationMs > 0 ? (currentPos / totalDurationMs).clamp(0.0, 1.0) : 0.0;

                              return _FilmstripTrimmerWidget(
                                trackWidth: trackWidth,
                                startFraction: startFraction,
                                endFraction: endFraction,
                                playheadFraction: playheadFraction,
                                onStartChanged: (fraction) {
                                  double newStart = fraction * totalDurationMs;
                                  final double maxStart = _endValue - _minDurationMs;
                                  if (newStart > maxStart) newStart = max(0.0, maxStart);
                                  newStart = newStart.clamp(0.0, totalDurationMs);
                                  setState(() {
                                    _startValue = newStart;
                                  });
                                  _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
                                },
                                onEndChanged: (fraction) {
                                  double newEnd = fraction * totalDurationMs;
                                  final double minEnd = _startValue + _minDurationMs;
                                  if (newEnd < minEnd) newEnd = min(totalDurationMs, minEnd);
                                  newEnd = newEnd.clamp(0.0, totalDurationMs);
                                  setState(() {
                                    _endValue = newEnd;
                                  });
                                  _controller.seekTo(Duration(milliseconds: _endValue.toInt()));
                                },
                                onScrub: (fraction) {
                                  final double targetMs = (fraction * totalDurationMs).clamp(_startValue, _endValue);
                                  _controller.seekTo(Duration(milliseconds: targetMs.toInt()));
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Animation FPS Selector & Stats Summary Row (Light Theme)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8EE)),
                ),
                child: Row(
                  children: [
                    // FPS Selector Label & Options
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TARGET FRAME RATE',
                            style: TextStyle(
                              color: ColorConstants.mediumText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _fpsOptions.map((fps) {
                              final bool isSelected = _selectedFps == fps;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedFps = fps;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? ColorConstants.accent : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? ColorConstants.accent : const Color(0xFFE0E0E8),
                                      ),
                                    ),
                                    child: Text(
                                      '$fps FPS',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : ColorConstants.darkText,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Frames Summary Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFDAB3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalFrames',
                            style: const TextStyle(
                              color: ColorConstants.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const Text(
                            'FRAMES',
                            style: TextStyle(
                              color: ColorConstants.darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 5. Large Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.accent,
                    elevation: 3,
                    shadowColor: ColorConstants.accent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Import $totalFrames Animation Frames',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E5EC)),
          ),
          child: Icon(icon, color: ColorConstants.darkText, size: 22),
        ),
      ),
    );
  }

  Widget _buildTimeChip({required String label, required String timeStr, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          timeStr,
          style: const TextStyle(color: ColorConstants.darkText, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

/// Custom tactile filmstrip trimmer with drag handles & live playhead needle (Light theme optimized)
class _FilmstripTrimmerWidget extends StatefulWidget {
  final double trackWidth;
  final double startFraction;
  final double endFraction;
  final double playheadFraction;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;
  final ValueChanged<double> onScrub;

  const _FilmstripTrimmerWidget({
    required this.trackWidth,
    required this.startFraction,
    required this.endFraction,
    required this.playheadFraction,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onScrub,
  });

  @override
  State<_FilmstripTrimmerWidget> createState() => _FilmstripTrimmerWidgetState();
}

class _FilmstripTrimmerWidgetState extends State<_FilmstripTrimmerWidget> {
  static const double handleWidth = 20.0;

  int _activeDrag = 0; // 0: None, 1: Start handle, 2: End handle, 3: Scrub track

  @override
  Widget build(BuildContext context) {
    final double w = widget.trackWidth;
    final double startX = widget.startFraction * w;
    final double endX = widget.endFraction * w;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        final double x = details.localPosition.dx;
        const double touchSlop = 28.0;

        // Check if touching left handle
        final bool nearLeftHandle = (x >= startX - touchSlop && x <= startX + handleWidth + touchSlop);
        // Check if touching right handle
        final bool nearRightHandle = (x >= endX - handleWidth - touchSlop && x <= endX + touchSlop);

        if (nearLeftHandle && nearRightHandle) {
          final double distLeft = (x - (startX + handleWidth / 2)).abs();
          final double distRight = (x - (endX - handleWidth / 2)).abs();
          if (distLeft <= distRight) {
            _activeDrag = 1;
          } else {
            _activeDrag = 2;
          }
          HapticFeedback.selectionClick();
        } else if (nearLeftHandle) {
          _activeDrag = 1;
          HapticFeedback.selectionClick();
        } else if (nearRightHandle) {
          _activeDrag = 2;
          HapticFeedback.selectionClick();
        } else {
          _activeDrag = 3;
          widget.onScrub((x / w).clamp(0.0, 1.0));
        }
      },
      onHorizontalDragUpdate: (details) {
        final double x = details.localPosition.dx;
        final double frac = (x / w).clamp(0.0, 1.0);

        if (_activeDrag == 1) {
          widget.onStartChanged(frac);
        } else if (_activeDrag == 2) {
          widget.onEndChanged(frac);
        } else if (_activeDrag == 3) {
          widget.onScrub(frac);
        }
      },
      onHorizontalDragEnd: (_) {
        _activeDrag = 0;
      },
      onTapDown: (details) {
        final double x = details.localPosition.dx;
        widget.onScrub((x / w).clamp(0.0, 1.0));
      },
      child: CustomPaint(
        size: Size(w, 52),
        painter: _FilmstripPainter(
          startFraction: widget.startFraction,
          endFraction: widget.endFraction,
          playheadFraction: widget.playheadFraction,
          handleWidth: handleWidth,
        ),
      ),
    );
  }
}

class _FilmstripPainter extends CustomPainter {
  final double startFraction;
  final double endFraction;
  final double playheadFraction;
  final double handleWidth;

  _FilmstripPainter({
    required this.startFraction,
    required this.endFraction,
    required this.playheadFraction,
    required this.handleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double startX = (startFraction * w).clamp(0.0, w);
    final double endX = (endFraction * w).clamp(startX + handleWidth, w);
    final double playheadX = (playheadFraction * w).clamp(0.0, w);

    // 1. Draw filmstrip background track (Dark slate for contrast with orange)
    final RRect trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(10),
    );
    final Paint trackPaint = Paint()..color = const Color(0xFF282836);
    canvas.drawRRect(trackRRect, trackPaint);

    // Draw filmstrip sprocket ticks (top and bottom)
    final Paint tickPaint = Paint()..color = Colors.white.withOpacity(0.14);
    const int numTicks = 24;
    final double tickSpacing = w / numTicks;
    for (int i = 0; i <= numTicks; i++) {
      final double tx = i * tickSpacing;
      // Top sprocket
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(tx + 2, 3, 5, 4), const Radius.circular(1)),
        tickPaint,
      );
      // Bottom sprocket
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(tx + 2, h - 7, 5, 4), const Radius.circular(1)),
        tickPaint,
      );
    }

    // 2. Dim unselected left and right regions
    final Paint dimPaint = Paint()..color = Colors.black.withOpacity(0.65);
    if (startX > 0) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, startX, h),
          topLeft: const Radius.circular(10),
          bottomLeft: const Radius.circular(10),
        ),
        dimPaint,
      );
    }
    if (endX < w) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(endX, 0, w - endX, h),
          topRight: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
        dimPaint,
      );
    }

    // 3. Selection Range Glow & Border
    final Paint borderPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(startX, 0),
        Offset(endX, 0),
        [const Color(0xFFFF9E24), const Color(0xFFFF6E00)],
      );

    // Top and bottom selection bars (spanning between the two handles)
    final double selBarWidth = (endX - startX).clamp(0.0, w);
    canvas.drawRect(Rect.fromLTWH(startX, 0, selBarWidth, 3.5), borderPaint);
    canvas.drawRect(Rect.fromLTWH(startX, h - 3.5, selBarWidth, 3.5), borderPaint);

    // 4. Left Handle (Inward facing, sits flush from startX to startX + handleWidth)
    final RRect leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTWH(startX, 0, handleWidth, h),
      topLeft: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
    );
    canvas.drawRRect(leftHandle, borderPaint);

    // Left Handle 2 White Grip lines
    final Paint gripPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final double leftMidX = startX + handleWidth / 2;
    canvas.drawLine(Offset(leftMidX - 2.5, h * 0.32), Offset(leftMidX - 2.5, h * 0.68), gripPaint);
    canvas.drawLine(Offset(leftMidX + 2.5, h * 0.32), Offset(leftMidX + 2.5, h * 0.68), gripPaint);

    // 5. Right Handle (Inward facing, sits flush from endX - handleWidth to endX)
    final RRect rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTWH(endX - handleWidth, 0, handleWidth, h),
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(rightHandle, borderPaint);

    // Right Handle 2 White Grip lines
    final double rightMidX = endX - handleWidth / 2;
    canvas.drawLine(Offset(rightMidX - 2.5, h * 0.32), Offset(rightMidX - 2.5, h * 0.68), gripPaint);
    canvas.drawLine(Offset(rightMidX + 2.5, h * 0.32), Offset(rightMidX + 2.5, h * 0.68), gripPaint);

    // 6. Playhead Needle (White glowing line)
    final Paint playheadShadow = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(playheadX, -2), Offset(playheadX, h + 2), playheadShadow);

    final Paint playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(playheadX, -2), Offset(playheadX, h + 2), playheadPaint);

    // Playhead top diamond/circle bead
    final Paint beadPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(playheadX, -1), 3.5, beadPaint);
  }

  @override
  bool shouldRepaint(covariant _FilmstripPainter oldDelegate) {
    return oldDelegate.startFraction != startFraction ||
        oldDelegate.endFraction != endFraction ||
        oldDelegate.playheadFraction != playheadFraction;
  }
}
