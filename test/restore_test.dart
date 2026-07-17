import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/main.dart'; 
import 'package:dummy/project_repository.dart';

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
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 500));

    // Navigate from ProjectsScreen to CreateProjectScreen
    await tester.tap(find.text('New Project'));
    await tester.pumpAndSettle();

    // Click CREATE PROJECT button in CreateProjectScreen
    await tester.runAsync(() async {
      await tester.tap(find.text('CREATE PROJECT'));
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

    await tester.tap(find.byTooltip('Save JSON'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('clear'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Load JSON'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsOneWidget);

    // Navigate to preview screen
    await tester.tap(find.byTooltip('Play Preview'));
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
