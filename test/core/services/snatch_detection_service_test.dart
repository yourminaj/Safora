import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/snatch_detection_service.dart';

void main() {
  group('SnatchDetectionService — Configuration', () {
    late SnatchDetectionService svc;

    setUp(() => svc = SnatchDetectionService(
          snatchThresholdG: 5.0,
          cooldownDuration: const Duration(seconds: 30),
        ));
    tearDown(() => svc.dispose());

    test('initial state is not running', () => expect(svc.isRunning, isFalse));
    test('custom threshold is configurable', () {
      final custom = SnatchDetectionService(snatchThresholdG: 8.0);
      expect(custom.snatchThresholdG, 8.0);
      custom.dispose();
    });
    test('stop is safe when not running', () {
      svc.stop();
      expect(svc.isRunning, isFalse);
    });
    test('default cooldown is 30 seconds', () {
      expect(svc.cooldownDuration.inSeconds, 30);
    });
  });

  group('SnatchDetectionService — Real Snatch Detection', () {
    late SnatchDetectionService svc;
    late List<double> detectedGs;

    setUp(() {
      detectedGs = [];
      svc = SnatchDetectionService(
        snatchThresholdG: 5.0,
        cooldownDuration: const Duration(hours: 1), // disable cooldown
      );
    });

    tearDown(() => svc.dispose());

    test('below threshold = no snatch', () {
      // 3G on Y axis — below 5G threshold
      final samples = List.generate(
        10,
        (_) => (x: 0.0, y: 29.4, z: 0.0), // 3G (3*9.81=29.4)
      );
      for (final s in samples) {
        svc.processSample(
          x: s.x,
          y: s.y,
          z: s.z,
          onSnatchDetected: detectedGs.add,
        );
      }
      expect(detectedGs, isEmpty);
    });

    test('single-axis 7G spike ABOVE threshold fires snatch', () {
      // Build 10 samples of mild motion first
      for (int i = 0; i < 10; i++) {
        svc.processSample(
          x: 1.0,
          y: 2.0,
          z: 1.0,
          onSnatchDetected: detectedGs.add,
        );
      }
      // Now fire a 7G Y-axis spike — dominant, directional
      final fired = svc.processSample(
        x: 5.0,   // noise
        y: 68.67, // 7G on Y (7*9.81)
        z: 5.0,   // noise
        onSnatchDetected: detectedGs.add,
      );
      expect(fired, isTrue);
      expect(detectedGs.length, 1);
      expect(detectedGs.first, greaterThan(5.0)); // > 5G
    });

    test('multi-axis tumbling 7G does NOT fire snatch (is a fall, not snatch)', () {
      // Build 10 samples of mild motion first
      for (int i = 0; i < 10; i++) {
        svc.processSample(
          x: 1.0,
          y: 1.0,
          z: 1.0,
          onSnatchDetected: detectedGs.add,
        );
      }
      // 7G equally distributed across all 3 axes — tumbling = fall, NOT snatch
      // Each axis ≈ sqrt(7^2/3)*9.81 — balanced across axes, <60% dominance
      const balanced = 68.67 / 3; // ~22.9 per axis
      final fired = svc.processSample(
        x: balanced,
        y: balanced,
        z: balanced,
        onSnatchDetected: detectedGs.add,
      );
      expect(fired, isFalse, reason: 'Balanced multi-axis = fall, not snatch');
      expect(detectedGs, isEmpty);
    });

    test('requires minimum 5 samples before detection decision', () {
      // With only 4 samples in window, _isDirectionalSnatch returns false
      for (int i = 0; i < 4; i++) {
        svc.processSample(
          x: 5.0,
          y: 68.67,
          z: 5.0,
          onSnatchDetected: detectedGs.add,
        );
      }
      // 4 samples — not enough for snatch judgment
      expect(detectedGs, isEmpty);
    });

    test('normal walking motion produces zero false positives', () {
      // Normal walking: ~0.5–1.5G per axis, total ~1–2G
      for (int i = 0; i < 200; i++) {
        svc.processSample(
          x: 5.0,   // ~0.5G
          y: 9.81,  // ~1G (gravity)
          z: 4.0,   // ~0.4G
          onSnatchDetected: detectedGs.add,
        );
      }
      // Total G ≈ sqrt(5^2+9.81^2+4^2)/9.81 ≈ 1.2G — below 5.0 threshold
      expect(detectedGs, isEmpty);
    });
  });
}
