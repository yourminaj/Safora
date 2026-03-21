import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/shake_detection_service.dart';

void main() {
  late ShakeDetectionService service;

  setUp(() {
    service = ShakeDetectionService(
      shakeThreshold: 15.0,
      shakeCount: 3,
      shakeWindowMs: 800,
    );
  });

  tearDown(() {
    service.dispose();
  });

  group('ShakeDetectionService', () {
    test('has correct default configuration', () {
      final defaultService = ShakeDetectionService();

      expect(defaultService.shakeThreshold, 15.0);
      expect(defaultService.shakeCount, 3);
      expect(defaultService.shakeWindowMs, 800);
      expect(defaultService.isEnabled, false);

      defaultService.dispose();
    });

    test('accepts custom configuration', () {
      final custom = ShakeDetectionService(
        shakeThreshold: 20.0,
        shakeCount: 5,
        shakeWindowMs: 1000,
      );

      expect(custom.shakeThreshold, 20.0);
      expect(custom.shakeCount, 5);
      expect(custom.shakeWindowMs, 1000);

      custom.dispose();
    });

    test('isEnabled is false before startListening', () {
      expect(service.isEnabled, false);
    });

    test('stopListening resets isEnabled', () {
      // Can't start listening without real accelerometer in unit test,
      // but stopListening should be safe to call regardless.
      service.stopListening();
      expect(service.isEnabled, false);
    });

    test('dispose cleans up and resets state', () {
      service.dispose();
      expect(service.isEnabled, false);
    });

    test('double dispose is safe', () {
      service.dispose();
      service.dispose(); // Should not throw.
      expect(service.isEnabled, false);
    });
  });
}
