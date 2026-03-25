import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/datasources/disaster_api_client.dart';

void main() {
  // ─── Weather Alerts ─────────────────────────────────────

  group('DisasterApiClient - Weather Alerts', () {
    test('detects extreme heat (>40°C)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-25'],
              'temperature_2m_max': [42.5],
              'temperature_2m_min': [28.0],
              'wind_speed_10m_max': [15.0],
              'precipitation_sum': [0.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [5.0],
            },
            'hourly': {
              'time': ['2026-03-25T12:00'],
              'visibility': [10000.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, hasLength(1));
      expect(alerts[0].type, AlertType.extremeHeat);
      expect(alerts[0].title, contains('Extreme Heat'));
      expect(alerts[0].magnitude, 42.5);
      expect(alerts[0].source, 'Open-Meteo');
    });

    test('detects extreme cold (<-15°C)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-01-15'],
              'temperature_2m_max': [-10.0],
              'temperature_2m_min': [-22.0],
              'wind_speed_10m_max': [30.0],
              'precipitation_sum': [0.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [2.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 64.0, longitude: 25.0,
      );

      expect(alerts.any((a) => a.type == AlertType.extremeCold), isTrue);
      final coldAlert = alerts.firstWhere(
        (a) => a.type == AlertType.extremeCold,
      );
      expect(coldAlert.magnitude, -22.0);
    });

    test('detects blizzard (snow >15cm + wind >50 km/h)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-12-20'],
              'temperature_2m_max': [-5.0],
              'temperature_2m_min': [-18.0],
              'wind_speed_10m_max': [65.0],
              'precipitation_sum': [5.0],
              'snowfall_sum': [25.0],
              'uv_index_max': [1.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 45.0, longitude: -73.0,
      );

      expect(alerts.any((a) => a.type == AlertType.blizzard), isTrue);
      expect(alerts.any((a) => a.type == AlertType.extremeCold), isTrue);
    });

    test('detects thunderstorm (rain >20mm + wind >60 km/h)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-07-10'],
              'temperature_2m_max': [35.0],
              'temperature_2m_min': [25.0],
              'wind_speed_10m_max': [75.0],
              'precipitation_sum': [45.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [4.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts.any((a) => a.type == AlertType.thunderstorm), isTrue);
    });

    test('detects strong wind (>90 km/h)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-25'],
              'temperature_2m_max': [20.0],
              'temperature_2m_min': [10.0],
              'wind_speed_10m_max': [105.0],
              'precipitation_sum': [2.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [3.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 35.0, longitude: 139.0,
      );

      expect(alerts.any((a) => a.type == AlertType.strongWind), isTrue);
    });

    test('detects high UV radiation (index >8)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-06-15'],
              'temperature_2m_max': [38.0],
              'temperature_2m_min': [22.0],
              'wind_speed_10m_max': [10.0],
              'precipitation_sum': [0.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [11.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: -33.0, longitude: 151.0,
      );

      expect(alerts.any((a) => a.type == AlertType.uvRadiation), isTrue);
      final uvAlert = alerts.firstWhere(
        (a) => a.type == AlertType.uvRadiation,
      );
      expect(uvAlert.magnitude, 11.0);
    });

    test('detects dense fog (visibility <200m)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-11-10'],
              'temperature_2m_max': [8.0],
              'temperature_2m_min': [2.0],
              'wind_speed_10m_max': [5.0],
              'precipitation_sum': [0.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [1.0],
            },
            'hourly': {
              'time': [
                '2026-11-10T06:00',
                '2026-11-10T07:00',
                '2026-11-10T08:00',
              ],
              'visibility': [150.0, 100.0, 500.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 51.5, longitude: -0.1,
      );

      expect(alerts.any((a) => a.type == AlertType.denseFog), isTrue);
      // Only first fog event should be reported.
      expect(
        alerts.where((a) => a.type == AlertType.denseFog).length,
        1,
      );
    });

    test('returns empty when no thresholds exceeded', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-03-25'],
              'temperature_2m_max': [25.0],
              'temperature_2m_min': [15.0],
              'wind_speed_10m_max': [20.0],
              'precipitation_sum': [2.0],
              'snowfall_sum': [0.0],
              'uv_index_max': [4.0],
            },
            'hourly': {
              'time': ['2026-03-25T12:00'],
              'visibility': [5000.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, isEmpty);
    });

    test('handles missing daily data gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, isEmpty);
    });

    test('handles multiple alerts on same day', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-07-15'],
              'temperature_2m_max': [45.0],        // Heat
              'temperature_2m_min': [30.0],
              'wind_speed_10m_max': [100.0],        // Wind + thunderstorm
              'precipitation_sum': [50.0],          // Thunderstorm
              'snowfall_sum': [0.0],
              'uv_index_max': [12.0],               // UV
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWeatherAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      // Should detect: extreme heat, thunderstorm, strong wind, UV
      expect(alerts.length, greaterThanOrEqualTo(3));
      final types = alerts.map((a) => a.type).toSet();
      expect(types, contains(AlertType.extremeHeat));
      expect(types, contains(AlertType.strongWind));
      expect(types, contains(AlertType.uvRadiation));
    });
  });

  // ─── Air Quality Alerts ─────────────────────────────────

  group('DisasterApiClient - Air Quality Alerts', () {
    test('detects hazardous AQI (>100)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'hourly': {
              'time': ['2026-03-25T10:00', '2026-03-25T11:00'],
              'european_aqi': [50.0, 120.0],
              'pm10': [80.0, 100.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchAirQualityAlerts(
        latitude: 28.6, longitude: 77.2,
      );

      expect(alerts, hasLength(1));
      expect(alerts[0].type, AlertType.airQuality);
      expect(alerts[0].title, contains('Hazardous'));
      expect(alerts[0].magnitude, 120.0);
    });

    test('detects dust storm (PM10 >500)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'hourly': {
              'time': ['2026-03-25T10:00'],
              'european_aqi': [50.0],
              'pm10': [650.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchAirQualityAlerts(
        latitude: 25.0, longitude: 55.0,
      );

      expect(alerts.any((a) => a.type == AlertType.dustStorm), isTrue);
    });

    test('reports only first occurrence of each alert type', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'hourly': {
              'time': [
                '2026-03-25T10:00',
                '2026-03-25T11:00',
                '2026-03-25T12:00',
              ],
              'european_aqi': [150.0, 200.0, 180.0],
              'pm10': [600.0, 700.0, 550.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchAirQualityAlerts(
        latitude: 28.6, longitude: 77.2,
      );

      // Only 1 AQI alert + 1 dust storm alert (=2 total, not 3+3).
      expect(alerts, hasLength(2));
    });

    test('returns empty when air quality is normal', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'hourly': {
              'time': ['2026-03-25T10:00'],
              'european_aqi': [30.0],
              'pm10': [20.0],
            },
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchAirQualityAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Timeout');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchAirQualityAlerts(
        latitude: 23.8, longitude: 90.4,
      );

      expect(alerts, isEmpty);
    });
  });

  // ─── NASA EONET Events ──────────────────────────────────

  group('DisasterApiClient - NASA EONET', () {
    test('parses EONET events with category mapping', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'events': [
              _eonetEvent('EONET_1', 'California Wildfire', 'wildfires',
                  -120.0, 37.0),
              _eonetEvent('EONET_2', 'Tonga Volcanic Activity', 'volcanoes',
                  -175.0, -20.5),
              _eonetEvent('EONET_3', 'Tropical Storm Alpha', 'severeStorms',
                  -65.0, 18.0),
            ],
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchNasaEonetEvents();

      expect(alerts, hasLength(3));
      expect(alerts[0].source, 'NASA EONET');

      final types = alerts.map((a) => a.type).toSet();
      expect(types, contains(AlertType.wildfire));
      expect(types, contains(AlertType.volcanicEruption));
      expect(types, contains(AlertType.cyclone));
    });

    test('returns empty on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 503);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchNasaEonetEvents();

      expect(alerts, isEmpty);
    });

    test('returns empty on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('DNS resolution failed');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchNasaEonetEvents();

      expect(alerts, isEmpty);
    });

    test('handles events with no geometry', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'events': [
              {
                'id': 'EONET_99',
                'title': 'No Geometry Event',
                'categories': [
                  {'id': 'floods'}
                ],
                'geometry': [],
              }
            ],
          }),
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchNasaEonetEvents();

      expect(alerts, hasLength(1));
      expect(alerts[0].latitude, 0);
      expect(alerts[0].longitude, 0);
    });
  });

  // ─── Wildfire Hotspots ──────────────────────────────────

  group('DisasterApiClient - NASA FIRMS Wildfire', () {
    test('returns empty on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWildfireHotspots(
        latitude: 37.0, longitude: -120.0,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWildfireHotspots(
        latitude: 37.0, longitude: -120.0,
      );

      expect(alerts, isEmpty);
    });

    test('returns empty for single header line (no data)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'latitude,longitude,brightness,confidence,acq_date\n',
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWildfireHotspots(
        latitude: 37.0, longitude: -120.0,
      );

      expect(alerts, isEmpty);
    });

    test('parses valid CSV fire data', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'latitude,longitude,bright_ti4,confidence,acq_date\n'
          '37.5,-121.2,350.5,high,2026-03-25\n'
          '37.6,-121.3,380.0,nominal,2026-03-25\n',
          200,
        );
      });

      final client = DisasterApiClient(client: mockClient);
      final alerts = await client.fetchWildfireHotspots(
        latitude: 37.0, longitude: -120.0,
      );

      expect(alerts, hasLength(2));
      expect(alerts[0].type, AlertType.wildfire);
      expect(alerts[0].source, 'NASA FIRMS');
      expect(alerts[0].title, contains('Wildfire'));
      expect(alerts[0].description, contains('high'));
    });
  });
}

// ── Test Helpers ────────────────────────────────────────────

Map<String, dynamic> _eonetEvent(
  String id,
  String title,
  String categoryId,
  double lng,
  double lat,
) =>
    {
      'id': id,
      'title': title,
      'description': 'Test event: $title',
      'categories': [
        {'id': categoryId}
      ],
      'geometry': [
        {
          'date': '2026-03-25T00:00:00Z',
          'type': 'Point',
          'coordinates': [lng, lat],
        }
      ],
    };
