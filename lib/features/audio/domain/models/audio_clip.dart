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
  double volume; // 0.0 to 1.0
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
    this.volume = 1.0,
    this.isMuted = false,
    List<double>? waveformSamples,
  })  : id = id ?? const Uuid().v4(),
        trimEndMs = trimEndMs ?? durationMs,
        waveformSamples = waveformSamples ?? _generateDefaultWaveform();

  int get endOffsetMs => startOffsetMs + (trimEndMs - trimStartMs);
  int get trimmedDurationMs => (trimEndMs - trimStartMs).clamp(0, durationMs);

  AudioClip copyWith({
    String? title,
    String? filePath,
    int? trackIndex,
    int? startOffsetMs,
    int? durationMs,
    int? trimStartMs,
    int? trimEndMs,
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
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      waveformSamples: samples,
    );
  }

  static List<double> _generateDefaultWaveform({int count = 60}) {
    // Generate an aesthetically natural default waveform
    return List.generate(count, (index) {
      final double normalized = index / count;
      final double sinVal = (normalized * 3.14159 * 4).abs();
      return (0.2 + 0.6 * (sinVal % 1.0)).clamp(0.1, 1.0);
    });
  }
}
