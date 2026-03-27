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
/// ## Lifecycle
///
/// 1. Call [loadModel] at app startup (or lazily on first inference).
/// 2. Call [classify] with a 12-element feature vector.
/// 3. Call [dispose] when done.
///
/// If the model file is missing or corrupt, [isModelLoaded] returns `false`
/// and [classify] returns `null` — the engine falls back to threshold-only.
///
/// > **Important**: The bundled model is a placeholder skeleton. A production
/// > model requires training on annotated accelerometer datasets
/// > (e.g., SisFall, MobiAct, or proprietary vehicle crash data).
class TfliteCrashClassifier {
  Interpreter? _interpreter;

  /// Path to the bundled TFLite model asset.
  static const String modelAssetPath = 'assets/ml_models/crash_fall_model.tflite';

  /// Whether the model has been loaded successfully.
  bool get isModelLoaded => _interpreter != null;

  /// Load the TFLite model from bundled assets.
  ///
  /// Returns `true` if the model loaded successfully, `false` otherwise.
  /// Does NOT throw — failure is intentionally non-fatal.
  Future<bool> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      AppLogger.info(
        '[TfliteCrashClassifier] Model loaded: '
        'input=${_interpreter!.getInputTensor(0).shape}, '
        'output=${_interpreter!.getOutputTensor(0).shape}',
      );
      return true;
    } catch (e) {
      AppLogger.warning(
        '[TfliteCrashClassifier] Model not loaded (threshold-only mode): $e',
      );
      _interpreter = null;
      return false;
    }
  }

  /// Classify a 12-element feature vector.
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
  }
}
