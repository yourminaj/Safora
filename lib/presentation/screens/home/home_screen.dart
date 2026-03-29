import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../widgets/safora_brand_mark.dart';
import '../shell/main_shell.dart';
import '../../../data/models/medicine_reminder.dart';

import '../../../services/risk_score_engine.dart';
import '../../../core/services/sms_service.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../emergency/emergency_full_screen_card.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../blocs/reminders/reminders_cubit.dart';
import '../../blocs/reminders/reminders_state.dart';
import '../../widgets/alert_card.dart';
import '../../../services/dead_man_switch_service.dart';
import 'widgets/sos_button.dart';

/// Main dashboard with SOS button, status, and quick actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _riskEngine = const RiskScoreEngine();
  /// Track which alert IDs have already triggered a full-screen card.
  final _triggeredAlertIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Load alerts when home screen opens (if not already loaded).
    final alertsCubit = context.read<AlertsCubit>();
    if (alertsCubit.state is AlertsInitial) {
      alertsCubit.loadAlerts();
    }
  }

  /// Check if any loaded alert has riskScore >= 80 and trigger
  /// the emergency full-screen card (only once per alert).
  void _checkForCriticalAlerts(List<dynamic> alerts) {
    for (final alert in alerts) {
      final enriched = _riskEngine.enrichWithScore(alert);
      final score = enriched.riskScore ?? 0;
      final id = enriched.id ?? '${enriched.title}_${enriched.timestamp}';

      if (score >= 80 && !_triggeredAlertIds.contains(id)) {
        _triggeredAlertIds.add(id);
        // Show emergency card after the current frame completes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            EmergencyFullScreenCard.show(context, enriched).then((isSafe) {
              if (isSafe == true) {
                _sendIAmSafeSms();
              }
            });
          }
        });
        break; // Only show one emergency card at a time.
      }
    }
  }

  void _sendIAmSafeSms() {
    final contacts = GetIt.instance<ContactsRepository>().getAll();
    if (contacts.isNotEmpty) {
      GetIt.instance<SmsService>().sendIAmSafeSms(contacts: contacts);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('"I Am Safe" sent to emergency contacts'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                            color: AppColors.textDisabled,
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
                                const Icon(
                                  Icons.medication_outlined,
                                  size: 48,
                                  color: AppColors.textDisabled,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.noRemindersSet,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.addRemindersHint,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
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
                                      : AppColors.textDisabled,
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: SaforaBrandMark(size: 24, color: Colors.white),
                    ),
                  ),
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
                  onPressed: () => context.go('/alerts'),
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSafe ? AppColors.safe : AppColors.danger)
                              .withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                              ? const SaforaBrandMark(
                                  size: 28,
                                  color: Colors.white,
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

            // ─── Dead Man's Switch Check-In ───────────────────
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final settings = GetIt.instance<Box>(instanceName: 'app_settings');
                  final dmsEnabled = settings.get('dead_man_switch_enabled', defaultValue: false) as bool;
                  if (!dmsEnabled) return const SizedBox.shrink();

                  final dms = GetIt.instance<DeadManSwitchService>();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          dms.checkIn();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✓ Check-in confirmed — timer reset'),
                              backgroundColor: AppColors.safe,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.safe.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.safe.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.safe.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: AppColors.safe,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dead Man\'s Switch Active',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.safe,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Tap to confirm you\'re safe',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.safe.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.safe,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'I\'m Safe',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.quickActions,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                          onTap: () => context.go('/contacts'),
                        ),
                        _QuickAction(
                          icon: Icons.person_rounded,
                          label: l.profile,
                          color: AppColors.success,
                          onTap: () => context.push('/profile'),
                        ),
                        _QuickAction(
                          icon: Icons.my_location_rounded,
                          label: l.liveMap,
                          color: AppColors.secondaryDark,
                          onTap: () => context.go('/live-map'),
                        ),
                        _QuickAction(
                          icon: Icons.medication_rounded,
                          label: l.reminders,
                          color: AppColors.primary,
                          onTap: () {
                            _showRemindersSheet(context);
                          },
                        ),
                        _QuickAction(
                          icon: Icons.emergency_rounded,
                          label: 'Emergency Center',
                          color: AppColors.danger,
                          onTap: () => context.push('/emergency-center'),
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
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.recentAlerts,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/alerts'),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text(l.seeAll),
                          style: TextButton.styleFrom(
                            textStyle: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<AlertsCubit, AlertsState>(
                      builder: (context, state) {
                        if (state is AlertsLoaded && state.alerts.isNotEmpty) {
                          // Auto-trigger emergency card for critical alerts.
                          _checkForCriticalAlerts(state.alerts);
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
            SliverPadding(padding: EdgeInsets.only(bottom: saforaBottomInset(context) + 8)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.7)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
