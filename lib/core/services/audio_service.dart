import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../constants/alert_sounds.dart';
import '../constants/alert_types.dart';
import 'app_logger.dart';

/// Service for playing emergency alert sounds.
///
/// Usage:
/// ```dart
/// final audio = AudioService();
/// await audio.playSiren();       // Loop emergency siren
/// await audio.stopAll();         // Stop everything
/// ```
class AudioService {
  AudioService();

  AudioPlayer? _sirenPlayer;
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _alertPlayer;

  bool _isSirenPlaying = false;
  bool _isRingtonePlaying = false;

  /// Whether the siren is currently playing.
  bool get isSirenPlaying => _isSirenPlaying;

  /// Whether the decoy ringtone is currently playing.
  bool get isRingtonePlaying => _isRingtonePlaying;

  /// Play a looping emergency siren sound.
  Future<void> playSiren() async {
    await stopAll();
    _sirenPlayer = AudioPlayer();
    _sirenPlayer!.setReleaseMode(ReleaseMode.loop);

    try {
      await _sirenPlayer!.play(
        AssetSource(AlertSounds.sirenSos),
        volume: 1.0,
      );
      _isSirenPlaying = true;
    } catch (e) {
      // Asset not found — use vibration as fallback so user still gets feedback.
      AppLogger.warning('[AudioService] Siren playback failed: $e');
      _isSirenPlaying = false;
      HapticFeedback.vibrate();
    }
  }

  /// Play a looping phone ringtone for decoy call feature.
  ///
  /// Uses a separate player so it doesn't interfere with the SOS siren.
  Future<void> playRingtone() async {
    await _ringtonePlayer?.stop();
    await _ringtonePlayer?.dispose();
    _ringtonePlayer = AudioPlayer();
    _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);

    try {
      await _ringtonePlayer!.play(
        AssetSource(AlertSounds.phoneRing),
        volume: 1.0,
      );
      _isRingtonePlaying = true;
    } catch (e) {
      AppLogger.warning('[AudioService] Ringtone playback failed: $e');
      _isRingtonePlaying = false;
      // Fallback: vibrate so user still gets tactile feedback.
      HapticFeedback.vibrate();
    }
  }

  /// Stop ringtone playback (when decoy call is answered or declined).
  Future<void> stopRingtone() async {
    _isRingtonePlaying = false;
    await _ringtonePlayer?.stop();
    await _ringtonePlayer?.dispose();
    _ringtonePlayer = null;
  }

  /// Play a one-shot alert sound based on alert type.
  Future<void> playAlertSound(AlertType type) async {
    await _alertPlayer?.stop();
    _alertPlayer = AudioPlayer();

    final soundPath = AlertSounds.forType(type);
    try {
      await _alertPlayer!.play(
        AssetSource(soundPath),
        volume: 0.8,
      );
    } catch (e) {
      // No asset available for this alert type — log and continue.
      AppLogger.warning('[AudioService] Alert sound failed for ${type.name}: $e');
    }
  }

  /// Stop all audio playback.
  Future<void> stopAll() async {
    _isSirenPlaying = false;
    _isRingtonePlaying = false;
    await _sirenPlayer?.stop();
    await _sirenPlayer?.dispose();
    _sirenPlayer = null;

    await _ringtonePlayer?.stop();
    await _ringtonePlayer?.dispose();
    _ringtonePlayer = null;

    await _alertPlayer?.stop();
    await _alertPlayer?.dispose();
    _alertPlayer = null;
  }

  /// Release all resources. Call when the service is no longer needed.
  Future<void> dispose() async {
    await stopAll();
  }
}
