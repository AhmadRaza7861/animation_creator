import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/rating_strategy_service.dart';
import 'package:dummy/core/utils/app_path_provider.dart';
import 'package:dummy/features/settings/presentation/dialogs/rate_us_dialog.dart';
import 'package:dummy/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rating_test_');
    AppPathProvider.overrideDocumentsDirectory = tempDir;
    await RatingStrategyService.resetForTesting();
  });

  tearDown(() async {
    AppPathProvider.overrideDocumentsDirectory = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
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

    test('When user rates, markRated stops prompts permanently', () async {
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);

      await RatingStrategyService.markRated();
      expect(RatingStrategyService.hasRated, isTrue);
      expect(await RatingStrategyService.shouldShowPrompt(), isFalse);
    });

    testWidgets('Button text displays correctly and Maybe Later button is removed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: RateUsDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no stars selected, button text is "Rate Us"
      expect(find.text('Rate Us'), findsOneWidget);

      // Tap 1st star
      final stars = find.byType(GestureDetector);
      await tester.tap(stars.at(0)); // 1 star
      await tester.pumpAndSettle();

      // For 1 star on non-iOS it shows Submit Feedback
      expect(find.text('Submit Feedback'), findsOneWidget);

      // Tap 5th star (5 stars)
      await tester.tap(stars.at(4)); // 5 stars
      await tester.pumpAndSettle();

      // For 5 stars it shows Rate Us
      expect(find.text('Rate Us'), findsOneWidget);

      // Verify "Maybe Later" / later button does NOT exist
      expect(find.text('Maybe Later'), findsNothing);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('Home visit on 2nd session triggers rating dialog', (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              testContext = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      // 1st visit: appOpenCount becomes 1, dialog not shown
      await tester.runAsync(() async {
        await RatingStrategyService.recordHomeVisit(testContext!);
      });
      await tester.pump();
      expect(RatingStrategyService.appOpenCount, equals(1));
      expect(find.byType(RateUsDialog), findsNothing);

      // Simulate 2nd app launch by resetting in-memory session flag while retaining persisted state
      RatingStrategyService.resetSessionForTesting();

      // Now 2nd visit:
      await tester.runAsync(() async {
        RatingStrategyService.recordHomeVisit(testContext!);
        await Future.delayed(const Duration(milliseconds: 800));
      });
      await tester.pumpAndSettle();
      expect(RatingStrategyService.appOpenCount, equals(2));
      expect(find.byType(RateUsDialog), findsOneWidget);

      // Dismiss dialog
      Navigator.of(testContext!, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(find.byType(RateUsDialog), findsNothing);
    });

    testWidgets('recordReturnedFromEditor triggers dialog and stops after markRated', (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      // Trigger return from editor
      await tester.runAsync(() async {
        RatingStrategyService.recordReturnedFromEditor(testContext!);
        await Future.delayed(const Duration(milliseconds: 800));
      });
      await tester.pumpAndSettle();

      // Rating dialog should now be displayed
      expect(find.byType(RateUsDialog), findsOneWidget);

      // Dismiss dialog
      Navigator.of(testContext!, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(find.byType(RateUsDialog), findsNothing);

      // Once user rates, should not show again
      await tester.runAsync(() async {
        await RatingStrategyService.markRated();
        RatingStrategyService.recordReturnedFromEditor(testContext!);
        await Future.delayed(const Duration(milliseconds: 800));
      });
      await tester.pumpAndSettle();
      expect(find.byType(RateUsDialog), findsNothing);
    });
  });
}
