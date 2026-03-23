import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/datasources/reminders_local_datasource.dart';
import 'package:safora/data/models/medicine_reminder.dart';
import 'package:safora/data/repositories/reminders_repository.dart';

class MockRemindersLocalDataSource extends Mock
    implements RemindersLocalDataSource {}

void main() {
  late RemindersRepositoryImpl repository;
  late MockRemindersLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockRemindersLocalDataSource();
    repository = RemindersRepositoryImpl(mockDataSource);
  });

  group('RemindersRepositoryImpl', () {
    test('getAll delegates to data source', () {
      const reminder = MedicineReminder(
        id: 'r1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: '08:00',
      );
      when(() => mockDataSource.getAll()).thenReturn([reminder]);

      final result = repository.getAll();

      expect(result, [reminder]);
      verify(() => mockDataSource.getAll()).called(1);
    });

    test('getActive delegates to data source', () {
      when(() => mockDataSource.getActive()).thenReturn([]);

      final result = repository.getActive();

      expect(result, isEmpty);
      verify(() => mockDataSource.getActive()).called(1);
    });

    test('add delegates to data source and returns ID', () async {
      const reminder = MedicineReminder(
        name: 'Metformin',
        dosage: '500mg',
        timeOfDay: '09:00',
      );
      when(() => mockDataSource.add(reminder))
          .thenAnswer((_) async => 'generated-id');

      final id = await repository.add(reminder);

      expect(id, 'generated-id');
      verify(() => mockDataSource.add(reminder)).called(1);
    });

    test('update delegates to data source', () async {
      const reminder = MedicineReminder(
        id: 'r1',
        name: 'Updated',
        dosage: '200mg',
        timeOfDay: '10:00',
      );
      when(() => mockDataSource.update(reminder)).thenAnswer((_) async {});

      await repository.update(reminder);

      verify(() => mockDataSource.update(reminder)).called(1);
    });

    test('delete delegates to data source', () async {
      when(() => mockDataSource.delete('r1')).thenAnswer((_) async {});

      await repository.delete('r1');

      verify(() => mockDataSource.delete('r1')).called(1);
    });

    test('toggleActive delegates to data source', () async {
      when(() => mockDataSource.toggleActive('r1'))
          .thenAnswer((_) async {});

      await repository.toggleActive('r1');

      verify(() => mockDataSource.toggleActive('r1')).called(1);
    });

    test('clear delegates to data source', () async {
      when(() => mockDataSource.clear()).thenAnswer((_) async {});

      await repository.clear();

      verify(() => mockDataSource.clear()).called(1);
    });

    test('count delegates to data source', () {
      when(() => mockDataSource.count).thenReturn(5);

      expect(repository.count, 5);
      verify(() => mockDataSource.count).called(1);
    });

    test('add throws ReminderLimitException when limit reached', () async {
      const reminder = MedicineReminder(
        name: 'Extra',
        dosage: '1',
        timeOfDay: '12:00',
      );
      when(() => mockDataSource.add(reminder)).thenThrow(
        ReminderLimitException('Maximum 20 reminders reached'),
      );

      expect(
        () => repository.add(reminder),
        throwsA(isA<ReminderLimitException>()),
      );
    });
  });
}
