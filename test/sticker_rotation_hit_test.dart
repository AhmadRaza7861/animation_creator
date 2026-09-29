import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/shape_sticker_widget.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/text_sticker_widget.dart';
import 'package:dummy/package_code/paint_contents.dart';

void main() {
  testWidgets('ShapeStickerWidget rotate handle receives hit test at scale 0.2', (WidgetTester tester) async {
    double currentRotation = 0.0;
    double currentScale = 0.2;
    Offset currentOffset = const Offset(300, 300);

    final sticker = ActiveShapeSticker(
      id: 'test_sticker',
      content: EmptyContent(),
      size: const Size(200, 200),
      offset: currentOffset,
      scale: currentScale,
      rotation: currentRotation,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return ShapeStickerWidget(
                    data: sticker,
                    onUpdate: (offset, scale, rotation) {
                      setState(() {
                        currentOffset = offset;
                        currentScale = scale;
                        currentRotation = rotation;
                        sticker.offset = offset;
                        sticker.scale = scale;
                        sticker.rotation = rotation;
                      });
                    },
                    onDelete: () {},
                    onConfirm: () {},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rotateIconFinder = find.byIcon(Icons.rotate_right_rounded);
    expect(rotateIconFinder, findsOneWidget);

    final rotateCenter = tester.getCenter(rotateIconFinder);

    // Drag the rotate icon to rotate the sticker
    final gesture = await tester.startGesture(rotateCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(currentRotation, isNot(0.0));
  });

  testWidgets('TextStickerWidget rotate handle receives hit test at scale 0.2', (WidgetTester tester) async {
    double currentRotation = 0.0;
    double currentScale = 0.2;
    Offset currentOffset = const Offset(300, 300);

    final sticker = ActiveTextSticker(
      id: 'test_text',
      text: 'Hello World',
      color: Colors.white,
      fontSize: 24,
      offset: currentOffset,
      scale: currentScale,
      rotation: currentRotation,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return TextStickerWidget(
                    data: sticker,
                    onUpdate: (offset, scale, rotation) {
                      setState(() {
                        currentOffset = offset;
                        currentScale = scale;
                        currentRotation = rotation;
                        sticker.offset = offset;
                        sticker.scale = scale;
                        sticker.rotation = rotation;
                      });
                    },
                    onDelete: () {},
                    onConfirm: () {},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rotateIconFinder = find.byIcon(Icons.rotate_right_rounded);
    expect(rotateIconFinder, findsOneWidget);

    final rotateCenter = tester.getCenter(rotateIconFinder);

    // Drag the rotate icon
    final gesture = await tester.startGesture(rotateCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(currentRotation, isNot(0.0));
  });
}
