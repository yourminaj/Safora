import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/services/app_logger.dart';
import 'ml_feature_extractor.dart';
import 'signal_processor.dart';
import 'tflite_crash_classifier.dart';

/// Detection result from the crash/fall detection engine.
class DetectionEvent {
  const DetectionEvent({
    required this.type,
    required this.confidence,
    required this.peakGForce,
    required this.timestamp,
    this.hadFreefall = false,
    this.postImpactStillness = false,
  });

  /// Type of detected event.
  final DetectionType type;

  /// Confidence score (0.0 – 1.0).
  ///
  /// Combines multiple signals:
  /// - G-force magnitude
  /// - Freefall detection
  /// - Post-impact stillness
  /// - Jerk magnitude
  final double confidence;

  /// Peak G-force recorded during the event.
  final double peakGForce;

  /// When the event was detected.
  final DateTime timestamp;

  /// Whether freefall was detected before impact.
  final bool hadFreefall;

  /// Whether post-impact stillness was detected.
  final bool postImpactStillness;

  @override
  String toString() =>
      'DetectionEvent(type: ${type.name}, confidence: ${confidence.toStringAsFixed(2)}, '
      'peakG: ${peakGForce.toStringAsFixed(1)}G, freefall: $hadFreefall, '
      'stillness: $postImpactStillness)';
}

/// Types of events the engine can detect.
enum DetectionType {
  /// Elderly/pedestrian fall (lower G, freefall + impact + stillness).
  fall,

  /// Vehicle crash (very high G, rapid deceleration, no freefall).
  vehicleCrash,

  /// Hard impact (high G but doesn't match fall/crash pattern).
  hardImpact,
}

/// Research-backed crash and fall detection engine.
///
/// ## Algorithm Overview
///
/// Uses a **multi-phase detection pipeline** based on peer-reviewed research:
///
/// ### Phase 1: Signal Acquisition (50 Hz)
/// - Raw accelerometer data → SMV (Signal Magnitude Vector)
/// - Low-pass filter separates gravity from user acceleration
///
/// ### Phase 2: Impact Detection (Threshold)
/// - **Fall threshold**: SMV > 3 G (29.4 m/s²) — research standard
/// - **Crash threshold**: SMV > 4 G (39.2 m/s²) — IEEE/WreckWatch standard
/// - **Hard impact**: SMV > 6 G (58.8 m/s²) — high severity
///
/// ### Phase 3: Pattern Analysis (Post-Impact)
/// - Freefall detection: SMV < 0.3 G before impact (weightlessness)
/// - Post-impact stillness: SMV variance → 0 after spike (lying still)
/// - Jerk analysis: Rate of acceleration change (sudden onset indicator)
///
/// ### Phase 4: Confidence Scoring
/// - Weighted combination of signals → 0.0–1.0 confidence
/// - Events below [minConfidence] are suppressed
///
/// ## References
/// - Biomedical Research (2017): SMV threshold-based fall detection
/// - IEEE WreckWatch: Smartphone crash detection at 4G threshold
/// - IJCSMC (2019): Multi-sensor vehicle accident detection
/// - SMU (2018): SVM + threshold hybrid fall detection
class CrashFallDetectionEngine {
  CrashFallDetectionEngine({
    this.fallThresholdG = 3.0,
    this.crashThresholdG = 4.0,
    this.hardImpactThresholdG = 6.0,
    this.minConfidence = 0.5,
    this.cooldownDuration = const Duration(seconds: 10),
    this.postImpactWindowMs = 2000,
    this.samplingRateHz = 50,
    this.mlWeight = 0.6,
  }) : _signalProcessor = SignalProcessor(
         smoothingFactor: 0.8,
         windowSize: samplingRateHz * 2, // 2-second window
       ),
       _featureExtractor = MlFeatureExtractor(samplingRateHz: samplingRateHz),
       _classifier = TfliteCrashClassifier();

  /// Fall detection threshold in G-force.
  /// Research standard: 3 G minimum for human falls.
  final double fallThresholdG;

  /// Vehicle crash detection threshold in G-force.
  /// IEEE/WreckWatch standard: 4 G for moderate impacts.
  final double crashThresholdG;

  /// Hard impact threshold for definite crash events.
  /// Research: > 6 G classified as severe impact.
  final double hardImpactThresholdG;

  /// Minimum confidence score to emit a detection event.
  final double minConfidence;

  /// Cooldown between detection events to prevent spam.
  final Duration cooldownDuration;

  /// Post-impact observation window (ms) for stillness check.
  final int postImpactWindowMs;

  /// Sensor sampling rate in Hz.
  final int samplingRateHz;

  /// Weight given to the ML model confidence in hybrid scoring.
  /// The threshold-based score receives `1 - mlWeight`.
  /// Ignored when the model is not loaded (threshold-only mode).
  final double mlWeight;

  final SignalProcessor _signalProcessor;
  final MlFeatureExtractor _featureExtractor;
  final TfliteCrashClassifier _classifier;
  StreamSubscription<AccelerometerEvent>? _subscription;
  bool _isRunning = false;
  DateTime? _lastDetectionTime;
  void Function(DetectionEvent)? _onDetection;

  // Post-impact analysis state.
  bool _impactDetected = false;
  DateTime? _impactTime;
  double _impactPeakG = 0;
  bool _hadFreefall = false;
  Timer? _postImpactTimer;

  /// Whether the engine is currently monitoring.
  bool get isRunning => _isRunning;

  /// Whether the TFLite model has been loaded successfully.
  bool get isModelLoaded => _classifier.isModelLoaded;

  /// Initialise the TFLite model. Call this at app startup.
  ///
  /// If loading fails, the engine operates in threshold-only mode.
  Future<void> loadModel() async {
    final loaded = await _classifier.loadModel();
    AppLogger.info(
      '[CrashFallDetection] ML model ${loaded ? 'loaded — hybrid mode' : 'unavailable — threshold-only mode'}',
    );
  }

  /// Start the detection engine.
  ///
  /// [onDetection] is called when a crash/fall event is detected
  /// with confidence above [minConfidence].
  void start({required void Function(DetectionEvent) onDetection}) {
    if (_isRunning) return;
    _isRunning = true;
    _onDetection = onDetection;
    _signalProcessor.reset();

    _subscription = accelerometerEventStream(
      samplingPeriod: Duration(microseconds: 1000000 ~/ samplingRateHz),
    ).listen(_onSensorData);
  }

  /// Stop the detection engine.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _postImpactTimer?.cancel();
    _postImpactTimer = null;
    _isRunning = false;
    _resetImpactState();
  }

  /// Process a single accelerometer sample through the detection pipeline.
  void _onSensorData(AccelerometerEvent event) {
    // Phase 1: Signal processing.
    final result = _signalProcessor.addSample(event.x, event.y, event.z);
    final gForce = result.gForce;

    // Check for freefall (precedes many impacts).
    if (gForce < 0.3) {
      _hadFreefall = true;
    }

    // Phase 2: Impact detection.
    if (!_impactDetected && gForce >= fallThresholdG) {
      _impactDetected = true;
      _impactTime = DateTime.now();
      _impactPeakG = gForce;

      // Start post-impact observation window.
      _postImpactTimer?.cancel();
      _postImpactTimer = Timer(
        Duration(milliseconds: postImpactWindowMs),
        _analyzePostImpact,
      );
    }

    // Track peak G during impact window.
    if (_impactDetected && gForce > _impactPeakG) {
      _impactPeakG = gForce;
    }
  }

  /// Phase 3 & 4: Analyze patterns after impact window expires.
  void _analyzePostImpact() {
    if (!_impactDetected) return;

    // Check cooldown.
    if (_lastDetectionTime != null) {
      final elapsed = DateTime.now().difference(_lastDetectionTime!);
      if (elapsed < cooldownDuration) {
        _resetImpactState();
        return;
      }
    }

    // Get post-impact analysis from signal processor.
    final hasStillness = _signalProcessor.hasPostImpactStillness;
    final jerk = _signalProcessor.computeJerk(
      deltaTimeSeconds: 1.0 / samplingRateHz,
    );
    final smvVariance = _signalProcessor.computeSmvVariance();

    // Phase 3: Classify event type.
    final DetectionType type;
    if (_impactPeakG >= crashThresholdG && !_hadFreefall) {
      type = DetectionType.vehicleCrash;
    } else if (_hadFreefall && hasStillness) {
      type = DetectionType.fall;
    } else if (_impactPeakG >= hardImpactThresholdG) {
      type = DetectionType.hardImpact;
    } else if (_hadFreefall ||
        hasStillness ||
        _impactPeakG >= crashThresholdG) {
      // Freefall OR stillness with moderate G — classify as fall.
      type = DetectionType.fall;
    } else {
      // Sub-threshold event — likely phone drop or bump.
      _resetImpactState();
      return;
    }

    // Phase 4: Hybrid confidence scoring.
    final double thresholdConfidence = _computeConfidence(
      type: type,
      peakG: _impactPeakG,
      hadFreefall: _hadFreefall,
      hasStillness: hasStillness,
      jerk: jerk,
      variance: smvVariance,
    );

    // Phase 4b: ML confidence (if model available).
    double confidence = thresholdConfidence;
    if (_classifier.isModelLoaded) {
      final rawSamples = _signalProcessor.rawSamples;
      final features = _featureExtractor.extract(rawSamples);
      if (features != null) {
        final result = _classifier.classify(features);
        if (result != null) {
          final mlConfidence = type == DetectionType.fall
              ? result.fallConfidence
              : type == DetectionType.vehicleCrash
                  ? result.crashConfidence
                  : result.maxConfidence;
          confidence = (1 - mlWeight) * thresholdConfidence +
              mlWeight * mlConfidence;
          AppLogger.info(
            '[CrashFallDetection] Hybrid score: '
            'threshold=${thresholdConfidence.toStringAsFixed(3)}, '
            'ml=${mlConfidence.toStringAsFixed(3)}, '
            'final=${confidence.toStringAsFixed(3)}',
          );
        }
      }
    }

    // Suppress low-confidence events.
    if (confidence < minConfidence) {
      _resetImpactState();
      return;
    }

    // Emit detection event.
    final detectionEvent = DetectionEvent(
      type: type,
      confidence: confidence,
      peakGForce: _impactPeakG,
      timestamp: _impactTime ?? DateTime.now(),
      hadFreefall: _hadFreefall,
      postImpactStillness: hasStillness,
    );

    AppLogger.info('[CrashFallDetection] $detectionEvent');

    _lastDetectionTime = DateTime.now();
    _onDetection?.call(detectionEvent);
    _resetImpactState();
  }

  /// Compute confidence score (0.0–1.0) using weighted signals.
  ///
  /// Weights are based on signal reliability from research:
  /// - G-force magnitude: 40% (primary indicator)
  /// - Post-impact stillness: 25% (strong fall indicator)
  /// - Freefall: 20% (precursor signal)
  /// - Jerk/variance: 15% (onset sharpness)
  double _computeConfidence({
    required DetectionType type,
    required double peakG,
    required bool hadFreefall,
    required bool hasStillness,
    required double jerk,
    required double variance,
  }) {
    double score = 0;

    // G-force score (40%): Normalized relative to detection threshold.
    final threshold = type == DetectionType.vehicleCrash
        ? crashThresholdG
        : fallThresholdG;
    final gRatio = (peakG / threshold).clamp(0.0, 3.0) / 3.0;
    score += gRatio * 0.40;

    // Stillness score (25%): Strong indicator for falls.
    if (hasStillness) {
      score += 0.25;
    }

    // Freefall score (20%): Precursor signal.
    if (hadFreefall) {
      score += 0.20;
    }

    // Jerk/variance score (15%): Sharper onset = more likely real event.
    final jerkScore = (jerk / 500.0).clamp(0.0, 1.0);
    score += jerkScore * 0.15;

    return score.clamp(0.0, 1.0);
  }

  void _resetImpactState() {
    _impactDetected = false;
    _impactTime = null;
    _impactPeakG = 0;
    _hadFreefall = false;
  }

  /// Release all resources.
  void dispose() {
    stop();
    _classifier.dispose();
    _onDetection = null;
  }
}
