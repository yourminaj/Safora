import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/models/sos_history_entry.dart';

void main() {
  group('SosHistoryEntry', () {
    final now = DateTime(2026, 3, 24, 12, 0);

    test('toMap serializes all fields correctly', () {
      final entry = SosHistoryEntry(
        timestamp: now,
        latitude: 23.8103,
        longitude: 90.4125,
        address: '123 Main St, Dhaka',
        contactsNotified: 3,
        smsSentCount: 2,
        wasCancelled: false,
        triggerSource: SosTriggerSource.shake,
      );
      final map = entry.toMap();
      expect(map['timestamp'], now.toIso8601String());
      expect(map['latitude'], 23.8103);
      expect(map['longitude'], 90.4125);
      expect(map['address'], '123 Main St, Dhaka');
      expect(map['contactsNotified'], 3);
      expect(map['smsSentCount'], 2);
      expect(map['wasCancelled'], false);
      expect(map['triggerSource'], 'shake');
    });

    test('fromMap deserializes all fields correctly', () {
      final map = {
        'timestamp': now.toIso8601String(),
        'latitude': 23.8103,
        'longitude': 90.4125,
        'address': 'Dhaka',
        'contactsNotified': 5,
        'smsSentCount': 4,
        'wasCancelled': true,
        'triggerSource': 'crashDetection',
      };
      final entry = SosHistoryEntry.fromMap(map);
      expect(entry.timestamp, now);
      expect(entry.latitude, 23.8103);
      expect(entry.contactsNotified, 5);
      expect(entry.wasCancelled, true);
      expect(entry.triggerSource, SosTriggerSource.crashDetection);
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'timestamp': now.toIso8601String(),
        'contactsNotified': 0,
        'smsSentCount': 0,
        'wasCancelled': false,
      };
      final entry = SosHistoryEntry.fromMap(map);
      expect(entry.latitude, isNull);
      expect(entry.longitude, isNull);
      expect(entry.address, isNull);
      expect(entry.triggerSource, SosTriggerSource.manual);
    });

    test('fromMap handles unknown trigger source', () {
      final map = {
        'timestamp': now.toIso8601String(),
        'triggerSource': 'unknownSource',
      };
      final entry = SosHistoryEntry.fromMap(map);
      expect(entry.triggerSource, SosTriggerSource.manual);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = SosHistoryEntry(
        timestamp: now,
        latitude: 1.5,
        longitude: 2.5,
        contactsNotified: 1,
        smsSentCount: 1,
        wasCancelled: false,
        triggerSource: SosTriggerSource.background,
      );
      final restored = SosHistoryEntry.fromMap(original.toMap());
      expect(restored, original);
    });

    test('Equatable equality works', () {
      final a = SosHistoryEntry(
        timestamp: now,
        contactsNotified: 1,
        smsSentCount: 1,
        wasCancelled: false,
      );
      final b = SosHistoryEntry(
        timestamp: now,
        contactsNotified: 1,
        smsSentCount: 1,
        wasCancelled: false,
      );
      expect(a, b);
    });
  });

  group('SosTriggerSource', () {
    test('has correct values', () {
      expect(SosTriggerSource.values.length, 10);
      expect(SosTriggerSource.manual.name, 'manual');
      expect(SosTriggerSource.shake.name, 'shake');
      expect(SosTriggerSource.crashDetection.name, 'crashDetection');
      expect(SosTriggerSource.fall.name, 'fall');
      expect(SosTriggerSource.snatch.name, 'snatch');
      expect(SosTriggerSource.voiceDistress.name, 'voiceDistress');
      expect(SosTriggerSource.anomalyMovement.name, 'anomalyMovement');
      expect(SosTriggerSource.deadManSwitch.name, 'deadManSwitch');
      expect(SosTriggerSource.geofenceExit.name, 'geofenceExit');
      expect(SosTriggerSource.background.name, 'background');
    });
  });
}
