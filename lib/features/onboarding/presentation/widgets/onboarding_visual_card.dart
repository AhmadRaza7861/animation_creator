import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';

/// Base frame container providing an elegant studio canvas aesthetic
/// with rounded corners, subtle border, inner grid backdrop, and soft ambient shadow.
class OnboardingCardContainer extends StatelessWidget {
  final Widget child;
  final double maxHeight;

  const OnboardingCardContainer({
    super.key,
    required this.child,
    this.maxHeight = 340,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: ColorConstants.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft studio ambient lighting
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      const Color(0xFFFFFDF8),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle dot pattern background simulating the animation drawing lightbox
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  dotColor: const Color(0xFFCBD5E1).withValues(alpha: 0.35),
                  spacing: 18.0,
                  radius: 1.0,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 1 VISUAL: Turn Your Drawings Into Animation (Anime 4-Pose Keyframe)
// =============================================================================
class OnboardingScreen1Visual extends StatelessWidget {
  const OnboardingScreen1Visual({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCardContainer(
      child: Stack(
        children: [
          // Hero Anime Character 4-Frame Jump Breakdown
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 54),
              child: Image.asset(
                AssetConstants.onboardStep1Filmstrip,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // Top Left Badge: Frame-by-Frame
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: ColorConstants.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('onboardFrameByFrame'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.darkText,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Badge: 12 FPS
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ColorConstants.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 13,
                    color: ColorConstants.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('fpsPreviewBadge'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Timeline Strip
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_creation_rounded,
                      size: 14,
                      color: ColorConstants.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TIMELINE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildTimelineFramePill('1', isActive: false),
                    const SizedBox(width: 5),
                    _buildTimelineFramePill('2', isActive: false),
                    const SizedBox(width: 5),
                    _buildTimelineFramePill('3', isActive: true),
                    const SizedBox(width: 5),
                    _buildTimelineFramePill('4', isActive: false),
                    const SizedBox(width: 5),
                    _buildTimelineFramePill('5', isActive: false),
                    const SizedBox(width: 5),
                    _buildTimelineFramePill('6', isActive: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineFramePill(String number, {required bool isActive}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isActive ? ColorConstants.primary : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xFFFFA940) : const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 2 VISUAL: Create Every Detail (Anime Character Inking & Coloring)
// =============================================================================
class OnboardingScreen2Visual extends StatelessWidget {
  const OnboardingScreen2Visual({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCardContainer(
      child: Stack(
        children: [
          // Center Anime Character Split: Line-art Sketch to Cel-Shaded Render
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 42, 16, 64),
              child: Image.asset(
                AssetConstants.onboardStep2Drawing,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // Top Left: Color Palette Swatches
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorDot(ColorConstants.primary, isSelected: true),
                  _buildColorDot(const Color(0xFF0F172A)),
                  _buildColorDot(const Color(0xFF0EA5E9)),
                  _buildColorDot(const Color(0xFFEC4899)),
                  _buildColorDot(const Color(0xFF10B981)),
                ],
              ),
            ),
          ),

          // Top Right: Brush Indicator
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ColorConstants.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AssetConstants.brush_icon,
                    width: 13,
                    height: 13,
                    colorFilter: const ColorFilter.mode(
                      ColorConstants.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${context.tr('brush')} • 10px',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.darkText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Verified Tools Bar
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToolItem(
                      label: context.tr('brush'),
                      svgAsset: AssetConstants.brush_icon,
                      isSelected: true,
                    ),
                    _buildToolItem(
                      label: context.tr('eraser'),
                      svgAsset: AssetConstants.erase_icon,
                      isSelected: false,
                    ),
                    _buildToolItem(
                      label: context.tr('fill'),
                      svgAsset: AssetConstants.paint_icon,
                      isSelected: false,
                    ),
                    _buildToolItem(
                      label: context.tr('lasso'),
                      svgAsset: AssetConstants.lesso_icon,
                      isSelected: false,
                    ),
                    _buildToolItem(
                      label: context.tr('shapes'),
                      svgAsset: AssetConstants.shapes_icon,
                      isSelected: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        width: isSelected ? 17 : 14,
        height: isSelected ? 17 : 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required String label,
    required String svgAsset,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? ColorConstants.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 17,
            height: 17,
            colorFilter: ColorFilter.mode(
              isSelected ? ColorConstants.primary : const Color(0xFF64748B),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? ColorConstants.primary : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 3 VISUAL: Make Every Frame Count (Anime Action Onion Skinning)
// =============================================================================
class OnboardingScreen3Visual extends StatelessWidget {
  const OnboardingScreen3Visual({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCardContainer(
      child: Stack(
        children: [
          // Center Anime Character Jump with Multi-Colored Onion Skin Ghost Trails
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 42, 16, 64),
              child: Image.asset(
                AssetConstants.onboardStep3Timeline,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // Top Left Badge: Onion Skin ON
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('onionSkinBadge'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Badge: 4 Keyframes
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ColorConstants.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                context.tr('onboardKeyframes'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bottom Timeline Filmstrip Controller
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play Button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ColorConstants.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildFrameThumbnail('1', isSelected: false),
                    const SizedBox(width: 6),
                    _buildFrameThumbnail('2', isSelected: true),
                    const SizedBox(width: 6),
                    _buildFrameThumbnail('3', isSelected: false),
                    const SizedBox(width: 6),
                    _buildFrameThumbnail('4', isSelected: false),
                    const SizedBox(width: 6),
                    // Add Frame Button
                    Container(
                      width: 28,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameThumbnail(String frameNumber, {required bool isSelected}) {
    return Container(
      width: 28,
      height: 34,
      decoration: BoxDecoration(
        color: isSelected ? ColorConstants.primaryLight : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? ColorConstants.primary : const Color(0xFFCBD5E1),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Center(
        child: Text(
          frameNumber,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? ColorConstants.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 4 VISUAL: Your Animation, Your Way (Anime Showcase & Export)
// =============================================================================
class OnboardingScreen4Visual extends StatelessWidget {
  const OnboardingScreen4Visual({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingCardContainer(
      child: Stack(
        children: [
          // Center Anime Artist Girl Celebrating with Tablet & Stars
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 68),
              child: Image.asset(
                AssetConstants.onboardStep4Export,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          // Top Left Badge: Auto-Saved Offline
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.tr('onboardAutoSavedOffline'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Badge: Ready to Share
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: ColorConstants.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: ColorConstants.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    context.tr('onboardReadyToShare'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Verified Export Formats (MP4 & GIF)
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildExportBadge(
                    icon: Icons.movie_rounded,
                    title: context.tr('mp4FormatBadge'),
                    subtitle: context.tr('mp4FormatDesc'),
                    isPrimary: true,
                  ),
                  const SizedBox(width: 10),
                  _buildExportBadge(
                    icon: Icons.gif_box_rounded,
                    title: context.tr('gifFormatBadge'),
                    subtitle: context.tr('gifFormatDesc'),
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? ColorConstants.primary.withValues(alpha: 0.45)
              : const Color(0xFFCBD5E1),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? ColorConstants.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPrimary ? ColorConstants.primaryLight : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isPrimary ? ColorConstants.primary : ColorConstants.darkText,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.darkText,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.mediumText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Custom Painters for Studio Aesthetics
// =============================================================================

/// Draws fine dot grid mimicking animation lightbox paper
class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double radius;

  _DotGridPainter({
    required this.dotColor,
    required this.spacing,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
