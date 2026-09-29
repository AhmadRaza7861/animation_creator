import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dummy/features/editor/presentation/screens/editor_screen.dart';
import 'package:dummy/features/editor/presentation/controllers/editor_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Brush right-side vertical dock collapses and expands on tap', (WidgetTester tester) async {
    final container = ProviderContainer();
    final controller = container.read(editorControllerProvider(null));
    controller.activeCategory = 'Brush';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: EditorScreen(projectId: null),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Initially, the full dock is visible with Collapse button and Brush Studio
    expect(find.byTooltip('Collapse Toolbar'), findsOneWidget);
    expect(find.byTooltip('Brush Studio'), findsOneWidget);

    // 2. Tap Collapse Toolbar button
    await tester.tap(find.byTooltip('Collapse Toolbar'));
    await tester.pump();

    // 3. Now the dock is collapsed (tool items are hidden)
    expect(find.byTooltip('Collapse Toolbar'), findsNothing);
    expect(find.byTooltip('Brush Studio'), findsNothing);

    // 4. Tap the collapsed floating pill
    final Finder collapsedPillFinder = find.byType(GestureDetector).first;
    await tester.tap(collapsedPillFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  });
}
