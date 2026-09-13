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

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  late TextEditingController _titleController;
  final AudioPlaybackService _playbackService = AudioPlaybackService();

  late int _trimStartMs;
  late int _trimEndMs;
  int _currentScrubberMs = 0;
  bool _isPlaying = false;
  Timer? _scrubberTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? widget.clip.title);
    _trimStartMs = widget.clip.trimStartMs;
    _trimEndMs = widget.clip.trimEndMs > 0 ? widget.clip.trimEndMs : widget.clip.durationMs;
    _currentScrubberMs = _trimStartMs;
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

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _playbackService.pause();
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
        trimStartMs: _currentScrubberMs,
        trimEndMs: _trimEndMs,
      );

      await _playbackService.playSingleClip(previewClip, onComplete: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentScrubberMs = _trimStartMs;
          });
        }
      });

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
            timer.cancel();
          }
        });
      });
    }
  }

  void _seekTo(int targetMs) {
    _scrubberTimer?.cancel();
    _playbackService.stopAll();
    setState(() {
      _isPlaying = false;
      _currentScrubberMs = targetMs.clamp(_trimStartMs, _trimEndMs);
    });
  }

  void _step(int deltaMs) {
    _seekTo(_currentScrubberMs + deltaMs);
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

                      return Stack(
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

                          // Left Trim Handle
                          Positioned(
                            left: (width * leftFraction - 16).clamp(0.0, width - 32),
                            top: height * 0.35,
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final double newFraction = ((width * leftFraction + details.delta.dx) / width).clamp(0.0, rightFraction - 0.05);
                                setState(() {
                                  _trimStartMs = (newFraction * totalDuration).round();
                                  _currentScrubberMs = _currentScrubberMs.clamp(_trimStartMs, _trimEndMs);
                                });
                              },
                              child: _buildTrimHandle(isLeft: true),
                            ),
                          ),

                          // Right Trim Handle
                          Positioned(
                            left: (width * rightFraction - 16).clamp(0.0, width - 32),
                            top: height * 0.35,
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final double newFraction = ((width * rightFraction + details.delta.dx) / width).clamp(leftFraction + 0.05, 1.0);
                                setState(() {
                                  _trimEndMs = (newFraction * totalDuration).round();
                                  _currentScrubberMs = _currentScrubberMs.clamp(_trimStartMs, _trimEndMs);
                                });
                              },
                              child: _buildTrimHandle(isLeft: false),
                            ),
                          ),

                          // Playhead Needle
                          Positioned(
                            left: (width * (leftFraction + scrubberFraction * (rightFraction - leftFraction)) - 1).clamp(0.0, width - 2),
                            top: 0,
                            bottom: 40,
                            child: Container(
                              width: 2,
                              color: const Color(0xFFFF9318),
                            ),
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
                      );
                    },
                  ),
                ),
              ),
            ),

            // Middle Transport Controls Row matching Image 4
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Start Trim Label & Jump Start
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFFFF9318), size: 28),
                        onPressed: () => _seekTo(_trimStartMs),
                      ),
                      Text(
                        _formatTimecode(_trimStartMs),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF9318)),
                      ),
                    ],
                  ),

                  // Middle Step Back, Play/Pause, Step Forward
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF1E1E24), size: 36),
                        onPressed: () => _step(-250),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9318),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right_rounded, color: Color(0xFF1E1E24), size: 36),
                        onPressed: () => _step(250),
                      ),
                    ],
                  ),

                  // End Trim Label & Jump End
                  Row(
                    children: [
                      Text(
                        _formatTimecode(_trimEndMs),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF9318)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFFF9318), size: 28),
                        onPressed: () => _seekTo(_trimEndMs),
                      ),
                    ],
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
                      trimStartMs: _trimStartMs,
                      trimEndMs: _trimEndMs,
                      durationMs: (_trimEndMs - _trimStartMs).clamp(100, widget.clip.durationMs),
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
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9318),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 20),
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
          final int seconds = timeAtPoint ~/ 1000;
          final int millis = (timeAtPoint % 1000) ~/ 100;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '00:${seconds.toString().padLeft(2, '0')}.$millis',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }
}
