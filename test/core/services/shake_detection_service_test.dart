import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/shake_detection_service.dart';

void main() {
  group('ShakeDetectionService — Configuration', () {
    test('has correct default configuration', () {
      final svc = ShakeDetectionService();
      expect(svc.shakeThreshold, 15.0);
      expect(svc.shakeCount, 3);
      expect(svc.shakeWindowMs, 800);
      expect(svc.isEnabled, false);
      // Do NOT call svc.dispose() — startListening was never called,
      // so there is no platform subscription to cancel.
    });

    test('accepts custom configuration', () {
      final svc = ShakeDetectionService(
        shakeThreshold: 20.0,
        shakeCount: 5,
        shakeWindowMs: 1000,
      );
      expect(svc.shakeThreshold, 20.0);
      expect(svc.shakeCount, 5);
      expect(svc.shakeWindowMs, 1000);
    });

    test('stopListening when never started is safe', () {
      final svc = ShakeDetectionService();
      svc.stopListening(); // no subscription to cancel
      expect(svc.isEnabled, false);
    });
  });

  // ── Pure detection algorithm tests ──────────────────────────────────────
  // These tests call processAccelerometerEvent() directly — NO hardware
  // stream is opened, so no MissingPluginException is possible.
  group('ShakeDetectionService — Real Detection Logic', () {
    late ShakeDetectionService svc;
    late int callCount;

    setUp(() {
      callCount = 0;
      svc = ShakeDetectionService(
        shakeThreshold: 15.0,
        shakeCount: 3,
        shakeWindowMs: 800,
      );
      // Register the callback WITHOUT opening the hardware stream.
      svc.startListening(
        onShakeDetected: () => callCount++,
        // NOTE: In real production the hardware stream starts here.
        // In tests we skip that by calling processAccelerometerEvent directly.
        skipStream: true,
      );
    });

    tearDown(() {
      // stopListening is safe because skipStream=true never opened a subscription.
      svc.stopListening();
    });

    test('single shake below threshold does NOT trigger callback', () {
      // magnitude sqrt(5^2+5^2+5^2) ≈ 8.66 — below 15.0
      svc.processAccelerometerEvent(5.0, 5.0, 5.0);
      svc.processAccelerometerEvent(5.0, 5.0, 5.0);
      expect(callCount, 0);
    });

    test('2 shakes above threshold does NOT trigger (need 3)', () {
      // magnitude sqrt(10^2+10^2+10^2) ≈ 17.3 — above 15.0
      svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      expect(callCount, 0);
    });

    test('exactly 3 shakes above threshold TRIGGERS callback', () {
      for (int i = 0; i < 3; i++) {
        svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      }
      expect(callCount, 1);
    });

    test('6 shakes = 2 callback triggers (counter resets after each detection)', () {
      for (int i = 0; i < 6; i++) {
        svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      }
      expect(callCount, 2);
    });

    test('processAccelerometerEvent returns true only when shake fires', () {
      final r1 = svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      final r2 = svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      final r3 = svc.processAccelerometerEvent(10.0, 10.0, 10.0); // fires
      expect(r1, false);
      expect(r2, false);
      expect(r3, true);
    });

    test('high X-axis spike triggers shake correctly', () {
      // Single axis spike: magnitude = 20 > 15
      for (int i = 0; i < 3; i++) {
        svc.processAccelerometerEvent(20.0, 0.0, 0.0);
      }
      expect(callCount, 1);
    });

    test('normal walking noise never triggers false positive', () {
      // Normal walking: ~2–4 m/s² — well below 15.0 threshold
      for (int i = 0; i < 100; i++) {
        svc.processAccelerometerEvent(1.0, 2.0, 1.5); // magnitude ≈ 2.7
      }
      expect(callCount, 0);
    });

    test('stopListening prevents further shake detection', () {
      svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      svc.stopListening();
      // Even if we call process directly, callback should be gone
      svc.processAccelerometerEvent(10.0, 10.0, 10.0);
      expect(callCount, 0); // callback was cleared on stop
      expect(svc.isEnabled, false);
    });
  });
}
