import 'package:hive/hive.dart';
import '../models/sos_history_entry.dart';

/// Local data source for SOS activation history.
///
/// Stores each SOS event with timestamp, location, contacts notified,
/// and result (success/partial/failure).
class SosHistoryDatasource {
  SosHistoryDatasource(this._box);

  final Box _box;

  static const String boxName = 'sos_history';
  static const int maxEntries = 100;

  /// Add a new SOS history entry.
  Future<void> add(SosHistoryEntry entry) async {
    await _box.add(entry.toMap());
    // Trim old entries if we exceed the limit.
    if (_box.length > maxEntries) {
      await _box.deleteAt(0);
    }
  }

  /// Get all SOS history entries, most recent first.
  List<SosHistoryEntry> getAll() {
    final entries = <SosHistoryEntry>[];
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw != null) {
        entries.add(SosHistoryEntry.fromMap(
          Map<String, dynamic>.from(raw as Map),
        ));
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  /// Get the N most recent entries.
  List<SosHistoryEntry> getRecent({int limit = 10}) {
    return getAll().take(limit).toList();
  }

  /// Total SOS activations count.
  int get count => _box.length;

  /// Clear all history.
  Future<void> clear() async => _box.clear();
}
