import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import 'video_processing_screen.dart';

class VideoTrimmingScreen extends StatefulWidget {
  final File videoFile;

  const VideoTrimmingScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmingScreen> createState() => _VideoTrimmingScreenState();
}

class _VideoTrimmingScreenState extends State<VideoTrimmingScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  double _startValue = 0.0;
  double _endValue = 0.0;
  final double _minDurationMs = 1000.0; // 1 second minimum

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: ColorConstants.background,
        body: Center(child: CircularProgressIndicator(color: ColorConstants.accent)),
      );
    }

    final durationMillis = _controller.value.duration.inMilliseconds.toDouble();

    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ColorConstants.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Video import', style: TextStyle(color: ColorConstants.darkText, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: const Text('Confirm', style: TextStyle(color: ColorConstants.darkText, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                // Top right timestamp badges
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(_controller.value.duration),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                          child: const Text('30 fps', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
                // Bottom center active playhead timestamp
                Positioned(
                  bottom: -15,
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0,-2))]
                        ),
                        child: Text(
                          _formatDuration(value.position),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Playback controls row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, size: 28), color: ColorConstants.darkText, onPressed: () {
                  _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
                }),
                IconButton(icon: const Icon(Icons.fast_rewind, size: 28), color: ColorConstants.darkText, onPressed: () {
                  _controller.seekTo(Duration(milliseconds: (_controller.value.position.inMilliseconds - 1000).clamp(_startValue.toInt(), _endValue.toInt())));
                }),
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return IconButton(
                      icon: Icon(value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 36), 
                      color: ColorConstants.darkText,
                      onPressed: () {
                        value.isPlaying ? _controller.pause() : _controller.play();
                      }
                    );
                  }
                ),
                IconButton(icon: const Icon(Icons.fast_forward, size: 28), color: ColorConstants.darkText, onPressed: () {
                  _controller.seekTo(Duration(milliseconds: (_controller.value.position.inMilliseconds + 1000).clamp(_startValue.toInt(), _endValue.toInt())));
                }),
                IconButton(icon: const Icon(Icons.skip_next, size: 28), color: ColorConstants.darkText, onPressed: () {
                  _controller.seekTo(Duration(milliseconds: _endValue.toInt()));
                }),
              ],
            ),
          ),
          
          // Timeline trimmer section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const double sliderPad = 24.0;
                    final double trackWidth = constraints.maxWidth - (sliderPad * 2);
                    
                    double startPercent = durationMillis > 0 ? (_startValue / durationMillis) : 0;
                    double endPercent = durationMillis > 0 ? (_endValue / durationMillis) : 1;
                    
                    final double startPos = sliderPad + (startPercent * trackWidth);
                    final double endPos = sliderPad + (endPercent * trackWidth);

                    return SizedBox(
                      height: 30,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: startPos - 20, 
                            bottom: 0,
                            child: Column(
                              children: [
                                Text(_formatDuration(Duration(milliseconds: _startValue.toInt())), style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Container(width: 1, height: 6, color: Colors.grey[300]), // tick mark pointing down
                              ],
                            ),
                          ),
                          Positioned(
                            left: endPos - 20,
                            bottom: 0,
                            child: Column(
                              children: [
                                Text(_formatDuration(Duration(milliseconds: _endValue.toInt())), style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Container(width: 1, height: 6, color: Colors.grey[300]), // tick mark pointing down
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 20,
                    activeTrackColor: ColorConstants.accent.withValues(alpha: 0.5),
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: ColorConstants.accent,
                    overlayColor: ColorConstants.accent.withValues(alpha: 0.2),
                  ),
                  child: RangeSlider(
                    values: RangeValues(_startValue, _endValue),
                    min: 0.0,
                    max: durationMillis > 0 ? durationMillis : 100.0,
                    onChanged: (values) {
                      double newStart = values.start;
                      double newEnd = values.end;

                      // Enforce minimum duration overlap boundary limit safely
                      final double limit = _minDurationMs < durationMillis ? _minDurationMs : durationMillis;

                      if (newEnd - newStart < limit) {
                        if (newStart != _startValue) {
                           newStart = newEnd - limit;
                           if (newStart < 0) {
                             newStart = 0;
                             newEnd = limit;
                           }
                        } else {
                           newEnd = newStart + limit;
                           if (newEnd > durationMillis) {
                             newEnd = durationMillis;
                             newStart = durationMillis - limit;
                           }
                        }
                      }

                      setState(() {
                        _startValue = newStart;
                        _endValue = newEnd;
                      });
                      
                      if (newStart != _startValue) {
                        _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
                      } else {
                        _controller.seekTo(Duration(milliseconds: _endValue.toInt()));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorConstants.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${((_endValue - _startValue) / 1000 * 10).round()} Frames Selected",
                      style: const TextStyle(color: ColorConstants.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
