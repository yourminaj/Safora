import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../core/theme/colors.dart';
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
    final cubit = context.read<SosCubit>();
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) {
        // Start countdown AFTER the dialog is mounted so listeners
        // are active when SosPreparing/SosPreflightFailed emit.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.startCountdown();
        });
        return BlocProvider.value(
          value: cubit,
          child: const CountdownOverlay(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosCancelled || state is SosActive || state is SosIdle) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        // Close dialog and show error when pre-flight fails.
        if (state is SosPreflightFailed) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          // Show error in the parent context's scaffold.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_localizeFailureReason(context, state.reason)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
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
        // Show pre-flight checklist while preparing.
        if (state is SosPreparing) {
          return PopScope(
            canPop: false,
            child: Dialog.fullscreen(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ↓ localized
                      Text(
                        l.sosPreparingTitle,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.sosPreflightChecks,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Pre-flight checklist
                      _PreflightCheckItem(
                        label: l.preflightGps,
                        ready: state.gpsReady,
                      ),
                      const SizedBox(height: 12),
                      _PreflightCheckItem(
                        label: l.preflightNetwork,
                        ready: state.networkReady,
                      ),
                      const SizedBox(height: 12),
                      _PreflightCheckItem(
                        label: l.preflightContacts,
                        ready: state.contactsReady,
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

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
                    Text(
                      l.sosAlertTitle,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.emergencyAlertWillBeSent,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 40),

                    _CircularCountdown(
                      secondsRemaining: state.secondsRemaining,
                      progress: state.progress,
                      secondsLabel: l.seconds,
                    ),

                    const SizedBox(height: 40),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l.sosContactsWillReceiveSms,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<SosCubit>().cancelCountdown();
                      },
                      icon: const Icon(Icons.close_rounded, size: 24),
                      label: Text(
                        l.cancel.toUpperCase(),
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

  /// Map [SosFailureReason] enum to a localized string at display time.
  static String _localizeFailureReason(
    BuildContext context,
    SosFailureReason reason,
  ) {
    final l = AppLocalizations.of(context)!;
    return switch (reason) {
      SosFailureReason.noContacts => l.preflightNoContacts,
      SosFailureReason.noGps => l.preflightNoGps,
      SosFailureReason.noNetwork => l.preflightNoNetwork,
      SosFailureReason.smsPermissionDenied =>
        'SMS permission required. Please grant it in Settings to send SOS alerts.',
    };
  }
}

/// Circular countdown timer widget.
class _CircularCountdown extends StatelessWidget {
  const _CircularCountdown({
    required this.secondsRemaining,
    required this.progress,
    required this.secondsLabel,
  });

  final int secondsRemaining;
  final double progress;
  final String secondsLabel;

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
                secondsLabel,
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

/// Single row in the pre-flight checklist (check/cross + label).
class _PreflightCheckItem extends StatelessWidget {
  const _PreflightCheckItem({
    required this.label,
    required this.ready,
  });

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: ready ? AppColors.safe : AppColors.danger,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
