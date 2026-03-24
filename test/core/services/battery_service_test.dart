import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/battery_service.dart';

void main() {
  group('BatteryService', () {
    test('can be instantiated', () {
      final service = BatteryService();
      expect(service, isNotNull);
    });

    test('isLow returns true for levels at or below threshold', () {
      expect(BatteryService.isLow(15), true);
      expect(BatteryService.isLow(10), true);
      expect(BatteryService.isLow(1), true);
    });

    test('isLow returns false for levels above threshold', () {
      expect(BatteryService.isLow(16), false);
      expect(BatteryService.isLow(50), false);
      expect(BatteryService.isLow(100), false);
    });

    test('isLow returns false for invalid levels', () {
      expect(BatteryService.isLow(0), false);
      expect(BatteryService.isLow(-1), false);
    });

    test('isCritical returns true for levels at or below critical threshold', () {
      expect(BatteryService.isCritical(5), true);
      expect(BatteryService.isCritical(3), true);
      expect(BatteryService.isCritical(1), true);
    });

    test('isCritical returns false for levels above critical threshold', () {
      expect(BatteryService.isCritical(6), false);
      expect(BatteryService.isCritical(15), false);
      expect(BatteryService.isCritical(100), false);
    });

    test('isCritical returns false for invalid levels', () {
      expect(BatteryService.isCritical(0), false);
      expect(BatteryService.isCritical(-1), false);
    });

    test('lowThreshold is 15', () {
      expect(BatteryService.lowThreshold, 15);
    });

    test('criticalThreshold is 5', () {
      expect(BatteryService.criticalThreshold, 5);
    });

    test('stopMonitoring does not throw when not started', () {
      final service = BatteryService();
      expect(() => service.stopMonitoring(), returnsNormally);
    });

    test('dispose does not throw', () {
      final service = BatteryService();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
