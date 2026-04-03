import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, sin, cos, sqrt, atan2, pi;
import 'package:http/http.dart' as http;
import '../models/emergency_poi.dart';
import '../../core/services/app_logger.dart';

/// Client for the OpenStreetMap Overpass API.
///
/// Fetches nearby emergency services (hospitals, police, fire stations,
/// pharmacies, shelters) within a given radius of a location.
///
/// Uses the public Overpass API. Rate limited but free. No API key needed.
/// Implements exponential backoff with jitter for transient failures (504s).
class OverpassApiClient {
  OverpassApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;
  final _random = Random();

  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Maximum radius in meters (5 km default).
  static const int defaultRadiusMeters = 5000;

  /// Retry configuration for transient failures.
  static const int _maxAttempts = 3;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(seconds: 16);

  /// HTTP status codes that warrant a retry (transient server errors).
  static const _retryableStatusCodes = {429, 500, 502, 503, 504};

  /// Fetch all emergency POIs near the given coordinates.
  ///
  /// Returns a combined list of hospitals, police, fire stations, etc.
  /// Sorted by distance from the center point.
  /// Retries up to [_maxAttempts] times on transient server errors.
  Future<List<EmergencyPoi>> fetchNearbyPois({
    required double latitude,
    required double longitude,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    final query = _buildQuery(latitude, longitude, radiusMeters);

    try {
      final response = await _retryWithBackoff(() async {
        return await _client.post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'data': query},
        ).timeout(const Duration(seconds: 15));
      });

      if (response.statusCode != 200) {
        final snippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        AppLogger.error(
          '[Overpass] HTTP ${response.statusCode}: $snippet',
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

  /// Execute [operation] with exponential backoff and full jitter.
  ///
  /// Retries on:
  /// - [SocketException] (network unreachable)
  /// - [TimeoutException] (request timed out)
  /// - HTTP responses with retryable status codes (429, 500-504)
  ///
  /// Uses "Full Jitter" strategy (AWS best practice) to prevent
  /// thundering herd when the Overpass API recovers from an outage.
  Future<http.Response> _retryWithBackoff(
    Future<http.Response> Function() operation,
  ) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await operation();

        // Success or non-retryable error — return immediately.
        if (!_retryableStatusCodes.contains(response.statusCode) ||
            attempt == _maxAttempts) {
          return response;
        }

        // Retryable HTTP error — log and wait.
        final delay = _calculateDelay(attempt);
        AppLogger.warning(
          '[Overpass] HTTP ${response.statusCode} on attempt $attempt/$_maxAttempts. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      } on SocketException {
        if (attempt == _maxAttempts) rethrow;
        final delay = _calculateDelay(attempt);
        AppLogger.warning(
          '[Overpass] Network error on attempt $attempt/$_maxAttempts. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      } on TimeoutException {
        if (attempt == _maxAttempts) rethrow;
        final delay = _calculateDelay(attempt);
        AppLogger.warning(
          '[Overpass] Timeout on attempt $attempt/$_maxAttempts. '
          'Retrying in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      }
    }

    // Should never reach here, but satisfy the type system.
    throw StateError('[Overpass] Exhausted all retry attempts');
  }

  /// Calculate delay with full jitter: random(0, min(maxDelay, base * 2^attempt))
  Duration _calculateDelay(int attempt) {
    final exponentialMs =
        _baseDelay.inMilliseconds * (1 << (attempt - 1)); // 2^(attempt-1)
    final cappedMs = exponentialMs.clamp(0, _maxDelay.inMilliseconds);
    final jitteredMs = _random.nextInt(cappedMs + 1); // Full jitter: [0, cap]
    return Duration(milliseconds: jitteredMs);
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
