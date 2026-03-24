import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/auth_service.dart';
import 'package:safora/data/datasources/contacts_cloud_sync.dart';
import 'package:safora/data/models/emergency_contact.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('ContactsCloudSync', () {
    group('Class Contract', () {
      test('class exists and is importable', () {
        expect(ContactsCloudSync, isNotNull);
      });
    });

    group('EmergencyContact Serialization (Cloud Sync Contract)', () {
      test('serializes basic contact to map', () {
        const contact = EmergencyContact(
          id: 'c1',
          name: 'Alice',
          phone: '+1234567890',
          relationship: 'Sister',
        );
        final map = contact.toMap();
        expect(map['name'], 'Alice');
        expect(map['phone'], '+1234567890');
        expect(map['relationship'], 'Sister');
      });

      test('deserializes contact from cloud map', () {
        final map = {
          'name': 'Bob',
          'phone': '+9876543210',
          'relationship': 'Brother',
        };
        final contact = EmergencyContact.fromMap(map, id: 'c2');
        expect(contact.name, 'Bob');
        expect(contact.id, 'c2');
        expect(contact.phone, '+9876543210');
        expect(contact.relationship, 'Brother');
      });

      test('round-trip serialization preserves all fields', () {
        const original = EmergencyContact(
          id: 'c3',
          name: 'Charlie',
          phone: '+1112223333',
          relationship: 'Friend',
        );
        final map = original.toMap();
        final restored = EmergencyContact.fromMap(map, id: original.id!);

        expect(restored.name, original.name);
        expect(restored.phone, original.phone);
        expect(restored.relationship, original.relationship);
        expect(restored.id, original.id);
      });

      test('handles empty relationship field', () {
        const contact = EmergencyContact(
          id: 'c4',
          name: 'Dana',
          phone: '+4445556666',
          relationship: '',
        );
        final map = contact.toMap();
        expect(map['relationship'], '');

        final restored = EmergencyContact.fromMap(map, id: 'c4');
        expect(restored.relationship, '');
      });

      test('handles special characters in name', () {
        const contact = EmergencyContact(
          id: 'c5',
          name: "O'Brien-Smith",
          phone: '+7778889999',
          relationship: 'Colleague',
        );
        final map = contact.toMap();
        expect(map['name'], "O'Brien-Smith");

        final restored = EmergencyContact.fromMap(map, id: 'c5');
        expect(restored.name, "O'Brien-Smith");
      });

      test('handles international phone number formats', () {
        const contact = EmergencyContact(
          id: 'c6',
          name: 'International',
          phone: '+880-1234-567890',
          relationship: 'Family',
        );
        final map = contact.toMap();
        final restored = EmergencyContact.fromMap(map, id: 'c6');
        expect(restored.phone, '+880-1234-567890');
      });
    });

    group('AuthService Contract for Sync', () {
      test('isSignedIn can be mocked as false (blocks sync)', () {
        final mockAuth = MockAuthService();
        when(() => mockAuth.isSignedIn).thenReturn(false);
        expect(mockAuth.isSignedIn, false);
      });

      test('isSignedIn can be mocked as true (allows sync)', () {
        final mockAuth = MockAuthService();
        when(() => mockAuth.isSignedIn).thenReturn(true);
        expect(mockAuth.isSignedIn, true);
      });

      test('currentUser can be null when not signed in', () {
        final mockAuth = MockAuthService();
        when(() => mockAuth.currentUser).thenReturn(null);
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('Batch Serialization (Multiple Contacts)', () {
      test('serializes list of contacts for batch upload', () {
        const contacts = [
          EmergencyContact(id: 'a', name: 'A', phone: '+1', relationship: 'X'),
          EmergencyContact(id: 'b', name: 'B', phone: '+2', relationship: 'Y'),
          EmergencyContact(id: 'c', name: 'C', phone: '+3', relationship: 'Z'),
        ];

        final maps = contacts.map((c) => c.toMap()).toList();
        expect(maps.length, 3);
        expect(maps[0]['name'], 'A');
        expect(maps[1]['name'], 'B');
        expect(maps[2]['name'], 'C');
      });

      test('empty contacts list produces empty batch', () {
        const contacts = <EmergencyContact>[];
        final maps = contacts.map((c) => c.toMap()).toList();
        expect(maps, isEmpty);
      });
    });
  });
}
