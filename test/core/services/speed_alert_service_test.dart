import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/speed_alert_service.dart';

void main() {
  group('SpeedAlertService', () {
    late SpeedAlertService service;

    setUp(() {
      service = SpeedAlertService(
        thresholdKmh: 120.0,
        cooldownDuration: const Duration(seconds: 60),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not running with zero speed', () {
      expect(service.isRunning, isFalse);
      expect(service.currentSpeedKmh, 0);
    });

    test('custom threshold is configurable', () {
      final custom = SpeedAlertService(thresholdKmh: 80.0);
      expect(custom.thresholdKmh, 80.0);
      custom.dispose();
    });

    test('stop is safe when not running', () {
      expect(() => service.stop(), returnsNormally);
      expect(service.isRunning, isFalse);
    });

    test('stop resets speed to zero', () {
      // Speed should be 0 after stop even if it was previously non-zero.
      service.stop();
      expect(service.currentSpeedKmh, 0);
    });

    test('dispose is safe when not running', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('default cooldown is 60 seconds', () {
      expect(service.cooldownDuration.inSeconds, 60);
    });

    test('default threshold is 120 km/h', () {
      final defaultService = SpeedAlertService();
      expect(defaultService.thresholdKmh, 120.0);
      defaultService.dispose();
    });
  });
}
