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

  // ── shakeSos Bug Fix Validation ───────────────────────────────────────────
  //
  // Bug: AlertEvent for shakeSos had no confidenceLevel set (null → 0.5 neutral).
  // This caused the risk score to be 78, just below the ≥80 gate in
  // ServiceBootstrapper — so SosCubit.startCountdown() was NEVER called.
  //
  // Fix: Set confidenceLevel=1.0 on the shake AlertEvent (user-initiated = 100%).
  // New score: 88 ≥ 80 → gate passes → SOS countdown starts.
  //
  // Score formula:
  //   severity  (40%) × 1.0  [critical]
  //   proximity (25%) × 0.5  [null distance → neutral]
  //   confidence(20%) × X    [0.5 = bug, 1.0 = fix]
  //   recency   (15%) × 1.0  [just now]
  //
  // Without fix: 0.40 + 0.125 + 0.10 + 0.15 = 0.775 × 100 = 77.5 → 78
  // With fix:    0.40 + 0.125 + 0.20 + 0.15 = 0.875 × 100 = 87.5 → 88

  group('shakeSos AlertEvent scoring — Bug Fix Validation', () {
    test(
      'REGRESSION: shakeSos WITHOUT confidenceLevel scores 78 (the original bug)',
      () {
        // This test documents the bug that was fixed.
        // If this score ever rises to ≥80 due to other changes, the fix
        // is no longer needed — but update this test accordingly.
        final event = makeEvent(
          type: AlertType.shakeSos,
          // confidenceLevel intentionally NOT set — simulates the original bug
        );
        final score = engine.computeScore(event);
        expect(
          score,
          lessThan(80),
          reason:
              'Without confidenceLevel, shakeSos scores $score < 80 — '
              'this is the original bug that prevented SOS from firing.',
        );
        expect(score, equals(78)); // Exact pre-fix value
      },
    );

    test(
      'FIX: shakeSos WITH confidenceLevel=1.0 scores 88 — passes ≥80 gate',
      () {
        final event = makeEvent(
          type: AlertType.shakeSos,
          confidence: 1.0, // ← what ServiceBootstrapper now sets
        );
        final score = engine.computeScore(event);
        expect(
          score,
          greaterThanOrEqualTo(80),
          reason:
              'shakeSos with confidence=1.0 must score ≥80 to pass the '
              'risk gate in ServiceBootstrapper.bootstrap().',
        );
        expect(score, equals(88)); // Exact post-fix value
      },
    );

    test(
      'shakeSos with confidenceLevel=1.0 is labeled Extreme (≥80)',
      () {
        final event = makeEvent(type: AlertType.shakeSos, confidence: 1.0);
        final score = engine.computeScore(event);
        expect(RiskScoreEngine.scoreLabel(score), equals('Extreme'));
      },
    );

    test(
      'shakeSos without confidenceLevel is labeled High (60–79, not Extreme)',
      () {
        final event = makeEvent(
          type: AlertType.shakeSos,
          // no confidence
        );
        final score = engine.computeScore(event);
        // score = 78 → "High" tier (60–79)
        expect(RiskScoreEngine.scoreLabel(score), equals('High'));
      },
    );
  });
}
