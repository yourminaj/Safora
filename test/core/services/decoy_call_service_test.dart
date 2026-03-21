import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora_sos/core/services/audio_service.dart';
import 'package:safora_sos/core/services/decoy_call_service.dart';

class MockAudioService extends Mock implements AudioService {}

void main() {
  late DecoyCallService service;
  late MockAudioService mockAudio;

  setUp(() {
    mockAudio = MockAudioService();
    service = DecoyCallService(audioService: mockAudio);

    // Stub default behaviors for ringtone (not siren).
    when(() => mockAudio.playRingtone()).thenAnswer((_) async {});
    when(() => mockAudio.stopRingtone()).thenAnswer((_) async {});
  });

  group('DecoyCallService', () {
    test('has correct defaults', () {
      expect(service.callerName, 'Mom');
      expect(service.delaySeconds, 5);
      expect(service.isRinging, false);
    });

    test('configure updates callerName and delay', () {
      service.configure(callerName: 'Dad', delaySeconds: 10);

      expect(service.callerName, 'Dad');
      expect(service.delaySeconds, 10);
    });

    test('configure with null does not change values', () {
      service.configure(callerName: 'Sister');
      service.configure(); // no args

      expect(service.callerName, 'Sister');
      expect(service.delaySeconds, 5);
    });

    test('startRinging sets isRinging and calls playRingtone', () async {
      await service.startRinging();

      expect(service.isRinging, true);
      verify(() => mockAudio.playRingtone()).called(1);
    });

    test('stopRinging resets isRinging and calls stopRingtone', () async {
      await service.startRinging();
      await service.stopRinging();

      expect(service.isRinging, false);
      verify(() => mockAudio.stopRingtone()).called(1);
    });

    test('reset restores all defaults', () async {
      service.configure(callerName: 'Boss', delaySeconds: 15);
      await service.startRinging();

      service.reset();

      expect(service.callerName, 'Mom');
      expect(service.delaySeconds, 5);
      expect(service.isRinging, false);
    });

    test('multiple startRinging calls play ringtone each time', () async {
      await service.startRinging();
      await service.startRinging();

      verify(() => mockAudio.playRingtone()).called(2);
    });
  });
}
