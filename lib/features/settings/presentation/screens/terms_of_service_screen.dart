import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, accessing, or using Clipax Animation Creator, you agree to be bound by these Terms of Service. If you do not agree, please discontinue use of the application.',
            ),
            _buildSection(
              '2. Intellectual Property & Artwork Ownership',
              'You retain 100% full ownership, copyright, and intellectual property rights to all original drawings, animations, and exported media created with Clipax. Clipax claims no ownership over user-generated content.',
            ),
            _buildSection(
              '3. App License & Usage',
              'Clipax grants you a personal, non-exclusive, non-transferable license to use the app for personal and commercial animation creation in compliance with these terms.',
            ),
            _buildSection(
              '4. Exporting & Distribution',
              'You are free to share, publish, monetize, and distribute any MP4 videos or GIF animations you create using Clipax on social platforms (YouTube, TikTok, Instagram, etc.).',
            ),
            _buildSection(
              '5. Disclaimer of Warranties',
              'Clipax is provided "as is" without warranty of any kind. While we strive to maintain complete reliability and high performance, we recommend backing up critical export files regularly.',
            ),
            _buildSection(
              '6. Contact Information',
              'For any legal, license, or support questions regarding these terms, please contact us at support@clipax.app.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ColorConstants.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
