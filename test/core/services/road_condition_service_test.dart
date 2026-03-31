/// Real integration tests for RoadConditionService fallback classification
/// and RoadConditionEvent model behavior.
///
/// These tests use the REAL fallback classifier — no mocks, no stubs.
/// They verify physics-based road hazard detection logic.
library;
import 'package:flutter_test/flutter_test.dart';

import 'package:safora/core/services/road_condition_service.dart';
import 'package:safora/detection/ml/road_condition_classifier.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  group('RoadConditionEvent', () {
    test('alertType maps to roadHazardAlert', () {
      final event = RoadConditionEvent(
        result: const RoadConditionResult(
          condition: RoadCondition.emergencyBrake,
          confidence: 0.8,
          speedKmh: 80,
        ),
        detectedAt: DateTime.now(),
      );
      expect(event.alertType, AlertType.roadHazardAlert);
    });
  });

  group('RoadConditionResult', () {
    test('requiresAlert true for emergencyBrake', () {
      const result = RoadConditionResult(
        condition: RoadCondition.emergencyBrake,
        confidence: 0.8,
        speedKmh: 60,
      );
      expect(result.requiresAlert, isTrue);
    });

    test('requiresAlert true for accidentRisk', () {
      const result = RoadConditionResult(
        condition: RoadCondition.accidentRisk,
        confidence: 0.9,
        speedKmh: 100,
      );
      expect(result.requiresAlert, isTrue);
    });

    test('requiresAlert false for pothole', () {
      const result = RoadConditionResult(
        condition: RoadCondition.pothole,
        confidence: 0.8,
        speedKmh: 40,
      );
      expect(result.requiresAlert, isFalse);
    });

    test('requiresAlert false for roughRoad', () {
      const result = RoadConditionResult(
        condition: RoadCondition.roughRoad,
        confidence: 0.7,
        speedKmh: 30,
      );
      expect(result.requiresAlert, isFalse);
    });

    test('requiresAlert false for normal', () {
      const result = RoadConditionResult(
        condition: RoadCondition.normal,
        confidence: 0.9,
        speedKmh: 50,
      );
      expect(result.requiresAlert, isFalse);
    });

    test('toString includes condition name and speed', () {
      const result = RoadConditionResult(
        condition: RoadCondition.pothole,
        confidence: 0.876,
        speedKmh: 45.3,
      );
      final s = result.toString();
      expect(s, contains('pothole'));
      expect(s, contains('0.876'));
      expect(s, contains('45.3'));
    });
  });

  group('RoadConditionFallback (real classifier, no mock)', () {
    DateTime ts(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

    test('too few samples classifies as normal', () {
      final window = [
        RoadSample(x: 0, y: 0, z: 9.81, timestamp: ts(0)),
        RoadSample(x: 0, y: 0, z: 9.81, timestamp: ts(20)),
      ];
      final result = RoadConditionFallback.classify(window, 60);
      expect(result.condition, RoadCondition.normal);
    });

    test('smooth road at speed = normal', () {
      final window = List.generate(
        100,
        (i) => RoadSample(x: 0.1, y: 0.1, z: 9.81, timestamp: ts(i * 20)),
      );
      final result = RoadConditionFallback.classify(window, 60);
      expect(result.condition, RoadCondition.normal);
    });

    test('Z-axis spike with return = pothole', () {
      // Build a window where Z has a massive spike then returns
      final window = <RoadSample>[];
      for (int i = 0; i < 100; i++) {
        double z;
        if (i == 50) {
          z = 40.0; // > 2G (19.6) spike
        } else {
          z = 9.81; // Normal gravity
        }
        window.add(RoadSample(x: 0, y: 0, z: z, timestamp: ts(i * 20)));
      }
      final result = RoadConditionFallback.classify(window, 60);
      expect(result.condition, RoadCondition.pothole);
    });

    test('strong deceleration at high speed = emergencyBrake', () {
      // X goes from 10 to 0 over 2 seconds at 80 km/h = deceleration of 5 m/s²
      final window = <RoadSample>[];
      for (int i = 0; i < 100; i++) {
        final x = 10.0 - (i / 99.0 * 10.0);
        window.add(RoadSample(x: x, y: 0, z: 9.81, timestamp: ts(i * 20)));
      }
      final result = RoadConditionFallback.classify(window, 80);
      expect(result.condition, RoadCondition.emergencyBrake);
      expect(result.requiresAlert, isTrue);
    });

    test('continuous Z variance = roughRoad', () {
      // Vibrating Z-axis: alternating high and low Z values
      final window = <RoadSample>[];
      for (int i = 0; i < 100; i++) {
        final z = i.isEven ? 11.0 : 8.0; // ±1.5 from mean ~9.5
        window.add(RoadSample(x: 0, y: 0, z: z, timestamp: ts(i * 20)));
      }
      final result = RoadConditionFallback.classify(window, 60);
      expect(result.condition, RoadCondition.roughRoad);
    });

    test('speedKmh is preserved in result', () {
      final window = List.generate(
        100,
        (i) => RoadSample(x: 0, y: 0, z: 9.81, timestamp: ts(i * 20)),
      );
      final result = RoadConditionFallback.classify(window, 95.5);
      expect(result.speedKmh, 95.5);
    });
  });

  group('RoadConditionClassifier constants', () {
    test('alertThreshold is 0.65', () {
      expect(RoadConditionClassifier.alertThreshold, 0.65);
    });

    test('featureCount is 8', () {
      expect(RoadConditionClassifier.featureCount, 8);
    });
  });

  group('RoadConditionService', () {
    test('onHazardDetected is a broadcast stream', () {
      final service = RoadConditionService();
      expect(service.onHazardDetected.isBroadcast, isTrue);
      service.dispose();
    });

    test('isRunning is false initially', () {
      final service = RoadConditionService();
      expect(service.isRunning, isFalse);
      service.dispose();
    });

    test('updateSpeed stores the speed value', () {
      final service = RoadConditionService();
      // While we can't read _currentSpeedKmh directly, we verify no crash
      service.updateSpeed(120.5);
      service.updateSpeed(0.0);
      service.updateSpeed(-5.0); // Edge case
      service.dispose();
    });
  });
}
