import 'package:flutter/material.dart';
import '../../core/constants/alert_types.dart';
import 'safora_animated_icons.dart';

/// Animated alert icon widget that uses CustomPainter for fully
/// branded alert category icons. No Lottie dependency.
///
/// Priority → animation mapping:
/// - Critical: pulsing red glow
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
    AlertPriority.danger => const Duration(milliseconds: 900),
    AlertPriority.warning => const Duration(milliseconds: 1200),
    AlertPriority.advisory => const Duration(milliseconds: 1500),
    AlertPriority.info => const Duration(milliseconds: 1800),
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
    AlertCategory.militaryDefense => Icons.military_tech_rounded,
    AlertCategory.infrastructure => Icons.domain_rounded,
    AlertCategory.spaceAstronomical => Icons.satellite_alt_rounded,
    AlertCategory.maritimeAviation => Icons.flight_rounded,
  };

  /// Get the color for this alert priority.
  Color get _priorityColor => switch (widget.priority) {
    AlertPriority.critical => const Color(0xFFEF4444),
    AlertPriority.danger => const Color(0xFFF97316),
    AlertPriority.warning => const Color(0xFFEAB308),
    AlertPriority.advisory => const Color(0xFF22C55E),
    AlertPriority.info => const Color(0xFF60A5FA),
  };

  /// Returns a branded custom widget for specific categories,
  /// falling back to Material icon for others.
  Widget _buildCategoryIcon() {
    final iconSize = widget.size * 0.52;
    switch (widget.category) {
      case AlertCategory.personalSafety:
        return SaforaShieldPulse(
          size: iconSize,
          animated: widget.priority == AlertPriority.critical,
        );
      case AlertCategory.weatherEmergency:
      case AlertCategory.naturalDisaster:
        return SaforaWarningIcon(
          size: iconSize,
          color: _priorityColor,
        );
      case AlertCategory.healthMedical:
        return SaforaMedicalIcon(
          size: iconSize,
          animated: widget.priority == AlertPriority.critical,
        );
      case AlertCategory.travelOutdoor:
        return SaforaLocationIcon(
          size: iconSize,
          animated: false,
        );
      default:
        return Icon(
          _categoryIcon,
          color: _priorityColor,
          size: iconSize,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Center(child: _buildCategoryIcon()),
            ),
          ),
        );
      },
    );
  }
}
