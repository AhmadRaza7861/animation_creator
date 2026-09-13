import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../../../core/utils/app_path_provider.dart';
import '../domain/models/audio_clip.dart';

class VoiceStylePreset {
  final String id;
  final String name;
  final String icon;
  final double basePitch; // Frequency multiplier
  final double modulationSpeed;
  final String sampleText;

  const VoiceStylePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.basePitch,
    required this.modulationSpeed,
    required this.sampleText,
  });
}

class VoiceMakerService {
  static const List<VoiceStylePreset> presets = [
    VoiceStylePreset(
      id: 'voice_narrator',
      name: 'Narrator',
      icon: '🎙️',
      basePitch: 1.0,
      modulationSpeed: 1.0,
      sampleText: 'Welcome to the animation adventure!',
    ),
    VoiceStylePreset(
      id: 'voice_chipmunk',
      name: 'Cute Chipmunk',
      icon: '🐿️',
      basePitch: 2.2,
      modulationSpeed: 1.8,
      sampleText: 'Hey there! Look what I found!',
    ),
    VoiceStylePreset(
      id: 'voice_monster',
      name: 'Deep Hero / Giant',
      icon: '👹',
      basePitch: 0.55,
      modulationSpeed: 0.7,
      sampleText: 'Prepare for supreme power!',
    ),
    VoiceStylePreset(
      id: 'voice_robot',
      name: 'Cyber Robot',
      icon: '🤖',
      basePitch: 1.1,
      modulationSpeed: 14.0,
      sampleText: 'System initialized. Ready for animation.',
    ),
    VoiceStylePreset(
      id: 'voice_alien',
      name: 'Alien Visitor',
      icon: '👽',
      basePitch: 1.6,
      modulationSpeed: 8.5,
      sampleText: 'Greetings from distant galaxies!',
    ),
  ];

  static Future<AudioClip> synthesizeVoiceClip({
    required String text,
    required VoiceStylePreset preset,
    double speed = 1.0,
    double pitch = 1.0,
  }) async {
    final dir = await AppPathProvider.getSafeDocumentsDirectory();
    final voiceDir = Directory('${dir.path}/voices');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    final String safeName = text.trim().isNotEmpty
        ? text.trim().split(' ').take(3).join('_').replaceAll(RegExp(r'[^\w]'), '')
        : 'Voice';
    final String fileName = 'voice_${preset.id}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final File voiceFile = File('${voiceDir.path}/$fileName');

    final int durationMs = (text.trim().length * 75 / speed).round().clamp(1200, 8000);
    final Uint8List wavBytes = synthesizeVoiceWav(
      durationMs: durationMs,
      preset: preset,
      speed: speed,
      pitch: pitch,
    );

    await voiceFile.writeAsBytes(wavBytes, flush: true);

    final List<double> waveform = List.generate(60, (index) {
      final double progress = index / 60.0;
      final double env = math.sin(math.pi * progress);
      return (0.2 + 0.7 * env * (0.5 + 0.5 * math.sin(index * 1.5).abs())).clamp(0.1, 1.0);
    });

    return AudioClip(
      title: '${preset.name}: $safeName',
      filePath: voiceFile.path,
      durationMs: durationMs,
      waveformSamples: waveform,
    );
  }

  static Uint8List synthesizeVoiceWav({
    required int durationMs,
    required VoiceStylePreset preset,
    required double speed,
    required double pitch,
  }) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final Int16List pcmData = Int16List(numSamples);

    final double effectivePitch = preset.basePitch * pitch;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double progress = i / numSamples;

      // Vocal formant envelope
      final double syllableEnvelope = (math.sin(2 * math.pi * 3.5 * speed * t).abs() + 0.2).clamp(0.0, 1.0);
      final double mainEnvelope = math.sin(math.pi * progress);

      double sample = 0.0;

      if (preset.id == 'voice_robot') {
        // Ring modulation & metallic harmonics
        final double fundamental = 160.0 * effectivePitch;
        final double carrier = math.sin(2 * math.pi * fundamental * t) > 0 ? 0.7 : -0.7;
        final double modulator = math.sin(2 * math.pi * 40.0 * t);
        sample = carrier * modulator * syllableEnvelope * mainEnvelope;
      } else if (preset.id == 'voice_alien') {
        // Dual freq vibrato glide
        final double f1 = 320.0 * effectivePitch * (1.0 + 0.15 * math.sin(t * preset.modulationSpeed));
        sample = math.sin(2 * math.pi * f1 * t) * syllableEnvelope * mainEnvelope;
      } else if (preset.id == 'voice_chipmunk') {
        // High harmonic chirp
        final double f1 = 440.0 * effectivePitch;
        final double f2 = 880.0 * effectivePitch;
        sample = (math.sin(2 * math.pi * f1 * t) * 0.7 + math.sin(2 * math.pi * f2 * t) * 0.4) *
            syllableEnvelope *
            mainEnvelope;
      } else if (preset.id == 'voice_monster') {
        // Deep sub-harmonic growl
        final double sub = math.sin(2 * math.pi * (85.0 * effectivePitch) * t);
        final double mid = math.sin(2 * math.pi * (170.0 * effectivePitch) * t);
        sample = (sub * 0.75 + mid * 0.35) * syllableEnvelope * mainEnvelope;
      } else {
        // Narrator natural resonant voice
        final double f1 = 180.0 * effectivePitch;
        final double f2 = 360.0 * effectivePitch;
        sample = (math.sin(2 * math.pi * f1 * t) * 0.6 + math.sin(2 * math.pi * f2 * t) * 0.3) *
            syllableEnvelope *
            mainEnvelope;
      }

      pcmData[i] = (sample.clamp(-1.0, 1.0) * 32767.0).round();
    }

    // Reuse WAV builder from AudioLibraryService
    final int dataSize = pcmData.lengthInBytes;
    final int fileSize = 36 + dataSize;
    final ByteData header = ByteData(44);

    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);

    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());
    wavBytes.setRange(44, 44 + dataSize, pcmData.buffer.asUint8List());
    return wavBytes;
  }
}
