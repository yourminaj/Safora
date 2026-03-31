import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Function signature for creating a one-shot [Timer].
/// Injected via constructor to allow [fakeAsync] control in tests.
typedef TimerFactory = Timer Function(Duration duration, void Function() callback);

/// Dead Man's Switch — periodic check-in timer.
///
/// If the user doesn't confirm they're safe within the [checkInInterval],
/// the service triggers an automatic emergency alert with SOS to
/// pre-configured contacts.
///
/// Usage:
/// ```dart
/// final dms = DeadManSwitchService(
///   onTrigger: () => sendSOSToContacts(),
///   checkInInterval: Duration(minutes: 30),
/// );
/// dms.start();
/// // User taps "I'm Safe" button:
/// dms.checkIn();
/// ```
class DeadManSwitchService {
  DeadManSwitchService({
    required this.onTrigger,
    this.checkInInterval = const Duration(minutes: 30),
    this.warningBeforeSeconds = 60,
    required Box settingsBox,
    TimerFactory? createTimer,
  })  : _settingsBox = settingsBox,
        _createTimer = createTimer ?? Timer.new;

  /// Persistence key for the next check-in deadline.
  static const String _deadlineKey = 'dms_next_deadline';

  /// Callback fired when the user fails to check in.
  final VoidCallback onTrigger;

  /// How often the user must check in (mutable for runtime updates).
  Duration checkInInterval;

  /// Seconds before deadline to fire a warning.
  final int warningBeforeSeconds;

  final Box _settingsBox;
  final TimerFactory _createTimer;

  Timer? _mainTimer;
  Timer? _warningTimer;
  DateTime? _nextDeadline;
  bool _isActive = false;

  /// Stream controller for warning notifications.
  final _warningController = StreamController<Duration>.broadcast();

  /// Emits the remaining time when a warning fires.
  Stream<Duration> get warningStream => _warningController.stream;

  /// Whether the dead man's switch is currently active.
  bool get isActive => _isActive;

  /// When the next check-in is due (null if inactive).
  DateTime? get nextDeadline => _nextDeadline;

  /// Remaining time until deadline.
  Duration? get remainingTime {
    if (_nextDeadline == null) return null;
    final remaining = _nextDeadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start the dead man's switch. Resets the timer if already running.
  void start() {
    stop();
    _isActive = true;
    _resetTimer(persist: true);
  }

  /// RESTORE the dead man's switch from a persisted deadline.
  /// Used during re-hydration if the app was killed.
  void restore(DateTime deadline) {
    stop();
    _isActive = true;
    _nextDeadline = deadline;

    final remaining = _nextDeadline!.difference(DateTime.now());
    if (remaining.isNegative) {
      _onDeadlineReached();
      return;
    }

    _mainTimer = _createTimer(remaining, _onDeadlineReached);

    final warningDelay =
        remaining - Duration(seconds: warningBeforeSeconds);
    if (warningDelay > Duration.zero) {
      _warningTimer = _createTimer(warningDelay, _onWarning);
    }
  }

  /// Start with a custom interval. Updates [checkInInterval] then starts.
  void startWithInterval(Duration interval) {
    checkInInterval = interval;
    start();
  }

  /// User confirms they are safe. Resets the countdown.
  void checkIn() {
    if (!_isActive) return;
    _resetTimer(persist: true);
  }

  /// Stop the dead man's switch completely.
  void stop() {
    _isActive = false;
    _mainTimer?.cancel();
    _warningTimer?.cancel();
    _mainTimer = null;
    _warningTimer = null;
    _nextDeadline = null;
    _settingsBox.delete(_deadlineKey);
  }

  /// Clean up resources.
  void dispose() {
    stop();
    _warningController.close();
  }

  void _resetTimer({bool persist = false}) {
    _mainTimer?.cancel();
    _warningTimer?.cancel();

    _nextDeadline = DateTime.now().add(checkInInterval);
    if (persist) {
      _settingsBox.put(_deadlineKey, _nextDeadline!.toIso8601String());
    }

    _mainTimer = _createTimer(checkInInterval, _onDeadlineReached);

    final warningDelay =
        checkInInterval - Duration(seconds: warningBeforeSeconds);
    if (warningDelay > Duration.zero) {
      _warningTimer = _createTimer(warningDelay, _onWarning);
    }
  }

  void _onWarning() {
    final remaining = remainingTime ?? Duration.zero;
    _warningController.add(remaining);
  }

  void _onDeadlineReached() {
    _isActive = false;
    onTrigger();
  }

  /// Evaluates the deadline based on persisted data.
  /// Designed to be called continuously from a background foreground service ticker
  /// (e.g., flutter_foreground_task) to trigger SOS exactly when time expires,
  /// even if the app's main timers were suspended by OS Doze mode.
  void evaluateBackground() {
    final deadlineStr = _settingsBox.get(_deadlineKey);
    if (deadlineStr == null) return;

    final deadline = DateTime.parse(deadlineStr);
    
    // Check if we should fire warning notification
    final remaining = deadline.difference(DateTime.now());
    if (remaining.inSeconds > 0 && remaining.inSeconds <= warningBeforeSeconds) {
       // We could show a background local notification here, but often the 
       // periodic ticker is enough to just trigger the final SOS.
    }

    if (remaining.isNegative) {
      // Time expired! Stop switch and trigger SOS.
      stop();
      onTrigger();
    }
  }
}
