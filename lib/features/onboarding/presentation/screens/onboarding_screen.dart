import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/data/project_repository.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../../data/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final ProjectRepository repository;

  const OnboardingScreen({super.key, required this.repository});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.markOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectsScreen(repository: widget.repository),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF2DA)],
              //  stops: [0.0, 0.35, 0.72, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Main Page Content Carousel
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildScreen1(size),
                      _buildScreen2(size),
                      _buildScreen3(size),
                    ],
                  ),
                ),

                // Bottom Indicator & Navigation Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 10),
                  child: _buildDotIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1: Welcome & Pumpkin
  // ---------------------------------------------------------------------------
  Widget _buildScreen1(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Title
          Text(
            context.tr('onboardWelcome'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF8A00),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            context.tr('onboardWelcomeDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A4E5D),
              height: 1.45,
            ),
          ),

          const Spacer(flex: 3),

          // Pumpkin Artwork
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.38,
              maxWidth: 260,
            ),
            child: Image.asset(
              AssetConstants.onboard_pumpkin,
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2: Flip Your Frames & Running Mouse
  // ---------------------------------------------------------------------------
  Widget _buildScreen2(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Running Character Landscape Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.35,
                maxWidth: 340,
              ),
              child: Image.asset(
                AssetConstants.onboard_mouse,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Title
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.tr('onboardFlipYour')} ',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E24),
                    letterSpacing: -0.4,
                  ),
                ),
                TextSpan(
                  text: context.tr('onboardFrames'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF8A00),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            context.tr('onboardFlipDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 3: Ready To Animate & Blooming Cactus
  // ---------------------------------------------------------------------------
  Widget _buildScreen3(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Cactus Plant Artwork
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.35,
              maxWidth: 260,
            ),
            child: Image.asset(
              AssetConstants.onboard_cactus,
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(flex: 2),

          // Title
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.tr('onboardReadyTo')} ',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E24),
                    letterSpacing: -0.4,
                  ),
                ),
                TextSpan(
                  text: context.tr('onboardAnimate'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF8A00),
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            context.tr('onboardReadyDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // "Start Drawing" Action Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 46,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                context.tr('startDrawing'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dot Page Indicator
  // ---------------------------------------------------------------------------
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final bool isSelected = _currentPage == index;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFF8A00)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A00)
                      : const Color(0xFFFF8A00).withValues(alpha: 0.7),
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
