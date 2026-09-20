import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/audio/domain/models/audio_clip.dart';
import 'package:dummy/features/audio/domain/models/audio_project_state.dart';
import 'package:dummy/features/audio/presentation/widgets/audio_timeline_studio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioTimelineStudio Gestures & 2D Manipulation Tests', () {
    late AudioProjectState audioState;
    late AudioClip clip1;
    late AudioClip clip2;
    AudioProjectState? lastUpdatedState;
    int lastUpdatedFrame = 0;

    setUp(() {
      audioState = AudioProjectState();
      clip1 = AudioClip(
        id: 'clip_t1',
        title: 'Voiceover 1',
        filePath: '/mock/voice.m4a',
        trackIndex: 0,
        startOffsetMs: 1000,
        durationMs: 4000,
        trimStartMs: 0,
        trimEndMs: 4000,
      );
      clip2 = AudioClip(
        id: 'clip_t2',
        title: 'Background Music',
        filePath: '/mock/music.mp3',
        trackIndex: 1,
        startOffsetMs: 500,
        durationMs: 5000,
        trimStartMs: 0,
        trimEndMs: 5000,
      );

      audioState.addClip(clip1);
      audioState.addClip(clip2);
      clip1 = audioState.findClip('clip_t1')!;
      clip2 = audioState.findClip('clip_t2')!;
      lastUpdatedState = null;
      lastUpdatedFrame = 0;
    });

    Future<void> pumpStudio(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 400,
              child: AudioTimelineStudio(
                audioState: audioState,
                currentFrameIndex: 0,
                totalFrames: 24,
                fps: 12,
                frameThumbnails: const [],
                onToggleAudioMode: () {},
                onFrameSelected: (frameIdx) {
                  lastUpdatedFrame = frameIdx;
                },
                onAddFrame: () {},
                onAudioStateChanged: (updated) {
                  lastUpdatedState = updated;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Renders tracks and clips accurately', (tester) async {
      await pumpStudio(tester);

      expect(find.text('Voiceover 1'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('T2'), findsOneWidget);
    });

    testWidgets('Dragging audio clip horizontally (left/right) moves startOffsetMs', (tester) async {
      await pumpStudio(tester);

      final clipFinder = find.byKey(const ValueKey('clip_pos_clip_t1'));
      expect(clipFinder, findsOneWidget);

      final initialCenter = tester.getCenter(clipFinder);
      expect(clip1.startOffsetMs, 1000);

      // Drag right by 60 pixels (at 120 px/sec, 60px = 500ms shift)
      final gesture = await tester.startGesture(initialCenter);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(clip1.startOffsetMs, closeTo(1500, 50));
      expect(lastUpdatedState, isNotNull);

      // Now drag left by 120 pixels (at 120 px/sec, 120px = 1000ms shift left)
      final newCenter = tester.getCenter(clipFinder);
      final gesture2 = await tester.startGesture(newCenter);
      await gesture2.moveBy(const Offset(-120, 0));
      await tester.pump();
      await gesture2.up();
      await tester.pumpAndSettle();

      expect(clip1.startOffsetMs, closeTo(500, 50));
    });

    testWidgets('Dragging audio clip vertically moves it down to Track 2 and up to Track 1', (tester) async {
      await pumpStudio(tester);

      final clipFinder = find.byKey(const ValueKey('clip_pos_clip_t1'));
      expect(clipFinder, findsOneWidget);
      expect(clip1.trackIndex, 0);

      final initialCenter = tester.getCenter(clipFinder);

      // Drag down by 52px (height of 1 track) to shift to Track 2 (index 1)
      // Use offset on Track 3 / 4 space to avoid overlap with clip2
      final gesture = await tester.startGesture(initialCenter);
      await gesture.moveBy(const Offset(200, 104)); // Move right by 200px and down 2 tracks (to Track 3, index 2)
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(clip1.trackIndex, 2);
      expect(audioState.tracks[2].clips.any((c) => c.id == 'clip_t1'), isTrue);
      expect(audioState.tracks[0].clips.any((c) => c.id == 'clip_t1'), isFalse);
    });

    testWidgets('Left and Right trim handles resize trimmed duration', (tester) async {
      await pumpStudio(tester);

      // Tap on clip1 to select it and reveal orange trim handles
      final clipFinder = find.byKey(const ValueKey('clip_pos_clip_t1'));
      await tester.tap(clipFinder);
      await tester.pump();

      final leftHandle = find.byKey(const ValueKey('clip_trim_left_clip_t1'));
      expect(leftHandle, findsOneWidget);

      // 1. Drag Left Trim Handle to the right by 24px (200ms)
      final leftCenter = tester.getCenter(leftHandle);
      final leftGesture = await tester.startGesture(leftCenter);
      await leftGesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await leftGesture.up();
      await tester.pumpAndSettle();

      expect(clip1.trimStartMs, closeTo(200, 50));

      // 2. Drag Right Trim Handle to the left by 60px (500ms)
      final rightHandleUpdated = find.byKey(const ValueKey('clip_trim_right_clip_t1'));
      expect(rightHandleUpdated, findsOneWidget);
      final rightCenter = tester.getCenter(rightHandleUpdated);
      final rightGesture = await tester.startGesture(rightCenter);
      await rightGesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await rightGesture.up();
      await tester.pumpAndSettle();

      expect(clip1.trimEndMs, closeTo(3500, 50));
    });

    testWidgets('Horizontal finger scrubbing smoothly advances timeline and active frame', (tester) async {
      await pumpStudio(tester);

      // Verify initial frame is frame 0
      expect(lastUpdatedFrame, 0);

      // Target the horizontal timeline SingleChildScrollView
      final horizontalScrollFinder = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScrollFinder, findsOneWidget);

      // Drag horizontally along the timeline to scrub forward by 240px (2.0 seconds at 120px/s)
      await tester.drag(horizontalScrollFinder, const Offset(-240, 0));
      await tester.pumpAndSettle();

      // At 240px scroll offset, time is 2000ms. At 12 fps, frame is 24 (or clamped to 23).
      expect(lastUpdatedFrame, greaterThan(10));
    });

    testWidgets('Dragging audio clip near viewport edge automatically auto-scrolls the timeline horizontally', (tester) async {
      await pumpStudio(tester);

      final clipFinder = find.byKey(const ValueKey('clip_pos_clip_t2'));
      expect(clipFinder, findsOneWidget);

      final initialStartOffsetMs = clip2.startOffsetMs;
      final initialCenter = tester.getCenter(clipFinder);

      // Start drag gesture on clip2
      final gesture = await tester.startGesture(initialCenter);
      // Move gesture towards right edge of viewport (e.g. x = 1380px on 1400px width window)
      await gesture.moveTo(Offset(1380, initialCenter.dy));
      await tester.pump();

      // Pump several frames to let the 16ms periodic auto-scroll timer run
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }

      await gesture.up();
      await tester.pumpAndSettle();

      // Clip2 startOffsetMs should have significantly increased due to auto-scrolling
      expect(clip2.startOffsetMs, greaterThan(initialStartOffsetMs + 1000));
      expect(lastUpdatedState, isNotNull);
    });
  });
}
