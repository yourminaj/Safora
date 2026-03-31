/// Tests for AlertPermissionGate — real business logic, no mocks.
///
/// Verifies category→permission mapping, required permission sets,
/// and PermissionResult model behavior.
library;
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:safora/core/services/alert_permission_gate.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  group('AlertPermissionGate.needsLocation', () {
    test('returns true for location-dependent categories', () {
      const locationCategories = [
        AlertCategory.vehicleTransport,
        AlertCategory.naturalDisaster,
        AlertCategory.weatherEmergency,
        AlertCategory.personalSafety,
        AlertCategory.militaryDefense,
        AlertCategory.childElder,
        AlertCategory.travelOutdoor,
        AlertCategory.waterMarine,
        AlertCategory.infrastructure,
      ];

      for (final category in locationCategories) {
        expect(
          AlertPermissionGate.needsLocation(category),
          isTrue,
          reason: '${category.name} should need location',
        );
      }
    });

    test('returns false for non-location categories', () {
      const nonLocation = [
        AlertCategory.healthMedical,
        AlertCategory.homeDomestic,
        AlertCategory.workplace,
        AlertCategory.environmentalChemical,
        AlertCategory.digitalCyber,
        AlertCategory.spaceAstronomical,
        AlertCategory.maritimeAviation,
      ];

      for (final category in nonLocation) {
        expect(
          AlertPermissionGate.needsLocation(category),
          isFalse,
          reason: '${category.name} should NOT need location',
        );
      }
    });
  });

  group('AlertPermissionGate.needsNotification', () {
    test('all categories except none require notification', () {
      // Every category in the _notificationCategories set should return true
      for (final category in AlertCategory.values) {
        // All 16 categories require notification in the current implementation
        expect(
          AlertPermissionGate.needsNotification(category),
          isTrue,
          reason: '${category.name} should need notification',
        );
      }
    });
  });

  group('AlertPermissionGate.requiredPermissions', () {
    test('location+notification for vehicleTransport alertType', () {
      // Pick a vehicleTransport alertType to verify both permissions
      final perms = AlertPermissionGate.requiredPermissions(
        AlertType.bicycleCrash,
      );
      expect(perms, contains(Permission.location));
      expect(perms, contains(Permission.notification));
      expect(perms.length, 2);
    });

    test('notification-only for healthMedical alertType', () {
      // healthMedical doesn't need location
      final perms = AlertPermissionGate.requiredPermissions(
        AlertType.cardiacArrest,
      );
      expect(perms, contains(Permission.notification));
      expect(perms, isNot(contains(Permission.location)));
      expect(perms.length, 1);
    });
  });

  group('PermissionResult', () {
    test('granted=true when denied set is empty', () {
      const result = PermissionResult(granted: true, denied: {});
      expect(result.granted, isTrue);
      expect(result.deniedNames, isEmpty);
    });

    test('granted=false when denied contains permissions', () {
      final result = PermissionResult(
        granted: false,
        denied: {Permission.location, Permission.notification},
      );
      expect(result.granted, isFalse);
      expect(result.deniedNames, hasLength(2));
    });

    test('deniedNames maps location to "Location"', () {
      final result = PermissionResult(
        granted: false,
        denied: {Permission.location},
      );
      expect(result.deniedNames, contains('Location'));
    });

    test('deniedNames maps notification to "Notification"', () {
      final result = PermissionResult(
        granted: false,
        denied: {Permission.notification},
      );
      expect(result.deniedNames, contains('Notification'));
    });
  });

  group('AlertCategory', () {
    test('all 16 categories have labels', () {
      for (final category in AlertCategory.values) {
        expect(category.label, isNotEmpty);
      }
    });

    test('has exactly 16 categories', () {
      expect(AlertCategory.values.length, 16);
    });
  });

  group('AlertPriority', () {
    test('has 5 levels: critical → info', () {
      expect(AlertPriority.values.length, 5);
      expect(AlertPriority.values, contains(AlertPriority.critical));
      expect(AlertPriority.values, contains(AlertPriority.danger));
      expect(AlertPriority.values, contains(AlertPriority.warning));
      expect(AlertPriority.values, contains(AlertPriority.advisory));
      expect(AlertPriority.values, contains(AlertPriority.info));
    });
  });
}
