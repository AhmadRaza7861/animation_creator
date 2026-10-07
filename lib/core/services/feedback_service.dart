import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../localization/app_localizations.dart';
import 'firebase_options.dart';

class FeedbackService {
  FeedbackService._();

  static FirebaseFirestore? _firestoreInstance;

  static FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  /// Saves a user's rating (1-3 stars) and constructive feedback to Firestore.
  static Future<bool> submitFeedback({
    required int rating,
    required String feedback,
    String? ratingLabel,
    String? languageCode,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (e) {
          debugPrint('FeedbackService Firebase.initializeApp: $e');
        }
      }

      final String platformName = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : Platform.isMacOS
                      ? 'macos'
                      : 'other';

      final Map<String, dynamic> data = {
        'rating': rating,
        'rating_label': ratingLabel ?? '',
        'feedback': feedback.trim(),
        'platform': platformName,
        'language': languageCode ?? AppLocalizations.current.locale.languageCode,
        'app_version': '1.0.0+15',
        'created_at': FieldValue.serverTimestamp(),
        'created_at_local': DateTime.now().toIso8601String(),
      };

      if (Firebase.apps.isNotEmpty) {
        // Set timeout so slow network / offline mode never hangs the UI
        await FirebaseFirestore.instance
            .collection('feedback')
            .add(data)
            .timeout(const Duration(seconds: 3));

        debugPrint('Feedback saved successfully to Firebase Firestore: $data');
      } else {
        debugPrint('Firebase not initialized; feedback acknowledged');
      }
      return true;
    } on TimeoutException {
      debugPrint('Feedback submitted (queued in Firestore background sync)');
      return true;
    } catch (e, stack) {
      debugPrint('Error saving feedback to Firestore: $e\n$stack');
      return false;
    }
  }

  /// Saves a contact us / support ticket message to Firestore ('contact_messages' collection).
  static Future<bool> submitContactMessage({
    required String topic,
    required String subject,
    required String message,
    String? userEmail,
    String? languageCode,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (e) {
          debugPrint('FeedbackService Firebase.initializeApp: $e');
        }
      }

      final String platformName = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : Platform.isMacOS
                      ? 'macos'
                      : 'other';

      final Map<String, dynamic> data = {
        'topic': topic,
        'subject': subject.trim(),
        'message': message.trim(),
        'user_email': userEmail?.trim() ?? '',
        'platform': platformName,
        'language': languageCode ?? AppLocalizations.current.locale.languageCode,
        'app_version': '1.0.0+15',
        'created_at': FieldValue.serverTimestamp(),
        'created_at_local': DateTime.now().toIso8601String(),
      };

      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('contact_messages')
            .add(data)
            .timeout(const Duration(seconds: 3));

        debugPrint('Contact message saved successfully to Firestore: $data');
      } else {
        debugPrint('Firebase not initialized; contact message acknowledged');
      }
      return true;
    } on TimeoutException {
      debugPrint('Contact message submitted (queued in Firestore background sync)');
      return true;
    } catch (e, stack) {
      debugPrint('Error saving contact message to Firestore: $e\n$stack');
      return false;
    }
  }
}
