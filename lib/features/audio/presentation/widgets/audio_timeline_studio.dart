import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../domain/models/audio_clip.dart';
import '../../domain/models/audio_project_state.dart';
import '../../services/audio_playback_service.dart';
import 'add_audio_bottom_sheet.dart';
import 'waveform_painter.dart';
import '../screens/audio_trimmer_screen.dart';
import '../screens/audio_library_screen.dart';
import '../screens/audio_recorder_screen.dart';
import '../screens/voice_maker_screen.dart';

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
  final ScrollController _leftHeadersVerticalScrollController = ScrollController();
  final ScrollController _lanesVerticalScrollController = ScrollController();

  // High-performance reactive state notifiers
  late final ValueNotifier<int> _positionNotifier;
  late final ValueNotifier<bool> _isPlayingNotifier;
  late final ValueNotifier<int> _selectedTrackIndexNotifier;
  late final ValueNotifier<String?> _selectedClipIdNotifier;
  late final ValueNotifier<int> _clipRevisionNotifier;
  late final ValueNotifier<bool> _isDraggingTimelineObjectNotifier;

  int _lastDispatchedFrame = -1;

  // Pixels per second in the timeline ruler
  static const double _pixelsPerSecond = 120.0;
  static const double _trackHeight = 52.0;

  // Pointer drag tracking for moving clips across tracks & time
  String? _draggingClipId;
  double _dragStartPointerX = 0.0;
  double _dragStartPointerY = 0.0;
  int _dragStartClipOffsetMs = 0;
  int _dragStartClipTrack = 0;
  bool _hasMovedClip = false;

  // Pointer drag tracking for trim handles
  double _handleStartPointerX = 0.0;
  int _handleStartTrimStartMs = 0;
  int _handleStartTrimEndMs = 0;
  int _handleStartOffsetMs = 0;

  // Pointer drag tracking for scrubber needle
  double _scrubberStartPointerX = 0.0;
  int _scrubberStartPosMs = 0;

  @override
  void initState() {
    super.initState();
    final initialPos = (widget.currentFrameIndex / (widget.fps > 0 ? widget.fps : 9) * 1000).round();
    _positionNotifier = ValueNotifier<int>(initialPos);
    _isPlayingNotifier = ValueNotifier<bool>(false);
    _selectedTrackIndexNotifier = ValueNotifier<int>(0);
    _selectedClipIdNotifier = ValueNotifier<String?>(null);
    _clipRevisionNotifier = ValueNotifier<int>(0);
    _isDraggingTimelineObjectNotifier = ValueNotifier<bool>(false);
    _lastDispatchedFrame = widget.currentFrameIndex;

    // Synchronize vertical scrolling between left track headers and right timeline lanes
    _leftHeadersVerticalScrollController.addListener(() {
      if (_lanesVerticalScrollController.hasClients &&
          _lanesVerticalScrollController.offset != _leftHeadersVerticalScrollController.offset) {
        _lanesVerticalScrollController.jumpTo(_leftHeadersVerticalScrollController.offset);
      }
    });

    _lanesVerticalScrollController.addListener(() {
      if (_leftHeadersVerticalScrollController.hasClients &&
          _leftHeadersVerticalScrollController.offset != _lanesVerticalScrollController.offset) {
        _leftHeadersVerticalScrollController.jumpTo(_lanesVerticalScrollController.offset);
      }
    });
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
    _leftHeadersVerticalScrollController.dispose();
    _lanesVerticalScrollController.dispose();
    _positionNotifier.dispose();
    _isPlayingNotifier.dispose();
    _selectedTrackIndexNotifier.dispose();
    _selectedClipIdNotifier.dispose();
    _clipRevisionNotifier.dispose();
    _isDraggingTimelineObjectNotifier.dispose();
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

  void _addNewTrack() {
    final newTrack = widget.audioState.addTrack();
    _selectedTrackIndexNotifier.value = newTrack.index;
    _clipRevisionNotifier.value++;
    widget.onAudioStateChanged(widget.audioState);
    Fluttertoast.showToast(
      msg: 'Added Track ${newTrack.index + 1} (T${newTrack.index + 1})',
      backgroundColor: const Color(0xFFFF9318),
      textColor: Colors.white,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_leftHeadersVerticalScrollController.hasClients) {
        _leftHeadersVerticalScrollController.animateTo(
          _leftHeadersVerticalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openAddAudioMenu({int? targetTrackIndex, int? targetPositionMs}) async {
    final int maxTrack = widget.audioState.tracks.length - 1;
    final int track = (targetTrackIndex ?? _selectedTrackIndexNotifier.value).clamp(0, maxTrack > 0 ? maxTrack : 0);
    final int posMs = (targetPositionMs ?? _positionNotifier.value).clamp(0, _maxTimelineMs);

    final source = await AddAudioBottomSheet.show(
      context: context,
      defaultTrackIndex: track,
    );

    if (source == null || !mounted) return;

    AudioClip? newClip;
    switch (source) {
      case AudioAddSource.voiceMaker:
        newClip = await Navigator.push<AudioClip>(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceMakerScreen(defaultTrackIndex: track),
          ),
        );
        break;
      case AudioAddSource.library:
        newClip = await Navigator.push<AudioClip>(
          context,
          MaterialPageRoute(
            builder: (context) => AudioLibraryScreen(defaultTrackIndex: track),
          ),
        );
        break;
      case AudioAddSource.recorder:
        newClip = await Navigator.push<AudioClip>(
          context,
          MaterialPageRoute(
            builder: (context) => AudioRecorderScreen(defaultTrackIndex: track),
          ),
        );
        break;
      case AudioAddSource.filePicker:
        newClip = await _pickAudioFile(track);
        break;
    }

    if (newClip != null && mounted) {
      final placedClip = newClip.copyWith(
        trackIndex: track,
        startOffsetMs: posMs,
      );
      widget.audioState.addClip(placedClip, targetTrackIndex: track);
      _selectedClipIdNotifier.value = placedClip.id;
      _selectedTrackIndexNotifier.value = track;
      _clipRevisionNotifier.value++;
      widget.onAudioStateChanged(widget.audioState);
    }
  }

  Future<AudioClip?> _pickAudioFile(int targetTrackIndex) async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
      );

      if (result.isNotEmpty && result.first.path != null && mounted) {
        final pickedFile = result.first;
        final file = File(pickedFile.path!);
        final clip = AudioClip(
          title: pickedFile.name.split('.').first,
          filePath: file.path,
          trackIndex: targetTrackIndex,
          durationMs: 3000,
        );

        return await Navigator.push<AudioClip>(
          context,
          MaterialPageRoute(
            builder: (context) => AudioTrimmerScreen(clip: clip),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
    return null;
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
      backgroundColor: const Color(0xFFFF9318),
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
      backgroundColor: const Color(0xFFFF9318),
      textColor: Colors.white,
    );
  }

  void _showVolumeSlider(AudioClip clip) {
    final volumeNotifier = ValueNotifier<double>(clip.volume);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: volumeNotifier,
        builder: (context, currentVol, _) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top drag pill
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Volume Control',
                        style: TextStyle(
                          color: Color(0xFF1E1E24),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9318),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          currentVol == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                          color: const Color(0xFF6B6E7B),
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
                            activeTrackColor: const Color(0xFFFF9318),
                            inactiveTrackColor: const Color(0xFFEBEBF0),
                            thumbColor: const Color(0xFFFF9318),
                            overlayColor: const Color(0xFFFF9318).withValues(alpha: 0.15),
                            trackHeight: 4,
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
                      const Icon(Icons.volume_up_rounded, color: Color(0xFF6B6E7B)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
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
        backgroundColor: const Color(0xFFFF9318),
        textColor: Colors.white,
      );
    }
  }

  void _showTrackSelectionMenu(AudioClip clip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Move to Track',
                            style: TextStyle(
                              color: Color(0xFF1E1E24),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clip.title,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF9318).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Current: Track ${clip.trackIndex + 1}',
                        style: const TextStyle(
                          color: Color(0xFFFF9318),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(widget.audioState.tracks.length, (trackIdx) {
                  final track = widget.audioState.tracks[trackIdx];
                  final isCurrent = clip.trackIndex == trackIdx;
                  final isLocked = track.isLocked;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: InkWell(
                      onTap: isLocked
                          ? () {
                              Fluttertoast.showToast(msg: 'Track ${trackIdx + 1} is locked');
                            }
                          : () {
                              Navigator.pop(context);
                              widget.audioState.tracks[clip.trackIndex].clips.removeWhere((c) => c.id == clip.id);
                              clip.trackIndex = trackIdx;
                              final targetTrack = widget.audioState.tracks[trackIdx];
                              clip.startOffsetMs = targetTrack.clampOffsetToPreventOverlap(clip, clip.startOffsetMs);
                              targetTrack.clips.add(clip);
                              targetTrack.resolveOverlapForClip(clip);
                              _selectedTrackIndexNotifier.value = trackIdx;
                              _clipRevisionNotifier.value++;
                              widget.onAudioStateChanged(widget.audioState);
                              Fluttertoast.showToast(
                                msg: 'Moved to Track ${trackIdx + 1}',
                                backgroundColor: const Color(0xFFFF9318),
                                textColor: Colors.white,
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFFF8F0) : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFFFF9318) : const Color(0xFFE8E9EF),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFFFF9318) : const Color(0xFFE8E9EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'T${trackIdx + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : const Color(0xFF5E606D),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Track ${trackIdx + 1}',
                                    style: TextStyle(
                                      color: const Color(0xFF1E1E24),
                                      fontSize: 14.5,
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isLocked
                                        ? 'Track is locked'
                                        : '${track.clips.length} clip${track.clips.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: isLocked ? const Color(0xFFFF9800) : const Color(0xFF8E8E93),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9318), size: 22)
                            else if (isLocked)
                              const Icon(Icons.lock_rounded, color: Color(0xFFFF9800), size: 20)
                            else
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0B2BD), size: 14),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      final newTrack = widget.audioState.addTrack();
                      widget.audioState.tracks[clip.trackIndex].clips.removeWhere((c) => c.id == clip.id);
                      clip.trackIndex = newTrack.index;
                      clip.startOffsetMs = newTrack.clampOffsetToPreventOverlap(clip, clip.startOffsetMs);
                      newTrack.clips.add(clip);
                      newTrack.resolveOverlapForClip(clip);
                      _selectedTrackIndexNotifier.value = newTrack.index;
                      _clipRevisionNotifier.value++;
                      widget.onAudioStateChanged(widget.audioState);
                      Fluttertoast.showToast(
                        msg: 'Created & Moved to Track ${newTrack.index + 1} (T${newTrack.index + 1})',
                        backgroundColor: const Color(0xFFFF9318),
                        textColor: Colors.white,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9318).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9318),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+ Add New Track (Track ${widget.audioState.tracks.length + 1})',
                            style: const TextStyle(
                              color: Color(0xFFFF9318),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
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
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF9318), size: 26),
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
                          color: Color(0xFFFFF4E8),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isPlayingNotifier,
                          builder: (context, isPlaying, _) {
                            return IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: const Color(0xFFFF9318),
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

                  // Add Audio Button (+) in coral/amber primary
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9318),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Track Headers with Mute & Lock controls + Add Track Button
                Container(
                  width: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFC),
                    border: Border(right: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Top Left Corner Box (Aligns with 28px Time Ruler)
                      Container(
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F5F8),
                          border: Border(bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
                        ),
                        child: Center(
                          child: Tooltip(
                            message: 'Add Track',
                            child: InkWell(
                              onTap: _addNewTrack,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFF9318).withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 13, color: Color(0xFFFF9318)),
                                    Text(
                                      'Track',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF9318),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Vertically Scrollable Track Headers
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isDraggingTimelineObjectNotifier,
                          builder: (context, isDraggingObject, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable: _clipRevisionNotifier,
                              builder: (context, revision, child) {
                                return ValueListenableBuilder<int>(
                                  valueListenable: _selectedTrackIndexNotifier,
                                  builder: (context, selectedTrack, child) {
                                    return SingleChildScrollView(
                                      controller: _leftHeadersVerticalScrollController,
                                      physics: isDraggingObject
                                          ? const NeverScrollableScrollPhysics()
                                          : const BouncingScrollPhysics(),
                                      child: Column(
                                        children: [
                                          ...List.generate(widget.audioState.tracks.length, (trackIdx) {
                                            final track = widget.audioState.tracks[trackIdx];
                                            final isSelected = selectedTrack == trackIdx;

                                            return GestureDetector(
                                              onTap: () {
                                                _selectedTrackIndexNotifier.value = trackIdx;
                                                _selectedClipIdNotifier.value = null;
                                              },
                                              child: Container(
                                                height: _trackHeight,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color(0xFFFFF8F0) : Colors.transparent,
                                                  border: Border(
                                                    left: isSelected
                                                        ? const BorderSide(color: Color(0xFFFF9318), width: 3.5)
                                                        : BorderSide.none,
                                                    bottom: const BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: isSelected ? const Color(0xFFFF9318) : const Color(0xFFEBEBF0),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'T${trackIdx + 1}',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: isSelected ? Colors.white : const Color(0xFF6B6E7B),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
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
                                                            size: 15,
                                                            color: track.isMuted
                                                                ? Colors.red
                                                                : (isSelected ? const Color(0xFFFF9318) : const Color(0xFF6B6E7B)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        // Lock button
                                                        GestureDetector(
                                                          onTap: () {
                                                            widget.audioState.toggleLock(trackIdx);
                                                            _clipRevisionNotifier.value++;
                                                            widget.onAudioStateChanged(widget.audioState);
                                                          },
                                                          child: Icon(
                                                            track.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                                            size: 15,
                                                            color: track.isLocked
                                                                ? const Color(0xFFFF9800)
                                                                : (isSelected ? const Color(0xFFFF9318) : const Color(0xFF9E9EA7)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),

                                          // Bottom "+ Track" button at the end of track headers list
                                          InkWell(
                                            onTap: _addNewTrack,
                                            child: Container(
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF5F6F9),
                                                border: Border(
                                                  bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.add_rounded, size: 14, color: Color(0xFFFF9318)),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Add',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFFFF9318),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
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

                // Right Column: Main Multi-Track Scrollable Timeline Lanes
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isDraggingTimelineObjectNotifier,
                    builder: (context, isDraggingObject, _) {
                      return SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: isDraggingObject
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: timelineWidth + 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Time Ruler along the top (Cached in RepaintBoundary, Fixed height 28)
                              SizedBox(
                                height: 28,
                                width: timelineWidth + 120,
                                child: RepaintBoundary(
                                  child: _buildTimeRuler(timelineWidth),
                                ),
                              ),

                              // 2. Track Grid Lanes & Clips (Scrollable vertically with synced controller)
                              Expanded(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _clipRevisionNotifier,
                                  builder: (context, revision, _) {
                                    final double lanesTotalHeight = (widget.audioState.tracks.length * _trackHeight) + 38.0;

                                    return SingleChildScrollView(
                                      controller: _lanesVerticalScrollController,
                                      scrollDirection: Axis.vertical,
                                      physics: isDraggingObject
                                          ? const NeverScrollableScrollPhysics()
                                          : const BouncingScrollPhysics(),
                                      child: SizedBox(
                                        height: lanesTotalHeight,
                                        width: timelineWidth + 120,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Track Grid Lines & Background Tap/DoubleTap Areas
                                            Positioned.fill(
                                              child: RepaintBoundary(
                                                child: ValueListenableBuilder<int>(
                                                  valueListenable: _selectedTrackIndexNotifier,
                                                  builder: (context, selectedTrack, _) {
                                                    return Column(
                                                      children: [
                                                        ...List.generate(widget.audioState.tracks.length, (trackIdx) {
                                                          final isSelected = selectedTrack == trackIdx;

                                                          return SizedBox(
                                                            height: _trackHeight,
                                                            child: GestureDetector(
                                                              behavior: HitTestBehavior.opaque,
                                                              onTapDown: (details) {
                                                                _selectedTrackIndexNotifier.value = trackIdx;
                                                                _selectedClipIdNotifier.value = null;
                                                                final double tapX = details.localPosition.dx;
                                                                final int targetMs = ((tapX / _pixelsPerSecond) * 1000)
                                                                    .round()
                                                                    .clamp(0, _maxTimelineMs);
                                                                _seekTo(targetMs);
                                                              },
                                                              onDoubleTapDown: (details) {
                                                                final double tapX = details.localPosition.dx;
                                                                final int targetMs = ((tapX / _pixelsPerSecond) * 1000)
                                                                    .round()
                                                                    .clamp(0, _maxTimelineMs);
                                                                _openAddAudioMenu(
                                                                    targetTrackIndex: trackIdx, targetPositionMs: targetMs);
                                                              },
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: isSelected ? const Color(0xFFFFFDF8) : Colors.white,
                                                                  border: const Border(
                                                                    bottom:
                                                                        BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                        // Bottom empty lane aligned with "+ Add Track"
                                                        Container(
                                                          height: 38,
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFFAFAFC),
                                                            border: Border(
                                                              bottom: BorderSide(color: Color(0xFFEBEBF0), width: 1),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),

                                            // Render Audio Clips across all tracks
                                            ValueListenableBuilder<String?>(
                                              valueListenable: _selectedClipIdNotifier,
                                              builder: (context, selectedClipId, _) {
                                                return Stack(
                                                  clipBehavior: Clip.none,
                                                  children: widget.audioState.tracks.expand((track) {
                                                    final int trackIdx = track.index;
                                                    const double trackHeight = _trackHeight;

                                                    return track.clips.map((clip) {
                                                      final double clipX =
                                                          (clip.startOffsetMs / 1000.0) * _pixelsPerSecond;
                                                      final double clipWidth = ((clip.trimmedDurationMs / 1000.0) *
                                                              _pixelsPerSecond)
                                                          .clamp(52.0, 4000.0);
                                                      final double clipY = trackIdx * trackHeight;
                                                      final bool isClipSelected = selectedClipId == clip.id;
                                                      final double handleWidth = clipWidth < 68.0 ? 11.0 : 14.0;
                                                      final double contentPaddingH =
                                                          isClipSelected ? (handleWidth + 2.0) : 5.0;

                                                      return Positioned(
                                                        key: ValueKey('clip_pos_${clip.id}'),
                                                        left: clipX,
                                                        top: clipY + 3,
                                                        width: clipWidth,
                                                        height: trackHeight - 6,
                                                        child: RepaintBoundary(
                                                          child: Stack(
                                                            clipBehavior: Clip.none,
                                                            children: [
                                                              // Main Clip Body (Handles 2D drag & taps)
                                                              Positioned.fill(
                                                                child: Listener(
                                                                  behavior: HitTestBehavior.opaque,
                                                                  onPointerDown: (event) {
                                                                    _selectedTrackIndexNotifier.value = trackIdx;
                                                                    _selectedClipIdNotifier.value = clip.id;
                                                                    if (track.isLocked) return;
                                                                    _draggingClipId = clip.id;
                                                                    _isDraggingTimelineObjectNotifier.value = true;
                                                                    _dragStartPointerX = event.position.dx;
                                                                    _dragStartPointerY = event.position.dy;
                                                                    _dragStartClipOffsetMs = clip.startOffsetMs;
                                                                    _dragStartClipTrack = clip.trackIndex;
                                                                    _hasMovedClip = false;
                                                                  },
                                                                  onPointerMove: (event) {
                                                                    if (track.isLocked ||
                                                                        !_isDraggingTimelineObjectNotifier.value) {
                                                                      return;
                                                                    }
                                                                    final activeClipId = _draggingClipId ?? clip.id;
                                                                    final targetClip =
                                                                        widget.audioState.findClip(activeClipId) ?? clip;
                                                                    final double dx = event.position.dx - _dragStartPointerX;
                                                                    final double dy = event.position.dy - _dragStartPointerY;
                                                                    if (!_hasMovedClip &&
                                                                        dx.abs() < 3.0 &&
                                                                        dy.abs() < 3.0) {
                                                                      return;
                                                                    }
                                                                    _hasMovedClip = true;

                                                                    // 1. Vertical movement across tracks (Track 1 to Track N)
                                                                    final int trackShift = (dy / trackHeight).round();
                                                                    final int rawTargetIdx = _dragStartClipTrack + trackShift;

                                                                    // Auto-expand track if dragged downwards past the bottom track!
                                                                    if (rawTargetIdx >= widget.audioState.tracks.length &&
                                                                        widget.audioState.tracks.length < 12) {
                                                                      widget.audioState.addTrack();
                                                                    }

                                                                    final int targetTrackIdx = rawTargetIdx.clamp(
                                                                        0, widget.audioState.tracks.length - 1);

                                                                    if (targetTrackIdx != targetClip.trackIndex &&
                                                                        !widget.audioState.tracks[targetTrackIdx].isLocked) {
                                                                      widget.audioState.tracks[targetClip.trackIndex].clips
                                                                          .removeWhere((c) => c.id == targetClip.id);
                                                                      targetClip.trackIndex = targetTrackIdx;
                                                                      widget.audioState.tracks[targetTrackIdx].clips.add(targetClip);
                                                                      _selectedTrackIndexNotifier.value = targetTrackIdx;
                                                                    }

                                                                    // 2. Horizontal movement in time (Left / Right) without jumping
                                                                    final int rawOffsetMs = (_dragStartClipOffsetMs +
                                                                            ((dx / _pixelsPerSecond) * 1000).round())
                                                                        .clamp(0, _maxTimelineMs);

                                                                    final currentTrack =
                                                                        widget.audioState.tracks[targetClip.trackIndex];
                                                                    final int snappedOffsetMs =
                                                                        currentTrack.findMagneticSnapOffset(
                                                                      targetClip,
                                                                      rawOffsetMs,
                                                                      snapThresholdMs: 40,
                                                                      playheadMs: _positionNotifier.value,
                                                                    );
                                                                    final int safeOffsetMs =
                                                                        currentTrack.clampOffsetToPreventOverlap(
                                                                            targetClip, snappedOffsetMs);
                                                                    targetClip.startOffsetMs = safeOffsetMs;

                                                                    _clipRevisionNotifier.value++;
                                                                  },
                                                                  onPointerUp: (event) {
                                                                    if (_isDraggingTimelineObjectNotifier.value) {
                                                                      _isDraggingTimelineObjectNotifier.value = false;
                                                                      final activeClipId = _draggingClipId ?? clip.id;
                                                                      final targetClip =
                                                                          widget.audioState.findClip(activeClipId) ?? clip;
                                                                      _draggingClipId = null;
                                                                      if (_hasMovedClip) {
                                                                        widget.audioState.tracks[targetClip.trackIndex]
                                                                            .resolveOverlapForClip(targetClip);
                                                                        _clipRevisionNotifier.value++;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    }
                                                                  },
                                                                  onPointerCancel: (event) {
                                                                    if (_isDraggingTimelineObjectNotifier.value) {
                                                                      _isDraggingTimelineObjectNotifier.value = false;
                                                                      final activeClipId = _draggingClipId ?? clip.id;
                                                                      final targetClip =
                                                                          widget.audioState.findClip(activeClipId) ?? clip;
                                                                      _draggingClipId = null;
                                                                      if (_hasMovedClip) {
                                                                        widget.audioState.tracks[targetClip.trackIndex]
                                                                            .resolveOverlapForClip(targetClip);
                                                                        _clipRevisionNotifier.value++;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    }
                                                                  },
                                                                  child: GestureDetector(
                                                                    behavior: HitTestBehavior.translucent,
                                                                    onTap: () {
                                                                      _selectedTrackIndexNotifier.value = trackIdx;
                                                                      _selectedClipIdNotifier.value = clip.id;
                                                                    },
                                                                    onDoubleTap: () => _editClip(clip),
                                                                    onLongPress: () => _showClipOptionsMenu(clip),
                                                                    child: Container(
                                                                      clipBehavior: Clip.antiAlias,
                                                                      decoration: BoxDecoration(
                                                                        color: isClipSelected ? const Color(0xFFFFFDF8) : Colors.white,
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        border: Border.all(
                                                                          color: isClipSelected
                                                                              ? const Color(0xFFFF9318)
                                                                              : const Color(0xFFE2E3E8),
                                                                          width: isClipSelected ? 1.8 : 1.0,
                                                                        ),
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color: isClipSelected
                                                                                ? const Color(0xFFFF9318).withValues(alpha: 0.18)
                                                                                : Colors.black.withValues(alpha: 0.04),
                                                                            blurRadius: isClipSelected ? 6 : 3,
                                                                            offset: const Offset(0, 1),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.max,
                                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                        children: [
                                                                          // Title & Duration Header (Strict 14px constraint)
                                                                          SizedBox(
                                                                            height: 14,
                                                                            child: Padding(
                                                                              padding: EdgeInsets.symmetric(
                                                                                horizontal: contentPaddingH,
                                                                                vertical: 0.0,
                                                                              ),
                                                                              child: Row(
                                                                                children: [
                                                                                  Expanded(
                                                                                    child: Text(
                                                                                      clip.title,
                                                                                      style: TextStyle(
                                                                                        color: isClipSelected
                                                                                            ? const Color(0xFFFF9318)
                                                                                            : const Color(0xFF1E1E24),
                                                                                        fontSize: 9.5,
                                                                                        fontWeight: FontWeight.w700,
                                                                                        height: 1.1,
                                                                                      ),
                                                                                      maxLines: 1,
                                                                                      softWrap: false,
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                    ),
                                                                                  ),
                                                                                  if (isClipSelected && clipWidth >= 72.0) ...[
                                                                                    const SizedBox(width: 4),
                                                                                    Text(
                                                                                      '${(clip.trimmedDurationMs / 1000).toStringAsFixed(1)}s',
                                                                                      style: const TextStyle(
                                                                                        color: Color(0xFFFF9318),
                                                                                        fontSize: 8.5,
                                                                                        fontWeight: FontWeight.w700,
                                                                                        height: 1.1,
                                                                                      ),
                                                                                      maxLines: 1,
                                                                                      softWrap: false,
                                                                                    ),
                                                                                  ],
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          // Center Waveform in rich primary orange
                                                                          Expanded(
                                                                            child: Padding(
                                                                              padding: EdgeInsets.symmetric(
                                                                                horizontal: contentPaddingH,
                                                                                vertical: 1.0,
                                                                              ),
                                                                              child: ClipRect(
                                                                                child: CustomPaint(
                                                                                  painter: WaveformPainter(
                                                                                    samples: clip.waveformSamples,
                                                                                    waveColor: const Color(0xFFFF9318),
                                                                                    playedColor: const Color(0xFFE07C0A),
                                                                                    barWidth: 2.0,
                                                                                    barGap: 1.0,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),

                                                              // Solid Orange Trim Handle - Left (Start Trim)
                                                              if (isClipSelected && !track.isLocked)
                                                                Positioned(
                                                                  key: ValueKey('clip_trim_left_${clip.id}'),
                                                                  left: 0,
                                                                  top: 0,
                                                                  bottom: 0,
                                                                  width: handleWidth,
                                                                  child: Listener(
                                                                    behavior: HitTestBehavior.opaque,
                                                                    onPointerDown: (event) {
                                                                      _isDraggingTimelineObjectNotifier.value = true;
                                                                      _handleStartPointerX = event.position.dx;
                                                                      _handleStartTrimStartMs = clip.trimStartMs;
                                                                      _handleStartOffsetMs = clip.startOffsetMs;
                                                                      _handleStartTrimEndMs = clip.trimEndMs;
                                                                    },
                                                                    onPointerMove: (event) {
                                                                      final double dx = event.position.dx - _handleStartPointerX;
                                                                      final int deltaMs = ((dx / _pixelsPerSecond) * 1000).round();
                                                                      final int newTrimStart = (_handleStartTrimStartMs + deltaMs)
                                                                          .clamp(0, clip.trimEndMs - 200);
                                                                      final int actualShift = newTrimStart - _handleStartTrimStartMs;
                                                                      clip.trimStartMs = newTrimStart;
                                                                      clip.startOffsetMs =
                                                                          (_handleStartOffsetMs + actualShift).clamp(0, _maxTimelineMs);
                                                                      _clipRevisionNotifier.value++;
                                                                    },
                                                                    onPointerUp: (event) {
                                                                      if (_isDraggingTimelineObjectNotifier.value) {
                                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    },
                                                                    onPointerCancel: (event) {
                                                                      if (_isDraggingTimelineObjectNotifier.value) {
                                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    },
                                                                    child: Container(
                                                                      decoration: const BoxDecoration(
                                                                        color: Color(0xFFFF9318),
                                                                        borderRadius:
                                                                            BorderRadius.horizontal(left: Radius.circular(7)),
                                                                      ),
                                                                      child: Center(
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            Container(width: 1.5, height: 14, color: Colors.white),
                                                                            if (handleWidth > 11) ...[
                                                                              const SizedBox(width: 2),
                                                                              Container(width: 1.5, height: 14, color: Colors.white),
                                                                            ],
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),

                                                              // Solid Orange Trim Handle - Right (End Trim)
                                                              if (isClipSelected && !track.isLocked)
                                                                Positioned(
                                                                  key: ValueKey('clip_trim_right_${clip.id}'),
                                                                  right: 0,
                                                                  top: 0,
                                                                  bottom: 0,
                                                                  width: handleWidth,
                                                                  child: Listener(
                                                                    behavior: HitTestBehavior.opaque,
                                                                    onPointerDown: (event) {
                                                                      _isDraggingTimelineObjectNotifier.value = true;
                                                                      _handleStartPointerX = event.position.dx;
                                                                      _handleStartTrimEndMs = clip.trimEndMs;
                                                                    },
                                                                    onPointerMove: (event) {
                                                                      final double dx = event.position.dx - _handleStartPointerX;
                                                                      final int deltaMs = ((dx / _pixelsPerSecond) * 1000).round();
                                                                      clip.trimEndMs = (_handleStartTrimEndMs + deltaMs)
                                                                          .clamp(clip.trimStartMs + 200, clip.durationMs);
                                                                      _clipRevisionNotifier.value++;
                                                                    },
                                                                    onPointerUp: (event) {
                                                                      if (_isDraggingTimelineObjectNotifier.value) {
                                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    },
                                                                    onPointerCancel: (event) {
                                                                      if (_isDraggingTimelineObjectNotifier.value) {
                                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                                        widget.onAudioStateChanged(widget.audioState);
                                                                      }
                                                                    },
                                                                    child: Container(
                                                                      decoration: const BoxDecoration(
                                                                        color: Color(0xFFFF9318),
                                                                        borderRadius:
                                                                            BorderRadius.horizontal(right: Radius.circular(7)),
                                                                      ),
                                                                      child: Center(
                                                                        child: Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            Container(width: 1.5, height: 14, color: Colors.white),
                                                                            if (handleWidth > 11) ...[
                                                                              const SizedBox(width: 2),
                                                                              Container(width: 1.5, height: 14, color: Colors.white),
                                                                            ],
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
                                                    });
                                                  }).toList(),
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
                                                    child: Listener(
                                                      behavior: HitTestBehavior.opaque,
                                                      onPointerDown: (event) {
                                                        _isDraggingTimelineObjectNotifier.value = true;
                                                        _scrubberStartPointerX = event.position.dx;
                                                        _scrubberStartPosMs = posMs;
                                                      },
                                                      onPointerMove: (event) {
                                                        final double dx = event.position.dx - _scrubberStartPointerX;
                                                        final int newMs =
                                                            (_scrubberStartPosMs + ((dx / _pixelsPerSecond) * 1000).round())
                                                                .clamp(0, _maxTimelineMs);
                                                        _seekTo(newMs);
                                                      },
                                                      onPointerUp: (event) {
                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                      },
                                                      onPointerCancel: (event) {
                                                        _isDraggingTimelineObjectNotifier.value = false;
                                                      },
                                                      child: SizedBox(
                                                        width: 12,
                                                        child: Column(
                                                          children: [
                                                            // Top Triangle Pointer Indicator
                                                            CustomPaint(
                                                              size: const Size(12, 10),
                                                              painter: _PlayheadTrianglePainter(color: const Color(0xFFFF9318)),
                                                            ),
                                                            // Vertical Line Needle
                                                            Expanded(
                                                              child: Container(
                                                                width: 2,
                                                                color: const Color(0xFFFF9318),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEBEBF0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
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
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E6EB), width: 1),
              ),
              child: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: Color(0xFF2C2D35),
                size: 22,
              ),
            ),
          ),

          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE5E6EB),
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
                    color: Color(0xFF2C2D35),
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

          // Action 4: Track Switcher
          _buildActionButton(
            icon: Icons.swap_vert_rounded,
            label: 'Track ${clip.trackIndex + 1}',
            onTap: () => _showTrackSelectionMenu(clip),
          ),

          // Action 5: Duplicate (Copy)
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Duplicate',
            onTap: _duplicateSelectedClip,
          ),

          // Action 6: Delete (Trash)
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
    final Color itemColor = isDestructive ? const Color(0xFFFF4B72) : const Color(0xFF2C2D35);

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
                      color: itemColor,
                      size: 22,
                    ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
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
                        color: isSelected ? const Color(0xFFFF9318) : const Color(0xFFD4D5DC),
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
                              color: isSelected ? const Color(0xFFFF9318) : Colors.black.withValues(alpha: 0.6),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert_rounded, color: Color(0xFFFF9318)),
              title: Text('Move to Track (Currently Track ${clip.trackIndex + 1})',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1E24))),
              onTap: () {
                Navigator.pop(context);
                _showTrackSelectionMenu(clip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: Color(0xFFFF9318)),
              title: const Text('Trim & Edit Waveform', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1E24))),
              onTap: () {
                Navigator.pop(context);
                _editClip(clip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4B72)),
              title: const Text('Delete Audio Clip', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFF4B72))),
              onTap: () {
                Navigator.pop(context);
                _deleteClip(clip);
              },
            ),
            const SizedBox(height: 8),
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
