import 'dart:math' as math;
import '../data/models/alert_event.dart';
import '../core/constants/alert_types.dart';

/// Composite Risk Score Engine.
///
/// Computes a 0–100 risk score for each [AlertEvent] using 4 weighted factors:
/// 1. **Severity** (40%) — based on [AlertPriority] tier.
/// 2. **Proximity** (25%) — exponential decay by [distanceKm].
/// 3. **Confidence** (20%) — source reliability [confidenceLevel].
/// 4. **Recency** (15%) — time decay from event [timestamp].
///
/// The output score is categorized into:
/// - 80–100: Extreme (activate emergency protocols)
/// - 60–79: High (urgent notification)
/// - 40–59: Moderate (standard notification)
/// - 20–39: Low (informational)
/// - 0–19: Minimal (silent)
class RiskScoreEngine {
  const RiskScoreEngine();

  static const double _wSeverity = 0.40;
  static const double _wProximity = 0.25;
  static const double _wConfidence = 0.20;
  static const double _wRecency = 0.15;

  /// Max relevant radius in km. Beyond this, proximity score = 0.
  static const double _maxRadiusKm = 50.0;

  /// Events older than this are considered fully decayed.
  static const Duration _maxAge = Duration(hours: 24);

  /// Compute the composite risk score for a single alert event.
  ///
  /// Returns a value between 0 and 100 (inclusive).
  int computeScore(AlertEvent event) {
    final severityScore = _severityScore(event.type.priority);
    final proximityScore = _proximityScore(event.distanceKm);
    final confidenceScore = _confidenceScore(event.confidenceLevel);
    final recencyScore = _recencyScore(event.timestamp);

    final raw = (severityScore * _wSeverity) +
        (proximityScore * _wProximity) +
        (confidenceScore * _wConfidence) +
        (recencyScore * _wRecency);

    // Clamp to 0-100 integer.
    return (raw * 100).round().clamp(0, 100);
  }

  /// Enrich an event with its computed score.
  AlertEvent enrichWithScore(AlertEvent event) {
    return event.copyWith(riskScore: computeScore(event));
  }

  /// Batch-enrich a list of events and sort by descending score.
  List<AlertEvent> enrichAndSort(List<AlertEvent> events) {
    final enriched = events.map(enrichWithScore).toList();
    enriched.sort((a, b) => (b.riskScore ?? 0).compareTo(a.riskScore ?? 0));
    return enriched;
  }

  /// Human-readable label for a risk score.
  static String scoreLabel(int score) {
    if (score >= 80) return 'Extreme';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Moderate';
    if (score >= 20) return 'Low';
    return 'Minimal';
  }

  /// Maps 5-tier priority to a 0.0–1.0 base severity factor.
  double _severityScore(AlertPriority priority) {
    return switch (priority) {
      AlertPriority.critical => 1.0,
      AlertPriority.danger => 0.80,
      AlertPriority.warning => 0.55,
      AlertPriority.advisory => 0.30,
      AlertPriority.info => 0.10,
    };
  }

  /// Exponential proximity decay. Closer = higher score.
  ///
  /// - 0 km → 1.0
  /// - 5 km → ~0.90
  /// - 25 km → ~0.61
  /// - 50 km → ~0.37
  /// - null (unknown distance) → 0.5 (neutral)
  double _proximityScore(double? distanceKm) {
    if (distanceKm == null) return 0.5; // Unknown → neutral
    if (distanceKm <= 0) return 1.0;
    if (distanceKm >= _maxRadiusKm) return 0.0;

    // Exponential decay: e^(-0.02 * distance)
    return math.exp(-0.02 * distanceKm);
  }

  /// Direct mapping: confidence level is already 0.0–1.0.
  double _confidenceScore(double? confidence) {
    return (confidence ?? 0.5).clamp(0.0, 1.0);
  }

  /// Linear time decay over [_maxAge].
  ///
  /// - Just now → 1.0
  /// - 12h ago → 0.5
  /// - 24h+ ago → 0.0
  double _recencyScore(DateTime timestamp) {
    final age = DateTime.now().difference(timestamp);
    if (age.isNegative) return 1.0; // Future event
    if (age >= _maxAge) return 0.0;

    return 1.0 - (age.inMinutes / _maxAge.inMinutes);
  }
}
