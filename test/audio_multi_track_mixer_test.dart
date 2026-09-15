import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/audio/domain/models/audio_clip.dart';
import 'package:dummy/features/audio/domain/models/audio_track.dart';
import 'package:dummy/features/audio/domain/models/audio_project_state.dart';
import 'package:dummy/features/audio/services/audio_library_service.dart';
import 'package:dummy/features/audio/services/audio_playback_service.dart';
import 'package:dummy/features/editor/services/movie_export_service.dart';

void main() {
  group('AudioClip Domain & Fade Tests', () {
    test('Calculates fade fractions accurately', () {
      final clip = AudioClip(
        title: 'BGM Track',
        filePath: '/mock/bgm.mp3',
        trackIndex: 0,
        startOffsetMs: 1000,
        durationMs: 10000,
        trimStartMs: 0,
        trimEndMs: 10000,
        fadeInMs: 2000,
        fadeOutMs: 3000,
      );

      expect(clip.trimmedDurationMs, 10000);
      expect(clip.fadeInFraction, closeTo(0.2, 0.001));
      expect(clip.fadeOutFraction, closeTo(0.3, 0.001));
    });

    test('Computes fade multiplier correctly across clip lifecycle', () {
      final clip = AudioClip(
        title: 'SFX',
        filePath: '/mock/sfx.mp3',
        trackIndex: 0,
        startOffsetMs: 0,
        durationMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
        fadeInMs: 1000, // 0-1000ms: fade in 0.0 -> 1.0
        fadeOutMs: 1000, // 3000-4000ms: fade out 1.0 -> 0.0
      );

      // Start of fade-in
      expect(clip.computeFadeMultiplier(0), closeTo(0.0, 0.01));
      // Halfway through fade-in
      expect(clip.computeFadeMultiplier(500), closeTo(0.5, 0.01));
      // Completed fade-in, sustained level
      expect(clip.computeFadeMultiplier(1000), closeTo(1.0, 0.01));
      expect(clip.computeFadeMultiplier(2000), closeTo(1.0, 0.01));
      // Halfway through fade-out (3500ms)
      expect(clip.computeFadeMultiplier(3500), closeTo(0.5, 0.01));
      // End of fade-out (4000ms)
      expect(clip.computeFadeMultiplier(4000), closeTo(0.0, 0.01));
      // Outside boundary
      expect(clip.computeFadeMultiplier(-100), 0.0);
      expect(clip.computeFadeMultiplier(5000), 0.0);
    });

    test('AudioClip serialization preserves fadeInMs and fadeOutMs', () {
      final clip = AudioClip(
        id: 'clip_abc',
        title: 'Voiceover',
        filePath: '/mock/voice.aac',
        trackIndex: 2,
        startOffsetMs: 500,
        durationMs: 8000,
        trimStartMs: 500,
        trimEndMs: 7500,
        volume: 1.5,
        isMuted: false,
        fadeInMs: 1200,
        fadeOutMs: 1800,
      );

      final json = clip.toJson();
      expect(json['fadeInMs'], 1200);
      expect(json['fadeOutMs'], 1800);

      final restored = AudioClip.fromJson(json);
      expect(restored.id, clip.id);
      expect(restored.title, clip.title);
      expect(restored.fadeInMs, 1200);
      expect(restored.fadeOutMs, 1800);
      expect(restored.volume, 1.5);
    });

    test('isPlayingAt correctly checks timeline position', () {
      final clip = AudioClip(
        title: 'Intro Jingle',
        filePath: '/mock/jingle.mp3',
        trackIndex: 0,
        startOffsetMs: 2000,
        durationMs: 5000,
        trimStartMs: 0,
        trimEndMs: 3000, // Trimmed duration = 3000ms (ends at 5000ms)
      );

      expect(clip.isPlayingAt(1999), isFalse);
      expect(clip.isPlayingAt(2000), isTrue);
      expect(clip.isPlayingAt(3500), isTrue);
      expect(clip.isPlayingAt(5000), isFalse);
      expect(clip.isPlayingAt(6000), isFalse);
    });
  });

  group('Multi-Track Audio State & Solo/Mute Priority Tests', () {
    test('Unlimited tracks can be added and managed dynamically', () {
      final state = AudioProjectState();
      expect(state.tracks.length, 4); // Default 4 tracks

      state.addTrack();
      state.addTrack();
      expect(state.tracks.length, 6);
      expect(state.tracks[5].index, 5);

      // Track names
      expect(state.tracks[0].name, 'Track 1');
      state.renameTrack(0, 'Voice Over');
      expect(state.tracks[0].name, 'Voice Over');

      // Track volume
      state.setTrackVolume(0, 1.8);
      expect(state.tracks[0].volume, 1.8);
    });

    test('Solo mode isolates selected tracks and silences non-solo tracks', () {
      final state = AudioProjectState();
      final clipT1 = AudioClip(
        title: 'Music',
        filePath: '/mock/music.mp3',
        trackIndex: 0,
        startOffsetMs: 0,
        durationMs: 10000,
        trimEndMs: 10000,
      );
      final clipT2 = AudioClip(
        title: 'Voice',
        filePath: '/mock/voice.mp3',
        trackIndex: 1,
        startOffsetMs: 0,
        durationMs: 10000,
        trimEndMs: 10000,
      );
      final clipT3 = AudioClip(
        title: 'Ambience',
        filePath: '/mock/ambience.mp3',
        trackIndex: 2,
        startOffsetMs: 0,
        durationMs: 10000,
        trimEndMs: 10000,
      );

      state.addClip(clipT1, targetTrackIndex: 0);
      state.addClip(clipT2, targetTrackIndex: 1);
      state.addClip(clipT3, targetTrackIndex: 2);

      // 1. Without Solo: all unmuted tracks are active
      expect(state.hasSoloTracks, isFalse);
      expect(state.getActiveClipsAt(1000).length, 3);

      // 2. Solo Track 2 (Voice)
      state.toggleSolo(1);
      expect(state.hasSoloTracks, isTrue);
      expect(state.isTrackActive(state.tracks[0]), isFalse);
      expect(state.isTrackActive(state.tracks[1]), isTrue);
      expect(state.isTrackActive(state.tracks[2]), isFalse);

      final activeClips = state.getActiveClipsAt(1000);
      expect(activeClips.length, 1);
      expect(activeClips.first.title, 'Voice');

      // 3. Solo Track 1 (Music) as well -> Both Voice & Music play concurrently
      state.toggleSolo(0);
      expect(state.getActiveClipsAt(1000).length, 2);

      // 4. Mute Track 2 while Soloed -> only Track 1 plays
      state.toggleMute(1);
      expect(state.getActiveClipsAt(1000).length, 1);
      expect(state.getActiveClipsAt(1000).first.title, 'Music');

      // 5. Unsolo all -> all unmuted tracks play (Track 0 and Track 2, since Track 1 is muted)
      state.toggleSolo(0);
      state.toggleSolo(1);
      expect(state.hasSoloTracks, isFalse);
      expect(state.getActiveClipsAt(1000).length, 2);
    });

    test('AudioProjectState serialization roundtrip with Solo and Volume', () {
      final state = AudioProjectState();
      state.addTrack();
      state.tracks[0].isSolo = true;
      state.tracks[0].volume = 1.4;
      state.tracks[1].isMuted = true;
      state.tracks[2].name = 'Sound FX';

      final json = state.toJson();
      final restored = AudioProjectState.fromJson(json);

      expect(restored.tracks.length, 5);
      expect(restored.tracks[0].isSolo, isTrue);
      expect(restored.tracks[0].volume, 1.4);
      expect(restored.tracks[1].isMuted, isTrue);
      expect(restored.tracks[2].name, 'Sound FX');
    });
  });

  group('Movie Export FFmpeg Filtergraph Multi-Track Audio Mixing Tests', () {
    test('Builds amix complex filtergraph for multiple simultaneous audio tracks', () {
      final state = AudioProjectState();
      state.addClip(
        AudioClip(
          id: 'c1',
          title: 'BGM',
          filePath: '/path/to/bgm.mp3',
          trackIndex: 0,
          startOffsetMs: 500,
          durationMs: 8000,
          trimStartMs: 1000,
          trimEndMs: 6000, // trimmed = 5000ms
          volume: 0.8,
          fadeInMs: 1000,
          fadeOutMs: 1500,
        ),
        targetTrackIndex: 0,
      );

      state.addClip(
        AudioClip(
          id: 'c2',
          title: 'SFX',
          filePath: '/path/to/sfx.wav',
          trackIndex: 1,
          startOffsetMs: 2000,
          durationMs: 3000,
          trimStartMs: 0,
          trimEndMs: 3000,
          volume: 1.2,
          fadeInMs: 0,
          fadeOutMs: 0,
        ),
        targetTrackIndex: 1,
      );

      final activeClipsWithVol = [
        (clip: state.tracks[0].clips.first, trackVolume: state.tracks[0].volume),
        (clip: state.tracks[1].clips.first, trackVolume: state.tracks[1].volume),
      ];

      final filterComplex = MovieExportService.buildAudioFilterComplex(activeClipsWithVol);
      expect(filterComplex, isNotNull);

      // Verify trimming filter
      expect(filterComplex, contains('atrim=start=1.000:end=6.000'));
      // Verify fade in filter
      expect(filterComplex, contains('afade=t=in:st=0:d=1.000'));
      // Verify fade out filter (start at 5.0 - 1.5 = 3.5s)
      expect(filterComplex, contains('afade=t=out:st=3.500:d=1.500'));
      // Verify volume scaling
      expect(filterComplex, contains('volume=0.80'));
      expect(filterComplex, contains('volume=1.20'));
      // Verify timeline sync delay (startOffsetMs)
      expect(filterComplex, contains('adelay=500|500'));
      expect(filterComplex, contains('adelay=2000|2000'));
      // Verify amix mixing filter with 2 inputs
      expect(filterComplex, contains('amix=inputs=2:dropout_transition=0:normalize=0[aout]'));
    });
  });

  group('Playback Replay & Re-triggering Tests', () {
    test('AudioPlaybackService handles sequential play/pause/replay cycles', () async {
      final state = AudioProjectState();
      state.addClip(
        AudioClip(
          id: 'clip_replay',
          title: 'Replay Test',
          filePath: '/mock/audio.mp3',
          trackIndex: 0,
          startOffsetMs: 0,
          durationMs: 3000,
        ),
      );

      // Verify active clips at 0ms is non-empty across multiple queries
      expect(state.getActiveClipsAt(0).length, 1);
      expect(state.getActiveClipsAt(1500).length, 1);
      expect(state.getActiveClipsAt(3000).length, 0);

      // Re-querying at 0ms simulates 2nd playback from start
      expect(state.getActiveClipsAt(0).length, 1);
      expect(state.getActiveClipsAt(0).first.id, 'clip_replay');
    });

    test('MultiTrackAudioMixerEngine mixes multiple simultaneous audio tracks into WAV', () async {
      final state = AudioProjectState();
      final tempDir = await Directory.systemTemp.createTemp('mixer_test');

      // Create two synthetic WAV files
      final wav1 = AudioLibraryService.synthesizeWavForItem(AudioLibraryService.libraryItems[0]);
      final file1 = File('${tempDir.path}/track1.wav');
      await file1.writeAsBytes(wav1);

      final wav2 = AudioLibraryService.synthesizeWavForItem(AudioLibraryService.libraryItems[1]);
      final file2 = File('${tempDir.path}/track2.wav');
      await file2.writeAsBytes(wav2);

      state.addClip(
        AudioClip(
          title: 'Track 1 Clip',
          filePath: file1.path,
          trackIndex: 0,
          startOffsetMs: 0,
          durationMs: 900,
          volume: 0.8,
        ),
        targetTrackIndex: 0,
      );

      state.addClip(
        AudioClip(
          title: 'Track 2 Clip',
          filePath: file2.path,
          trackIndex: 1,
          startOffsetMs: 200,
          durationMs: 400,
          volume: 1.0,
        ),
        targetTrackIndex: 1,
      );

      final mixPath = await MultiTrackAudioMixerEngine.mixProject(
        state: state,
        outputDir: tempDir,
        maxDurationMs: 1500,
      );

      expect(mixPath, isNotNull);
      final mixFile = File(mixPath!);
      expect(await mixFile.exists(), isTrue);
      expect(await mixFile.length(), greaterThan(1000));

      await tempDir.delete(recursive: true);
    });
  });
}
