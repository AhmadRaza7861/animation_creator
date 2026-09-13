import 'audio_clip.dart';

class AudioTrack {
  final int index;
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
    String? name,
    bool? isMuted,
    bool? isLocked,
    double? volume,
    List<AudioClip>? clips,
  }) {
    return AudioTrack(
      index: index,
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
}
