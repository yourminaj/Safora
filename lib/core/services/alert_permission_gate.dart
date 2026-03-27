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

  /// Get all permissions required for an alert type.
  static Set<Permission> requiredPermissions(AlertType type) {
    final perms = <Permission>{};
    if (needsLocation(type.category)) {
      perms.add(Permission.location);
    }
    if (needsNotification(type.category)) {
      perms.add(Permission.notification);
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
      if (p == Permission.notification) return 'Notification';
      return p.toString();
    }).toList();
  }
}
