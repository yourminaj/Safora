import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/geofence_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Coordinate helpers
// 1 degree of latitude ≈ 111,319 m
// ─────────────────────────────────────────────────────────────────────────────
// Centre point: Dhaka, Bangladesh  23.8103°N, 90.4125°E
const _homeLat = 23.8103;
const _homeLon = 90.4125;

double _northOf(double lat, double metres) => lat + (metres / 111319.0);
double _eastOf(double lon, double lat, double metres) =>
    lon + metres / (111319.0 * _cosDeg(lat));

double _cosDeg(double deg) {
  const toRad = 3.14159265358979 / 180;
  var result = 1.0;
  var term = 1.0;
  final rad = deg * toRad;
  for (var i = 1; i <= 6; i++) {
    term *= -rad * rad / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

const _homeZone = SafeZone(
  id: 'home',
  name: 'Home',
  latitude: _homeLat,
  longitude: _homeLon,
  radiusMeters: 500,
);

final _officeZone = SafeZone(
  id: 'office',
  name: 'Office',
  latitude: _northOf(_homeLat, 5000),
  longitude: _homeLon,
  radiusMeters: 300,
);

void main() {
  // ─────────────────────────── Haversine accuracy ───────────────────────────
  group('Haversine formula accuracy', () {
    test('distance from a point to itself is zero', () {
      final d = GeofenceService.distanceMetersForTest(
        _homeLat, _homeLon, _homeLat, _homeLon,
      );
      expect(d, closeTo(0.0, 0.001));
    });

    test('Dhaka → Chittagong ≈ 214 km (real-world sanity check)', () {
      final d = GeofenceService.distanceMetersForTest(
        23.8103, 90.4125, // Dhaka
        22.3569, 91.7832, // Chittagong
      );
      expect(d, greaterThan(200000));
      expect(d, lessThan(230000));
    });

    test('400 m north of home is correctly computed', () {
      final lat2 = _northOf(_homeLat, 400);
      final d = GeofenceService.distanceMetersForTest(
        _homeLat, _homeLon, lat2, _homeLon,
      );
      expect(d, closeTo(400.0, 1.0));
    });

    test('symmetric: A→B == B→A', () {
      final d1 = GeofenceService.distanceMetersForTest(
        23.8103, 90.4125, 22.3569, 91.7832,
      );
      final d2 = GeofenceService.distanceMetersForTest(
        22.3569, 91.7832, 23.8103, 90.4125,
      );
      expect(d1, closeTo(d2, 0.001));
    });
  });

  // ────────────────────────── isInsideZone static ───────────────────────────
  group('GeofenceService.isInsideZone', () {
    test('centre is inside', () {
      expect(GeofenceService.isInsideZone(_homeZone, _homeLat, _homeLon), isTrue);
    });

    test('400 m north is inside 500 m zone', () {
      expect(GeofenceService.isInsideZone(_homeZone, _northOf(_homeLat, 400), _homeLon), isTrue);
    });

    test('boundary 500 m is inside (≤ radiusMeters)', () {
      expect(GeofenceService.isInsideZone(_homeZone, _northOf(_homeLat, 500), _homeLon), isTrue);
    });

    test('600 m north is outside 500 m zone', () {
      expect(GeofenceService.isInsideZone(_homeZone, _northOf(_homeLat, 600), _homeLon), isFalse);
    });

    test('diagonal 280 m NE is inside (hypotenuse ~396 m)', () {
      final lat = _northOf(_homeLat, 280);
      final lon = _eastOf(_homeLon, _homeLat, 280);
      expect(GeofenceService.isInsideZone(_homeZone, lat, lon), isTrue);
    });

    test('diagonal 380 m NE is outside (hypotenuse ~537 m)', () {
      final lat = _northOf(_homeLat, 380);
      final lon = _eastOf(_homeLon, _homeLat, 380);
      expect(GeofenceService.isInsideZone(_homeZone, lat, lon), isFalse);
    });
  });

  // ─────────────────────── firstZoneContaining ──────────────────────────────
  group('GeofenceService.firstZoneContaining', () {
    late GeofenceService svc;

    setUp(() {
      svc = GeofenceService(checkIntervalSeconds: 999);
      svc.addZone(_homeZone);
    });
    tearDown(() => svc.dispose());

    test('returns null when outside all zones', () {
      expect(svc.firstZoneContaining(_northOf(_homeLat, 700), _homeLon), isNull);
    });

    test('returns the matching zone when inside', () {
      final zone = svc.firstZoneContaining(_homeLat, _homeLon);
      expect(zone?.id, 'home');
    });

    test('returns first zone when two zones overlap at a point', () {
      const bigZone = SafeZone(
        id: 'big', name: 'Big', latitude: _homeLat,
        longitude: _homeLon, radiusMeters: 1000,
      );
      svc.addZone(bigZone); // home(500m) first, big(1000m) second.
      // 700 m north — inside big(1000), outside home(500) → should return big.
      final zone = svc.firstZoneContaining(_northOf(_homeLat, 700), _homeLon);
      expect(zone?.id, 'big');
    });
  });

  // ─────────────────── isOutsideAllZones state tracking ─────────────────────
  group('GeofenceService.isOutsideAllZones', () {
    late GeofenceService svc;

    setUp(() {
      svc = GeofenceService(checkIntervalSeconds: 999);
      svc.addZone(_homeZone);
    });
    tearDown(() => svc.dispose());

    test('initially false (user assumed inside)', () {
      expect(svc.isOutsideAllZones, isFalse);
    });

    test('stop() resets isOutsideAllZones to false', () {
      svc.stop();
      expect(svc.isOutsideAllZones, isFalse);
    });
  });

  // ────────────────────── Zone management ────────────────────────────────────
  group('GeofenceService zone management', () {
    late GeofenceService svc;

    setUp(() => svc = GeofenceService(checkIntervalSeconds: 999));
    tearDown(() => svc.dispose());

    test('addZone makes zone findable', () {
      svc.addZone(_homeZone);
      expect(svc.firstZoneContaining(_homeLat, _homeLon), isNotNull);
    });

    test('removeZone removes the zone', () {
      svc.addZone(_homeZone);
      svc.removeZone('home');
      expect(svc.firstZoneContaining(_homeLat, _homeLon), isNull);
    });

    test('multiple zones all registered', () {
      svc.addZone(_homeZone);
      svc.addZone(_officeZone);
      expect(svc.firstZoneContaining(_homeLat, _homeLon)?.id, 'home');
      expect(svc.firstZoneContaining(_officeZone.latitude, _homeLon)?.id, 'office');
    });

    test('dispose does not throw', () {
      svc.addZone(_homeZone);
      expect(() => svc.dispose(), returnsNormally);
    });
  });
}
