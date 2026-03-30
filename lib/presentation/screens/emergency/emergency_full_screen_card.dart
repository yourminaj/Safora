import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/services/sms_service.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../data/models/alert_event.dart';
import '../../../services/risk_score_engine.dart';
import '../shell/main_shell.dart' show SaforaAnimatedBuilder;

/// Full-screen emergency takeover card.
///
/// Displayed on critical-priority alerts (riskScore ≥ 80).
/// Shows: risk type, severity, confidence, actionable advice,
/// distance, and a large "I Am Safe" button.
///
/// The card has a pulsing red background and cannot be dismissed
/// without user action (confirming safety or calling emergency).
class EmergencyFullScreenCard extends StatefulWidget {
  const EmergencyFullScreenCard({super.key, required this.alert});

  final AlertEvent alert;

  /// Push this screen as a full-screen modal.
  static Future<bool?> show(BuildContext context, AlertEvent alert) {
    // Force portrait, full immersive for maximum urgency.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, _, _) => EmergencyFullScreenCard(alert: alert),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<EmergencyFullScreenCard> createState() =>
      _EmergencyFullScreenCardState();
}

class _EmergencyFullScreenCardState extends State<EmergencyFullScreenCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Restore system UI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final score = alert.riskScore ?? 0;
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // Prevent back button dismiss.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SaforaAnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Container(
              width: screenSize.width,
              height: screenSize.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFFB91C1C),
                      const Color(0xFFEF4444),
                      _pulseAnimation.value,
                    )!,
                    const Color(0xFF1A0505),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'RISK SCORE: $score',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          RiskScoreEngine.scoreLabel(score).toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        alert.title,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      if (alert.description != null)
                        Text(
                          alert.description!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 24),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (alert.distanceKm != null)
                            _InfoChip(
                              icon: Icons.near_me_rounded,
                              text:
                                  '${alert.distanceKm!.toStringAsFixed(1)} km',
                            ),
                          _InfoChip(
                            icon: Icons.verified_rounded,
                            text: alert.confidenceLabel,
                          ),
                          if (alert.expiresAt != null)
                            _InfoChip(
                              icon: Icons.timer_rounded,
                              text: _formatExpiry(alert.expiresAt!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      if (alert.actionAdvice != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RECOMMENDED ACTION',
                                    style:
                                        AppTypography.labelSmall.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alert.actionAdvice!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // Send "I Am Safe" SMS to all emergency contacts.
                            final contacts = GetIt.instance<ContactsRepository>().getAll();
                            if (contacts.isNotEmpty) {
                              GetIt.instance<SmsService>().sendIAmSafeSms(
                                contacts: contacts,
                              );
                            }
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safe,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'I AM SAFE',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Launch the default emergency number.
                            final uri = Uri.parse('tel:999');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop(false);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'CALL EMERGENCY',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}m remaining';
    if (remaining.inHours < 24) return '${remaining.inHours}h remaining';
    return '${remaining.inDays}d remaining';
  }
}

/// Frosted glass info chip used inside the emergency card.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                text,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

