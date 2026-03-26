import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/medicine_reminder.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../blocs/reminders/reminders_cubit.dart';
import '../../blocs/reminders/reminders_state.dart';
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

  void _showRemindersSheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final remindersCubit = context.read<RemindersCubit>();
    remindersCubit.loadReminders();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: remindersCubit,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.medication_rounded,
                                size: 20,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l.medicineReminders,
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state is RemindersLoaded)
                                Text(
                                  l.nActive(state.activeCount),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle_rounded),
                                color: AppColors.primary,
                                tooltip: l.addReminder,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => BlocProvider.value(
                                      value: remindersCubit,
                                      child: const _AddReminderDialog(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state is RemindersLoading)
                        const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (state is RemindersLoaded &&
                          state.reminders.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.noRemindersSet,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.addRemindersHint,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (state is RemindersLoaded)
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.reminders.length,
                            itemBuilder: (context, index) {
                              final r = state.reminders[index];
                              return ListTile(
                                leading: Icon(
                                  r.isActive
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: r.isActive
                                      ? AppColors.success
                                      : Colors.grey,
                                ),
                                title: Text(r.name),
                                subtitle: Text(
                                  '${r.dosage} — ${r.timeOfDay} (${r.frequency.displayName})',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    if (r.id != null) {
                                      remindersCubit.deleteReminder(r.id!);
                                    }
                                  },
                                ),
                                onTap: () {
                                  if (r.id != null) {
                                    remindersCubit.toggleReminder(r.id!);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                    l.appTitle,
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
                          child: isSafe
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Lottie.asset(
                                    'assets/lottie/shield_pulse.json',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const Icon(
                                  Icons.warning_amber_rounded,
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
                                isSafe ? l.allSafe : l.activeAlerts(alertCount),
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                isSafe ? l.noActiveThreats : l.tapToViewDetails,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                            l.live,
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
                    Text(l.quickActions, style: AppTypography.titleMedium),
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
                          label: l.decoyCall,
                          color: AppColors.secondary,
                          onTap: () => context.push('/decoy-call'),
                        ),
                        _QuickAction(
                          icon: Icons.contacts_rounded,
                          label: l.contacts,
                          color: AppColors.accent,
                          onTap: () => context.push('/contacts'),
                        ),
                        _QuickAction(
                          icon: Icons.medical_information_rounded,
                          label: l.medicalId,
                          color: AppColors.success,
                          onTap: () => context.push('/profile'),
                        ),
                        _QuickAction(
                          icon: Icons.warning_amber_rounded,
                          label: l.alerts,
                          color: AppColors.warning,
                          onTap: () => context.push('/alerts'),
                        ),
                        _QuickAction(
                          icon: Icons.map_rounded,
                          label: l.alertMap,
                          color: AppColors.info,
                          onTap: () => context.push('/alert-map'),
                        ),
                        _QuickAction(
                          icon: Icons.medication_rounded,
                          label: l.reminders,
                          color: AppColors.primary,
                          onTap: () {
                            _showRemindersSheet(context);
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
                        Text(l.recentAlerts, style: AppTypography.titleMedium),
                        TextButton(
                          onPressed: () => context.push('/alerts'),
                          child: Text(l.seeAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<AlertsCubit, AlertsState>(
                      builder: (context, state) {
                        if (state is AlertsLoaded && state.alerts.isNotEmpty) {
                          final recent = state.alerts.take(3).toList();
                          return Column(
                            children: recent
                                .map(
                                  (alert) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: AlertCard(alert: alert),
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 48,
                                  color: AppColors.safe.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.noRecentAlerts,
                                  style: AppTypography.bodyMedium.copyWith(
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

/// Dialog to add a new medicine reminder with time picker and frequency.
class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog();

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _dosageCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  ReminderFrequency _freq = ReminderFrequency.daily;

  @override
  void dispose() {
    _nameCtl.dispose();
    _dosageCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    context.read<RemindersCubit>().addReminder(
      name: _nameCtl.text.trim(),
      dosage: _dosageCtl.text.trim(),
      timeOfDay: timeStr,
      frequency: _freq,
      notes: _notesCtl.text.trim().isNotEmpty ? _notesCtl.text.trim() : null,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.addReminder),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: InputDecoration(
                  labelText: l.medicineName,
                  prefixIcon: const Icon(Icons.medication_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.enterMedicineName
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageCtl,
                decoration: InputDecoration(
                  labelText: l.dosage,
                  hintText: l.dosageHint,
                  prefixIcon: const Icon(Icons.science_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.enterDosage : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l.time),
                trailing: TextButton(
                  onPressed: _pickTime,
                  child: Text(_time.format(context)),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderFrequency>(
                initialValue: _freq,
                decoration: InputDecoration(
                  labelText: l.frequency,
                  prefixIcon: const Icon(Icons.repeat_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: ReminderFrequency.daily,
                    child: Text(l.onceDailyLabel),
                  ),
                  DropdownMenuItem(
                    value: ReminderFrequency.twiceDaily,
                    child: Text(l.twiceDailyLabel),
                  ),
                  DropdownMenuItem(
                    value: ReminderFrequency.weekly,
                    child: Text(l.weeklyLabel),
                  ),
                  DropdownMenuItem(
                    value: ReminderFrequency.asNeeded,
                    child: Text(l.asNeededLabel),
                  ),
                ],
                onChanged: (v) => setState(() => _freq = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtl,
                decoration: InputDecoration(
                  labelText: l.notes,
                  hintText: l.notesHint,
                  prefixIcon: const Icon(Icons.note_rounded),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
