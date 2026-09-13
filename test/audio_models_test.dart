import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/audio/domain/models/audio_clip.dart';
import 'package:dummy/features/audio/domain/models/audio_track.dart';
import 'package:dummy/features/audio/domain/models/audio_project_state.dart';
import 'package:dummy/features/audio/services/audio_library_service.dart';
import 'package:dummy/features/audio/services/voice_maker_service.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Domain Models & Serialization Tests', () {
    test('AudioClip initializes, calculates offsets, and serializes accurately', () {
      final clip = AudioClip(
        id: 'test_clip_1',
        title: 'Voice Over',
        filePath: '/mock/path/voice.m4a',
        trackIndex: 1,
        startOffsetMs: 500,
        durationMs: 3000,
        trimStartMs: 200,
        trimEndMs: 2500,
        volume: 0.8,
        isMuted: false,
      );

      expect(clip.trimmedDurationMs, 2300);
      expect(clip.endOffsetMs, 2800);

      final json = clip.toJson();
      final fromJson = AudioClip.fromJson(json);

      expect(fromJson.id, 'test_clip_1');
      expect(fromJson.title, 'Voice Over');
      expect(fromJson.filePath, '/mock/path/voice.m4a');
      expect(fromJson.trackIndex, 1);
      expect(fromJson.startOffsetMs, 500);
      expect(fromJson.durationMs, 3000);
      expect(fromJson.trimStartMs, 200);
      expect(fromJson.trimEndMs, 2500);
      expect(fromJson.trimmedDurationMs, 2300);
      expect(fromJson.volume, 0.8);
      expect(fromJson.isMuted, isFalse);
      expect(fromJson.waveformSamples, isNotEmpty);
    });

    test('AudioTrack manages clips, muting, locking, and serializes accurately', () {
      final track = AudioTrack(index: 2, name: 'Effects Track');
      expect(track.index, 2);
      expect(track.name, 'Effects Track');
      expect(track.isMuted, isFalse);
      expect(track.isLocked, isFalse);
      expect(track.clips, isEmpty);

      final clip = AudioClip(
        title: 'Pop Sound',
        filePath: '/mock/pop.wav',
        durationMs: 600,
      );
      track.clips.add(clip);

      final json = track.toJson();
      final fromJson = AudioTrack.fromJson(json);

      expect(fromJson.index, 2);
      expect(fromJson.name, 'Effects Track');
      expect(fromJson.clips.length, 1);
      expect(fromJson.clips.first.title, 'Pop Sound');
    });

    test('AudioProjectState initializes with 4 tracks and handles clip mutations', () {
      final state = AudioProjectState();
      expect(state.tracks.length, 4);
      expect(state.isEmpty, isTrue);

      final clip1 = AudioClip(
        id: 'c1',
        title: 'Dialogue',
        filePath: '/mock/d.wav',
        trackIndex: 0,
        startOffsetMs: 0,
        durationMs: 2000,
      );
      final clip2 = AudioClip(
        id: 'c2',
        title: 'Music',
        filePath: '/mock/m.wav',
        trackIndex: 1,
        startOffsetMs: 1500,
        durationMs: 4000,
      );

      state.addClip(clip1);
      state.addClip(clip2);

      expect(state.isEmpty, isFalse);
      expect(state.allClips.length, 2);
      expect(state.findClip('c1'), isNotNull);
      expect(state.findClip('c2'), isNotNull);
      expect(state.maxDurationMs, 5500);

      // Toggle mute & lock
      state.toggleMute(0);
      expect(state.tracks[0].isMuted, isTrue);
      state.toggleLock(1);
      expect(state.tracks[1].isLocked, isTrue);

      // Move clip
      final updatedClip = clip1.copyWith(startOffsetMs: 1000);
      state.updateClip(updatedClip);
      expect(state.findClip('c1')?.startOffsetMs, 1000);

      // JSON serialization
      final json = state.toJson();
      final fromJson = AudioProjectState.fromJson(json);
      expect(fromJson.tracks.length, 4);
      expect(fromJson.allClips.length, 2);
      expect(fromJson.tracks[0].isMuted, isTrue);
      expect(fromJson.tracks[1].isLocked, isTrue);

      // Remove clip
      state.removeClip('c1');
      expect(state.allClips.length, 1);
      expect(state.findClip('c1'), isNull);
    });

    test('AudioLibraryService generates valid RIFF WAV audio files', () {
      final item = AudioLibraryService.libraryItems.firstWhere((i) => i.id == 'sfx_boing');
      expect(item.title, 'Cartoon Boing');
      expect(item.durationMs, greaterThan(0));

      final Uint8List wavBytes = AudioLibraryService.synthesizeWavForItem(item);
      expect(wavBytes.length, greaterThan(44));

      // Verify RIFF WAVE header bytes
      final String riff = String.fromCharCodes(wavBytes.sublist(0, 4));
      final String wave = String.fromCharCodes(wavBytes.sublist(8, 12));
      final String fmt = String.fromCharCodes(wavBytes.sublist(12, 16));
      final String data = String.fromCharCodes(wavBytes.sublist(36, 40));

      expect(riff, 'RIFF');
      expect(wave, 'WAVE');
      expect(fmt, 'fmt ');
      expect(data, 'data');
    });

    test('VoiceMakerService generates valid synthesized character voices', () {
      final preset = VoiceMakerService.presets.firstWhere((p) => p.id == 'voice_robot');
      expect(preset.name, 'Cyber Robot');

      final Uint8List wavBytes = VoiceMakerService.synthesizeVoiceWav(
        durationMs: 1500,
        preset: preset,
        speed: 1.0,
        pitch: 1.0,
      );

      expect(wavBytes.length, greaterThan(44));
      final String riff = String.fromCharCodes(wavBytes.sublist(0, 4));
      final String wave = String.fromCharCodes(wavBytes.sublist(8, 12));
      expect(riff, 'RIFF');
      expect(wave, 'WAVE');
    });

    test('EditorController automatically adds frames according to audio duration and FPS', () {
      final repository = ProjectRepository();
      final controller = EditorController(repository: repository);
      controller.fps = 9;

      // Initially project has 1 frame
      expect(controller.canvases.length, 1);

      // Add a 3-second (3000ms) audio clip
      final state = AudioProjectState();
      state.addClip(
        AudioClip(
          title: '3-second audio',
          filePath: '/mock/voice.m4a',
          durationMs: 3000,
        ),
      );

      // Updating audio state should automatically expand canvases to 27 frames (3s * 9 fps)
      final addedFrames = controller.updateAudioState(state, autoAddFrames: true);
      expect(addedFrames, 26);
      expect(controller.canvases.length, 27);
      expect(controller.thumbnails.length, 27);

      // Adding a second clip extending to 5000ms at 9 fps -> ceil(5 * 9) = 45 frames
      state.addClip(
        AudioClip(
          title: 'Outro sound',
          filePath: '/mock/outro.wav',
          startOffsetMs: 3000,
          durationMs: 2000,
        ),
      );

      final addedFrames2 = controller.updateAudioState(state, autoAddFrames: true);
      expect(addedFrames2, 18); // 45 - 27
      expect(controller.canvases.length, 45);

      // Changing FPS from 9 to 12 should auto-expand frames to 5s * 12 fps = 60 frames
      controller.fps = 12;
      expect(controller.canvases.length, 60);

      controller.dispose();
    });

    test('EditorController persists and restores AudioProjectState', () async {
      final repository = ProjectRepository();
      final controller = EditorController(repository: repository);

      expect(controller.audioState.allClips, isEmpty);
      expect(controller.isAudioStudioOpen, isFalse);

      final clip = AudioClip(
        title: 'Intro SFX',
        filePath: '/mock/intro.wav',
        durationMs: 1200,
      );
      controller.audioState.addClip(clip);
      controller.isAudioStudioOpen = true;

      expect(controller.isAudioStudioOpen, isTrue);
      expect(controller.audioState.allClips.length, 1);

      controller.projectName = 'Audio Animation Test';
      await controller.saveProject();

      final projectId = controller.projectId!;
      final loaded = await repository.loadProject(projectId);

      expect(loaded, isNotNull);
      expect(loaded!.state.containsKey('audio'), isTrue);

      final restoredAudio = AudioProjectState.fromJson(loaded.state['audio'] as Map<String, dynamic>);
      expect(restoredAudio.allClips.length, 1);
      expect(restoredAudio.allClips.first.title, 'Intro SFX');

      await repository.deleteProject(projectId);
      controller.dispose();
    });
  });
}
