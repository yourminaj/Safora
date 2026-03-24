import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/models/alert_event.dart';

void main() {
  group('AlertEvent', () {
    final now = DateTime(2026, 3, 24, 14, 30);

    test('toMap serializes all fields', () {
      final alert = AlertEvent(
        id: 'abc',
        type: AlertType.earthquake,
        title: 'M5.2 Earthquake',
        description: 'Near Dhaka',
        latitude: 23.81,
        longitude: 90.41,
        timestamp: now,
        source: 'USGS',
        magnitude: 5.2,
        isActive: true,
        isUserTriggered: false,
      );
      final map = alert.toMap();
      expect(map['type'], 'earthquake');
      expect(map['title'], 'M5.2 Earthquake');
      expect(map['description'], 'Near Dhaka');
      expect(map['latitude'], 23.81);
      expect(map['longitude'], 90.41);
      expect(map['timestamp'], now.toIso8601String());
      expect(map['source'], 'USGS');
      expect(map['magnitude'], 5.2);
      expect(map['isActive'], true);
      expect(map['isUserTriggered'], false);
    });

    test('fromMap deserializes all fields', () {
      final map = {
        'type': 'flood',
        'title': 'Flood Warning',
        'description': 'River rising',
        'latitude': 23.0,
        'longitude': 90.0,
        'timestamp': now.toIso8601String(),
        'source': 'BMD',
        'magnitude': 3.5,
        'isActive': false,
        'isUserTriggered': true,
      };
      final alert = AlertEvent.fromMap(map, id: 'xyz');
      expect(alert.id, 'xyz');
      expect(alert.type, AlertType.flood);
      expect(alert.title, 'Flood Warning');
      expect(alert.latitude, 23.0);
      expect(alert.isActive, false);
      expect(alert.isUserTriggered, true);
      expect(alert.magnitude, 3.5);
    });

    test('fromMap handles unknown type gracefully', () {
      final map = {
        'type': 'unknownType',
        'title': 'Unknown',
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': now.toIso8601String(),
      };
      final alert = AlertEvent.fromMap(map);
      expect(alert.type, AlertType.manualSos);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'type': 'earthquake',
        'title': 'Quake',
        'latitude': 1.0,
        'longitude': 2.0,
        'timestamp': now.toIso8601String(),
      };
      final alert = AlertEvent.fromMap(map);
      expect(alert.description, isNull);
      expect(alert.source, isNull);
      expect(alert.magnitude, isNull);
      expect(alert.isActive, true);
      expect(alert.isUserTriggered, false);
    });

    test('copyWith preserves unchanged fields', () {
      final original = AlertEvent(
        type: AlertType.earthquake,
        title: 'Quake',
        latitude: 1.0,
        longitude: 2.0,
        timestamp: now,
        magnitude: 4.0,
      );
      final updated = original.copyWith(title: 'Updated Quake');
      expect(updated.title, 'Updated Quake');
      expect(updated.magnitude, 4.0);
      expect(updated.type, AlertType.earthquake);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = AlertEvent(
        type: AlertType.cyclone,
        title: 'Cyclone Mocha',
        latitude: 21.0,
        longitude: 92.0,
        timestamp: now,
        source: 'BMD',
        magnitude: 180.0,
      );
      final restored = AlertEvent.fromMap(original.toMap());
      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.source, original.source);
    });

    test('Equatable equality', () {
      final a = AlertEvent(
        type: AlertType.earthquake,
        title: 'Q',
        latitude: 1,
        longitude: 2,
        timestamp: now,
      );
      final b = AlertEvent(
        type: AlertType.earthquake,
        title: 'Q',
        latitude: 1,
        longitude: 2,
        timestamp: now,
      );
      expect(a, b);
    });
  });
}
