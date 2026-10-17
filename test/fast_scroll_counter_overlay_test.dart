import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/widgets/fast_scroll_counter_overlay.dart';
import 'package:dummy/features/editor/presentation/widgets/canvas_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FastScrollCounterOverlay tests', () {
    testWidgets('Renders nothing when notifier is null or isVisible is false', (tester) async {
      final notifier = ValueNotifier<FastScrollState>(const FastScrollState(isVisible: false));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastScrollCounterOverlay(notifier: notifier),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fast_scroll_counter_card')), findsNothing);
    });

    testWidgets('Displays current frame, total frames, and formatted seconds matching reference design', (tester) async {
      // 146 frames at 12 FPS = 12 seconds ("00:12")
      // 321 frames at 12 FPS = 26 seconds ("00:26")
      final notifier = ValueNotifier<FastScrollState>(
        const FastScrollState(
          isVisible: true,
          currentFrame: 146,
          totalFrames: 321,
          fps: 12,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FastScrollCounterOverlay(notifier: notifier),
            ),
          ),
        ),
      );

      // Advance animation
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('fast_scroll_counter_card')), findsOneWidget);
      expect(find.text('CURRENT FRAME'), findsOneWidget);
      expect(find.text('146'), findsOneWidget);
      expect(find.text('00:12'), findsOneWidget);

      expect(find.text('TOTAL FRAMES'), findsOneWidget);
      expect(find.text('321'), findsOneWidget);
      expect(find.text('00:26'), findsOneWidget);

      // Dynamically update frame
      notifier.value = notifier.value.copyWith(
        currentFrame: 147,
      );
      await tester.pump();
      expect(find.text('147'), findsOneWidget);

      // Tapping card immediately dismisses it
      await tester.tap(find.byKey(const ValueKey('fast_scroll_counter_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('fast_scroll_counter_card')), findsNothing);
      expect(notifier.value.isVisible, isFalse);
    });

    testWidgets('Calculates playback time accurately at custom FPS (24 FPS, 60 FPS)', (tester) async {
      // At 24 FPS: 48 frames = 2 seconds ("00:02")
      final notifier = ValueNotifier<FastScrollState>(
        const FastScrollState(
          isVisible: true,
          currentFrame: 48,
          totalFrames: 240,
          fps: 24,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastScrollCounterOverlay(notifier: notifier),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:02'), findsOneWidget); // 48 / 24 = 2s
      expect(find.text('00:10'), findsOneWidget); // 240 / 24 = 10s
    });
  });

  group('CanvasSelector + FastScrollState integration', () {
    testWidgets('Normal slow scrolling does NOT trigger fast scroll counter', (tester) async {
      const int frameCount = 100;
      int selectedIndex = 0;
      final fastScrollNotifier = ValueNotifier<FastScrollState>(const FastScrollState());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              width: 400,
              child: CanvasSelector(
                thumbnails: List<ui.Image?>.filled(frameCount, null),
                currentIndex: selectedIndex,
                fps: 12,
                fastScrollNotifier: fastScrollNotifier,
                onSelect: (index) {
                  selectedIndex = index;
                },
                onAdd: () {},
                onOpenGallery: () {},
                onOpenFrames: () {},
                onImportVideo: () {},
                onPlay: () {},
                onFrameAction: (action, index) {},
                canvasKeys: List.generate(frameCount, (i) => ValueKey('canvas_$i')),
                onReorder: (oldIdx, newIdx) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(fastScrollNotifier.value.isVisible, isFalse);

      // Slow scroll (drag only 30px slowly)
      final listFinder = find.byType(ReorderableListView);
      await tester.drag(listFinder, const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 100));

      // Should NOT be visible during normal/slow scrolling
      expect(fastScrollNotifier.value.isVisible, isFalse);
    });

    testWidgets('Rapid scrolling updates fastScrollNotifier with isVisible: true and lingers for increased duration', (tester) async {
      const int frameCount = 100;
      int selectedIndex = 0;
      final fastScrollNotifier = ValueNotifier<FastScrollState>(const FastScrollState());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              width: 400,
              child: CanvasSelector(
                thumbnails: List<ui.Image?>.filled(frameCount, null),
                currentIndex: selectedIndex,
                fps: 12,
                fastScrollNotifier: fastScrollNotifier,
                onSelect: (index) {
                  selectedIndex = index;
                },
                onAdd: () {},
                onOpenGallery: () {},
                onOpenFrames: () {},
                onImportVideo: () {},
                onPlay: () {},
                onFrameAction: (action, index) {},
                canvasKeys: List.generate(frameCount, (i) => ValueKey('canvas_$i')),
                onReorder: (oldIdx, newIdx) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(fastScrollNotifier.value.isVisible, isFalse);

      // Fast fling across timeline
      final listFinder = find.byType(ReorderableListView);
      await tester.fling(listFinder, const Offset(-300, 0), 1000);
      await tester.pump(const Duration(milliseconds: 100));

      // Fast scroll notifier should be active
      expect(fastScrollNotifier.value.isVisible, isTrue);
      expect(fastScrollNotifier.value.totalFrames, equals(frameCount));
      expect(fastScrollNotifier.value.fps, equals(12));

      // After 800ms, it should STILL be visible (lingers longer as requested!)
      await tester.pump(const Duration(milliseconds: 800));
      expect(fastScrollNotifier.value.isVisible, isTrue);

      // Wait for remaining hide timer + reverse animation
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(fastScrollNotifier.value.isVisible, isFalse);
    });

    testWidgets('Tapping a frame thumbnail dismisses fast scroll overlay immediately', (tester) async {
      const int frameCount = 100;
      int selectedIndex = 0;
      final fastScrollNotifier = ValueNotifier<FastScrollState>(
        const FastScrollState(isVisible: true, currentFrame: 10, totalFrames: frameCount),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              width: 400,
              child: CanvasSelector(
                thumbnails: List<ui.Image?>.filled(frameCount, null),
                currentIndex: selectedIndex,
                fps: 12,
                fastScrollNotifier: fastScrollNotifier,
                onSelect: (index) {
                  selectedIndex = index;
                },
                onAdd: () {},
                onOpenGallery: () {},
                onOpenFrames: () {},
                onImportVideo: () {},
                onPlay: () {},
                onFrameAction: (action, index) {},
                canvasKeys: List.generate(frameCount, (i) => ValueKey('canvas_$i')),
                onReorder: (oldIdx, newIdx) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(fastScrollNotifier.value.isVisible, isTrue);

      // Tap on frame 0
      final thumbFinder = find.byKey(const ValueKey('thumb_0'));
      await tester.tap(thumbFinder);
      await tester.pump();

      // Overlay must be dismissed immediately!
      expect(fastScrollNotifier.value.isVisible, isFalse);
    });
  });
}
