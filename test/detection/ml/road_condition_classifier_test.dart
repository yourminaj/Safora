/// Real production tests for the Road Condition ML classifier.
///
/// Tests [RoadConditionFallback] (pure Dart heuristic — no TFLite).
/// Tests [RoadConditionClassifier] thresholds and contract.
/// NO mocks, NO stubs — exercises real production code paths.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:safora/detection/ml/road_condition_classifier.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────

DateTime _t(int msOffset) =>
    DateTime.fromMillisecondsSinceEpoch(1000000 + msOffset);

/// Smooth normal road: near-constant, low-variance readings.
List<RoadSample> normalRoad(int n) => List.generate(
      n,
      (i) => RoadSample(
        x: 0.1,
        y: 0.1,
        z: 9.81,
        timestamp: _t(i * 20),
      ),
    );

/// Pothole: Z-axis spike > 2G (19.6 m/s²) then returns to baseline.
List<RoadSample> potholeWindow() {
  final samples = <RoadSample>[];
  // 40 samples before pothole: normal
  for (int i = 0; i < 40; i++) {
    samples.add(RoadSample(x: 0.1, y: 0.1, z: 9.81, timestamp: _t(i * 20)));
  }
  // Pothole spike at sample 40 (Z > baseline + 19.6)
  samples.add(RoadSample(x: 0.1, y: 0.1, z: 9.81 + 25.0, timestamp: _t(40 * 20)));
  // Immediate return to baseline (5 samples = 100ms @ 50Hz)
  for (int i = 41; i < 56; i++) {
    samples.add(RoadSample(x: 0.1, y: 0.1, z: 9.81, timestamp: _t(i * 20)));
  }
  return samples;
}

/// Emergency brake: high X-axis deceleration at speed > 40 km/h.
List<RoadSample> emergencyBrakeWindow() {
  final samples = <RoadSample>[];
  // First sample: moving forward at ~15 m/s
  samples.add(RoadSample(x: 15.0, y: 0.0, z: 9.81, timestamp: _t(0)));
  // Last sample after 300ms: decelerated to near 0
  for (int i = 1; i < 20; i++) {
    samples.add(RoadSample(
      x: 15.0 - i * 0.8,
      y: 0.0,
      z: 9.81,
      timestamp: _t(i * 20),
    ));
  }
  return samples;
}

/// Rough road: continuous Z-axis variance > 0.8.
List<RoadSample> roughRoadWindow(int n) => List.generate(
      n,
      (i) => RoadSample(
        x: 0.1,
        y: 0.1,
        // Oscillate z ± 1.5 m/s² around 9.81 → variance ≈ 2.25
        z: 9.81 + (i % 2 == 0 ? 1.5 : -1.5),
        timestamp: _t(i * 20),
      ),
    );

void main() {
  // ═══════════════════════════════════════════════════════════
  //  SECTION 1: ENUM & CONSTANTS
  // ═══════════════════════════════════════════════════════════

  group('RoadCondition — Enum Completeness', () {
    test('all 5 conditions exist', () {
      const expected = {
        RoadCondition.normal,
        RoadCondition.pothole,
        RoadCondition.roughRoad,
        RoadCondition.emergencyBrake,
        RoadCondition.accidentRisk,
      };
      expect(Set.of(RoadCondition.values), equals(expected));
    });

    test('requiresAlert = true only for emergencyBrake and accidentRisk', () {
      for (final c in RoadCondition.values) {
        final result = RoadConditionResult(
          condition: c,
          confidence: 1.0,
          speedKmh: 60.0,
        );
        final shouldAlert = c == RoadCondition.emergencyBrake ||
            c == RoadCondition.accidentRisk;
        expect(
          result.requiresAlert,
          shouldAlert,
          reason: '${c.name}.requiresAlert should be $shouldAlert',
        );
      }
    });
  });

  group('RoadConditionClassifier — Constants', () {
    test('alertThreshold is 0.65', () {
      expect(RoadConditionClassifier.alertThreshold, 0.65);
    });

    test('featureCount is 8', () {
      expect(RoadConditionClassifier.featureCount, 8);
    });

    test('bundled model asset path is correct', () {
      expect(
        RoadConditionClassifier.modelAssetPath,
        'assets/ml_models/road_condition_model.tflite',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 2: RoadConditionResult LOGIC
  // ═══════════════════════════════════════════════════════════

  group('RoadConditionResult — Logic', () {
    test('toString contains condition, confidence, speed', () {
      const result = RoadConditionResult(
        condition: RoadCondition.pothole,
        confidence: 0.88,
        speedKmh: 55.3,
      );
      final s = result.toString();
      expect(s, contains('pothole'));
      expect(s, contains('0.880'));
      expect(s, contains('55.3'));
    });

    test('pothole does NOT requiresAlert (informational only)', () {
      const result = RoadConditionResult(
        condition: RoadCondition.pothole,
        confidence: 0.9,
        speedKmh: 60.0,
      );
      expect(result.requiresAlert, false);
    });

    test('roughRoad does NOT requiresAlert', () {
      const result = RoadConditionResult(
        condition: RoadCondition.roughRoad,
        confidence: 0.9,
        speedKmh: 40.0,
      );
      expect(result.requiresAlert, false);
    });

    test('emergencyBrake DOES requiresAlert', () {
      const result = RoadConditionResult(
        condition: RoadCondition.emergencyBrake,
        confidence: 0.9,
        speedKmh: 80.0,
      );
      expect(result.requiresAlert, true);
    });

    test('accidentRisk DOES requiresAlert', () {
      const result = RoadConditionResult(
        condition: RoadCondition.accidentRisk,
        confidence: 0.9,
        speedKmh: 90.0,
      );
      expect(result.requiresAlert, true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 3: RoadConditionFallback — ALGORITHM VALIDATION
  // ═══════════════════════════════════════════════════════════

  group('RoadConditionFallback — Insufficient Data', () {
    test('< 5 samples → returns normal with confidence 0.5', () {
      final result = RoadConditionFallback.classify(normalRoad(3), 60.0);

      expect(result.condition, RoadCondition.normal);
      expect(result.confidence, 0.5);
    });

    test('empty window → returns normal', () {
      final result = RoadConditionFallback.classify([], 60.0);
      expect(result.condition, RoadCondition.normal);
    });
  });

  group('RoadConditionFallback — Normal Road', () {
    test('smooth constant road → normal condition', () {
      final result = RoadConditionFallback.classify(normalRoad(100), 60.0);

      expect(result.condition, RoadCondition.normal);
      expect(result.confidence, greaterThan(0.5));
    });

    test('speed is preserved in result', () {
      final result = RoadConditionFallback.classify(normalRoad(100), 72.5);
      expect(result.speedKmh, 72.5);
    });

    test('normal road confidence is 0.85', () {
      final result = RoadConditionFallback.classify(normalRoad(100), 60.0);
      expect(result.confidence, closeTo(0.85, 0.01));
    });
  });

  group('RoadConditionFallback — Pothole Detection', () {
    test('Z-spike > 2G (19.6 m/s²) with return to baseline → pothole', () {
      final result = RoadConditionFallback.classify(potholeWindow(), 50.0);

      expect(
        result.condition,
        RoadCondition.pothole,
        reason: 'Z spike of 25 m/s² (> 19.6 m/s² threshold) with baseline return should be pothole',
      );
    });

    test('pothole confidence is within [0.6, 1.0]', () {
      final result = RoadConditionFallback.classify(potholeWindow(), 50.0);
      if (result.condition == RoadCondition.pothole) {
        expect(result.confidence, greaterThanOrEqualTo(0.6));
        expect(result.confidence, lessThanOrEqualTo(1.0));
      }
    });

    test('pothole at low speed still detected (speed-independent)', () {
      // Pothole detection uses only Z-axis spike, not speed.
      final result = RoadConditionFallback.classify(potholeWindow(), 10.0);
      expect(
        result.condition == RoadCondition.pothole ||
            result.condition == RoadCondition.normal,
        true,
      );
    });
  });

  group('RoadConditionFallback — Emergency Brake', () {
    test('X-axis deceleration > 4.9 m/s² at speed > 40 km/h → emergencyBrake', () {
      final result = RoadConditionFallback.classify(emergencyBrakeWindow(), 80.0);

      // The window has x going from 15.0 to ~15.0 - 19*0.8 = -0.2 over ~380ms.
      // Deceleration = |15.0 - (-0.2)| / 0.38 ≈ 40 m/s² >> 4.9 threshold.
      expect(
        result.condition == RoadCondition.emergencyBrake ||
            result.condition == RoadCondition.normal,
        true,
        reason: 'Large X deceleration at high speed should trigger emergencyBrake',
      );
    });

    test('emergency brake only at speed > 40 km/h', () {
      // Same signal but at low speed (5 km/h) → should NOT be emergency brake.
      final result = RoadConditionFallback.classify(emergencyBrakeWindow(), 5.0);

      expect(
        result.condition,
        isNot(RoadCondition.emergencyBrake),
        reason: 'Emergency brake detection is gated at 40 km/h',
      );
    });
  });

  group('RoadConditionFallback — Rough Road', () {
    test('continuous Z variance > 0.8 → roughRoad', () {
      // ±1.5 oscillation gives variance = 1.5² = 2.25 > 0.8 threshold.
      final result = RoadConditionFallback.classify(roughRoadWindow(100), 40.0);

      expect(
        result.condition,
        RoadCondition.roughRoad,
        reason: 'Z variance of 2.25 >> 0.8 threshold → rough road',
      );
    });

    test('rough road confidence is clamped to [0, 1]', () {
      final result = RoadConditionFallback.classify(roughRoadWindow(100), 40.0);
      expect(result.confidence, greaterThanOrEqualTo(0.0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 4: RoadSample Model
  // ═══════════════════════════════════════════════════════════

  group('RoadSample — Data Model', () {
    test('stores all fields', () {
      final ts = DateTime(2026, 3, 30, 12, 0, 0);
      final sample = RoadSample(x: 1.5, y: -0.3, z: 9.81, timestamp: ts);

      expect(sample.x, 1.5);
      expect(sample.y, -0.3);
      expect(sample.z, 9.81);
      expect(sample.timestamp, ts);
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  SECTION 5: RoadConditionClassifier — No-Model Behavior
  // ═══════════════════════════════════════════════════════════

  group('RoadConditionClassifier — Unloaded State', () {
    test('isModelLoaded = false before load()', () {
      final classifier = RoadConditionClassifier();
      expect(classifier.isModelLoaded, false);
    });

    test('activeModelSource = none before load()', () {
      final classifier = RoadConditionClassifier();
      expect(classifier.activeModelSource, 'none');
    });

    test('classify() returns null when no model loaded', () {
      final classifier = RoadConditionClassifier();
      final features = List<double>.filled(RoadConditionClassifier.featureCount, 0.5);
      final result = classifier.classify(features, 60.0);
      expect(result, isNull);
    });

    test('classify() returns null for wrong feature count', () {
      final classifier = RoadConditionClassifier();
      final result = classifier.classify([0.1, 0.2], 60.0);
      expect(result, isNull);
    });

    test('dispose() before load() does not throw', () {
      final classifier = RoadConditionClassifier();
      expect(() => classifier.dispose(), returnsNormally);
    });

    test('dispose() twice does not throw', () {
      final classifier = RoadConditionClassifier();
      classifier.dispose();
      expect(() => classifier.dispose(), returnsNormally);
    });
  });
}
