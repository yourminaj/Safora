import '../models/medicine_reminder.dart';
import '../datasources/reminders_local_datasource.dart';

/// Abstract repository contract for medicine reminders.
abstract class RemindersRepository {
  List<MedicineReminder> getAll();
  List<MedicineReminder> getActive();
  Future<String> add(MedicineReminder reminder);
  Future<void> update(MedicineReminder reminder);
  Future<void> delete(String id);
  Future<void> toggleActive(String id);
  Future<void> clear();
  int get count;
}

/// Hive-backed implementation of [RemindersRepository].
class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl(this._localDataSource);

  final RemindersLocalDataSource _localDataSource;

  @override
  List<MedicineReminder> getAll() => _localDataSource.getAll();

  @override
  List<MedicineReminder> getActive() => _localDataSource.getActive();

  @override
  Future<String> add(MedicineReminder reminder) =>
      _localDataSource.add(reminder);

  @override
  Future<void> update(MedicineReminder reminder) =>
      _localDataSource.update(reminder);

  @override
  Future<void> delete(String id) => _localDataSource.delete(id);

  @override
  Future<void> toggleActive(String id) => _localDataSource.toggleActive(id);

  @override
  Future<void> clear() => _localDataSource.clear();

  @override
  int get count => _localDataSource.count;
}
