import 'package:safora/presentation/widgets/safora_toast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/premium_manager.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/datasources/sos_history_datasource.dart';
import '../../../data/models/sos_history_entry.dart';
import '../../../injection.dart';

/// Screen displaying a list of past SOS activation events.
class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  late List<SosHistoryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    final allEntries = getIt<SosHistoryDatasource>().getAll();
    // Apply free-tier date filter (7 days free, 365 days pro).
    final retentionDays = getIt<PremiumManager>().historyRetentionDays;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    _entries = allEntries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  Future<void> _clearHistory(AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearHistory),
        content: Text(l.historyClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(l.clearHistory),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<SosHistoryDatasource>().clear();
      setState(() => _loadEntries());
      if (mounted) {
        SaforaToast.showInfo(context, l.historyCleared);
      }
    }
  }

  IconData _triggerIcon(SosTriggerSource source) {
    switch (source) {
      case SosTriggerSource.shake:
        return Icons.vibration_rounded;
      case SosTriggerSource.crashDetection:
        return Icons.minor_crash_rounded;
      case SosTriggerSource.background:
        return Icons.dns_rounded;
      case SosTriggerSource.manual:
        return Icons.touch_app_rounded;
    }
  }

  String _triggerLabel(SosTriggerSource source, AppLocalizations l) {
    switch (source) {
      case SosTriggerSource.shake:
        return l.triggerShake;
      case SosTriggerSource.crashDetection:
        return l.triggerCrash;
      case SosTriggerSource.background:
        return l.triggerBackground;
      case SosTriggerSource.manual:
        return l.triggerManual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.sosHistory),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _clearHistory(l),
              tooltip: l.clearHistory,
            ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppColors.textDisabled.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noSosHistory,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final dateStr = DateFormat.yMMMd().add_jm().format(entry.timestamp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: entry.wasCancelled
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _triggerIcon(entry.triggerSource),
                        color: entry.wasCancelled
                            ? AppColors.warning
                            : AppColors.danger,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          _triggerLabel(entry.triggerSource, l),
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: entry.wasCancelled
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.wasCancelled
                                ? l.cancelledLabel
                                : l.completedLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: entry.wasCancelled
                                  ? AppColors.warning
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.contactsNotifiedLabel}: ${entry.contactsNotified} · '
                          '${l.smsSentLabel}: ${entry.smsSentCount}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (entry.address != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.address!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
