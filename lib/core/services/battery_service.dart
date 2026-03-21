import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

/// Service for monitoring device battery level.
///
/// Emits callbacks when battery level crosses thresholds.
class BatteryService {
  BatteryService() : _battery = Battery();

  final Battery _battery;
  Timer? _pollingTimer;

  /// Battery level thresholds.
  static const int lowThreshold = 15;
  static const int criticalThreshold = 5;

  /// Get the current battery level (0-100).
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1; // Unknown
    }
  }

  /// Get the current battery state (charging, discharging, full, etc.).
  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (_) {
      return BatteryState.unknown;
    }
  }

  /// Start polling battery level every [interval].
  ///
  /// Calls [onLevelChanged] when the level changes.
  void startMonitoring({
    Duration interval = const Duration(minutes: 5),
    required void Function(int level, BatteryState state) onLevelChanged,
  }) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      final level = await getBatteryLevel();
      final state = await getBatteryState();
      onLevelChanged(level, state);
    });

    // Immediately check once (fire-and-forget).
    unawaited(Future(() async {
      final level = await getBatteryLevel();
      final state = await getBatteryState();
      onLevelChanged(level, state);
    }));
  }

  /// Whether the given level is considered low.
  static bool isLow(int level) => level > 0 && level <= lowThreshold;

  /// Whether the given level is considered critical.
  static bool isCritical(int level) => level > 0 && level <= criticalThreshold;

  /// Stop polling.
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    stopMonitoring();
  }
}
