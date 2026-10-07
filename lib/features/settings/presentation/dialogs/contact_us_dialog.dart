import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common_widgets/show_toast.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';

class ContactUsDialog extends StatefulWidget {
  final String supportEmail;

  const ContactUsDialog({
    super.key,
    this.supportEmail = 'nextgenappsmaker@gmail.com',
  });

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ContactUsDialog(),
    );
  }

  @override
  State<ContactUsDialog> createState() => _ContactUsDialogState();
}

class _ContactUsDialogState extends State<ContactUsDialog> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _emailError;
  String? _messageError;

  final List<String> _categoryKeys = [
    'bugReportTopic',
    'featureRequestTopic',
    'questionTopic',
    'generalFeedbackTopic',
  ];

  @override
  void initState() {
    super.initState();
    _subjectController.text = 'Clipax Bug Report';
    _emailController.addListener(_clearEmailError);
    _messageController.addListener(_clearMessageError);
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearMessageError() {
    if (_messageError != null) {
      setState(() {
        _messageError = null;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailError);
    _messageController.removeListener(_clearMessageError);
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      if (index == 0) {
        _subjectController.text = 'Clipax Bug Report';
      } else if (index == 1) {
        _subjectController.text = 'Clipax Feature Request';
      } else if (index == 2) {
        _subjectController.text = 'Clipax Question & Help';
      } else {
        _subjectController.text = 'Clipax Feedback';
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$').hasMatch(email);
  }

  Future<void> _submitToFirebase() async {
    final userEmail = _emailController.text.trim();
    if (userEmail.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email address';
      });
      showToast(message: 'Please enter your email address');
      return;
    }

    if (!_isValidEmail(userEmail)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      showToast(message: 'Please enter a valid email address');
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _messageError = 'Please enter your message';
      });
      showToast(message: 'Please enter your message');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailError = null;
      _messageError = null;
    });

    final selectedTopicName = context.tr(_categoryKeys[_selectedCategoryIndex]);
    final subject = _subjectController.text.trim();

    try {
      await FeedbackService.submitContactMessage(
        topic: selectedTopicName,
        subject: subject.isNotEmpty ? subject : selectedTopicName,
        message: message,
        userEmail: userEmail,
      );
    } catch (e) {
      debugPrint('Contact submission error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.pop(context);
        showToast(message: 'Submit successfully');
      }
    }
  }

  Future<void> _sendViaEmailApp() async {
    final userEmail = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    final selectedCategoryName = context.tr(_categoryKeys[_selectedCategoryIndex]);

    final String platformName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Desktop');
    final String body = '''
Hello Clipax Team,

$message

-----------------------
From: ${userEmail.isNotEmpty ? userEmail : 'Not provided'}
Category: $selectedCategoryName
App: Clipax Animation Creator (v1.0.0)
Platform: $platformName
-----------------------
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: widget.supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        await _copyEmailToClipboard();
      }
    } catch (e) {
      debugPrint('Failed to open email client: $e');
      await _copyEmailToClipboard();
    }
  }

  Future<void> _copyEmailToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.supportEmail));
    showToast(message: 'Email copied: ${widget.supportEmail}');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with glowing icon badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9318), Color(0xFFFF5E28)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('contactUs'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ColorConstants.darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          context.tr('contactUsDescription'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: ColorConstants.mediumText,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.black54, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Topic Selector Section
              Text(
                context.tr('selectTopic'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_categoryKeys.length, (index) {
                  final key = _categoryKeys[index];
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFFF9318), Color(0xFFFF5E28)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF9318).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        context.tr(key),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Email Input (Required)
              Row(
                children: [
                  const Text(
                    'Your Email',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFFFF9318)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  hintText: 'name@example.com',
                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _emailError != null ? const Color(0xFFE53935) : Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _emailError != null ? const Color(0xFFE53935) : Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _emailError != null ? const Color(0xFFE53935) : ColorConstants.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_emailError != null) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Subject Input
              Text(
                context.tr('subject'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _subjectController,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.title_rounded, size: 16, color: Color(0xFFFF9318)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  hintText: context.tr('enterSubject'),
                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorConstants.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Message Input
              Row(
                children: [
                  Text(
                    context.tr('message'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _messageController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: context.tr('tellUsThoughts'),
                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _messageError != null ? const Color(0xFFE53935) : Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _messageError != null ? const Color(0xFFE53935) : Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _messageError != null ? const Color(0xFFE53935) : ColorConstants.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_messageError != null) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _messageError!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Submit / Send Message Button (Stores into Firebase Firestore)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9318), Color(0xFFFF5E28)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9318).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitToFirebase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('submitFeedback'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Alternative: Open email client or copy email
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    TextButton.icon(
                      onPressed: _sendViaEmailApp,
                      icon: const Icon(Icons.mail_outline_rounded, size: 13, color: ColorConstants.mediumText),
                      label: Text(
                        context.tr('openEmailClient'),
                        style: const TextStyle(fontSize: 11.5, color: ColorConstants.mediumText, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    TextButton.icon(
                      onPressed: _copyEmailToClipboard,
                      icon: const Icon(Icons.copy_rounded, size: 12, color: ColorConstants.mediumText),
                      label: Text(
                        context.tr('copyEmail', {'email': widget.supportEmail}),
                        style: const TextStyle(fontSize: 11.5, color: ColorConstants.mediumText, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
