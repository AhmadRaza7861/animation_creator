import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/constants/app_colors.dart';
import 'package:dummy/features/editor/presentation/widgets/canvas_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fast-scrub handle appears when scrolling fastly and responds to drag', (tester) async {
    const int frameCount = 100;
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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

    // Fast scroll / drag the timeline list horizontally
    final listFinder = find.byType(ReorderableListView);
    expect(listFinder, findsOneWidget);

    // Fast fling gesture
    await tester.fling(listFinder, const Offset(-300, 0), 1000);
    await tester.pump(const Duration(milliseconds: 100));

    // The fast-scrub pill handle should now be visible
    final scrubberHandleFinder = find.byKey(const ValueKey('timeline_fast_scrub_handle'));
    expect(scrubberHandleFinder, findsOneWidget);

    // Verify it uses brand theme orange gradient and rounded corners
    final container = tester.widget<Container>(scrubberHandleFinder);
    final box = container.decoration as BoxDecoration;
    expect(box.gradient, isNotNull);
    final linearGradient = box.gradient as LinearGradient;
    expect(linearGradient.colors, [const Color(0xFFFFA940), ColorConstants.primary]);
    expect(box.borderRadius, BorderRadius.circular(11));

    // Verify it contains the 3 white vertical grip bars
    final gripBars = find.descendant(
      of: scrubberHandleFinder,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final b = widget.decoration as BoxDecoration;
          return b.color == Colors.white && b.borderRadius == BorderRadius.circular(1.5);
        }
        return false;
      }),
    );
    expect(gripBars, findsNWidgets(3));

    // Drag the scrubber handle directly to scrub the timeline view
    await tester.drag(scrubberHandleFinder, const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 50));

    // Selected frame must NOT change automatically; selection only changes when user explicitly selects a frame
    expect(selectedIndex, equals(0));

    // Wait for auto-hide duration (1200ms)
    await tester.pump(const Duration(milliseconds: 1600));
    // Complete the 250ms reverse animation
    await tester.pump(const Duration(milliseconds: 350));

    // After inactivity and reverse animation, handle is completely hidden
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);
  });

  testWidgets('Adding a frame or selecting a frame does NOT show the fast-scrub handle', (tester) async {
    int selectedIndex = 0;
    int frameCount = 10;

    Widget buildSelector() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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
      );
    }

    await tester.pumpWidget(buildSelector());
    await tester.pumpAndSettle();

    // Verify initially hidden
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);

    // Select a different frame
    selectedIndex = 5;
    await tester.pumpWidget(buildSelector());
    await tester.pumpAndSettle();

    // Scrubber must NOT appear when simply changing selected frame
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);

    // Simulate adding a frame (frameCount changes to 11, selectedIndex changes to 10)
    frameCount = 11;
    selectedIndex = 10;
    await tester.pumpWidget(buildSelector());
    await tester.pumpAndSettle();

    // Scrubber must NOT appear when adding a frame
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);
    // Selected frame must remain 10 (not overridden)
    expect(selectedIndex, equals(10));
  });

  testWidgets('Scrubber handle does NOT appear when project has 4 or fewer frames', (tester) async {
    const int frameCount = 4;
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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

    // Fling gesture when only 4 frames exist
    final listFinder = find.byType(ReorderableListView);
    await tester.fling(listFinder, const Offset(-100, 0), 1000);
    await tester.pump(const Duration(milliseconds: 100));

    // Handle should NOT appear because all 4 frames fit on screen
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);
  });

  testWidgets('Selected frame thumbnail uses ColorConstants.primary for border and badge', (tester) async {
    const int frameCount = 6;
    int selectedIndex = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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

    // Verify selected frame badge has ColorConstants.primary
    final selectedBadgeFinder = find.descendant(
      of: find.byType(CanvasSelector),
      matching: find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final b = w.decoration as BoxDecoration;
          return b.color == ColorConstants.primary;
        }
        return false;
      }),
    );
    expect(selectedBadgeFinder, findsWidgets);
  });

  testWidgets('Selecting 1 frame then scrolling does NOT automatically select different frame', (tester) async {
    const int frameCount = 30;
    int selectedIndex = 0; // Frame 1 selected

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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
    expect(selectedIndex, equals(0));

    // Scroll through the timeline across multiple frames
    final listFinder = find.byType(ReorderableListView);
    await tester.fling(listFinder, const Offset(-300, 0), 1000);
    await tester.pump(const Duration(milliseconds: 100));

    // Wait until scrolling settles and stops
    await tester.pumpAndSettle();

    // The selected frame must STILL be Frame 1 (index 0) and NOT automatically changed!
    expect(selectedIndex, equals(0));
  });

  testWidgets('Dragging the fast-scrub handle with 10,000+ frames does not crash or change frame selection', (tester) async {
    const int frameCount = 10857;
    int selectedIndex = 0; // Frame 1 selected

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: List<ui.Image?>.filled(frameCount, null),
              currentIndex: selectedIndex,
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
    expect(selectedIndex, equals(0));

    // Fast scroll to reveal scrubber handle
    final listFinder = find.byKey(const PageStorageKey('timeline_canvas_selector_scroll'));
    await tester.fling(listFinder, const Offset(-300, 0), 1000);
    await tester.pump(const Duration(milliseconds: 100));

    final scrubberHandleFinder = find.byKey(const ValueKey('timeline_fast_scrub_handle'));
    expect(scrubberHandleFinder, findsOneWidget);

    // Drag the scrubber handle across a wide distance (simulating user scrub)
    await tester.drag(scrubberHandleFinder, const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Must NOT automatically switch selected frame
    expect(selectedIndex, equals(0));

    // Wait for auto-hide
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('timeline_fast_scrub_handle')), findsNothing);
  });
}
