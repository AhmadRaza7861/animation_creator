import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/splash/presentation/screens/splash_screen.dart';
import 'package:dummy/features/projects/data/project_repository.dart';
import 'package:dummy/features/projects/domain/project_model.dart';

class FakeProjectRepository implements ProjectRepository {
  @override
  Future<List<ProjectMeta>> listProjects() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SplashScreen renders cinematic vector drawing logo, letter-by-letter reveal and dynamic phases', (WidgetTester tester) async {
    final fakeRepo = FakeProjectRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(repository: fakeRepo),
      ),
    );

    // Initial frame
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(find.text('l'), findsOneWidget);
    expect(find.text('i'), findsOneWidget);
    expect(find.text('p'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('x'), findsOneWidget);

    // Pump through logo drawing and typography reveal
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('ANIMATE ANYTHING'), findsOneWidget);

    // Pump midway to see dynamic status text and custom painters
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(CustomPaint), findsWidgets);

    // Fast-forward past the 6.0s delay to trigger navigation
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
