import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'app_logger.dart';

/// A safe zone defined by center coordinates and radius.
class SafeZone {
  const SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };

  factory SafeZone.fromMap(Map<String, dynamic> map) => SafeZone(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Zone',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 500,
      );
}

/// Monitors user position against defined safe zones.
///
/// Alerts when the user exits all defined safe zones.
/// Uses periodic GPS checks (default: every 30 seconds).
class GeofenceService {
  GeofenceService({
    this.checkIntervalSeconds = 30,
  });

  /// How often to check position in seconds.
  final int checkIntervalSeconds;

  Timer? _checkTimer;
  final List<SafeZone> _zones = [];
  bool _isOutsideAllZones = false;

  /// Whether the service is actively monitoring.
  bool get isRunning => _checkTimer != null;

  /// Current safe zones.
  List<SafeZone> get zones => List.unmodifiable(_zones);

  /// Add a safe zone.
  void addZone(SafeZone zone) {
    _zones.add(zone);
    AppLogger.info('[Geofence] Added zone: ${zone.name} '
        '(${zone.radiusMeters}m radius)');
  }

  /// Remove a safe zone by ID.
  void removeZone(String id) {
    _zones.removeWhere((z) => z.id == id);
    AppLogger.info('[Geofence] Removed zone: $id');
  }

  /// Load zones from Hive box.
  void loadZones(Box settingsBox) {
    final stored = settingsBox.get('geofence_zones') as List<dynamic>?;
    if (stored != null) {
      _zones.clear();
      for (final item in stored) {
        if (item is Map) {
          _zones.add(SafeZone.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      AppLogger.info('[Geofence] Loaded ${_zones.length} zones');
    }
  }

  /// Save zones to Hive box.
  Future<void> saveZones(Box settingsBox) async {
    await settingsBox.put(
      'geofence_zones',
      _zones.map((z) => z.toMap()).toList(),
    );
  }

  /// Start geofence monitoring.
  ///
  /// [onExitAllZones] is called when the user leaves all defined zones.
  /// [onReenterZone] is called when the user re-enters any zone.
  void start({
    required void Function(Position position) onExitAllZones,
    void Function(SafeZone zone)? onReenterZone,
  }) {
    if (_checkTimer != null || _zones.isEmpty) return;

    _checkTimer = Timer.periodic(
      Duration(seconds: checkIntervalSeconds),
      (_) => _checkPosition(
        onExitAllZones: onExitAllZones,
        onReenterZone: onReenterZone,
      ),
    );

    AppLogger.info('[Geofence] Started monitoring ${_zones.length} zones');
  }

  /// Stop geofence monitoring.
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isOutsideAllZones = false;
    AppLogger.info('[Geofence] Stopped monitoring');
  }

  Future<void> _checkPosition({
    required void Function(Position position) onExitAllZones,
    void Function(SafeZone zone)? onReenterZone,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Check if inside any zone.
      SafeZone? insideZone;
      for (final zone in _zones) {
        final distance = _distanceMeters(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );
        if (distance <= zone.radiusMeters) {
          insideZone = zone;
          break;
        }
      }

      if (insideZone != null) {
        // User is inside a zone.
        if (_isOutsideAllZones) {
          _isOutsideAllZones = false;
          onReenterZone?.call(insideZone);
          AppLogger.info('[Geofence] Re-entered zone: ${insideZone.name}');
        }
      } else {
        // User is outside all zones.
        if (!_isOutsideAllZones) {
          _isOutsideAllZones = true;
          onExitAllZones(position);
          AppLogger.info('[Geofence] Exited all safe zones');
        }
      }
    } catch (e) {
      AppLogger.warning('[Geofence] Position check failed: $e');
    }
  }

  /// Haversine formula for distance between two coordinates in meters.
  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Exposed for testing only.
  static double distanceMetersForTest(
    double lat1, double lon1, double lat2, double lon2,
  ) => _distanceMeters(lat1, lon1, lat2, lon2);

  /// Release resources.
  void dispose() {
    stop();
    _zones.clear();
  }
}
