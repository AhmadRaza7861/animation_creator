import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../../../core/utils/app_path_provider.dart';
import '../domain/models/audio_clip.dart';

class AudioLibraryItem {
  final String id;
  final String title;
  final String category; // 'Cartoon', 'Action', 'Game', 'Magic', 'Music'
  final String icon;
  final int durationMs;
  final String description;

  AudioLibraryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.durationMs,
    required this.description,
  });
}

class AudioLibraryService {
  static final List<AudioLibraryItem> libraryItems = [
    // Cartoon Category
    AudioLibraryItem(
      id: 'sfx_boing',
      title: 'Cartoon Boing',
      category: 'Cartoon',
      icon: '🎪',
      durationMs: 900,
      description: 'Springy bouncy cartoon boing sound',
    ),
    AudioLibraryItem(
      id: 'sfx_pop',
      title: 'Bubble Pop',
      category: 'Cartoon',
      icon: '🫧',
      durationMs: 400,
      description: 'Crisp bubble burst pop',
    ),
    AudioLibraryItem(
      id: 'sfx_slide_whistle',
      title: 'Slide Whistle',
      category: 'Cartoon',
      icon: '🎺',
      durationMs: 1200,
      description: 'Ascending slide whistle glide',
    ),
    AudioLibraryItem(
      id: 'sfx_whoosh',
      title: 'Fast Whoosh',
      category: 'Cartoon',
      icon: '💨',
      durationMs: 600,
      description: 'Quick air whip whoosh sound',
    ),

    // Action Category
    AudioLibraryItem(
      id: 'sfx_punch',
      title: 'Action Hit',
      category: 'Action',
      icon: '🥊',
      durationMs: 500,
      description: 'Punchy impact hit sound',
    ),
    AudioLibraryItem(
      id: 'sfx_laser',
      title: 'Laser Blast',
      category: 'Action',
      icon: '⚡',
      durationMs: 700,
      description: 'Sci-fi futuristic laser ray',
    ),
    AudioLibraryItem(
      id: 'sfx_explosion',
      title: 'Boom Blast',
      category: 'Action',
      icon: '💥',
      durationMs: 1400,
      description: 'Deep explosive reverberating boom',
    ),

    // Game Category
    AudioLibraryItem(
      id: 'sfx_jump',
      title: 'Arcade Jump',
      category: 'Game',
      icon: '🦘',
      durationMs: 650,
      description: '8-bit retro arcade jump sound',
    ),
    AudioLibraryItem(
      id: 'sfx_coin',
      title: 'Collect Coin',
      category: 'Game',
      icon: '🪙',
      durationMs: 500,
      description: 'Bright sparkly coin pickup chime',
    ),
    AudioLibraryItem(
      id: 'sfx_powerup',
      title: 'Power Up',
      category: 'Game',
      icon: '⭐',
      durationMs: 1100,
      description: 'Ascending arpeggio energy boost',
    ),

    // Magic Category
    AudioLibraryItem(
      id: 'sfx_magic_chime',
      title: 'Magic Sparkle',
      category: 'Magic',
      icon: '✨',
      durationMs: 1500,
      description: 'Enchanted shimmering crystal chime',
    ),
    AudioLibraryItem(
      id: 'sfx_bell',
      title: 'Clear Bell',
      category: 'Magic',
      icon: '🔔',
      durationMs: 1200,
      description: 'Pure resonant high bell tone',
    ),

    // Music Category
    AudioLibraryItem(
      id: 'bgm_cheerful',
      title: 'Happy Vibes Loop',
      category: 'Music',
      icon: '🎵',
      durationMs: 3200,
      description: 'Upbeat cheerful acoustic groove loop',
    ),
    AudioLibraryItem(
      id: 'bgm_retro',
      title: 'Retro Pixel Beat',
      category: 'Music',
      icon: '🎮',
      durationMs: 2800,
      description: 'Funky chiptune synth bassline loop',
    ),
  ];

  static Future<AudioClip> generateOrGetClip(AudioLibraryItem item) async {
    final dir = await AppPathProvider.getSafeDocumentsDirectory();
    final sfxDir = Directory('${dir.path}/sfx_cache');
    if (!await sfxDir.exists()) {
      await sfxDir.create(recursive: true);
    }

    final File sfxFile = File('${sfxDir.path}/${item.id}.wav');
    if (!await sfxFile.exists() || await sfxFile.length() < 100) {
      final Uint8List wavBytes = synthesizeWavForItem(item);
      await sfxFile.writeAsBytes(wavBytes, flush: true);
    }

    final samples = _generateSampleWaveform(item.id);

    return AudioClip(
      title: item.title,
      filePath: sfxFile.path,
      durationMs: item.durationMs,
      waveformSamples: samples,
    );
  }

  static Uint8List synthesizeWavForItem(AudioLibraryItem item) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * (item.durationMs / 1000.0)).round();
    final Int16List pcmData = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double progress = i / numSamples;
      double sample = 0.0;

      switch (item.id) {
        case 'sfx_boing':
          // Modulated frequency sine with bouncy decay
          final double freq = 220.0 + 350.0 * math.sin(t * 22.0) * math.exp(-progress * 2.5);
          sample = math.sin(2 * math.pi * freq * t) * (1.0 - progress);
          break;

        case 'sfx_pop':
          // Rapid decaying pop tone
          final double freq = 700.0 * math.exp(-progress * 8.0);
          sample = math.sin(2 * math.pi * freq * t) * math.exp(-progress * 6.0);
          break;

        case 'sfx_slide_whistle':
          // Ascending glide
          final double freq = 300.0 + 800.0 * progress;
          sample = math.sin(2 * math.pi * freq * t) * (1.0 - math.pow(progress, 3));
          break;

        case 'sfx_whoosh':
          // Filtered noise swoosh
          final double noise = (math.Random(i).nextDouble() * 2.0 - 1.0);
          final double envelope = math.sin(math.pi * progress);
          sample = noise * envelope * 0.7;
          break;

        case 'sfx_punch':
          // Low punch with noise burst
          final double sub = math.sin(2 * math.pi * (140.0 * (1.0 - progress)) * t);
          final double noise = (math.Random(i).nextDouble() * 2.0 - 1.0) * math.exp(-progress * 9.0);
          sample = (sub * 0.7 + noise * 0.5) * math.exp(-progress * 4.0);
          break;

        case 'sfx_laser':
          // Downward chirp
          final double freq = 1600.0 * math.exp(-progress * 5.0) + 120.0;
          sample = math.sin(2 * math.pi * freq * t) * (1.0 - progress);
          break;

        case 'sfx_explosion':
          // Low rumble noise
          final double noise = (math.Random(i).nextDouble() * 2.0 - 1.0);
          final double rumble = math.sin(2 * math.pi * 65.0 * t);
          sample = (noise * 0.7 + rumble * 0.5) * math.exp(-progress * 2.0);
          break;

        case 'sfx_jump':
          // Quick retro upward square wave
          final double freq = 200.0 + 700.0 * math.pow(progress, 0.5);
          final double square = (math.sin(2 * math.pi * freq * t) > 0 ? 1.0 : -1.0);
          sample = square * (1.0 - progress) * 0.6;
          break;

        case 'sfx_coin':
          // Two-tone bright chime (B5 -> E6)
          final double freq = progress < 0.35 ? 987.77 : 1318.51;
          sample = math.sin(2 * math.pi * freq * t) * math.exp(-progress * 3.5);
          break;

        case 'sfx_powerup':
          // Arpeggio notes (C5, E5, G5, C6)
          final List<double> notes = [523.25, 659.25, 783.99, 1046.50];
          final int noteIdx = (progress * notes.length).floor().clamp(0, notes.length - 1);
          sample = (math.sin(2 * math.pi * notes[noteIdx] * t) > 0 ? 0.7 : -0.7) * (1.0 - progress * 0.5);
          break;

        case 'sfx_magic_chime':
          // Harmonic shimmer
          sample = (math.sin(2 * math.pi * 1200.0 * t) * 0.4 +
                  math.sin(2 * math.pi * 1800.0 * t) * 0.3 +
                  math.sin(2 * math.pi * 2400.0 * t) * 0.2) *
              math.exp(-progress * 2.0);
          break;

        case 'sfx_bell':
          // Pristine bell harmonics
          sample = (math.sin(2 * math.pi * 880.0 * t) * 0.6 +
                  math.sin(2 * math.pi * 1760.0 * t) * 0.3) *
              math.exp(-progress * 2.2);
          break;

        case 'bgm_cheerful':
        case 'bgm_retro':
        default:
          // Melodic sequence loop
          final List<double> chord = [440.0, 554.37, 659.25, 880.0];
          final int step = ((t * 4.0).floor()) % chord.length;
          final double base = math.sin(2 * math.pi * chord[step] * t);
          final double beat = math.sin(2 * math.pi * 110.0 * t) * ((t * 2.0) % 1.0 < 0.2 ? 1.0 : 0.0);
          sample = (base * 0.5 + beat * 0.4) * 0.8;
          break;
      }

      pcmData[i] = (sample.clamp(-1.0, 1.0) * 32767.0).round();
    }

    return _buildWavHeaderAndData(pcmData, sampleRate: sampleRate);
  }

  static Uint8List _buildWavHeaderAndData(Int16List pcmData, {required int sampleRate}) {
    final int dataSize = pcmData.lengthInBytes;
    final int fileSize = 36 + dataSize;
    final ByteData header = ByteData(44);

    // RIFF
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    header.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    header.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
    header.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List(header.offsetInBytes, 44));
    wavBytes.setRange(44, 44 + dataSize, pcmData.buffer.asUint8List(pcmData.offsetInBytes, dataSize));
    return wavBytes;
  }

  static List<double> _generateSampleWaveform(String id, {int count = 60}) {
    return List.generate(count, (index) {
      final double p = index / count;
      if (id.contains('pop') || id.contains('punch')) {
        return (math.exp(-p * 4.0) * (0.3 + 0.7 * math.sin(p * 15.0).abs())).clamp(0.1, 1.0);
      } else if (id.contains('laser') || id.contains('whistle')) {
        return (0.2 + 0.7 * math.sin(p * 10.0).abs()).clamp(0.1, 1.0);
      } else if (id.contains('magic') || id.contains('chime')) {
        return (0.3 + 0.6 * math.cos(p * 8.0).abs() * math.exp(-p * 1.5)).clamp(0.1, 1.0);
      }
      return (0.2 + 0.6 * math.sin(p * 12.0).abs()).clamp(0.1, 1.0);
    });
  }
}
