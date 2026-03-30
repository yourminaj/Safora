import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'app_logger.dart';

/// Detects phone snatching attempts using accelerometer data.
///
/// Snatching pattern:
/// 1. Sudden high linear acceleration (>5G) in a single direction
/// 2. Without tumbling/rotation (unlike a fall)
/// 3. Brief event (<500ms)
///
/// Inject a custom [accelerometerStream] via the constructor to drive
/// the sensor pipeline from any stream source.
class SnatchDetectionService {
  SnatchDetectionService({
    this.snatchThresholdG = 5.0,
    this.cooldownDuration = const Duration(seconds: 30),
    Stream<AccelerometerEvent>? accelerometerStream,
  }) : _accelerometerStream = accelerometerStream;

  /// Minimum G-force for a snatch event.
  final double snatchThresholdG;

  /// Cooldown between alerts.
  final Duration cooldownDuration;

  /// Injected stream — if null, uses real hardware stream.
  final Stream<AccelerometerEvent>? _accelerometerStream;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastAlertTime;
  bool _isRunning = false;

  // Internal sample buffer accessible to the detection logic.
  final List<_AccelSample> _recentSamples = [];
  static const int _windowSize = 25; // ~500ms at 50Hz

  /// Whether the service is actively monitoring.
  bool get isRunning => _isRunning;

  /// Start monitoring for phone snatching.
  ///
  /// [onSnatchDetected] is called when a snatch is detected,
  /// with the peak G-force value.
  void start({required void Function(double peakG) onSnatchDetected}) {
    if (_isRunning) return;
    _isRunning = true;

    final stream = _accelerometerStream ??
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 20), // 50Hz
        );

    _subscription = stream.listen((event) {
      _processSample(
        x: event.x,
        y: event.y,
        z: event.z,
        now: DateTime.now(),
        onSnatchDetected: onSnatchDetected,
      );
    });

    AppLogger.info('[SnatchDetection] Started monitoring');
  }

  /// Process a single accelerometer sample.
  ///
  /// Exposed for direct testing without needing a live stream.
  /// Returns true if a snatch was detected.
  bool processSample({
    required double x,
    required double y,
    required double z,
    required void Function(double peakG) onSnatchDetected,
    DateTime? timestamp,
  }) {
    return _processSample(
      x: x,
      y: y,
      z: z,
      now: timestamp ?? DateTime.now(),
      onSnatchDetected: onSnatchDetected,
    );
  }

  bool _processSample({
    required double x,
    required double y,
    required double z,
    required DateTime now,
    required void Function(double peakG) onSnatchDetected,
  }) {
    final gForce = _calculateG(x, y, z);

    _recentSamples.add(_AccelSample(
      x: x,
      y: y,
      z: z,
      gForce: gForce,
      time: now,
    ));

    // Keep window bounded.
    if (_recentSamples.length > _windowSize) {
      _recentSamples.removeAt(0);
    }

    // Check for snatch pattern.
    if (gForce > snatchThresholdG && _canAlert(now)) {
      if (_isDirectionalSnatch(_recentSamples)) {
        _lastAlertTime = now;
        onSnatchDetected(gForce);
        AppLogger.info(
          '[SnatchDetection] Snatch detected: ${gForce.toStringAsFixed(1)}G',
        );
        return true;
      }
    }
    return false;
  }

  /// Stop monitoring.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
    _recentSamples.clear();
    AppLogger.info('[SnatchDetection] Stopped monitoring');
  }


  /// Check if acceleration pattern is a directional snatch vs. a tumbling fall.
  ///
  /// Snatches have high acceleration primarily in one direction,
  /// while falls have more balanced multi-axis acceleration.
  bool _isDirectionalSnatch(List<_AccelSample> samples) {
    if (samples.length < 5) return false;

    // Find the peak sample.
    final peak = samples.reduce(
      (a, b) => a.gForce > b.gForce ? a : b,
    );

    final absX = peak.x.abs();
    final absY = peak.y.abs();
    final absZ = peak.z.abs();
    final total = absX + absY + absZ;
    if (total == 0) return false;

    final maxAxis = [absX, absY, absZ].reduce((a, b) => a > b ? a : b);

    // Snatch = dominant single-axis motion (>60% of total).
    return maxAxis / total > 0.6;
  }

  double _calculateG(double x, double y, double z) {
    return _sqrt(x * x + y * y + z * z) / 9.81;
  }

  static double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
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

/// Internal accelerometer sample for pattern analysis.
class _AccelSample {
  const _AccelSample({
    required this.x,
    required this.y,
    required this.z,
    required this.gForce,
    required this.time,
  });

  final double x;
  final double y;
  final double z;
  final double gForce;
  final DateTime time;
}
