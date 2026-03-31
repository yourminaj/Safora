import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    final info = await PackageInfo.fromPlatform();
    await settingsBox.put('onboarding_completed', true);
    await settingsBox.put('onboarding_build', info.buildNumber);
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

    final pages = [
      _OnboardingPage(
        iconBuilder: (size) => SaforaSosIcon(size: size, animated: true),
        secondaryIcons: const [
          Icons.location_on_rounded,
          Icons.phone_in_talk_rounded,
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
        iconBuilder: (size) => SaforaContactsIcon(size: size, animated: true),
        secondaryIcons: const [
          Icons.sms_rounded,
          Icons.gps_fixed_rounded,
          Icons.group_add_rounded,
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
        iconBuilder: (size) => SaforaMedicalIcon(size: size, animated: true),
        secondaryIcons: const [
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

    // Current page's gradient primary for color-matched indicators.
    final activePrimary =
        (pages[_currentPage].gradient as LinearGradient).colors.first;

    return Scaffold(
      // ── FIX 2: Animated background tint ──
      // Cross-fades between warm pink → cool blue → soft green as user swipes.
      backgroundColor: pages[_currentPage].backgroundColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        color: pages[_currentPage].backgroundColor,
        child: SafeArea(
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
                          // Branded illustration with satellite icons.
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
                              style: AppTypography.headlineMedium,
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
              // ── FIX 3: Color-matched page indicators ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Animated dots — active dot matches current page gradient.
                    Row(
                      children: List.generate(
                        pages.length,
                        (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? activePrimary
                                  : activePrimary.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: activePrimary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    // Next/Get Started button.
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activePrimary,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ONBOARDING ILLUSTRATION
//  Gradient circle + custom painter + 3 orbiting satellite
//  icons with staggered entrance & gentle floating bob.
// ═══════════════════════════════════════════════════════════

class _OnboardingIllustration extends StatefulWidget {
  const _OnboardingIllustration({required this.page});

  final _OnboardingPage page;

  @override
  State<_OnboardingIllustration> createState() =>
      _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<_OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final gradientColors = (page.gradient as LinearGradient).colors;
    final primaryColor = gradientColors.first;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Pulsing glow ring.
              CustomPaint(
                size: const Size(280, 280),
                painter: _GlowRingPainter(
                  progress: t,
                  glowColor: primaryColor,
                ),
              ),
              // Layer 2: Gradient main circle with glassmorphism.
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: page.gradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(
                          alpha: 0.25 + 0.10 * _sin01(t)),
                      blurRadius: 28 + 8 * _sin01(t),
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Layer 3: Custom animated center icon.
              page.iconBuilder(130),
              // Layer 4: 3 orbiting satellite icons.
              ..._buildSatelliteIcons(t, primaryColor),
            ],
          ),
        );
      },
    );
  }

  /// Builds the 3 satellite icon widgets positioned around the main circle.
  ///
  /// Each satellite:
  ///  - Is a 46px white circle with a colored border ring
  ///  - Contains a 22px icon matching the gradient primary color
  ///  - Has a gentle Y-axis floating bob (3px amplitude, phase-offset)
  ///  - Enters with BounceInDown (staggered 300ms, 500ms, 700ms)
  List<Widget> _buildSatelliteIcons(double t, Color primaryColor) {
    final page = widget.page;

    // Fixed orbital positions (angles in radians from center).
    // Top-left, top-right, bottom-right — evenly spaced, visually balanced.
    const positions = [
      _SatellitePosition(-0.82, -0.78), // Top-left
      _SatellitePosition(0.88, -0.50), // Top-right
      _SatellitePosition(0.68, 0.82), // Bottom-right
    ];
    const entranceDelays = [300, 500, 700];

    return List.generate(
      math.min(page.secondaryIcons.length, 3),
      (i) {
        // Gentle floating bob: 3px Y amplitude, each satellite phase-offset.
        final bobOffset = 3.0 * math.sin(2 * math.pi * t + i * 2.1);

        return Align(
          alignment: Alignment(positions[i].x, positions[i].y),
          child: Transform.translate(
            offset: Offset(0, bobOffset),
            child: BounceInDown(
              delay: Duration(milliseconds: entranceDelays[i]),
              duration: const Duration(milliseconds: 800),
              child: _SatelliteBubble(
                icon: page.secondaryIcons[i],
                color: primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  static double _sin01(double t) =>
      (0.5 + 0.5 * math.sin(2 * math.pi * t));
}

// ═══════════════════════════════════════════════════════════
//  SATELLITE BUBBLE
//  A white circle with colored border ring + icon inside.
// ═══════════════════════════════════════════════════════════

class _SatelliteBubble extends StatelessWidget {
  const _SatelliteBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // ── FIX 4: Enhanced satellite bubbles ──
    // 50px with radial gradient depth, inner glow ring, and premium shadows.
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        // Radial gradient: white center → subtle color tint at edges.
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.06),
          ],
        ),
        shape: BoxShape.circle,
        // Dual-layer border: inner glow ring + outer colored ring.
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 1.8,
        ),
        boxShadow: [
          // Primary colored shadow — gives the bubble a lifted, branded feel.
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          // Ambient shadow — subtle depth grounding.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          // Inner glow — faint inner radiance for glassmorphism depth.
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.70),
          ],
        ).createShader(bounds),
        child: Icon(
          icon,
          size: 24,
          color: Colors.white, // ShaderMask applies the gradient over white.
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  GLOW RING PAINTER
//  Soft animated gradient ring that pulses around the circle.
// ═══════════════════════════════════════════════════════════

class _GlowRingPainter extends CustomPainter {
  const _GlowRingPainter({required this.progress, required this.glowColor});
  final double progress;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseRadius = size.width * 0.44;
    final pulse = baseRadius + 3 * math.sin(progress * 2 * math.pi);

    // Outer glow ring.
    canvas.drawCircle(
      Offset(cx, cy),
      pulse,
      Paint()
        ..color = glowColor.withValues(
            alpha: 0.10 + 0.06 * math.sin(progress * 2 * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Inner subtle ring.
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius - 8,
      Paint()
        ..color = glowColor.withValues(
            alpha: 0.05 + 0.03 * math.sin(progress * 2 * math.pi + 1.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
//  SATELLITE POSITION
// ═══════════════════════════════════════════════════════════

class _SatellitePosition {
  const _SatellitePosition(this.x, this.y);
  final double x;
  final double y;
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
