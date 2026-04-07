import 'package:safora/presentation/widgets/safora_toast.dart';
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
/// Features custom animated Safora-branded illustrations with orbiting
/// satellite icons, entrance animations, and permission requests.
/// Sets a Hive flag when completed so splash won't show again.
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
        SaforaToast.showInfo(context, l.locationNeededSnack);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  Future<void> _completeOnboarding() async {
    final box = getIt<Box>(instanceName: 'app_settings');
    await box.put('onboarding_completed', true);
    if (mounted) {
      context.go('/home');
    }
  }

  List<_OnboardingPage> get _pages {
    final l = AppLocalizations.of(context)!;
    return [
      _OnboardingPage(
        iconBuilder: (size) => SaforaShieldPulse(size: size, animated: true),
        secondaryIcons: [Icons.security, Icons.location_on, Icons.notifications],
        title: l.onboardingTitle1,
        description: l.onboardingDesc1,
        gradient: AppColors.primaryGradient,
        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
      ),
      _OnboardingPage(
        iconBuilder: (size) => SaforaContactsIcon(size: size, animated: true),
        secondaryIcons: [Icons.people, Icons.message, Icons.call],
        title: l.onboardingTitle2,
        description: l.onboardingDesc2,
        gradient: AppColors.secondaryGradient,
        backgroundColor: AppColors.secondary.withValues(alpha: 0.05),
      ),
      _OnboardingPage(
        iconBuilder: (size) => SaforaMedicalIcon(size: size, animated: true),
        secondaryIcons: [Icons.medical_services, Icons.bloodtype, Icons.history],
        title: l.onboardingTitle3,
        description: l.onboardingDesc3,
        gradient: AppColors.errorGradient,
        backgroundColor: AppColors.danger.withValues(alpha: 0.05),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = _pages;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: pages.length,
            itemBuilder: (ctx, idx) {
              final page = pages[idx];
              return Container(
                color: page.backgroundColor,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: page.iconBuilder(150),
                    ),
                    const SizedBox(height: 60),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        page.title,
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        page.description,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == idx ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == idx
                            ? AppColors.primary
                            : AppColors.textDisabled.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1 ? l.getStarted : l.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l.skip,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE MODEL
// ═══════════════════════════════════════════════════════════

class _OnboardingPage {
  const _OnboardingPage({
    required this.iconBuilder,
    required this.secondaryIcons,
    required this.title,
    required this.description,
    required this.gradient,
    required this.backgroundColor,
  });

  /// Builder for the custom animated center icon (SaforaSosIcon, etc.).
  final Widget Function(double size) iconBuilder;

  /// 3 contextual satellite icons orbiting the main circle.
  final List<IconData> secondaryIcons;

  final String title;
  final String description;

  /// Gradient fill for the main circle.
  final Gradient gradient;

  /// Light background tint for the glow area.
  final Color backgroundColor;
}
