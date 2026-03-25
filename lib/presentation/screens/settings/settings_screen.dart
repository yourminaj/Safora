import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../app.dart';
import '../../../core/constants/alert_types.dart';
import '../../../data/models/alert_event.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/context_alert_service.dart';
import '../../../core/services/geofence_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/shake_detection_service.dart';
import '../../../core/services/snatch_detection_service.dart';
import '../../../core/services/speed_alert_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../detection/ml/crash_fall_detection_service.dart';
import '../../../detection/ml/crash_fall_detection_engine.dart';
import '../../../injection.dart';
import '../../blocs/contacts/contacts_cubit.dart';
import '../../blocs/contacts/contacts_state.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/sos/sos_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';
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
  /// Current GPS coordinates from the cached LocationService position.
  /// Falls back to 0.0 only when no position has ever been acquired.
  double get _lastLat => getIt<LocationService>().lastPosition?.latitude ?? 0.0;
  double get _lastLon => getIt<LocationService>().lastPosition?.longitude ?? 0.0;

  bool _shakeEnabled = false;
  bool _lockEnabled = false;
  bool _crashFallEnabled = false;
  bool _geofenceEnabled = false;
  bool _snatchEnabled = false;
  bool _speedAlertEnabled = false;
  bool _contextAlertEnabled = false;
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
    _crashFallEnabled = _appSettings.get('crash_fall_enabled', defaultValue: false) as bool;
    _geofenceEnabled = _appSettings.get('geofence_enabled', defaultValue: false) as bool;
    _snatchEnabled = _appSettings.get('snatch_enabled', defaultValue: false) as bool;
    _speedAlertEnabled = _appSettings.get('speed_alert_enabled', defaultValue: false) as bool;
    _contextAlertEnabled = _appSettings.get('context_alert_enabled', defaultValue: false) as bool;
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

  /// Change PIN flow: verify old PIN, then set a new one.
  void _changePin() async {
    final l = AppLocalizations.of(context)!;
    // Step 1: Verify current PIN.
    final verified = await _showPinVerifyDialog(l);
    if (!verified || !mounted) return;
    // Step 2: Set new PIN.
    final newPin = await _showPinSetupDialog(l);
    if (newPin != null && mounted) {
      await _lockService.setPin(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.changePinSuccess)),
        );
      }
    }
  }

  StreamSubscription<DetectionAlert>? _crashSubscription;

  void _toggleCrashFall(bool enabled) {
    setState(() => _crashFallEnabled = enabled);
    _appSettings.put('crash_fall_enabled', enabled);
    final service = getIt<CrashFallDetectionService>();
    if (enabled) {
      service.start();
      // Listen to crash/fall detection stream.
      _crashSubscription?.cancel();
      _crashSubscription = service.alerts.listen((detectionAlert) {
        // Create AlertEvent from DetectionAlert.
        final alertEvent = AlertEvent(
          id: 'crash_${DateTime.now().millisecondsSinceEpoch}',
          type: detectionAlert.alertType,
          title: detectionAlert.title,
          description: detectionAlert.message,
          latitude: _lastLat,
          longitude: _lastLon,
          timestamp: detectionAlert.timestamp,
          source: 'On-Device Accelerometer',
          magnitude: detectionAlert.peakGForce,
        );

        if (mounted) {
          context.read<AlertsCubit>().addLocalAlert(alertEvent);

          // Auto-trigger SOS for vehicle crashes and hard impacts.
          if (detectionAlert.alertType == AlertType.carAccident ||
              detectionAlert.alertType == AlertType.motorcycleCrash ||
              detectionAlert.alertType == AlertType.pedestrianHit) {
            context.read<SosCubit>().startCountdown();
          }
        }
      });
    } else {
      service.stop();
      _crashSubscription?.cancel();
      _crashSubscription = null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? AppLocalizations.of(context)!.crashFallEnabled
              : AppLocalizations.of(context)!.crashFallDisabled,
        ),
      ),
    );
  }

  /// Show crash/fall sensitivity settings bottom sheet.
  void _showSensitivitySettings() {
    final l = AppLocalizations.of(context)!;
    double fallG = _appSettings.get('fall_threshold_g', defaultValue: 3.0) as double;
    double crashG = _appSettings.get('crash_threshold_g', defaultValue: 4.0) as double;
    double minConf = _appSettings.get('min_confidence', defaultValue: 0.5) as double;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(l.sensitivitySettings,
                          style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fall threshold slider
                  Text(l.fallThreshold, style: AppTypography.labelMedium),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: fallG,
                          min: 1.5,
                          max: 6.0,
                          divisions: 9,
                          label: '${fallG.toStringAsFixed(1)}G',
                          onChanged: (v) => setSheetState(() => fallG = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${fallG.toStringAsFixed(1)}G',
                            style: AppTypography.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Crash threshold slider
                  Text(l.crashThreshold, style: AppTypography.labelMedium),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: crashG,
                          min: 2.0,
                          max: 10.0,
                          divisions: 16,
                          label: '${crashG.toStringAsFixed(1)}G',
                          onChanged: (v) => setSheetState(() => crashG = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${crashG.toStringAsFixed(1)}G',
                            style: AppTypography.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Min confidence slider
                  Text(l.minConfidence, style: AppTypography.labelMedium),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: minConf,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: '${(minConf * 100).toInt()}%',
                          onChanged: (v) => setSheetState(() => minConf = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${(minConf * 100).toInt()}%',
                            style: AppTypography.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            fallG = 3.0;
                            crashG = 4.0;
                            minConf = 0.5;
                          });
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(l.resetDefaults),
                      ),
                      FilledButton(
                        onPressed: () {
                          _appSettings.put('fall_threshold_g', fallG);
                          _appSettings.put('crash_threshold_g', crashG);
                          _appSettings.put('min_confidence', minConf);

                          // If service is running, restart with new config.
                          if (_crashFallEnabled) {
                            final service = getIt<CrashFallDetectionService>();
                            service.stop();
                            // Re-register with new thresholds.
                            if (getIt.isRegistered<CrashFallDetectionService>()) {
                              getIt.unregister<CrashFallDetectionService>();
                            }
                            getIt.registerLazySingleton<CrashFallDetectionService>(
                              () => CrashFallDetectionService(
                                engine: CrashFallDetectionEngine(
                                  fallThresholdG: fallG,
                                  crashThresholdG: crashG,
                                  minConfidence: minConf,
                                ),
                              ),
                            );
                            _toggleCrashFall(true);
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.sensitivitySaved)),
                          );
                        },
                        child: Text(l.save),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleGeofence(bool enabled) {
    setState(() => _geofenceEnabled = enabled);
    _appSettings.put('geofence_enabled', enabled);
    final service = getIt<GeofenceService>();
    if (enabled) {
      service.start(onExitAllZones: (zoneName) {
        // Inject into main alert pipeline.
        final alertEvent = AlertEvent(
          id: 'geofence_exit_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.geofenceExit,
          title: 'Left Safe Zone: $zoneName',
          description:
              'You have left the designated safe zone "$zoneName". '
              'Your emergency contacts have been notified.',
          latitude: _lastLat,
          longitude: _lastLon,
          timestamp: DateTime.now(),
          source: 'On-Device GPS',
        );
        if (mounted) {
          context.read<AlertsCubit>().addLocalAlert(alertEvent);
        }
      });
    } else {
      service.stop();
    }
  }

  void _toggleSnatch(bool enabled) {
    setState(() => _snatchEnabled = enabled);
    _appSettings.put('snatch_enabled', enabled);
    final service = getIt<SnatchDetectionService>();
    if (enabled) {
      service.start(onSnatchDetected: (confidence) {
        // Snatch is critical — auto-trigger SOS countdown.
        if (mounted) {
          context.read<SosCubit>().startCountdown();
        }
        // Also inject into alert pipeline.
        final alertEvent = AlertEvent(
          id: 'snatch_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.phoneSnatching,
          title: 'Phone Snatch Detected',
          description:
              'A sudden directional grab was detected '
              '(confidence: ${(confidence * 100).toStringAsFixed(0)}%). '
              'SOS countdown started.',
          latitude: _lastLat,
          longitude: _lastLon,
          timestamp: DateTime.now(),
          source: 'On-Device Accelerometer',
          magnitude: confidence,
        );
        if (mounted) {
          context.read<AlertsCubit>().addLocalAlert(alertEvent);
        }
      });
    } else {
      service.stop();
    }
  }

  void _toggleSpeedAlert(bool enabled) {
    setState(() => _speedAlertEnabled = enabled);
    _appSettings.put('speed_alert_enabled', enabled);
    final service = getIt<SpeedAlertService>();
    if (enabled) {
      service.start(onSpeedExceeded: (speedKmh) {
        final alertEvent = AlertEvent(
          id: 'speed_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.speedWarning,
          title: 'Overspeeding: ${speedKmh.toStringAsFixed(0)} km/h',
          description:
              'Your speed exceeded the safe limit '
              '(${speedKmh.toStringAsFixed(0)} km/h). Slow down.',
          latitude: _lastLat,
          longitude: _lastLon,
          timestamp: DateTime.now(),
          source: 'On-Device GPS',
          magnitude: speedKmh,
        );
        if (mounted) {
          context.read<AlertsCubit>().addLocalAlert(alertEvent);
        }
      });
    } else {
      service.stop();
    }
  }

  void _toggleContextAlert(bool enabled) {
    setState(() => _contextAlertEnabled = enabled);
    _appSettings.put('context_alert_enabled', enabled);
    final service = getIt<ContextAlertService>();
    if (enabled) {
      service.start(onContextAlert: (ctxAlert) {
        // Map ContextAlertType to AlertType.
        final alertType = _mapContextAlertType(ctxAlert.type);
        final alertEvent = AlertEvent(
          id: 'ctx_${ctxAlert.type.name}_${DateTime.now().millisecondsSinceEpoch}',
          type: alertType,
          title: ctxAlert.title,
          description: ctxAlert.message,
          latitude: _lastLat,
          longitude: _lastLon,
          timestamp: DateTime.now(),
          source: 'On-Device Context',
        );
        if (mounted) {
          context.read<AlertsCubit>().addLocalAlert(alertEvent);
        }
      });
    } else {
      service.stop();
    }
  }

  /// Map ContextAlertType → AlertType for pipeline integration.
  AlertType _mapContextAlertType(ContextAlertType type) {
    return switch (type) {
      ContextAlertType.heatStroke => AlertType.heatStroke,
      ContextAlertType.hypothermia => AlertType.hypothermia,
      ContextAlertType.drowsyDriving => AlertType.drowsyDriving,
      ContextAlertType.loneNightWalk => AlertType.suspiciousActivity,
      ContextAlertType.altitudeSickness => AlertType.avalanche,
      ContextAlertType.flashFloodRisk => AlertType.flood,
    };
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
              if (_lockEnabled)
                _SettingsTile(
                  icon: Icons.pin_rounded,
                  title: l.changePinTitle,
                  subtitle: l.changePinDesc,
                  onTap: _changePin,
                ),
              _SettingsTile(
                icon: Icons.car_crash_rounded,
                title: l.crashFallDetection,
                subtitle: l.crashFallDetectionDesc,
                onTap: () => _toggleCrashFall(!_crashFallEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      onPressed: _showSensitivitySettings,
                      tooltip: l.sensitivitySettings,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    Switch(
                      value: _crashFallEnabled,
                      onChanged: _toggleCrashFall,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.my_location_rounded,
                title: l.geofenceTitle,
                subtitle: l.geofenceDesc,
                onTap: () => _toggleGeofence(!_geofenceEnabled),
                trailing: Switch(
                  value: _geofenceEnabled,
                  onChanged: _toggleGeofence,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.pan_tool_rounded,
                title: l.snatchTitle,
                subtitle: l.snatchDesc,
                onTap: () => _toggleSnatch(!_snatchEnabled),
                trailing: Switch(
                  value: _snatchEnabled,
                  onChanged: _toggleSnatch,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.speed_rounded,
                title: l.speedAlertTitle,
                subtitle: l.speedAlertDesc,
                onTap: () => _toggleSpeedAlert(!_speedAlertEnabled),
                trailing: Switch(
                  value: _speedAlertEnabled,
                  onChanged: _toggleSpeedAlert,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.psychology_rounded,
                title: l.contextAlertTitle,
                subtitle: l.contextAlertDesc,
                onTap: () => _toggleContextAlert(!_contextAlertEnabled),
                trailing: Switch(
                  value: _contextAlertEnabled,
                  onChanged: _toggleContextAlert,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: l.sosHistory,
                subtitle: l.sosHistoryDesc,
                onTap: () => context.push(AppRoutes.sosHistory),
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
                  final themeCubit = getIt<ThemeCubit>();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l.chooseTheme),
                      content: RadioGroup<ThemeMode>(
                        groupValue: themeCubit.state,
                        onChanged: (v) {
                          if (v == null) return;
                          themeCubit.setTheme(v);
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text(l.themeSystem),
                              value: ThemeMode.system,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(l.themeLight),
                              value: ThemeMode.light,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(l.themeDark),
                              value: ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
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
