import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class ContactUsDialog extends StatefulWidget {
  final String supportEmail;

  const ContactUsDialog({
    super.key,
    this.supportEmail = 'support@clipax.app',
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
  final List<String> _categories = [
    'Bug Report 🐞',
    'Feature Request 💡',
    'Question ❓',
    'General Feedback 💬',
  ];

  late String _selectedCategory;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[0];
    _subjectController.text = 'Clipax Bug Report';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      _selectedCategory = cat;
      if (cat.contains('Bug')) {
        _subjectController.text = 'Clipax Bug Report';
      } else if (cat.contains('Feature')) {
        _subjectController.text = 'Clipax Feature Request';
      } else if (cat.contains('Question')) {
        _subjectController.text = 'Clipax Question & Help';
      } else {
        _subjectController.text = 'Clipax Feedback';
      }
    });
  }

  Future<void> _sendEmail() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    final String platformName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Desktop');
    final String body = '''
Hello Clipax Team,

$message

-----------------------
Category: $_selectedCategory
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
        // Fallback: copy email to clipboard
        await Clipboard.setData(ClipboardData(text: widget.supportEmail));
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Support email copied to clipboard: ${widget.supportEmail}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: ColorConstants.primary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to open email client: $e');
      await Clipboard.setData(ClipboardData(text: widget.supportEmail));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support email copied to clipboard: ${widget.supportEmail}'),
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: ColorConstants.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Us',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ColorConstants.darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'We are here to help & improve Clipax',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ColorConstants.mediumText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category Selector
              const Text(
                'Select Topic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : ColorConstants.darkText,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: ColorConstants.primary,
                    backgroundColor: const Color(0xFFF3F4F6),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? ColorConstants.primary : Colors.transparent,
                      ),
                    ),
                    onSelected: (_) => _onCategoryChanged(cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Subject Input
              const Text(
                'Subject',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _subjectController,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Enter subject...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              const SizedBox(height: 14),

              // Message Input
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Tell us your thoughts, bug details, or ideas...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.all(14),
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
              const SizedBox(height: 20),

              // Send Email Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Open Email Client',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Direct email address copy button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.supportEmail));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${widget.supportEmail} to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14, color: ColorConstants.mediumText),
                  label: Text(
                    'Copy: ${widget.supportEmail}',
                    style: const TextStyle(fontSize: 12, color: ColorConstants.mediumText, fontWeight: FontWeight.w500),
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
