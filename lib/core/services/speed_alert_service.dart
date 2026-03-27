import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'app_logger.dart';

/// Monitors GPS speed and alerts when exceeding a threshold.
///
/// Uses [Geolocator.getPositionStream] for real-time speed data.
/// Speed is provided in m/s by the platform, converted to km/h.
class SpeedAlertService {
  SpeedAlertService({
    this.thresholdKmh = 120.0,
    this.cooldownDuration = const Duration(seconds: 60),
    this.notifyIntervalMs = 5000,
  });

  /// Speed threshold in km/h to trigger an alert.
  final double thresholdKmh;

  /// Cooldown between alerts to avoid spamming.
  final Duration cooldownDuration;

  /// Position update interval in milliseconds.
  final int notifyIntervalMs;

  StreamSubscription<Position>? _subscription;
  DateTime? _lastAlertTime;
  double _currentSpeedKmh = 0;

  /// Whether the service is actively monitoring.
  bool get isRunning => _subscription != null;

  /// Current speed in km/h.
  double get currentSpeedKmh => _currentSpeedKmh;

  /// Start monitoring GPS speed.
  ///
  /// [onSpeedExceeded] is called when speed exceeds [thresholdKmh],
  /// with the current speed in km/h.
  /// [onSpeedUpdate] is called on every GPS position update (for cross-
  /// service wiring, e.g. feeding speed into crash/fall classification).
  void start({
    required void Function(double speedKmh) onSpeedExceeded,
    void Function(double speedKmh)? onSpeedUpdate,
  }) {
    if (_subscription != null) return;

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Minimum 10m between updates.
      timeLimit: Duration(milliseconds: notifyIntervalMs),
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        // GPS speed is in m/s. Convert to km/h.
        _currentSpeedKmh = (position.speed >= 0)
            ? position.speed * 3.6
            : 0;

        // Broadcast speed to cross-service consumers.
        onSpeedUpdate?.call(_currentSpeedKmh);

        if (_currentSpeedKmh > thresholdKmh && _canAlert()) {
          _lastAlertTime = DateTime.now();
          onSpeedExceeded(_currentSpeedKmh);
          AppLogger.info(
            '[SpeedAlert] Speed alert: '
            '${_currentSpeedKmh.toStringAsFixed(1)} km/h > $thresholdKmh km/h',
          );
        }
      },
      onError: (Object error) {
        AppLogger.warning('[SpeedAlert] Position stream error: $error');
      },
    );

    AppLogger.info('[SpeedAlert] Started monitoring (threshold: $thresholdKmh km/h)');
  }

  /// Stop monitoring GPS speed.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _currentSpeedKmh = 0;
    AppLogger.info('[SpeedAlert] Stopped monitoring');
  }

  bool _canAlert() {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!) > cooldownDuration;
  }

  /// Release resources.
  void dispose() {
    stop();
  }
}
