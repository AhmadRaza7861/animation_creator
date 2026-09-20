import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/audio_clip.dart';
import '../../services/audio_playback_service.dart';
import '../widgets/waveform_painter.dart';

class AudioTrimmerScreen extends StatefulWidget {
  final AudioClip clip;
  final String? initialTitle;

  const AudioTrimmerScreen({
    super.key,
    required this.clip,
    this.initialTitle,
  });

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

enum _TrimmerDragTarget {
  none,
  leftHandle,
  rightHandle,
  scrubber,
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  late TextEditingController _titleController;
  final AudioPlaybackService _playbackService = AudioPlaybackService();

  late int _trimStartMs;
  late int _trimEndMs;
  int _currentScrubberMs = 0;
  bool _isPlaying = false;
  Timer? _scrubberTimer;
  _TrimmerDragTarget _activeDragTarget = _TrimmerDragTarget.none;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? widget.clip.title,
    );
    _trimStartMs = widget.clip.trimStartMs;
    _trimEndMs =
        widget.clip.trimEndMs > 0
            ? widget.clip.trimEndMs
            : widget.clip.durationMs;
    _currentScrubberMs = _trimStartMs;

    _ensureAccurateDuration();
  }

  void _ensureAccurateDuration() async {
    if (widget.clip.filePath.isNotEmpty &&
        (widget.clip.durationMs <= 0 ||
            widget.clip.waveformSamples.isEmpty ||
            widget.clip.durationMs == 3000)) {
      final actualDur = await AudioPlaybackService.getAudioDurationMs(
        widget.clip.filePath,
      );
      List<double> samples = widget.clip.waveformSamples;
      if (samples.isEmpty || samples.length <= 10) {
        samples = await AudioPlaybackService.extractWaveform(
          widget.clip.filePath,
        );
      }
      if (mounted && actualDur > 0) {
        setState(() {
          final bool wasFullTrim =
              _trimEndMs == widget.clip.durationMs || _trimEndMs <= 0;
          widget.clip.durationMs = actualDur;
          widget.clip.waveformSamples = samples;
          if (wasFullTrim || _trimEndMs > actualDur) {
            _trimEndMs = actualDur;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrubberTimer?.cancel();
    _playbackService.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatTimecode(int ms) {
    final int minutes = ms ~/ 60000;
    final int seconds = (ms % 60000) ~/ 1000;
    final int millis = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  String _formatCompactTimecode(int ms) {
    final int minutes = ms ~/ 60000;
    final int seconds = (ms % 60000) ~/ 1000;
    final int tenths = (ms % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  void _startScrubberTimer() {
    _scrubberTimer?.cancel();
    _scrubberTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isPlaying || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentScrubberMs += 33;
        if (_currentScrubberMs >= _trimEndMs) {
          _isPlaying = false;
          _currentScrubberMs = _trimStartMs;
          _playbackService.stopSingleClip();
          timer.cancel();
        }
      });
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _playbackService.pauseSingleClip();
      _scrubberTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_currentScrubberMs >= _trimEndMs) {
        _currentScrubberMs = _trimStartMs;
      }

      setState(() {
        _isPlaying = true;
      });

      final previewClip = widget.clip.copyWith(
        trimStartMs: _trimStartMs,
        trimEndMs: _trimEndMs,
      );

      await _playbackService.playSingleClip(
        previewClip,
        customStartMs: _currentScrubberMs,
        onComplete: () {
          if (mounted) {
            _scrubberTimer?.cancel();
            setState(() {
              _isPlaying = false;
              _currentScrubberMs = _trimStartMs;
            });
          }
        },
      );

      _startScrubberTimer();
    }
  }

  void _seekTo(int targetMs) {
    final int clamped = targetMs.clamp(_trimStartMs, _trimEndMs);
    setState(() {
      _currentScrubberMs = clamped;
    });

    if (_isPlaying) {
      _playbackService.seekSingleClip(clamped);
      _startScrubberTimer();
    }
  }

  void _step(int direction, int totalDuration) {
    final int stepSize = (totalDuration < 2000) ? 50 : (totalDuration < 10000 ? 100 : 250);
    _seekTo(_currentScrubberMs + (direction > 0 ? stepSize : -stepSize));
  }

  @override
  Widget build(BuildContext context) {
    final int totalDuration = widget.clip.durationMs > 0 ? widget.clip.durationMs : 1000;
    final double leftFraction = (_trimStartMs / totalDuration).clamp(0.0, 1.0);
    final double rightFraction = (_trimEndMs / totalDuration).clamp(0.0, 1.0);
    final double scrubberFraction = ((_currentScrubberMs - _trimStartMs) / (_trimEndMs - _trimStartMs > 0 ? _trimEndMs - _trimStartMs : 1)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E1E24)),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Recording Name',
            isDense: true,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Timeline Waveform Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double height = constraints.maxHeight;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) {
                          final double touchX = details.localPosition.dx;
                          final double leftHandleX = width * leftFraction;
                          final double rightHandleX = width * rightFraction;
                          final double needleX = width * (_currentScrubberMs / totalDuration);

                          const double handleHitRadius = 44.0; // Wide 88px touch radius
                          const double needleHitRadius = 28.0;

                          final double distToLeft = (touchX - leftHandleX).abs();
                          final double distToRight = (touchX - rightHandleX).abs();
                          final double distToNeedle = (touchX - needleX).abs();

                          if (distToLeft <= handleHitRadius && distToLeft <= distToRight) {
                            _activeDragTarget = _TrimmerDragTarget.leftHandle;
                          } else if (distToRight <= handleHitRadius) {
                            _activeDragTarget = _TrimmerDragTarget.rightHandle;
                          } else if (distToNeedle <= needleHitRadius) {
                            _activeDragTarget = _TrimmerDragTarget.scrubber;
                          } else {
                            // Touch anywhere on the waveform instantly seeks and scrubs without stopping audio
                            _activeDragTarget = _TrimmerDragTarget.scrubber;
                            final double fraction = (touchX / width).clamp(0.0, 1.0);
                            final int targetMs = (fraction * totalDuration).round().clamp(_trimStartMs, _trimEndMs);
                            _seekTo(targetMs);
                          }
                        },
                        onPanUpdate: (details) {
                          if (_activeDragTarget == _TrimmerDragTarget.none) return;

                          final double touchX = details.localPosition.dx;
                          const int minDurationMs = 100;

                          if (_activeDragTarget == _TrimmerDragTarget.leftHandle) {
                            final double maxAllowedX = width * ((_trimEndMs - minDurationMs) / totalDuration);
                            final double clampedX = touchX.clamp(0.0, maxAllowedX.clamp(0.0, width));
                            final int newStart = ((clampedX / width) * totalDuration).round().clamp(0, _trimEndMs - minDurationMs);
                            setState(() {
                              _trimStartMs = newStart;
                              _currentScrubberMs = _currentScrubberMs.clamp(_trimStartMs, _trimEndMs);
                            });
                            if (_isPlaying) {
                              _playbackService.seekSingleClip(_currentScrubberMs);
                            }
                          } else if (_activeDragTarget == _TrimmerDragTarget.rightHandle) {
                            final double minAllowedX = width * ((_trimStartMs + minDurationMs) / totalDuration);
                            final double clampedX = touchX.clamp(minAllowedX.clamp(0.0, width), width);
                            final int newEnd = ((clampedX / width) * totalDuration).round().clamp(_trimStartMs + minDurationMs, totalDuration);
                            setState(() {
                              _trimEndMs = newEnd;
                              _currentScrubberMs = _currentScrubberMs.clamp(_trimStartMs, _trimEndMs);
                            });
                            if (_isPlaying) {
                              _playbackService.seekSingleClip(_currentScrubberMs);
                            }
                          } else if (_activeDragTarget == _TrimmerDragTarget.scrubber) {
                            final double fraction = (touchX / width).clamp(0.0, 1.0);
                            final int targetMs = (fraction * totalDuration).round();
                            _seekTo(targetMs);
                          }
                        },
                        onPanEnd: (_) {
                          _activeDragTarget = _TrimmerDragTarget.none;
                        },
                        onPanCancel: () {
                          _activeDragTarget = _TrimmerDragTarget.none;
                        },
                        child: Stack(
                          children: [
                            // Time ruler along the top
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 28,
                              child: _buildRuler(width, totalDuration),
                            ),

                            // Waveform visualizer
                            Positioned(
                              top: 32,
                              bottom: 40,
                              left: 0,
                              right: 0,
                              child: CustomPaint(
                                painter: WaveformPainter(
                                  samples: widget.clip.waveformSamples,
                                  waveColor: const Color(0xFFFF9318),
                                  playedColor: const Color(0xFFE07C0A),
                                  progress: scrubberFraction,
                                ),
                              ),
                            ),

                            // Left Dimmed Mask (before trimStart)
                            Positioned(
                              top: 28,
                              bottom: 40,
                              left: 0,
                              width: width * leftFraction,
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),

                            // Right Dimmed Mask (after trimEnd)
                            Positioned(
                              top: 28,
                              bottom: 40,
                              left: width * rightFraction,
                              right: 0,
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),

                            // Playhead Needle
                            Positioned(
                              left: (width * (_currentScrubberMs / totalDuration) - 1.5).clamp(0.0, width - 3.0),
                              top: 0,
                              bottom: 40,
                              child: Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9318),
                                  borderRadius: BorderRadius.circular(1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9318).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Left Trim Handle
                            Positioned(
                              left: (width * leftFraction - 17).clamp(0.0, width - 34),
                              top: height * 0.30,
                              child: _buildTrimHandle(isLeft: true),
                            ),

                            // Right Trim Handle
                            Positioned(
                              left: (width * rightFraction - 17).clamp(0.0, width - 34),
                              top: height * 0.30,
                              child: _buildTrimHandle(isLeft: false),
                            ),

                            // Current Time Pill in bottom center of waveform card
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F5F8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatTimecode(_currentScrubberMs),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF2C2D35),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Middle Transport Controls Row matching Image 4
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Start Trim Label & Jump Start
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _seekTo(_trimStartMs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.skip_previous_rounded, color: Color(0xFFFF9318), size: 24),
                          const SizedBox(width: 2),
                          Text(
                            _formatCompactTimecode(_trimStartMs),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFF9318)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Middle Step Back, Play/Pause, Step Forward
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF1E1E24), size: 32),
                        onPressed: () => _step(-1, totalDuration),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9318),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.arrow_right_rounded, color: Color(0xFF1E1E24), size: 32),
                        onPressed: () => _step(1, totalDuration),
                      ),
                    ],
                  ),

                  // End Trim Label & Jump End
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _seekTo(_trimEndMs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCompactTimecode(_trimEndMs),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFF9318)),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.skip_next_rounded, color: Color(0xFFFF9318), size: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Large "Add to timeline" Button matching Image 4
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final trimmedClip = widget.clip.copyWith(
                      title: _titleController.text.trim().isNotEmpty
                          ? _titleController.text.trim()
                          : widget.clip.title,
                      durationMs: widget.clip.durationMs,
                      trimStartMs: _trimStartMs,
                      trimEndMs: _trimEndMs,
                      waveformSamples: widget.clip.waveformSamples,
                      fadeInMs: widget.clip.fadeInMs,
                      fadeOutMs: widget.clip.fadeOutMs,
                    );
                    Navigator.pop(context, trimmedClip);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9318),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Add to timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimHandle({required bool isLeft}) {
    return Container(
      width: 34,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9318),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9318).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildRuler(double width, int totalMs) {
    return Container(
      color: const Color(0xFFFAFAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final int timeAtPoint = ((index / 4) * totalMs).round();
          final int minutes = timeAtPoint ~/ 60000;
          final int seconds = (timeAtPoint % 60000) ~/ 1000;
          final int millis = (timeAtPoint % 1000) ~/ 100;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$millis',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }
}
