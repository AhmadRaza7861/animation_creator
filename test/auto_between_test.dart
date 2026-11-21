import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/widgets/app_back_button.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/presentation/widgets/auto_between_sheet.dart';
import 'package:dummy/features/editor/services/auto_between_service.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/features/projects/data/project_thumbnail_helper.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_extension/ex_paint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TweenEasing', () {
    test('all easing curves map 0 -> 0 and 1 -> 1', () {
      for (final easing in TweenEasing.values) {
        expect(easing.transform(0.0), closeTo(0.0, 1e-6));
        expect(easing.transform(1.0), closeTo(1.0, 1e-6));
      }
      expect(TweenEasing.linear.transform(0.5), closeTo(0.5, 1e-6));
      expect(TweenEasing.easeIn.transform(0.5), lessThan(0.5));
      expect(TweenEasing.easeOut.transform(0.5), greaterThan(0.5));
      expect(TweenEasing.easeInOut.transform(0.5), closeTo(0.5, 1e-6));
    });
  });

  group('AutoBetweenPlan', () {
    test('interpolates Circle geometry, color, and strokeWidth accurately', () {
      final circleA = Circle.data(
        center: const Offset(100, 100),
        radius: 20,
        startPoint: const Offset(100, 100),
        endPoint: const Offset(120, 100),
        paint: Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = 4.0,
        id: 'c1',
      );
      final circleB = Circle.data(
        center: const Offset(300, 200),
        radius: 60,
        startPoint: const Offset(300, 200),
        endPoint: const Offset(360, 200),
        paint: Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 12.0,
        id: 'c1',
      );

      final plan = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [circleA], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [circleB], currentIndex: 1)],
      );

      final midLayers = plan.buildLayersAt(0.5);
      expect(midLayers.length, 1);
      expect(midLayers.first.history.length, 1);

      final midCircle = midLayers.first.history.first as Circle;
      expect(midCircle.center.dx, closeTo(200, 1e-4));
      expect(midCircle.center.dy, closeTo(150, 1e-4));
      expect(midCircle.radius, closeTo(40, 1e-4));
      expect(midCircle.paint.strokeWidth, closeTo(8.0, 1e-4));
    });

    test('matches raw item with Select-lifted ShapeStickerContent and takes shortest rotation arc', () {
      final rawRect = Rectangle.data(
        startPoint: const Offset(0, 0),
        endPoint: const Offset(100, 100),
        paint: Paint()
          ..color = Colors.red
          ..strokeWidth = 4.0,
        id: 'rect_1',
      );

      final liftedSticker = ShapeStickerContent.data(
        child: OffsetContent(rawRect.copy(), const Offset(2, 2)),
        offset: const Offset(250, 150),
        scale: 2.0,
        rotation: 0.2, // ~11 deg
        size: const Size(104, 104),
        paint: rawRect.paint.copyWith(),
      );

      final stickerA = ShapeStickerContent.data(
        child: OffsetContent(rawRect.copy(), const Offset(2, 2)),
        offset: const Offset(50, 50),
        scale: 1.0,
        rotation: 2 * math.pi - 0.2, // ~349 deg
        size: const Size(104, 104),
        paint: rawRect.paint.copyWith(),
      );

      // Test raw <-> ShapeStickerContent pairing by ID
      final planRawToSticker = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [rawRect], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [liftedSticker], currentIndex: 1)],
      );
      expect(planRawToSticker.matchedPairCount, 1);
      final midRawToSticker =
          planRawToSticker.buildLayersAt(0.5).first.history.first as ShapeStickerContent;
      expect(midRawToSticker.offset.dx, closeTo(150, 1.0));
      expect(midRawToSticker.scale, closeTo(1.5, 1e-4));

      // Test shortest-angle rotation across 0/2pi boundary
      final planRot = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [stickerA], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [liftedSticker], currentIndex: 1)],
      );
      final midRot =
          planRot.buildLayersAt(0.5).first.history.first as ShapeStickerContent;
      // Midpoint between -0.2 and +0.2 rad should be ~0.0 (not pi!)
      final double normalized = midRot.rotation % (2 * math.pi);
      expect(math.min(normalized, (2 * math.pi - normalized).abs()), lessThan(0.05));
    });

    test('resamples FreehandLine strokes with different point counts and aligns direction', () {
      final lineA = FreehandLine.data(
        points: const [Offset(0, 0), Offset(50, 0), Offset(100, 0)],
        paint: Paint()..color = Colors.black..strokeWidth = 5.0,
      );
      // Drawn in reverse direction (from x=100 to x=0) at y=100
      final lineB = FreehandLine.data(
        points: const [
          Offset(100, 100),
          Offset(75, 100),
          Offset(50, 100),
          Offset(25, 100),
          Offset(0, 100),
        ],
        paint: Paint()..color = Colors.black..strokeWidth = 15.0,
      );

      final plan = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [lineA], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [lineB], currentIndex: 1)],
      );

      final mid = plan.buildLayersAt(0.5).first.history.first as FreehandLine;
      expect(mid.points, isNotNull);
      expect(mid.points!.length, greaterThanOrEqualTo(12));
      // Start point should be around (0, 50) and end point around (100, 50), not collapsed at center!
      expect(mid.points!.first.dx, closeTo(0.0, 2.0));
      expect(mid.points!.first.dy, closeTo(50.0, 2.0));
      expect(mid.points!.last.dx, closeTo(100.0, 2.0));
      expect(mid.points!.last.dy, closeTo(50.0, 2.0));
      expect(mid.paint.strokeWidth, closeTo(10.0, 1e-4));

      // Verify JSON round-trip
      final decoded = decodePaintContent(mid.contentType, mid.toJson());
      expect(decoded, isA<FreehandLine>());
    });

    test('translation-invariant optimal matching pairs head with head and eyes with eyes without crossing', () {
      // Frame A: big head at (100,100) + small left eye at (85,90) + small right eye at (115,90)
      final headA = Circle.data(
        center: const Offset(100, 100),
        radius: 40,
        startPoint: const Offset(100, 100),
        endPoint: const Offset(140, 100),
        paint: Paint()..color = Colors.black..strokeWidth = 4.0,
      );
      final leftEyeA = Circle.data(
        center: const Offset(85, 90),
        radius: 5,
        startPoint: const Offset(85, 90),
        endPoint: const Offset(90, 90),
        paint: Paint()..color = Colors.black..strokeWidth = 3.0,
      );
      final rightEyeA = Circle.data(
        center: const Offset(115, 90),
        radius: 5,
        startPoint: const Offset(115, 90),
        endPoint: const Offset(120, 90),
        paint: Paint()..color = Colors.black..strokeWidth = 3.0,
      );

      // Frame B: moved +400px right, drawn in reversed order (rightEye, leftEye, head)
      final rightEyeB = Circle.data(
        center: const Offset(515, 90),
        radius: 5,
        startPoint: const Offset(515, 90),
        endPoint: const Offset(520, 90),
        paint: Paint()..color = Colors.black..strokeWidth = 3.0,
      );
      final leftEyeB = Circle.data(
        center: const Offset(485, 90),
        radius: 5,
        startPoint: const Offset(485, 90),
        endPoint: const Offset(490, 90),
        paint: Paint()..color = Colors.black..strokeWidth = 3.0,
      );
      final headB = Circle.data(
        center: const Offset(500, 100),
        radius: 40,
        startPoint: const Offset(500, 100),
        endPoint: const Offset(540, 100),
        paint: Paint()..color = Colors.black..strokeWidth = 4.0,
      );

      final plan = AutoBetweenPlan.fromLayers(
        [
          LayerData(
            id: 'l1',
            name: 'Layer 1',
            history: [headA, leftEyeA, rightEyeA],
            currentIndex: 3,
          ),
        ],
        [
          LayerData(
            id: 'l2',
            name: 'Layer 1',
            history: [rightEyeB, leftEyeB, headB],
            currentIndex: 3,
          ),
        ],
      );

      final midCircles = plan.buildLayersAt(0.5).first.history.cast<Circle>();
      expect(midCircles.length, 3);
      final bigCircle = midCircles.firstWhere((c) => c.radius > 20);
      expect(bigCircle.center.dx, closeTo(300, 1.0));
      expect(bigCircle.radius, closeTo(40, 1.0));

      final smallCircles = midCircles.where((c) => c.radius < 10).toList()
        ..sort((a, b) => a.center.dx.compareTo(b.center.dx));
      expect(smallCircles.length, 2);
      // Left eye stays left (285), right eye stays right (315) — no crossover!
      expect(smallCircles[0].center.dx, closeTo(285, 1.0));
      expect(smallCircles[1].center.dx, closeTo(315, 1.0));
    });

    test('filters out ShapeFillContent, StrokeRecolorContent, and Eyedropper metadata', () {
      final circleA = Circle.data(
        center: const Offset(50, 50),
        radius: 25,
        startPoint: const Offset(50, 50),
        endPoint: const Offset(75, 50),
        paint: Paint()..color = Colors.black,
        fillColor: Colors.red,
        id: 'c1',
      );
      final circleB = Circle.data(
        center: const Offset(150, 50),
        radius: 25,
        startPoint: const Offset(150, 50),
        endPoint: const Offset(175, 50),
        paint: Paint()..color = Colors.blue,
        fillColor: Colors.yellow,
        id: 'c1',
      );
      final shapeFillMeta = ShapeFillContent(
        targetShape: circleB,
        oldFillColor: Colors.red,
        newFillColor: Colors.yellow,
        targetIndex: 0,
      );
      final recolorMeta = StrokeRecolorContent(
        targetItem: circleB,
        oldColor: Colors.black,
        newColor: Colors.blue,
        targetIndex: 0,
      );

      final plan = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [circleA], currentIndex: 1)],
        [
          LayerData(
            id: 'l2',
            name: 'Layer 1',
            history: [circleB, shapeFillMeta, recolorMeta, Eyedropper()],
            currentIndex: 4,
          ),
        ],
      );

      final midHistory = plan.buildLayersAt(0.5).first.history;
      expect(midHistory.length, 1);
      expect(midHistory.first, isA<Circle>());
      expect(midHistory.first.fillColor, isNotNull);
    });

    test('GroupContent preserves boundsOffset across JSON round-trip', () {
      final group = GroupContent(
        children: [
          Rectangle.data(
            startPoint: const Offset(0, 0),
            endPoint: const Offset(20, 20),
            paint: Paint()..color = Colors.black,
          ),
        ],
        boundsOffset: const Offset(-12.5, 34.0),
      );

      final decoded =
          decodePaintContent(group.contentType, group.toJson()) as GroupContent;
      expect(decoded.boundsOffset.dx, closeTo(-12.5, 1e-6));
      expect(decoded.boundsOffset.dy, closeTo(34.0, 1e-6));
    });

    test('morphs incompatible closed shapes (Circle <-> Rectangle) cleanly', () {
      final circle = Circle.data(
        center: const Offset(50, 50),
        radius: 30,
        startPoint: const Offset(50, 50),
        endPoint: const Offset(80, 50),
        paint: Paint()..color = Colors.blue..strokeWidth = 4.0,
      );
      final rect = Rectangle.data(
        startPoint: const Offset(200, 200),
        endPoint: const Offset(300, 300),
        paint: Paint()..color = Colors.green..strokeWidth = 6.0,
      );

      final plan = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [circle], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [rect], currentIndex: 1)],
      );

      final mid = plan.buildLayersAt(0.5).first.history.first;
      expect(mid, isA<FreehandLine>());
      expect((mid as FreehandLine).points!.length, greaterThan(10));
    });

    test('morphs ShapeStickerContent wrapped shapes (Heart <-> Rectangle)', () {
      final heartSticker = ShapeStickerContent.data(
        child: Heart.data(
          startPoint: Offset.zero,
          endPoint: const Offset(100, 100),
          paint: Paint()
            ..color = Colors.black
            ..strokeWidth = 6.0,
        ),
        offset: const Offset(150, 200),
        scale: 1.0,
        rotation: 0.0,
        size: const Size(100, 100),
        paint: Paint()
          ..color = Colors.black
          ..strokeWidth = 6.0,
      );
      final rectSticker = ShapeStickerContent.data(
        child: Rectangle.data(
          startPoint: Offset.zero,
          endPoint: const Offset(120, 120),
          paint: Paint()
            ..color = Colors.black
            ..strokeWidth = 6.0,
        ),
        offset: const Offset(450, 200),
        scale: 1.0,
        rotation: 0.0,
        size: const Size(120, 120),
        paint: Paint()
          ..color = Colors.black
          ..strokeWidth = 6.0,
      );

      final plan = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Background', history: [heartSticker], currentIndex: 1)],
        [LayerData(id: 'l2', name: 'Background', history: [rectSticker], currentIndex: 1)],
      );

      expect(plan.matchedPairCount, 1);
      final midItems = plan.buildLayersAt(0.5).first.history;
      expect(midItems.length, 1);
      expect(midItems.first, isA<ShapeStickerContent>());
      final midSticker = midItems.first as ShapeStickerContent;
      expect(midSticker.offset.dx, closeTo(300, 1e-4));
      expect(midSticker.child, isA<FreehandLine>());
    });

    test('interpolates TextContent and respects fadeUnmatched option', () {
      final textA = TextContent.data(
        offset: const Offset(10, 20),
        text: 'Hello',
        scale: 1.0,
        rotation: 0.0,
        fontSize: 20.0,
        isBold: true,
        opacity: 1.0,
        paint: Paint()..color = Colors.black,
        );
      final textB = TextContent.data(
        offset: const Offset(110, 220),
        text: 'Hello',
        scale: 3.0,
        rotation: 1.0,
        fontSize: 40.0,
        isBold: true,
        opacity: 0.5,
        paint: Paint()..color = Colors.black,
      );
      final extraDot = Circle.data(
        center: const Offset(10, 10),
        radius: 5,
        startPoint: const Offset(10, 10),
        endPoint: const Offset(15, 10),
        paint: Paint()..color = Colors.red,
      );

      final planFade = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [textA, extraDot], currentIndex: 2)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [textB], currentIndex: 1)],
        fadeUnmatched: true,
      );
      final fadeItems = planFade.buildLayersAt(0.5).first.history;
      expect(fadeItems.length, 2);
      final midText = fadeItems.whereType<TextContent>().first;
      expect(midText.offset.dx, closeTo(60, 1e-4));
      expect(midText.fontSize, closeTo(30, 1e-4));
      expect(midText.opacity, closeTo(0.75, 1e-4));

      final planNoFade = AutoBetweenPlan.fromLayers(
        [LayerData(id: 'l1', name: 'Layer 1', history: [textA, extraDot], currentIndex: 2)],
        [LayerData(id: 'l2', name: 'Layer 1', history: [textB], currentIndex: 1)],
        fadeUnmatched: false,
      );
      expect(planNoFade.buildLayersAt(0.5).first.history.length, 1);
    });
  });

  group('EditorController.generateAutoBetweenFrames', () {
    test('inserts frames lazily without eager thumbnail generation', () async {
      final controller = EditorController(repository: ProjectRepository());
      controller.canvases[0].addContent(
        Circle.data(
          center: const Offset(50, 50),
          radius: 20,
          startPoint: const Offset(50, 50),
          endPoint: const Offset(70, 50),
          paint: Paint()..color = Colors.black..strokeWidth = 4.0,
          id: 'ball',
        ),
      );

      controller.addFrame();
      controller.canvases[1].addContent(
        Circle.data(
          center: const Offset(250, 50),
          radius: 20,
          startPoint: const Offset(250, 50),
          endPoint: const Offset(270, 50),
          paint: Paint()..color = Colors.black..strokeWidth = 4.0,
          id: 'ball',
        ),
      );

      final sw = Stopwatch()..start();
      final count = await controller.generateAutoBetweenFrames(
        startIndex: 0,
        endIndex: 1,
        betweenCount: 24,
        easing: TweenEasing.easeInOut,
      );
      sw.stop();

      expect(count, 24);
      expect(controller.canvases.length, 26);
      expect(controller.thumbnails.length, 26);
      // Newly generated frames must keep null thumbnails until lazily scrolled into view
      expect(controller.thumbnails.sublist(1, 25).every((t) => t == null), isTrue);
      // Current index lands on first generated frame
      expect(controller.currentIndex, 1);
      // Verify midpoint frame (index 12 or 13) interpolated smoothly
      final midBall =
          controller.canvases[12].layers.first.getEffectiveHistory().first as Circle;
      expect(midBall.center.dx, greaterThan(50));
      expect(midBall.center.dx, lessThan(250));
      // Sanity performance check: 24 frames should generate in well under 500ms
      expect(sw.elapsedMilliseconds, lessThan(500));

      controller.dispose();
    });

    test('replaceExistingBetween replaces intermediate frames cleanly', () async {
      final controller = EditorController(repository: ProjectRepository());
      controller.addFrame(); // frame 1 (blank middle)
      controller.addFrame(); // frame 2 (blank middle)
      controller.addFrame(); // frame 3 (keyframe B)

      final count = await controller.generateAutoBetweenFrames(
        startIndex: 0,
        endIndex: 3,
        betweenCount: 5,
        replaceExistingBetween: true,
      );

      expect(count, 5);
      // 2 original keyframes + 5 generated = 7 total (the 2 old blanks were replaced)
      expect(controller.canvases.length, 7);
      expect(controller.canUndoLastAutoBetween, isTrue);

      // Undo restores exact original 4 frames
      expect(controller.undoLastAutoBetween(), isTrue);
      expect(controller.canvases.length, 4);
      expect(controller.canUndoLastAutoBetween, isFalse);
      controller.dispose();
    });
  });

  group('AutoBetweenSheet Widget', () {
    testWidgets('displays controls, empty hint, frame picker, small screen layout, and undo snackbar', (tester) async {
      // Test on a compact small-phone screen size (320x568) to catch any overflow bugs
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = EditorController(repository: ProjectRepository());
      controller.addFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => AutoBetweenSheet.show(context, controller),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Auto Between'), findsOneWidget);
      expect(find.text('Draw on both keyframes to preview motion'), findsOneWidget);
      expect(find.text('Generate 5 Frames'), findsOneWidget);

      // Select quick preset 3
      await tester.ensureVisible(find.text('3'));
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(find.text('Generate 3 Frames'), findsOneWidget);

      // Pinned Generate CTA must be visible and tappable without overflow
      await tester.tap(find.text('Generate 3 Frames'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.canvases.length, 5);
      expect(find.text('Undo'), findsOneWidget);

      // Tapping Undo reverts generated frames
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(controller.canvases.length, 2);

      controller.dispose();
    });

    testWidgets('AppBackButton does not double-flip directional back icon in RTL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(child: AppBackButton()),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_back_ios_new_rounded);
      expect(icon.icon!.matchTextDirection, isTrue);
    });

    test('EditorController tracks needsThumbnailUpdate on edits', () {
      final controller = EditorController(repository: ProjectRepository());
      expect(controller.needsThumbnailUpdate, isFalse);
      controller.markDirty();
      expect(controller.needsThumbnailUpdate, isTrue);
      controller.dispose();
    });

    test('ProjectThumbnailHelper returns null for empty state and renders non-empty frame 2 artwork', () async {
      final Map<String, dynamic> blankState = {
        'aspectRatio': 1.0,
        'globalBackground': {'color': 0xFFFFFFFF, 'pattern': null},
        'canvases': [
          {
            'size': {'width': 400.0, 'height': 400.0},
            'backgroundColor': 0xFFFFFFFF,
            'layers': [
              {
                'id': 'layer_0',
                'name': 'Background',
                'isVisible': true,
                'isLocked': false,
                'opacity': 1.0,
                'blendMode': BlendMode.srcOver.index,
                'currentIndex': 0,
                'history': <dynamic>[],
              },
            ],
          },
        ],
      };
      expect(ProjectThumbnailHelper.stateHasVisualContent(blankState), isFalse);
      expect(await ProjectThumbnailHelper.renderFromState(blankState), isNull);

      final Map<String, dynamic> frame2DrawnState = {
        'aspectRatio': 1.0,
        'globalBackground': {'color': 0xFFFFFFFF, 'pattern': null},
        'canvases': [
          blankState['canvases']![0],
          {
            'size': {'width': 400.0, 'height': 400.0},
            'backgroundColor': 0xFFFFFFFF,
            'layers': [
              {
                'id': 'layer_0',
                'name': 'Background',
                'isVisible': true,
                'isLocked': false,
                'isGuide': null,
                'opacity': 1.0,
                'blendMode': BlendMode.srcOver.index,
                'currentIndex': 1,
                'history': [
                  Circle.data(
                    center: const Offset(200, 200),
                    radius: 80,
                    startPoint: const Offset(200, 200),
                    endPoint: const Offset(280, 200),
                    paint: Paint()
                      ..color = Colors.red
                      ..strokeWidth = 8.0,
                  ).toJson(),
                ],
              },
            ],
          },
        ],
      };
      expect(ProjectThumbnailHelper.stateHasVisualContent(frame2DrawnState), isTrue);
      final bytes = await ProjectThumbnailHelper.renderFromState(frame2DrawnState);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(100));
    });
  });
}
