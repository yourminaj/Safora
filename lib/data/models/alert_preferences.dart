import 'package:hive/hive.dart';
import '../../core/constants/alert_types.dart';

/// Persisted alert preferences — tracks which alerts are enabled/disabled
/// and the user's minimum severity threshold.
///
/// Stored in a Hive box. Key = [AlertType.name], value = bool (enabled).
/// Default: all free alerts enabled, all premium alerts disabled.
///
/// Severity threshold: stored as `_severity_threshold` key.
/// 0 = info (show everything), 4 = critical (only critical alerts).
class AlertPreferences {
  AlertPreferences(this._box);

  static const String boxName = 'alert_preferences';
  static const String _severityKey = '_severity_threshold';

  final Box _box;

  /// Priority index mapping (higher = more severe).
  static const _priorityIndex = {
    AlertPriority.info: 0,
    AlertPriority.advisory: 1,
    AlertPriority.warning: 2,
    AlertPriority.danger: 3,
    AlertPriority.critical: 4,
  };

  /// Ordered priority list for UI display (low → high).
  static const priorityLevels = [
    AlertPriority.info,
    AlertPriority.advisory,
    AlertPriority.warning,
    AlertPriority.danger,
    AlertPriority.critical,
  ];

  /// Get the current minimum severity threshold.
  /// Default: info (0) — show everything.
  AlertPriority get minimumSeverity {
    final idx = _box.get(_severityKey, defaultValue: 0) as int;
    return priorityLevels[idx.clamp(0, 4)];
  }

  /// Set the minimum severity threshold.
  Future<void> setMinimumSeverity(AlertPriority priority) async {
    await _box.put(_severityKey, _priorityIndex[priority] ?? 0);
  }

  /// Check if an alert's priority meets the severity threshold.
  bool isAllowedBySeverity(AlertPriority priority) {
    final threshold = _priorityIndex[minimumSeverity] ?? 0;
    final alertLevel = _priorityIndex[priority] ?? 0;
    return alertLevel >= threshold;
  }

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

  /// Full filter: alert type must be enabled AND priority must meet threshold.
  bool shouldReceive(AlertType type) {
    return isEnabled(type) && isAllowedBySeverity(type.priority);
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
  /// If the user is on the Free tier, it explicitly avoids enabling Pro-only alerts.
  /// Returns the number of alerts that were newly enabled.
  Future<int> enableCategory(AlertCategory category,
      {required bool isUserPremium}) async {
    int count = 0;
    for (final type in AlertType.values) {
      if (type.category == category) {
        if (!type.isFree && !isUserPremium) continue;
        if (!isEnabled(type)) {
          await setEnabled(type, true);
          count++;
        }
      }
    }
    return count;
  }

  /// Disable all alerts in a category.
  /// Returns the number of alerts that were newly disabled.
  Future<int> disableCategory(AlertCategory category) async {
    int count = 0;
    for (final type in AlertType.values) {
      if (type.category == category) {
        if (isEnabled(type)) {
          await setEnabled(type, false);
          count++;
        }
      }
    }
    return count;
  }

  /// Enable all free alerts.
  /// Returns the number of alerts that were newly enabled.
  Future<int> enableAllFree() async {
    int count = 0;
    for (final type in AlertType.values) {
      if (type.isFree && !isEnabled(type)) {
        await setEnabled(type, true);
        count++;
      }
    }
    return count;
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
