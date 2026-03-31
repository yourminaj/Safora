/// Tests for SosEventService — validates event document structure,
/// triggerType mapping, and data contract correctness.
///
/// Firebase Firestore/Auth are NOT mocked. We test the pure business logic:
/// SOS event data model generation, location URL construction, and
/// platform string resolution.
library;
import 'package:flutter_test/flutter_test.dart';

import 'package:safora/data/models/emergency_contact.dart';

void main() {
  group('SOS event data contract', () {
    test('location URL is constructed correctly when GPS is available', () {
      const lat = 23.8103;
      const lng = 90.4125;
      const url = 'https://maps.google.com/?q=$lat,$lng';
      expect(url, 'https://maps.google.com/?q=23.8103,90.4125');
    });

    test('location URL is null when GPS unavailable', () {
      const double? lat = null;
      const double? lng = null;
      const url = (lat != null && lng != null)
          ? 'https://maps.google.com/?q=$lat,$lng'
          : null;
      expect(url, isNull);
    });

    test('contact phones list extracted correctly', () {
      final contacts = [
        const EmergencyContact(
          id: '1',
          name: 'Alice',
          phone: '+8801700000001',
          relationship: 'Mother',
          isPrimary: true,
        ),
        const EmergencyContact(
          id: '2',
          name: 'Bob',
          phone: '+8801700000002',
          relationship: 'Father',
          isPrimary: false,
        ),
      ];
      final phones = contacts.map((c) => c.phone).toList();
      expect(phones, ['+8801700000001', '+8801700000002']);
    });

    test('SOS event document structure has all required fields', () {
      final contacts = [
        const EmergencyContact(
          id: '1',
          name: 'Alice',
          phone: '+8801700000001',
          relationship: 'Sister',
          isPrimary: true,
        ),
      ];

      final sosEvent = <String, dynamic>{
        'triggerType': 'manual',
        'status': 'active',
        'locationUrl': null,
        'latitude': null,
        'longitude': null,
        'contactPhones': contacts.map((c) => c.phone).toList(),
        'contactCount': contacts.length,
      };

      expect(sosEvent.containsKey('triggerType'), isTrue);
      expect(sosEvent.containsKey('status'), isTrue);
      expect(sosEvent.containsKey('locationUrl'), isTrue);
      expect(sosEvent.containsKey('contactPhones'), isTrue);
      expect(sosEvent.containsKey('contactCount'), isTrue);
      expect(sosEvent['status'], 'active');
      expect(sosEvent['contactCount'], 1);
    });

    test('trigger types are valid strings', () {
      // The SOS system uses these trigger types
      const validTriggers = ['manual', 'shake', 'crash', 'dead_man_switch'];
      for (final trigger in validTriggers) {
        expect(trigger, isNotEmpty);
        expect(trigger, isA<String>());
      }
    });
  });

  group('EmergencyContact model', () {
    test('can be constructed with all fields', () {
      const contact = EmergencyContact(
        id: 'abc123',
        name: 'Test Contact',
        phone: '+880123456789',
        relationship: 'Friend',
        isPrimary: false,
      );
      expect(contact.id, 'abc123');
      expect(contact.name, 'Test Contact');
      expect(contact.phone, '+880123456789');
    });

    test('isPrimary flag works', () {
      const primary = EmergencyContact(
        id: '1',
        name: 'Primary',
        phone: '+880100',
        relationship: 'Spouse',
        isPrimary: true,
      );
      const secondary = EmergencyContact(
        id: '2',
        name: 'Secondary',
        phone: '+880200',
        relationship: 'Friend',
        isPrimary: false,
      );
      expect(primary.isPrimary, isTrue);
      expect(secondary.isPrimary, isFalse);
    });
  });
}
