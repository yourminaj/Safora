import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../widgets/safora_animated_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safora/l10n/app_localizations.dart';
import '../../../app.dart';
import '../../../core/constants/alert_types.dart';
import '../../../data/models/alert_event.dart';
import '../../../core/services/premium_manager.dart';
import '../../../core/services/subscription_service.dart';
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
import '../../../core/services/weather_feed_service.dart';
import '../../../core/services/voice_distress_service.dart';
import '../../../core/services/anomaly_movement_service.dart';
import '../../../core/services/road_condition_service.dart';
import '../../../injection.dart';
import '../../../services/dead_man_switch_service.dart';
import '../../blocs/contacts/contacts_cubit.dart';
import '../../blocs/contacts/contacts_state.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/sos/sos_cubit.dart';
import '../../blocs/theme/theme_cubit.dart';

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
  double get _lastLon =>
      getIt<LocationService>().lastPosition?.longitude ?? 0.0;

  bool _shakeEnabled = false;
  bool _lockEnabled = false;
  bool _crashFallEnabled = false;
  bool _geofenceEnabled = false;
  bool _snatchEnabled = false;
  bool _speedAlertEnabled = false;
  bool _contextAlertEnabled = false;
  bool _dmsEnabled = false;
  int _dmsIntervalMinutes = 30;
  bool _voiceDistressEnabled = false;
  bool _anomalyMovementEnabled = false;
  bool _roadConditionEnabled = false;
  late final ShakeDetectionService _shakeService;
  late final AppLockService _lockService;
  late final Box _appSettings;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _shakeService = getIt<ShakeDetectionService>();
    _lockService = getIt<AppLockService>();
    _appSettings = getIt<Box>(instanceName: 'app_settings');
    // Restore persisted state.
    _shakeEnabled =
        _appSettings.get('shake_enabled', defaultValue: false) as bool;
    _lockEnabled = _lockService.isLockEnabled;
    _crashFallEnabled =
        _appSettings.get('crash_fall_enabled', defaultValue: false) as bool;
    _geofenceEnabled =
        _appSettings.get('geofence_enabled', defaultValue: false) as bool;
    _snatchEnabled =
        _appSettings.get('snatch_enabled', defaultValue: false) as bool;
    _speedAlertEnabled =
        _appSettings.get('speed_alert_enabled', defaultValue: false) as bool;
    _contextAlertEnabled =
        _appSettings.get('context_alert_enabled', defaultValue: false) as bool;
    _dmsEnabled =
        _appSettings.get('dead_man_switch_enabled', defaultValue: false) as bool;
    _dmsIntervalMinutes =
        _appSettings.get('dms_interval_minutes', defaultValue: 30) as int;
    _voiceDistressEnabled =
        _appSettings.get('voice_distress_enabled', defaultValue: false) as bool;
    _anomalyMovementEnabled =
        _appSettings.get('anomaly_movement_enabled', defaultValue: false) as bool;
    _roadConditionEnabled =
        _appSettings.get('road_condition_enabled', defaultValue: false) as bool;
    // Load version from pubspec (single source of truth).
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  void dispose() {
    _crashSubscription?.cancel();
    _voiceSubscription?.cancel();
    _anomalySubscription?.cancel();
    _roadSubscription?.cancel();
    super.dispose();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.lockEnabled)));
        }
      }
    } else {
      // Verify current PIN before disabling.
      final verified = await _showPinVerifyDialog(l);
      if (verified && mounted) {
        await _lockService.disableLock();
        setState(() => _lockEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.lockDisabled)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.changePinSuccess)));
      }
    }
  }

  StreamSubscription<DetectionAlert>? _crashSubscription;
  StreamSubscription<VoiceDistressEvent>? _voiceSubscription;
  StreamSubscription<AnomalyMovementEvent>? _anomalySubscription;
  StreamSubscription<RoadConditionEvent>? _roadSubscription;

  /// Small PRO badge widget for premium-gated features.
  Widget _proBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _toggleCrashFall(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.crashFallDetection,
        )) {
      _showUpgradeDialog();
      return;
    }
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
    double fallG =
        _appSettings.get('fall_threshold_g', defaultValue: 3.0) as double;
    double crashG =
        _appSettings.get('crash_threshold_g', defaultValue: 4.0) as double;
    double minConf =
        _appSettings.get('min_confidence', defaultValue: 0.5) as double;

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
                24,
                20,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      Text(
                        l.sensitivitySettings,
                        style: AppTypography.titleMedium,
                      ),
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
                        child: Text(
                          '${fallG.toStringAsFixed(1)}G',
                          style: AppTypography.bodySmall,
                        ),
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
                        child: Text(
                          '${crashG.toStringAsFixed(1)}G',
                          style: AppTypography.bodySmall,
                        ),
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
                        child: Text(
                          '${(minConf * 100).toInt()}%',
                          style: AppTypography.bodySmall,
                        ),
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
                            if (getIt
                                .isRegistered<CrashFallDetectionService>()) {
                              getIt.unregister<CrashFallDetectionService>();
                            }
                            getIt.registerLazySingleton<
                              CrashFallDetectionService
                            >(
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

  /// Show upgrade dialog for Pro-only features.
  void _showUpgradeDialog() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.proFeatureTitle),
        content: Text(l.proFeatureMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.paywall);
            },
            child: Text(l.upgradeToPro),
          ),
        ],
      ),
    );
  }

  void _toggleGeofence(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.unlimitedGeofenceZones,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _geofenceEnabled = enabled);
    _appSettings.put('geofence_enabled', enabled);
    final service = getIt<GeofenceService>();
    if (enabled) {
      service.start(
        onExitAllZones: (position) {
          final l = AppLocalizations.of(context)!;
          final zoneName =
              l.geofenceTitle; // generic; API provides Position not name
          // Inject into main alert pipeline.
          final alertEvent = AlertEvent(
            id: 'geofence_exit_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.geofenceExit,
            title: l.alertGeofenceExitTitle(zoneName),
            description: l.alertGeofenceExitDesc(zoneName),
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            source: 'On-Device GPS',
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
          }
        },
      );
    } else {
      service.stop();
    }
  }

  void _toggleSnatch(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.snatchDetection,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _snatchEnabled = enabled);
    _appSettings.put('snatch_enabled', enabled);
    final service = getIt<SnatchDetectionService>();
    if (enabled) {
      service.start(
        onSnatchDetected: (confidence) {
          final l = AppLocalizations.of(context)!;
          // Snatch is critical — auto-trigger SOS countdown.
          if (mounted) {
            context.read<SosCubit>().startCountdown();
          }
          // Also inject into alert pipeline.
          final pct = (confidence * 100).toStringAsFixed(0);
          final alertEvent = AlertEvent(
            id: 'snatch_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.phoneSnatching,
            title: l.alertSnatchTitle,
            description: l.alertSnatchDesc(pct),
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: DateTime.now(),
            source: 'On-Device Accelerometer',
            magnitude: confidence,
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
          }
        },
      );
    } else {
      service.stop();
    }
  }

  void _toggleSpeedAlert(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(ProFeature.speedAlert)) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _speedAlertEnabled = enabled);
    _appSettings.put('speed_alert_enabled', enabled);
    final service = getIt<SpeedAlertService>();
    if (enabled) {
      final crashService = getIt<CrashFallDetectionService>();
      service.start(
        onSpeedExceeded: (speedKmh) {
          final l = AppLocalizations.of(context)!;
          final speedStr = speedKmh.toStringAsFixed(0);
          final alertEvent = AlertEvent(
            id: 'speed_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.speedWarning,
            title: l.alertSpeedTitle(speedStr),
            description: l.alertSpeedDesc(speedStr),
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: DateTime.now(),
            source: 'On-Device GPS',
            magnitude: speedKmh,
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
          }
        },
        // Cross-service wiring: feed live speed into crash/fall detector.
        onSpeedUpdate: (speedKmh) {
          crashService.currentSpeedKmh = speedKmh;
        },
      );
    } else {
      service.stop();
    }
  }

  void _toggleContextAlert(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(ProFeature.contextAlerts)) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _contextAlertEnabled = enabled);
    _appSettings.put('context_alert_enabled', enabled);
    final service = getIt<ContextAlertService>();
    final feed = getIt<WeatherFeedService>();
    if (enabled) {
      // Start app-level weather feed (persists across navigation).
      feed.start();
      service.start(
        onContextAlert: (ctxAlert) {
          // Map ContextAlertType to AlertType.
          final alertType = _mapContextAlertType(ctxAlert.type);
          // Localize title/message at display time.
          final localized = _localizeContextAlert(ctxAlert);
          final alertEvent = AlertEvent(
            id: 'ctx_${ctxAlert.type.name}_${DateTime.now().millisecondsSinceEpoch}',
            type: alertType,
            title: localized.$1,
            description: localized.$2,
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: DateTime.now(),
            source: 'On-Device Context',
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
          }
        },
      );
    } else {
      service.stop();
      feed.stop();
    }
  }

  void _toggleDms(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.deadManSwitch,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _dmsEnabled = enabled);
    _appSettings.put('dead_man_switch_enabled', enabled);
    final dms = getIt<DeadManSwitchService>();
    if (enabled) {
      dms.startWithInterval(Duration(minutes: _dmsIntervalMinutes));
    } else {
      dms.stop();
    }
  }

  void _changeDmsInterval(int minutes) {
    setState(() => _dmsIntervalMinutes = minutes);
    _appSettings.put('dms_interval_minutes', minutes);
    final dms = getIt<DeadManSwitchService>();
    if (_dmsEnabled) {
      dms.startWithInterval(Duration(minutes: minutes));
    }
  }

  /// Voice Distress Detection toggle — 16kHz PCM → Mel spectrogram → TFLite.
  void _toggleVoiceDistress(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.voiceDistressDetection,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _voiceDistressEnabled = enabled);
    _appSettings.put('voice_distress_enabled', enabled);
    final service = getIt<VoiceDistressService>();
    if (enabled) {
      service.start().then((_) {
        _voiceSubscription?.cancel();
        _voiceSubscription = service.onDistressDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'voice_distress_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Voice Distress Detected',
            description:
                'Distress vocalization detected '
                '(confidence: ${(event.confidence * 100).toStringAsFixed(0)}%). '
                'SOS countdown started.',
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: event.detectedAt,
            source: 'On-Device Microphone',
            magnitude: event.confidence,
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
            context.read<SosCubit>().startCountdown();
          }
        });
      });
    } else {
      _voiceSubscription?.cancel();
      _voiceSubscription = null;
      service.stop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Voice Distress Detection enabled'
              : 'Voice Distress Detection disabled',
        ),
      ),
    );
  }

  /// Anomaly Movement Detection toggle — 24-feature accel window → TFLite.
  void _toggleAnomalyMovement(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.anomalyMovementDetection,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _anomalyMovementEnabled = enabled);
    _appSettings.put('anomaly_movement_enabled', enabled);
    final service = getIt<AnomalyMovementService>();
    if (enabled) {
      service.start().then((_) {
        _anomalySubscription?.cancel();
        _anomalySubscription = service.onAnomalyDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'anomaly_mov_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Suspicious Movement: ${event.result.predictedClass.name}',
            description:
                'Anomalous movement detected '
                '(${event.result.predictedClass.name}, '
                'confidence: ${(event.result.confidence * 100).toStringAsFixed(0)}%). '
                'SOS countdown started.',
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: event.detectedAt,
            source: 'On-Device Accelerometer',
            magnitude: event.result.confidence,
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
            context.read<SosCubit>().startCountdown();
          }
        });
      });
    } else {
      _anomalySubscription?.cancel();
      _anomalySubscription = null;
      service.stop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Anomaly Movement Detection enabled'
              : 'Anomaly Movement Detection disabled',
        ),
      ),
    );
  }

  /// Road Condition Detection toggle — 8-feature accel+GPS vector → TFLite.
  void _toggleRoadCondition(bool enabled) {
    if (enabled &&
        !getIt<PremiumManager>().isFeatureAvailable(
          ProFeature.roadConditionDetection,
        )) {
      _showUpgradeDialog();
      return;
    }
    setState(() => _roadConditionEnabled = enabled);
    _appSettings.put('road_condition_enabled', enabled);
    final service = getIt<RoadConditionService>();
    if (enabled) {
      service.start().then((_) {
        _roadSubscription?.cancel();
        _roadSubscription = service.onHazardDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'road_${event.result.condition.name}_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Road Hazard: ${event.result.condition.name}',
            description:
                'Road hazard detected at '
                '${event.result.speedKmh.toStringAsFixed(0)} km/h '
                '(${event.result.condition.name}, '
                'confidence: ${(event.result.confidence * 100).toStringAsFixed(0)}%).',
            latitude: _lastLat,
            longitude: _lastLon,
            timestamp: event.detectedAt,
            source: 'On-Device Accelerometer + GPS',
            magnitude: event.result.confidence,
          );
          if (mounted) {
            context.read<AlertsCubit>().addLocalAlert(alertEvent);
          }
        });
      });
    } else {
      _roadSubscription?.cancel();
      _roadSubscription = null;
      service.stop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Road Condition Detection enabled'
              : 'Road Condition Detection disabled',
        ),
      ),
    );
  }

  /// Map ContextAlertType → AlertType via canonical single-source method.

  AlertType _mapContextAlertType(ContextAlertType type) {
    return ContextAlertService.mapToAlertType(type);
  }

  /// Localize context alert title + message at display time.
  /// Returns (localizedTitle, localizedMessage).
  (String, String) _localizeContextAlert(ContextAlert alert) {
    final l = AppLocalizations.of(context)!;
    return switch (alert.type) {
      ContextAlertType.heatStroke => (
        l.ctxHeatTitle,
        l.ctxHeatMsg(
          (getIt<ContextAlertService>().currentTemperatureCelsius ?? 0)
              .toStringAsFixed(0),
        ),
      ),
      ContextAlertType.hypothermia => (
        l.ctxHypothermiaTitle,
        l.ctxHypothermiaMsg(
          (getIt<ContextAlertService>().currentTemperatureCelsius ?? 0)
              .toStringAsFixed(0),
          '—', // wind chill unavailable at this point; use service message as fallback
        ),
      ),
      ContextAlertType.drowsyDriving => (
        l.ctxDrowsyTitle,
        l.ctxDrowsyMsg(
          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}',
          (getIt<ContextAlertService>().currentSpeedKmh ?? 0).toStringAsFixed(
            0,
          ),
        ),
      ),
      ContextAlertType.loneNightWalk => (
        l.ctxNightWalkTitle,
        l.ctxNightWalkMsg,
      ),
      ContextAlertType.altitudeSickness => (
        l.ctxAltitudeTitle,
        alert
            .message, // keep service-generated message (has precise altitude data)
      ),
      ContextAlertType.flashFloodRisk => (
        l.ctxFloodTitle,
        alert
            .message, // keep service-generated message (has precise precipitation data)
      ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.pinMismatch)));
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.wrongPin)));
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
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsSection(
            title: l.account,
            children: [

              _SettingsTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: AppColors.accent,
                title: l.premium,
                subtitle: l.unlockAllRiskTypes,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.accent,
                          ),
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
                          _iconText(
                            Icons.check_circle,
                            AppColors.success,
                            l.freeSos,
                          ),
                          _iconText(
                            Icons.check_circle,
                            AppColors.success,
                            l.freeContacts,
                          ),
                          _iconText(
                            Icons.check_circle,
                            AppColors.success,
                            l.freeAlerts,
                          ),
                          _iconText(
                            Icons.check_circle,
                            AppColors.success,
                            l.freeDetection,
                          ),
                          _iconText(
                            Icons.check_circle,
                            AppColors.success,
                            l.freeMedicalId,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.premiumRoadmap,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(AppRoutes.paywall);
                          },
                          icon: const Icon(Icons.workspace_premium),
                          label: Text(l.upgradeToPro),
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
                    iconColor: AppColors.secondary,
                    title: l.emergencyContacts,
                    subtitle: l.nContactsAdded(count),
                    onTap: () => context.go('/contacts'),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.vibration_rounded,
                iconColor: AppColors.primary,
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
                iconColor: AppColors.textSecondary,
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
                  iconColor: AppColors.textSecondary,
                  title: l.changePinTitle,
                  subtitle: l.changePinDesc,
                  onTap: _changePin,
                ),
              _SettingsTile(
                icon: Icons.car_crash_rounded,
                iconColor: AppColors.warning,
                title: l.crashFallDetection,
                subtitle: l.crashFallDetectionDesc,
                onTap: () => _toggleCrashFall(!_crashFallEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (getIt<PremiumManager>().isProOnly(
                          ProFeature.crashFallDetection,
                        ) &&
                        !getIt<PremiumManager>().isPremium)
                      _proBadge(),
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
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.my_location_rounded,
                iconColor: AppColors.success,
                title: l.geofenceTitle,
                subtitle: l.geofenceDesc,
                onTap: () => _toggleGeofence(!_geofenceEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _geofenceEnabled,
                      onChanged: _toggleGeofence,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.pan_tool_rounded,
                iconColor: AppColors.primary,
                title: l.snatchTitle,
                subtitle: l.snatchDesc,
                onTap: () => _toggleSnatch(!_snatchEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _snatchEnabled,
                      onChanged: _toggleSnatch,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.speed_rounded,
                iconColor: AppColors.info,
                title: l.speedAlertTitle,
                subtitle: l.speedAlertDesc,
                onTap: () => _toggleSpeedAlert(!_speedAlertEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _speedAlertEnabled,
                      onChanged: _toggleSpeedAlert,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.psychology_rounded,
                iconColor: AppColors.accent,
                title: l.contextAlertTitle,
                subtitle: l.contextAlertDesc,
                onTap: () => _toggleContextAlert(!_contextAlertEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _contextAlertEnabled,
                      onChanged: _toggleContextAlert,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.timer_rounded,
                iconColor: AppColors.error,
                title: 'Dead Man\'s Switch',
                subtitle: 'Auto-SOS if you don\'t check in',
                onTap: () => _toggleDms(!_dmsEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _dmsEnabled,
                      onChanged: _toggleDms,
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (_dmsEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in Interval',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [15, 30, 60].map((m) {
                            final isSelected = _dmsIntervalMinutes == m;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _changeDmsInterval(m),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.error
                                          : AppColors.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$m min',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              _SettingsTile(
                icon: Icons.record_voice_over_rounded,
                iconColor: const Color(0xFFE53935),
                customIcon: const SaforaVoiceDistressIcon(size: 30, animated: true),
                title: 'Voice Distress Detection',
                subtitle: 'ML detects screams & distress calls (microphone)',
                onTap: () => _toggleVoiceDistress(!_voiceDistressEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _voiceDistressEnabled,
                      onChanged: _toggleVoiceDistress,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.directions_run_rounded,
                iconColor: const Color(0xFF9C27B0),
                customIcon: const SaforaAnomalyMovementIcon(size: 30, animated: true),
                title: 'Anomaly Movement Detection',
                subtitle: 'ML detects struggling, dragging & falls (accelerometer)',
                onTap: () => _toggleAnomalyMovement(!_anomalyMovementEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _anomalyMovementEnabled,
                      onChanged: _toggleAnomalyMovement,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.construction_rounded,
                iconColor: const Color(0xFFFF6F00),
                customIcon: const SaforaRoadConditionIcon(size: 30, animated: true),
                title: 'Road Condition Detection',
                subtitle: 'ML detects potholes, rough roads & hard braking',
                onTap: () => _toggleRoadCondition(!_roadConditionEnabled),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!getIt<PremiumManager>().isPremium) _proBadge(),
                    Switch(
                      value: _roadConditionEnabled,
                      onChanged: _toggleRoadCondition,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              _SettingsTile(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF7E57C2),
                title: 'Alert Preferences',
                subtitle: 'Choose which alerts to receive',
                onTap: () => context.push(AppRoutes.alertPreferences),
              ),


              _SettingsTile(
                icon: Icons.volume_up_rounded,
                iconColor: AppColors.info,
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
                          _colorDotText(
                            AppColors.danger,
                            l.criticalSiren,
                            fontWeight: FontWeight.w600,
                          ),
                          _colorDotText(AppColors.warning, l.highMediumWarning),
                          _colorDotText(AppColors.success, l.lowNotification),
                          const SizedBox(height: 12),
                          Text(
                            l.customSoundFuture,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
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
                iconColor: AppColors.secondary,
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
                          _iconText(
                            Icons.smartphone,
                            null,
                            l.deviceSettingsLanguage,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.inAppLanguageFuture,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
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
                iconColor: AppColors.textSecondary,
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
              if (getIt<PremiumManager>().isPremium)
                _SettingsTile(
                  icon: Icons.card_membership_rounded,
                  iconColor: AppColors.accent,
                  title: 'Manage Subscription',
                  subtitle: 'View, change, or cancel your plan',
                  onTap: () {
                    getIt<SubscriptionService>().presentCustomerCenter();
                  },
                ),

            ],
          ),
          const Divider(height: 32),
          if (getIt<AuthService>().isSignedIn)
            _SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.danger,
              title: l.signOut,
              subtitle: getIt<AuthService>().currentUser?.email ?? '',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.signOut),
                    content: Text(l.signOutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.signOut),
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
              iconColor: AppColors.success,
              title: l.signIn,
              subtitle: l.signInSubtitle,
              onTap: () => context.go('/login'),
            ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'Safora',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appVersion.isNotEmpty ? _appVersion : '...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, Color? color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }

  Widget _colorDotText(Color dotColor, String text, {FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: fontWeight != null
                  ? TextStyle(fontWeight: fontWeight)
                  : null,
            ),
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
    this.iconColor,
    this.trailing,
    this.customIcon,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  /// When set, renders a custom branded widget (e.g. [SaforaVoiceDistressIcon])
  /// instead of the default [Icon]. Size it to ≈30×30 for best fit in the tile.
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final Widget leadingChild =
        customIcon ?? Icon(icon, color: color, size: 22);

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        padding: EdgeInsets.all(customIcon != null ? 6 : 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: leadingChild,
      ),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
