import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/editor/presentation/screens/font_selection_screen.dart';
import 'package:dummy/features/editor/presentation/widgets/sticker_widgets/text_sticker_widget.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_controller.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/core/widgets/font_presets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FontSelectionScreen renders live preview banner and font cards', (WidgetTester tester) async {
    final sticker = ActiveTextSticker(
      id: 'test_text_sticker',
      text: 'Hello World',
      color: Colors.black,
      fontSize: 24,
      fontFamily: 'Alex Brush',
    );

    final controller = EditorController(
      repository: ProjectRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FontSelectionScreen(
          sticker: sticker,
          controller: controller,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title and Subtitle
    expect(find.text('Typography & Fonts'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Verify Live Preview Banner
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('Hello World'), findsWidgets);

    // Verify Category Tabs exist
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Script & Cursive'), findsOneWidget);
    expect(find.text('Bold & Display'), findsOneWidget);

    // Verify search input is present
    expect(find.byType(TextField), findsWidgets);

    // Tap on a category tab (e.g., Script & Cursive)
    await tester.tap(find.text('Script & Cursive'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify font in Script & Cursive appears
    expect(find.text('Dancing Script'), findsOneWidget);

    // Tap on an undownloaded font card (Dancing Script) -> should not select it yet
    await tester.tap(find.text('Dancing Script'));
    await tester.pump(const Duration(milliseconds: 100));

    // Sticker font should remain 'Alex Brush' because Dancing Script is not downloaded in test env
    expect(sticker.fontFamily, 'Alex Brush');
  });

  testWidgets('FontSelectionScreen search filters fonts accurately', (WidgetTester tester) async {
    final sticker = ActiveTextSticker(
      id: 'test_text_sticker',
      text: 'Typo Test',
      color: Colors.blue,
      fontSize: 20,
    );

    final controller = EditorController(
      repository: ProjectRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FontSelectionScreen(
          sticker: sticker,
          controller: controller,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Search for a specific font
    final searchField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText?.contains('Search') == true,
    );
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'bebas');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bebas Neue'), findsOneWidget);
    expect(find.text('Dancing Script'), findsNothing);
  });

  testWidgets('FontSelectionScreen does not show font count subtitle and manages download icon properly', (WidgetTester tester) async {
    final sticker = ActiveTextSticker(
      id: 'test_text_sticker_2',
      text: 'Sample',
      color: Colors.black,
      fontSize: 22,
      fontFamily: 'Roboto',
    );

    final controller = EditorController(
      repository: ProjectRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FontSelectionScreen(
          sticker: sticker,
          controller: controller,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Title is simply Typography & Fonts
    expect(find.text('Typography & Fonts'), findsOneWidget);

    // Ensure no font count subtitle or number badges are rendered
    expect(find.textContaining('Fonts Ready'), findsNothing);
    expect(find.textContaining('of 258'), findsNothing);
    expect(find.text('258'), findsNothing);
    expect(find.text('42'), findsNothing);
    expect(find.text('34'), findsNothing);

    // Ensure search hint does not contain numbers
    expect(find.text('Search fonts & styles...'), findsOneWidget);
    expect(find.textContaining('250+'), findsNothing);
  });
}


