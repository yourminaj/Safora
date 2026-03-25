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
/// This differs from fall detection which includes:
/// - Freefall phase (low G before impact)
/// - Multi-axis rotation
/// - Post-impact stillness
class SnatchDetectionService {
  SnatchDetectionService({
    this.snatchThresholdG = 5.0,
    this.cooldownDuration = const Duration(seconds: 30),
  });

  /// Minimum G-force for a snatch event.
  final double snatchThresholdG;

  /// Cooldown between alerts.
  final Duration cooldownDuration;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastAlertTime;
  bool _isRunning = false;

  /// Whether the service is actively monitoring.
  bool get isRunning => _isRunning;

  /// Start monitoring for phone snatching.
  ///
  /// [onSnatchDetected] is called when a snatch is detected,
  /// with the peak G-force value.
  void start({required void Function(double peakG) onSnatchDetected}) {
    if (_isRunning) return;
    _isRunning = true;

    // Track recent samples for pattern analysis.
    final recentSamples = <_AccelSample>[];
    const windowSize = 25; // ~500ms at 50Hz

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // 50Hz
    ).listen((event) {
      final now = DateTime.now();
      final gForce = _calculateG(event.x, event.y, event.z);

      recentSamples.add(_AccelSample(
        x: event.x,
        y: event.y,
        z: event.z,
        gForce: gForce,
        time: now,
      ));

      // Keep window bounded.
      if (recentSamples.length > windowSize) {
        recentSamples.removeAt(0);
      }

      // Check for snatch pattern.
      if (gForce > snatchThresholdG && _canAlert()) {
        // Snatch analysis: check if this is directional (not tumbling).
        if (_isDirectionalSnatch(recentSamples)) {
          _lastAlertTime = now;
          onSnatchDetected(gForce);
          AppLogger.info(
            '[SnatchDetection] Snatch detected: '
            '${gForce.toStringAsFixed(1)}G',
          );
        }
      }
    });

    AppLogger.info('[SnatchDetection] Started monitoring');
  }

  /// Stop monitoring.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
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

    // Calculate directional dominance: strongest axis should be >70% of total.
    final absX = peak.x.abs();
    final absY = peak.y.abs();
    final absZ = peak.z.abs();
    final total = absX + absY + absZ;
    if (total == 0) return false;

    final maxAxis = [absX, absY, absZ].reduce(
      (a, b) => a > b ? a : b,
    );

    // Snatch = dominant single-axis motion (>60% of total).
    return maxAxis / total > 0.6;
  }

  double _calculateG(double x, double y, double z) {
    return _sqrt(x * x + y * y + z * z) / 9.81;
  }

  /// Sqrt without dart:math to reduce imports (same pattern as SignalProcessor).
  static double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
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
