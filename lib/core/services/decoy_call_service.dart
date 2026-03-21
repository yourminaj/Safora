import 'audio_service.dart';

/// Service for triggering decoy incoming phone calls.
///
/// A decoy call simulates a realistic incoming phone call to help
/// users discreetly exit uncomfortable or dangerous situations.
/// Uses [AudioService] for ringtone playback and provides
/// configurable caller identity for realistic appearance.
class DecoyCallService {
  DecoyCallService({required AudioService audioService})
      : _audioService = audioService;

  final AudioService _audioService;

  /// Default caller name when none specified.
  static const String defaultCallerName = 'Mom';

  /// Default delay before the call starts (seconds).
  static const int defaultDelaySeconds = 5;

  String _callerName = defaultCallerName;
  int _delaySeconds = defaultDelaySeconds;
  bool _isRinging = false;

  /// Get configured caller name.
  String get callerName => _callerName;

  /// Get configured delay.
  int get delaySeconds => _delaySeconds;

  /// Whether a decoy call is currently ringing.
  bool get isRinging => _isRinging;

  /// Configure the decoy call parameters.
  void configure({String? callerName, int? delaySeconds}) {
    if (callerName != null) _callerName = callerName;
    if (delaySeconds != null) _delaySeconds = delaySeconds;
  }

  /// Start the decoy call ringtone.
  Future<void> startRinging() async {
    _isRinging = true;
    // Play a realistic phone ringtone, NOT the emergency siren.
    await _audioService.playRingtone();
  }

  /// Stop the ringtone (when call is answered or declined).
  Future<void> stopRinging() async {
    _isRinging = false;
    await _audioService.stopRingtone();
  }

  /// Reset to defaults.
  void reset() {
    _callerName = defaultCallerName;
    _delaySeconds = defaultDelaySeconds;
    _isRinging = false;
  }
}
