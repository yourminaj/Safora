import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';

/// Unit tests for AlertsState — validates filtered view, copyWith, equatable.
void main() {
  final now = DateTime.now();

  AlertEvent makeAlert({
    required String id,
    required String typeName,
  }) {
    return AlertEvent.fromMap({
      'title': 'Alert $id',
      'description': 'Test desc',
      'type': typeName,
      'latitude': 0.0,
      'longitude': 0.0,
      'timestamp': now.toIso8601String(),
    }, id: id);
  }

  group('AlertsLoaded.filtered', () {
    test('returns all alerts when no filters set', () {
      final alerts = [
        makeAlert(id: '1', typeName: 'heartAttack'),
        makeAlert(id: '2', typeName: 'carAccident'),
        makeAlert(id: '3', typeName: 'choking'),
      ];
      final state = AlertsLoaded(alerts: alerts);
      expect(state.filtered.length, 3);
    });

    test('filters by category', () {
      final alerts = [
        makeAlert(id: '1', typeName: 'heartAttack'),      // healthMedical
        makeAlert(id: '2', typeName: 'bicycleCrash'),       // vehicleTransport
      ];
      final state = AlertsLoaded(
        alerts: alerts,
        filterCategory: AlertCategory.healthMedical,
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first.type, AlertType.heartAttack);
    });

    test('filters by priority', () {
      final alerts = [
        makeAlert(id: '1', typeName: 'heartAttack'),   // critical
        makeAlert(id: '2', typeName: 'dehydration'),    // warning
      ];
      final state = AlertsLoaded(
        alerts: alerts,
        filterPriority: AlertPriority.critical,
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first.type, AlertType.heartAttack);
    });

    test('both category and priority filters apply together', () {
      final alerts = [
        makeAlert(id: '1', typeName: 'heartAttack'),     // healthMedical, critical
        makeAlert(id: '2', typeName: 'dehydration'),     // healthMedical, warning
        makeAlert(id: '3', typeName: 'bicycleCrash'),     // vehicleTransport, critical
      ];
      final state = AlertsLoaded(
        alerts: alerts,
        filterCategory: AlertCategory.healthMedical,
        filterPriority: AlertPriority.critical,
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first.id, '1');
    });
  });

  group('AlertsLoaded.copyWith', () {
    test('preserves values when arguments not given', () {
      final alerts = [makeAlert(id: '1', typeName: 'heartAttack')];
      final original = AlertsLoaded(
        alerts: alerts,
        filterCategory: AlertCategory.healthMedical,
      );
      final copied = original.copyWith();
      expect(copied.alerts, original.alerts);
      expect(copied.filterCategory, original.filterCategory);
    });

    test('clears nullable filter via Function()', () {
      final alerts = [makeAlert(id: '1', typeName: 'heartAttack')];
      final original = AlertsLoaded(
        alerts: alerts,
        filterCategory: AlertCategory.healthMedical,
      );
      final cleared = original.copyWith(filterCategory: () => null);
      expect(cleared.filterCategory, isNull);
    });

    test('updates preferencesApplied flag', () {
      final original = AlertsLoaded(alerts: []);
      expect(original.preferencesApplied, isFalse);
      final updated = original.copyWith(preferencesApplied: true);
      expect(updated.preferencesApplied, isTrue);
    });
  });

  group('AlertsState sealed classes', () {
    test('AlertsInitial is equatable', () {
      expect(const AlertsInitial(), equals(const AlertsInitial()));
    });

    test('AlertsLoading is equatable', () {
      expect(const AlertsLoading(), equals(const AlertsLoading()));
    });

    test('AlertsError carries message', () {
      const error = AlertsError('Network failure');
      expect(error.message, 'Network failure');
    });

    test('AlertsError equality', () {
      expect(
        const AlertsError('same'),
        equals(const AlertsError('same')),
      );
    });
  });
}
