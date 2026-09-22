import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/screens/image_crop_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File testImageFile;

  setUpAll(() async {
    // Generate a simple valid PNG test image
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 100), Paint()..color = Colors.blue);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(200, 100);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final Directory tempDir = Directory.systemTemp;
    testImageFile = File('${tempDir.path}/test_crop_image.png');
    await testImageFile.writeAsBytes(pngBytes);
  });

  tearDownAll(() async {
    if (await testImageFile.exists()) {
      await testImageFile.delete();
    }
  });

  testWidgets('ImageCropScreen renders correctly with 16:9 aspect ratio badge and action buttons', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImageCropScreen(
            imageFile: testImageFile,
            targetAspectRatio: 16.0 / 9.0,
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });

    // Verify top bar elements
    expect(find.text('Image import'), findsOneWidget);
    expect(find.text('16:9'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Verify toolbar tool icons
    expect(find.byIcon(Icons.flip_rounded), findsNWidgets(2)); // Horizontal and Vertical
    expect(find.byIcon(Icons.rotate_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
  });

  testWidgets('ImageCropScreen toolbar interactions trigger without errors', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImageCropScreen(
            imageFile: testImageFile,
            targetAspectRatio: 1.0,
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });

    // Tap Flip Horizontal
    await tester.tap(find.byTooltip('Flip Horizontal'));
    await tester.pump();

    // Tap Flip Vertical
    await tester.tap(find.byTooltip('Flip Vertical'));
    await tester.pump();

    // Tap Rotate Right
    await tester.tap(find.byTooltip('Rotate Right'));
    await tester.pump();

    // Tap Rotate Left
    await tester.tap(find.byTooltip('Rotate Left'));
    await tester.pump();

    // Tap Fit / Cover Toggle
    await tester.tap(find.byTooltip('Fit Entire Image'));
    await tester.pump();

    // Tap Reset
    await tester.tap(find.byTooltip('Reset Transforms'));
    await tester.pump();

    // Verify screen is still active and stable
    expect(find.text('1:1'), findsOneWidget);
  });
}
