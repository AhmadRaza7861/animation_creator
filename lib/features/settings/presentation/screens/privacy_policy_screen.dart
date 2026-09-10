import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dialogs/contact_us_dialog.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
            // Top Badge Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.primary.withValues(alpha: 0.12),
                    const Color(0xFFFFB038).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy is Our Priority',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ColorConstants.darkText,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Clipax stores your animation projects 100% offline on your device.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ColorConstants.mediumText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              icon: Icons.folder_shared_outlined,
              iconColor: Colors.blueAccent,
              title: '1. Local Data Storage',
              content:
                  'All your animation frames, layers, custom brush configurations, and project metadata are saved directly in your device\'s local storage. We do not upload your artwork or personal drawings to external servers without your explicit intent.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.perm_media_outlined,
              iconColor: Colors.deepPurpleAccent,
              title: '2. Device Permissions',
              content:
                  'Clipax requests access to your Photos / Media library solely to import background images or export rendered MP4 videos and animated GIFs to your gallery. We do not access other media files.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.no_accounts_outlined,
              iconColor: Colors.teal,
              title: '3. Personal Information',
              content:
                  'Clipax does not require registration, login, phone numbers, or passwords. We do not collect, sell, or monetize any personal identification information.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.analytics_outlined,
              iconColor: Colors.orangeAccent,
              title: '4. Analytics & Diagnostics',
              content:
                  'Anonymous performance data and crash logs may be collected by platform frameworks (Google Play / Apple) to diagnose bugs, improve frame rendering speed, and prevent app crashes.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.child_care_rounded,
              iconColor: Colors.pinkAccent,
              title: '5. Children\'s Privacy (COPPA)',
              content:
                  'Clipax is a family-friendly creative tool suitable for creators of all ages. We do not knowingly collect personal information from children under 13.',
            ),
            const SizedBox(height: 14),

            _buildSectionCard(
              icon: Icons.update_rounded,
              iconColor: Colors.indigoAccent,
              title: '6. Policy Updates',
              content:
                  'We may update this Privacy Policy from time to time to reflect new animation features or regulatory requirements. Continued use of the app signifies acceptance of any updates.',
            ),
            const SizedBox(height: 24),

            // Contact Us Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions about our policy?',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Feel free to reach out to our privacy and developer team at any time.',
                    style: TextStyle(fontSize: 12.5, color: ColorConstants.mediumText),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => ContactUsDialog.show(context),
                      icon: const Icon(Icons.mail_outline_rounded, size: 18, color: ColorConstants.primary),
                      label: const Text(
                        'Contact Support Team',
                        style: TextStyle(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColorConstants.primary, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
