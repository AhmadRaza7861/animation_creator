import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  final String filePath;
  final String format; // 'MP4' or 'GIF'
  final int fps;

  const FullscreenPlayerScreen({
    super.key,
    required this.filePath,
    required this.format,
    required this.fps,
  });

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // GIF playback fallback state
  bool _isGif = false;
  bool _isGifPlaying = true;

  @override
  void initState() {
    super.initState();
    _isGif = widget.format.toUpperCase() == 'GIF' || widget.filePath.toLowerCase().endsWith('.gif');

    if (!_isGif) {
      _initVideoPlayer();
    } else {
      _isInitialized = true;
    }

    _startHideControlsTimer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      final file = File(widget.filePath);
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      await _videoController!.play();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && (_videoController?.value.isPlaying ?? _isGifPlaying)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _seekRelative(int seconds) {
    if (_videoController == null || !_isInitialized) return;
    final current = _videoController!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _videoController!.value.duration.inMilliseconds),
    );
    _videoController!.seekTo(clamped);
    _startHideControlsTimer();
  }

  void _stepFrame(bool forward) {
    if (_videoController == null || !_isInitialized) return;
    final int frameDurationMs = (1000 / widget.fps).round();
    final current = _videoController!.value.position;
    final delta = forward ? frameDurationMs : -frameDurationMs;
    final target = current + Duration(milliseconds: delta);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _videoController!.value.duration.inMilliseconds),
    );
    _videoController!.seekTo(clamped);
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    final Duration currentPos = _videoController?.value.position ?? Duration.zero;
    final Duration totalDuration = _videoController?.value.duration ?? Duration.zero;
    final bool isPlaying = _videoController?.value.isPlaying ?? _isGifPlaying;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Content
              Center(
                child: _isGif
                    ? Image.file(
                        File(widget.filePath),
                        fit: BoxFit.contain,
                      )
                    : (_isInitialized && _videoController != null
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(color: Colors.white)),
              ),

              // Controls Overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Bar: Close Button
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Center Playback Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Step Back Frame
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                              onPressed: () => _stepFrame(false),
                            ),
                            const SizedBox(width: 8),

                            // 2. Replay 5s
                            IconButton(
                              iconSize: 36,
                              icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                              onPressed: () => _seekRelative(-5),
                            ),
                            const SizedBox(width: 14),

                            // 3. Central Play / Pause Button
                            GestureDetector(
                              onTap: () {
                                if (!_isGif && _videoController != null) {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                } else {
                                  setState(() {
                                    _isGifPlaying = !_isGifPlaying;
                                  });
                                }
                                _startHideControlsTimer();
                              },
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black87,
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 4. Forward 10s
                            IconButton(
                              iconSize: 36,
                              icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                              onPressed: () => _seekRelative(10),
                            ),
                            const SizedBox(width: 8),

                            // 5. Step Forward Frame
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                              onPressed: () => _stepFrame(true),
                            ),
                          ],
                        ),

                        // Bottom Seek Bar and Time
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isGif && _videoController != null && totalDuration.inMilliseconds > 0)
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white30,
                                    thumbColor: Colors.white,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    trackHeight: 3.0,
                                  ),
                                  child: Slider(
                                    value: currentPos.inMilliseconds.clamp(0, totalDuration.inMilliseconds).toDouble(),
                                    min: 0.0,
                                    max: totalDuration.inMilliseconds.toDouble(),
                                    onChanged: (val) {
                                      _videoController!.seekTo(Duration(milliseconds: val.toInt()));
                                      _startHideControlsTimer();
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_formatDuration(currentPos)} · ${_formatDuration(totalDuration)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                      onPressed: () {
                                        // Settings options (looping toggle, speed)
                                      },
                                    ),
                                  ],
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
  }
}
