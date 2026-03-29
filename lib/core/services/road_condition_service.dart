import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../constants/alert_types.dart';
import 'app_logger.dart';
import '../../detection/ml/road_condition_classifier.dart';

/// Event emitted when a road hazard condition is detected.
class RoadConditionEvent {
  const RoadConditionEvent({required this.result, required this.detectedAt});

  final RoadConditionResult result;
  final DateTime detectedAt;

  AlertType get alertType => AlertType.roadHazardAlert;
}

/// Monitors accelerometer + GPS speed for road condition anomalies.
///
/// ## Algorithm Summary
/// 1. Buffers accelerometer at 50Hz over a 2-second rolling window
/// 2. GPS speed is updated externally (wired from SpeedAlertService)
/// 3. Every [_inferenceInterval] extracts 8 features and runs inference
/// 4. Emits [RoadConditionEvent] for potholes, emergency braking, or accident risk
///
/// ## External Dependencies
/// - [updateSpeed]: must be called by SpeedAlertService on each GPS update
class RoadConditionService {
  RoadConditionService({RoadConditionClassifier? classifier})
      : _classifier = classifier ?? RoadConditionClassifier();

  final RoadConditionClassifier _classifier;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  final _eventController = StreamController<RoadConditionEvent>.broadcast();

  /// Emits [RoadConditionEvent] whenever a road hazard is classified.
  Stream<RoadConditionEvent> get onHazardDetected => _eventController.stream;

  bool _running = false;
  bool get isRunning => _running;

  /// Current GPS speed in km/h, updated by SpeedAlertService.
  double _currentSpeedKmh = 0.0;

  /// Minimum speed to care about road conditions.
  static const double _minSpeedKmh = 5.0;

  /// 2-second window at 50Hz = 100 samples.
  static const int _windowSize = 100;

  /// Run inference every 1 second (50% overlap).
  static const Duration _inferenceInterval = Duration(seconds: 1);

  final List<RoadSample> _window = [];
  Timer? _inferenceTimer;

  // ──────────────────────────────────────────────────────────────────
  // External Speed Feed
  // ──────────────────────────────────────────────────────────────────

  /// Called by SpeedAlertService on each GPS velocity update.
  void updateSpeed(double speedKmh) {
    _currentSpeedKmh = speedKmh;
  }

  // ──────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_running) return;
    await _classifier.load();
    AppLogger.info('[RoadCondition] Model source: ${_classifier.activeModelSource}');

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // ~50Hz
    ).listen(_onAccelEvent, onError: _onError);

    _inferenceTimer = Timer.periodic(_inferenceInterval, (_) => _runInference());
    _running = true;
    AppLogger.info('[RoadCondition] ✅ Monitoring started');
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _inferenceTimer?.cancel();
    _inferenceTimer = null;
    await _accelSub?.cancel();
    _accelSub = null;
    _window.clear();
    AppLogger.info('[RoadCondition] Monitoring stopped');
  }

  // ──────────────────────────────────────────────────────────────────
  // Data Collection
  // ──────────────────────────────────────────────────────────────────

  void _onAccelEvent(AccelerometerEvent event) {
    _window.add(RoadSample(x: event.x, y: event.y, z: event.z, timestamp: DateTime.now()));
    if (_window.length > _windowSize) _window.removeAt(0);
  }

  // ──────────────────────────────────────────────────────────────────
  // Inference
  // ──────────────────────────────────────────────────────────────────

  void _runInference() {
    if (_window.length < 20) return;
    if (_currentSpeedKmh < _minSpeedKmh) return; // no road analysis while stationary

    RoadConditionResult? result;

    if (_classifier.isModelLoaded) {
      final features = _extractFeatures(_window, _currentSpeedKmh);
      result = _classifier.classify(features, _currentSpeedKmh);
    }

    result ??= RoadConditionFallback.classify(_window, _currentSpeedKmh);

    if (result.requiresAlert && result.confidence >= RoadConditionClassifier.alertThreshold) {
      _eventController.add(RoadConditionEvent(result: result, detectedAt: DateTime.now()));
      AppLogger.info('[RoadCondition] 🚨 ${result.condition.name} detected '
          '(conf: ${result.confidence.toStringAsFixed(3)}, '
          'speed: ${result.speedKmh.toStringAsFixed(1)} km/h)');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Feature Extraction (8-element vector)
  // ──────────────────────────────────────────────────────────────────

  List<double> _extractFeatures(List<RoadSample> window, double speedKmh) {
    final zValues = window.map((s) => s.z).toList();
    final xValues = window.map((s) => s.x).toList();
    final smvValues = window.map((s) => _smv(s.x, s.y, s.z)).toList();

    // Z-axis stats
    final zMean = _mean(zValues);
    final zMax = zValues.reduce((a, b) => a > b ? a : b);
    double zVar = 0;
    for (final z in zValues) zVar += (z - zMean) * (z - zMean);
    zVar /= zValues.length;

    // SMV variance
    final smvMean = _mean(smvValues);
    double smvVar = 0;
    for (final v in smvValues) smvVar += (v - smvMean) * (v - smvMean);
    smvVar /= smvValues.length;

    // Jerk mean (rate of acceleration change)
    double jerkSum = 0;
    for (int i = 1; i < window.length; i++) {
      final jx = (window[i].x - window[i-1].x) * 50;
      final jy = (window[i].y - window[i-1].y) * 50;
      final jz = (window[i].z - window[i-1].z) * 50;
      jerkSum += _smv(jx, jy, jz);
    }
    final jerkMean = window.length > 1 ? jerkSum / (window.length - 1) : 0.0;

    // Deceleration rate via X-axis
    double xDeceleration = 0;
    if (xValues.length >= 2) {
      final dt = window.last.timestamp.difference(window.first.timestamp).inMilliseconds / 1000.0;
      if (dt > 0) xDeceleration = (xValues.first - xValues.last).abs() / dt;
    }

    // Vertical oscillation frequency (zero crossings in Z relative to mean)
    int zcZ = 0;
    for (int i = 1; i < zValues.length; i++) {
      if ((zValues[i-1] - zMean) * (zValues[i] - zMean) < 0) zcZ++;
    }
    final vertOscFreq = zcZ / (window.length - 1);

    // Axis energy ratio
    double eX = 0, eY = 0, eZ = 0;
    for (final s in window) { eX += s.x*s.x; eY += s.y*s.y; eZ += s.z*s.z; }
    final totalE = eX + eY + eZ;
    final domAxisRatio = totalE > 0
        ? [eX, eY, eZ].reduce((a, b) => a > b ? a : b) / totalE
        : 0.33;

    const g = 9.80665;
    return [
      (zMax.abs() / (5 * g)).clamp(0, 1),         // 0: Z spike
      (zVar / 10.0).clamp(0, 1),                   // 1: Z variance
      (smvVar / 10.0).clamp(0, 1),                 // 2: SMV variance
      (jerkMean / 1000.0).clamp(0, 1),             // 3: jerk mean
      (speedKmh / 200.0).clamp(0, 1),              // 4: speed
      (xDeceleration / (2 * g)).clamp(0, 1),       // 5: deceleration
      vertOscFreq.clamp(0, 1),                      // 6: vertical oscillation
      domAxisRatio,                                  // 7: dominant axis ratio
    ];
  }

  // ── Math utilities ────────────────────────────────────────────────
  double _mean(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  double _smv(double x, double y, double z) {
    final s = x*x + y*y + z*z;
    if (s <= 0) return 0;
    double g = s / 2;
    for (int i = 0; i < 12; i++) g = (g + s / g) / 2;
    return g;
  }

  void _onError(Object err) {
    AppLogger.warning('[RoadCondition] Sensor error: $err');
  }

  void dispose() {
    stop();
    _classifier.dispose();
    _eventController.close();
  }
}
