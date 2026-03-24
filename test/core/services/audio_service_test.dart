import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/audio_service.dart';

/// AudioService tests.
///
/// NOTE: AudioPlayer from the `audioplayers` package requires real platform
/// channels for initialization. Tests that call `playSiren()` or `playRingtone()`
/// may hang in the test environment. We test state management, contract, and
/// safe cleanup here. Platform-dependent playback is validated via integration tests.
void main() {
  group('AudioService', () {
    group('Initial State', () {
      test('can be instantiated', () {
        final service = AudioService();
        expect(service, isNotNull);
      });

      test('isSirenPlaying is false initially', () {
        final service = AudioService();
        expect(service.isSirenPlaying, false);
      });

      test('isRingtonePlaying is false initially', () {
        final service = AudioService();
        expect(service.isRingtonePlaying, false);
      });

      test('both flags are false on fresh instance', () {
        final service = AudioService();
        expect(service.isSirenPlaying, false);
        expect(service.isRingtonePlaying, false);
      });
    });

    group('Stop Operations (Safe When Nothing Playing)', () {
      test('stopAll completes without error', () async {
        final service = AudioService();
        await expectLater(service.stopAll(), completes);
      });

      test('stopAll resets isSirenPlaying to false', () async {
        final service = AudioService();
        await service.stopAll();
        expect(service.isSirenPlaying, false);
      });

      test('stopAll resets isRingtonePlaying to false', () async {
        final service = AudioService();
        await service.stopAll();
        expect(service.isRingtonePlaying, false);
      });

      test('stopRingtone completes without error', () async {
        final service = AudioService();
        await expectLater(service.stopRingtone(), completes);
      });

      test('stopRingtone resets ringtone flag, leaves siren unchanged', () async {
        final service = AudioService();
        await service.stopRingtone();
        expect(service.isRingtonePlaying, false);
        expect(service.isSirenPlaying, false);
      });
    });

    group('Idempotent Stop', () {
      test('stopAll can be called multiple times', () async {
        final service = AudioService();
        await service.stopAll();
        await service.stopAll();
        await service.stopAll();
        expect(service.isSirenPlaying, false);
        expect(service.isRingtonePlaying, false);
      });

      test('stopRingtone can be called multiple times', () async {
        final service = AudioService();
        await service.stopRingtone();
        await service.stopRingtone();
        expect(service.isRingtonePlaying, false);
      });
    });

    group('Dispose', () {
      test('dispose completes without error', () async {
        final service = AudioService();
        await expectLater(service.dispose(), completes);
      });

      test('dispose resets all state', () async {
        final service = AudioService();
        await service.dispose();
        expect(service.isSirenPlaying, false);
        expect(service.isRingtonePlaying, false);
      });

      test('dispose on fresh instance is safe', () async {
        final fresh = AudioService();
        await expectLater(fresh.dispose(), completes);
      });
    });

    group('Multiple Instances', () {
      test('instances are independent', () {
        final a = AudioService();
        final b = AudioService();
        expect(a.isSirenPlaying, false);
        expect(b.isSirenPlaying, false);
        expect(identical(a, b), false);
      });
    });
  });
}
