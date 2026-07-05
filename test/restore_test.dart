import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/main.dart'; 
import 'package:dummy/project_repository.dart';

void main() {
  testWidgets('Drawing app restores lines correctly', (WidgetTester tester) async {
    // Set screen size to prevent overflow of AppBar actions
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = ProjectRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 500));

    // Navigate from ProjectsScreen to MyHomePage
    await tester.tap(find.text('New Project'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Dismiss aspect ratio dialog
    await tester.tap(find.text('Free (Fill Space)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final boardFinder = find.byType(InteractiveViewer);
    expect(boardFinder, findsOneWidget);

    final center = tester.getCenter(boardFinder);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(50, 50));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Save JSON'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('clear'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Load JSON'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
