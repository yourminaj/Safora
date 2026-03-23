import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/alert_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.disasterAlerts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AlertsCubit>().refreshAlerts(),
          ),
        ],
      ),
      bottomNavigationBar: AdBanner(adUnitId: AdService.bannerAlerts),
      body: BlocBuilder<AlertsCubit, AlertsState>(
        builder: (context, state) {
          if (state is AlertsLoading) {
            return const Center(child: CircularProgressIndicator());
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
                label: '🔴 ${l.filterCritical}',
                isSelected: state.filterPriority == AlertPriority.critical,
                color: AppColors.danger,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByPriority(AlertPriority.critical),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '🌍 ${l.filterDisaster}',
                isSelected:
                    state.filterCategory == AlertCategory.naturalDisaster,
                color: AppColors.warning,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.naturalDisaster),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '⛈️ ${l.filterWeather}',
                isSelected:
                    state.filterCategory == AlertCategory.weatherEmergency,
                color: AppColors.info,
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.weatherEmergency),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '🌊 ${l.filterWater}',
                isSelected:
                    state.filterCategory == AlertCategory.waterMarine,
                color: const Color(0xFF42A5F5),
                onTap: () => context
                    .read<AlertsCubit>()
                    .filterByCategory(AlertCategory.waterMarine),
              ),
            ],
          ),
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final alert = filtered[index];
                      return AlertCard(alert: alert);
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
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Material(
      color: isSelected
          ? chipColor.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? chipColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
