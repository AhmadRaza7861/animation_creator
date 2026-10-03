import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/localization/app_localizations.dart';
import 'package:dummy/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OnboardingScreen renders 3 screens and navigates correctly', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    // Screen 1 checks
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Swipe to Screen 2
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Flip Your'), findsOneWidget);
    expect(find.textContaining('Frames'), findsOneWidget);

    // Swipe to Screen 3
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ready To'), findsOneWidget);
    expect(find.textContaining('Animate'), findsOneWidget);
    expect(find.text('Start Drawing'), findsOneWidget);
  });
}
