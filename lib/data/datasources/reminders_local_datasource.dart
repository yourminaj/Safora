import '../../core/services/app_logger.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine_reminder.dart';

/// Local data source for medicine reminders using Hive.
class RemindersLocalDataSource {
  RemindersLocalDataSource(this._box);

  final Box _box;

  static const String boxName = 'medicine_reminders';
  static const int maxReminders = 20;

  /// Get all reminders, sorted by time of day.
  List<MedicineReminder> getAll() {
    try {
      final reminders = <MedicineReminder>[];
      for (final key in _box.keys) {
        final data = _box.get(key);
        if (data is Map) {
          reminders.add(MedicineReminder.fromMap(data, id: key.toString()));
        }
      }
      reminders.sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
      return reminders;
    } catch (e) {
      AppLogger.warning('[RemindersDS] Error getting reminders: $e');
      return [];
    }
  }

  /// Get only active reminders.
  List<MedicineReminder> getActive() {
    return getAll().where((r) => r.isActive).toList();
  }

  /// Add a new reminder. Returns the generated ID.
  Future<String> add(MedicineReminder reminder) async {
    if (_box.length >= maxReminders) {
      throw ReminderLimitException(
        'Maximum $maxReminders reminders reached',
      );
    }

    final id = const Uuid().v4();
    final withTimestamp = MedicineReminder(
      id: id,
      name: reminder.name,
      dosage: reminder.dosage,
      timeOfDay: reminder.timeOfDay,
      frequency: reminder.frequency,
      notes: reminder.notes,
      isActive: reminder.isActive,
      createdAt: DateTime.now(),
    );

    await _box.put(id, withTimestamp.toMap());
    return id;
  }

  /// Update an existing reminder.
  Future<void> update(MedicineReminder reminder) async {
    if (reminder.id == null) return;
    await _box.put(reminder.id, reminder.toMap());
  }

  /// Delete a reminder by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Toggle a reminder's active state.
  Future<void> toggleActive(String id) async {
    final data = _box.get(id);
    if (data is Map) {
      final reminder = MedicineReminder.fromMap(data, id: id);
      await _box.put(
        id,
        reminder.copyWith(isActive: !reminder.isActive).toMap(),
      );
    }
  }

  /// Clear all reminders.
  Future<void> clear() async {
    await _box.clear();
  }

  int get count => _box.length;
}

/// Exception thrown when the reminder limit is reached.
class ReminderLimitException implements Exception {
  ReminderLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}
