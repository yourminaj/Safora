import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/datasources/contacts_local_datasource.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/repositories/contacts_repository.dart';

class MockContactsLocalDataSource extends Mock
    implements ContactsLocalDataSource {}

void main() {
  late MockContactsLocalDataSource mockDataSource;
  late ContactsRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockContactsLocalDataSource();
    repository = ContactsRepositoryImpl(mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(const EmergencyContact(
      name: 'Fallback',
      phone: '+000',
      relationship: 'Other',
    ));
  });

  group('ContactsRepositoryImpl', () {
    test('getAll delegates to data source', () {
      final contacts = [
        const EmergencyContact(
          id: 'id1',
          name: 'Alice',
          phone: '+111',
          relationship: 'Friend',
        ),
      ];
      when(() => mockDataSource.getAll()).thenReturn(contacts);

      final result = repository.getAll();
      expect(result, contacts);
      verify(() => mockDataSource.getAll()).called(1);
    });

    test('add delegates to data source and returns ID', () async {
      const contact = EmergencyContact(
        name: 'Bob',
        phone: '+222',
        relationship: 'Brother',
      );
      when(() => mockDataSource.add(any())).thenAnswer((_) async => 'new-id');

      final id = await repository.add(contact);
      expect(id, 'new-id');
      verify(() => mockDataSource.add(contact)).called(1);
    });

    test('update delegates to data source', () async {
      const contact = EmergencyContact(
        id: 'id1',
        name: 'Updated',
        phone: '+111',
        relationship: 'Friend',
      );
      when(() => mockDataSource.update(any())).thenAnswer((_) async {});

      await repository.update(contact);
      verify(() => mockDataSource.update(contact)).called(1);
    });

    test('delete delegates to data source', () async {
      when(() => mockDataSource.delete(any())).thenAnswer((_) async {});

      await repository.delete('id1');
      verify(() => mockDataSource.delete('id1')).called(1);
    });

    test('getById delegates to data source', () {
      const contact = EmergencyContact(
        id: 'id1',
        name: 'Carol',
        phone: '+333',
        relationship: 'Sister',
      );
      when(() => mockDataSource.getById('id1')).thenReturn(contact);

      final result = repository.getById('id1');
      expect(result, contact);
      expect(result!.name, 'Carol');
    });

    test('getById returns null for missing ID', () {
      when(() => mockDataSource.getById('missing')).thenReturn(null);
      expect(repository.getById('missing'), isNull);
    });

    test('isLimitReached delegates to data source', () {
      when(() => mockDataSource.isLimitReached).thenReturn(true);
      expect(repository.isLimitReached, true);
    });

    test('count delegates to data source', () {
      when(() => mockDataSource.count).thenReturn(5);
      expect(repository.count, 5);
    });
  });
}
