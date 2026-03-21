import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

/// Hive-backed local data source for the user's medical profile.
class ProfileLocalDataSource {
  ProfileLocalDataSource(this._box);

  final Box _box;

  static const String boxName = 'user_profile';
  static const String _profileKey = 'profile';

  /// Load the stored profile, or null if none exists.
  UserProfile? load() {
    final raw = _box.get(_profileKey) as String?;
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Save or update the profile.
  Future<void> save(UserProfile profile) async {
    await _box.put(_profileKey, jsonEncode(profile.toMap()));
  }

  /// Delete the stored profile.
  Future<void> clear() async {
    await _box.delete(_profileKey);
  }

  /// Whether a profile exists.
  bool get hasProfile => _box.containsKey(_profileKey);
}
