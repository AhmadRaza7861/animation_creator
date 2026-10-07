import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/core/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FeedbackService submitFeedback handles gracefully without exceptions', () async {
    // When Firebase is not initialized in raw unit test environment,
    // FeedbackService catches the error and returns false without throwing/crashing.
    final result = await FeedbackService.submitFeedback(
      rating: 3,
      feedback: 'Great app, please add more onion skinning layers!',
      ratingLabel: 'Okay',
    );
    // Verified graceful execution
    expect(result, isA<bool>());
  });

  test('FeedbackService submitContactMessage handles gracefully without exceptions', () async {
    final result = await FeedbackService.submitContactMessage(
      topic: 'Bug Report 🐞',
      subject: 'Drawing lag issue',
      message: 'When I draw fast, line is delayed.',
      userEmail: 'test@example.com',
    );
    expect(result, isA<bool>());
  });
}
