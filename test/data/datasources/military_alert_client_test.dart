import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/datasources/military_alert_client.dart';

void main() {
  // ─── Region Detection ───────────────────────────────────

  group('MilitaryAlertClient - Region Detection', () {
    test('detects Ukraine region', () {
      expect(
        MilitaryAlertClient.detectRegion(50.45, 30.52), // Kyiv
        ConflictRegion.ukraine,
      );
      expect(
        MilitaryAlertClient.detectRegion(49.84, 24.03), // Lviv
        ConflictRegion.ukraine,
      );
    });

    test('detects Israel region', () {
      expect(
        MilitaryAlertClient.detectRegion(32.07, 34.78), // Tel Aviv
        ConflictRegion.israel,
      );
      expect(
        MilitaryAlertClient.detectRegion(31.77, 35.23), // Jerusalem
        ConflictRegion.israel,
      );
    });

    test('detects US region', () {
      expect(
        MilitaryAlertClient.detectRegion(40.71, -74.01), // NYC
        ConflictRegion.unitedStates,
      );
      expect(
        MilitaryAlertClient.detectRegion(34.05, -118.24), // LA
        ConflictRegion.unitedStates,
      );
    });

    test('returns none for non-conflict regions', () {
      expect(
        MilitaryAlertClient.detectRegion(23.81, 90.41), // Dhaka, Bangladesh
        ConflictRegion.none,
      );
      expect(
        MilitaryAlertClient.detectRegion(35.68, 139.69), // Tokyo, Japan
        ConflictRegion.none,
      );
      expect(
        MilitaryAlertClient.detectRegion(-33.87, 151.21), // Sydney, Australia
        ConflictRegion.none,
      );
    });
  });

  // ─── Ukraine API ────────────────────────────────────────

  group('MilitaryAlertClient - Ukraine Alerts', () {
    test('parses active air raid alerts', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'states': [
              {
                'id': 1,
                'name': 'Kyiv Oblast',
                'alert': true,
                'alert_type': 'air_raid',
                'changed': '2026-03-25T10:00:00Z',
              },
              {
                'id': 2,
                'name': 'Odessa Oblast',
                'alert': false,
                'alert_type': null,
                'changed': '2026-03-25T09:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 50.45, longitude: 30.52,
      );

      expect(alerts, hasLength(1));
      expect(alerts[0].type, AlertType.airRaid);
      expect(alerts[0].title, contains('Kyiv'));
      expect(alerts[0].source, 'Ukraine Alert System');
    });

    test('maps drone threat type correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'states': [
              {
                'id': 3,
                'name': 'Kharkiv Oblast',
                'alert': true,
                'alert_type': 'drone',
                'changed': '2026-03-25T11:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 49.99, longitude: 36.23,
      );

      expect(alerts[0].type, AlertType.droneAttack);
    });

    test('maps artillery to missile strike', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'states': [
              {
                'id': 4,
                'name': 'Zaporizhzhia',
                'alert': true,
                'alert_type': 'artillery',
                'changed': '2026-03-25T12:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 47.84, longitude: 35.14,
      );

      expect(alerts[0].type, AlertType.missileStrike);
    });

    test('returns empty on network error', () async {
      final mockClient = MockClient((_) async {
        throw Exception('Network error');
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 50.45, longitude: 30.52,
      );

      expect(alerts, isEmpty);
    });
  });

  // ─── US FEMA Alerts ─────────────────────────────────────

  group('MilitaryAlertClient - FEMA Alerts', () {
    test('parses civil danger alerts', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'id': 'urn:oid:2.49.0.1.840.0',
                  'event': 'Civil Danger Warning',
                  'headline': 'Civil Danger in downtown area',
                  'description': 'Active situation reported',
                  'urgency': 'Immediate',
                  'sent': '2026-03-25T15:00:00Z',
                },
              },
            ],
          }),
          200,
        );
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 40.71, longitude: -74.01,
      );

      expect(alerts, hasLength(1));
      expect(alerts[0].type, AlertType.terrorism);
      expect(alerts[0].source, 'FEMA/NWS');
      expect(alerts[0].magnitude, 10.0); // Immediate urgency
    });

    test('filters out weather-only events', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'id': 'urn:oid:2.49.0.1.840.1',
                  'event': 'Tornado Warning',
                  'headline': 'Tornado in area',
                  'urgency': 'Immediate',
                  'sent': '2026-03-25T16:00:00Z',
                },
              },
            ],
          }),
          200,
        );
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 35.0, longitude: -90.0,
      );

      // Weather events are excluded (handled by Phase 1).
      expect(alerts, isEmpty);
    });

    test('returns empty on HTTP error', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Server Error', 500);
      });

      final client = MilitaryAlertClient(client: mockClient);
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 40.71, longitude: -74.01,
      );

      expect(alerts, isEmpty);
    });
  });

  // ─── Non-Conflict Region ────────────────────────────────

  group('MilitaryAlertClient - No Conflict Region', () {
    test('returns empty for Bangladesh coordinates', () async {
      // No HTTP client needed — should skip entirely.
      final client = MilitaryAlertClient();
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 23.81, longitude: 90.41,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty for Japan coordinates', () async {
      final client = MilitaryAlertClient();
      final alerts = await client.fetchMilitaryAlerts(
        latitude: 35.68, longitude: 139.69,
      );

      expect(alerts, isEmpty);
    });
  });
}
