import '../models/emergency_contact.dart';
import '../datasources/contacts_local_datasource.dart';

/// Abstract repository contract for emergency contacts.
abstract class ContactsRepository {
  List<EmergencyContact> getAll();
  Future<String> add(EmergencyContact contact);
  Future<void> update(EmergencyContact contact);
  Future<void> delete(String id);
  EmergencyContact? getById(String id);
  bool get isLimitReached;
  int get count;
}

/// Hive-backed implementation of [ContactsRepository].
class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this._localDataSource);

  final ContactsLocalDataSource _localDataSource;

  @override
  List<EmergencyContact> getAll() => _localDataSource.getAll();

  @override
  Future<String> add(EmergencyContact contact) =>
      _localDataSource.add(contact);

  @override
  Future<void> update(EmergencyContact contact) =>
      _localDataSource.update(contact);

  @override
  Future<void> delete(String id) => _localDataSource.delete(id);

  @override
  EmergencyContact? getById(String id) => _localDataSource.getById(id);

  @override
  bool get isLimitReached => _localDataSource.isLimitReached;

  @override
  int get count => _localDataSource.count;
}
