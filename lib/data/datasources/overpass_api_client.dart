import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:http/http.dart' as http;
import '../models/emergency_poi.dart';
import '../../core/services/app_logger.dart';

/// Client for the OpenStreetMap Overpass API.
///
/// Fetches nearby emergency services (hospitals, police, fire stations,
/// pharmacies, shelters) within a given radius of a location.
///
/// Uses the public Overpass API. Rate limited but free. No API key needed.
class OverpassApiClient {
  OverpassApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Maximum radius in meters (5 km default).
  static const int defaultRadiusMeters = 5000;

  /// Fetch all emergency POIs near the given coordinates.
  ///
  /// Returns a combined list of hospitals, police, fire stations, etc.
  /// Sorted by distance from the center point.
  Future<List<EmergencyPoi>> fetchNearbyPois({
    required double latitude,
    required double longitude,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = _buildQuery(latitude, longitude, radiusMeters);

    try {
      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        AppLogger.error(
          '[Overpass] HTTP ${response.statusCode}: ${response.body.substring(0, 200)}',
        );
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (json['elements'] as List<dynamic>?) ?? [];

      final pois = <EmergencyPoi>[];
      for (final element in elements) {
        final e = element as Map<String, dynamic>;
        final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
        final amenity = tags['amenity'] as String?;

        final type = _mapAmenityToType(amenity);
        if (type == null) continue;

        final poi = EmergencyPoi.fromOverpassElement(e, type);
        pois.add(poi);
      }

      // Sort by distance from center.
      pois.sort((a, b) {
        final distA = _haversine(latitude, longitude, a.latitude, a.longitude);
        final distB = _haversine(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      AppLogger.info('[Overpass] Found ${pois.length} POIs within ${radiusMeters}m');
      return pois;
    } catch (e) {
      AppLogger.error('[Overpass] Failed to fetch POIs: $e');
      return [];
    }
  }

  /// Build the Overpass QL query for emergency amenities.
  String _buildQuery(double lat, double lon, int radius) {
    return '''
[out:json][timeout:10];
(
  node["amenity"="hospital"](around:$radius,$lat,$lon);
  node["amenity"="police"](around:$radius,$lat,$lon);
  node["amenity"="fire_station"](around:$radius,$lat,$lon);
  node["amenity"="pharmacy"](around:$radius,$lat,$lon);
  node["amenity"="shelter"](around:$radius,$lat,$lon);
  way["amenity"="hospital"](around:$radius,$lat,$lon);
  way["amenity"="police"](around:$radius,$lat,$lon);
  way["amenity"="fire_station"](around:$radius,$lat,$lon);
);
out center;
''';
  }

  /// Map OSM amenity tag to our EmergencyPoiType.
  EmergencyPoiType? _mapAmenityToType(String? amenity) {
    return switch (amenity) {
      'hospital' => EmergencyPoiType.hospital,
      'police' => EmergencyPoiType.policeStation,
      'fire_station' => EmergencyPoiType.fireStation,
      'pharmacy' => EmergencyPoiType.pharmacy,
      'shelter' => EmergencyPoiType.shelter,
      _ => null,
    };
  }

  /// Simple Haversine distance (meters) for sorting.
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters.
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  void dispose() {
    _client.close();
  }
}
