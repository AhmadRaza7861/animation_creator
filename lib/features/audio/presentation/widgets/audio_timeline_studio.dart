import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../domain/models/audio_clip.dart';
import '../../domain/models/audio_project_state.dart';
import '../../services/audio_playback_service.dart';
import 'add_audio_bottom_sheet.dart';
import 'waveform_painter.dart';
import '../screens/audio_trimmer_screen.dart';
import '../screens/audio_library_screen.dart';

class AudioTimelineStudio extends StatefulWidget {
  final AudioProjectState audioState;
  final int currentFrameIndex;
  final int totalFrames;
  final int fps;
  final List<ui.Image?> frameThumbnails;
  final VoidCallback onToggleAudioMode;
  final void Function(int frameIndex) onFrameSelected;
  final VoidCallback onAddFrame;
  final void Function(AudioProjectState updatedState) onAudioStateChanged;

  const AudioTimelineStudio({
    super.key,
    required this.audioState,
    required this.currentFrameIndex,
    required this.totalFrames,
    required this.fps,
    required this.frameThumbnails,
    required this.onToggleAudioMode,
    required this.onFrameSelected,
    required this.onAddFrame,
    required this.onAudioStateChanged,
  });

  @override
  State<AudioTimelineStudio> createState() => _AudioTimelineStudioState();
}

class _AudioTimelineStudioState extends State<AudioTimelineStudio> {
  final AudioPlaybackService _playbackService = AudioPlaybackService();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _frameScrollController = ScrollController();

  // High-performance reactive state notifiers
  late final ValueNotifier<int> _positionNotifier;
  late final ValueNotifier<bool> _isPlayingNotifier;
  late final ValueNotifier<int> _selectedTrackIndexNotifier;
  late final ValueNotifier<String?> _selectedClipIdNotifier;
  late final ValueNotifier<int> _clipRevisionNotifier;

  int _lastDispatchedFrame = -1;

  // Pixels per second in the timeline ruler
  static const double _pixelsPerSecond = 120.0;

  @override
  void initState() {
    super.initState();
    final initialPos = (widget.currentFrameIndex / (widget.fps > 0 ? widget.fps : 9) * 1000).round();
    _positionNotifier = ValueNotifier<int>(initialPos);
    _isPlayingNotifier = ValueNotifier<bool>(false);
    _selectedTrackIndexNotifier = ValueNotifier<int>(0);
    _selectedClipIdNotifier = ValueNotifier<String?>(null);
    _clipRevisionNotifier = ValueNotifier<int>(0);
    _lastDispatchedFrame = widget.currentFrameIndex;
  }

  @override
  void didUpdateWidget(covariant AudioTimelineStudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isPlayingNotifier.value && oldWidget.currentFrameIndex != widget.currentFrameIndex) {
      final targetMs = (widget.currentFrameIndex / (widget.fps > 0 ? widget.fps : 9) * 1000).round();
      _positionNotifier.value = targetMs;
      _lastDispatchedFrame = widget.currentFrameIndex;
      _scrollToActiveFrame(widget.currentFrameIndex);
    }
    if (oldWidget.totalFrames != widget.totalFrames || oldWidget.audioState != widget.audioState) {
      _clipRevisionNotifier.value++;
    }
  }

  void _scrollToActiveFrame(int frameIdx) {
    if (_frameScrollController.hasClients) {
      final double targetOffset = (frameIdx * 56.0) - 100.0;
      final double clampedOffset = targetOffset.clamp(0.0, _frameScrollController.position.maxScrollExtent);
      _frameScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _playbackService.dispose();
    _horizontalScrollController.dispose();
    _frameScrollController.dispose();
    _positionNotifier.dispose();
    _isPlayingNotifier.dispose();
    _selectedTrackIndexNotifier.dispose();
    _selectedClipIdNotifier.dispose();
    _clipRevisionNotifier.dispose();
    super.dispose();
  }

  String _formatTimecode(int ms) {
    final int minutes = ms ~/ 60000;
    final int seconds = (ms % 60000) ~/ 1000;
    final int millis = ms % 1000;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  int get _maxTimelineMs {
    final int animationDurationMs = ((widget.totalFrames / (widget.fps > 0 ? widget.fps : 9)) * 1000).round();
    final int audioDurationMs = widget.audioState.maxDurationMs;
    final int maxMs = animationDurationMs > audioDurationMs ? animationDurationMs : audioDurationMs;
    return maxMs > 4000 ? maxMs + 2000 : 6000;
  }

  void _togglePlayPause() async {
    if (_isPlayingNotifier.value) {
      await _playbackService.pause();
      _isPlayingNotifier.value = false;
    } else {
      _isPlayingNotifier.value = true;

      await _playbackService.playTracks(
        state: widget.audioState,
        startMs: _positionNotifier.value,
        maxTimelineMs: _maxTimelineMs,
        onPositionUpdate: (posMs) {
          if (!mounted) return;
          _positionNotifier.value = posMs;

          final int frameIdx = ((posMs / 1000.0) * widget.fps).floor().clamp(0, widget.totalFrames - 1);
          if (frameIdx != _lastDispatchedFrame && frameIdx != widget.currentFrameIndex) {
            _lastDispatchedFrame = frameIdx;
            widget.onFrameSelected(frameIdx);
            _scrollToActiveFrame(frameIdx);
          }
        },
        onPlaybackComplete: () {
          if (!mounted) return;
          _isPlayingNotifier.value = false;
          _positionNotifier.value = 0;
          _lastDispatchedFrame = 0;
          widget.onFrameSelected(0);
          _scrollToActiveFrame(0);
        },
      );
    }
  }

  void _seekTo(int ms) {
    final int clamped = ms.clamp(0, _maxTimelineMs);
    _positionNotifier.value = clamped;

    final int frameIdx = ((clamped / 1000.0) * widget.fps).floor().clamp(0, widget.totalFrames - 1);
    if (frameIdx != _lastDispatchedFrame && frameIdx != widget.currentFrameIndex) {
      _lastDispatchedFrame = frameIdx;
      widget.onFrameSelected(frameIdx);
      _scrollToActiveFrame(frameIdx);
    }

    if (_isPlayingNotifier.value) {
      _playbackService.playTracks(
        state: widget.audioState,
        startMs: clamped,
        maxTimelineMs: _maxTimelineMs,
        onPositionUpdate: (posMs) {
          if (!mounted) return;
          _positionNotifier.value = posMs;
          final int f = ((posMs / 1000.0) * widget.fps).floor().clamp(0, widget.totalFrames - 1);
          if (f != _lastDispatchedFrame && f != widget.currentFrameIndex) {
            _lastDispatchedFrame = f;
            widget.onFrameSelected(f);
            _scrollToActiveFrame(f);
          }
        },
        onPlaybackComplete: () {
          if (!mounted) return;
          _isPlayingNotifier.value = false;
          _positionNotifier.value = 0;
          _lastDispatchedFrame = 0;
          widget.onFrameSelected(0);
          _scrollToActiveFrame(0);
        },
      );
    }
  }

  void _openAddAudioMenu() {
    AddAudioBottomSheet.show(
      context: context,
      defaultTrackIndex: _selectedTrackIndexNotifier.value,
      onAudioClipAdded: (clip) {
        final placedClip = clip.copyWith(
          trackIndex: _selectedTrackIndexNotifier.value,
          startOffsetMs: _positionNotifier.value,
        );
        widget.audioState.addClip(placedClip);
        _selectedClipIdNotifier.value = placedClip.id;
        _clipRevisionNotifier.value++;
        widget.onAudioStateChanged(widget.audioState);
      },
    );
  }

  void _editClip(AudioClip clip) async {
    final updated = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioTrimmerScreen(clip: clip),
      ),
    );

    if (updated != null && mounted) {
      widget.audioState.updateClip(updated);
      _clipRevisionNotifier.value++;
      widget.onAudioStateChanged(widget.audioState);
    }
  }

  void _deleteClip(AudioClip clip) {
    widget.audioState.removeClip(clip.id);
    _selectedClipIdNotifier.value = null;
    _clipRevisionNotifier.value++;
    widget.onAudioStateChanged(widget.audioState);
  }

  void _splitSelectedClip() {
    final selectedId = _selectedClipIdNotifier.value;
    if (selectedId == null) return;
    final clip = widget.audioState.findClip(selectedId);
    if (clip == null) return;

    final int needleMs = _positionNotifier.value;
    if (needleMs <= clip.startOffsetMs || needleMs >= clip.endOffsetMs) {
      Fluttertoast.showToast(
        msg: 'Position playhead inside the clip to split',
        backgroundColor: const Color(0xFF2C2D35),
        textColor: Colors.white,
      );
      return;
    }

    final int localSplitMs = clip.trimStartMs + (needleMs - clip.startOffsetMs);
    final double splitRatio = ((localSplitMs - clip.trimStartMs) / clip.trimmedDurationMs).clamp(0.05, 0.95);

    final int sampleSplitIdx = (clip.waveformSamples.length * splitRatio).round().clamp(1, clip.waveformSamples.length - 1);
    final List<double> part1Samples = clip.waveformSamples.sublist(0, sampleSplitIdx);
    final List<double> part2Samples = clip.waveformSamples.sublist(sampleSplitIdx);

    final int origTrimEnd = clip.trimEndMs;
    clip.trimEndMs = localSplitMs;
    clip.waveformSamples = part1Samples;

    final newClip = AudioClip(
      title: '${clip.title} (Part 2)',
      filePath: clip.filePath,
      trackIndex: clip.trackIndex,
      startOffsetMs: needleMs,
      durationMs: clip.durationMs,
      trimStartMs: localSplitMs,
      trimEndMs: origTrimEnd,
      volume: clip.volume,
      isMuted: clip.isMuted,
      waveformSamples: part2Samples.isNotEmpty ? part2Samples : List.generate(30, (i) => 0.4),
    );

    widget.audioState.addClip(newClip, targetTrackIndex: clip.trackIndex);
    _selectedClipIdNotifier.value = newClip.id;
    _clipRevisionNotifier.value++;
    widget.onAudioStateChanged(widget.audioState);

    Fluttertoast.showToast(
      msg: 'Audio clip split at ${_formatTimecode(needleMs)}',
      backgroundColor: const Color(0xFFFF4B72),
      textColor: Colors.white,
    );
  }

  void _duplicateSelectedClip() {
    final selectedId = _selectedClipIdNotifier.value;
    if (selectedId == null) return;
    final clip = widget.audioState.findClip(selectedId);
    if (clip == null) return;

    final newClip = AudioClip(
      title: '${clip.title} (Copy)',
      filePath: clip.filePath,
      trackIndex: clip.trackIndex,
      startOffsetMs: clip.endOffsetMs + 40,
      durationMs: clip.durationMs,
      trimStartMs: clip.trimStartMs,
      trimEndMs: clip.trimEndMs,
      volume: clip.volume,
      isMuted: clip.isMuted,
      waveformSamples: List<double>.from(clip.waveformSamples),
    );

    widget.audioState.addClip(newClip, targetTrackIndex: clip.trackIndex);
    _selectedClipIdNotifier.value = newClip.id;
    _clipRevisionNotifier.value++;
    widget.onAudioStateChanged(widget.audioState);

    Fluttertoast.showToast(
      msg: 'Audio clip duplicated',
      backgroundColor: const Color(0xFFFF4B72),
      textColor: Colors.white,
    );
  }

  void _showVolumeSlider(AudioClip clip) {
    final volumeNotifier = ValueNotifier<double>(clip.volume);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: volumeNotifier,
        builder: (context, currentVol, _) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Volume Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(currentVol * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        currentVol == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        final newVol = currentVol == 0 ? 1.0 : 0.0;
                        volumeNotifier.value = newVol;
                        clip.volume = newVol;
                        clip.isMuted = newVol == 0;
                        _clipRevisionNotifier.value++;
                        widget.onAudioStateChanged(widget.audioState);
                      },
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF4B72),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: const Color(0xFFFF4B72).withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentVol,
                          min: 0.0,
                          max: 2.0,
                          divisions: 40,
                          onChanged: (val) {
                            volumeNotifier.value = val;
                            clip.volume = val;
                            clip.isMuted = val == 0.0;
                            _clipRevisionNotifier.value++;
                          },
                          onChangeEnd: (val) {
                            widget.onAudioStateChanged(widget.audioState);
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSoundFXSelector(AudioClip clip) async {
    final sfxClip = await Navigator.push<AudioClip>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioLibraryScreen(defaultTrackIndex: clip.trackIndex),
      ),
    );

    if (sfxClip != null && mounted) {
      clip.title = sfxClip.title;
      clip.filePath = sfxClip.filePath;
      clip.durationMs = sfxClip.durationMs;
      clip.trimStartMs = 0;
      clip.trimEndMs = sfxClip.durationMs;
      clip.waveformSamples = sfxClip.waveformSamples;
      _clipRevisionNotifier.value++;
      widget.onAudioStateChanged(widget.audioState);
      Fluttertoast.showToast(
        msg: 'Updated to ${sfxClip.title}',
        backgroundColor: const Color(0xFFFF4B72),
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double timelineWidth = (_maxTimelineMs / 1000.0) * _pixelsPerSecond;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Timecode & Frame Count Display (Rebuilt ONLY when playhead moves)
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: _positionNotifier,
                          builder: (context, posMs, _) {
                            return Text(
                              _formatTimecode(posMs),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2D35),
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.totalFrames} Frames',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636366),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Transport Controls Bar (Mode, Transport, Add Audio)
          RepaintBoundary(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
              ),
              child: Row(
                children: [
                  // Audio Studio Mode Exit / Toggle button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF4B72), size: 26),
                    onPressed: widget.onToggleAudioMode,
                    tooltip: 'Back to Canvas Timeline',
                  ),

                  const Spacer(),

                  // Center Transport Controls (Prev, Play, Next)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFF1E1E24), size: 26),
                        onPressed: () => _seekTo(0),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFF0F3),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isPlayingNotifier,
                          builder: (context, isPlaying, _) {
                            return IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: const Color(0xFFFF4B72),
                                size: 22,
                              ),
                              onPressed: _togglePlayPause,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF1E1E24), size: 26),
                        onPressed: () => _seekTo(_maxTimelineMs),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Add Audio Button (+) in coral
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B72),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      onPressed: _openAddAudioMenu,
                      tooltip: 'Add Audio',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Multi-track Audio Timeline Area
          SizedBox(
            height: 240,
            child: Row(
              children: [
                // Left Column: Track Headers with Mute & Lock controls
                Container(
                  width: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFC),
                    border: Border(right: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _clipRevisionNotifier,
                    builder: (context, revision, child) {
                      return ValueListenableBuilder<int>(
                        valueListenable: _selectedTrackIndexNotifier,
                        builder: (context, selectedTrack, child) {
                          return Column(
                            children: [
                              const SizedBox(height: 28),
                              ...List.generate(widget.audioState.tracks.length, (trackIdx) {
                                final track = widget.audioState.tracks[trackIdx];
                                final isSelected = selectedTrack == trackIdx;

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      _selectedTrackIndexNotifier.value = trackIdx;
                                      _selectedClipIdNotifier.value = null;
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFFFF0F3) : Colors.transparent,
                                        border: const Border(
                                          bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Mute button
                                          GestureDetector(
                                            onTap: () {
                                              widget.audioState.toggleMute(trackIdx);
                                              _clipRevisionNotifier.value++;
                                              widget.onAudioStateChanged(widget.audioState);
                                            },
                                            child: Icon(
                                              track.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                              size: 18,
                                              color: track.isMuted
                                                  ? Colors.red
                                                  : (isSelected ? const Color(0xFFFF4B72) : const Color(0xFF6B6E7B)),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Lock button
                                          GestureDetector(
                                            onTap: () {
                                              widget.audioState.toggleLock(trackIdx);
                                              _clipRevisionNotifier.value++;
                                              widget.onAudioStateChanged(widget.audioState);
                                            },
                                            child: Icon(
                                              track.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                              size: 18,
                                              color: track.isLocked
                                                  ? const Color(0xFFFF9800)
                                                  : (isSelected ? const Color(0xFFFF4B72) : const Color(0xFF9E9EA7)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // Main Multi-Track Scrollable Timeline Lanes
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: timelineWidth + 120,
                      child: Stack(
                        children: [
                          // Time Ruler along the top (Cached in RepaintBoundary)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 28,
                            child: RepaintBoundary(
                              child: _buildTimeRuler(timelineWidth),
                            ),
                          ),

                          // Track Grid Lines & Lanes (Cached in RepaintBoundary)
                          Positioned(
                            top: 28,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: RepaintBoundary(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _selectedTrackIndexNotifier,
                                builder: (context, selectedTrack, _) {
                                  return Column(
                                    children: List.generate(widget.audioState.tracks.length, (trackIdx) {
                                      final isSelected = selectedTrack == trackIdx;

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _selectedTrackIndexNotifier.value = trackIdx;
                                            _selectedClipIdNotifier.value = null;
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFFCFCFD) : Colors.white,
                                              border: const Border(
                                                bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Render Audio Clips across tracks (Isolated to _clipRevisionNotifier & _selectedClipIdNotifier)
                          ValueListenableBuilder<int>(
                            valueListenable: _clipRevisionNotifier,
                            builder: (context, revision, child) {
                              return ValueListenableBuilder<String?>(
                                valueListenable: _selectedClipIdNotifier,
                                builder: (context, selectedClipId, child) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: widget.audioState.tracks.expand((track) {
                                      final int trackIdx = track.index;
                                      const double trackHeight = (240.0 - 28.0) / 4.0;

                                      return track.clips.map((clip) {
                                        final double clipX = (clip.startOffsetMs / 1000.0) * _pixelsPerSecond;
                                        final double clipWidth = ((clip.trimmedDurationMs / 1000.0) * _pixelsPerSecond).clamp(36.0, 4000.0);
                                        final double clipY = 28.0 + (trackIdx * trackHeight);
                                        final bool isClipSelected = selectedClipId == clip.id;
                                        final Color clipColor = isClipSelected ? const Color(0xFF00BCD4) : const Color(0xFFFF4B72);

                                        return Positioned(
                                          left: clipX,
                                          top: clipY + 3,
                                          width: clipWidth,
                                          height: trackHeight - 6,
                                          child: RepaintBoundary(
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                // Main Clip Body
                                                Positioned.fill(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _selectedTrackIndexNotifier.value = trackIdx;
                                                      _selectedClipIdNotifier.value = clip.id;
                                                    },
                                                    onDoubleTap: () => _editClip(clip),
                                                    onLongPress: () => _showClipOptionsMenu(clip),
                                                    onHorizontalDragUpdate: track.isLocked
                                                        ? null
                                                        : (details) {
                                                            final double currentX = (clip.startOffsetMs / 1000.0) * _pixelsPerSecond;
                                                            final double newX = (currentX + details.delta.dx).clamp(0.0, timelineWidth);
                                                            final int newOffsetMs = ((newX / _pixelsPerSecond) * 1000).round();
                                                            if (newOffsetMs != clip.startOffsetMs) {
                                                              clip.startOffsetMs = newOffsetMs;
                                                              _clipRevisionNotifier.value++;
                                                            }
                                                          },
                                                    onHorizontalDragEnd: (details) {
                                                      widget.onAudioStateChanged(widget.audioState);
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: clipColor,
                                                        borderRadius: BorderRadius.circular(isClipSelected ? 4 : 8),
                                                        border: Border.all(
                                                          color: isClipSelected ? Colors.white : const Color(0xFFD81B60),
                                                          width: isClipSelected ? 1.5 : 1.0,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: clipColor.withValues(alpha: 0.35),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          // Waveform
                                                          Positioned.fill(
                                                            child: Padding(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: isClipSelected ? 14.0 : 4.0,
                                                                vertical: 2.0,
                                                              ),
                                                              child: CustomPaint(
                                                                painter: WaveformPainter(
                                                                  samples: clip.waveformSamples,
                                                                  waveColor: Colors.white.withValues(alpha: 0.85),
                                                                  playedColor: Colors.white,
                                                                  barWidth: 2.0,
                                                                  barGap: 1.0,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Title Badge
                                                          Positioned(
                                                            top: 2,
                                                            left: isClipSelected ? 14 : 4,
                                                            child: Text(
                                                              clip.title,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // White Trim Handle - Left (Start Trim)
                                                if (isClipSelected && !track.isLocked)
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    width: 14,
                                                    child: GestureDetector(
                                                      onHorizontalDragUpdate: (details) {
                                                        final int deltaMs = ((details.delta.dx / _pixelsPerSecond) * 1000).round();
                                                        if (deltaMs == 0) return;
                                                        final int newTrimStart = (clip.trimStartMs + deltaMs).clamp(0, clip.trimEndMs - 200);
                                                        final int actualShift = newTrimStart - clip.trimStartMs;
                                                        clip.trimStartMs = newTrimStart;
                                                        clip.startOffsetMs = (clip.startOffsetMs + actualShift).clamp(0, _maxTimelineMs);
                                                        _clipRevisionNotifier.value++;
                                                      },
                                                      onHorizontalDragEnd: (details) {
                                                        widget.onAudioStateChanged(widget.audioState);
                                                      },
                                                      child: Container(
                                                        decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black26,
                                                              blurRadius: 2,
                                                              offset: Offset(-1, 0),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: Container(
                                                            width: 2,
                                                            height: 12,
                                                            color: const Color(0xFF6B6E7B),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                // White Trim Handle - Right (End Trim)
                                                if (isClipSelected && !track.isLocked)
                                                  Positioned(
                                                    right: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    width: 14,
                                                    child: GestureDetector(
                                                      onHorizontalDragUpdate: (details) {
                                                        final int deltaMs = ((details.delta.dx / _pixelsPerSecond) * 1000).round();
                                                        if (deltaMs == 0) return;
                                                        clip.trimEndMs = (clip.trimEndMs + deltaMs).clamp(clip.trimStartMs + 200, clip.durationMs);
                                                        _clipRevisionNotifier.value++;
                                                      },
                                                      onHorizontalDragEnd: (details) {
                                                        widget.onAudioStateChanged(widget.audioState);
                                                      },
                                                      child: Container(
                                                        decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black26,
                                                              blurRadius: 2,
                                                              offset: Offset(1, 0),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: Container(
                                                            width: 2,
                                                            height: 12,
                                                            color: const Color(0xFF6B6E7B),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                    }).toList(),
                                  );
                                },
                              );
                            },
                          ),

                          // Playhead Scrubber Needle (Rebuilt ONLY via _positionNotifier)
                          ValueListenableBuilder<int>(
                            valueListenable: _positionNotifier,
                            builder: (context, posMs, _) {
                              final double playheadX = (posMs / 1000.0) * _pixelsPerSecond;

                              return Positioned(
                                left: playheadX - 6,
                                top: 0,
                                bottom: 0,
                                child: RepaintBoundary(
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (details) {
                                      final double newX = (playheadX + details.delta.dx).clamp(0.0, timelineWidth);
                                      final int newMs = ((newX / _pixelsPerSecond) * 1000).round();
                                      _seekTo(newMs);
                                    },
                                    child: Column(
                                      children: [
                                        // Top Triangle Pointer Indicator
                                        CustomPaint(
                                          size: const Size(12, 10),
                                          painter: _PlayheadTrianglePainter(color: const Color(0xFFFF4B72)),
                                        ),
                                        // Vertical Line Needle
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: const Color(0xFFFF4B72),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Area: Contextual Audio Action Toolbar (when clip is selected) OR Animation Frame Strip
          ValueListenableBuilder<String?>(
            valueListenable: _selectedClipIdNotifier,
            builder: (context, selectedClipId, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _clipRevisionNotifier,
                builder: (context, revision, child) {
                  final clip = selectedClipId != null ? widget.audioState.findClip(selectedClipId) : null;
                  return clip != null ? _buildAudioActionToolbar(clip) : _buildAnimationFrameStrip();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioActionToolbar(AudioClip clip) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24),
        border: Border(top: BorderSide(color: Color(0xFF2C2D35), width: 1)),
      ),
      child: Row(
        children: [
          // 1. Collapse / Back Button (<<)
          GestureDetector(
            onTap: () {
              _selectedClipIdNotifier.value = null;
            },
            child: Container(
              width: 42,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B33),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          Container(
            width: 1,
            height: 28,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),

          // Action 1: Sound FX (Star)
          _buildActionButton(
            icon: Icons.star_border_rounded,
            label: 'Sound FX',
            onTap: () => _openSoundFXSelector(clip),
          ),

          // Action 2: Split (][)
          _buildActionButton(
            iconWidget: const SizedBox(
              height: 22,
              child: Center(
                child: Text(
                  '][',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ),
            label: 'Split',
            onTap: _splitSelectedClip,
          ),

          // Action 3: Volume (Speaker)
          _buildActionButton(
            icon: Icons.volume_up_outlined,
            label: 'Volume',
            onTap: () => _showVolumeSlider(clip),
          ),

          // Action 4: Duplicate (Copy)
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Duplicate',
            onTap: _duplicateSelectedClip,
          ),

          // Action 5: Delete (Trash)
          _buildActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            isDestructive: true,
            onTap: () => _deleteClip(clip),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget ??
                    Icon(
                      icon,
                      color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
                      size: 22,
                    ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationFrameStrip() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F6F9),
        border: Border(top: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _frameScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.frameThumbnails.length,
              itemBuilder: (context, index) {
                final isSelected = index == widget.currentFrameIndex;
                final image = widget.frameThumbnails[index];

                return GestureDetector(
                  onTap: () {
                    widget.onFrameSelected(index);
                    final int targetMs = ((index / (widget.fps > 0 ? widget.fps : 9)) * 1000).round();
                    _seekTo(targetMs);
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF4B72) : const Color(0xFFD4D5DC),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (image != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: RawImage(
                                image: image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        // Frame Number Badge
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF4B72) : Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
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
          // Add Frame Button
          GestureDetector(
            onTap: widget.onAddFrame,
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(left: 6, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFC8C9D2),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF2C2D35), size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRuler(double width) {
    final int totalSeconds = (_maxTimelineMs / 1000.0).ceil();

    return Container(
      color: const Color(0xFFF9F9FB),
      child: Stack(
        children: List.generate(totalSeconds + 1, (sec) {
          final double x = sec * _pixelsPerSecond;
          return Positioned(
            left: x,
            top: 0,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.black.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    '00:${sec.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showClipOptionsMenu(AudioClip clip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: Color(0xFFFF4B72)),
              title: const Text('Trim & Edit Waveform'),
              onTap: () {
                Navigator.pop(context);
                _editClip(clip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Audio Clip', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteClip(clip);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayheadTrianglePainter extends CustomPainter {
  final Color color;

  _PlayheadTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayheadTrianglePainter oldDelegate) => false;
}
