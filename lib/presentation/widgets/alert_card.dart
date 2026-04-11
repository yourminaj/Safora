import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../core/constants/alert_types.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/models/alert_event.dart';
import 'alert_icon_widget.dart';

/// A card widget displaying a single disaster alert event.
///
/// Includes Trust Center data: source badge, confidence indicator,
/// and action advice banner when available.
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
    AlertPriority.danger => AppColors.warning,
    AlertPriority.warning => const Color(0xFFFFD54F),
    AlertPriority.advisory => AppColors.safe,
    AlertPriority.info => const Color(0xFF60A5FA),
  };

  /// Confidence indicator color.
  Color _confidenceColor(BuildContext context) {
    final c = alert.confidenceLevel ?? 0.0;
    if (c >= 0.8) return AppColors.safe;
    if (c >= 0.5) return AppColors.warning;
    if (c >= 0.3) return const Color(0xFFFFD54F);
    return (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary);
  }

  IconData get _confidenceIcon {
    final c = alert.confidenceLevel ?? 0.0;
    if (c >= 0.8) return Icons.verified_rounded;
    if (c >= 0.5) return Icons.check_circle_outline_rounded;
    return Icons.help_outline_rounded;
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator + animated icon.
                  AlertIconWidget(
                    category: alert.type.category,
                    priority: alert.type.priority,
                    size: 42,
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
                                  color:
                                      _priorityColor.withValues(alpha: 0.15),
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
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 6),

                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Source badge
                            if (alert.source != null)
                              _TrustBadge(
                                icon: Icons.source_rounded,
                                label: alert.source!,
                                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary),
                              ),

                            // Confidence badge
                            if (alert.confidenceLevel != null)
                              _TrustBadge(
                                icon: _confidenceIcon,
                                label: alert.confidenceLabel,
                                color: _confidenceColor(context),
                              ),

                            // Risk score
                            if (alert.riskScore != null)
                              _TrustBadge(
                                icon: Icons.speed_rounded,
                                label: 'Risk ${alert.riskScore}',
                                color: _priorityColor,
                              ),

                            // Distance
                            if (alert.distanceKm != null)
                              _TrustBadge(
                                icon: Icons.near_me_rounded,
                                label:
                                    '${alert.distanceKm!.toStringAsFixed(1)} km',
                                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary),
                              ),

                            // Time
                            _TrustBadge(
                              icon: Icons.access_time_rounded,
                              label: _formatTime(context, alert.timestamp),
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (alert.actionAdvice != null &&
                  alert.actionAdvice!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.safe.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        size: 16,
                        color: AppColors.safe,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.actionAdvice!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.safe,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return l.mAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l.hAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l.dAgo(diff.inDays);
    }
    return DateFormat('MMM d').format(time);
  }
}

/// Small inline badge for Trust Center metadata.
class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
