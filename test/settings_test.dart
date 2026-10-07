import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummy/features/settings/presentation/screens/settings_screen.dart';
import 'package:dummy/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:dummy/features/settings/presentation/screens/terms_of_service_screen.dart';
import 'package:dummy/features/settings/presentation/dialogs/rate_us_dialog.dart';
import 'package:dummy/features/settings/presentation/dialogs/contact_us_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dummy/features/settings/presentation/screens/language_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings & Legal Module Tests', () {
    testWidgets('SettingsScreen renders Language, Rate Us, Contact Us, Privacy Policy, and Terms', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Rate Us'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Share Clipax'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('PrivacyPolicyScreen renders offline storage sections and contact button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Your Privacy is Our Priority'), findsOneWidget);
      expect(find.textContaining('1. Local Data Storage'), findsOneWidget);
      expect(find.textContaining('2. Device Permissions'), findsOneWidget);
      expect(find.textContaining('3. Personal Information'), findsOneWidget);
      expect(find.text('Contact Support Team'), findsOneWidget);
    });

    testWidgets('TermsOfServiceScreen renders usage terms sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsOfServiceScreen(),
        ),
      );

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.textContaining('1. Acceptance of Terms'), findsOneWidget);
      expect(find.textContaining('2. Intellectual Property & Artwork Ownership'), findsOneWidget);
    });

    testWidgets('RateUsDialog allows interactive star rating selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateUsDialog(),
          ),
        ),
      );

      expect(find.text('Enjoying Clipax?'), findsOneWidget);
      // Initially no stars selected by default
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(1)); // Top badge only

      // Tap 5th star
      final starOutlines = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(starOutlines.at(4));
      await tester.pump();

      expect(find.text('Loved it! Amazing! 🤩'), findsOneWidget);
      expect(find.text('Rate on App Store / Play Store'), findsOneWidget);

      // Tap 2nd star
      final stars = find.byIcon(Icons.star_rounded);
      await tester.tap(stars.at(2));
      await tester.pump();

      expect(find.text('Could be better 😐'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
      expect(find.text('What can we improve? (Optional)'), findsOneWidget);
    });

    testWidgets('ContactUsDialog renders category choices and input fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContactUsDialog(),
          ),
        ),
      );

      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Bug Report 🐞'), findsOneWidget);
      expect(find.text('Feature Request 💡'), findsOneWidget);
      expect(find.text('Your Email'), findsOneWidget);
      expect(find.text('Open Email Client'), findsOneWidget);
      expect(find.textContaining('nextgenappsmaker@gmail.com'), findsOneWidget);
    });
  });
}
