import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/alert_types.dart';

/// Animated alert icon widget that uses Lottie for critical categories
/// and animated Material icons for others.
///
/// Priority → animation mapping:
/// - Critical: pulsing red with Lottie shield
/// - High: breathing orange animation
/// - Medium: gentle yellow pulse
/// - Low: subtle green indicator
class AlertIconWidget extends StatefulWidget {
  const AlertIconWidget({
    super.key,
    required this.category,
    required this.priority,
    this.size = 42,
  });

  final AlertCategory category;
  final AlertPriority priority;
  final double size;

  @override
  State<AlertIconWidget> createState() => _AlertIconWidgetState();
}

class _AlertIconWidgetState extends State<AlertIconWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Only critical alerts pulse continuously; others animate once.
    if (widget.priority == AlertPriority.critical) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  Duration get _animationDuration => switch (widget.priority) {
    AlertPriority.critical => const Duration(milliseconds: 600),
    AlertPriority.high => const Duration(milliseconds: 900),
    AlertPriority.medium => const Duration(milliseconds: 1200),
    AlertPriority.low => const Duration(milliseconds: 1500),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get the Material icon for this alert category.
  IconData get _categoryIcon => switch (widget.category) {
    AlertCategory.naturalDisaster => Icons.public_rounded,
    AlertCategory.weatherEmergency => Icons.thunderstorm_rounded,
    AlertCategory.healthMedical => Icons.medical_services_rounded,
    AlertCategory.vehicleTransport => Icons.directions_car_rounded,
    AlertCategory.personalSafety => Icons.shield_rounded,
    AlertCategory.homeDomestic => Icons.home_rounded,
    AlertCategory.workplace => Icons.engineering_rounded,
    AlertCategory.waterMarine => Icons.water_rounded,
    AlertCategory.travelOutdoor => Icons.terrain_rounded,
    AlertCategory.environmentalChemical => Icons.science_rounded,
    AlertCategory.digitalCyber => Icons.phone_android_rounded,
    AlertCategory.childElder => Icons.child_care_rounded,
  };

  /// Get the color for this alert priority.
  Color get _priorityColor => switch (widget.priority) {
    AlertPriority.critical => const Color(0xFFEF4444),
    AlertPriority.high => const Color(0xFFF97316),
    AlertPriority.medium => const Color(0xFFEAB308),
    AlertPriority.low => const Color(0xFF22C55E),
  };

  /// Lottie asset path if available for this category.
  String? get _lottieAsset => switch (widget.category) {
    AlertCategory.personalSafety => 'assets/lottie/shield_pulse.json',
    AlertCategory.weatherEmergency => 'assets/lottie/warning_alert.json',
    AlertCategory.naturalDisaster => 'assets/lottie/warning_alert.json',
    AlertCategory.healthMedical => 'assets/lottie/sos_active.json',
    AlertCategory.travelOutdoor => 'assets/lottie/location_tracking.json',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final lottieAsset = _lottieAsset;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                boxShadow: widget.priority == AlertPriority.critical
                    ? [
                        BoxShadow(
                          color: _priorityColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: lottieAsset != null
                  ? Lottie.asset(
                      lottieAsset,
                      width: widget.size * 0.55,
                      height: widget.size * 0.55,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        _categoryIcon,
                        color: _priorityColor,
                        size: widget.size * 0.52,
                      ),
                    )
                  : Icon(
                      _categoryIcon,
                      color: _priorityColor,
                      size: widget.size * 0.52,
                    ),
            ),
          ),
        );
      },
    );
  }
}
