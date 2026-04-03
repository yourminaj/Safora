import 'alert_types.dart';

/// Maps each alert type to its distinct sound asset file.
///
/// **Sound policy** (strict):
/// - `siren.mp3`     → ONLY for `critical` priority (life-threatening).
/// - `phone_ring.mp3` → ALL sub-critical priorities (danger/warning/advisory/info).
///
/// This prevents false-positive siren triggers from low-severity alerts.
abstract final class AlertSounds {
  static const String _base = 'sounds';

  /// Get the sound file path for a given alert type.
  ///
  /// **Critical** = emergency siren (siren.mp3).
  /// **All others** = notification ring (phone_ring.mp3).
  static String forType(AlertType type) {
    return switch (type.priority) {
      AlertPriority.critical => sirenSos,
      AlertPriority.danger => notificationRing,
      AlertPriority.warning => notificationRing,
      AlertPriority.advisory => notificationRing,
      AlertPriority.info => notificationRing,
    };
  }

  /// SOS panic button siren — ONLY for critical/life-threatening events.
  static const String sirenSos = '$_base/siren.mp3';

  /// General notification ring — used for all sub-critical alerts.
  /// Replaces the old `generalWarning` which incorrectly used siren.mp3.
  static const String notificationRing = '$_base/phone_ring.mp3';

  // ─── Named aliases for future specialization ───
  // Replace these paths when specialized sound files are added.

  /// Crash detection alarm — critical, uses siren.
  static const String crashAlarm = '$_base/siren.mp3';

  /// Earthquake alert — critical, uses siren.
  static const String earthquakeAlert = '$_base/siren.mp3';

  /// Flood warning — critical, uses siren.
  static const String floodWarning = '$_base/siren.mp3';

  /// Heart anomaly alert — critical, uses siren.
  static const String heartAlert = '$_base/siren.mp3';

  /// Fall detection tone — danger-level, uses notification ring.
  static const String fallDetection = '$_base/phone_ring.mp3';

  /// Fire alarm — critical, uses siren.
  static const String fireAlarm = '$_base/siren.mp3';

  /// Cyclone siren — critical, uses siren.
  static const String cycloneSiren = '$_base/siren.mp3';

  /// Phone ring for decoy calls.
  static const String phoneRing = '$_base/phone_ring.mp3';
}
