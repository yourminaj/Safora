import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';

/// 3-step onboarding: SOS Overview, Emergency Contacts, Medical Profile.
///
/// Features rich animated illustrations, entrance animations, and permission
/// requests. Sets a Hive flag when completed so splash won't show again.
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
    if (mounted) context.go('/home');
  }

  void _skip() async {
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

    final pages = [
      _OnboardingPage(
        primaryIcon: Icons.notifications_active_rounded,
        secondaryIcons: [
          Icons.location_on_rounded,
          Icons.phone_rounded,
          Icons.shield_rounded,
        ],
        title: l.onboardingTitle1,
        description: l.onboardingDesc1,
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        backgroundColor: const Color(0xFFFFF3F0),
      ),
      _OnboardingPage(
        primaryIcon: Icons.contacts_rounded,
        secondaryIcons: [
          Icons.sms_rounded,
          Icons.gps_fixed_rounded,
          Icons.group_rounded,
        ],
        title: l.onboardingTitle2,
        description: l.onboardingDesc2,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        backgroundColor: const Color(0xFFF0F7FF),
      ),
      _OnboardingPage(
        primaryIcon: Icons.medical_information_rounded,
        secondaryIcons: [
          Icons.bloodtype_rounded,
          Icons.medication_rounded,
          Icons.health_and_safety_rounded,
        ],
        title: l.onboardingTitle3,
        description: l.onboardingDesc3,
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    color: AppColors.textSecondary,
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
                        // ── Rich Illustration ────────────
                        FadeInDown(
                          key: ValueKey('illustration_$index'),
                          duration: const Duration(milliseconds: 600),
                          child: _OnboardingIllustration(page: page),
                        ),
                        const SizedBox(height: 40),
                        // ── Title ────────────────────────
                        FadeInUp(
                          key: ValueKey('title_$index'),
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            page.title,
                            style: AppTypography.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Description ──────────────────
                        FadeInUp(
                          key: ValueKey('desc_$index'),
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            page.description,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
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

// ═══════════════════════════════════════════════════════════
//  ONBOARDING ILLUSTRATION
// ═══════════════════════════════════════════════════════════

/// A rich, animated illustration widget for onboarding pages.
///
/// Features a gradient circle with the primary icon and three
/// orbiting secondary icons for visual interest.
class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
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
              color: page.backgroundColor,
            ),
          ),
          // Gradient main circle.
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: page.gradient,
              boxShadow: [
                BoxShadow(
                  color: (page.gradient as LinearGradient)
                      .colors
                      .first
                      .withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              page.primaryIcon,
              size: 64,
              color: Colors.white,
            ),
          ),
          // Orbiting secondary icons.
          ..._buildSecondaryIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildSecondaryIcons() {
    final positions = [
      const Alignment(-0.85, -0.8),  // Top-left
      const Alignment(0.9, -0.5),    // Top-right
      const Alignment(0.7, 0.85),    // Bottom-right
    ];
    final delays = [0, 200, 400];

    return List.generate(page.secondaryIcons.length, (i) {
      return Align(
        alignment: positions[i % positions.length],
        child: BounceInDown(
          delay: Duration(milliseconds: 300 + delays[i]),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              page.secondaryIcons[i],
              size: 22,
              color: (page.gradient as LinearGradient).colors.first,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE MODEL
// ═══════════════════════════════════════════════════════════

class _OnboardingPage {
  const _OnboardingPage({
    required this.primaryIcon,
    required this.secondaryIcons,
    required this.title,
    required this.description,
    required this.gradient,
    required this.backgroundColor,
  });

  final IconData primaryIcon;
  final List<IconData> secondaryIcons;
  final String title;
  final String description;
  final Gradient gradient;
  final Color backgroundColor;
}
