import 'dart:async';
import 'package:flutter/foundation.dart';

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
  });

  /// Callback fired when the user fails to check in.
  final VoidCallback onTrigger;

  /// How often the user must check in (mutable for runtime updates).
  Duration checkInInterval;

  /// Seconds before deadline to fire a warning.
  final int warningBeforeSeconds;

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
    _resetTimer();
  }

  /// Start with a custom interval. Updates [checkInInterval] then starts.
  void startWithInterval(Duration interval) {
    checkInInterval = interval;
    start();
  }

  /// User confirms they are safe. Resets the countdown.
  void checkIn() {
    if (!_isActive) return;
    _resetTimer();
  }

  /// Stop the dead man's switch completely.
  void stop() {
    _isActive = false;
    _mainTimer?.cancel();
    _warningTimer?.cancel();
    _mainTimer = null;
    _warningTimer = null;
    _nextDeadline = null;
  }

  /// Clean up resources.
  void dispose() {
    stop();
    _warningController.close();
  }

  void _resetTimer() {
    _mainTimer?.cancel();
    _warningTimer?.cancel();

    _nextDeadline = DateTime.now().add(checkInInterval);

    // Set main timer — fires the SOS trigger.
    _mainTimer = Timer(checkInInterval, _onDeadlineReached);

    // Set warning timer — fires warningBeforeSeconds before deadline.
    final warningDelay = checkInInterval -
        Duration(seconds: warningBeforeSeconds);
    if (warningDelay > Duration.zero) {
      _warningTimer = Timer(warningDelay, _onWarning);
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
}
