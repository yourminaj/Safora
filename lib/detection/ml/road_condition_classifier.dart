import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../../core/services/app_logger.dart';

/// Road condition classification labels.
enum RoadCondition {
  /// Smooth, normal road — no action needed.
  normal,

  /// Pothole detected — Z-axis spike then return.
  pothole,

  /// Rough road surface — continuous low-amplitude vibration.
  roughRoad,

  /// Emergency braking event — rapid deceleration while moving fast.
  emergencyBrake,

  /// High risk of accident — combined signals.
  accidentRisk,
}

/// Result from road condition classification.
class RoadConditionResult {
  const RoadConditionResult({
    required this.condition,
    required this.confidence,
    required this.speedKmh,
  });

  final RoadCondition condition;
  final double confidence;

  /// GPS speed at the time of classification.
  final double speedKmh;

  /// Whether this condition should generate an alert.
  bool get requiresAlert =>
      condition == RoadCondition.emergencyBrake ||
      condition == RoadCondition.accidentRisk;

  @override
  String toString() =>
      'RoadConditionResult(condition: ${condition.name}, '
      'confidence: ${confidence.toStringAsFixed(3)}, '
      'speed: ${speedKmh.toStringAsFixed(1)} km/h)';
}

/// TFLite wrapper for the road condition classification model.
///
/// ## Model Contract
/// - Input:  `[1, 8]` Float32 — 8-feature vector from 2s accelerometer window
/// - Output: `[1, 5]` Float32 → softmax over [normal, pothole, roughRoad, emergencyBrake, accidentRisk]
///
/// ## Feature Vector (8 elements)
/// | Index | Feature |
/// |-------|---------|
/// | 0     | Z-axis max (normalised) — pothole spike |
/// | 1     | Z-axis variance |
/// | 2     | SMV variance |
/// | 3     | Jerk mean |
/// | 4     | Speed (normalised 0–1 over 200 km/h) |
/// | 5     | Deceleration rate |
/// | 6     | Vertical oscillation frequency |
/// | 7     | Dominant axis ratio |
class RoadConditionClassifier {
  Interpreter? _interpreter;
  _ModelSource _source = _ModelSource.none;

  static const String _kFirebaseModelName = 'road_condition_classifier';
  static const String modelAssetPath = 'assets/ml_models/road_condition_model.tflite';

  static const double alertThreshold = 0.65;
  static const int featureCount = 8;

  bool get isModelLoaded => _interpreter != null;
  String get activeModelSource => _source.name;

  // Loading

  Future<bool> load() async {
    final fromFirebase = await _loadFromFirebase();
    if (fromFirebase) return true;
    return _loadFromAsset();
  }

  Future<bool> _loadFromFirebase() async {
    try {
      AppLogger.info('[RoadCondition] Attempting Firebase ML download...');
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
      AppLogger.info('[RoadCondition] ✅ Firebase ML model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[RoadCondition] Firebase ML unavailable: $e');
      return false;
    }
  }

  Future<bool> _loadFromAsset() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _source = _ModelSource.bundledAsset;
      AppLogger.info('[RoadCondition] ✅ Bundled model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[RoadCondition] No model — fallback mode: $e');
      _interpreter = null;
      _source = _ModelSource.none;
      return false;
    }
  }

  // Inference

  /// Classify road condition from an 8-element normalised feature vector.
  RoadConditionResult? classify(List<double> features, double speedKmh) {
    if (_interpreter == null) return null;
    if (features.length != featureCount) {
      AppLogger.warning('[RoadCondition] Expected $featureCount features, got ${features.length}');
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
      const conditions = RoadCondition.values;
      final maxIdx = probs.indexOf(probs.reduce(max));
      final predicted = conditions[maxIdx];

      return RoadConditionResult(
        condition: predicted,
        confidence: probs[maxIdx].clamp(0.0, 1.0),
        speedKmh: speedKmh,
      );
    } catch (e) {
      AppLogger.warning('[RoadCondition] Inference failed: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _source = _ModelSource.none;
  }
}

// Fallback: Physics-based heuristic

/// Accelerometer sample for road condition analysis.
class RoadSample {
  const RoadSample({required this.x, required this.y, required this.z, required this.timestamp});
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
}

/// Physics-based road condition detector used when TFLite model unavailable.
///
/// Algorithm:
/// - **Pothole**: Z-axis spike > 2G (19.6 m/s²) returning to baseline within 200ms
/// - **Emergency brake**: deceleration > 4.9 m/s² (0.5G) sustained 300ms at speed > 40 km/h
/// - **Rough road**: continuous Z-axis variance > 0.8 over 2s window
class RoadConditionFallback {
  static RoadConditionResult classify(List<RoadSample> window, double speedKmh) {
    if (window.length < 5) {
      return RoadConditionResult(condition: RoadCondition.normal, confidence: 0.5, speedKmh: speedKmh);
    }

    // Pothole: sharp Z spike returning quickly
    final zValues = window.map((s) => s.z).toList();
    final zMean = zValues.reduce((a, b) => a + b) / zValues.length;
    final zMax = zValues.reduce(max);
    final zMaxIdx = zValues.indexOf(zMax);

    const potholeThreshold = 19.6; // 2G in m/s²
    bool isPothole = false;
    if ((zMax - zMean).abs() > potholeThreshold && zMaxIdx > 0) {
      // Check return to baseline within next 200ms (10 samples at 50Hz)
      final endIdx = min(zMaxIdx + 10, zValues.length - 1);
      final postSpike = zValues.sublist(zMaxIdx + 1, endIdx + 1);
      if (postSpike.isNotEmpty) {
        final postMean = postSpike.reduce((a, b) => a + b) / postSpike.length;
        isPothole = (postMean - zMean).abs() < 4.9; // returned within 0.5G of baseline
      }
    }

    if (isPothole) {
      return RoadConditionResult(
        condition: RoadCondition.pothole,
        confidence: ((zMax - zMean).abs() / potholeThreshold).clamp(0.6, 1.0),
        speedKmh: speedKmh,
      );
    }

    // Emergency brake: deceleration via X-axis (forward) at speed
    final xValues = window.map((s) => s.x).toList();
    double xDeceleration = 0;
    if (xValues.length >= 2) {
      final dt = window.last.timestamp.difference(window.first.timestamp).inMilliseconds / 1000.0;
      if (dt > 0) {
        xDeceleration = (xValues.first - xValues.last).abs() / dt;
      }
    }

    if (xDeceleration > 4.9 && speedKmh > 40) {
      return RoadConditionResult(
        condition: RoadCondition.emergencyBrake,
        confidence: (xDeceleration / 9.81).clamp(0.0, 1.0),
        speedKmh: speedKmh,
      );
    }

    // Rough road: continuous Z-axis variance
    double zVar = 0;
    for (final z in zValues) {
      zVar += (z - zMean) * (z - zMean);
    }
    zVar /= zValues.length;

    if (zVar > 0.8) {
      return RoadConditionResult(
        condition: RoadCondition.roughRoad,
        confidence: (zVar / 5.0).clamp(0.0, 1.0),
        speedKmh: speedKmh,
      );
    }

    return RoadConditionResult(
      condition: RoadCondition.normal,
      confidence: 0.85,
      speedKmh: speedKmh,
    );
  }
}

enum _ModelSource { none, firebaseML, bundledAsset }
