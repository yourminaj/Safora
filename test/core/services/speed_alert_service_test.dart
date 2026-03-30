import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/speed_alert_service.dart';

void main() {
  group('SpeedAlertService — Configuration', () {
    test('has correct defaults', () {
      final svc = SpeedAlertService();
      expect(svc.thresholdKmh, 120.0);
      expect(svc.cooldownDuration.inSeconds, 60);
      expect(svc.isRunning, isFalse);
      expect(svc.currentSpeedKmh, 0);
      svc.dispose();
    });

    test('accepts custom threshold', () {
      final svc = SpeedAlertService(thresholdKmh: 80.0);
      expect(svc.thresholdKmh, 80.0);
      svc.dispose();
    });
  });

  group('SpeedAlertService — Real Speed Alert Logic', () {
    late SpeedAlertService svc;
    late List<double> alerts;
    late List<double> updates;

    setUp(() {
      alerts = [];
      updates = [];
      svc = SpeedAlertService(
        thresholdKmh: 120.0,
        cooldownDuration: const Duration(hours: 1), // disable cooldown
      );
    });

    tearDown(() => svc.dispose());

    test('speed at exactly threshold does NOT trigger alert', () {
      // 120 km/h = 33.33 m/s — threshold is > 120, so exactly 120 is safe
      svc.processPosition(
        speedMs: 33.33, // exactly 120 km/h
        onSpeedExceeded: alerts.add,
        onSpeedUpdate: updates.add,
      );
      expect(alerts, isEmpty);
      expect(updates, hasLength(1));
      expect(updates.first, closeTo(120.0, 0.1));
    });

    test('speed above threshold triggers alert with correct km/h', () {
      // 150 km/h = 41.67 m/s
      final triggered = svc.processPosition(
        speedMs: 41.67,
        onSpeedExceeded: alerts.add,
        onSpeedUpdate: updates.add,
      );
      expect(triggered, isTrue);
      expect(alerts.length, 1);
      expect(alerts.first, closeTo(150.0, 0.5));
    });

    test('speed below threshold fires onSpeedUpdate but NOT onSpeedExceeded', () {
      // 80 km/h = 22.22 m/s
      svc.processPosition(
        speedMs: 22.22,
        onSpeedExceeded: alerts.add,
        onSpeedUpdate: updates.add,
      );
      expect(alerts, isEmpty);
      expect(updates.length, 1);
      expect(updates.first, closeTo(80.0, 0.5));
    });

    test('m/s to km/h conversion is correct', () {
      svc.processPosition(
        speedMs: 27.78, // 100 km/h exactly
        onSpeedExceeded: alerts.add,
        onSpeedUpdate: updates.add,
      );
      expect(updates.first, closeTo(100.0, 0.1));
      expect(svc.currentSpeedKmh, closeTo(100.0, 0.1));
    });

    test('negative speed is clamped to zero', () {
      svc.processPosition(
        speedMs: -1.0,
        onSpeedExceeded: alerts.add,
        onSpeedUpdate: updates.add,
      );
      expect(svc.currentSpeedKmh, 0.0);
      expect(alerts, isEmpty);
    });

    test('cooldown prevents duplicate speed alerts', () {
      final cooldownSvc = SpeedAlertService(
        thresholdKmh: 120.0,
        cooldownDuration: const Duration(minutes: 5),
      );
      final t0 = DateTime.now();

      // First alert at t=0
      cooldownSvc.processPosition(
        speedMs: 41.67, // 150 km/h
        onSpeedExceeded: alerts.add,
        timestamp: t0,
      );
      // Second alert 30 seconds later — within 5 min cooldown
      cooldownSvc.processPosition(
        speedMs: 41.67,
        onSpeedExceeded: alerts.add,
        timestamp: t0.add(const Duration(seconds: 30)),
      );
      // Should only fire once
      expect(alerts.length, 1);

      // After cooldown expires, fires again
      cooldownSvc.processPosition(
        speedMs: 41.67,
        onSpeedExceeded: alerts.add,
        timestamp: t0.add(const Duration(minutes: 6)),
      );
      expect(alerts.length, 2);
      cooldownSvc.dispose();
    });

    test('multiple overspeeds with zero cooldown fire an alert each time', () {
      final zeroCooldownSvc = SpeedAlertService(
        thresholdKmh: 120.0,
        cooldownDuration: Duration.zero,
      );
      final multiAlerts = <double>[];
      final t0 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        zeroCooldownSvc.processPosition(
          speedMs: 41.67, // 150 km/h
          onSpeedExceeded: multiAlerts.add,
          timestamp: t0.add(Duration(milliseconds: i)),
        );
      }
      expect(multiAlerts.length, 5);
      zeroCooldownSvc.dispose();
    });

    test('highway cruising at exactly 120 does NOT spam alerts', () {
      for (int i = 0; i < 100; i++) {
        svc.processPosition(
          speedMs: 33.33, // 120.0 km/h — not strictly > 120
          onSpeedExceeded: alerts.add,
        );
      }
      // threshold is >, not >=
      expect(alerts, isEmpty);
    });

    test('stop resets currentSpeedKmh to zero', () {
      svc.processPosition(
        speedMs: 41.67,
        onSpeedExceeded: alerts.add,
      );
      expect(svc.currentSpeedKmh, greaterThan(0));
      svc.stop();
      expect(svc.currentSpeedKmh, 0.0);
    });
  });
}
