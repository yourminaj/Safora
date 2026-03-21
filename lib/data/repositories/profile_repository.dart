import '../models/user_profile.dart';
import '../datasources/profile_local_datasource.dart';

/// Abstract repository for user medical profile.
abstract class ProfileRepository {
  UserProfile? load();
  Future<void> save(UserProfile profile);
  Future<void> clear();
  bool get hasProfile;
}

/// Hive-backed implementation.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource);

  final ProfileLocalDataSource _dataSource;

  @override
  UserProfile? load() => _dataSource.load();

  @override
  Future<void> save(UserProfile profile) => _dataSource.save(profile);

  @override
  Future<void> clear() => _dataSource.clear();

  @override
  bool get hasProfile => _dataSource.hasProfile;
}
