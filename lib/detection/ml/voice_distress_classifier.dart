import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../../core/services/app_logger.dart';

/// Result of voice distress classification.
class VoiceDistressResult {
  const VoiceDistressResult({
    required this.distressConfidence,
    required this.normalConfidence,
  });

  /// Probability that distress (screaming/crying) is present.
  final double distressConfidence;

  /// Probability that audio is normal (no distress).
  final double normalConfidence;

  /// True when distress confidence exceeds the alert threshold.
  bool get isDistress => distressConfidence >= VoiceDistressClassifier.alertThreshold;

  @override
  String toString() =>
      'VoiceDistressResult(distress: ${distressConfidence.toStringAsFixed(3)}, '
      'normal: ${normalConfidence.toStringAsFixed(3)}, '
      'isDistress: $isDistress)';
}

/// TFLite inference wrapper for the voice distress classification model.
///
/// ## Model Contract
/// - Input:  `[1, 40, 32]` Float32 tensor — 40-band Mel spectrogram, 32 frames
/// - Output: `[1, 2]` Float32 tensor → `[normal, distress]` probabilities
///
/// ## Loading Priority
/// 1. Firebase ML → `voice_distress_classifier` model name
/// 2. Bundled asset → `assets/ml_models/voice_distress_model.tflite`
/// 3. Fallback algorithm → [VoiceDistressFallback] (no TFLite required)
///
/// ## Fallback Algorithm
/// When no model is available, uses energy-based heuristics:
/// - RMS energy > 0.3 (loud audio event)
/// - Zero-crossing rate > 0.15 (high-frequency content, typical of screams)
class VoiceDistressClassifier {
  Interpreter? _interpreter;
  _ModelSource _source = _ModelSource.none;

  static const String _kFirebaseModelName = 'voice_distress_classifier';
  static const String modelAssetPath = 'assets/ml_models/voice_distress_model.tflite';

  /// Confidence threshold above which an alert is triggered.
  static const double alertThreshold = 0.75;

  /// Number of Mel bands in the spectrogram (must match training).
  static const int melBands = 40;

  /// Number of time frames in the spectrogram (must match training).
  static const int timeFrames = 32;

  /// Total input features: melBands × timeFrames.
  static const int inputSize = melBands * timeFrames;

  /// Whether any model (Firebase or bundled) has been loaded.
  bool get isModelLoaded => _interpreter != null;

  /// Which source the active model was loaded from.
  String get activeModelSource => _source.name;

  // Loading

  /// Attempts Firebase ML download → falls back to bundled asset.
  Future<bool> load() async {
    final fromFirebase = await _loadFromFirebase();
    if (fromFirebase) return true;
    return _loadFromAsset();
  }

  Future<bool> _loadFromFirebase() async {
    try {
      AppLogger.info('[VoiceDistress] Attempting Firebase ML download...');
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
      AppLogger.info('[VoiceDistress] ✅ Firebase ML model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[VoiceDistress] Firebase ML unavailable: $e');
      return false;
    }
  }

  Future<bool> _loadFromAsset() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAssetPath);
      _source = _ModelSource.bundledAsset;
      AppLogger.info('[VoiceDistress] ✅ Bundled model loaded');
      return true;
    } catch (e) {
      AppLogger.warning('[VoiceDistress] No model available — fallback mode: $e');
      _interpreter = null;
      _source = _ModelSource.none;
      return false;
    }
  }

  // Inference

  /// Classify a Mel spectrogram feature vector.
  ///
  /// [features] must have exactly [inputSize] (40 × 32 = 1280) elements,
  /// normalised to the range [0, 1].
  ///
  /// Returns `null` if the model is not loaded — caller should use
  /// [VoiceDistressFallback.classify] instead.
  VoiceDistressResult? classify(List<double> features) {
    if (_interpreter == null) return null;
    if (features.length != inputSize) {
      AppLogger.warning('[VoiceDistress] Expected $inputSize features, got ${features.length}');
      return null;
    }

    try {
      final input = Float32List.fromList(features)
          .buffer
          .asFloat32List()
          .reshape([1, melBands, timeFrames]);
      final output = List.filled(2, 0.0).reshape([1, 2]);

      _interpreter!.run(input, output);

      final probs = output[0] as List<double>;
      return VoiceDistressResult(
        normalConfidence: probs[0].clamp(0.0, 1.0),
        distressConfidence: probs[1].clamp(0.0, 1.0),
      );
    } catch (e) {
      AppLogger.warning('[VoiceDistress] Inference failed: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _source = _ModelSource.none;
  }
}

// Fallback: Energy-based heuristic (no ML required)

/// Rule-based voice distress detector used when TFLite model is unavailable.
///
/// Algorithm (based on acoustic research on distress vocalizations):
/// - **RMS energy > 0.3**: indicative of a loud audio event (cry/scream)
/// - **ZCR > 0.15**: high-frequency content pattern typical of screams
///
/// Both conditions must hold simultaneously to avoid false positives from
/// regular loud noise (music, traffic).
class VoiceDistressFallback {
  /// Classify raw PCM audio samples[-1.0, 1.0].
  ///
  /// Returns a [VoiceDistressResult] based on heuristic rules.
  static VoiceDistressResult classify(List<double> pcmSamples) {
    if (pcmSamples.isEmpty) {
      return const VoiceDistressResult(distressConfidence: 0, normalConfidence: 1);
    }

    final rms = _rmsEnergy(pcmSamples);
    final zcr = _zeroCrossingRate(pcmSamples);

    // Both signals must be elevated: loud + high-frequency = distress pattern.
    final isDistressPattern = rms > 0.3 && zcr > 0.15;

    // Map heuristic signals to confidence scores.
    // RMS contribution (0–0.5) + ZCR contribution (0–0.5)
    final distressConf = isDistressPattern
        ? ((rms - 0.3) / 0.7 * 0.5 + (zcr - 0.15) / 0.85 * 0.5).clamp(0.0, 1.0)
        : 0.0;

    return VoiceDistressResult(
      distressConfidence: distressConf,
      normalConfidence: 1.0 - distressConf,
    );
  }

  /// Root-mean-square energy of audio samples.
  static double _rmsEnergy(List<double> samples) {
    double sumSq = 0;
    for (final s in samples) {
      sumSq += s * s;
    }
    return (sumSq / samples.length) > 0
        ? _sqrt(sumSq / samples.length)
        : 0.0;
  }

  /// Fraction of samples where sign changes (high = rapid oscillation).
  static double _zeroCrossingRate(List<double> samples) {
    int crossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] >= 0) != (samples[i] >= 0)) crossings++;
    }
    return crossings / (samples.length - 1);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double g = v / 2;
    for (int i = 0; i < 10; i++) {
      g = (g + v / g) / 2;
    }
    return g;
  }
}

enum _ModelSource { none, firebaseML, bundledAsset }
