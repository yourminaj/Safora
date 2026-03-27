import 'dart:async';
import '../../core/constants/alert_types.dart';
import '../../core/services/app_logger.dart';
import 'crash_fall_detection_engine.dart';

/// Service that wraps the [CrashFallDetectionEngine] and integrates
/// with the Safora alert system.
///
/// Maps detection events to [AlertType] values and provides a
/// simplified API for the presentation layer.
///
/// When [currentSpeedKmh] is set (e.g., by [SpeedAlertService]),
/// vehicle crash detections are refined into specific types:
/// - Walking (<7 km/h) → pedestrian hit
/// - Cycling (15–40 km/h) → bicycle crash
/// - Motorcycle (40–120 km/h) → motorcycle crash
/// - Car (>120 km/h or no speed data) → car accident
class CrashFallDetectionService {
  CrashFallDetectionService({
    CrashFallDetectionEngine? engine,
  }) : _engine = engine ?? CrashFallDetectionEngine();

  final CrashFallDetectionEngine _engine;

  /// Stream controller for detection events.
  final StreamController<DetectionAlert> _alertController =
      StreamController<DetectionAlert>.broadcast();

  /// Stream of detection alerts for the presentation layer.
  Stream<DetectionAlert> get alerts => _alertController.stream;

  /// Whether the detection engine is currently running.
  bool get isRunning => _engine.isRunning;

  /// Current GPS speed in km/h (set externally by SpeedAlertService).
  ///
  /// Used to refine vehicle crash classification.
  /// If null, defaults to car accident classification.
  double? currentSpeedKmh;

  /// Start crash/fall monitoring.
  ///
  /// Loads the TFLite model first, then starts the sensor pipeline.
  /// If model loading fails, the engine falls back to threshold-only mode.
  Future<void> start() async {
    await _engine.loadModel();
    _engine.start(
      onDetection: _handleDetection,
    );
    AppLogger.info('[CrashFallDetectionService] Started monitoring '
        '(ML: ${_engine.isModelLoaded ? "hybrid" : "threshold-only"})');
  }

  /// Stop crash/fall monitoring.
  void stop() {
    _engine.stop();
    AppLogger.info('[CrashFallDetectionService] Stopped monitoring');
  }

  void _handleDetection(DetectionEvent event) {
    final alertType = _mapToAlertType(event.type);
    final severity = _mapToSeverity(event.confidence);

    final alert = DetectionAlert(
      alertType: alertType,
      detectionType: event.type,
      severity: severity,
      confidence: event.confidence,
      peakGForce: event.peakGForce,
      timestamp: event.timestamp,
      title: _generateTitle(event, alertType),
      message: _generateMessage(event, alertType),
    );

    _alertController.add(alert);
  }

  AlertType _mapToAlertType(DetectionType type) {
    return switch (type) {
      DetectionType.fall => AlertType.elderlyFall,
      DetectionType.vehicleCrash => _classifyVehicleCrash(),
      DetectionType.hardImpact => AlertType.fainting,
    };
  }

  /// Classify vehicle crash type based on GPS speed at time of impact.
  AlertType _classifyVehicleCrash() {
    final speed = currentSpeedKmh;
    if (speed == null) return AlertType.carAccident;

    if (speed < 7) return AlertType.pedestrianHit;
    if (speed < 40) return AlertType.bicycleCrash;
    if (speed < 120) return AlertType.motorcycleCrash;
    return AlertType.carAccident;
  }

  AlertPriority _mapToSeverity(double confidence) {
    if (confidence >= 0.8) return AlertPriority.critical;
    if (confidence >= 0.6) return AlertPriority.danger;
    if (confidence >= 0.4) return AlertPriority.warning;
    return AlertPriority.advisory;
  }

  String _generateTitle(DetectionEvent event, AlertType alertType) {
    final conf = '${(event.confidence * 100).toInt()}%';
    return switch (alertType) {
      AlertType.elderlyFall => 'Fall Detected ($conf confidence)',
      AlertType.carAccident => 'Car Crash Detected ($conf confidence)',
      AlertType.motorcycleCrash =>
        'Motorcycle Crash Detected ($conf confidence)',
      AlertType.bicycleCrash =>
        'Bicycle Crash Detected ($conf confidence)',
      AlertType.pedestrianHit =>
        'Pedestrian Impact Detected ($conf confidence)',
      AlertType.fainting => 'Hard Impact ($conf confidence)',
      _ =>
        'Impact Detected ($conf confidence)',
    };
  }

  String _generateMessage(DetectionEvent event, AlertType alertType) {
    final details = <String>[];
    details.add('Peak: ${event.peakGForce.toStringAsFixed(1)}G');

    if (event.hadFreefall) {
      details.add('Freefall detected before impact');
    }
    if (event.postImpactStillness) {
      details.add('No movement after impact');
    }
    if (currentSpeedKmh != null) {
      details.add('Speed: ${currentSpeedKmh!.toStringAsFixed(0)} km/h');
    }

    return switch (alertType) {
      AlertType.elderlyFall =>
        'A possible fall has been detected. ${details.join('. ')}. '
            'SOS will trigger if not cancelled.',
      AlertType.carAccident ||
      AlertType.motorcycleCrash ||
      AlertType.bicycleCrash =>
        'A possible ${alertType.label.toLowerCase()} has been detected. '
            '${details.join('. ')}. '
            'Emergency contacts will be notified.',
      AlertType.pedestrianHit =>
        'A possible pedestrian impact has been detected. '
            '${details.join('. ')}. '
            'Are you okay? SOS will trigger if not cancelled.',
      AlertType.fainting =>
        'A hard impact has been detected. ${details.join('. ')}. '
            'Are you okay?',
      _ =>
        'An impact has been detected. ${details.join('. ')}.',
    };
  }

  /// Release all resources.
  void dispose() {
    _engine.dispose();
    _alertController.close();
  }
}


/// Alert emitted by the detection service for the presentation layer.
class DetectionAlert {
  const DetectionAlert({
    required this.alertType,
    required this.detectionType,
    required this.severity,
    required this.confidence,
    required this.peakGForce,
    required this.timestamp,
    required this.title,
    required this.message,
  });

  /// Safora alert type for integration with the alert system.
  final AlertType alertType;

  /// The raw detection classification.
  final DetectionType detectionType;

  /// Severity level for notification/SOS logic.
  final AlertPriority severity;

  /// Confidence score (0.0 – 1.0).
  final double confidence;

  /// Peak G-force during the event.
  final double peakGForce;

  /// When the event was detected.
  final DateTime timestamp;

  /// Human-readable title for notifications.
  final String title;

  /// Human-readable description for notifications.
  final String message;
}
