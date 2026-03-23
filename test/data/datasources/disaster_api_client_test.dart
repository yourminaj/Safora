import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/datasources/disaster_api_client.dart';

void main() {
  group('DisasterApiClient - USGS Earthquakes', () {
    test('parses valid USGS GeoJSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(_validUsgsResponse),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      expect(alerts, hasLength(2));
      // Sorted newest first: M 4.1 (time: 1700000000000) before M 5.2 (time: 1690000000000).
      expect(alerts[0].type, AlertType.earthquake);
      expect(alerts[0].title, 'M 4.1 - Offshore');
      expect(alerts[0].source, 'USGS');
      expect(alerts[0].magnitude, 4.1);
      expect(alerts[1].title, 'M 5.2 - Southern Alaska');
      expect(alerts[1].magnitude, 5.2);
      expect(alerts[1].latitude, closeTo(61.5, 0.01));
      expect(alerts[1].longitude, closeTo(-150.2, 0.01));
    });

    test('sorts earthquakes newest first', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(_validUsgsResponse), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      // Second earthquake (time: 1700000000000) is newer.
      expect(alerts[0].title, 'M 4.1 - Offshore');
      expect(alerts[1].title, 'M 5.2 - Southern Alaska');
    });

    test('returns empty list on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      expect(alerts, isEmpty);
    });

    test('returns empty list on network exception', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      expect(alerts, isEmpty);
    });

    test('handles missing features array', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'type': 'FeatureCollection'}), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      expect(alerts, isEmpty);
    });

    test('handles missing optional fields gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'id': 'eq1',
                'properties': {
                  'time': 1690000000000,
                },
                'geometry': {
                  'coordinates': [0.0, 0.0, 10.0],
                },
              }
            ],
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsEarthquakes();

      expect(alerts, hasLength(1));
      expect(alerts[0].title, 'Earthquake'); // Default title
      expect(alerts[0].magnitude, isNull); // mag not provided
    });
  });

  group('DisasterApiClient - USGS Significant', () {
    test('parses significant earthquakes', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(_validUsgsResponse), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchUsgsSignificant();

      expect(alerts, hasLength(2));
      expect(alerts[0].source, 'USGS');
    });
  });

  group('DisasterApiClient - GDACS', () {
    test('parses valid GDACS response with event type mapping', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(_validGdacsResponse), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchGdacsEvents();

      expect(alerts, hasLength(3));

      // Check event type mapping.
      final types = alerts.map((a) => a.type).toSet();
      expect(types, contains(AlertType.earthquake));
      expect(types, contains(AlertType.cyclone));
      expect(types, contains(AlertType.flood));
    });

    test('maps GDACS event types correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              _gdacsFeature('EQ', 'Earthquake Event'),
              _gdacsFeature('TC', 'Tropical Cyclone'),
              _gdacsFeature('FL', 'Flood Event'),
              _gdacsFeature('VO', 'Volcanic Eruption'),
              _gdacsFeature('DR', 'Drought'),
              _gdacsFeature('WF', 'Wildfire'),
              _gdacsFeature('UNKNOWN', 'Unknown Event'),
            ],
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchGdacsEvents();

      expect(alerts[0].type, AlertType.earthquake);
      expect(alerts[1].type, AlertType.cyclone);
      expect(alerts[2].type, AlertType.flood);
      expect(alerts[3].type, AlertType.volcanicEruption);
      expect(alerts[4].type, AlertType.drought);
      expect(alerts[5].type, AlertType.wildfire);
      expect(alerts[6].type, AlertType.earthquake); // Unknown maps to default
    });

    test('returns empty on GDACS HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 503);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchGdacsEvents();

      expect(alerts, isEmpty);
    });

    test('handles missing geometry coordinates', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'eventid': '1',
                  'name': 'No Coords Event',
                  'eventtype': 'EQ',
                  'fromdate': '2026-03-21',
                },
                'geometry': null,
              }
            ],
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchGdacsEvents();

      expect(alerts, hasLength(1));
      expect(alerts[0].latitude, 0); // Default when no coords
      expect(alerts[0].longitude, 0);
    });
  });

  group('DisasterApiClient - Open-Meteo Flood', () {
    test('detects flood risk when discharge > 500 m³/s', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-21', '2026-03-22', '2026-03-23'],
              'river_discharge': [100.0, 600.0, 1200.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchFloodRisk(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      // Only 600 and 1200 exceed 500 threshold.
      expect(alerts, hasLength(2));
      expect(alerts[0].type, AlertType.flood);
      expect(alerts[0].source, 'Open-Meteo');
      expect(alerts[0].magnitude, 600.0);
      expect(alerts[1].magnitude, 1200.0);
    });

    test('returns empty when no flood risk', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-21'],
              'river_discharge': [100.0], // Below threshold
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchFloodRisk(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(alerts, isEmpty);
    });

    test('handles missing daily data', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchFloodRisk(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(alerts, isEmpty);
    });

    test('handles null discharge values', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-21', '2026-03-22'],
              'river_discharge': [null, 800.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchFloodRisk(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      // null discharge defaults to 0, only 800 exceeds threshold.
      expect(alerts, hasLength(1));
      expect(alerts[0].magnitude, 800.0);
    });

    test('returns empty on network failure', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Timeout');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchFloodRisk(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(alerts, isEmpty);
    });
  });
}

// ── Test Data ─────────────────────────────────────────────────

final _validUsgsResponse = {
  'type': 'FeatureCollection',
  'features': [
    {
      'id': 'us7000abcd',
      'properties': {
        'title': 'M 5.2 - Southern Alaska',
        'place': '50km NW of Anchorage',
        'time': 1690000000000,
        'mag': 5.2,
      },
      'geometry': {
        'coordinates': [-150.2, 61.5, 35.0],
      },
    },
    {
      'id': 'us7000efgh',
      'properties': {
        'title': 'M 4.1 - Offshore',
        'place': 'Pacific Ocean',
        'time': 1700000000000,
        'mag': 4.1,
      },
      'geometry': {
        'coordinates': [-130.5, 40.2, 10.0],
      },
    },
  ],
};

final _validGdacsResponse = {
  'features': [
    _gdacsFeature('EQ', 'Turkey Earthquake'),
    _gdacsFeature('TC', 'Cyclone Mocha'),
    _gdacsFeature('FL', 'Bangladesh Flood'),
  ],
};

Map<String, dynamic> _gdacsFeature(String eventType, String name) => {
      'properties': {
        'eventid': '${eventType}_${name.hashCode}',
        'name': name,
        'eventtype': eventType,
        'description': 'Test $name',
        'country': 'Test Country',
        'fromdate': '2026-03-21T00:00:00Z',
        'severity': 7.0,
      },
      'geometry': {
        'coordinates': [90.4, 23.8],
      },
    };
