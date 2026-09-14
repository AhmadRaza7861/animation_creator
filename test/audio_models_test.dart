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

    test('AudioProjectState handles multi-track parallel audio clips across 4 tracks', () {
      final state = AudioProjectState();

      // Track 1 (idx 0): Recording 3 (0s to 3s)
      final clipT1 = AudioClip(
        id: 't1_clip',
        title: 'Recording 3',
        filePath: '/mock/rec3.wav',
        trackIndex: 0,
        startOffsetMs: 0,
        durationMs: 3000,
      );

      // Track 2 (idx 1): Recording 1 (500ms to 2000ms) - plays concurrently in parallel
      final clipT2 = AudioClip(
        id: 't2_clip',
        title: 'Recording 1',
        filePath: '/mock/rec1.wav',
        trackIndex: 1,
        startOffsetMs: 500,
        durationMs: 1500,
      );

      // Track 3 (idx 2): Recording 3 copy (300ms to 1800ms)
      final clipT3 = AudioClip(
        id: 't3_clip',
        title: 'Recording 3',
        filePath: '/mock/rec3_alt.wav',
        trackIndex: 2,
        startOffsetMs: 300,
        durationMs: 1500,
      );

      // Track 4 (idx 3): Recording 3 (0s to 2500ms)
      final clipT4 = AudioClip(
        id: 't4_clip',
        title: 'Recording 3 (Trunk)',
        filePath: '/mock/rec3_trunk.wav',
        trackIndex: 3,
        startOffsetMs: 0,
        durationMs: 2500,
      );

      state.addClip(clipT1, targetTrackIndex: 0);
      state.addClip(clipT2, targetTrackIndex: 1);
      state.addClip(clipT3, targetTrackIndex: 2);
      state.addClip(clipT4, targetTrackIndex: 3);

      expect(state.tracks[0].clips.length, 1);
      expect(state.tracks[1].clips.length, 1);
      expect(state.tracks[2].clips.length, 1);
      expect(state.tracks[3].clips.length, 1);

      // Move clip from Track 1 down to Track 4
      state.tracks[0].clips.removeWhere((c) => c.id == 't1_clip');
      clipT1.trackIndex = 3;
      state.tracks[3].clips.add(clipT1);

      expect(state.tracks[0].clips.length, 0);
      expect(state.tracks[3].clips.length, 2);
      expect(state.tracks[3].clips.map((c) => c.id), contains('t1_clip'));
    });

    test('AudioProjectState dynamically adds and manages Track 5 (T5), Track 6 (T6) and beyond', () {
      final state = AudioProjectState();
      expect(state.tracks.length, 4);

      // Add Track 5
      final track5 = state.addTrack();
      expect(track5.index, 4);
      expect(track5.name, 'Track 5');
      expect(state.tracks.length, 5);

      // Add clip to Track 5
      final clipT5 = AudioClip(
        id: 't5_clip',
        title: 'Background Ambience',
        filePath: '/mock/ambience.wav',
        trackIndex: 4,
        startOffsetMs: 1000,
        durationMs: 5000,
      );
      state.addClip(clipT5, targetTrackIndex: 4);

      expect(state.tracks[4].clips.length, 1);
      expect(state.findClip('t5_clip')?.trackIndex, 4);

      // Ensure track count to 8
      state.ensureTrackCount(8);
      expect(state.tracks.length, 8);
      expect(state.tracks[7].index, 7);
      expect(state.tracks[7].name, 'Track 8');

      // Test JSON persistence for 8 tracks
      final json = state.toJson();
      final restored = AudioProjectState.fromJson(json);
      expect(restored.tracks.length, 8);
      expect(restored.findClip('t5_clip')?.trackIndex, 4);

      // Test track removal
      final removed = state.removeTrack(7);
      expect(removed, isTrue);
      expect(state.tracks.length, 7);
    });

    test('Magnetic attraction and overlap resolution when moving clips between tracks', () {
      final state = AudioProjectState();
      state.ensureTrackCount(6); // Tracks T1 to T6

      // T6 has Bubble audio clip at [0ms .. 600ms]
      final bubbleClip = AudioClip(
        id: 'bubble_clip',
        title: 'Bubble Pop',
        filePath: '/mock/bubble.wav',
        trackIndex: 5,
        startOffsetMs: 0,
        durationMs: 600,
      );
      state.addClip(bubbleClip, targetTrackIndex: 5);

      // T5 has Action Hit clip at [1300ms .. 1800ms] (separated by distance)
      final actionClip = AudioClip(
        id: 'action_clip',
        title: 'Action Hit',
        filePath: '/mock/action.wav',
        trackIndex: 4,
        startOffsetMs: 1300,
        durationMs: 500,
      );
      state.addClip(actionClip, targetTrackIndex: 4);

      final track6 = state.tracks[5];

      // 1. Moving Action Hit from T5 down to T6 preserves its independent 1300ms position with ZERO overlap
      final safeOffset1300 = track6.clampOffsetToPreventOverlap(actionClip, 1300);
      expect(safeOffset1300, 1300); // 1300ms is free and stays 1300ms!

      // 2. Clips do NOT automatically pull or jump across empty space:
      final offset650 = track6.findMagneticSnapOffset(actionClip, 650);
      expect(offset650, 650); // Stays at 650ms, no jumping!

      // 3. Test Overlap Clamping on T6:
      // When dragged into an overlapping position (e.g. 200ms which collides with [0 .. 600ms]):
      final safeOffset = track6.clampOffsetToPreventOverlap(actionClip, 200);
      expect(safeOffset, 600); // Clamped to sit cleanly after bubbleClip at 600ms

      // Move actionClip from T5 down into T6
      state.tracks[4].clips.removeWhere((c) => c.id == actionClip.id);
      actionClip.trackIndex = 5;
      actionClip.startOffsetMs = 1300;
      state.tracks[5].clips.add(actionClip);
      state.tracks[5].resolveOverlapForClip(actionClip);

      // Verify both clips on Track 6 maintain clean separation without overlap
      expect(state.tracks[5].clips.length, 2);
      expect(bubbleClip.startOffsetMs, 0);
      expect(bubbleClip.endOffsetMs, 600);
      expect(actionClip.startOffsetMs, 1300);
      expect(actionClip.endOffsetMs, 1800);
      expect(bubbleClip.endOffsetMs <= actionClip.startOffsetMs, isTrue);
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
