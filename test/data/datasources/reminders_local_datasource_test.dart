import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/premium_manager.dart';
import 'package:safora/data/datasources/reminders_local_datasource.dart';
import 'package:safora/data/models/medicine_reminder.dart';

class MockBox extends Mock implements Box {}
class MockPremiumManager extends Mock implements PremiumManager {}

void main() {
  late MockBox mockBox;
  late MockPremiumManager mockPremiumManager;
  late RemindersLocalDataSource datasource;

  setUp(() {
    mockBox = MockBox();
    mockPremiumManager = MockPremiumManager();
    // Stub the reminder limit; free tier allows 2 reminders.
    when(() => mockPremiumManager.reminderLimit).thenReturn(2);
    datasource = RemindersLocalDataSource(mockBox, mockPremiumManager);
  });

  group('RemindersLocalDataSource', () {
    test('count returns box length', () {
      when(() => mockBox.length).thenReturn(3);
      expect(datasource.count, 3);
    });

    test('getAll returns empty list for empty box', () {
      when(() => mockBox.keys).thenReturn([]);
      final result = datasource.getAll();
      expect(result, isEmpty);
    });

    test('getAll returns sorted reminders', () {
      when(() => mockBox.keys).thenReturn(['r1', 'r2']);
      when(() => mockBox.get('r1')).thenReturn({
        'name': 'Vitamin D',
        'dosage': '1 tablet',
        'timeOfDay': '18:00',
        'frequency': 'daily',
        'isActive': true,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      when(() => mockBox.get('r2')).thenReturn({
        'name': 'Aspirin',
        'dosage': '75mg',
        'timeOfDay': '08:00',
        'frequency': 'daily',
        'isActive': true,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      final result = datasource.getAll();
      expect(result.length, 2);
      expect(result.first.name, 'Aspirin');
      expect(result.last.name, 'Vitamin D');
    });

    test('getActive returns only active reminders', () {
      when(() => mockBox.keys).thenReturn(['r1', 'r2']);
      when(() => mockBox.get('r1')).thenReturn({
        'name': 'Active Med',
        'dosage': '1',
        'timeOfDay': '08:00',
        'frequency': 'daily',
        'isActive': true,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      when(() => mockBox.get('r2')).thenReturn({
        'name': 'Inactive Med',
        'dosage': '1',
        'timeOfDay': '09:00',
        'frequency': 'daily',
        'isActive': false,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      final result = datasource.getActive();
      expect(result.length, 1);
      expect(result.first.name, 'Active Med');
    });

    test('add throws ReminderLimitException when at max', () {
      when(() => mockBox.length)
          .thenReturn(datasource.maxReminders);
      const reminder = MedicineReminder(
        name: 'Test',
        dosage: '1',
        timeOfDay: '08:00',
        frequency: ReminderFrequency.daily,
      );
      expect(
        () => datasource.add(reminder),
        throwsA(isA<ReminderLimitException>()),
      );
    });

    test('add stores reminder when under limit', () async {
      when(() => mockBox.length).thenReturn(1);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      const reminder = MedicineReminder(
        name: 'New Med',
        dosage: '2 tablets',
        timeOfDay: '10:00',
        frequency: ReminderFrequency.daily,
      );
      final id = await datasource.add(reminder);
      expect(id, isNotEmpty);
      verify(() => mockBox.put(id, any())).called(1);
    });

    test('update does nothing when reminder has no ID', () async {
      const reminder = MedicineReminder(
        name: 'No ID',
        dosage: '1',
        timeOfDay: '08:00',
        frequency: ReminderFrequency.daily,
      );
      await datasource.update(reminder);
      verifyNever(() => mockBox.put(any(), any()));
    });

    test('update stores reminder by ID', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      const reminder = MedicineReminder(
        id: 'r1',
        name: 'Updated',
        dosage: '1',
        timeOfDay: '08:00',
        frequency: ReminderFrequency.daily,
      );
      await datasource.update(reminder);
      verify(() => mockBox.put('r1', any())).called(1);
    });

    test('delete removes reminder by ID', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});
      await datasource.delete('r1');
      verify(() => mockBox.delete('r1')).called(1);
    });

    test('clear clears all reminders', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      await datasource.clear();
      verify(() => mockBox.clear()).called(1);
    });

    test('toggleActive flips isActive on existing reminder', () async {
      when(() => mockBox.get('r1')).thenReturn({
        'name': 'Med',
        'dosage': '1',
        'timeOfDay': '08:00',
        'frequency': 'daily',
        'isActive': true,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await datasource.toggleActive('r1');
      final captured =
          verify(() => mockBox.put('r1', captureAny())).captured.single as Map;
      expect(captured['isActive'], false);
    });
  });
}
