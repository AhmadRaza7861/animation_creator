import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class RateUsDialog extends StatefulWidget {
  final String? appPackageName;

  const RateUsDialog({super.key, this.appPackageName});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RateUsDialog(),
    );
  }

  @override
  State<RateUsDialog> createState() => _RateUsDialogState();
}

class _RateUsDialogState extends State<RateUsDialog> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _submittedFeedback = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String _getRatingLabel(BuildContext context) {
    switch (_rating) {
      case 1:
        return context.tr('rating1');
      case 2:
        return context.tr('rating2');
      case 3:
        return context.tr('rating3');
      case 4:
        return context.tr('rating4');
      case 5:
      default:
        return context.tr('rating5');
    }
  }

  Future<void> _handleRateAction() async {
    if (_rating >= 4) {
      // Direct user to store
      final Uri storeUri = Uri.parse(
        'market://details?id=${widget.appPackageName ?? 'com.clipax.animationcreator'}',
      );
      final Uri webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=${widget.appPackageName ?? 'com.clipax.animationcreator'}',
      );

      try {
        if (await canLaunchUrl(storeUri)) {
          await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Could not launch store URL: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('thankYouSupport')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Constructive feedback submission
      setState(() {
        _submittedFeedback = true;
      });

      final feedbackText = _feedbackController.text.trim();
      if (feedbackText.isNotEmpty) {
        final Uri mailtoUri = Uri(
          scheme: 'mailto',
          path: 'support@clipax.app',
          query: 'subject=Clipax User Feedback (${_rating} Stars)&body=${Uri.encodeComponent(feedbackText)}',
        );
        try {
          if (await canLaunchUrl(mailtoUri)) {
            await launchUrl(mailtoUri);
          }
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('thankYouFeedback')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Top App Icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9318), Color(0xFFFF5E28)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),

            Text(
              context.tr('enjoyingClipax'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ColorConstants.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('rateUsDescription'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: ColorConstants.mediumText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // Interactive Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _rating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starNumber;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSelected ? const Color(0xFFFFB038) : Colors.grey.shade300,
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Rating description
            Text(
              _getRatingLabel(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _rating >= 4 ? ColorConstants.primary : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Conditional feedback box if <= 3 stars
            if (_rating <= 3) ...[
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: context.tr('whatCanWeImprove'),
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: ColorConstants.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submittedFeedback ? null : _handleRateAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _rating >= 4 ? context.tr('rateOnStore') : context.tr('submitFeedback'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Maybe Later button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('maybeLater'),
                style: const TextStyle(
                  color: ColorConstants.mediumText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

