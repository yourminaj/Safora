import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../widgets/alert_card.dart';
import 'widgets/sos_button.dart';

/// Main dashboard with SOS button, status, and quick actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load alerts when home screen opens (if not already loaded).
    final alertsCubit = context.read<AlertsCubit>();
    if (alertsCubit.state is AlertsInitial) {
      alertsCubit.loadAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 60,
              floating: true,
              pinned: true,
              title: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Safora SOS',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/alerts'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),

            // ─── Status Banner ───────────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<AlertsCubit, AlertsState>(
                builder: (context, state) {
                  final alertCount = state is AlertsLoaded
                      ? state.alerts.length
                      : 0;
                  final isSafe = alertCount == 0;

                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSafe
                          ? AppColors.safeGradient
                          : AppColors.dangerGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isSafe ? AppColors.safe : AppColors.danger)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSafe
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSafe
                                    ? 'All Safe'
                                    : '$alertCount Active Alert${alertCount == 1 ? '' : 's'}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                isSafe
                                    ? 'No active threats detected'
                                    : 'Tap to view details',
                                style: AppTypography.bodySmall.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'LIVE',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── SOS Button ──────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SosButton(),
              ),
            ),

            // ─── Quick Actions Grid ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _QuickAction(
                          icon: Icons.phone_in_talk_rounded,
                          label: 'Decoy Call',
                          color: AppColors.secondary,
                          onTap: () => context.push('/decoy-call'),
                        ),
                        _QuickAction(
                          icon: Icons.contacts_rounded,
                          label: 'Contacts',
                          color: AppColors.accent,
                          onTap: () => context.push('/contacts'),
                        ),
                        _QuickAction(
                          icon: Icons.medical_information_rounded,
                          label: 'Medical ID',
                          color: AppColors.success,
                          onTap: () => context.push('/profile'),
                        ),
                        _QuickAction(
                          icon: Icons.warning_amber_rounded,
                          label: 'Alerts',
                          color: AppColors.warning,
                          onTap: () => context.push('/alerts'),
                        ),
                        _QuickAction(
                          icon: Icons.map_rounded,
                          label: 'Live Map',
                          color: AppColors.info,
                          onTap: () => context.push('/alerts'),
                        ),
                        _QuickAction(
                          icon: Icons.medication_rounded,
                          label: 'Reminders',
                          color: AppColors.primary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Medicine reminders coming in Phase 2',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Recent Alerts Section ──────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Alerts',
                            style: AppTypography.titleMedium),
                        TextButton(
                          onPressed: () => context.push('/alerts'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<AlertsCubit, AlertsState>(
                      builder: (context, state) {
                        if (state is AlertsLoaded &&
                            state.alerts.isNotEmpty) {
                          final recent = state.alerts.take(3).toList();
                          return Column(
                            children: recent
                                .map((alert) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: AlertCard(alert: alert),
                                    ))
                                .toList(),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 48,
                                  color:
                                      AppColors.safe.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No recent alerts',
                                  style:
                                      AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Extra bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
