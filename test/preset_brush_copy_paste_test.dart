import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/package_code/paint_contents.dart';
import 'package:dummy/package_code/src/paint_contents/paint_content_decoder.dart';
import 'package:dummy/package_code/src/paint_contents/preset_strokes.dart';
import 'package:dummy/package_code/src/paint_contents/stroke_styles.dart';
import 'package:dummy/package_code/src/drawing_controller.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/editor/services/global_clipboard.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlobalClipboard.instance.clearAll();
  });

  tearDown(() {
    GlobalClipboard.instance.clearAll();
  });

  group('Brush Tips & Preset Strokes Serialization and Copy/Paste Tests', () {
    test('decodePaintContent decodes all preset brush tips accurately', () {
      final roughPen = RoughPenLine.data(
        minPointDistance: 2.0,
        points: const [Offset(10, 10), Offset(20, 30), Offset(50, 80)],
        paint: Paint()..color = Colors.blue..strokeWidth = 12.0,
      );

      final roughJson = roughPen.toJson();
      expect(roughJson['type'], equals('RoughPenLine'));

      final decoded = decodePaintContent('RoughPenLine', roughJson);
      expect(decoded, isNotNull);
      expect(decoded, isA<RoughPenLine>());
      final decodedRough = decoded as RoughPenLine;
      expect(decodedRough.points.length, equals(3));
      expect(decodedRough.paint.strokeWidth, equals(12.0));
      expect(decodedRough.paint.color.toARGB32(), equals(Colors.blue.toARGB32()));
    });

    test('decodePaintContent decodes all other preset brush strokes', () {
      final presetTypes = [
        ChoppyLine.data(points: const [Offset(0, 0)], paint: Paint()),
        RoughPenLine.data(points: const [Offset(0, 0)], paint: Paint()),
        InkLine.data(points: const [Offset(0, 0)], paint: Paint()),
        PencilLine.data(points: const [Offset(0, 0)], paint: Paint()),
        HalftoneLine.data(points: const [Offset(0, 0)], paint: Paint()),
        HatchLine.data(points: const [Offset(0, 0)], paint: Paint()),
        MosaicLine.data(points: const [Offset(0, 0)], paint: Paint()),
        TubeLine.data(points: const [Offset(0, 0)], paint: Paint()),
        CandyCaneLine.data(points: const [Offset(0, 0)], paint: Paint()),
        SparklesLine.data(points: const [Offset(0, 0)], paint: Paint()),
        SprinklesLine.data(points: const [Offset(0, 0)], paint: Paint()),
        StaticLine.data(points: const [Offset(0, 0)], paint: Paint()),
        NeonGlowLine.data(points: const [Offset(0, 0)], paint: Paint()),
        RainbowLine.data(points: const [Offset(0, 0)], paint: Paint()),
        RibbonLine.data(points: const [Offset(0, 0)], paint: Paint()),
        ConstellationLine.data(points: const [Offset(0, 0)], paint: Paint()),
        ChainLine.data(points: const [Offset(0, 0)], paint: Paint()),
        ElectricArcLine.data(points: const [Offset(0, 0)], paint: Paint()),
        BubbleTrailLine.data(points: const [Offset(0, 0)], paint: Paint()),
        AudioSpectrumLine.data(points: const [Offset(0, 0)], paint: Paint()),
        StitchLine.data(points: const [Offset(0, 0)], paint: Paint()),
        SawLine.data(points: const [Offset(0, 0)], paint: Paint()),
        ZigzagLine.data(points: const [Offset(0, 0)], paint: Paint()),
        GearLine.data(points: const [Offset(0, 0)], paint: Paint()),
        HeartbeatLine.data(points: const [Offset(0, 0)], paint: Paint()),
        HairLine.data(points: const [Offset(0, 0)], paint: Paint()),
        PixelLine.data(points: const [Offset(0, 0)], paint: Paint()),
        GradientLine.data(points: const [Offset(0, 0)], paint: Paint()),
        SketchLine.data(points: const [Offset(0, 0)], paint: Paint()),
      ];

      for (final stroke in presetTypes) {
        final json = stroke.toJson();
        final decoded = decodePaintContent(stroke.contentType, json);
        expect(decoded, isNotNull, reason: 'Failed to decode ${stroke.contentType}');
        expect(decoded.runtimeType, equals(stroke.runtimeType));
      }
    });

    test('Drawing with Rough Pen on frame 0, copying frame, and pasting on frame 1 transfers stroke', () async {
      final controller = EditorController(repository: ProjectRepository());
      controller.addFrame(); // Frame 0 and Frame 1

      // 1. Select frame 0 and draw with Rough Pen
      controller.selectCanvas(0);
      final roughPen = RoughPenLine.data(
        minPointDistance: 2.0,
        points: const [Offset(10, 10), Offset(50, 100), Offset(100, 200)],
        paint: Paint()..color = Colors.black..strokeWidth = 50.0,
      );
      controller.drawingController.addContent(roughPen);

      expect(controller.drawingController.getHistory.length, equals(1));
      expect(controller.drawingController.getHistory.first, isA<RoughPenLine>());

      // 2. Copy frame 0
      controller.copyFrame(0);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.hasClipboardFrame, isTrue);

      // 3. Paste onto frame 1
      controller.pasteFrame(1);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      controller.selectCanvas(1);
      expect(controller.drawingController.getHistory.length, equals(1));
      expect(controller.drawingController.getHistory.first, isA<RoughPenLine>());
      final pastedStroke = controller.drawingController.getHistory.first as RoughPenLine;
      expect(pastedStroke.points.length, equals(3));
      expect(pastedStroke.paint.strokeWidth, equals(50.0));
    });
  });
}
