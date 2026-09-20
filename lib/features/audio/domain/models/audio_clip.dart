import 'package:uuid/uuid.dart';

class AudioClip {
  final String id;
  String title;
  String filePath;
  int trackIndex; // 0..3
  int startOffsetMs; // Position on animation timeline in milliseconds
  int durationMs; // Duration of the active clip in milliseconds
  int trimStartMs; // Start offset within the source audio file
  int trimEndMs; // End offset within the source audio file
  int fadeInMs; // Fade in duration in milliseconds (0 = no fade)
  int fadeOutMs; // Fade out duration in milliseconds (0 = no fade)
  double volume; // 0.0 to 2.0 (default 1.0)
  bool isMuted;
  List<double> waveformSamples; // Normalized amplitudes (0.0 to 1.0)

  AudioClip({
    String? id,
    required this.title,
    required this.filePath,
    this.trackIndex = 0,
    this.startOffsetMs = 0,
    required this.durationMs,
    this.trimStartMs = 0,
    int? trimEndMs,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.volume = 1.0,
    this.isMuted = false,
    List<double>? waveformSamples,
  })  : id = id ?? const Uuid().v4(),
        trimEndMs = trimEndMs ?? durationMs,
        waveformSamples = waveformSamples ?? _generateDefaultWaveform();

  int get trimmedDurationMs {
    final int raw = trimEndMs - trimStartMs;
    final int effectiveMax = durationMs > 0 ? (durationMs >= raw ? durationMs : raw) : raw;
    return raw.clamp(0, effectiveMax > 0 ? effectiveMax : 0);
  }

  int get endOffsetMs => startOffsetMs + trimmedDurationMs;

  /// Fraction of trimmed duration occupied by fade-in (0.0 to 1.0)
  double get fadeInFraction {
    if (trimmedDurationMs <= 0 || fadeInMs <= 0) return 0.0;
    return (fadeInMs / trimmedDurationMs).clamp(0.0, 1.0);
  }

  /// Fraction of trimmed duration occupied by fade-out (0.0 to 1.0)
  double get fadeOutFraction {
    if (trimmedDurationMs <= 0 || fadeOutMs <= 0) return 0.0;
    return (fadeOutMs / trimmedDurationMs).clamp(0.0, 1.0);
  }

  /// Returns true if this clip is active on the timeline at [timelineMs].
  bool isPlayingAt(int timelineMs) {
    return timelineMs >= startOffsetMs && timelineMs < endOffsetMs;
  }

  /// Computes the volume multiplier (0.0 to 1.0) based on fade-in and fade-out
  /// for a given [localOffsetMs] (relative to the start of this clip on the timeline, 0..trimmedDurationMs).
  double computeFadeMultiplier(int localOffsetMs) {
    if (trimmedDurationMs <= 0) return 1.0;
    final int clampedOffset = localOffsetMs.clamp(0, trimmedDurationMs);
    double multiplier = 1.0;

    // Apply Fade In
    if (fadeInMs > 0 && clampedOffset < fadeInMs) {
      multiplier = (clampedOffset / fadeInMs).clamp(0.0, 1.0);
    }

    // Apply Fade Out
    final int remainingMs = trimmedDurationMs - clampedOffset;
    if (fadeOutMs > 0 && remainingMs < fadeOutMs) {
      final double outMul = (remainingMs / fadeOutMs).clamp(0.0, 1.0);
      multiplier = multiplier < outMul ? multiplier : outMul;
    }

    return multiplier.clamp(0.0, 1.0);
  }

  AudioClip copyWith({
    String? title,
    String? filePath,
    int? trackIndex,
    int? startOffsetMs,
    int? durationMs,
    int? trimStartMs,
    int? trimEndMs,
    int? fadeInMs,
    int? fadeOutMs,
    double? volume,
    bool? isMuted,
    List<double>? waveformSamples,
  }) {
    return AudioClip(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      trackIndex: trackIndex ?? this.trackIndex,
      startOffsetMs: startOffsetMs ?? this.startOffsetMs,
      durationMs: durationMs ?? this.durationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      waveformSamples: waveformSamples ?? this.waveformSamples,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'trackIndex': trackIndex,
      'startOffsetMs': startOffsetMs,
      'durationMs': durationMs,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'fadeInMs': fadeInMs,
      'fadeOutMs': fadeOutMs,
      'volume': volume,
      'isMuted': isMuted,
      'waveformSamples': waveformSamples,
    };
  }

  factory AudioClip.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? samplesJson = json['waveformSamples'] as List<dynamic>?;
    final List<double> samples = samplesJson != null
        ? samplesJson.map((e) => (e as num).toDouble()).toList()
        : _generateDefaultWaveform();

    final int duration = json['durationMs'] as int? ?? 1000;
    return AudioClip(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Audio Clip',
      filePath: json['filePath'] as String? ?? '',
      trackIndex: json['trackIndex'] as int? ?? 0,
      startOffsetMs: json['startOffsetMs'] as int? ?? 0,
      durationMs: duration,
      trimStartMs: json['trimStartMs'] as int? ?? 0,
      trimEndMs: json['trimEndMs'] as int? ?? duration,
      fadeInMs: json['fadeInMs'] as int? ?? 0,
      fadeOutMs: json['fadeOutMs'] as int? ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      waveformSamples: samples,
    );
  }

  static List<double> generateDefaultWaveform({int count = 80, String? seed}) {
    final int hash = seed != null && seed.isNotEmpty ? seed.hashCode : 42;
    return List.generate(count, (index) {
      final double t = index / count;
      final double sin1 = ((t * 8.0 * 3.14159) + (hash % 17)).abs();
      final double sin2 = ((t * 19.0 * 3.14159) + (hash % 31)).abs();
      final double sin3 = ((t * 37.0 * 3.14159) + (hash % 7)).abs();
      final double combined = 0.22 + 0.38 * (sin1 % 1.0) + 0.25 * (sin2 % 1.0) + 0.15 * (sin3 % 1.0);
      return combined.clamp(0.1, 0.95);
    });
  }

  static List<double> _generateDefaultWaveform({int count = 80}) =>
      generateDefaultWaveform(count: count);
}
