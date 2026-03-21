import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// In-call screen shown after answering a decoy call.
///
/// Displays a live call timer (MM:SS), mute/keypad/speaker controls,
/// and a prominent end-call button to maintain the realistic appearance.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key, required this.callerName});

  final String callerName;

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Avatar.
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  widget.callerName.isNotEmpty
                      ? widget.callerName[0].toUpperCase()
                      : '?',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.secondary,
                    fontSize: 36,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.callerName,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formattedTime,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.safe,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),

            const Spacer(),

            // Call controls.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    isActive: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _ControlButton(
                    icon: Icons.dialpad,
                    label: 'Keypad',
                    onTap: () {},
                  ),
                  _ControlButton(
                    icon:
                        _isSpeaker ? Icons.volume_up : Icons.volume_up_outlined,
                    label: 'Speaker',
                    isActive: _isSpeaker,
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // End call button.
            Material(
              color: AppColors.danger,
              shape: const CircleBorder(),
              elevation: 8,
              child: InkWell(
                onTap: _endCall,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 70,
                  height: 70,
                  child: Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'End Call',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
