import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../widgets/safora_animated_icons.dart';
import '../shell/main_shell.dart';

/// "More" tab screen -- a clean grid of secondary app features.
///
/// Provides access to Profile, Settings, SOS History, Reminders,
/// Decoy Call, and About.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.more),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, saforaBottomInset(context) + 8),
        children: [
          // Account Section
          _SectionHeader(title: l.account),
          const SizedBox(height: 8),
          _MoreTile(
            icon: Icons.person_rounded,
            color: AppColors.secondary,
            label: l.profile,
            subtitle: l.profileSubtitle,
            onTap: () => context.push('/profile'),
            isDark: isDark,
          ),
          _MoreTile(
            icon: Icons.settings_rounded,
            color: AppColors.textSecondary,
            label: l.settings,
            subtitle: l.settingsSubtitle,
            onTap: () => context.push('/settings'),
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Safety Tools
          _SectionHeader(title: l.safetyTools),
          const SizedBox(height: 8),
          _MoreTile(
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.info,
            label: l.decoyCall,
            subtitle: l.decoyCallSubtitle,
            onTap: () => context.push('/decoy-call'),
            isDark: isDark,
          ),
          _MoreTile(
            icon: Icons.medication_rounded,
            color: AppColors.primary,
            label: l.reminders,
            subtitle: l.remindersSubtitle,
            onTap: () => _showRemindersInfo(context),
            isDark: isDark,
          ),
          _MoreTile(
            icon: Icons.tune_rounded,
            color: AppColors.primary,
            label: 'Alert Preferences',
            subtitle: 'Choose which alerts to receive',
            onTap: () => context.push('/alert-preferences'),
            isDark: isDark,
          ),
          _MoreTile(
            icon: Icons.history_rounded,
            color: AppColors.accent,
            label: l.sosHistory,
            subtitle: l.sosHistorySubtitle,
            onTap: () => context.push('/sos-history'),
            isDark: isDark,
          ),
          _MoreTile(
            icon: Icons.map_rounded,
            color: AppColors.success,
            label: l.alertMap,
            subtitle: l.alertMapSubtitle,
            onTap: () => context.push('/alert-map'),
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // About
          _SectionHeader(title: l.about),
          const SizedBox(height: 8),
          _MoreTile(
            icon: Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            label: l.aboutSafora,
            subtitle: l.aboutSaforaSubtitle,
            onTap: () => _showAboutDialog(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _showRemindersInfo(BuildContext context) {
    // Navigate home and the user can access reminders from there.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.remindersAccessedFromHome),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom branded shield pulse (replaces Lottie)
            const SaforaShieldPulse(size: 80, animated: true),
            const SizedBox(height: 12),
            Text(
              'SAFORA',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.appTagline,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'v1.1.3',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
