import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/typography.dart';
import '../blocs/sos/sos_cubit.dart';
import '../blocs/sos/sos_state.dart';

/// Full-screen overlay shown during SOS countdown.
///
/// Displays a 30-second circular countdown with cancel option.
/// Uses [SosCubit] to manage the countdown state.
class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({super.key});

  /// Show the overlay as a modal on top of the current screen.
  static Future<void> show(BuildContext context) {
    context.read<SosCubit>().startCountdown();
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => BlocProvider.value(
        value: context.read<SosCubit>(),
        child: const CountdownOverlay(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosCancelled || state is SosActive || state is SosIdle) {
          // Close the dialog when SOS is cancelled, active, or reset.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        // Haptic feedback on each tick.
        if (state is SosCountdown) {
          HapticFeedback.lightImpact();
          if (state.secondsRemaining <= 5) {
            HapticFeedback.heavyImpact();
          }
        }
      },
      builder: (context, state) {
        if (state is! SosCountdown) {
          return const SizedBox.shrink();
        }

        return PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFF880E4F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Warning text ───────────────
                    Text(
                      '🚨 SOS ALERT',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency alert will be sent in',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ─── Circular countdown ─────────
                    _CircularCountdown(
                      secondsRemaining: state.secondsRemaining,
                      progress: state.progress,
                    ),

                    const SizedBox(height: 40),

                    // ─── Info text ───────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your emergency contacts will receive an SMS with your GPS location.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ─── Cancel button ───────────────
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<SosCubit>().cancelCountdown();
                      },
                      icon: const Icon(Icons.close_rounded, size: 24),
                      label: Text(
                        'CANCEL',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Circular countdown timer widget.
class _CircularCountdown extends StatelessWidget {
  const _CircularCountdown({
    required this.secondsRemaining,
    required this.progress,
  });

  final int secondsRemaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: const Size(200, 200),
            painter: _CountdownPainter(progress: progress),
          ),
          // Number
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondsRemaining',
                style: AppTypography.sosCountdown.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                'seconds',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular countdown arc.
class _CountdownPainter extends CustomPainter {
  _CountdownPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
