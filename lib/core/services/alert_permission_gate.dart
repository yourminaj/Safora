import 'package:permission_handler/permission_handler.dart';
import '../constants/alert_types.dart';
import 'app_logger.dart';

/// Permission-on-demand gating for alert types.
///
/// Only requests system permissions (location, notification, SMS) when the
/// user explicitly enables an alert that requires them. Never auto-requests.
///
/// This follows the design principle: "don't take anything before user
/// allows or enables."
class AlertPermissionGate {
  const AlertPermissionGate();

  /// Categories that require location permission for detection.
  static const Set<AlertCategory> _locationCategories = {
    AlertCategory.vehicleTransport,
    AlertCategory.naturalDisaster,
    AlertCategory.weatherEmergency,
    AlertCategory.personalSafety,
    AlertCategory.militaryDefense,
    AlertCategory.childElder,
    AlertCategory.travelOutdoor,
    AlertCategory.waterMarine,
    AlertCategory.infrastructure,
  };

  /// Categories that require notification permission for alerting.
  /// (Practically all categories need this, but we list explicitly.)
  static const Set<AlertCategory> _notificationCategories = {
    AlertCategory.healthMedical,
    AlertCategory.vehicleTransport,
    AlertCategory.naturalDisaster,
    AlertCategory.weatherEmergency,
    AlertCategory.personalSafety,
    AlertCategory.homeDomestic,
    AlertCategory.workplace,
    AlertCategory.waterMarine,
    AlertCategory.travelOutdoor,
    AlertCategory.environmentalChemical,
    AlertCategory.digitalCyber,
    AlertCategory.childElder,
    AlertCategory.militaryDefense,
    AlertCategory.infrastructure,
    AlertCategory.spaceAstronomical,
    AlertCategory.maritimeAviation,
  };

  /// Whether the given category needs location access to function.
  static bool needsLocation(AlertCategory category) {
    return _locationCategories.contains(category);
  }

  /// Whether the given category needs notification permission.
  static bool needsNotification(AlertCategory category) {
    return _notificationCategories.contains(category);
  }

  /// Whether the given alert type requires microphone (Voice Distress).
  static bool needsMicrophone(AlertType type) {
    return type == AlertType.voiceDistressSos;
  }

  /// Whether the given alert type requires device sensors (Accelerometer).
  static bool needsSensors(AlertType type) {
    return type == AlertType.elderlyFall ||
        type == AlertType.carAccident ||
        type == AlertType.motorcycleCrash ||
        type == AlertType.pedestrianHit ||
        type == AlertType.phoneSnatching ||
        type == AlertType.suspiciousActivity; // fallback for shake
  }

  /// Whether the given alert type is a background SOS trigger requiring SMS & Battery optimization ignoring.
  static bool needsBackgroundEmergency(AlertType type) {
    return needsMicrophone(type) || needsSensors(type) || type == AlertType.geofenceExit;
  }

  /// Get all permissions required for an alert type.
  static Set<Permission> requiredPermissions(AlertType type) {
    final perms = <Permission>{};
    if (needsLocation(type.category)) {
      perms.add(Permission.location);
      // For full SOS functionality, background location is also necessary,
      // but usually requested separately. We add it to the required list if background emergency.
      if (needsBackgroundEmergency(type)) {
        perms.add(Permission.locationAlways);
      }
    }
    if (needsNotification(type.category)) {
      perms.add(Permission.notification);
    }
    if (needsMicrophone(type)) {
      perms.add(Permission.microphone);
    }
    if (needsSensors(type)) {
      perms.add(Permission.sensors);
      // Activity recognition is often needed alongside sensors on newer Android
      perms.add(Permission.activityRecognition);
    }
    if (needsBackgroundEmergency(type)) {
      perms.add(Permission.sms);
      perms.add(Permission.contacts);
      perms.add(Permission.ignoreBatteryOptimizations);
    }
    return perms;
  }

  /// Request all permissions required for a specific alert type.
  ///
  /// Returns `true` if ALL required permissions are granted.
  /// Returns `true` if no permissions are needed.
  ///
  /// Only call this when the user explicitly enables an alert.
  Future<PermissionResult> requestForAlert(AlertType type) async {
    final required = requiredPermissions(type);
    if (required.isEmpty) {
      return const PermissionResult(granted: true, denied: {});
    }

    final denied = <Permission>{};

    for (final perm in required) {
      final status = await perm.status;
      if (status.isGranted) continue;

      // Request the permission.
      final result = await perm.request();
      if (!result.isGranted) {
        denied.add(perm);
        AppLogger.warning(
          '[PermissionGate] ${perm.toString()} denied for ${type.label}',
        );
      } else {
        AppLogger.info(
          '[PermissionGate] ${perm.toString()} granted for ${type.label}',
        );
      }
    }

    return PermissionResult(
      granted: denied.isEmpty,
      denied: denied,
    );
  }

  /// Check if all required permissions are already granted (without requesting).
  Future<bool> hasPermissions(AlertType type) async {
    final required = requiredPermissions(type);
    for (final perm in required) {
      if (!await perm.isGranted) return false;
    }
    return true;
  }
}

/// Result of a permission request.
class PermissionResult {
  const PermissionResult({required this.granted, required this.denied});

  /// Whether all required permissions were granted.
  final bool granted;

  /// Which permissions were denied (empty if all granted).
  final Set<Permission> denied;

  /// Human-readable list of denied permission names.
  List<String> get deniedNames {
    return denied.map((p) {
      if (p == Permission.location) return 'Location';
      if (p == Permission.locationAlways) return 'Background Location';
      if (p == Permission.notification) return 'Notification';
      if (p == Permission.microphone) return 'Microphone';
      if (p == Permission.sensors) return 'Body Sensors';
      if (p == Permission.activityRecognition) return 'Motion & Fitness';
      if (p == Permission.sms) return 'SMS';
      if (p == Permission.contacts) return 'Contacts';
      if (p == Permission.ignoreBatteryOptimizations) return 'Battery Optimization Exemption';
      return p.toString();
    }).toList();
  }
}
