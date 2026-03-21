import 'alert_types.dart';

/// Maps each alert type to its distinct sound asset file.
abstract final class AlertSounds {
  static const String _base = 'assets/sounds';

  /// Get the sound file path for a given alert type.
  static String forType(AlertType type) {
    return switch (type.priority) {
      AlertPriority.critical => '$_base/siren_sos.mp3',
      AlertPriority.high => '$_base/general_warning.mp3',
      AlertPriority.medium => '$_base/general_warning.mp3',
      AlertPriority.low => '$_base/general_warning.mp3',
    };
  }

  /// SOS panic button siren.
  static const String sirenSos = '$_base/siren_sos.mp3';

  /// Crash detection alarm.
  static const String crashAlarm = '$_base/crash_alarm.mp3';

  /// Earthquake alert.
  static const String earthquakeAlert = '$_base/earthquake_alert.mp3';

  /// Flood warning.
  static const String floodWarning = '$_base/flood_warning.mp3';

  /// Heart anomaly alert.
  static const String heartAlert = '$_base/heart_alert.mp3';

  /// Fall detection tone.
  static const String fallDetection = '$_base/fall_detection.mp3';

  /// Fire alarm.
  static const String fireAlarm = '$_base/fire_alarm.mp3';

  /// Cyclone siren.
  static const String cycloneSiren = '$_base/cyclone_siren.mp3';

  /// General warning tone.
  static const String generalWarning = '$_base/general_warning.mp3';
}
