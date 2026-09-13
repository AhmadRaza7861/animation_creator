import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/audio_clip.dart';
import '../domain/models/audio_project_state.dart';

class AudioPlaybackService {
  final Map<String, AudioPlayer> _players = {};
  bool _isPlaying = false;
  int _currentPositionMs = 0;
  Timer? _ticker;

  bool get isPlaying => _isPlaying;
  int get currentPositionMs => _currentPositionMs;

  /// Play multi-track audio at given [startMs] timeline position
  Future<void> playTracks({
    required AudioProjectState state,
    required int startMs,
    required void Function(int positionMs) onPositionUpdate,
    required VoidCallback onPlaybackComplete,
    int? maxTimelineMs,
  }) async {
    await stopAll();

    _isPlaying = true;
    _currentPositionMs = startMs;
    final int limitMs = maxTimelineMs ?? (state.maxDurationMs > 0 ? state.maxDurationMs : 10000);

    // Identify active clips on unmuted tracks
    for (final track in state.tracks) {
      if (track.isMuted) continue;
      for (final clip in track.clips) {
        if (clip.isMuted) continue;
        if (startMs >= clip.startOffsetMs && startMs < clip.endOffsetMs) {
          final int clipSeekOffset = (startMs - clip.startOffsetMs) + clip.trimStartMs;
          await _startClipPlayer(clip, clipSeekOffset, trackVolume: track.volume);
        }
      }
    }

    // Precise 30Hz ticker for smooth scrubber and audio sync
    const interval = Duration(milliseconds: 33);
    _ticker = Timer.periodic(interval, (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      _currentPositionMs += 33;
      onPositionUpdate(_currentPositionMs);

      // Check for clips that start at the current time
      for (final track in state.tracks) {
        if (track.isMuted) continue;
        for (final clip in track.clips) {
          if (clip.isMuted) continue;
          if (_currentPositionMs >= clip.startOffsetMs &&
              _currentPositionMs < clip.startOffsetMs + 40 &&
              !_players.containsKey(clip.id)) {
            await _startClipPlayer(clip, clip.trimStartMs, trackVolume: track.volume);
          }
          // Stop player if clip reached its end
          if (_currentPositionMs >= clip.endOffsetMs && _players.containsKey(clip.id)) {
            final player = _players.remove(clip.id);
            try {
              await player?.stop();
              await player?.dispose();
            } catch (_) {}
          }
        }
      }

      if (_currentPositionMs >= limitMs) {
        await stopAll();
        onPlaybackComplete();
      }
    });
  }

  Future<void> _startClipPlayer(AudioClip clip, int seekOffsetMs, {double trackVolume = 1.0}) async {
    try {
      if (clip.filePath.isEmpty) return;
      final file = File(clip.filePath);
      if (!await file.exists() && !clip.filePath.startsWith('assets/')) return;

      final player = AudioPlayer();
      _players[clip.id] = player;

      await player.setVolume((clip.volume * trackVolume).clamp(0.0, 1.0));

      if (clip.filePath.startsWith('assets/')) {
        await player.setSource(AssetSource(clip.filePath.replaceFirst('assets/', '')));
      } else {
        await player.setSource(DeviceFileSource(clip.filePath));
      }

      if (seekOffsetMs > 0) {
        await player.seek(Duration(milliseconds: seekOffsetMs));
      }
      await player.resume();
    } catch (e) {
      debugPrint('Error starting audio player for clip ${clip.title}: $e');
    }
  }

  /// Play a single standalone clip preview
  Future<void> playSingleClip(AudioClip clip, {VoidCallback? onComplete}) async {
    await stopAll();
    try {
      final player = AudioPlayer();
      _players['preview'] = player;
      await player.setVolume(clip.volume.clamp(0.0, 1.0));

      player.onPlayerComplete.listen((_) {
        onComplete?.call();
      });

      if (clip.filePath.startsWith('assets/')) {
        await player.setSource(AssetSource(clip.filePath.replaceFirst('assets/', '')));
      } else {
        await player.setSource(DeviceFileSource(clip.filePath));
      }

      if (clip.trimStartMs > 0) {
        await player.seek(Duration(milliseconds: clip.trimStartMs));
      }
      await player.resume();
    } catch (e) {
      debugPrint('Error playing single clip preview: $e');
      onComplete?.call();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    _ticker?.cancel();
    _ticker = null;
    for (final player in _players.values) {
      try {
        await player.pause();
      } catch (_) {}
    }
  }

  Future<void> stopAll() async {
    _isPlaying = false;
    _ticker?.cancel();
    _ticker = null;

    for (final player in _players.values) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
  }

  void dispose() {
    stopAll();
  }
}
