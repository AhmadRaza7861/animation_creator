import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/main.dart'; 
import 'package:dummy/project_repository.dart';

void main() {
  testWidgets('Drawing app restores lines correctly', (WidgetTester tester) async {
    final repository = ProjectRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 500));

    final boardFinder = find.byType(InteractiveViewer);
    expect(boardFinder, findsOneWidget);

    final center = tester.getCenter(boardFinder);
    await tester.dragFrom(center, const Offset(50, 50));
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
