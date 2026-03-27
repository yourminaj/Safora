import 'package:hive/hive.dart';
import '../../core/constants/alert_types.dart';

/// Persisted alert preferences — tracks which alerts are enabled/disabled.
///
/// Stored in a Hive box. Key = [AlertType.name], value = bool (enabled).
/// Default: all free alerts enabled, all premium alerts disabled.
class AlertPreferences {
  AlertPreferences(this._box);

  static const String boxName = 'alert_preferences';

  final Box _box;

  /// Check if a specific alert type is enabled.
  ///
  /// Defaults: free alerts → enabled, premium → disabled.
  bool isEnabled(AlertType type) {
    return _box.get(type.name, defaultValue: type.isFree) as bool;
  }

  /// Enable or disable a specific alert type.
  Future<void> setEnabled(AlertType type, bool enabled) async {
    await _box.put(type.name, enabled);
  }

  /// Toggle a specific alert type.
  Future<bool> toggle(AlertType type) async {
    final newValue = !isEnabled(type);
    await setEnabled(type, newValue);
    return newValue;
  }

  /// Get all currently enabled alert types.
  Set<AlertType> get enabledAlerts {
    return AlertType.values.where(isEnabled).toSet();
  }

  /// Get all currently disabled alert types.
  Set<AlertType> get disabledAlerts {
    return AlertType.values.where((t) => !isEnabled(t)).toSet();
  }

  /// Enable all alerts in a category.
  Future<void> enableCategory(AlertCategory category) async {
    for (final type in AlertType.values) {
      if (type.category == category) {
        await setEnabled(type, true);
      }
    }
  }

  /// Disable all alerts in a category.
  Future<void> disableCategory(AlertCategory category) async {
    for (final type in AlertType.values) {
      if (type.category == category) {
        await setEnabled(type, false);
      }
    }
  }

  /// Group all alert types by category with their enabled status.
  Map<AlertCategory, List<AlertTypeStatus>> groupedByCategory() {
    final map = <AlertCategory, List<AlertTypeStatus>>{};
    for (final type in AlertType.values) {
      final list = map.putIfAbsent(type.category, () => []);
      list.add(AlertTypeStatus(type: type, enabled: isEnabled(type)));
    }
    return map;
  }

  /// Count of enabled alerts per category.
  Map<AlertCategory, int> enabledCountByCategory() {
    final map = <AlertCategory, int>{};
    for (final type in AlertType.values) {
      if (isEnabled(type)) {
        map[type.category] = (map[type.category] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Total counts.
  int get totalEnabled => enabledAlerts.length;
  int get totalAlerts => AlertType.values.length;
}

/// Status wrapper for display in UI.
class AlertTypeStatus {
  const AlertTypeStatus({required this.type, required this.enabled});

  final AlertType type;
  final bool enabled;
}
