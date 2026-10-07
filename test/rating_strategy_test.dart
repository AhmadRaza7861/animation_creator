import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/rating_strategy_service.dart';

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

    test('Rule 1: Once user has rated or given feedback, shouldShowPrompt is permanently false', () async {
      expect(await RatingStrategyService.shouldShowPrompt(), isTrue);
      
      await RatingStrategyService.markRated();
      expect(RatingStrategyService.hasRated, isTrue);
      expect(await RatingStrategyService.shouldShowPrompt(), isFalse);
    });

    test('Rule 2: Cooldown period of 2 days is enforced after prompt is shown', () async {
      await RatingStrategyService.markPromptShown();
      expect(RatingStrategyService.promptCount, equals(1));
      expect(RatingStrategyService.lastPromptTime, isNotNull);

      // Should be blocked immediately during the 2-day cooldown
      expect(await RatingStrategyService.shouldShowPrompt(), isFalse);
    });

    test('Rule 3: Max lifetime limit of 3 prompts is strictly enforced', () async {
      await RatingStrategyService.markPromptShown();
      await RatingStrategyService.markPromptShown();
      await RatingStrategyService.markPromptShown();

      expect(RatingStrategyService.promptCount, equals(3));
      expect(await RatingStrategyService.shouldShowPrompt(), isFalse);
    });
  });
}
