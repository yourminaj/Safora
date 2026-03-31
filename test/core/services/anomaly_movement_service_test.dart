/// Real integration tests for AnomalyMovementService fallback classification
/// and AnomalyMovementEvent model behavior.
///
/// These tests use the REAL fallback classifier — no mocks, no stubs.
/// They verify movement pattern recognition that runs when TFLite is unavailable.
library;
import 'package:flutter_test/flutter_test.dart';

import 'package:safora/core/services/anomaly_movement_service.dart';
import 'package:safora/detection/ml/anomaly_movement_classifier.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  group('AnomalyMovementEvent', () {
    test('alertType maps to suspiciousMovementSos', () {
      final event = AnomalyMovementEvent(
        result: AnomalyMovementResult(
          predictedClass: MovementClass.dragged,
          confidence: 0.85,
          probabilities: {for (final c in MovementClass.values) c: 0.2},
        ),
        detectedAt: DateTime.now(),
      );
      expect(event.alertType, AlertType.suspiciousMovementSos);
    });
  });

  group('AnomalyMovementResult', () {
    test('isAnomaly true for restrained', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.restrained,
        confidence: 0.8,
        probabilities: {},
      );
      expect(result.isAnomaly, isTrue);
    });

    test('isAnomaly true for unconscious', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.unconscious,
        confidence: 0.9,
        probabilities: {},
      );
      expect(result.isAnomaly, isTrue);
    });

    test('isAnomaly true for dragged', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.dragged,
        confidence: 0.7,
        probabilities: {},
      );
      expect(result.isAnomaly, isTrue);
    });

    test('isAnomaly false for normal', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.normal,
        confidence: 0.9,
        probabilities: {},
      );
      expect(result.isAnomaly, isFalse);
    });

    test('isAnomaly false for running', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.running,
        confidence: 0.95,
        probabilities: {},
      );
      expect(result.isAnomaly, isFalse);
    });

    test('toString includes class name and confidence', () {
      const result = AnomalyMovementResult(
        predictedClass: MovementClass.dragged,
        confidence: 0.876,
        probabilities: {},
      );
      final s = result.toString();
      expect(s, contains('dragged'));
      expect(s, contains('0.876'));
    });
  });

  group('AnomalyMovementFallback (real classifier, no mock)', () {
    test('too few samples classifies as normal', () {
      final window = List.generate(
        5,
        (_) => const AccelWindow(x: 0, y: 0, z: 9.81),
      );
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.normal);
    });

    test('still person with gravity = unconscious', () {
      // Person lying still — near-zero variance, gravity aligned to Z
      final window = List.generate(
        250,
        (_) => const AccelWindow(x: 0.01, y: 0.01, z: 9.81),
      );
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.unconscious);
      expect(result.isAnomaly, isTrue);
    });

    test('still person without gravity alignment = restrained', () {
      // Near-zero variance but no gravity alignment (abnormal)
      final window = List.generate(
        250,
        (_) => const AccelWindow(x: 0.01, y: 0.01, z: 0.01),
      );
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.restrained);
      expect(result.isAnomaly, isTrue);
    });

    test('X-axis dominant moderate movement = dragged', () {
      // X-axis high variance, Y/Z low — dragging pattern
      final window = <AccelWindow>[];
      for (int i = 0; i < 250; i++) {
        window.add(AccelWindow(
          x: (i.isEven ? 0.5 : -0.5),
          y: 0.01,
          z: 9.81,
        ));
      }
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.dragged);
      expect(result.isAnomaly, isTrue);
    });

    test('high variance = running (not anomaly)', () {
      // Large movements on all axes = running
      final window = <AccelWindow>[];
      for (int i = 0; i < 250; i++) {
        window.add(AccelWindow(
          x: (i.isEven ? 3.0 : -3.0),
          y: (i.isEven ? 2.0 : -2.0),
          z: (i.isEven ? 12.0 : 7.0),
        ));
      }
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.running);
      expect(result.isAnomaly, isFalse);
    });

    test('moderate uniform movement = normal', () {
      // Normal walking — moderate variance distributed across axes
      final window = <AccelWindow>[];
      for (int i = 0; i < 250; i++) {
        final phase = i / 50.0;
        window.add(AccelWindow(
          x: 0.3 * (phase % 2 < 1 ? 1 : -1),
          y: 0.3 * (phase % 2 < 1 ? -1 : 1),
          z: 9.81 + 0.3 * (phase % 2 < 1 ? 1 : -1),
        ));
      }
      final result = AnomalyMovementFallback.classify(window);
      expect(result.predictedClass, MovementClass.normal);
      expect(result.isAnomaly, isFalse);
    });

    test('probability map sums to approximately 1.0', () {
      final window = List.generate(
        250,
        (_) => const AccelWindow(x: 0.01, y: 0.01, z: 9.81),
      );
      final result = AnomalyMovementFallback.classify(window);
      final sum = result.probabilities.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.01));
    });
  });

  group('AnomalyMovementClassifier constants', () {
    test('alertThreshold is 0.60', () {
      expect(AnomalyMovementClassifier.alertThreshold, 0.60);
    });

    test('featureCount is 24', () {
      expect(AnomalyMovementClassifier.featureCount, 24);
    });
  });

  group('AnomalyMovementService stream', () {
    test('onAnomalyDetected is a broadcast stream', () {
      final service = AnomalyMovementService();
      expect(service.onAnomalyDetected.isBroadcast, isTrue);
      service.dispose();
    });

    test('isRunning is false initially', () {
      final service = AnomalyMovementService();
      expect(service.isRunning, isFalse);
      service.dispose();
    });
  });
}
