import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safora/core/services/location_service.dart';

// LocationService uses static Geolocator calls, so we test the public API
// surface by verifying the service's internal logic and state management.

void main() {
  late LocationService service;

  setUp(() {
    service = LocationService();
  });

  group('LocationService', () {
    test('lastPosition is null initially', () {
      expect(service.lastPosition, isNull);
    });

    test('generateMapsLink returns valid URL', () {
      final position = Position(
        latitude: 23.8103,
        longitude: 90.4125,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final link = service.generateMapsLink(position);
      expect(link, contains('23.8103'));
      expect(link, contains('90.4125'));
      expect(link, anyOf(contains('maps.google.com'), contains('google.com/maps')));
    });
  });
}
