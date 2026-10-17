import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/widgets/canvas_selector.dart';

import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/core/widgets/app_dialogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('EditorController limits active cached thumbnails to 32 when handling 500 frames', () async {
    final controller = EditorController(repository: ProjectRepository());

    // Create a temporary 1x1 png image file
    final tempDir = await Directory.systemTemp.createTemp('frame_test_');
    final tempFile = File('${tempDir.path}/test_frame.png');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 10, 10), Paint()..color = Colors.blue);
    final pic = recorder.endRecording();
    final img = await pic.toImage(10, 10);
    pic.dispose();
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

    final framePaths = List.generate(500, (i) => tempFile.path);

    // Import 500 video frames
    await controller.importVideoFrames(framePaths);

    expect(controller.canvases.length, 500);
    expect(controller.thumbnails.length, 500);

    // Verify that at import time, only initial frames (10) are pre-decoded as ui.Image, not all 500!
    final nonNullCountAtImport = controller.thumbnails.where((t) => t != null).length;
    expect(nonNullCountAtImport, lessThanOrEqualTo(10));

    // Simulate scrolling through frames and requesting thumbnails
    for (int i = 0; i < 500; i += 5) {
      controller.requestThumbnail(i);
    }

    // Let any async thumbnail decodes process
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final nonNullCountAfterScroll = controller.thumbnails.where((t) => t != null).length;
    expect(nonNullCountAfterScroll, lessThanOrEqualTo(32));

    controller.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('CanvasSelector renders and flings through 500 frames without crashing', (tester) async {
    const int count = 500;
    final List<ui.Image?> thumbnails = List<ui.Image?>.filled(count, null);
    final List<String?> framePaths = List<String?>.filled(count, null);
    final List<Key> keys = List.generate(count, (i) => ValueKey('key_$i'));

    int requestedThumbnails = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CanvasSelector(
            thumbnails: thumbnails,
            frameImagePaths: framePaths,
            currentIndex: 0,
            onSelect: (_) {},
            onAdd: () {},
            onOpenGallery: () {},
            onOpenFrames: () {},
            onImportVideo: () {},
            onPlay: () {},
            onFrameAction: (action, index) {},
            canvasKeys: keys,
            onReorder: (oldIdx, newIdx) {},
            onRequestThumbnail: (index) {
              requestedThumbnails++;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollFinder = find.byKey(const PageStorageKey('timeline_canvas_selector_scroll'));
    expect(scrollFinder, findsOneWidget);

    // Rapid continuous fling scroll across all 500 items
    for (int i = 0; i < 35; i++) {
      await tester.fling(scrollFinder, const Offset(-1500, 0), 1500);
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(requestedThumbnails, greaterThan(0));
  });

  testWidgets('CanvasSelector renders and flings through 10,857 frames instantly without ANR', (tester) async {
    const int count = 10857;
    final List<ui.Image?> thumbnails = List<ui.Image?>.filled(count, null);
    final List<String?> framePaths = List<String?>.filled(count, null);
    final List<Key> keys = List.generate(count, (i) => ValueKey('key_$i'));
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            width: 400,
            child: CanvasSelector(
              thumbnails: thumbnails,
              frameImagePaths: framePaths,
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
              canvasKeys: keys,
              onReorder: (oldIdx, newIdx) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollFinder = find.byKey(const PageStorageKey('timeline_canvas_selector_scroll'));
    expect(scrollFinder, findsOneWidget);

    // Verify it uses ListView for large lists (>100 frames)
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);

    // Rapid continuous flings across thousands of frames
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 6; i++) {
      await tester.fling(scrollFinder, const Offset(-2000, 0), 2000);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    stopwatch.stop();

    // Must be blazing fast (< 3.5 seconds in VM test runner)
    expect(stopwatch.elapsedMilliseconds, lessThan(3500));
    // Must NOT automatically switch selected frame
    expect(selectedIndex, equals(0));
  });

  testWidgets('CanvasSelector maintains identical AspectRatio framing before and after selection', (tester) async {
    const double projectRatio = 9.0 / 16.0;
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CanvasSelector(
                aspectRatio: projectRatio,
                thumbnails: const [null, null, null],
                frameImagePaths: const ['/fake/path/1.png', '/fake/path/2.png', '/fake/path/3.png'],
                currentIndex: selectedIndex,
                onSelect: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                onAdd: () {},
                onOpenGallery: () {},
                onOpenFrames: () {},
                onImportVideo: () {},
                onPlay: () {},
                onFrameAction: (action, index) {},
                canvasKeys: const [ValueKey(1), ValueKey(2), ValueKey(3)],
                onReorder: (oldIdx, newIdx) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all AspectRatio widgets for the frames have the project aspect ratio (9/16)
    final aspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    expect(aspectRatios.isNotEmpty, isTrue);
    for (final ar in aspectRatios) {
      expect(ar.aspectRatio, closeTo(projectRatio, 0.001));
    }

    // Tap on frame 2 (index 1) to select it
    final secondFrameFinder = find.byKey(const ValueKey(2));
    expect(secondFrameFinder, findsOneWidget);
    await tester.tap(secondFrameFinder);
    await tester.pumpAndSettle();

    // Verify aspect ratios remain identical after selection
    final aspectRatiosAfter = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    for (final ar in aspectRatiosAfter) {
      expect(ar.aspectRatio, closeTo(projectRatio, 0.001));
    }
  });

  testWidgets('AppDialogs.showProcessingDialog displays animated indicator and dismisses safely', (tester) async {
    late VoidCallback dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  dismiss = AppDialogs.showProcessingDialog(
                    context,
                    title: 'Saving Project',
                    message: 'Saving your animation frames...',
                    icon: Icons.save_rounded,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Saving Project'), findsOneWidget);
    expect(find.text('Saving your animation frames...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Dismiss dialog
    dismiss();
    await tester.pumpAndSettle();

    expect(find.text('Saving Project'), findsNothing);
  });

  test('EditorController saveProject skips redundant write when not dirty', () async {
    final controller = EditorController(repository: ProjectRepository());
    // Initially not dirty and has no project id or changes
    expect(controller.isDirty, isFalse);

    // Calling saveProject when clean should not crash or hang
    await controller.saveProject();
    expect(controller.isSaving, isFalse);
    controller.dispose();
  });
}
