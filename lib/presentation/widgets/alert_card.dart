import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/alert_types.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/models/alert_event.dart';

/// A card widget displaying a single disaster alert event.
///
/// Color-coded by priority:
/// - Critical → red
/// - High → orange
/// - Medium → yellow
/// - Low → green
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  final AlertEvent alert;
  final VoidCallback? onTap;

  Color get _priorityColor => switch (alert.type.priority) {
        AlertPriority.critical => AppColors.danger,
        AlertPriority.high => AppColors.warning,
        AlertPriority.medium => const Color(0xFFFFD54F),
        AlertPriority.low => AppColors.safe,
      };

  IconData get _categoryIcon => switch (alert.type.category) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? _priorityColor.withValues(alpha: 0.08)
          : _priorityColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _priorityColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority indicator + icon.
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon,
                  color: _priorityColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Content.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (alert.magnitude != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              alert.type == AlertType.earthquake
                                  ? 'M${alert.magnitude!.toStringAsFixed(1)}'
                                  : alert.magnitude!.toStringAsFixed(0),
                              style: AppTypography.labelSmall.copyWith(
                                color: _priorityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (alert.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        alert.description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Meta row: source + time.
                    Row(
                      children: [
                        if (alert.source != null) ...[
                          Icon(
                            Icons.source_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alert.source!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(alert.timestamp),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('MMM d').format(time);
  }
}
