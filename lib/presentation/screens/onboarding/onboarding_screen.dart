import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';
import '../../widgets/safora_animated_icons.dart';

/// 3-step onboarding: SOS Overview, Emergency Contacts, Medical Profile.
///
/// Features custom animated Safora-branded illustrations, entrance
/// animations, and permission requests. Sets a Hive flag when completed
/// so splash won't show again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _nextPage() async {
    if (_currentPage < 2) {
      if (_currentPage == 0) {
        await _requestLocationPermission();
      } else if (_currentPage == 1) {
        await _requestNotificationPermission();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.locationNeededSnack)),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.notificationsNeededSnack)),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final settingsBox = getIt<Box>(instanceName: 'app_settings');
    await settingsBox.put('onboarding_completed', true);
    // Always route to login after onboarding — auth state determines
    // whether the user is taken to /home or /verify-email.
    if (mounted) context.go('/login');
  }

  Future<void> _skip() async {
    await _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OnboardingPage(
        iconBuilder: (size) => SaforaSosIcon(size: size, animated: true),
        title: l.onboardingTitle1,
        description: l.onboardingDesc1,
        backgroundColor: const Color(0xFFFFF3F0),
      ),
      _OnboardingPage(
        iconBuilder: (size) => SaforaContactsIcon(size: size, animated: true),
        title: l.onboardingTitle2,
        description: l.onboardingDesc2,
        backgroundColor: const Color(0xFFF0F7FF),
      ),
      _OnboardingPage(
        iconBuilder: (size) => SaforaMedicalIcon(size: size, animated: true),
        title: l.onboardingTitle3,
        description: l.onboardingDesc3,
        backgroundColor: const Color(0xFFF0FFF0),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button.
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l.skip,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.textDisabled : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Page view.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom Branded Illustration
                        FadeInDown(
                          key: ValueKey('illustration_$index'),
                          duration: const Duration(milliseconds: 600),
                          child: _OnboardingIllustration(page: page),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        FadeInUp(
                          key: ValueKey('title_$index'),
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            page.title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: isDark ? AppColors.darkOnSurface : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        FadeInUp(
                          key: ValueKey('desc_$index'),
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            page.description,
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark ? AppColors.textDisabled : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicators + Next button.
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated dots.
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next/Get Started button.
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1
                          ? l.getStarted
                          : l.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Onboarding illustration - custom animated icon on background circle
class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    // Determine background based on theme mode to ensure visibility
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow.
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark 
                   ? page.backgroundColor.withValues(alpha: 0.15) 
                   : page.backgroundColor,
            ),
          ),
          // Custom animated icon (no Lottie).
          page.iconBuilder(140),
        ],
      ),
    );
  }
}

// Page model
class _OnboardingPage {
  const _OnboardingPage({
    required this.iconBuilder,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });

  final Widget Function(double size) iconBuilder;
  final String title;
  final String description;
  final Color backgroundColor;
}
