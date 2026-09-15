import 'audio_clip.dart';
import 'audio_track.dart';

class AudioProjectState {
  final List<AudioTrack> tracks;

  AudioProjectState({
    List<AudioTrack>? tracks,
  }) : tracks = tracks ?? List.generate(4, (i) => AudioTrack(index: i));

  bool get isEmpty => tracks.every((t) => t.clips.isEmpty);
  bool get isNotEmpty => !isEmpty;

  List<AudioClip> get allClips {
    final List<AudioClip> result = [];
    for (final track in tracks) {
      result.addAll(track.clips);
    }
    return result;
  }

  int get maxDurationMs {
    int maxMs = 0;
    for (final clip in allClips) {
      if (clip.endOffsetMs > maxMs) {
        maxMs = clip.endOffsetMs;
      }
    }
    return maxMs;
  }

  void addClip(AudioClip clip, {int? targetTrackIndex}) {
    final int idx = (targetTrackIndex ?? clip.trackIndex).clamp(0, tracks.length - 1);
    final targetTrack = tracks[idx];
    final int safeOffset = targetTrack.clampOffsetToPreventOverlap(clip, clip.startOffsetMs);
    final updatedClip = clip.copyWith(trackIndex: idx, startOffsetMs: safeOffset);
    targetTrack.clips.add(updatedClip);
    targetTrack.resolveOverlapForClip(updatedClip);
  }

  void removeClip(String clipId) {
    for (final track in tracks) {
      track.clips.removeWhere((c) => c.id == clipId);
    }
  }

  void updateClip(AudioClip updated) {
    for (final track in tracks) {
      final idx = track.clips.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        if (track.index == updated.trackIndex) {
          final int safeOffset = track.clampOffsetToPreventOverlap(updated, updated.startOffsetMs);
          updated.startOffsetMs = safeOffset;
          track.clips[idx] = updated;
          track.resolveOverlapForClip(updated);
        } else {
          track.clips.removeAt(idx);
          final targetIdx = updated.trackIndex.clamp(0, tracks.length - 1);
          final targetTrack = tracks[targetIdx];
          final int safeOffset = targetTrack.clampOffsetToPreventOverlap(updated, updated.startOffsetMs);
          updated.startOffsetMs = safeOffset;
          targetTrack.clips.add(updated);
          targetTrack.resolveOverlapForClip(updated);
        }
        return;
      }
    }
  }

  AudioClip? findClip(String clipId) {
    for (final track in tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) return clip;
      }
    }
    return null;
  }

  /// Whether any track in the project is currently soloed.
  bool get hasSoloTracks => tracks.any((t) => t.isSolo);

  /// Evaluates whether [track] should produce audio (handles solo & mute).
  bool isTrackActive(AudioTrack track) {
    if (track.isMuted) return false;
    if (hasSoloTracks) return track.isSolo;
    return true;
  }

  /// Evaluates whether [clip] should produce audio (handles parent track solo/mute & clip mute).
  bool isClipActive(AudioClip clip) {
    if (clip.isMuted || clip.filePath.isEmpty) return false;
    if (clip.trackIndex >= 0 && clip.trackIndex < tracks.length) {
      return isTrackActive(tracks[clip.trackIndex]);
    }
    return false;
  }

  /// Returns all clips that are actively playing at the given [timelineMs] position.
  List<AudioClip> getActiveClipsAt(int timelineMs) {
    final List<AudioClip> active = [];
    for (final track in tracks) {
      if (!isTrackActive(track)) continue;
      for (final clip in track.clips) {
        if (!clip.isMuted && clip.filePath.isNotEmpty && clip.isPlayingAt(timelineMs)) {
          active.add(clip);
        }
      }
    }
    return active;
  }

  void toggleMute(int trackIndex) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].isMuted = !tracks[trackIndex].isMuted;
    }
  }

  void toggleSolo(int trackIndex) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].isSolo = !tracks[trackIndex].isSolo;
    }
  }

  void toggleLock(int trackIndex) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].isLocked = !tracks[trackIndex].isLocked;
    }
  }

  void setTrackVolume(int trackIndex, double volume) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].volume = volume.clamp(0.0, 2.0);
    }
  }

  void renameTrack(int trackIndex, String name) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].name = name.trim().isNotEmpty ? name.trim() : 'Track ${trackIndex + 1}';
    }
  }

  AudioTrack addTrack({String? name}) {
    final newTrack = AudioTrack(
      index: tracks.length,
      name: name ?? 'Track ${tracks.length + 1}',
    );
    tracks.add(newTrack);
    return newTrack;
  }

  void ensureTrackCount(int count) {
    while (tracks.length < count) {
      addTrack();
    }
  }

  bool removeTrack(int trackIndex) {
    if (trackIndex < 0 || trackIndex >= tracks.length || tracks.length <= 1) {
      return false;
    }
    tracks.removeAt(trackIndex);
    for (int i = 0; i < tracks.length; i++) {
      tracks[i].index = i;
      for (final clip in tracks[i].clips) {
        clip.trackIndex = i;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }

  factory AudioProjectState.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? tracksJson = json['tracks'] as List<dynamic>?;
    if (tracksJson != null && tracksJson.isNotEmpty) {
      final List<AudioTrack> parsed = tracksJson
          .map((t) => AudioTrack.fromJson(t as Map<String, dynamic>))
          .toList();
      for (int i = 0; i < parsed.length; i++) {
        parsed[i].index = i;
      }
      while (parsed.length < 4) {
        parsed.add(AudioTrack(index: parsed.length));
      }
      return AudioProjectState(tracks: parsed);
    }
    return AudioProjectState();
  }

  AudioProjectState clone() {
    return AudioProjectState(
      tracks: tracks.map((t) => t.copyWith(clips: t.clips.map((c) => c.copyWith()).toList())).toList(),
    );
  }
}
