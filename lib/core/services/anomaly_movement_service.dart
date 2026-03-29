import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../constants/alert_types.dart';
import 'app_logger.dart';
import '../../detection/ml/anomaly_movement_classifier.dart';

/// Event emitted when suspicious movement pattern is detected.
class AnomalyMovementEvent {
  const AnomalyMovementEvent({
    required this.result,
    required this.detectedAt,
  });

  final AnomalyMovementResult result;
  final DateTime detectedAt;

  AlertType get alertType => AlertType.suspiciousMovementSos;
}

/// Monitors accelerometer data for anomalous movement patterns.
///
/// ## Algorithm Summary
/// 1. Buffers accelerometer samples over a 5-second rolling window (50Hz → 250 samples)
/// 2. Every [_inferenceInterval], extracts a 24-feature vector and runs inference
/// 3. Emits [AnomalyMovementEvent] if confidence exceeds threshold
///
/// ## Detection Targets
/// - **Restrained**: person not moving voluntarily (low variance)
/// - **Unconscious**: passive gravity alignment with no voluntary movement
/// - **Dragged**: X-axis dominant directional movement
class AnomalyMovementService {
  AnomalyMovementService({AnomalyMovementClassifier? classifier})
      : _classifier = classifier ?? AnomalyMovementClassifier();

  final AnomalyMovementClassifier _classifier;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final _eventController = StreamController<AnomalyMovementEvent>.broadcast();

  /// Emits [AnomalyMovementEvent] whenever suspicious movement is detected.
  Stream<AnomalyMovementEvent> get onAnomalyDetected => _eventController.stream;

  bool _running = false;
  bool get isRunning => _running;

  /// 5-second window at 50Hz = 250 samples.
  static const int _windowSize = 250;

  /// Run inference every 2.5 seconds (50% overlap with window).
  static const Duration _inferenceInterval = Duration(milliseconds: 2500);

  final List<AccelWindow> _window = [];
  Timer? _inferenceTimer;

  // ──────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_running) return;
    await _classifier.load();
    AppLogger.info('[AnomalyMovement] Model source: ${_classifier.activeModelSource}');

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // ~50Hz
    ).listen(_onAccelEvent, onError: _onError);

    _inferenceTimer = Timer.periodic(_inferenceInterval, (_) => _runInference());
    _running = true;
    AppLogger.info('[AnomalyMovement] ✅ Monitoring started');
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _inferenceTimer?.cancel();
    _inferenceTimer = null;
    await _accelSub?.cancel();
    _accelSub = null;
    _window.clear();
    AppLogger.info('[AnomalyMovement] Monitoring stopped');
  }

  // ──────────────────────────────────────────────────────────────────
  // Data Collection
  // ──────────────────────────────────────────────────────────────────

  void _onAccelEvent(AccelerometerEvent event) {
    _window.add(AccelWindow(x: event.x, y: event.y, z: event.z));
    if (_window.length > _windowSize) {
      _window.removeAt(0); // keep rolling window
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Inference
  // ──────────────────────────────────────────────────────────────────

  void _runInference() {
    if (_window.length < 50) return; // need minimum data

    AnomalyMovementResult? result;

    if (_classifier.isModelLoaded) {
      final features = _extractFeatures(_window);
      result = _classifier.classify(features);
    }

    result ??= AnomalyMovementFallback.classify(_window);

    if (result.isAnomaly && result.confidence >= AnomalyMovementClassifier.alertThreshold) {
      _eventController.add(AnomalyMovementEvent(result: result, detectedAt: DateTime.now()));
      AppLogger.info('[AnomalyMovement] 🚨 ${result.predictedClass.name} detected '
          '(conf: ${result.confidence.toStringAsFixed(3)})');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Feature Extraction (24-element vector)
  // ──────────────────────────────────────────────────────────────────

  List<double> _extractFeatures(List<AccelWindow> window) {
    final n = window.length.toDouble();
    final xs = window.map((s) => s.x).toList();
    final ys = window.map((s) => s.y).toList();
    final zs = window.map((s) => s.z).toList();
    final smvs = window.map((s) => _smv(s.x, s.y, s.z)).toList();

    // Means
    final mx = _mean(xs), my = _mean(ys), mz = _mean(zs);
    final mSmv = _mean(smvs);

    // Std deviations
    final sdX = _std(xs, mx), sdY = _std(ys, my), sdZ = _std(zs, mz);
    final varSmv = sdX + sdY + sdZ; // approximate SMV variance

    // Maxima and minima
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final maxZ = zs.reduce((a, b) => a > b ? a : b);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final minZ = zs.reduce((a, b) => a < b ? a : b);
    final rangeSmv = smvs.reduce((a, b) => a > b ? a : b) -
        smvs.reduce((a, b) => a < b ? a : b);

    // Axis energy
    double eX = 0, eY = 0, eZ = 0;
    for (final s in window) { eX += s.x * s.x; eY += s.y * s.y; eZ += s.z * s.z; }
    final totalE = eX + eY + eZ;
    final domAxisRatio = totalE > 0
        ? [eX, eY, eZ].reduce((a, b) => a > b ? a : b) / totalE
        : 0.33;

    // Zero crossing rate using SMV
    int zcCount = 0;
    for (int i = 1; i < smvs.length; i++) {
      if ((smvs[i - 1] - mSmv) * (smvs[i] - mSmv) < 0) zcCount++;
    }
    final zcr = zcCount / (smvs.length - 1);

    // Freefall ratio (SMV < 3G = 29.4 m/s²)
    int ffCount = 0;
    for (final v in smvs) if (v < 2.94) ffCount++;
    final ffRatio = ffCount / n;

    // Stillness ratio (variance of 10-sample sub-windows)
    int stillCount = 0;
    const sub = 10;
    for (int i = 0; i <= window.length - sub; i++) {
      final subVals = smvs.sublist(i, i + sub);
      final sm = _mean(subVals);
      final sv = _variance(subVals, sm);
      if (sv < 0.5) stillCount++;
    }
    final stillRatio = stillCount / ((window.length - sub + 1).clamp(1, window.length));

    // Jerk (rate of change of acceleration)
    double jerkSum = 0, jerkMax = 0;
    for (int i = 1; i < window.length; i++) {
      final jx = window[i].x - window[i-1].x;
      final jy = window[i].y - window[i-1].y;
      final jz = window[i].z - window[i-1].z;
      final jerk = _smv(jx * 50, jy * 50, jz * 50); // multiply by Hz for proper units
      jerkSum += jerk;
      if (jerk > jerkMax) jerkMax = jerk;
    }
    final jerkMean = (window.length > 1) ? jerkSum / (window.length - 1) : 0.0;

    // SMA
    double sma = 0;
    const dt = 1.0 / 50;
    for (final s in window) sma += (s.x.abs() + s.y.abs() + s.z.abs()) * dt;

    // Autocorrelation at lag-1
    double ac1 = 0;
    for (int i = 1; i < smvs.length; i++) {
      ac1 += (smvs[i] - mSmv) * (smvs[i - 1] - mSmv);
    }
    final varTotal = smvs.map((v) => (v - mSmv) * (v - mSmv)).reduce((a, b) => a + b);
    final autocorr = varTotal > 0 ? (ac1 / varTotal).clamp(-1.0, 1.0) : 0.0;

    // Periodicity: ratio of max autocorr to self (simplified)
    final periodicity = autocorr.abs();

    const g = 9.80665;
    return [
      (mx / (2 * g)).clamp(-1, 1),           // 0: mean ax
      (my / (2 * g)).clamp(-1, 1),           // 1: mean ay
      (mz / (2 * g)).clamp(-1, 1),           // 2: mean az
      (sdX / g).clamp(0, 1),                 // 3: std ax
      (sdY / g).clamp(0, 1),                 // 4: std ay
      (sdZ / g).clamp(0, 1),                 // 5: std az
      (maxX / (5 * g)).clamp(0, 1),          // 6: max ax
      (maxY / (5 * g)).clamp(0, 1),          // 7: max ay
      (maxZ / (5 * g)).clamp(0, 1),          // 8: max az
      (minX / (5 * g)).clamp(-1, 0) + 1,    // 9: min ax (shifted to [0,1])
      (minY / (5 * g)).clamp(-1, 0) + 1,    // 10: min ay
      (minZ / (5 * g)).clamp(-1, 0) + 1,    // 11: min az
      (mSmv / (5 * g)).clamp(0, 1),         // 12: SMV mean
      (varSmv / 10.0).clamp(0, 1),          // 13: SMV variance
      (rangeSmv / (10 * g)).clamp(0, 1),    // 14: SMV range
      domAxisRatio,                           // 15: dominant axis ratio
      zcr,                                    // 16: zero crossing rate
      ffRatio,                                // 17: freefall ratio
      stillRatio,                             // 18: stillness ratio
      (jerkMean / 1000.0).clamp(0, 1),      // 19: jerk mean
      (jerkMax / 5000.0).clamp(0, 1),       // 20: jerk max
      (sma / (n * g * dt * 3)).clamp(0, 1), // 21: SMA
      (autocorr + 1) / 2,                    // 22: autocorr (shifted to [0,1])
      periodicity,                            // 23: periodicity score
    ];
  }

  // ── Math utilities ────────────────────────────────────────────────
  double _mean(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  double _std(List<double> v, double mean) => _variance(v, mean) > 0 ? _sqrtD(_variance(v, mean)) : 0;
  double _variance(List<double> v, double mean) {
    if (v.isEmpty) return 0;
    double s = 0;
    for (final x in v) s += (x - mean) * (x - mean);
    return s / v.length;
  }
  double _smv(double x, double y, double z) => _sqrtD(x*x + y*y + z*z);
  double _sqrtD(double v) {
    if (v <= 0) return 0;
    double g = v / 2;
    for (int i = 0; i < 12; i++) g = (g + v / g) / 2;
    return g;
  }

  void _onError(Object err) {
    AppLogger.warning('[AnomalyMovement] Sensor error: $err');
  }

  void dispose() {
    stop();
    _classifier.dispose();
    _eventController.close();
  }
}
