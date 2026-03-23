import 'dart:async';
import '../../core/constants/alert_types.dart';
import '../../core/services/app_logger.dart';
import 'crash_fall_detection_engine.dart';

/// Service that wraps the [CrashFallDetectionEngine] and integrates
/// with the Safora alert system.
///
/// Maps detection events to [AlertType] values and provides a
/// simplified API for the presentation layer.
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

  /// Start crash/fall monitoring.
  void start() {
    _engine.start(
      onDetection: _handleDetection,
    );
    AppLogger.info('[CrashFallDetectionService] Started monitoring');
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
      title: _generateTitle(event),
      message: _generateMessage(event),
    );

    _alertController.add(alert);
  }

  AlertType _mapToAlertType(DetectionType type) {
    return switch (type) {
      DetectionType.fall => AlertType.elderlyFall,
      DetectionType.vehicleCrash => AlertType.carAccident,
      DetectionType.hardImpact => AlertType.fainting,
    };
  }

  AlertPriority _mapToSeverity(double confidence) {
    if (confidence >= 0.8) return AlertPriority.critical;
    if (confidence >= 0.6) return AlertPriority.high;
    if (confidence >= 0.4) return AlertPriority.medium;
    return AlertPriority.low;
  }

  String _generateTitle(DetectionEvent event) {
    return switch (event.type) {
      DetectionType.fall =>
        '⚠️ Fall Detected (${(event.confidence * 100).toInt()}% confidence)',
      DetectionType.vehicleCrash =>
        '🚨 Crash Detected (${(event.confidence * 100).toInt()}% confidence)',
      DetectionType.hardImpact =>
        '💥 Hard Impact (${(event.confidence * 100).toInt()}% confidence)',
    };
  }

  String _generateMessage(DetectionEvent event) {
    final details = <String>[];
    details.add('Peak: ${event.peakGForce.toStringAsFixed(1)}G');

    if (event.hadFreefall) {
      details.add('Freefall detected before impact');
    }
    if (event.postImpactStillness) {
      details.add('No movement after impact');
    }

    return switch (event.type) {
      DetectionType.fall =>
        'A possible fall has been detected. ${details.join('. ')}. '
            'SOS will trigger if not cancelled.',
      DetectionType.vehicleCrash =>
        'A possible vehicle crash has been detected. ${details.join('. ')}. '
            'Emergency contacts will be notified.',
      DetectionType.hardImpact =>
        'A hard impact has been detected. ${details.join('. ')}. '
            'Are you okay?',
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
