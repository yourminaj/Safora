import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';

/// Full-screen lock screen with 4-digit PIN entry and biometric option.
///
/// Shown when the app resumes from background (if lock is enabled).
/// Attempts biometric auth on mount if available and enabled.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, this.onUnlocked});

  /// Called after successful authentication.
  final VoidCallback? onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final List<String> _pin = [];
  bool _error = false;
  bool _biometricAvailable = false;
  late final AppLockService _lockService;

  @override
  void initState() {
    super.initState();
    _lockService = getIt<AppLockService>();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (_lockService.isBiometricEnabled) {
      final available = await _lockService.isBiometricAvailable();
      if (mounted) setState(() => _biometricAvailable = available);
      if (available) _attemptBiometric();
    }
  }

  Future<void> _attemptBiometric() async {
    final success = await _lockService.authenticateWithBiometric();
    if (success && mounted) _unlock();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin.add(digit);
      _error = false;
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin.removeLast();
      _error = false;
    });
  }

  void _verifyPin() {
    final enteredPin = _pin.join();
    if (_lockService.verifyPin(enteredPin)) {
      _unlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
        _pin.clear();
      });
    }
  }

  void _unlock() {
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else {
      // Use GoRouter's pop so the push() Future in SaforaApp resolves
      // correctly, resetting the _lockScreenShowing flag.
      context.pop(true);
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
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.enterPin,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (_error)
                Text(
                  l.wrongPin,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.yellow,
                  ),
                )
              else
                Text(
                  l.enterPinToUnlock,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              const SizedBox(height: 32),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: filled ? 20 : 16,
                    height: filled ? 20 : 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      border: _error
                          ? Border.all(color: Colors.yellow, width: 2)
                          : null,
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Number pad
              _buildNumberPad(),
              const SizedBox(height: 16),
              // Biometric button
              if (_biometricAvailable)
                TextButton.icon(
                  onPressed: _attemptBiometric,
                  icon: const Icon(Icons.fingerprint_rounded,
                      color: Colors.white, size: 28),
                  label: Text(
                    l.useBiometric,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: digits.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((digit) {
              if (digit.isEmpty) {
                return const SizedBox(width: 72, height: 72);
              }
              if (digit == '⌫') {
                return _PadButton(
                  onTap: _onBackspace,
                  child: const Icon(Icons.backspace_rounded,
                      color: Colors.white, size: 24),
                );
              }
              return _PadButton(
                child: Text(
                  digit,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: () => _onDigitPressed(digit),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

/// A single number pad button.
class _PadButton extends StatelessWidget {
  const _PadButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: child,
        ),
      ),
    );
  }
}
