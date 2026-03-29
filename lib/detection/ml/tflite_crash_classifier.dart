import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/services/app_logger.dart';

/// Classification result from the TFLite crash/fall model.
class ClassificationResult {
  const ClassificationResult({
    required this.normalConfidence,
    required this.fallConfidence,
    required this.crashConfidence,
  });

  /// Confidence that the activity is normal (no event).
  final double normalConfidence;

  /// Confidence that a fall event is occurring.
  final double fallConfidence;

  /// Confidence that a crash/vehicle impact is occurring.
  final double crashConfidence;

  /// Highest confidence class.
  String get predictedClass {
    if (fallConfidence >= crashConfidence && fallConfidence >= normalConfidence) {
      return 'fall';
    }
    if (crashConfidence >= fallConfidence && crashConfidence >= normalConfidence) {
      return 'crash';
    }
    return 'normal';
  }

  /// Confidence of the predicted class.
  double get maxConfidence {
    if (predictedClass == 'fall') return fallConfidence;
    if (predictedClass == 'crash') return crashConfidence;
    return normalConfidence;
  }

  @override
  String toString() =>
      'ClassificationResult(normal: ${normalConfidence.toStringAsFixed(3)}, '
      'fall: ${fallConfidence.toStringAsFixed(3)}, '
      'crash: ${crashConfidence.toStringAsFixed(3)}, '
      'predicted: $predictedClass)';
}

/// TFLite inference wrapper for the crash/fall classification model.
///
/// ## Model Contract
///
/// - **Input**: `[1, 12]` Float32 tensor (from [MlFeatureExtractor])
/// - **Output**: `[1, 3]` Float32 tensor → `[normal, fall, crash]` probabilities
///
/// ## M4: Dynamic Model Loading via Firebase ML
///
/// Loading priority (highest to lowest):
/// 1. **Firebase ML** (`loadFromFirebaseML`) — downloads the latest
///    `crash_fall_classifier` model from Firebase Console → Machine Learning.
///    The model is cached on-device and served offline after first download.
/// 2. **Bundled asset fallback** (`loadModel`) — uses the `.tflite` file
///    inside `assets/ml_models/`.  Useful for local dev and CI.
/// 3. **Threshold-only mode** — if both fail, `classify` returns `null`
///    and `CrashFallDetectionEngine` uses its threshold algorithm exclusively.
///
/// ## Lifecycle
///
/// 1. Call [loadFromFirebaseML] at app startup (managed by ServiceBootstrapper).
/// 2. Call [classify] with a 12-element feature vector.
/// 3. Call [dispose] when done.
class TfliteCrashClassifier {
  Interpreter? _interpreter;
  _ModelSource _activeSource = _ModelSource.none;

  /// Firebase ML model name published in the Firebase Console.
  static const String _kFirebaseModelName = 'crash_fall_classifier';

  /// Path to the bundled TFLite model asset (fallback).
  static const String modelAssetPath = 'assets/ml_models/crash_fall_model.tflite';

  /// Whether the model has been loaded successfully.
  bool get isModelLoaded => _interpreter != null;

  /// Which source the active model was loaded from.
  String get activeModelSource => _activeSource.name;

  // ──────────────────────────────────────────────────────────────────
  // M4: PRIMARY — Firebase ML dynamic model download
  // ──────────────────────────────────────────────────────────────────

  /// Attempts to load the latest model from Firebase ML.
  ///
  /// If the device has never downloaded the model, it fetches it over the
  /// network (WiFi or cellular, depending on [conditions]).
  /// If the download fails, falls back to [loadModel] (bundled asset).
  ///
  /// Returns `true` if any model source succeeded.
  Future<bool> loadFromFirebaseML() async {
    try {
      AppLogger.info('[TfliteCrashClassifier] Attempting Firebase ML download...');

      final conditions = FirebaseModelDownloadConditions(
        androidChargingRequired: false,
        androidWifiRequired: false,
        iosAllowsCellularAccess: true,
        iosAllowsBackgroundDownloading: false,
      );

      final downloadedModel = await FirebaseModelDownloader.instance.getModel(
        _kFirebaseModelName,
        FirebaseModelDownloadType.latestModel,
        conditions,
      );

      _interpreter = Interpreter.fromFile(downloadedModel.file);
      _activeSource = _ModelSource.firebaseML;

      AppLogger.info(
        '[TfliteCrashClassifier] ✅ Firebase ML model loaded '
        'from ${downloadedModel.file.path} — '
        'input=${_interpreter!.getInputTensor(0).shape}, '
        'output=${_interpreter!.getOutputTensor(0).shape}',
      );
      return true;
    } catch (e) {
      AppLogger.warning(
        '[TfliteCrashClassifier] Firebase ML unavailable — falling back to bundled asset: $e',
      );
      return loadModel();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // FALLBACK — Bundled asset model
  // ──────────────────────────────────────────────────────────────────

  /// Load the TFLite model from bundled assets.
  ///
  /// Returns `true` if the model loaded successfully, `false` otherwise.
  /// Does NOT throw — failure is intentionally non-fatal.
  Future<bool> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _activeSource = _ModelSource.bundledAsset;
      AppLogger.info(
        '[TfliteCrashClassifier] ⚠️ Bundled model loaded (placeholder — threshold-only mode for ML): '
        'input=${_interpreter!.getInputTensor(0).shape}, '
        'output=${_interpreter!.getOutputTensor(0).shape}',
      );
      return true;
    } catch (e) {
      AppLogger.warning(
        '[TfliteCrashClassifier] No model available — running in threshold-only mode: $e',
      );
      _interpreter = null;
      _activeSource = _ModelSource.none;
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // INFERENCE
  // ──────────────────────────────────────────────────────────────────

  /// Classify a 12-element feature vector.
  ///
  /// Feature vector index contract (must match training pipeline):
  /// ```
  /// [0]  smv              — Signal Magnitude Vector
  /// [1]  gForce           — Converted to G from m/s²
  /// [2]  jerk             — Rate of change of SMV
  /// [3]  sma              — Signal Magnitude Area
  /// [4]  smvVariance      — Variance of SMV in window
  /// [5]  freefallFlag     — 1.0 if freefall detected in window
  /// [6]  postImpactStillness — 1.0 if stillness detected post-impact
  /// [7]  axMean           — Mean X-axis acceleration
  /// [8]  ayMean           — Mean Y-axis acceleration
  /// [9]  azMean           — Mean Z-axis acceleration
  /// [10] axStd            — Std deviation of X-axis
  /// [11] azStd            — Std deviation of Z-axis
  /// ```
  ///
  /// Returns `null` if the model is not loaded or inference fails.
  ClassificationResult? classify(List<double> features) {
    if (_interpreter == null) return null;
    if (features.length != 12) {
      AppLogger.warning('[TfliteCrashClassifier] Expected 12 features, got ${features.length}');
      return null;
    }

    try {
      // Prepare input tensor: [1, 12].
      final input = Float32List.fromList(features);
      final inputBuffer = input.buffer.asFloat32List().reshape([1, 12]);

      // Prepare output tensor: [1, 3].
      final output = List.filled(3, 0.0).reshape([1, 3]);

      _interpreter!.run(inputBuffer, output);

      final probs = (output[0] as List<double>);
      return ClassificationResult(
        normalConfidence: probs[0].clamp(0.0, 1.0),
        fallConfidence: probs[1].clamp(0.0, 1.0),
        crashConfidence: probs[2].clamp(0.0, 1.0),
      );
    } catch (e) {
      AppLogger.warning('[TfliteCrashClassifier] Inference failed: $e');
      return null;
    }
  }

  /// Release the interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _activeSource = _ModelSource.none;
  }
}

/// Internal enum tracking where the active model was loaded from.
enum _ModelSource {
  /// No model loaded — threshold-only mode.
  none,
  /// Loaded from Firebase ML (production model).
  firebaseML,
  /// Loaded from bundled assets (placeholder/dev model).
  bundledAsset,
}
