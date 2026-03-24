import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';

class MockAudioService extends Mock implements AudioService {}

class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SosHistoryEntry(
      timestamp: DateTime(2020),
      contactsNotified: 0,
      smsSentCount: 0,
      wasCancelled: false,
    ));
  });
  late SosCubit cubit;
  late MockAudioService mockAudio;
  late MockTriggerSosUseCase mockUseCase;
  late MockContactsRepository mockContacts;
  late MockSosHistoryDatasource mockHistory;
  late MockLocationService mockLocation;

  setUp(() {
    mockAudio = MockAudioService();
    mockUseCase = MockTriggerSosUseCase();
    mockContacts = MockContactsRepository();
    mockHistory = MockSosHistoryDatasource();
    mockLocation = MockLocationService();

    when(() => mockAudio.playSiren()).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockUseCase.cancel()).thenAnswer((_) async {});
    when(() => mockContacts.getAll()).thenReturn([]);
    when(() => mockHistory.add(any())).thenAnswer((_) async {});
    when(() => mockLocation.lastPosition).thenReturn(null);
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
      sosHistoryDatasource: mockHistory,
      locationService: mockLocation,
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
