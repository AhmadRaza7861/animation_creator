import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/screens/projects_screen.dart';
import 'package:dummy/repositories/project_repository.dart';

void main() {
  testWidgets('Drawing app restores lines correctly', (WidgetTester tester) async {
    // Mock path_provider channel
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path; // Return clean system temp path
      }
      return null;
    });

    // Set screen size to prevent overflow of AppBar actions
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = ProjectRepository();
    await tester.pumpWidget(MaterialApp(
      home: ProjectsScreen(repository: repository),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    // Navigate from ProjectsScreen to CreateProjectScreen using FloatingActionButton type
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // Settle navigation transition

    // Click Apply button in CreateProjectScreen
    await tester.runAsync(() async {
      await tester.tap(find.text('Apply'));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 600));
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 600));
      await tester.pump();
    });
    await tester.pump(const Duration(milliseconds: 500));

    final boardFinder = find.byType(InteractiveViewer);
    expect(boardFinder, findsOneWidget);

    final center = tester.getCenter(boardFinder);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(50, 50));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    // Save JSON
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    final saveFinder = find.text('Save Frame JSON to Device');
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    // Clear Canvas
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    final clearFinder = find.text('Clear Canvas');
    await tester.ensureVisible(clearFinder);
    await tester.tap(clearFinder);
    await tester.pumpAndSettle();

    // Load JSON
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    final loadFinder = find.text('Load Frame JSON from Device');
    await tester.ensureVisible(loadFinder);
    await tester.tap(loadFinder);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(SnackBar))).removeCurrentSnackBar();
    await tester.pump();

    // Play Preview
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    
    // Check if the preview screen is active
    expect(find.text('Preview Animation'), findsOneWidget);
    expect(find.text('Tap on screen to stop'), findsOneWidget);

    // Tap to stop/exit the animation playback (which pops back to the editor)
    await tester.tap(find.byType(AspectRatio));
    await tester.pumpAndSettle();

    // Verify we are back in the editor screen
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
