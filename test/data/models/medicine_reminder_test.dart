import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/models/medicine_reminder.dart';

void main() {
  group('MedicineReminder', () {
    const reminder = MedicineReminder(
      id: '123',
      name: 'Aspirin',
      dosage: '500mg',
      timeOfDay: '08:30',
      frequency: ReminderFrequency.daily,
      notes: 'Take with food',
      isActive: true,
    );

    test('toMap serializes all fields correctly', () {
      final map = reminder.toMap();

      expect(map['name'], 'Aspirin');
      expect(map['dosage'], '500mg');
      expect(map['timeOfDay'], '08:30');
      expect(map['frequency'], 'daily');
      expect(map['notes'], 'Take with food');
      expect(map['isActive'], true);
    });

    test('fromMap deserializes all fields correctly', () {
      final map = {
        'name': 'Ibuprofen',
        'dosage': '200mg',
        'timeOfDay': '14:00',
        'frequency': 'twiceDaily',
        'notes': 'After meals',
        'isActive': false,
        'createdAt': '2026-03-21T10:00:00.000',
      };

      final result = MedicineReminder.fromMap(map, id: '456');

      expect(result.id, '456');
      expect(result.name, 'Ibuprofen');
      expect(result.dosage, '200mg');
      expect(result.timeOfDay, '14:00');
      expect(result.frequency, ReminderFrequency.twiceDaily);
      expect(result.notes, 'After meals');
      expect(result.isActive, false);
      expect(result.createdAt, isNotNull);
    });

    test('fromMap handles missing optional fields', () {
      final minimalMap = {
        'name': 'Vitamin',
        'dosage': '1 tablet',
      };

      final result = MedicineReminder.fromMap(minimalMap);

      expect(result.name, 'Vitamin');
      expect(result.dosage, '1 tablet');
      expect(result.timeOfDay, '08:00'); // Default
      expect(result.frequency, ReminderFrequency.daily); // Default
      expect(result.notes, isNull);
      expect(result.isActive, true); // Default
    });

    test('toMap and fromMap are reversible', () {
      final map = reminder.toMap();
      final restored = MedicineReminder.fromMap(map, id: reminder.id);

      expect(restored.name, reminder.name);
      expect(restored.dosage, reminder.dosage);
      expect(restored.timeOfDay, reminder.timeOfDay);
      expect(restored.frequency, reminder.frequency);
      expect(restored.notes, reminder.notes);
      expect(restored.isActive, reminder.isActive);
    });

    test('copyWith creates modified copy', () {
      final modified = reminder.copyWith(
        name: 'Paracetamol',
        dosage: '1g',
        isActive: false,
      );

      expect(modified.name, 'Paracetamol');
      expect(modified.dosage, '1g');
      expect(modified.isActive, false);
      expect(modified.timeOfDay, '08:30'); // Unchanged
      expect(modified.notes, 'Take with food'); // Unchanged
    });

    test('timeParts parses hour and minute', () {
      expect(reminder.timeParts.hour, 8);
      expect(reminder.timeParts.minute, 30);
    });

    test('timeParts handles edge cases', () {
      const midnight = MedicineReminder(
        name: 'Test',
        dosage: 'Test',
        timeOfDay: '00:00',
      );
      expect(midnight.timeParts.hour, 0);
      expect(midnight.timeParts.minute, 0);

      const endOfDay = MedicineReminder(
        name: 'Test',
        dosage: 'Test',
        timeOfDay: '23:59',
      );
      expect(endOfDay.timeParts.hour, 23);
      expect(endOfDay.timeParts.minute, 59);
    });

    test('ReminderFrequency displayName is correct', () {
      expect(ReminderFrequency.daily.displayName, 'Once daily');
      expect(ReminderFrequency.twiceDaily.displayName, 'Twice daily');
      expect(ReminderFrequency.weekly.displayName, 'Weekly');
      expect(ReminderFrequency.asNeeded.displayName, 'As needed');
    });

    test('equatable compares by value', () {
      const same = MedicineReminder(
        id: '123',
        name: 'Aspirin',
        dosage: '500mg',
        timeOfDay: '08:30',
        frequency: ReminderFrequency.daily,
        notes: 'Take with food',
        isActive: true,
      );

      const different = MedicineReminder(
        id: '999',
        name: 'Aspirin',
        dosage: '500mg',
        timeOfDay: '08:30',
      );

      expect(reminder, equals(same));
      expect(reminder, isNot(equals(different)));
    });

    test('fromMap with unknown frequency defaults to daily', () {
      final map = {
        'name': 'Test',
        'dosage': 'Test',
        'frequency': 'unknownFrequency',
      };

      final result = MedicineReminder.fromMap(map);
      expect(result.frequency, ReminderFrequency.daily);
    });
  });
}
