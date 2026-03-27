import 'package:flutter_test/flutter_test.dart';
import 'package:safora/services/risk_score_engine.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  late RiskScoreEngine engine;

  setUp(() {
    engine = const RiskScoreEngine();
  });

  /// Helper: create a test AlertEvent with controllable scoring factors.
  AlertEvent makeEvent({
    AlertType type = AlertType.earthquake,
    double? distanceKm,
    double? confidence,
    DateTime? timestamp,
  }) {
    return AlertEvent(
      type: type,
      title: 'Test Alert',
      latitude: 0,
      longitude: 0,
      timestamp: timestamp ?? DateTime.now(),
      distanceKm: distanceKm,
      confidenceLevel: confidence,
    );
  }

  group('RiskScoreEngine.computeScore', () {
    test('critical, close, confident, recent event scores above 70', () {
      final event = makeEvent(
        type: AlertType.earthquake, // critical priority
        distanceKm: 0.5,
        confidence: 1.0,
        timestamp: DateTime.now(),
      );
      final score = engine.computeScore(event);
      expect(score, greaterThan(70));
    });

    test('info-level event scores lower than critical', () {
      final critical = engine.computeScore(makeEvent(
        type: AlertType.earthquake, // critical
        distanceKm: 1.0,
        confidence: 0.9,
      ));
      // Find an info-level alert
      final infoType = AlertType.values.firstWhere(
        (t) => t.priority == AlertPriority.info,
      );
      final info = engine.computeScore(makeEvent(
        type: infoType,
        distanceKm: 1.0,
        confidence: 0.9,
      ));
      expect(critical, greaterThan(info));
    });

    test('closer events score higher than distant ones', () {
      final close = engine.computeScore(makeEvent(distanceKm: 0.5));
      final far = engine.computeScore(makeEvent(distanceKm: 40.0));
      expect(close, greaterThan(far));
    });

    test('higher confidence scores higher', () {
      final high = engine.computeScore(makeEvent(confidence: 1.0));
      final low = engine.computeScore(makeEvent(confidence: 0.1));
      expect(high, greaterThan(low));
    });

    test('score is clamped between 0 and 100', () {
      final score = engine.computeScore(makeEvent(
        distanceKm: 0.01,
        confidence: 1.0,
      ));
      expect(score, lessThanOrEqualTo(100));
      expect(score, greaterThanOrEqualTo(0));
    });

    test('null distance gets neutral proximity (0.5)', () {
      final score = engine.computeScore(makeEvent(distanceKm: null));
      // Should still produce a valid score.
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('RiskScoreEngine.scoreLabel', () {
    test('returns Extreme for score >= 80', () {
      expect(RiskScoreEngine.scoreLabel(85), equals('Extreme'));
    });

    test('returns High for score >= 60', () {
      expect(RiskScoreEngine.scoreLabel(65), equals('High'));
    });

    test('returns Moderate for score >= 40', () {
      expect(RiskScoreEngine.scoreLabel(45), equals('Moderate'));
    });

    test('returns Low for score >= 20', () {
      expect(RiskScoreEngine.scoreLabel(25), equals('Low'));
    });

    test('returns Minimal for score < 20', () {
      expect(RiskScoreEngine.scoreLabel(10), equals('Minimal'));
    });
  });

  group('RiskScoreEngine.enrichAndSort', () {
    test('returns events sorted by descending score', () {
      final events = [
        makeEvent(
          type: AlertType.values.firstWhere(
            (t) => t.priority == AlertPriority.info,
          ),
          distanceKm: 40.0,
          confidence: 0.3,
        ),
        makeEvent(
          type: AlertType.earthquake,
          distanceKm: 0.5,
          confidence: 1.0,
        ),
      ];

      final sorted = engine.enrichAndSort(events);
      expect(sorted.first.riskScore, greaterThan(sorted.last.riskScore ?? 0));
    });
  });
}
