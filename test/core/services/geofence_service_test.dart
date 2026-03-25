import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/geofence_service.dart';

void main() {
  group('SafeZone', () {
    test('creates from constructor', () {
      const zone = SafeZone(
        id: 'home',
        name: 'Home',
        latitude: 23.8103,
        longitude: 90.4125,
        radiusMeters: 500,
      );

      expect(zone.id, 'home');
      expect(zone.name, 'Home');
      expect(zone.latitude, 23.8103);
      expect(zone.longitude, 90.4125);
      expect(zone.radiusMeters, 500);
    });

    test('serializes to map', () {
      const zone = SafeZone(
        id: 'office',
        name: 'Office',
        latitude: 23.7,
        longitude: 90.3,
        radiusMeters: 200,
      );
      final map = zone.toMap();

      expect(map['id'], 'office');
      expect(map['name'], 'Office');
      expect(map['latitude'], 23.7);
      expect(map['longitude'], 90.3);
      expect(map['radiusMeters'], 200);
    });

    test('deserializes from map', () {
      final zone = SafeZone.fromMap({
        'id': 'school',
        'name': 'School',
        'latitude': 23.9,
        'longitude': 90.5,
        'radiusMeters': 300,
      });

      expect(zone.id, 'school');
      expect(zone.name, 'School');
      expect(zone.latitude, 23.9);
      expect(zone.radiusMeters, 300);
    });

    test('handles missing map values with defaults', () {
      final zone = SafeZone.fromMap(<String, dynamic>{});

      expect(zone.id, '');
      expect(zone.name, 'Zone');
      expect(zone.latitude, 0);
      expect(zone.longitude, 0);
      expect(zone.radiusMeters, 500);
    });

    test('roundtrip toMap -> fromMap preserves data', () {
      const original = SafeZone(
        id: 'rt',
        name: 'Roundtrip',
        latitude: 51.5074,
        longitude: -0.1278,
        radiusMeters: 1000,
      );
      final restored = SafeZone.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.radiusMeters, original.radiusMeters);
    });
  });

  group('GeofenceService', () {
    late GeofenceService service;

    setUp(() {
      service = GeofenceService(checkIntervalSeconds: 60);
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not running with empty zones', () {
      expect(service.isRunning, isFalse);
      expect(service.zones, isEmpty);
    });

    test('addZone increases zones list', () {
      service.addZone(const SafeZone(
        id: 'z1',
        name: 'Zone 1',
        latitude: 23.8,
        longitude: 90.4,
        radiusMeters: 500,
      ));

      expect(service.zones, hasLength(1));
      expect(service.zones.first.id, 'z1');
    });

    test('removeZone decreases zones list', () {
      service.addZone(const SafeZone(
        id: 'z1',
        name: 'Zone 1',
        latitude: 23.8,
        longitude: 90.4,
        radiusMeters: 500,
      ));
      service.addZone(const SafeZone(
        id: 'z2',
        name: 'Zone 2',
        latitude: 24.0,
        longitude: 91.0,
        radiusMeters: 300,
      ));

      service.removeZone('z1');

      expect(service.zones, hasLength(1));
      expect(service.zones.first.id, 'z2');
    });

    test('zones list is unmodifiable', () {
      expect(
        () => service.zones.add(const SafeZone(
          id: 'hack',
          name: 'Hack',
          latitude: 0,
          longitude: 0,
          radiusMeters: 0,
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('stop is safe when not running', () {
      expect(() => service.stop(), returnsNormally);
    });

    test('dispose clears zones and stops', () {
      service.addZone(const SafeZone(
        id: 'z1',
        name: 'Zone 1',
        latitude: 23.8,
        longitude: 90.4,
        radiusMeters: 500,
      ));

      service.dispose();

      expect(service.zones, isEmpty);
      expect(service.isRunning, isFalse);
    });

    test('start does nothing when zones are empty', () {
      service.start(onExitAllZones: (_) {});

      // Should not start because zones is empty.
      expect(service.isRunning, isFalse);
    });

    test('Haversine distance calculation is accurate', () {
      // Dhaka to Chittagong ≈ 252km
      final distance = GeofenceService.distanceMetersForTest(
        23.8103, 90.4125, // Dhaka
        22.3569, 91.7832, // Chittagong
      );

      // Should be approximately 214km (±20km tolerance).
      expect(distance, greaterThan(190000));
      expect(distance, lessThan(240000));
    });
  });
}
