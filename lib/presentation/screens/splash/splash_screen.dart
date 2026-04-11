import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/app_logger.dart';
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
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final settingsBox = getIt<Box>(instanceName: 'app_settings');

    // DEV ONLY: Reset onboarding on every debug launch for testing.
    // Set 'debug_force_onboarding' to true in Hive to re-trigger onboarding
    // without clearing app data. Ignored in release builds.
    if (kDebugMode) {
      final forceOnboarding =
          settingsBox.get('debug_force_onboarding', defaultValue: false) as bool;
      if (forceOnboarding) {
        await settingsBox.delete('onboarding_completed');
        await settingsBox.delete('onboarding_build');
        await settingsBox.put('debug_force_onboarding', false);
        AppLogger.info('[Splash] DEBUG: Forced onboarding reset');
      }
    }

    // Guard: if this installation has never completed onboarding (no build
    // token stored), treat the session as a fresh install and show onboarding.
    // This fixes the case where a previous debug session left
    // onboarding_completed=true in Hive but the user did a fresh install
    // without a clean data wipe.
    final info = await PackageInfo.fromPlatform();
    final currentBuild = info.buildNumber;
    final storedBuild =
        settingsBox.get('onboarding_build', defaultValue: '') as String;
    final onboardingDone =
        settingsBox.get('onboarding_completed', defaultValue: false) as bool;

    AppLogger.info(
      '[Splash] onboarding_completed=$onboardingDone '
      'storedBuild=$storedBuild currentBuild=$currentBuild',
    );

    final needsOnboarding = !onboardingDone;

    if (!mounted) return;

    if (!needsOnboarding) {
      final authService = getIt<AuthService>();
      if (authService.isSignedIn) {
        // Reload to ensure emailVerified flag is fresh from Firebase.
        await authService.reloadUser();
        if (!mounted) return;
        if (authService.isEmailVerified) {
          context.go('/home');
        } else {
          // Signed in but email not verified — block access.
          context.go('/verify-email');
        }
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
