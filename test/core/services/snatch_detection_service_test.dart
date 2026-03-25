import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/snatch_detection_service.dart';

void main() {
  group('SnatchDetectionService', () {
    late SnatchDetectionService service;

    setUp(() {
      service = SnatchDetectionService(
        snatchThresholdG: 5.0,
        cooldownDuration: const Duration(seconds: 30),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not running', () {
      expect(service.isRunning, isFalse);
    });

    test('custom threshold is configurable', () {
      final custom = SnatchDetectionService(snatchThresholdG: 8.0);
      expect(custom.snatchThresholdG, 8.0);
      custom.dispose();
    });

    test('stop is safe when not running', () {
      expect(() => service.stop(), returnsNormally);
      expect(service.isRunning, isFalse);
    });

    test('dispose is safe when not running', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('double stop does not throw', () {
      service.stop();
      expect(() => service.stop(), returnsNormally);
    });

    test('default cooldown is 30 seconds', () {
      expect(service.cooldownDuration.inSeconds, 30);
    });
  });
}
