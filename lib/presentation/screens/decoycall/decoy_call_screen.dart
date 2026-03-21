import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/decoy_call_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';
import 'in_call_screen.dart';

/// Full-screen incoming call UI mimicking a real phone call.
///
/// This is a decoy call feature — helps users discreetly exit
/// uncomfortable or dangerous situations by simulating an incoming call.
class DecoyCallScreen extends StatefulWidget {
  const DecoyCallScreen({super.key});

  @override
  State<DecoyCallScreen> createState() => _DecoyCallScreenState();
}

class _DecoyCallScreenState extends State<DecoyCallScreen>
    with SingleTickerProviderStateMixin {
  late final DecoyCallService _decoyCallService;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _decoyCallService = getIt<DecoyCallService>();
    _decoyCallService.startRinging();

    // Vibrate on incoming call.
    HapticFeedback.heavyImpact();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _decoyCallService.stopRinging();
    super.dispose();
  }

  void _answerCall() {
    _decoyCallService.stopRinging();
    // Use GoRouter-compatible navigation: replace current route
    // so the user can't swipe back to the ringing screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            InCallScreen(callerName: _decoyCallService.callerName),
      ),
    );
  }

  void _declineCall() {
    _decoyCallService.stopRinging();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = _decoyCallService.callerName;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Caller avatar with pulse effect.
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.08;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    callerName.isNotEmpty
                        ? callerName[0].toUpperCase()
                        : '?',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Caller name.
            Text(
              callerName,
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Incoming call...',
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

            const Spacer(flex: 3),

            // Answer / Decline buttons.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline.
                  _CallButton(
                    icon: Icons.call_end_rounded,
                    color: AppColors.danger,
                    label: 'Decline',
                    onTap: _declineCall,
                  ),
                  // Answer.
                  _CallButton(
                    icon: Icons.call_rounded,
                    color: AppColors.safe,
                    label: 'Answer',
                    onTap: _answerCall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
