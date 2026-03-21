import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/alert_event.dart';

/// Hive-backed local data source for alert event history.
class AlertsLocalDataSource {
  AlertsLocalDataSource(this._box);

  final Box _box;

  static const String boxName = 'alert_history';

  /// Maximum number of alerts to keep in history.
  static const int maxHistory = 100;

  /// Get all stored alerts, sorted newest first.
  List<AlertEvent> getAll() {
    final entries = <AlertEvent>[];
    for (final key in _box.keys) {
      try {
        final json = jsonDecode(_box.get(key) as String);
        entries.add(AlertEvent.fromMap(
          json as Map<String, dynamic>,
          id: key.toString(),
        ));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Get the most recent [limit] alerts.
  List<AlertEvent> getRecent({int limit = 5}) {
    final all = getAll();
    return all.take(limit).toList();
  }

  /// Save an alert to history (deduplicates by ID).
  Future<void> save(AlertEvent alert) async {
    final key = alert.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(key, jsonEncode(alert.toMap()));

    // Prune old entries if over limit.
    if (_box.length > maxHistory) {
      final all = getAll();
      final toRemove = all.skip(maxHistory);
      for (final old in toRemove) {
        if (old.id != null) await _box.delete(old.id);
      }
    }
  }

  /// Save multiple alerts at once.
  Future<void> saveAll(List<AlertEvent> alerts) async {
    for (final alert in alerts) {
      await save(alert);
    }
  }

  /// Check if an alert with this ID already exists.
  bool exists(String id) => _box.containsKey(id);

  /// Clear all history.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Total number of stored alerts.
  int get count => _box.length;
}
