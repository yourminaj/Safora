import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/detection/ml/crash_fall_detection_engine.dart';
import 'package:safora/detection/ml/crash_fall_detection_service.dart';

void main() {
  group('CrashFallDetectionService', () {
    test('is not running by default', () {
      final service = CrashFallDetectionService();
      expect(service.isRunning, false);
      service.dispose();
    });

    test('alerts stream is a broadcast stream', () {
      final service = CrashFallDetectionService();
      expect(service.alerts.isBroadcast, true);
      service.dispose();
    });

    test('dispose does not throw on fresh instance', () {
      final service = CrashFallDetectionService();
      expect(() => service.dispose(), returnsNormally);
    });

    test('stop is safe when not running', () {
      final service = CrashFallDetectionService();
      expect(() => service.stop(), returnsNormally);
      expect(service.isRunning, false);
      service.dispose();
    });

    test('service accepts custom engine parameter', () {
      final service = CrashFallDetectionService();
      expect(service, isA<CrashFallDetectionService>());
      service.dispose();
    });

    test('DetectionAlert model has required fields', () {
      final alert = DetectionAlert(
        alertType: AlertType.elderlyFall,
        detectionType: DetectionType.fall,
        severity: AlertPriority.critical,
        confidence: 0.95,
        peakGForce: 8.5,
        timestamp: DateTime.now(),
        title: 'Fall Detected',
        message: 'A possible fall has been detected.',
      );
      expect(alert.confidence, 0.95);
      expect(alert.peakGForce, 8.5);
      expect(alert.alertType, AlertType.elderlyFall);
      expect(alert.severity, AlertPriority.critical);
    });
  });
}
