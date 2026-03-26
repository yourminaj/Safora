import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safora/core/services/location_service.dart';

/// Helper to create a Position for testing.
Position _fakePosition({
  double lat = 23.8103,
  double lng = 90.4125,
  double alt = 10.0,
  double speed = 0.0,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 3, 26),
    accuracy: 10,
    altitude: alt,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocationService service;

  setUp(() {
    service = LocationService();
  });

  group('LocationService — State Management', () {
    test('lastPosition is null initially', () {
      expect(service.lastPosition, isNull);
    });
  });

  group('LocationService — generateMapsLink', () {
    test('returns valid Google Maps URL with correct coordinates', () {
      final position = _fakePosition(lat: 23.8103, lng: 90.4125);
      final link = service.generateMapsLink(position);
      expect(link, contains('23.8103'));
      expect(link, contains('90.4125'));
      expect(
        link,
        anyOf(contains('maps.google.com'), contains('google.com/maps')),
      );
    });

    test('handles negative coordinates (southern/western hemisphere)', () {
      final position = _fakePosition(lat: -33.8688, lng: -151.2093);
      final link = service.generateMapsLink(position);
      expect(link, contains('-33.8688'));
      expect(link, contains('-151.2093'));
    });

    test('handles zero coordinates (null island)', () {
      final position = _fakePosition(lat: 0.0, lng: 0.0);
      final link = service.generateMapsLink(position);
      expect(link, contains('0.0'));
      expect(link, startsWith('https://'));
    });

    test('handles extreme coordinates (poles)', () {
      final position = _fakePosition(lat: 90.0, lng: 180.0);
      final link = service.generateMapsLink(position);
      expect(link, contains('90.0'));
      expect(link, contains('180.0'));
    });
  });

  group('LocationService — buildLocationMessage', () {
    test('returns "Location unavailable." when Geolocator is unavailable', () async {
      // In test environment, Geolocator throws MissingPluginException.
      // getCurrentPosition catches this and returns null (_lastPosition).
      // buildLocationMessage then returns the fallback message.
      final message = await service.buildLocationMessage();
      expect(message, 'Location unavailable.');
    });
  });

  group('LocationService — ensurePermission', () {
    test('returns false when Geolocator platform is unavailable', () async {
      // After the fix, ensurePermission catches MissingPluginException
      // and returns false gracefully instead of crashing.
      final result = await service.ensurePermission();
      expect(result, false);
    });
  });

  group('LocationService — getCurrentPosition', () {
    test('returns null when Geolocator is unavailable', () async {
      // getCurrentPosition catches the MissingPluginException from
      // ensurePermission and returns _lastPosition (null initially).
      final position = await service.getCurrentPosition();
      expect(position, isNull);
    });
  });
}
