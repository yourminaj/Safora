import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'app_logger.dart';

/// Monitors GPS speed and alerts when exceeding a threshold.
///
/// Uses [Geolocator.getPositionStream] for real-time speed data.
/// Speed is provided in m/s by the platform, converted to km/h.
///
/// For testing, inject a custom [positionStream] via the constructor.
/// In production, the hardware stream is used automatically.
class SpeedAlertService {
  SpeedAlertService({
    this.thresholdKmh = 120.0,
    this.cooldownDuration = const Duration(seconds: 60),
    this.notifyIntervalMs = 5000,
    Stream<Position>? positionStream,
  }) : _positionStream = positionStream;

  /// Speed threshold in km/h to trigger an alert.
  final double thresholdKmh;

  /// Cooldown between alerts to avoid spamming.
  final Duration cooldownDuration;

  /// Position update interval in milliseconds.
  final int notifyIntervalMs;

  /// Injected stream — if null, uses real GPS hardware stream.
  final Stream<Position>? _positionStream;

  StreamSubscription<Position>? _subscription;
  DateTime? _lastAlertTime;
  double _currentSpeedKmh = 0;

  /// Whether the service is actively monitoring.
  bool get isRunning => _subscription != null;

  /// Current speed in km/h.
  double get currentSpeedKmh => _currentSpeedKmh;

  /// Process a raw GPS position sample.
  ///
  /// Exposed for direct testing without needing a live GPS stream.
  /// Returns true if a speed alert was triggered.
  bool processPosition({
    required double speedMs,
    required void Function(double speedKmh) onSpeedExceeded,
    void Function(double speedKmh)? onSpeedUpdate,
    DateTime? timestamp,
  }) {
    _currentSpeedKmh = speedMs >= 0 ? speedMs * 3.6 : 0;
    onSpeedUpdate?.call(_currentSpeedKmh);

    final now = timestamp ?? DateTime.now();
    if (_currentSpeedKmh > thresholdKmh && _canAlert(now)) {
      _lastAlertTime = now;
      onSpeedExceeded(_currentSpeedKmh);
      AppLogger.info(
        '[SpeedAlert] Speed alert: '
        '${_currentSpeedKmh.toStringAsFixed(1)} km/h > $thresholdKmh km/h',
      );
      return true;
    }
    return false;
  }

  /// Start monitoring GPS speed.
  ///
  /// [onSpeedExceeded] is called when speed exceeds [thresholdKmh].
  /// [onSpeedUpdate] is called on every position update.
  void start({
    required void Function(double speedKmh) onSpeedExceeded,
    void Function(double speedKmh)? onSpeedUpdate,
  }) {
    if (_subscription != null) return;

    Stream<Position> stream;
    if (_positionStream != null) {
      stream = _positionStream;
    } else {
      final settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum 10m between updates.
        timeLimit: Duration(milliseconds: notifyIntervalMs),
      );
      stream = Geolocator.getPositionStream(locationSettings: settings);
    }

    _subscription = stream.listen(
      (position) {
        processPosition(
          speedMs: position.speed,
          onSpeedExceeded: onSpeedExceeded,
          onSpeedUpdate: onSpeedUpdate,
        );
      },
      onError: (Object error) {
        AppLogger.warning('[SpeedAlert] Position stream error: $error');
      },
    );

    AppLogger.info(
      '[SpeedAlert] Started monitoring (threshold: $thresholdKmh km/h)',
    );
  }

  /// Stop monitoring GPS speed.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _currentSpeedKmh = 0;
    AppLogger.info('[SpeedAlert] Stopped monitoring');
  }

  bool _canAlert(DateTime now) {
    if (_lastAlertTime == null) return true;
    return now.difference(_lastAlertTime!) > cooldownDuration;
  }

  /// Release resources.
  void dispose() {
    stop();
  }
}
