import 'alert_types.dart';

/// Maps each alert type to its distinct sound asset file.
///
/// **Production note**: Currently only `siren.mp3` and `phone_ring.mp3`
/// exist in assets/sounds/. All other constants map to these two files
/// as fallbacks. Replace with specialized sounds before releasing
/// premium sound customization features.
abstract final class AlertSounds {
  static const String _base = 'sounds';

  /// Get the sound file path for a given alert type.
  static String forType(AlertType type) {
    return switch (type.priority) {
      AlertPriority.critical => sirenSos,
      AlertPriority.high => generalWarning,
      AlertPriority.medium => generalWarning,
      AlertPriority.low => generalWarning,
    };
  }

  // ── Available sounds (existing assets) ──────────────────

  /// SOS panic button siren — uses siren.mp3.
  static const String sirenSos = '$_base/siren.mp3';

  /// General warning tone — uses siren.mp3 (lower urgency).
  static const String generalWarning = '$_base/siren.mp3';

  // ── Fallback sounds (mapped to existing assets) ─────────
  // Replace these paths when specialized sound files are added.

  /// Crash detection alarm.
  static const String crashAlarm = '$_base/siren.mp3';

  /// Earthquake alert.
  static const String earthquakeAlert = '$_base/siren.mp3';

  /// Flood warning.
  static const String floodWarning = '$_base/siren.mp3';

  /// Heart anomaly alert.
  static const String heartAlert = '$_base/siren.mp3';

  /// Fall detection tone.
  static const String fallDetection = '$_base/siren.mp3';

  /// Fire alarm.
  static const String fireAlarm = '$_base/siren.mp3';

  /// Cyclone siren.
  static const String cycloneSiren = '$_base/siren.mp3';

  /// Phone ring for decoy calls.
  static const String phoneRing = '$_base/phone_ring.mp3';
}
