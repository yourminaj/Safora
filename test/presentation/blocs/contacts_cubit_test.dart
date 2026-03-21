import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora_sos/data/datasources/contacts_local_datasource.dart';
import 'package:safora_sos/data/models/emergency_contact.dart';
import 'package:safora_sos/data/repositories/contacts_repository.dart';
import 'package:safora_sos/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:safora_sos/presentation/blocs/contacts/contacts_state.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late ContactsCubit cubit;
  late MockContactsRepository mockRepo;

  final testContacts = [
    const EmergencyContact(
      id: '1',
      name: 'Mom',
      phone: '+8801712345678',
      relationship: 'Mother',
      isPrimary: true,
      createdAt: null,
    ),
    const EmergencyContact(
      id: '2',
      name: 'Brother',
      phone: '+8801787654321',
      relationship: 'Brother',
    ),
  ];

  setUp(() {
    mockRepo = MockContactsRepository();
    cubit = ContactsCubit(mockRepo);

    // Default stubs.
    when(() => mockRepo.getAll()).thenReturn(testContacts);
    when(() => mockRepo.isLimitReached).thenReturn(false);
    when(() => mockRepo.count).thenReturn(2);
  });

  setUpAll(() {
    registerFallbackValue(const EmergencyContact(
      name: 'fallback',
      phone: '000',
    ));
  });

  tearDown(() => cubit.close());

  group('ContactsCubit', () {
    test('initial state is ContactsInitial', () {
      expect(cubit.state, const ContactsInitial());
    });

    test('loadContacts emits ContactsLoaded with real contacts', () async {
      final states = <ContactsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadContacts();
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is ContactsLoading), true);
      expect(states.last, isA<ContactsLoaded>());

      final loaded = states.last as ContactsLoaded;
      expect(loaded.contacts.length, 2);
      expect(loaded.contacts.first.name, 'Mom');
      expect(loaded.contacts.first.isPrimary, true);
      expect(loaded.isLimitReached, false);

      await sub.cancel();
    });

    test('addContact delegates to repository and reloads', () async {
      when(() => mockRepo.add(any())).thenAnswer((_) async => '3');

      await cubit.addContact(
        name: 'Sister',
        phone: '+8801711111111',
        relationship: 'Sister',
      );

      verify(() => mockRepo.add(any())).called(1);
      // Should call loadContacts after add.
      verify(() => mockRepo.getAll()).called(1);
    });

    test('addContact emits ContactsLimitReached when limit exceeded', () async {
      when(() => mockRepo.add(any()))
          .thenThrow(ContactLimitException('Max 3 contacts'));

      final states = <ContactsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.addContact(name: 'Extra', phone: '+880170000000');
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ContactsLimitReached>());

      await sub.cancel();
    });

    test('deleteContact removes contact and reloads', () async {
      when(() => mockRepo.delete('2')).thenAnswer((_) async {});

      await cubit.deleteContact('2');

      verify(() => mockRepo.delete('2')).called(1);
      verify(() => mockRepo.getAll()).called(1);
    });

    test('updateContact delegates to repository', () async {
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      final updated = testContacts.first.copyWith(name: 'Updated Mom');
      await cubit.updateContact(updated);

      verify(() => mockRepo.update(updated)).called(1);
    });

    test('setPrimary sets correct contact as primary', () async {
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      await cubit.setPrimary('2');

      // Should update contact '2' to isPrimary=true and contact '1' to isPrimary=false.
      verify(() => mockRepo.update(any())).called(2);
    });

    test('loadContacts handles errors gracefully', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('Hive error'));

      final states = <ContactsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadContacts();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ContactsError>());
      final error = states.last as ContactsError;
      expect(error.message, contains('Failed to load contacts'));

      await sub.cancel();
    });
  });
}
