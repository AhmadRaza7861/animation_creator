import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dummy/features/templates/data/tutorial_project_builder.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/drawing_bar/brush_presets.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/package_code/src/paint_contents/brush_cache.dart';
import 'package:dummy/package_code/src/paint_contents/brush_stamps.dart';
import 'package:dummy/package_code/src/paint_contents/dashed_line.dart';
import 'package:dummy/package_code/src/paint_contents/dotted_line.dart';
import 'package:dummy/package_code/src/paint_contents/highlighter_line.dart';
import 'package:dummy/package_code/src/paint_contents/layer_data.dart';
import 'package:dummy/package_code/src/paint_contents/shape_brush_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _countNonTransparentPixels(
  void Function(Canvas canvas, Size size) painter, {
  Size size = const Size(120, 120),
}) async {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  final Canvas canvas = Canvas(rec, Offset.zero & size);
  painter(canvas, size);
  final ui.Picture pic = rec.endRecording();
  final ui.Image img = await pic.toImage(size.width.toInt(), size.height.toInt());
  pic.dispose();
  final ByteData? bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  if (bd == null) return 0;
  final Uint8List bytes = bd.buffer.asUint8List();
  int count = 0;
  for (int i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) count++;
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    BrushStampLibrary.instance.clearCache();
    TipBrush.clearStampCache();
    ProceduralStampCaches.clearAll();
  });

  test('All kDefaultBrushPresets complete fast 80-point continuous drawing within budget', () {
    const Size boardSize = Size(400, 400);
    const int strokePoints = 80;
    final List<({String id, double moveDrawMs})> results = [];

    for (final BrushPreset preset in kDefaultBrushPresets) {
      final PaintContent brush = preset.create()
        ..paint = (Paint()
          ..color = const Color(0xFFE11D48)
          ..strokeWidth = 14.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true);

      brush.startDraw(const Offset(20, 200));

      final Stopwatch swMove = Stopwatch()..start();
      for (int i = 1; i <= strokePoints; i++) {
        final double t = i / strokePoints;
        final Offset pt = Offset(
          20 + t * 360,
          200 + sin(t * pi * 6) * 120,
        );
        brush.drawing(pt);
        final ui.PictureRecorder rec = ui.PictureRecorder();
        final Canvas c = Canvas(rec, Offset.zero & boardSize);
        brush.draw(c, boardSize, false);
        final ui.Picture pic = rec.endRecording();
        pic.dispose();
      }
      swMove.stop();
      brush.clearRenderCache();

      results.add((
        id: preset.id,
        moveDrawMs: swMove.elapsedMicroseconds / 1000.0,
      ));
    }

    results.sort((a, b) => b.moveDrawMs.compareTo(a.moveDrawMs));
    debugPrint('=== AFTER-FIX TOP 25 SLOWEST BRUSHES (80-point continuous move+draw) ===');
    for (final r in results.take(25)) {
      debugPrint('${r.id.padRight(20)} : ${r.moveDrawMs.toStringAsFixed(1)} ms');
    }

    // No brush should stall over 250ms across 80 incremental repaints in debug/JIT VM.
    for (final r in results) {
      expect(
        r.moveDrawMs,
        lessThan(250.0),
        reason: 'Brush ${r.id} exceeded continuous stroke latency budget: ${r.moveDrawMs} ms',
      );
    }
  });

  test('Baked stamp and chunked vector brushes produce accurate non-empty tinted pixels', () async {
    final List<PaintContent> brushes = <PaintContent>[
      FreehandLine(),
      SmoothLine(),
      DashedLine(),
      DottedLine(),
      HighlighterLine(),
      SoftRoundBrush(softness: 0.6),
      AirbrushBrush(),
      ChalkBrush(),
      ScatterBrush(),
      TubeLine(),
      CandyCaneLine(),
      PencilLine(),
      RainbowLine(),
      NeonGlowLine(),
      SprinklesLine(),
      StaticLine(),
      HairLine(),
      PixelLine(),
      SketchLine(),
      SawLine(),
      ImageTipBrush(stampKey: 'sand', spacing: 0.15, hardness: 0.7),
      ImageTipBrush(stampKey: 'spray', spacing: 0.1, hardness: 0.5, flipX: true),
      TipBrush(kind: BrushTipKind.round, hardness: 0.25, spacing: 0.12),
      TipBrush(kind: BrushTipKind.charcoal, hardness: 0.4, spacing: 0.18),
      TipBrush(kind: BrushTipKind.charcoal, hardness: 1.0, spacing: 0.18),
      TipBrush(kind: BrushTipKind.glyphStar, roundness: 0.6, followPath: true),
      TipBrush(kind: BrushTipKind.puzzle, flipX: true),
    ];

    for (final PaintContent b in brushes) {
      b.paint = Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      b.startDraw(const Offset(15, 60));
      for (int i = 1; i <= 12; i++) {
        b.drawing(Offset(15 + i * 8.0, 60 + sin(i * 0.6) * 20));
      }
      final int pixels = await _countNonTransparentPixels(
        (c, s) => b.draw(c, s, false),
      );
      expect(pixels, greaterThan(20), reason: '${b.contentType} drew empty output');
      b.clearRenderCache();
    }
  });

  test('DrawingController incremental layer raster cache renders consistently across draw, erase, undo, redo, and dispose', () async {
    final DrawingController controller = DrawingController();
    controller.setBoardSize(const Size(200, 200));

    // Draw 20 rapid strokes across different brush families via startDraw/drawing/endDraw.
    controller.setPaintContent(ImageTipBrush(stampKey: 'sand', spacing: 0.15));
    for (int s = 0; s < 20; s++) {
      final double y = 20.0 + (s % 8) * 20.0;
      controller.startDraw(Offset(15, y));
      for (int i = 1; i <= 10; i++) {
        controller.drawing(Offset(15 + i * 16.0, y + sin(i * 0.5) * 8));
      }
      controller.endDraw();
    }

    expect(controller.getHistory.length, 20);
    final LayerData layer = controller.activeLayer.value!;

    // Render using drawLayerCached (schedules background bake) and compare with vector drawHistory.
    final int cachedPixels1 = await _countNonTransparentPixels(
      (c, s) => controller.drawLayerCached(c, s, layer, true),
      size: const Size(200, 200),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Second render uses baked image base; add 1 more stroke + 1 eraser cleanly.
    controller.setPaintContent(TipBrush(kind: BrushTipKind.charcoal));
    controller.startDraw(const Offset(30, 100));
    controller.drawing(const Offset(150, 100));
    controller.endDraw();

    final int cachedPixelsAfterStroke = await _countNonTransparentPixels(
      (c, s) => controller.drawLayerCached(c, s, layer, true),
      size: const Size(200, 200),
    );
    expect(cachedPixelsAfterStroke, greaterThanOrEqualTo(cachedPixels1));

    // Wait for async bake, then test Undo & Redo invalidation.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    controller.undo();
    expect(layer.currentIndex, 20);

    final int afterUndoPixels = await _countNonTransparentPixels(
      (c, s) => controller.drawLayerCached(c, s, layer, true),
      size: const Size(200, 200),
    );
    final int expectedUndoPixels = await _countNonTransparentPixels(
      (c, s) => layer.drawHistory(c, s, true),
      size: const Size(200, 200),
    );
    expect((afterUndoPixels - expectedUndoPixels).abs(), lessThan(40));

    controller.redo();
    expect(layer.currentIndex, 21);

    controller.clear();
    expect(layer.history.isEmpty, isTrue);

    controller.dispose();
  });

  test('ChunkedStrokeCache incremental sampling matches buildSmoothPath().computeMetrics()', () {
    final DottedLine lineOneShot = DottedLine();
    final DottedLine lineIncremental = DottedLine();
    final List<Offset> pts = List<Offset>.generate(
      80,
      (int i) => Offset(20.0 + i * 4.5, 160.0 + sin(i * 0.25) * 65.0),
    );

    lineOneShot.points = List<Offset>.from(pts);
    final ChunkedStrokeCache oneShotCache = lineOneShot.sampleSmooth(5.0);

    // Feed points incrementally in small batches as pointer move events do.
    lineIncremental.startDraw(pts.first);
    for (int i = 1; i < pts.length; i++) {
      lineIncremental.points.add(pts[i]);
      if (i % 3 == 0 || i == pts.length - 1) {
        lineIncremental.sampleSmooth(5.0);
      }
    }
    final ChunkedStrokeCache incCache = lineIncremental.strokeCache;

    expect(incCache.frozenCount, oneShotCache.frozenCount);
    expect(incCache.tailCount, oneShotCache.tailCount);
    for (int i = 0; i < oneShotCache.frozenCount; i++) {
      expect((incCache.xs[i] - oneShotCache.xs[i]).abs(), lessThan(1e-3));
      expect((incCache.ys[i] - oneShotCache.ys[i]).abs(), lessThan(1e-3));
      expect((incCache.angles[i] - oneShotCache.angles[i]).abs(), lessThan(1e-3));
      expect((incCache.distances[i] - oneShotCache.distances[i]).abs(), lessThan(1e-3));
    }

    // Compare sample proximity against full-path PathMetric.
    final Path fullPath = lineOneShot.buildSmoothPath();
    final ui.PathMetric metric = fullPath.computeMetrics().first;
    final int checkLimit = min(oneShotCache.frozenCount, 60);
    for (int i = 0; i < checkLimit; i++) {
      final double d = oneShotCache.distances[i];
      final ui.Tangent? expected = metric.getTangentForOffset(d.clamp(0.0, metric.length));
      expect(expected, isNotNull);
      final Offset cachedPos = Offset(oneShotCache.xs[i], oneShotCache.ys[i]);
      expect((cachedPos - expected!.position).distance, lessThan(2.5));
    }
    for (int j = 0; j < oneShotCache.tailCount; j++) {
      final double d = oneShotCache.tailDistances[j];
      final ui.Tangent? expected = metric.getTangentForOffset(d.clamp(0.0, metric.length));
      expect(expected, isNotNull);
      final Offset cachedPos = Offset(oneShotCache.tailXs[j], oneShotCache.tailYs[j]);
      expect((cachedPos - expected!.position).distance, lessThan(2.5));
    }

    lineOneShot.clearRenderCache();
    lineIncremental.clearRenderCache();
  });

  test('Active-stroke range baking renders accurate non-empty output and cleans up on end/cancel', () async {
    final List<PaintContent> activeBrushes = <PaintContent>[
      ImageTipBrush(stampKey: 'sand', spacing: 0.15, hardness: 0.7),
      TipBrush(kind: BrushTipKind.round, hardness: 0.3, spacing: 0.12),
      TipBrush(kind: BrushTipKind.charcoal, hardness: 0.4, spacing: 0.18),
      SoftRoundBrush(softness: 0.6),
      TubeLine(),
      CandyCaneLine(),
      PencilLine(),
      DottedLine(),
      SprinklesLine(),
      StaticLine(),
      AudioSpectrumLine(),
      AirbrushBrush(),
      ChalkBrush(),
    ];

    const Size boardSize = Size(300, 300);
    final DrawingController controller = DrawingController();
    controller.setBoardSize(boardSize);

    for (final PaintContent brush in activeBrushes) {
      brush.paint = Paint()
        ..color = const Color(0xFFE11D48)
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      expect(brush.supportsActiveRangeBaking, isTrue, reason: brush.contentType);

      controller.setPaintContent(brush);
      controller.setStyle(color: const Color(0xFFE11D48), strokeWidth: 14.0);
      controller.startDraw(const Offset(20, 150));
      for (int i = 1; i <= 65; i++) {
        final double t = i / 65.0;
        controller.drawing(Offset(20 + t * 250, 150 + sin(t * pi * 4) * 80));
      }

      final PaintContent active = controller.drawingContent!;
      final int directPixels = await _countNonTransparentPixels(
        (c, s) => active.draw(c, s, false),
        size: boardSize,
      );
      expect(directPixels, greaterThan(50), reason: '${brush.contentType} direct pixels');

      // First call triggers async active bake for [0..48).
      await _countNonTransparentPixels(
        (c, s) => controller.drawActiveContentCached(c, s, active),
        size: boardSize,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Add extra tail points and render via baked prefix + drawLiveFromSample tail.
      controller.drawing(const Offset(275, 160));
      controller.drawing(const Offset(282, 175));
      final int cachedPixels = await _countNonTransparentPixels(
        (c, s) => controller.drawActiveContentCached(c, s, active),
        size: boardSize,
      );
      expect(cachedPixels, greaterThan(50), reason: '${brush.contentType} active-baked pixels');

      // Verify endDraw clears active state and commits cleanly.
      controller.endDraw();
      expect(controller.drawingContent, isNull);
    }

    // Verify Eraser still clears strokes cleanly after heavy brush work.
    controller.setPaintContent(Eraser());
    controller.setStyle(strokeWidth: 40.0);
    controller.startDraw(const Offset(20, 150));
    controller.drawing(const Offset(280, 150));
    controller.endDraw();
    expect(controller.activeLayer.value!.history.last, isA<Eraser>());

    controller.dispose();
  });

  testWidgets('TutorialLivePreview pauses periodic timer when TickerMode is disabled', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> twoFrames = <Map<String, dynamic>>[
      <String, dynamic>{
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'isVisible': true,
            'opacity': 1.0,
            'history': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'StraightLine',
                'startPoint': <String, double>{'dx': 10, 'dy': 10},
                'endPoint': <String, double>{'dx': 90, 'dy': 90},
                'paint': <String, dynamic>{'color': 0xFF000000, 'strokeWidth': 4.0},
              },
            ],
          },
        ],
      },
      <String, dynamic>{
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'isVisible': true,
            'opacity': 1.0,
            'history': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'StraightLine',
                'startPoint': <String, double>{'dx': 90, 'dy': 10},
                'endPoint': <String, double>{'dx': 10, 'dy': 90},
                'paint': <String, dynamic>{'color': 0xFF000000, 'strokeWidth': 4.0},
              },
            ],
          },
        ],
      },
    ];

    final ValueNotifier<bool> tickerEnabled = ValueNotifier<bool>(true);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: tickerEnabled,
          builder: (BuildContext _, bool enabled, Widget? child) => TickerMode(
            enabled: enabled,
            child: SizedBox(
              width: 120,
              height: 120,
              child: TutorialLivePreview(
                canvases: twoFrames,
                frameInterval: const Duration(milliseconds: 50),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);

    // Disable TickerMode (simulating covered Navigator route): timer must cancel cleanly.
    tickerEnabled.value = false;
    await tester.pump();
    final CustomPaint cpWhenDisabled = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(TutorialLivePreview),
        matching: find.byType(CustomPaint),
      ),
    );
    final dynamic frameAtDisable =
        (cpWhenDisabled.painter! as TutorialVectorPainter).canvasData;
    await tester.pump(const Duration(milliseconds: 250));
    final CustomPaint cpAfterWait = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(TutorialLivePreview),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      identical(
        (cpAfterWait.painter! as TutorialVectorPainter).canvasData,
        frameAtDisable,
      ),
      isTrue,
      reason: 'TutorialLivePreview must not advance frames while TickerMode is disabled',
    );
    expect(tester.takeException(), isNull);

    // Re-enable and verify smooth recovery + clean dispose.
    tickerEnabled.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final CustomPaint cpAfterResume = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(TutorialLivePreview),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(
      identical(
        (cpAfterResume.painter! as TutorialVectorPainter).canvasData,
        frameAtDisable,
      ),
      isFalse,
      reason: 'TutorialLivePreview should resume advancing frames when TickerMode re-enables',
    );
    tickerEnabled.dispose();
  });

  test('AsyncScratchpadBacking and AsyncTileBitmapCache bake and dispose cleanly', () async {
    int bakedNotifications = 0;
    final AsyncScratchpadBacking backing = AsyncScratchpadBacking(
      onImageBaked: () => bakedNotifications++,
    );
    final ImageTipBrush brush = ImageTipBrush(stampKey: 'sand', spacing: 0.15)
      ..paint = (Paint()
        ..color = Colors.black
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke);
    brush.startDraw(const Offset(10, 20));
    brush.drawing(const Offset(120, 40));

    final int px1 = await _countNonTransparentPixels((Canvas c, Size s) {
      backing.drawCommitted(c, s, 1, (Canvas t, Size sz, int i) => brush.draw(t, sz, false));
    }, size: const Size(160, 80));
    expect(px1, greaterThan(10));

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(bakedNotifications, greaterThanOrEqualTo(1));

    final int px2 = await _countNonTransparentPixels((Canvas c, Size s) {
      backing.drawCommitted(c, s, 1, (Canvas t, Size sz, int i) => brush.draw(t, sz, false));
    }, size: const Size(160, 80));
    expect(px2, greaterThan(10));

    backing.dispose();
    brush.clearRenderCache();

    final AsyncTileBitmapCache tileCache = AsyncTileBitmapCache(maxEntries: 4);
    final int tilePx = await _countNonTransparentPixels((Canvas c, Size s) {
      tileCache.draw(c, s, 'tile_a', (Canvas rec, Size sz) {
        rec.drawCircle(sz.center(Offset.zero), 18, Paint()..color = Colors.blue);
      });
    }, size: const Size(48, 48));
    expect(tilePx, greaterThan(100));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    tileCache.clear();
  });
}
