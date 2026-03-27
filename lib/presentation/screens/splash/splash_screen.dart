import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hive/hive.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/colors.dart';
import '../../widgets/safora_brand_mark.dart';
import '../../widgets/safora_animated_icons.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';

/// Animated splash screen with Safora branding.
///
/// Checks if the user has completed onboarding — navigates to
/// `/onboarding` on first launch, `/home` on subsequent launches.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Use centralized DI box instead of opening a duplicate.
    final settingsBox = getIt<Box>(instanceName: 'app_settings');
    final onboardingDone =
        settingsBox.get('onboarding_completed', defaultValue: false) as bool;

    if (!mounted) return;

    if (onboardingDone) {
      // Check if user is signed in.
      final isSignedIn = getIt<AuthService>().isSignedIn;
      if (isSignedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.sosGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield icon
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SaforaBrandMark(size: 72, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 400),
              child: Text(
                'SAFORA',
                style: AppTypography.emergencyBanner.copyWith(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 600),
              child: Text(
                l.appTagline,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Custom branded loading spinner (replaces Lottie)
            FadeIn(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 1000),
              child: const SaforaLoadingSpinner(
                size: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
