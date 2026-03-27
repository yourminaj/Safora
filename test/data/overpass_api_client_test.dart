import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:safora/data/datasources/overpass_api_client.dart';
import 'package:safora/data/models/emergency_poi.dart';

void main() {
  group('OverpassApiClient', () {
    test('parses valid Overpass response into EmergencyPoi list', () async {
      final mockClient = MockClient((request) async {
        final responseBody = jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 123,
              'lat': 23.8103,
              'lon': 90.4125,
              'tags': {
                'amenity': 'hospital',
                'name': 'Dhaka Medical College',
                'phone': '+880-2-12345678',
              },
            },
            {
              'type': 'node',
              'id': 456,
              'lat': 23.8120,
              'lon': 90.4150,
              'tags': {
                'amenity': 'police',
                'name': 'Lalbagh Police Station',
              },
            },
            {
              'type': 'way',
              'id': 789,
              'center': {'lat': 23.8090, 'lon': 90.4100},
              'tags': {
                'amenity': 'fire_station',
                'name': 'Dhaka Fire Service',
              },
            },
          ],
        });
        return http.Response(responseBody, 200);
      });

      final client = OverpassApiClient(httpClient: mockClient);

      final pois = await client.fetchNearbyPois(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(pois.length, equals(3));

      // Verify hospital.
      final hospital = pois.firstWhere(
        (p) => p.type == EmergencyPoiType.hospital,
      );
      expect(hospital.name, equals('Dhaka Medical College'));
      expect(hospital.phone, equals('+880-2-12345678'));

      // Verify police station.
      final police = pois.firstWhere(
        (p) => p.type == EmergencyPoiType.policeStation,
      );
      expect(police.name, equals('Lalbagh Police Station'));

      // Verify fire station (from way with center).
      final fire = pois.firstWhere(
        (p) => p.type == EmergencyPoiType.fireStation,
      );
      expect(fire.name, equals('Dhaka Fire Service'));
      expect(fire.latitude, equals(23.8090));

      client.dispose();
    });

    test('returns empty list on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too Many Requests', 429);
      });

      final client = OverpassApiClient(httpClient: mockClient);

      final pois = await client.fetchNearbyPois(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(pois, isEmpty);
      client.dispose();
    });

    test('returns empty list on invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final client = OverpassApiClient(httpClient: mockClient);

      final pois = await client.fetchNearbyPois(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(pois, isEmpty);
      client.dispose();
    });

    test('returns empty list on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final client = OverpassApiClient(httpClient: mockClient);

      final pois = await client.fetchNearbyPois(
        latitude: 23.8103,
        longitude: 90.4125,
      );

      expect(pois, isEmpty);
      client.dispose();
    });

    test('skips elements with unknown amenity type', () async {
      final mockClient = MockClient((request) async {
        final responseBody = jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': 23.81,
              'lon': 90.41,
              'tags': {'amenity': 'restaurant', 'name': 'A Restaurant'},
            },
            {
              'type': 'node',
              'id': 2,
              'lat': 23.81,
              'lon': 90.41,
              'tags': {'amenity': 'pharmacy', 'name': 'City Pharmacy'},
            },
          ],
        });
        return http.Response(responseBody, 200);
      });

      final client = OverpassApiClient(httpClient: mockClient);

      final pois = await client.fetchNearbyPois(
        latitude: 23.81,
        longitude: 90.41,
      );

      // restaurant should be filtered out, pharmacy should remain.
      expect(pois.length, equals(1));
      expect(pois.first.type, equals(EmergencyPoiType.pharmacy));
      client.dispose();
    });
  });

  group('EmergencyPoi', () {
    test('fromOverpassElement uses name tag', () {
      final poi = EmergencyPoi.fromOverpassElement({
        'lat': 1.0,
        'lon': 2.0,
        'tags': {'name': 'Test Hospital', 'amenity': 'hospital'},
      }, EmergencyPoiType.hospital);

      expect(poi.name, equals('Test Hospital'));
      expect(poi.latitude, equals(1.0));
      expect(poi.longitude, equals(2.0));
    });

    test('fromOverpassElement falls back to amenity tag when no name', () {
      final poi = EmergencyPoi.fromOverpassElement({
        'lat': 1.0,
        'lon': 2.0,
        'tags': {'amenity': 'hospital'},
      }, EmergencyPoiType.hospital);

      expect(poi.name, equals('hospital'));
    });

    test('fromOverpassElement falls back to type label when no tags', () {
      final poi = EmergencyPoi.fromOverpassElement({
        'lat': 1.0,
        'lon': 2.0,
      }, EmergencyPoiType.policeStation);

      expect(poi.name, equals('Police Station'));
    });
  });
}
