import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/models/emergency_poi.dart';

/// Unit tests for EmergencyPoi — validates factory parsing, fallback logic.
void main() {
  group('EmergencyPoi.fromOverpassElement', () {
    test('parses direct lat/lon correctly', () {
      final element = {
        'lat': 23.8103,
        'lon': 90.4125,
        'tags': {
          'name': 'Dhaka Medical College',
          'amenity': 'hospital',
          'phone': '+880-2-555',
        },
      };

      final poi =
          EmergencyPoi.fromOverpassElement(element, EmergencyPoiType.hospital);

      expect(poi.name, 'Dhaka Medical College');
      expect(poi.latitude, 23.8103);
      expect(poi.longitude, 90.4125);
      expect(poi.phone, '+880-2-555');
      expect(poi.type, EmergencyPoiType.hospital);
    });

    test('falls back to center lat/lon when direct not present', () {
      final element = {
        'center': {'lat': 40.7128, 'lon': -74.0060},
        'tags': {'name': 'NYC Police HQ'},
      };

      final poi = EmergencyPoi.fromOverpassElement(
          element, EmergencyPoiType.policeStation);

      expect(poi.latitude, 40.7128);
      expect(poi.longitude, -74.0060);
      expect(poi.name, 'NYC Police HQ');
    });

    test('defaults to 0.0 when no lat/lon or center', () {
      final element = <String, dynamic>{
        'tags': {'name': 'Unknown Place'},
      };

      final poi =
          EmergencyPoi.fromOverpassElement(element, EmergencyPoiType.shelter);

      expect(poi.latitude, 0.0);
      expect(poi.longitude, 0.0);
    });

    test('uses amenity tag when name is absent', () {
      final element = {
        'lat': 1.0,
        'lon': 2.0,
        'tags': {'amenity': 'pharmacy'},
      };

      final poi =
          EmergencyPoi.fromOverpassElement(element, EmergencyPoiType.pharmacy);
      expect(poi.name, 'pharmacy');
    });

    test('uses type label as fallback when no name or amenity', () {
      final element = {
        'lat': 1.0,
        'lon': 2.0,
        'tags': <String, dynamic>{},
      };

      final poi = EmergencyPoi.fromOverpassElement(
          element, EmergencyPoiType.fireStation);
      expect(poi.name, 'Fire Station');
    });

    test('handles entirely missing tags', () {
      final element = {
        'lat': 10.0,
        'lon': 20.0,
      };

      final poi =
          EmergencyPoi.fromOverpassElement(element, EmergencyPoiType.hospital);
      expect(poi.name, 'Hospital');
      expect(poi.phone, isNull);
    });
  });

  group('EmergencyPoiType', () {
    test('all types have labels', () {
      for (final type in EmergencyPoiType.values) {
        expect(type.label, isNotEmpty);
      }
    });

    test('5 types exist', () {
      expect(EmergencyPoiType.values.length, 5);
    });
  });
}
