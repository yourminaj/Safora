import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/alert_types.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/app_logger.dart';
import '../models/alert_event.dart';

/// HTTP client for fetching disaster data from external APIs.
///
/// Sources:
/// - USGS: Earthquakes (GeoJSON)
/// - GDACS: Cyclones, floods, earthquakes (JSON)
/// - Open-Meteo: Flood risk (river discharge)
class DisasterApiClient {
  DisasterApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  // ─── USGS Earthquakes ────────────────────────────────────

  /// Fetch earthquakes from the last 24 hours.
  ///
  /// Returns [AlertEvent] list sorted by time (newest first).
  Future<List<AlertEvent>> fetchUsgsEarthquakes() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiEndpoints.usgsEarthquakeDay))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;

        return AlertEvent(
          id: (feature['id'])?.toString(),
          type: AlertType.earthquake,
          title: props['title'] as String? ?? 'Earthquake',
          description: props['place'] as String?,
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (props['time'] as num).toInt(),
          ),
          source: 'USGS',
          magnitude: (props['mag'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] USGS earthquakes fetch failed: $e');
      return [];
    }
  }

  /// Fetch only significant earthquakes from the last 24 hours.
  Future<List<AlertEvent>> fetchUsgsSignificant() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiEndpoints.usgsSignificantDay))
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;

        return AlertEvent(
          id: (feature['id'])?.toString(),
          type: AlertType.earthquake,
          title: props['title'] as String? ?? 'Significant Earthquake',
          description: props['place'] as String?,
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (props['time'] as num).toInt(),
          ),
          source: 'USGS',
          magnitude: (props['mag'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] USGS significant fetch failed: $e');
      return [];
    }
  }

  // ─── GDACS (Global Disaster Alerts) ──────────────────────

  /// Fetch recent disaster events from GDACS.
  ///
  /// Includes earthquakes, tropical cyclones, and floods worldwide.
  Future<List<AlertEvent>> fetchGdacsEvents() async {
    try {
      final uri = Uri.parse(ApiEndpoints.gdacsJson).replace(
        queryParameters: {
          'fromDate': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String()
              .split('T')
              .first,
          'toDate': DateTime.now().toIso8601String().split('T').first,
          'alertlevel': 'Green;Orange;Red',
        },
      );

      final response =
          await _client.get(uri, headers: {
            'Accept': 'application/json',
          }).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (json['features'] as List<dynamic>?) ?? [];

      return features.map((f) {
        final feature = f as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>?;
        final coords = geometry?['coordinates'] as List<dynamic>?;

        final eventType = _gdacsEventTypeToAlertType(
          props['eventtype'] as String? ?? '',
        );

        return AlertEvent(
          id: props['eventid']?.toString(),
          type: eventType,
          title: props['name'] as String? ??
              props['eventtype'] as String? ??
              'Disaster Alert',
          description: props['description'] as String? ??
              props['country'] as String?,
          longitude: coords != null ? (coords[0] as num).toDouble() : 0,
          latitude: coords != null ? (coords[1] as num).toDouble() : 0,
          timestamp: DateTime.tryParse(
                  props['fromdate'] as String? ?? '') ??
              DateTime.now(),
          source: 'GDACS',
          magnitude: (props['severity'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      AppLogger.warning('[DisasterAPI] GDACS events fetch failed: $e');
      return [];
    }
  }

  AlertType _gdacsEventTypeToAlertType(String eventType) {
    return switch (eventType.toUpperCase()) {
      'EQ' => AlertType.earthquake,
      'TC' => AlertType.cyclone,
      'FL' => AlertType.flood,
      'VO' => AlertType.volcanicEruption,
      'DR' => AlertType.drought,
      'WF' => AlertType.wildfire,
      _ => AlertType.earthquake,
    };
  }

  // ─── Open-Meteo Flood ────────────────────────────────────

  /// Check flood risk at a specific location.
  ///
  /// Returns a list of flood alerts if river discharge exceeds threshold.
  Future<List<AlertEvent>> fetchFloodRisk({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.openMeteoFlood).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'daily': 'river_discharge',
          'forecast_days': '7',
        },
      );

      final response =
          await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>?;
      if (daily == null) return [];

      final times = daily['time'] as List<dynamic>? ?? [];
      final discharges =
          daily['river_discharge'] as List<dynamic>? ?? [];

      final alerts = <AlertEvent>[];

      for (int i = 0; i < times.length && i < discharges.length; i++) {
        final discharge = (discharges[i] as num?)?.toDouble() ?? 0;

        // High discharge threshold — rough heuristic for flood risk.
        if (discharge > 500) {
          alerts.add(AlertEvent(
            id: 'flood_${times[i]}',
            type: AlertType.flood,
            title: 'Flood Risk Alert',
            description:
                'River discharge: ${discharge.toStringAsFixed(0)} m³/s '
                'on ${times[i]}',
            latitude: latitude,
            longitude: longitude,
            timestamp:
                DateTime.tryParse(times[i] as String) ?? DateTime.now(),
            source: 'Open-Meteo',
            magnitude: discharge,
          ));
        }
      }

      return alerts;
    } catch (e) {
      AppLogger.warning('[DisasterAPI] Open-Meteo flood risk fetch failed: $e');
      return [];
    }
  }

  /// Dispose HTTP client.
  void dispose() {
    _client.close();
  }
}
