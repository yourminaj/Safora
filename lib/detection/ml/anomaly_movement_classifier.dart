import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../../core/services/app_logger.dart';

/// Classification labels from the anomaly movement model.
enum MovementClass {
  /// Normal walking, standing, or expected daily movement.
  normal,

  /// High-intensity movement (exercise, running) — not a safety concern.
  running,

  /// Very low movement duration suggesting the person may be restrained.
  restrained,

  /// Passive body movement with lack of voluntary control — possible unconsciousness.
  unconscious,

  /// Passive but directional movement — possible dragging of the person.
  dragged,
}

/// Result from anomaly movement classification.
class AnomalyMovementResult {
  const AnomalyMovementResult({
    required this.predictedClass,
    required this.confidence,
    required this.probabilities,
  });

  final MovementClass predictedClass;
  final double confidence;
  final Map<MovementClass, double> probabilities;

  /// True when an actionable anomaly is detected.
  bool get isAnomaly =>
      predictedClass == MovementClass.restrained ||
      predictedClass == MovementClass.unconscious ||
      predictedClass == MovementClass.dragged;

  @override
  String toString() =>
      'AnomalyMovementResult(class: ${predictedClass.name}, '
      'confidence: ${confidence.toStringAsFixed(3)}, '
      'anomaly: $isAnomaly)';
}

/// TFLite wrapper for the anomaly movement detection model.
///
/// ## Model Contract
/// - Input:  `[1, 24]` Float32 — 24-feature vector extracted from 5s accel window
/// - Output: `[1, 5]` Float32 → softmax over [normal, running, restrained, unconscious, dragged]
///
/// ## Feature Vector (24 elements)
/// | Index | Feature |
/// |-------|---------|
/// | 0–2   | Mean [ax, ay, az] |
/// | 3–5   | Std deviation [ax, ay, az] |
/// | 6–8   | Max [ax, ay, az] |
/// | 9–11  | Min [ax, ay, az] |
/// | 12    | SMV mean |
/// | 13    | SMV variance |
/// | 14    | SMV range |
/// | 15    | Dominant axis ratio |
/// | 16    | Zero-crossing rate |
/// | 17    | Freefall ratio |
/// | 18    | Stillness ratio |
/// | 19    | Jerk mean |
/// | 20    | Jerk max |
/// | 21    | SMA (Signal Magnitude Area) |
/// | 22    | Autocorrelation at lag-1 |
/// | 23    | Periodicity score |
class AnomalyMovementClassifier {
  Interpreter? _interpreter;
  _ModelSource _source = _ModelSource.none;

  static const String _kFirebaseModelName = 'anomaly_movement_detector';
  static const String modelAssetPath = 'assets/ml_models/anomaly_movement_model.tflite';

  /// Confidence threshold above which an anomaly alert is triggered.
  static const double alertThreshold = 0.60;

  /// Number of features in the input vector.
  static const int featureCount = 24;

  bool get isModelLoaded => _interpreter != null;
  String get activeModelSource => _source.name;

  // ──────────────────────────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────────────────────────

  Future<bool> load() async {
    final fromFirebase = await _loadFromFirebase();
    if (fromFirebase) return true;
    return _loadFromAsset();
  }

  Future<bool> _loadFromFirebase() async {
    try {
      AppLogger.info('[AnomalyMovement] Attempting Firebase ML download...');
      final model = await FirebaseModelDownloader.instance.getModel(
        _kFirebaseModelName,
        FirebaseModelDownloadType.latestModel,
        FirebaseModelDownloadConditions(
          androidWifiRequired: false,
          androidChargingRequired: false,
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: false,
        ),
      );
      _interpreter = Interpreter.fromFile(model.file);
      _source = _ModelSource.firebaseML;
      AppLogger.info('[AnomalyMovement] ✅ Firebase ML model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[AnomalyMovement] Firebase ML unavailable: $e');
      return false;
    }
  }

  Future<bool> _loadFromAsset() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _source = _ModelSource.bundledAsset;
      AppLogger.info('[AnomalyMovement] ✅ Bundled model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[AnomalyMovement] No model — fallback mode: $e');
      _interpreter = null;
      _source = _ModelSource.none;
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Inference
  // ──────────────────────────────────────────────────────────────────

  /// Classify a 24-element normalised feature vector.
  ///
  /// Returns `null` if model is not loaded → use [AnomalyMovementFallback].
  AnomalyMovementResult? classify(List<double> features) {
    if (_interpreter == null) return null;
    if (features.length != featureCount) {
      AppLogger.warning('[AnomalyMovement] Expected $featureCount features, got ${features.length}');
      return null;
    }

    try {
      final input = Float32List.fromList(features)
          .buffer
          .asFloat32List()
          .reshape([1, featureCount]);
      final output = List.filled(5, 0.0).reshape([1, 5]);

      _interpreter!.run(input, output);

      final probs = output[0] as List<double>;
      final classes = MovementClass.values;
      final probMap = {
        for (int i = 0; i < classes.length; i++) classes[i]: probs[i].clamp(0.0, 1.0)
      };

      final predicted = classes[probs.indexOf(probs.reduce(max))];
      return AnomalyMovementResult(
        predictedClass: predicted,
        confidence: probMap[predicted]!,
        probabilities: probMap,
      );
    } catch (e) {
      AppLogger.warning('[AnomalyMovement] Inference failed: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _source = _ModelSource.none;
  }
}

// ──────────────────────────────────────────────────────────────────
// Fallback: Variance-based heuristic
// ──────────────────────────────────────────────────────────────────

/// Accelerometer sample for anomaly detection.
class AccelWindow {
  const AccelWindow({required this.x, required this.y, required this.z});
  final double x;
  final double y;
  final double z;
}

/// Variance-based anomaly detector used when TFLite model is unavailable.
///
/// Algorithm:
/// - **Restrained**: very low 5s variance (< 0.05 m²/s⁴) — person not moving voluntarily
/// - **Dragged**: X-axis dominant (> 70%) with moderate total variance (0.05–0.5)
/// - **Unconscious**: near-zero variance + maintained gravity alignment on one axis
class AnomalyMovementFallback {
  static AnomalyMovementResult classify(List<AccelWindow> window) {
    if (window.length < 10) {
      return AnomalyMovementResult(
        predictedClass: MovementClass.normal,
        confidence: 0.5,
        probabilities: {for (final c in MovementClass.values) c: 0.2},
      );
    }

    // Compute per-axis variance
    final axMean = window.map((s) => s.x).reduce((a, b) => a + b) / window.length;
    final ayMean = window.map((s) => s.y).reduce((a, b) => a + b) / window.length;
    final azMean = window.map((s) => s.z).reduce((a, b) => a + b) / window.length;

    double varX = 0, varY = 0, varZ = 0;
    for (final s in window) {
      varX += (s.x - axMean) * (s.x - axMean);
      varY += (s.y - ayMean) * (s.y - ayMean);
      varZ += (s.z - azMean) * (s.z - azMean);
    }
    varX /= window.length;
    varY /= window.length;
    varZ /= window.length;

    final totalVariance = varX + varY + varZ;
    final dominantAxisVariance = [varX, varY, varZ].reduce(max);
    final dominantRatio = totalVariance > 0 ? dominantAxisVariance / totalVariance : 0.0;

    MovementClass predicted;
    double confidence;

    if (totalVariance < 0.05) {
      // Near-zero movement — restrained or unconscious
      // Gravity should still be aligned to one axis if unconscious
      final gravityMagnitude = sqrt(axMean * axMean + ayMean * ayMean + azMean * azMean);
      if ((gravityMagnitude - 9.81).abs() < 2.0) {
        predicted = MovementClass.unconscious;
        confidence = (1.0 - totalVariance / 0.05).clamp(0.0, 1.0);
      } else {
        predicted = MovementClass.restrained;
        confidence = 0.7;
      }
    } else if (dominantRatio > 0.7 && varX > varY && varX > varZ && totalVariance < 0.5) {
      // X-axis dominant with moderate total movement — dragging pattern
      predicted = MovementClass.dragged;
      confidence = ((dominantRatio - 0.7) / 0.3 * 0.6 + 0.4).clamp(0.0, 1.0);
    } else if (totalVariance > 2.0) {
      predicted = MovementClass.running;
      confidence = (totalVariance / 10.0).clamp(0.0, 1.0);
    } else {
      predicted = MovementClass.normal;
      confidence = 0.8;
    }

    final probMap = <MovementClass, double>{};
    for (final c in MovementClass.values) {
      probMap[c] = c == predicted ? confidence : (1.0 - confidence) / 4;
    }

    return AnomalyMovementResult(
      predictedClass: predicted,
      confidence: confidence,
      probabilities: probMap,
    );
  }
}

enum _ModelSource { none, firebaseML, bundledAsset }
