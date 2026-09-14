import 'audio_clip.dart';

class AudioTrack {
  int index;
  String name;
  bool isMuted;
  bool isLocked;
  double volume; // 0.0 to 1.0
  List<AudioClip> clips;

  AudioTrack({
    required this.index,
    String? name,
    this.isMuted = false,
    this.isLocked = false,
    this.volume = 1.0,
    List<AudioClip>? clips,
  })  : name = name ?? 'Track ${index + 1}',
        clips = clips ?? [];

  AudioTrack copyWith({
    int? index,
    String? name,
    bool? isMuted,
    bool? isLocked,
    double? volume,
    List<AudioClip>? clips,
  }) {
    return AudioTrack(
      index: index ?? this.index,
      name: name ?? this.name,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      volume: volume ?? this.volume,
      clips: clips != null ? List<AudioClip>.from(clips) : List<AudioClip>.from(this.clips),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'isMuted': isMuted,
      'isLocked': isLocked,
      'volume': volume,
      'clips': clips.map((c) => c.toJson()).toList(),
    };
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? clipsJson = json['clips'] as List<dynamic>?;
    final List<AudioClip> clips = clipsJson != null
        ? clipsJson.map((c) => AudioClip.fromJson(c as Map<String, dynamic>)).toList()
        : [];

    final int idx = json['index'] as int? ?? 0;
    return AudioTrack(
      index: idx,
      name: json['name'] as String? ?? 'Track ${idx + 1}',
      isMuted: json['isMuted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      clips: clips,
    );
  }

  /// Snaps to timeline start (0ms) if dragged right next to 0.
  /// Does NOT pull, attract, or move clips towards each other across empty space.
  int findMagneticSnapOffset(
    AudioClip clip,
    int candidateOffsetMs, {
    int snapThresholdMs = 40,
    int? playheadMs,
  }) {
    // Snap to 0ms if dragged very close to timeline start and not blocked
    if (candidateOffsetMs < snapThresholdMs && candidateOffsetMs >= 0) {
      final otherClips = clips.where((c) => c.id != clip.id).toList();
      bool blockedAtZero = false;
      for (final other in otherClips) {
        if (0 < other.endOffsetMs && clip.trimmedDurationMs > other.startOffsetMs) {
          blockedAtZero = true;
          break;
        }
      }
      if (!blockedAtZero) {
        return 0;
      }
    }

    return candidateOffsetMs;
  }

  /// Clamps [targetOffsetMs] so that [clip] NEVER overlaps with any other clip on this track.
  int clampOffsetToPreventOverlap(AudioClip clip, int targetOffsetMs) {
    final otherClips = clips.where((c) => c.id != clip.id).toList()
      ..sort((a, b) => a.startOffsetMs.compareTo(b.startOffsetMs));

    if (otherClips.isEmpty) return targetOffsetMs.clamp(0, 3600000);

    final int duration = clip.trimmedDurationMs;
    final int targetEnd = targetOffsetMs + duration;

    // 1. Check if targetOffsetMs already fits in free space without overlap
    bool overlaps = false;
    for (final other in otherClips) {
      if (targetOffsetMs < other.endOffsetMs && targetEnd > other.startOffsetMs) {
        overlaps = true;
        break;
      }
    }

    if (!overlaps) {
      return targetOffsetMs.clamp(0, 3600000);
    }

    // 2. If it overlaps, find the nearest non-overlapping free slot
    int bestOffset = targetOffsetMs;
    int minShift = 999999999;

    // Check slot at 0 (if free)
    if (otherClips.first.startOffsetMs >= duration) {
      final int shift = targetOffsetMs.abs();
      if (shift < minShift) {
        minShift = shift;
        bestOffset = 0;
      }
    }

    for (int i = 0; i < otherClips.length; i++) {
      final other = otherClips[i];

      // Slot right after this other clip
      final int afterOffset = other.endOffsetMs;
      final int afterEnd = afterOffset + duration;
      final bool nextFree = (i == otherClips.length - 1) || (otherClips[i + 1].startOffsetMs >= afterEnd);
      if (nextFree) {
        final int shift = (targetOffsetMs - afterOffset).abs();
        if (shift < minShift) {
          minShift = shift;
          bestOffset = afterOffset;
        }
      }

      // Slot right before this other clip
      final int beforeOffset = other.startOffsetMs - duration;
      final bool prevFree = beforeOffset >= 0 && ((i == 0) || (otherClips[i - 1].endOffsetMs <= beforeOffset));
      if (prevFree) {
        final int shift = (targetOffsetMs - beforeOffset).abs();
        if (shift < minShift) {
          minShift = shift;
          bestOffset = beforeOffset;
        }
      }
    }

    return bestOffset.clamp(0, 3600000);
  }

  /// Resolves any overlap for [clip] on this track so no two clips overlap.
  void resolveOverlapForClip(AudioClip clip) {
    clip.startOffsetMs = clampOffsetToPreventOverlap(clip, clip.startOffsetMs);
  }
}
