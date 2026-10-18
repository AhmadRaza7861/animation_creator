import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../projects/data/project_repository.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/onboarding_service.dart';
import '../widgets/onboarding_visual_card.dart';

class OnboardingScreen extends StatefulWidget {
  final ProjectRepository repository;

  const OnboardingScreen({super.key, required this.repository});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'OnboardingScreen');
    AnalyticsService.instance.logOnboardingStart();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
      AnalyticsService.instance.logOnboardingStep(
        stepIndex: page,
        stepTitle: 'Step ${page + 1}',
      );
    }
  }

  void _onNextPressed() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onBackPressed() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _skipOnboarding() async {
    AnalyticsService.instance.logOnboardingSkip(atStepIndex: _currentPage);
    await _completeOnboarding(isSkip: true);
  }

  Future<void> _completeOnboarding({bool isSkip = false}) async {
    if (_isCompleting) return;
    _isCompleting = true;
    HapticFeedback.mediumImpact();

    if (!isSkip) {
      AnalyticsService.instance.logOnboardingComplete();
    }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: _currentPage == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentPage > 0) {
            _onBackPressed();
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFCFDFE),
                  Color(0xFFFFF7ED),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Soft atmospheric studio warmth glow
                Positioned(
                  top: -40,
                  right: -30,
                  width: 240,
                  height: 240,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ColorConstants.primary.withValues(alpha: 0.07),
                            ColorConstants.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: -40,
                  width: 220,
                  height: 220,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFA940).withValues(alpha: 0.06),
                            const Color(0xFFFFA940).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Top Navigation Header (Skip button)
                      _buildTopBar(),

                  // 4-Screen PageView Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPage(
                          visual: const OnboardingScreen1Visual(),
                          headline: context.tr('onboardTitle1'),
                          description: context.tr('onboardDesc1'),
                          highlightKeyword: 'Animation',
                        ),
                        _buildPage(
                          visual: const OnboardingScreen2Visual(),
                          headline: context.tr('onboardTitle2'),
                          description: context.tr('onboardDesc2'),
                          highlightKeyword: 'Detail',
                        ),
                        _buildPage(
                          visual: const OnboardingScreen3Visual(),
                          headline: context.tr('onboardTitle3'),
                          description: context.tr('onboardDesc3'),
                          highlightKeyword: 'Count',
                        ),
                        _buildPage(
                          visual: const OnboardingScreen4Visual(),
                          headline: context.tr('onboardTitle4'),
                          description: context.tr('onboardDesc4'),
                          highlightKeyword: 'Way',
                        ),
                      ],
                    ),
                  ),

                  // Bottom Controls (Page Indicator & Action Button)
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  // ---------------------------------------------------------------------------
  // Top Header Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Skip Button
            AnimatedOpacity(
              opacity: _currentPage < 3 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _currentPage >= 3,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.mediumText,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tr('skip'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.mediumText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Item Builder
  // ---------------------------------------------------------------------------
  Widget _buildPage({
    required Widget visual,
    required String headline,
    required String description,
    required String highlightKeyword,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxHeight < 580;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isCompact ? 4 : 12),

              // Visual Artwork Card with studio canvas aesthetic
              Expanded(
                flex: isCompact ? 10 : 12,
                child: Center(
                  child: visual,
                ),
              ),

              SizedBox(height: isCompact ? 14 : 24),

              // Headline with keyword highlight
              _buildStyledHeadline(headline, highlightKeyword, isCompact),

              SizedBox(height: isCompact ? 8 : 12),

              // Description Text
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 13.5 : 15.0,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.mediumText,
                    height: 1.45,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              SizedBox(height: isCompact ? 10 : 20),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Styled Headline with Vibrant Highlight Accent
  // ---------------------------------------------------------------------------
  Widget _buildStyledHeadline(String text, String highlightKeyword, bool isCompact) {
    final double fontSize = isCompact ? 22 : 26;

    if (!text.contains(highlightKeyword)) {
      final int lastSpace = text.lastIndexOf(' ');
      if (lastSpace != -1 && lastSpace < text.length - 1) {
        final String before = text.substring(0, lastSpace + 1);
        final String lastWord = text.substring(lastSpace + 1);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: before,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: lastWord,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: ColorConstants.darkText,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        );
      }
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: ColorConstants.darkText,
          letterSpacing: -0.5,
          height: 1.25,
        ),
      );
    }

    final int index = text.indexOf(highlightKeyword);
    final String before = text.substring(0, index);
    final String match = text.substring(index, index + highlightKeyword.length);
    final String after = text.substring(index + highlightKeyword.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: before,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: ColorConstants.darkText,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: match,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: ColorConstants.primary,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: after,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: ColorConstants.darkText,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Controls: Animated Pill Indicator & Continue / Get Started Button
  // ---------------------------------------------------------------------------
  Widget _buildBottomControls() {
    final bool isLastPage = _currentPage == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Page Dot / Pill Indicator
          _buildPageIndicator(),

          const SizedBox(height: 20),

          // Primary Navigation Button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFA940),
                  ColorConstants.primary,
                  Color(0xFFFF8500),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primary.withValues(alpha: 0.38),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onNextPressed,
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.white.withValues(alpha: 0.25),
                highlightColor: Colors.white.withValues(alpha: 0.15),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Text(
                      isLastPage
                          ? context.tr('getStarted')
                          : context.tr('continueBtn'),
                      key: ValueKey<bool>(isLastPage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Smooth Animated Page Indicator (Continuous real-time interpolation on drag)
  // ---------------------------------------------------------------------------
  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        double page = _currentPage.toDouble();
        if (_pageController.hasClients && _pageController.position.hasContentDimensions) {
          page = _pageController.page ?? _currentPage.toDouble();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            // Continuous distance between this dot and the scroll position
            final double distance = (page - index).abs();
            // Active factor smoothly drops from 1.0 down to 0.0 as distance increases
            final double factor = (1.0 - distance).clamp(0.0, 1.0);

            // Dynamically interpolate width: 8.0 (inactive dot) -> 26.0 (active pill)
            final double width = 8.0 + (18.0 * factor);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Container(
                  width: width,
                  height: 8.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: factor > 0.02
                        ? LinearGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xFFE2E8F0),
                                const Color(0xFFFFA940),
                                factor,
                              )!,
                              Color.lerp(
                                const Color(0xFFE2E8F0),
                                ColorConstants.primary,
                                factor,
                              )!,
                            ],
                          )
                        : null,
                    color: factor <= 0.02 ? const Color(0xFFE2E8F0) : null,
                    boxShadow: factor > 0.08
                        ? [
                            BoxShadow(
                              color: ColorConstants.primary.withValues(
                                alpha: 0.35 * factor,
                              ),
                              blurRadius: 6 * factor,
                              offset: Offset(0, 2 * factor),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
