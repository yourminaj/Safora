import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects rapid device shaking using the accelerometer.
///
/// Triggers a callback after detecting [shakeThreshold] × [shakeCount]
/// acceleration events within a time window.
class ShakeDetectionService {
  ShakeDetectionService({
    this.shakeThreshold = 15.0,
    this.shakeCount = 3,
    this.shakeWindowMs = 800,
  });

  /// Minimum acceleration magnitude (m/s²) to count as a shake.
  final double shakeThreshold;

  /// Number of shakes required to trigger callback.
  final int shakeCount;

  /// Time window (ms) in which [shakeCount] shakes must occur.
  final int shakeWindowMs;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<int> _shakeTimestamps = [];
  void Function()? _onShakeDetected;
  bool _isEnabled = false;

  /// Whether shake detection is running.
  bool get isEnabled => _isEnabled;

  /// Start listening for shake events.
  ///
  /// Calls [onShakeDetected] when a shake pattern is detected.
  void startListening({required void Function() onShakeDetected}) {
    if (_isEnabled) return;
    _isEnabled = true;
    _onShakeDetected = onShakeDetected;

    _subscription = userAccelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude >= shakeThreshold) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _shakeTimestamps.add(now);

        // Remove old timestamps outside the window.
        _shakeTimestamps.removeWhere(
          (t) => now - t > shakeWindowMs,
        );

        if (_shakeTimestamps.length >= shakeCount) {
          _shakeTimestamps.clear();
          _onShakeDetected?.call();
        }
      }
    });
  }

  /// Stop listening for shake events.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _shakeTimestamps.clear();
    _isEnabled = false;
  }

  /// Dispose resources.
  void dispose() {
    stopListening();
    _onShakeDetected = null;
  }
}
