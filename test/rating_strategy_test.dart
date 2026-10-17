import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/rating_strategy_service.dart';
import 'package:dummy/features/settings/presentation/dialogs/rate_us_dialog.dart';
import 'package:dummy/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await RatingStrategyService.resetForTesting();
  });

  group('Rating Strategy Rules & Triggers Tests', () {
    test('Initial state allows rating prompt eligibility', () async {
      expect(RatingStrategyService.hasRated, isFalse);
      expect(RatingStrategyService.promptCount, equals(0));
      expect(RatingStrategyService.exportCount, equals(0));
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);
    });

    test('If user dismisses dialog or clicks maybe later, shouldShowPrompt remains true for next time', () async {
      await RatingStrategyService.markPromptShown();
      expect(RatingStrategyService.promptCount, equals(1));
      expect(RatingStrategyService.hasRated, isFalse);

      // Dismissing / not rating keeps shouldShowPrompt true
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);

      // Multiple dismissals still show again next time
      await RatingStrategyService.markPromptShown();
      await RatingStrategyService.markPromptShown();
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);
    });

    test('When user rates 3 stars or less, markRated stops prompts permanently', () async {
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);

      await RatingStrategyService.markRated();
      expect(RatingStrategyService.hasRated, isTrue);
      expect(await RatingStrategyService.shouldShowPrompt(), isFalse);
    });

    testWidgets('Button text is always "Rate Us" whether 1 star, 3 stars, or 5 stars selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RateUsDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no stars selected, button text should be "Rate Us"
      expect(find.text('Rate Us'), findsOneWidget);

      // Tap 1st star
      final stars = find.byType(GestureDetector);
      await tester.tap(stars.at(0)); // 1 star
      await tester.pumpAndSettle();

      // Button text MUST still be "Rate Us"
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsNothing);

      // Tap 3rd star (3 stars or less)
      await tester.tap(stars.at(2)); // 3 stars
      await tester.pumpAndSettle();

      // Button text MUST still be "Rate Us"
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsNothing);

      // Tap 5th star (5 stars)
      await tester.tap(stars.at(4)); // 5 stars
      await tester.pumpAndSettle();

      // Button text MUST still be "Rate Us"
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.text('Rate on Google Play'), findsNothing);
    });
  });
}
