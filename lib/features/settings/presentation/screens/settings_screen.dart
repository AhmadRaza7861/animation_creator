import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../dialogs/rate_us_dialog.dart';
import '../dialogs/contact_us_dialog.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _shareApp(BuildContext context) {
    const String shareText =
        '🎨 Check out Clipax - Animation Creator! Draw frame-by-frame animations, use 110+ brushes, stickers, and export high-quality MP4/GIFs: https://play.google.com/store/apps/details?id=com.clipax.animationcreator';
    Share.share(
      shareText,
      subject: 'Clipax Animation Creator',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: const AppBackButton(),
        title: const Text(
          'Settings',
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
            // App Banner
            _buildAppHeaderCard(),
            const SizedBox(height: 24),

            // Section 1: Support & Feedback
            _buildSectionHeader('SUPPORT & FEEDBACK'),
            const SizedBox(height: 10),
            _buildCardGroup([
              _buildSettingsTile(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFF9318),
                title: 'Rate Us',
                subtitle: 'Share your feedback & support development',
                onTap: () => RateUsDialog.show(context),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.mail_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Contact Us',
                subtitle: 'Report a bug, suggest features or ask questions',
                onTap: () => ContactUsDialog.show(context),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Share Clipax',
                subtitle: 'Invite your friends to animate and draw',
                onTap: () => _shareApp(context),
              ),
            ]),
            const SizedBox(height: 24),

            // Section 2: Legal & Privacy
            _buildSectionHeader('LEGAL & PRIVACY'),
            const SizedBox(height: 10),
            _buildCardGroup([
              _buildSettingsTile(
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Privacy Policy',
                subtitle: 'Read our offline data and privacy terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.description_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Terms of Service',
                subtitle: 'Usage guidelines and content ownership',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Clipax v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for Animation Creators',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade400,
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

  Widget _buildAppHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9318),
            Color(0xFFFF7A1A),
            Color(0xFFFF5E28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9318).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.draw_rounded,
              color: ColorConstants.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clipax Studio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '2D Animation & Frame Creator',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: ColorConstants.mediumText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorConstants.mediumText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 22),
          ],
        ),
      ),
    );
  }
}
