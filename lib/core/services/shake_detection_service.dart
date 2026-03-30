import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects rapid device shaking using the accelerometer.
///
/// Triggers a callback after detecting [shakeThreshold] × [shakeCount]
/// acceleration events within a time window.
///
/// For testing, inject a custom [accelerometerStream] via the constructor.
/// In production, the hardware stream is used automatically.
class ShakeDetectionService {
  ShakeDetectionService({
    this.shakeThreshold = 15.0,
    this.shakeCount = 3,
    this.shakeWindowMs = 800,
    Stream<UserAccelerometerEvent>? accelerometerStream,
  }) : _accelerometerStream = accelerometerStream;

  /// Minimum acceleration magnitude (m/s²) to count as a shake.
  final double shakeThreshold;

  /// Number of shakes required to trigger callback.
  final int shakeCount;

  /// Time window (ms) in which [shakeCount] shakes must occur.
  final int shakeWindowMs;

  /// Injected stream — if null, uses real hardware stream.
  final Stream<UserAccelerometerEvent>? _accelerometerStream;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<int> _shakeTimestamps = [];
  void Function()? _onShakeDetected;
  bool _isEnabled = false;

  /// Whether shake detection is running.
  bool get isEnabled => _isEnabled;

  /// Exposes the detection logic so tests can inject raw magnitude values.
  /// Returns true if the shake was counted AND a shake was triggered.
  bool processAccelerometerEvent(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude >= shakeThreshold) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _shakeTimestamps.add(now);
      _shakeTimestamps.removeWhere((t) => now - t > shakeWindowMs);
      if (_shakeTimestamps.length >= shakeCount) {
        _shakeTimestamps.clear();
        _onShakeDetected?.call();
        return true;
      }
    }
    return false;
  }

  /// Start listening for shake events.
  ///
  /// Calls [onShakeDetected] when a shake pattern is detected.
  ///
  /// Set [skipStream] to `true` in unit tests to register the callback
  /// without opening the real hardware EventChannel. Tests should then
  /// call [processAccelerometerEvent] directly.
  void startListening({
    required void Function() onShakeDetected,
    bool skipStream = false,
  }) {
    if (_isEnabled) return;
    _isEnabled = true;
    _onShakeDetected = onShakeDetected;

    if (!skipStream) {
      final stream = _accelerometerStream ?? userAccelerometerEventStream();
      _subscription = stream.listen((event) {
        processAccelerometerEvent(event.x, event.y, event.z);
      });
    }
  }

  /// Stop listening for shake events.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _shakeTimestamps.clear();
    _isEnabled = false;
    _onShakeDetected = null; // Clear callback so processAccelerometerEvent is a no-op
  }

  /// Dispose resources.
  void dispose() {
    stopListening();
    _onShakeDetected = null;
  }
}
