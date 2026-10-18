import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/localization/app_localizations.dart';
import 'package:dummy/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dummy/features/onboarding/data/onboarding_service.dart';
import 'package:dummy/features/projects/data/project_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await OnboardingService.resetOnboarding();
  });

  Widget buildOnboardingTestApp(ProjectRepository repository, {Locale? locale}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingScreen(repository: repository),
    );
  }

  testWidgets('OnboardingScreen renders 4 screens with rich visuals and verified app features', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository));
    await tester.pumpAndSettle();

    // =========================================================================
    // SCREEN 1: Turn Your Drawings Into Animation
    // =========================================================================
    expect(find.textContaining('Turn Your Drawings Into'), findsOneWidget);
    expect(find.textContaining('Animation'), findsWidgets);
    expect(
      find.text('Draw your ideas and bring them to life with simple frame-by-frame animation.'),
      findsOneWidget,
    );
    expect(find.text('12 FPS'), findsOneWidget);
    expect(find.text('Frame-by-Frame'), findsOneWidget);
    expect(find.text('TIMELINE'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap "Continue" to navigate to Screen 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // =========================================================================
    // SCREEN 2: Create Every Detail
    // =========================================================================
    expect(find.textContaining('Create Every'), findsOneWidget);
    expect(find.textContaining('Detail'), findsWidgets);
    expect(
      find.text('Use drawing tools, colors, shapes, and other available editing features to create your own unique characters.'),
      findsOneWidget,
    );
    expect(find.text('Brush • 10px'), findsOneWidget);
    expect(find.text('Brush'), findsOneWidget);
    expect(find.text('Eraser'), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
    expect(find.text('Lasso'), findsOneWidget);
    expect(find.text('Shapes'), findsOneWidget);

    // Tap "Continue" to navigate to Screen 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // =========================================================================
    // SCREEN 3: Make Every Frame Count
    // =========================================================================
    expect(find.textContaining('Make Every Frame'), findsOneWidget);
    expect(find.textContaining('Count'), findsWidgets);
    expect(
      find.text('Add frames, adjust your animation speed, and preview your creation as it comes to life.'),
      findsOneWidget,
    );
    expect(find.text('Onion Skin ON'), findsOneWidget);
    expect(find.text('4 Keyframes'), findsOneWidget);

    // Tap "Continue" to navigate to Screen 4
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // =========================================================================
    // SCREEN 4: Save and Share Your Creation
    // =========================================================================
    expect(find.textContaining('Your Animation, Your'), findsOneWidget);
    expect(find.textContaining('Way'), findsWidgets);
    expect(
      find.text('Save your projects and export your creations in the formats supported by the app.'),
      findsOneWidget,
    );
    expect(find.text('Auto-Saved Offline'), findsOneWidget);
    expect(find.text('Ready to Share'), findsOneWidget);
    expect(find.text('MP4 Video'), findsOneWidget);
    expect(find.text('GIF Animation'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Top bar has no back arrow and allows smooth horizontal drag navigation', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository));
    await tester.pumpAndSettle();

    // Verify back arrow is NOT present in the top bar
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

    // Navigate to page 1
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Create Every'), findsOneWidget);

    // Verify back arrow is still NOT present
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

    // Swipe right to go back to page 0
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    // Must be back on Screen 1
    expect(find.textContaining('Turn Your Drawings Into'), findsOneWidget);
  });

  testWidgets('Skip button completes onboarding', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Onboarding should be marked completed
    final completed = await OnboardingService.isOnboardingCompleted();
    expect(completed, isTrue);
  });

  testWidgets('Get Started button completes onboarding on the last screen', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository));
    await tester.pumpAndSettle();

    // Advance 3 times to Screen 4
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final completed = await OnboardingService.isOnboardingCompleted();
    expect(completed, isTrue);
  });

  testWidgets('Top DRAW ANIMATION capsule and button sparkle/arrow icons are removed', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository));
    await tester.pumpAndSettle();

    // Verify DRAW ANIMATION pill is removed
    expect(find.text('DRAW ANIMATION'), findsNothing);

    // Verify no sparkle or arrow icons inside the primary action button
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  testWidgets('Onboarding renders localized strings when locale is Spanish', (tester) async {
    final repository = ProjectRepository();

    await tester.pumpWidget(buildOnboardingTestApp(repository, locale: const Locale('es')));
    await tester.pumpAndSettle();

    // Verify Spanish translations are rendered
    expect(find.textContaining('Convierte tus dibujos en'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Fotograma a fotograma'), findsOneWidget);
    expect(find.text('12 FPS'), findsOneWidget);
  });
}
