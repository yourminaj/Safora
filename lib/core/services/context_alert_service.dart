import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../constants/alert_types.dart';
import 'app_logger.dart';

/// Smart context-aware alert service that combines GPS, weather, and time
/// to generate composite risk alerts.
///
/// This service runs periodically and checks for conditions that no single
/// sensor or API can detect alone:
///
/// - **Heat stroke risk**: High temperature + outdoor GPS activity
/// - **Hypothermia risk**: Low temperature + outdoor GPS activity
/// - **Drowsy driving**: Night-time + high-speed GPS movement
/// - **Lone walkout**: Late night + walking speed + no movement for 5+ min
/// - **Altitude sickness**: Rapid altitude change (>500m in 30 min)
/// - **Flooding risk**: Heavy rain forecast + user in low-elevation area
class ContextAlertService {
  ContextAlertService({
    this.checkIntervalMinutes = 5,
  });

  /// How often to run context checks (in minutes).
  final int checkIntervalMinutes;

  Timer? _checkTimer;
  double? _lastAltitude;
  DateTime? _lastAltitudeTime;
  final Map<ContextAlertType, DateTime> _lastAlertTimes = {};

  /// External data injected before each check cycle.
  double? currentTemperatureCelsius;
  double? currentWindSpeedKmh;
  double? currentUvIndex;
  double? currentSpeedKmh;
  double? currentPrecipitationMm;

  bool get isRunning => _checkTimer != null;

  /// Start context monitoring.
  ///
  /// [onContextAlert] is called when a composite risk is detected.
  /// Each alert includes a type string and a human-readable message.
  void start({
    required void Function(ContextAlert alert) onContextAlert,
  }) {
    if (_checkTimer != null) return;

    _checkTimer = Timer.periodic(
      Duration(minutes: checkIntervalMinutes),
      (_) => _runChecks(onContextAlert),
    );

    AppLogger.info(
      '[ContextAlert] Started (interval: ${checkIntervalMinutes}min)',
    );
  }

  /// Stop context monitoring.
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    AppLogger.info('[ContextAlert] Stopped');
  }

  Future<void> _runChecks(
    void Function(ContextAlert alert) onAlert,
  ) async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      final position = await _getCurrentPosition();

      // High temp + UV + outdoor movement
      if (currentTemperatureCelsius != null &&
          currentTemperatureCelsius! > 35 &&
          currentSpeedKmh != null &&
          currentSpeedKmh! > 2) {
        _emitIfCooldown(
          onAlert,
          ContextAlert(
            type: ContextAlertType.heatStroke,
            title: 'Heat Stroke Risk',
            message:
                'Temperature is ${currentTemperatureCelsius!.toStringAsFixed(0)}°C '
                'and you are active outdoors. '
                'Stay hydrated and seek shade.',
            severity: currentTemperatureCelsius! > 42
                ? ContextSeverity.critical
                : ContextSeverity.warning,
          ),
        );
      }

      // Low temp + outdoor movement + wind chill
      if (currentTemperatureCelsius != null &&
          currentTemperatureCelsius! < -5 &&
          currentSpeedKmh != null &&
          currentSpeedKmh! > 1) {
        final windChill = _calculateWindChill(
          currentTemperatureCelsius!,
          currentWindSpeedKmh ?? 0,
        );
        _emitIfCooldown(
          onAlert,
          ContextAlert(
            type: ContextAlertType.hypothermia,
            title: 'Hypothermia Risk',
            message:
                'Temperature: ${currentTemperatureCelsius!.toStringAsFixed(0)}°C, '
                'Wind chill: ${windChill.toStringAsFixed(0)}°C. '
                'Seek warm shelter immediately.',
            severity: windChill < -25
                ? ContextSeverity.critical
                : ContextSeverity.warning,
          ),
        );
      }

      // Night time (11 PM – 5 AM) + driving speed (>50 km/h)
      if ((hour >= 23 || hour < 5) &&
          currentSpeedKmh != null &&
          currentSpeedKmh! > 50) {
        _emitIfCooldown(
          onAlert,
          ContextAlert(
            type: ContextAlertType.drowsyDriving,
            title: 'Drowsy Driving Alert',
            message:
                'It\'s ${now.hour}:${now.minute.toString().padLeft(2, "0")} '
                'and you\'re traveling at '
                '${currentSpeedKmh!.toStringAsFixed(0)} km/h. '
                'Consider pulling over for a rest.',
            severity: ContextSeverity.warning,
          ),
        );
      }

      // Late night (10 PM – 4 AM) + walking speed (2–7 km/h)
      if ((hour >= 22 || hour < 4) &&
          currentSpeedKmh != null &&
          currentSpeedKmh! > 2 &&
          currentSpeedKmh! < 7) {
        _emitIfCooldown(
          onAlert,
          const ContextAlert(
            type: ContextAlertType.loneNightWalk,
            title: 'Late Night Walking',
            message:
                'You are walking alone late at night. '
                'Share your live location with a trusted contact. '
                'Safora SOS is ready if needed.',
            severity: ContextSeverity.info,
          ),
        );
      }

      // Rapid altitude gain (>500m in 30 minutes)
      if (position != null) {
        final altitude = position.altitude;
        final now = DateTime.now();

        if (_lastAltitude != null && _lastAltitudeTime != null) {
          final altChange = altitude - _lastAltitude!;
          final timeDiff = now.difference(_lastAltitudeTime!).inMinutes;

          if (timeDiff > 0 && timeDiff <= 30 && altChange > 500) {
            _emitIfCooldown(
              onAlert,
              ContextAlert(
                type: ContextAlertType.altitudeSickness,
                title: 'Rapid Altitude Change',
                message:
                    'You\'ve gained ${altChange.toStringAsFixed(0)}m in '
                    '$timeDiff minutes. Watch for symptoms: '
                    'headache, nausea, dizziness.',
                severity: ContextSeverity.warning,
              ),
            );
          }
        }

        _lastAltitude = altitude;
        _lastAltitudeTime = now;
      }

      // Heavy rain forecast + low elevation
      if (currentPrecipitationMm != null &&
          currentPrecipitationMm! > 30 &&
          position != null &&
          position.altitude < 50) {
        _emitIfCooldown(
          onAlert,
          ContextAlert(
            type: ContextAlertType.flashFloodRisk,
            title: 'Flash Flood Risk',
            message:
                'Heavy rainfall (${currentPrecipitationMm!.toStringAsFixed(0)}mm) '
                'forecast and you\'re at low elevation '
                '(${position.altitude.toStringAsFixed(0)}m). '
                'Move to higher ground.',
            severity: ContextSeverity.critical,
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('[ContextAlert] Check cycle failed: $e');
    }
  }

  void _emitIfCooldown(
    void Function(ContextAlert) onAlert,
    ContextAlert alert,
  ) {
    final now = DateTime.now();
    // 10-minute cooldown per alert type (not global).
    final lastTime = _lastAlertTimes[alert.type];
    if (lastTime != null && now.difference(lastTime).inMinutes < 10) {
      return;
    }
    _lastAlertTimes[alert.type] = now;
    onAlert(alert);
    AppLogger.info('[ContextAlert] Emitted: ${alert.type.name}');
  }

  /// Wind chill calculation (Environment Canada formula).
  static double _calculateWindChill(double tempC, double windKmh) {
    if (windKmh < 5) return tempC;
    return 13.12 +
        0.6215 * tempC -
        11.37 * math.pow(windKmh, 0.16) +
        0.3965 * tempC * math.pow(windKmh, 0.16);
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stop();
  }

  /// Canonical mapping from [ContextAlertType] → [AlertType].
  ///
  /// Used by both `ServiceBootstrapper` and `SettingsScreen` to
  /// ensure a single source of truth for type translation.
  static AlertType mapToAlertType(ContextAlertType type) {
    return switch (type) {
      ContextAlertType.heatStroke => AlertType.heatStroke,
      ContextAlertType.hypothermia => AlertType.hypothermia,
      ContextAlertType.drowsyDriving => AlertType.drowsyDriving,
      ContextAlertType.loneNightWalk => AlertType.suspiciousActivity,
      ContextAlertType.altitudeSickness => AlertType.altitudeSickness,
      ContextAlertType.flashFloodRisk => AlertType.flood,
    };
  }
}

/// Types of context-aware alerts.
enum ContextAlertType {
  heatStroke,
  hypothermia,
  drowsyDriving,
  loneNightWalk,
  altitudeSickness,
  flashFloodRisk,
}

/// Severity levels for context alerts.
enum ContextSeverity {
  info,
  warning,
  critical,
}

/// A composite context-aware alert.
class ContextAlert {
  const ContextAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
  });

  final ContextAlertType type;
  final String title;
  final String message;
  final ContextSeverity severity;
}
