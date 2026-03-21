import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora_sos/core/services/audio_service.dart';
import 'package:safora_sos/data/repositories/contacts_repository.dart';
import 'package:safora_sos/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora_sos/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora_sos/presentation/blocs/sos/sos_state.dart';

class MockAudioService extends Mock implements AudioService {}

class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late SosCubit cubit;
  late MockAudioService mockAudio;
  late MockTriggerSosUseCase mockUseCase;
  late MockContactsRepository mockContacts;

  setUp(() {
    mockAudio = MockAudioService();
    mockUseCase = MockTriggerSosUseCase();
    mockContacts = MockContactsRepository();

    when(() => mockAudio.playSiren()).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockUseCase.cancel()).thenAnswer((_) async {});
    when(() => mockContacts.getAll()).thenReturn([]);
    when(
      () => mockUseCase.execute(
        contacts: any(named: 'contacts'),
        userName: any(named: 'userName'),
      ),
    ).thenAnswer(
      (_) async => const SosResult(
        smsSentCount: 0,
        totalContacts: 0,
        hasLocation: false,
      ),
    );

    cubit = SosCubit(
      audioService: mockAudio,
      triggerSosUseCase: mockUseCase,
      contactsRepository: mockContacts,
    );
  });

  tearDown(() => cubit.close());

  group('SosCubit', () {
    test('initial state is SosIdle', () {
      expect(cubit.state, const SosIdle());
    });

    test('startCountdown emits SosCountdown', () async {
      cubit.startCountdown();

      // Allow stream to emit.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<SosCountdown>());
    });

    test('cancelCountdown returns to idle', () async {
      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      cubit.cancelCountdown();
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(cubit.state, const SosIdle());
    });

    test('deactivateSos stops audio and returns to idle', () async {
      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      await cubit.deactivateSos();

      expect(cubit.state, const SosIdle());
      verify(() => mockAudio.stopAll()).called(1);
      verify(() => mockUseCase.cancel()).called(1);
    });

    test('startCountdown is ignored if already counting (double-tap protection)', () async {
      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      // Try to start again while counting.
      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      // Should still be in countdown, not restarted.
      expect(cubit.state, isA<SosCountdown>());
    });

    test('countdown progress decreases each tick', () async {
      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      final initial = cubit.state as SosCountdown;
      expect(initial.secondsRemaining, 30);
      expect(initial.progress, 1.0);

      // Wait for 2 ticks.
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 200));

      final after2 = cubit.state as SosCountdown;
      expect(after2.secondsRemaining, lessThan(30));
      expect(after2.progress, lessThan(1.0));
    });

    test('cancelCountdown emits SosCancelled then returns to SosIdle', () async {
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      cubit.cancelCountdown();
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(states.any((s) => s is SosCancelled), true);
      expect(cubit.state, const SosIdle());

      await sub.cancel();
    });
  });
}
