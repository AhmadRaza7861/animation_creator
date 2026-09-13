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
    final updatedClip = clip.copyWith(trackIndex: idx);
    tracks[idx].clips.add(updatedClip);
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
          track.clips[idx] = updated;
        } else {
          track.clips.removeAt(idx);
          final targetIdx = updated.trackIndex.clamp(0, tracks.length - 1);
          tracks[targetIdx].clips.add(updated);
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

  void toggleMute(int trackIndex) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].isMuted = !tracks[trackIndex].isMuted;
    }
  }

  void toggleLock(int trackIndex) {
    if (trackIndex >= 0 && trackIndex < tracks.length) {
      tracks[trackIndex].isLocked = !tracks[trackIndex].isLocked;
    }
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
