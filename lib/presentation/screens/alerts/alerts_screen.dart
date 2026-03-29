import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../widgets/safora_animated_icons.dart';
import '../shell/main_shell.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/alert_event.dart';
import '../../../data/models/alert_preferences.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/native_ad_widget.dart';

/// Alert list screen with filtering by category and priority.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlertsCubit>().loadAlerts();
  }

  // ── Native ad slot helpers ───────────────────────────
  /// Insert a native ad after every 5th real alert.
  static const _nativeAdInterval = 5;

  /// Whether the list index is a native ad slot.
  bool _isNativeAdSlot(int index) {
    if (index == 0) return false; // Never first item.
    return (index + 1) % (_nativeAdInterval + 1) == 0;
  }

  /// Total items including native ad slots.
  int _itemCountWithNativeAds(int alertCount) {
    if (alertCount == 0) return 0;
    final adCount = alertCount ~/ _nativeAdInterval;
    return alertCount + adCount;
  }

  /// Convert a list index to the real alert index.
  int _alertIndexFromListIndex(int index) {
    final adsBefore = index ~/ (_nativeAdInterval + 1);
    return index - adsBefore;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.disasterAlerts),
        actions: [
          // Alert Preferences entry point
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Alert Preferences',
            onPressed: () => context.push('/alert-preferences'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AlertsCubit>().refreshAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AlertsCubit, AlertsState>(
              builder: (context, state) {
                if (state is AlertsLoading) {
                  return const Center(
                    child: SaforaLoadingSpinner(size: 48),
                  );
                }

                if (state is AlertsError) {
                  return _buildError(context, state.message);
                }

                if (state is AlertsLoaded) {
                  return _buildLoaded(context, state);
                }

                return _buildEmpty(context);
              },
            ),
          ),
          // Banner ad at bottom of alerts screen.
          AdBanner(adUnitId: AdService.bannerAlerts),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, AlertsLoaded state) {
    final l = AppLocalizations.of(context)!;
    final filtered = state.filtered;

    return Column(
      children: [
        // ─── Filter chips ─────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: l.filterAll,
                isSelected: state.filterPriority == null &&
                    state.filterCategory == null,
                onTap: () => context.read<AlertsCubit>().clearFilters(),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterCritical,
                isSelected: state.filterPriority == AlertPriority.critical,
                color: AppColors.danger,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByPriority(AlertPriority.critical),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterHigh,
                isSelected: state.filterPriority == AlertPriority.danger,
                color: AppColors.high,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByPriority(AlertPriority.danger),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterMedium,
                isSelected: state.filterPriority == AlertPriority.warning,
                color: AppColors.warning,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByPriority(AlertPriority.warning),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterLow,
                isSelected: state.filterPriority == AlertPriority.advisory,
                color: AppColors.success,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByPriority(AlertPriority.advisory),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterDisaster,
                isSelected:
                    state.filterCategory == AlertCategory.naturalDisaster,
                color: AppColors.warning,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.naturalDisaster),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterWeather,
                isSelected:
                    state.filterCategory == AlertCategory.weatherEmergency,
                color: AppColors.info,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.weatherEmergency),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterWater,
                isSelected:
                    state.filterCategory == AlertCategory.waterMarine,
                color: AppColors.secondaryLight,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.waterMarine),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterSafety,
                isSelected:
                    state.filterCategory == AlertCategory.personalSafety,
                color: AppColors.secondary,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.personalSafety),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterHealth,
                isSelected:
                    state.filterCategory == AlertCategory.healthMedical,
                color: AppColors.danger,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.healthMedical),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterVehicle,
                isSelected:
                    state.filterCategory == AlertCategory.vehicleTransport,
                color: AppColors.textSecondary,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.vehicleTransport),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l.filterEnvironmental,
                isSelected:
                    state.filterCategory == AlertCategory.environmentalChemical,
                color: AppColors.accent,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.environmentalChemical),
              ),
            ],
          ),
        ),

        // ── Preference info banner ────────────────────────
        if (state.preferencesApplied)
          _PreferenceInfoBanner(
            enabledCount:
                GetIt.instance<AlertPreferences>().totalEnabled,
            totalCount:
                GetIt.instance<AlertPreferences>().totalAlerts,
            onTap: () => context.push('/alert-preferences'),
          ),

        // ─── Alert count ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                l.nAlerts(filtered.length),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                l.autoRefreshNote,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ─── Alert list ───────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<AlertsCubit>().refreshAlerts(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16, 4, 16, saforaBottomInset(context) + 8),
                    itemCount: _itemCountWithNativeAds(filtered.length),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      // Insert a native ad every 5th slot.
                      if (_isNativeAdSlot(index)) {
                        return NativeAdCard(
                          adUnitId: AdService.nativeAlertsFeed,
                        );
                      }
                      final alertIndex = _alertIndexFromListIndex(index);
                      final alert = filtered[alertIndex];
                      return AlertCard(
                        alert: alert,
                        onTap: () =>
                            _showTrustCenterDetail(context, alert),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.safe.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 48,
                color: AppColors.safe,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.allClear,
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.noActiveAlerts,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l.unableToLoadAlerts,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.checkConnection,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  context.read<AlertsCubit>().loadAlerts(),
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TRUST CENTER DETAIL SHEET
  // ═══════════════════════════════════════════════════════════

  void _showTrustCenterDetail(BuildContext context, AlertEvent alert) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMM d, yyyy – HH:mm').format(alert.timestamp);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trust Center',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert title
                    Text(
                      alert.title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (alert.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        alert.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Why this alert exists ──
                    _TrustDetailSection(
                      icon: Icons.info_outline_rounded,
                      title: 'Why this alert exists',
                      content: _buildWhyExplanation(alert),
                    ),

                    // ── Source ──
                    _TrustDetailSection(
                      icon: Icons.source_rounded,
                      title: 'Source',
                      content: alert.source ?? 'System-generated',
                    ),

                    // ── Confidence ──
                    _TrustDetailSection(
                      icon: Icons.verified_rounded,
                      title: 'Confidence Score',
                      content: alert.confidenceLevel != null
                          ? '${(alert.confidenceLevel! * 100).toInt()}% — ${alert.confidenceLabel}'
                          : 'Not yet verified',
                    ),

                    // ── Risk Score ──
                    if (alert.riskScore != null)
                      _TrustDetailSection(
                        icon: Icons.speed_rounded,
                        title: 'Risk Score',
                        content:
                            '${alert.riskScore}/100 — ${_riskLabel(alert.riskScore!)}',
                      ),

                    // ── Timing ──
                    _TrustDetailSection(
                      icon: Icons.access_time_rounded,
                      title: 'Time of last update',
                      content: timeStr,
                    ),

                    // ── Expiry ──
                    if (alert.expiresAt != null)
                      _TrustDetailSection(
                        icon: Icons.timer_off_rounded,
                        title: 'Expires',
                        content: alert.isExpired
                            ? 'Expired'
                            : DateFormat('MMM d, HH:mm')
                                .format(alert.expiresAt!),
                      ),

                    // ── Action Advice ──
                    if (alert.actionAdvice != null &&
                        alert.actionAdvice!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.safe.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.safe.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded,
                                size: 18, color: AppColors.safe),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                alert.actionAdvice!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.safe,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Report False Alert action ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showReportFalseAlert(context, alert);
                        },
                        icon: const Icon(Icons.flag_rounded, size: 18),
                        label: const Text('Report as false alert'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWhyExplanation(AlertEvent alert) {
    final parts = <String>[];
    parts.add(
        'This ${alert.type.label} alert was triggered by ${alert.source ?? "the system monitoring pipeline"}.');
    if (alert.distanceKm != null) {
      parts.add(
          'It was detected ${alert.distanceKm!.toStringAsFixed(1)} km from your location.');
    }
    if (alert.confidenceLevel != null) {
      parts.add(
          'The source has a confidence rating of ${(alert.confidenceLevel! * 100).toInt()}%.');
    }
    if (alert.riskScore != null) {
      parts.add(
          'Your personal risk score for this event is ${alert.riskScore}/100.');
    }
    return parts.join(' ');
  }

  String _riskLabel(int score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Moderate';
    if (score >= 20) return 'Low';
    return 'Minimal';
  }

  // ═══════════════════════════════════════════════════════════
  //  REPORT FALSE ALERT SHEET
  // ═══════════════════════════════════════════════════════════

  void _showReportFalseAlert(BuildContext context, AlertEvent alert) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FalseAlertReportSheet(
        alert: alert,
        isDark: isDark,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═════════════════════════════════════════════════════════════

/// Section row for Trust Center detail sheet.
class _TrustDetailSection extends StatelessWidget {
  const _TrustDetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// False alert report bottom sheet with reason selection and Hive persistence.
class _FalseAlertReportSheet extends StatefulWidget {
  const _FalseAlertReportSheet({
    required this.alert,
    required this.isDark,
  });

  final AlertEvent alert;
  final bool isDark;

  @override
  State<_FalseAlertReportSheet> createState() => _FalseAlertReportSheetState();
}

class _FalseAlertReportSheetState extends State<_FalseAlertReportSheet> {
  String? _selectedReason;

  static const _reasons = [
    'Not happening at this location',
    'Already resolved / outdated',
    'Inaccurate severity level',
    'Duplicate of another alert',
    'Other / spam',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.warning, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Report False Alert',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Help improve alert accuracy by reporting false alerts. Select a reason below.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: _selectedReason == reason
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (widget.isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedReason = reason),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              _selectedReason == reason
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: _selectedReason == reason
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reason,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: _selectedReason == reason
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason == null ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      AppColors.textDisabled.withValues(alpha: 0.2),
                ),
                child: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    // Persist to Hive for analytics / future sync
    final box = await Hive.openBox('false_alert_reports');
    await box.add({
      'alertId': widget.alert.id,
      'alertTitle': widget.alert.title,
      'alertType': widget.alert.type.name,
      'reason': _selectedReason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Report submitted — thank you for improving alert accuracy'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  chipColor.withValues(alpha: 0.18),
                  chipColor.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: isSelected
            ? null
            : isDark
                ? AppColors.darkSurfaceVariant.withValues(alpha: 0.6)
                : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? chipColor.withValues(alpha: 0.4)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: chipColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? chipColor
                    : isDark
                        ? Colors.white54
                        : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Info banner showing how many alert types are active from preferences.
class _PreferenceInfoBanner extends StatelessWidget {
  const _PreferenceInfoBanner({
    required this.enabledCount,
    required this.totalCount,
    required this.onTap,
  });

  final int enabledCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing $enabledCount of $totalCount alert types',
                  style: AppTypography.labelSmall.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
