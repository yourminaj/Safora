import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/premium_manager.dart';
import 'package:safora/data/datasources/contacts_local_datasource.dart';
import 'package:safora/data/models/emergency_contact.dart';

class MockBox extends Mock implements Box {}
class MockPremiumManager extends Mock implements PremiumManager {}

void main() {
  late MockBox mockBox;
  late MockPremiumManager mockPremiumManager;
  late ContactsLocalDataSource datasource;

  setUp(() {
    mockBox = MockBox();
    mockPremiumManager = MockPremiumManager();
    // Stub the contact limit; free tier allows 3 contacts.
    when(() => mockPremiumManager.contactLimit).thenReturn(3);
    datasource = ContactsLocalDataSource(mockBox, mockPremiumManager);
  });

  group('ContactsLocalDataSource', () {
    test('getAll returns empty list when box is empty', () {
      when(() => mockBox.length).thenReturn(0);
      expect(datasource.getAll(), isEmpty);
    });

    test('count returns box length', () {
      when(() => mockBox.length).thenReturn(2);
      expect(datasource.count, 2);
    });

    test('isLimitReached returns true at max', () {
      when(() => mockBox.length)
          .thenReturn(datasource.maxFreeContacts);
      expect(datasource.isLimitReached, true);
    });

    test('isLimitReached returns false below max', () {
      when(() => mockBox.length).thenReturn(1);
      expect(datasource.isLimitReached, false);
    });

    test('add throws ContactLimitException when limit reached', () {
      when(() => mockBox.length)
          .thenReturn(datasource.maxFreeContacts);
      const contact = EmergencyContact(
        name: 'Test',
        phone: '+1234567890',
        relationship: 'Friend',
      );
      expect(
        () => datasource.add(contact),
        throwsA(isA<ContactLimitException>()),
      );
    });

    test('add stores contact and returns ID when under limit', () async {
      when(() => mockBox.length).thenReturn(1);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      const contact = EmergencyContact(
        name: 'Jane',
        phone: '+9876543210',
        relationship: 'Sister',
      );
      final id = await datasource.add(contact);
      expect(id, isNotEmpty);
      verify(() => mockBox.put(id, any())).called(1);
    });

    test('update throws ArgumentError if contact has no ID', () {
      const contact = EmergencyContact(
        name: 'No ID',
        phone: '+1234567890',
        relationship: 'Friend',
      );
      expect(() => datasource.update(contact), throwsArgumentError);
    });

    test('update stores contact by ID', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      const contact = EmergencyContact(
        id: 'abc123',
        name: 'Updated',
        phone: '+1234567890',
        relationship: 'Friend',
      );
      await datasource.update(contact);
      verify(() => mockBox.put('abc123', any())).called(1);
    });

    test('delete removes contact by ID', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      await datasource.delete('id1');
      verify(() => mockBox.delete('id1')).called(1);
    });

    test('getById returns null for missing ID', () {
      when(() => mockBox.get('missing')).thenReturn(null);
      expect(datasource.getById('missing'), isNull);
    });

    test('getById returns contact for existing ID', () {
      when(() => mockBox.get('id1')).thenReturn({
        '_id': 'id1',
        'name': 'Alice',
        'phone': '+111',
        'relationship': 'Mom',
        'isPrimary': false,
      });
      final contact = datasource.getById('id1');
      expect(contact, isNotNull);
      expect(contact!.name, 'Alice');
      expect(contact.phone, '+111');
    });

    test('getAll sorts primary first', () {
      when(() => mockBox.length).thenReturn(2);
      when(() => mockBox.getAt(0)).thenReturn({
        '_id': 'id1',
        'name': 'B',
        'phone': '+111',
        'relationship': 'Friend',
        'isPrimary': false,
      });
      when(() => mockBox.getAt(1)).thenReturn({
        '_id': 'id2',
        'name': 'A',
        'phone': '+222',
        'relationship': 'Mom',
        'isPrimary': true,
      });
      final contacts = datasource.getAll();
      expect(contacts.length, 2);
      expect(contacts.first.isPrimary, true);
      expect(contacts.first.name, 'A');
    });
  });
}
