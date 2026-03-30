import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../../core/constants/alert_types.dart';
import '../../data/models/alert_event.dart';
import '../../detection/ml/crash_fall_detection_service.dart';
import '../services/connectivity_service.dart';
import '../services/context_alert_service.dart';
import '../services/geofence_service.dart';
import '../services/location_service.dart';
import '../services/shake_detection_service.dart';
import '../services/snatch_detection_service.dart';
import '../services/speed_alert_service.dart';
import '../services/weather_feed_service.dart';
import '../services/app_logger.dart';
import '../services/sos_foreground_service.dart';
import '../../services/dead_man_switch_service.dart';
import '../../core/services/voice_distress_service.dart';
import '../../core/services/anomaly_movement_service.dart';
import '../../core/services/road_condition_service.dart';
import '../../core/services/sos_contact_alert_listener.dart';
import '../../presentation/blocs/alerts/alerts_cubit.dart';
import '../../presentation/blocs/battery/battery_cubit.dart';
import '../../presentation/blocs/sos/sos_cubit.dart';

/// Restores all detection services on app startup based on persisted Hive state.
///
/// This solves the critical re-hydration bug: when the app restarts, the
/// Settings screen reads Hive toggle states for UI display, but the actual
/// services were never started. This class bridges that gap by reading
/// the same Hive keys and starting services with proper callback wiring.
///
/// Must be called AFTER [configureDependencies] and AFTER BLoC providers are
/// created (i.e., inside the widget tree or after cubits are registered as
/// singletons).
class ServiceBootstrapper {
  ServiceBootstrapper._();

  static StreamSubscription<DetectionAlert>? _crashSubscription;

  /// Bootstrap all services based on persisted Hive state.
  ///
  /// [sl] is the GetIt service locator.
  /// [settings] is the Hive 'app_settings' box.
  static Future<void> bootstrap({
    required GetIt sl,
    required Box settings,
  }) async {
    AppLogger.info('[ServiceBootstrapper] Starting service re-hydration...');

    try {
      sl<ConnectivityService>().startMonitoring(
        onChanged: (isOnline) {
          AppLogger.info(
            '[ConnectivityService] Network status: '
            '${isOnline ? "ONLINE" : "OFFLINE"}',
          );
        },
      );
      AppLogger.info('[ServiceBootstrapper] ConnectivityService started');
    } catch (e) {
      AppLogger.warning('[ServiceBootstrapper] ConnectivityService failed: $e');
    }

    try {
      await sl<SosContactAlertListener>().startListening();
      AppLogger.info('[ServiceBootstrapper] SosContactAlertListener started');
    } catch (e) {
      AppLogger.warning('[ServiceBootstrapper] SosContactAlertListener failed: $e');
    }

    // Helper to get current GPS coordinates.
    double lastLat() =>
        sl<LocationService>().lastPosition?.latitude ?? 0.0;
    double lastLon() =>
        sl<LocationService>().lastPosition?.longitude ?? 0.0;

    if (_isEnabled(settings, 'shake_enabled')) {
      try {
        sl<ShakeDetectionService>().startListening(
          onShakeDetected: () => sl<SosCubit>().startCountdown(),
        );
        AppLogger.info('[ServiceBootstrapper] ShakeDetection re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] ShakeDetection failed: $e');
      }
    }

    if (_isEnabled(settings, 'crash_fall_enabled')) {
      try {
        final service = sl<CrashFallDetectionService>();
        await service.start();
        _crashSubscription?.cancel();
        _crashSubscription = service.alerts.listen((detectionAlert) {
          final alertEvent = AlertEvent(
            id: 'crash_${DateTime.now().millisecondsSinceEpoch}',
            type: detectionAlert.alertType,
            title: detectionAlert.title,
            description: detectionAlert.message,
            latitude: lastLat(),
            longitude: lastLon(),
            timestamp: detectionAlert.timestamp,
            source: 'On-Device Accelerometer',
            magnitude: detectionAlert.peakGForce,
          );
          sl<AlertsCubit>().addLocalAlert(alertEvent);

          // Auto-trigger SOS for vehicle crashes.
          if (detectionAlert.alertType == AlertType.carAccident ||
              detectionAlert.alertType == AlertType.motorcycleCrash ||
              detectionAlert.alertType == AlertType.pedestrianHit) {
            sl<SosCubit>().startCountdown();
          }
        });
        AppLogger.info('[ServiceBootstrapper] CrashFallDetection re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] CrashFallDetection failed: $e');
      }
    }

    if (_isEnabled(settings, 'geofence_enabled')) {
      try {
        final service = sl<GeofenceService>();
        service.loadZones(settings);
        service.start(onExitAllZones: (position) {
          // Build zone name from the service's loaded zones.
          final zoneNames = service.zones.map((z) => z.name).join(', ');
          final displayName =
              zoneNames.isNotEmpty ? zoneNames : 'Safe Zone';
          final alertEvent = AlertEvent(
            id: 'geofence_exit_${DateTime.now().millisecondsSinceEpoch}',
            type: AlertType.geofenceExit,
            title: 'Left Safe Zone: $displayName',
            description:
                'You have left the designated safe zone "$displayName". '
                'Your emergency contacts have been notified.',
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            source: 'On-Device GPS',
          );
          sl<AlertsCubit>().addLocalAlert(alertEvent);
        });
        AppLogger.info('[ServiceBootstrapper] Geofence re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] Geofence failed: $e');
      }
    }

    if (_isEnabled(settings, 'snatch_enabled')) {
      try {
        sl<SnatchDetectionService>().start(
          onSnatchDetected: (peakG) {
            sl<SosCubit>().startCountdown();
            final alertEvent = AlertEvent(
              id: 'snatch_${DateTime.now().millisecondsSinceEpoch}',
              type: AlertType.phoneSnatching,
              title: 'Phone Snatch Detected',
              description:
                  'A sudden directional grab was detected '
                  '(peak: ${peakG.toStringAsFixed(1)}G). '
                  'SOS countdown started.',
              latitude: lastLat(),
              longitude: lastLon(),
              timestamp: DateTime.now(),
              source: 'On-Device Accelerometer',
              magnitude: peakG,
            );
            sl<AlertsCubit>().addLocalAlert(alertEvent);
          },
        );
        AppLogger.info('[ServiceBootstrapper] SnatchDetection re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] SnatchDetection failed: $e');
      }
    }

    if (_isEnabled(settings, 'speed_alert_enabled')) {
      try {
        // Wire speed data into CrashFallDetectionService for improved
        // crash-vs-fall classification (speed context).
        final crashService = sl<CrashFallDetectionService>();

        sl<SpeedAlertService>().start(
          onSpeedExceeded: (speedKmh) {
            final alertEvent = AlertEvent(
              id: 'speed_${DateTime.now().millisecondsSinceEpoch}',
              type: AlertType.speedWarning,
              title: 'Overspeeding: ${speedKmh.toStringAsFixed(0)} km/h',
              description:
                  'Your speed exceeded the safe limit '
                  '(${speedKmh.toStringAsFixed(0)} km/h). Slow down.',
              latitude: lastLat(),
              longitude: lastLon(),
              timestamp: DateTime.now(),
              source: 'On-Device GPS',
              magnitude: speedKmh,
            );
            sl<AlertsCubit>().addLocalAlert(alertEvent);
          },
          // Cross-service wiring: feed live speed into crash/fall detector
          // so it can differentiate vehicle crash (high speed) from
          // pedestrian fall (walking speed).
          // Also feed into road condition classifier for context-aware detection.
          onSpeedUpdate: (speedKmh) {
            crashService.currentSpeedKmh = speedKmh;
            sl<RoadConditionService>().updateSpeed(speedKmh);
          },
        );
        AppLogger.info('[ServiceBootstrapper] SpeedAlert re-hydrated (+ crash feed)');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] SpeedAlert failed: $e');
      }
    }

    if (_isEnabled(settings, 'context_alert_enabled')) {
      try {
        sl<WeatherFeedService>().start();
        sl<ContextAlertService>().start(
          onContextAlert: (ctxAlert) {
            final alertType = _mapContextAlertType(ctxAlert.type);
            final alertEvent = AlertEvent(
              id: 'ctx_${ctxAlert.type.name}_${DateTime.now().millisecondsSinceEpoch}',
              type: alertType,
              title: ctxAlert.title,
              description: ctxAlert.message,
              latitude: lastLat(),
              longitude: lastLon(),
              timestamp: DateTime.now(),
              source: 'On-Device Context',
            );
            sl<AlertsCubit>().addLocalAlert(alertEvent);
          },
        );
        AppLogger.info('[ServiceBootstrapper] ContextAlert re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] ContextAlert failed: $e');
      }
    }

    if (_isEnabled(settings, 'dead_man_switch_enabled')) {
      try {
        final intervalMinutes =
            settings.get('dms_interval_minutes', defaultValue: 30) as int;
        sl<DeadManSwitchService>()
            .startWithInterval(Duration(minutes: intervalMinutes));
        AppLogger.info(
            '[ServiceBootstrapper] DeadManSwitch re-hydrated (${intervalMinutes}min)');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] DeadManSwitch failed: $e');
      }
    }

    if (_isEnabled(settings, 'voice_distress_enabled')) {
      try {
        final voiceService = sl<VoiceDistressService>();
        await voiceService.start();
        voiceService.onDistressDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'voice_distress_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Voice Distress Detected',
            description:
                'A distress vocalization was detected '
                '(confidence: ${(event.confidence * 100).toStringAsFixed(0)}%). '
                'SOS countdown started.',
            latitude: lastLat(),
            longitude: lastLon(),
            timestamp: event.detectedAt,
            source: 'On-Device Microphone',
            magnitude: event.confidence,
          );
          sl<AlertsCubit>().addLocalAlert(alertEvent);
          sl<SosCubit>().startCountdown();
        });
        AppLogger.info('[ServiceBootstrapper] VoiceDistress re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] VoiceDistress failed: $e');
      }
    }

    if (_isEnabled(settings, 'anomaly_movement_enabled')) {
      try {
        final movService = sl<AnomalyMovementService>();
        await movService.start();
        movService.onAnomalyDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'anomaly_mov_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Suspicious Movement: ${event.result.predictedClass.name}',
            description:
                'Anomalous movement pattern detected '
                '(${event.result.predictedClass.name}, '
                'confidence: ${(event.result.confidence * 100).toStringAsFixed(0)}%). '
                'SOS countdown started.',
            latitude: lastLat(),
            longitude: lastLon(),
            timestamp: event.detectedAt,
            source: 'On-Device Accelerometer',
            magnitude: event.result.confidence,
          );
          sl<AlertsCubit>().addLocalAlert(alertEvent);
          sl<SosCubit>().startCountdown();
        });
        AppLogger.info('[ServiceBootstrapper] AnomalyMovement re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] AnomalyMovement failed: $e');
      }
    }

    if (_isEnabled(settings, 'road_condition_enabled')) {
      try {
        final roadService = sl<RoadConditionService>();
        await roadService.start();
        roadService.onHazardDetected.listen((event) {
          final alertEvent = AlertEvent(
            id: 'road_${event.result.condition.name}_${DateTime.now().millisecondsSinceEpoch}',
            type: event.alertType,
            title: 'Road Hazard: ${event.result.condition.name}',
            description:
                'A road hazard was detected at '
                '${event.result.speedKmh.toStringAsFixed(0)} km/h '
                '(${event.result.condition.name}, '
                'confidence: ${(event.result.confidence * 100).toStringAsFixed(0)}%).',
            latitude: lastLat(),
            longitude: lastLon(),
            timestamp: event.detectedAt,
            source: 'On-Device Accelerometer + GPS',
            magnitude: event.result.confidence,
          );
          sl<AlertsCubit>().addLocalAlert(alertEvent);
        });
        AppLogger.info('[ServiceBootstrapper] RoadCondition re-hydrated');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] RoadCondition failed: $e');
      }
    }

    try {
      sl<BatteryCubit>().startMonitoring();
      AppLogger.info('[ServiceBootstrapper] BatteryMonitor started');
    } catch (e) {
      AppLogger.warning('[ServiceBootstrapper] BatteryMonitor failed: $e');
    }

    final anyDetectionEnabled = _countEnabled(settings) > 0;
    if (anyDetectionEnabled) {
      try {
        await SosForegroundService.instance.start();
        AppLogger.info('[ServiceBootstrapper] ForegroundService started');
      } catch (e) {
        AppLogger.warning('[ServiceBootstrapper] ForegroundService failed: $e');
      }
    }

    final count = _countEnabled(settings);
    AppLogger.info(
      '[ServiceBootstrapper] Re-hydration complete. '
      '$count service(s) restored.',
    );
  }

  /// Dispose resources managed by the bootstrapper.
  static void dispose() {
    _crashSubscription?.cancel();
    _crashSubscription = null;
  }

  static bool _isEnabled(Box settings, String key) =>
      settings.get(key, defaultValue: false) as bool;

  static int _countEnabled(Box settings) {
    const keys = [
      'shake_enabled',
      'crash_fall_enabled',
      'geofence_enabled',
      'snatch_enabled',
      'speed_alert_enabled',
      'context_alert_enabled',
      'dead_man_switch_enabled',
      'voice_distress_enabled',
      'anomaly_movement_enabled',
      'road_condition_enabled',
    ];
    return keys.where((k) => _isEnabled(settings, k)).length;
  }

  /// Map ContextAlertType → AlertType via canonical single-source method.
  static AlertType _mapContextAlertType(ContextAlertType type) {
    return ContextAlertService.mapToAlertType(type);
  }
}
