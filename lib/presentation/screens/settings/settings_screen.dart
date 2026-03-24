import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/shake_detection_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../injection.dart';
import '../../blocs/contacts/contacts_cubit.dart';
import '../../blocs/contacts/contacts_state.dart';
import '../../blocs/sos/sos_cubit.dart';
import '../../widgets/ad_banner_widget.dart';

/// Functional settings screen with real navigation and state.
///
/// Wires: Profile nav, Contacts nav, Shake-to-SOS toggle (starts/stops
/// [ShakeDetectionService] connected to [SosCubit]), and Language.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _shakeEnabled = false;
  bool _lockEnabled = false;
  late final ShakeDetectionService _shakeService;
  late final AppLockService _lockService;
  late final Box _appSettings;

  @override
  void initState() {
    super.initState();
    _shakeService = getIt<ShakeDetectionService>();
    _lockService = getIt<AppLockService>();
    _appSettings = getIt<Box>(instanceName: 'app_settings');
    // Restore persisted state.
    _shakeEnabled = _appSettings.get('shake_enabled', defaultValue: false) as bool;
    _lockEnabled = _lockService.isLockEnabled;
  }

  void _toggleShake(bool enabled) {
    setState(() => _shakeEnabled = enabled);
    // Persist to Hive so it survives app restart.
    _appSettings.put('shake_enabled', enabled);
    if (enabled) {
      _shakeService.startListening(
        onShakeDetected: () {
          // Trigger SOS countdown when device is shaken.
          context.read<SosCubit>().startCountdown();
        },
      );
    } else {
      _shakeService.stopListening();
    }
  }

  void _toggleLock(bool enabled) async {
    final l = AppLocalizations.of(context)!;
    if (enabled) {
      // Show PIN setup dialog.
      final pin = await _showPinSetupDialog(l);
      if (pin != null && mounted) {
        await _lockService.setPin(pin);
        await _lockService.enableLock();
        setState(() => _lockEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.lockEnabled)),
          );
        }
      }
    } else {
      // Verify current PIN before disabling.
      final verified = await _showPinVerifyDialog(l);
      if (verified && mounted) {
        await _lockService.disableLock();
        setState(() => _lockEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.lockDisabled)),
          );
        }
      }
    }
  }

  Future<String?> _showPinSetupDialog(AppLocalizations l) async {
    String? firstPin;
    final pinController = TextEditingController();

    // Step 1: Enter PIN
    firstPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.setPinTitle),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '• • • •',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(ctx, pinController.text);
              }
            },
            child: Text(l.next),
          ),
        ],
      ),
    );

    if (firstPin == null || !mounted) return null;

    // Step 2: Confirm PIN
    pinController.clear();
    final confirm = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmPin),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '• • • •',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                Navigator.pop(ctx, pinController.text);
              }
            },
            child: Text(l.ok),
          ),
        ],
      ),
    );

    pinController.dispose();

    if (confirm == null) return null;
    if (firstPin != confirm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.pinMismatch)),
        );
      }
      return null;
    }
    return firstPin;
  }

  Future<bool> _showPinVerifyDialog(AppLocalizations l) async {
    final pinController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.enterPin),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '• • • •',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              final ok = _lockService.verifyPin(pinController.text);
              Navigator.pop(ctx, ok);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.wrongPin)),
                );
              }
            },
            child: Text(l.ok),
          ),
        ],
      ),
    );
    pinController.dispose();
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: AdBanner(adUnitId: AdService.bannerSettings),
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsSection(
            title: l.account,
            children: [
              _SettingsTile(
                icon: Icons.person_rounded,
                title: l.profile,
                subtitle: l.manageProfile,
                onTap: () => context.push('/profile'),
              ),
              _SettingsTile(
                icon: Icons.workspace_premium_rounded,
                title: l.premium,
                subtitle: l.unlockAllRiskTypes,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(l.saforaPremium),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.currentFreePlan),
                          const SizedBox(height: 8),
                          Text(l.freeSos),
                          Text(l.freeContacts),
                          Text(l.freeAlerts),
                          Text(l.freeDetection),
                          Text(l.freeMedicalId),
                          const SizedBox(height: 12),
                          Text(
                            l.premiumRoadmap,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        if (AdService.instance.isRewardedReady)
                          TextButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final rewarded =
                                  await AdService.instance.showRewarded();
                              if (rewarded && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.premiumRoadmap),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Watch Ad'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.ok),
                        ),
                      ],
                    ),
                  );
                },
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.pro,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: l.safety,
            children: [
              BlocBuilder<ContactsCubit, ContactsState>(
                builder: (context, state) {
                  final count = state is ContactsLoaded
                      ? state.contacts.length
                      : 0;
                  return _SettingsTile(
                    icon: Icons.contacts_rounded,
                    title: l.emergencyContacts,
                    subtitle: l.nContactsAdded(count),
                    onTap: () => context.push('/contacts'),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.vibration_rounded,
                title: l.shakeToSos,
                subtitle: l.shakeToSosDesc,
                onTap: () => _toggleShake(!_shakeEnabled),
                trailing: Switch(
                  value: _shakeEnabled,
                  onChanged: _toggleShake,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_rounded,
                title: l.appLock,
                subtitle: l.appLockDesc,
                onTap: () => _toggleLock(!_lockEnabled),
                trailing: Switch(
                  value: _lockEnabled,
                  onChanged: _toggleLock,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.volume_up_rounded,
                title: l.alertSounds,
                subtitle: l.configureAlertSounds,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.alertSoundSettings),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.alertSoundExplain),
                          const SizedBox(height: 12),
                          Text(l.criticalSiren,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(l.highMediumWarning),
                          Text(l.lowNotification),
                          const SizedBox(height: 12),
                          Text(
                            l.customSoundFuture,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.ok),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: l.general,
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: l.language,
                subtitle: l.english,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.languageSettings),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.languageExplain),
                          const SizedBox(height: 12),
                          Text(
                            l.toChangeLanguage,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(l.deviceSettingsLanguage),
                          const SizedBox(height: 12),
                          Text(
                            l.inAppLanguageFuture,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.ok),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: l.darkMode,
                subtitle: l.systemDefault,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.themeFollowsSystem),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: l.about,
                subtitle: l.saforaVersion,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: l.appTitle,
                    applicationVersion: '1.1.0',
                    applicationLegalese: l.saforaLegalese,
                    children: [
                      const SizedBox(height: 16),
                      Text(l.saforaAbout),
                    ],
                  );
                },
              ),
            ],
          ),
          // ── Account Actions ────────────────────────────
          const Divider(height: 32),
          if (getIt<AuthService>().isSignedIn)
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: getIt<AuthService>().currentUser?.email ?? '',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await getIt<AuthService>().signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            )
          else
            _SettingsTile(
              icon: Icons.login_rounded,
              title: 'Sign In',
              subtitle: 'Sync your contacts to the cloud',
              onTap: () => context.go('/login'),
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
