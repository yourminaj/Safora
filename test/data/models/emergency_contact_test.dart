import 'package:flutter_test/flutter_test.dart';
import 'package:safora_sos/data/models/emergency_contact.dart';

void main() {
  group('EmergencyContact', () {
    const contact = EmergencyContact(
      id: '123',
      name: 'Mom',
      phone: '+8801712345678',
      relationship: 'Mother',
      isPrimary: true,
    );

    test('toMap serializes all fields correctly', () {
      final map = contact.toMap();

      expect(map['name'], 'Mom');
      expect(map['phone'], '+8801712345678');
      expect(map['relationship'], 'Mother');
      expect(map['isPrimary'], true);
    });

    test('fromMap deserializes all fields correctly', () {
      final map = {
        'name': 'Brother',
        'phone': '+8801787654321',
        'relationship': 'Brother',
        'isPrimary': false,
        'createdAt': '2026-03-21T00:00:00.000',
      };

      final result = EmergencyContact.fromMap(map, id: '456');

      expect(result.id, '456');
      expect(result.name, 'Brother');
      expect(result.phone, '+8801787654321');
      expect(result.relationship, 'Brother');
      expect(result.isPrimary, false);
      expect(result.createdAt, isNotNull);
    });

    test('fromMap handles missing optional fields', () {
      final minimalMap = {
        'name': 'Test',
        'phone': '01700000000',
      };

      final result = EmergencyContact.fromMap(minimalMap);

      expect(result.name, 'Test');
      expect(result.phone, '01700000000');
      expect(result.relationship, isNull);
      expect(result.isPrimary, false);
      expect(result.createdAt, isNull);
      expect(result.id, isNull);
    });

    test('toMap and fromMap are reversible', () {
      final map = contact.toMap();
      final restored = EmergencyContact.fromMap(map, id: contact.id);

      expect(restored.name, contact.name);
      expect(restored.phone, contact.phone);
      expect(restored.relationship, contact.relationship);
      expect(restored.isPrimary, contact.isPrimary);
    });

    test('copyWith creates modified copy preserving unchanged fields', () {
      final modified = contact.copyWith(
        name: 'Dad',
        isPrimary: false,
      );

      expect(modified.name, 'Dad');
      expect(modified.phone, '+8801712345678'); // unchanged
      expect(modified.relationship, 'Mother'); // unchanged
      expect(modified.isPrimary, false);
      expect(modified.id, '123'); // unchanged
    });

    test('copyWith with no args returns identical values', () {
      final copy = contact.copyWith();

      expect(copy.name, contact.name);
      expect(copy.phone, contact.phone);
      expect(copy.relationship, contact.relationship);
      expect(copy.isPrimary, contact.isPrimary);
    });

    test('equatable compares by value (id, name, phone, relationship, isPrimary)', () {
      const same = EmergencyContact(
        id: '123',
        name: 'Mom',
        phone: '+8801712345678',
        relationship: 'Mother',
        isPrimary: true,
      );

      const different = EmergencyContact(
        id: '999',
        name: 'Mom',
        phone: '+8801712345678',
        relationship: 'Mother',
        isPrimary: true,
      );

      expect(contact, equals(same));
      expect(contact, isNot(equals(different)));
    });

    test('phone number with country code preserves format', () {
      const bd = EmergencyContact(
        name: 'Test',
        phone: '+880-171-234-5678',
      );

      expect(bd.phone, '+880-171-234-5678');

      final map = bd.toMap();
      final restored = EmergencyContact.fromMap(map);
      expect(restored.phone, '+880-171-234-5678');
    });
  });
}
