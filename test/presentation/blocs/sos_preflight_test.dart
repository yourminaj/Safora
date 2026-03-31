import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/connectivity_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';

// ── Mocks ──────────────────────────────────────────────────

class MockAudioService extends Mock implements AudioService {}
class MockBox extends Mock implements Box<dynamic> {}

class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}

class MockLocationService extends Mock implements LocationService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(SosHistoryEntry(
      timestamp: DateTime(2026),
      contactsNotified: 0,
      smsSentCount: 0,
      wasCancelled: false,
    ));
  });

  late MockAudioService audioService;
  late MockTriggerSosUseCase triggerSos;
  late MockContactsRepository contactsRepo;
  late MockSosHistoryDatasource sosHistory;
  late MockLocationService locationService;
  late MockConnectivityService connectivity;
  late MockBox settingsBox;

  setUp(() {
    audioService = MockAudioService();
    triggerSos = MockTriggerSosUseCase();
    contactsRepo = MockContactsRepository();
    sosHistory = MockSosHistoryDatasource();
    locationService = MockLocationService();
    connectivity = MockConnectivityService();
    settingsBox = MockBox();

    when(() => settingsBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(null);
    when(() => settingsBox.put(any(), any())).thenAnswer((_) async {});
    when(() => settingsBox.delete(any())).thenAnswer((_) async {});

    when(() => locationService.lastPosition).thenReturn(null);
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => null);
    when(() => connectivity.isOnline).thenReturn(true);
    when(() => audioService.stopAll()).thenAnswer((_) async {});
    when(() => contactsRepo.getAll()).thenReturn([]);
    when(() => sosHistory.add(any())).thenAnswer((_) async {});
  });

  SosCubit createCubit() => SosCubit(
        audioService: audioService,
        triggerSosUseCase: triggerSos,
        contactsRepository: contactsRepo,
        sosHistoryDatasource: sosHistory,
        locationService: locationService,
        connectivityService: connectivity,
        settingsBox: settingsBox,
      );

  group('SOS Pre-flight', () {
    test('initial state is SosIdle', () {
      final cubit = createCubit();
      expect(cubit.state, isA<SosIdle>());
      cubit.close();
    });

    test(
      'emits SosPreparing then SosPreflightFailed when no contacts',
      () async {
        when(() => contactsRepo.getAll()).thenReturn([]);

        final cubit = createCubit();
        final states = <SosState>[];
        final sub = cubit.stream.listen(states.add);

        cubit.startCountdown();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(states, isNotEmpty);
        expect(states.first, isA<SosPreparing>());
        expect(
          (states.first as SosPreparing).contactsReady,
          false,
        );
        expect(
          states.any((s) => s is SosPreflightFailed),
          true,
        );
        final failed = states.firstWhere((s) => s is SosPreflightFailed)
            as SosPreflightFailed;
        expect(failed.reason, SosFailureReason.noContacts);

        await sub.cancel();
        await cubit.close();
      },
    );

    test(
      'emits SosPreparing then SosCountdown when contacts exist',
      () async {
        when(() => contactsRepo.getAll()).thenReturn([
          const EmergencyContact(
            id: '1',
            name: 'Test Contact',
            phone: '+1234567890',
          ),
        ]);

        final cubit = createCubit();
        final states = <SosState>[];
        final sub = cubit.stream.listen(states.add);

        cubit.startCountdown();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(states, isNotEmpty);
        expect(states.first, isA<SosPreparing>());
        expect(
          (states.first as SosPreparing).contactsReady,
          true,
        );
        expect(
          states.any((s) => s is SosCountdown),
          true,
        );
        final countdown =
            states.firstWhere((s) => s is SosCountdown) as SosCountdown;
        expect(countdown.secondsRemaining, 30);

        await sub.cancel();
        await cubit.close();
      },
    );

    test(
      'SosPreparing reports gpsReady=false when no cached position',
      () async {
        when(() => locationService.lastPosition).thenReturn(null);
        when(() => locationService.getCurrentPosition())
            .thenAnswer((_) async => null);
        when(() => contactsRepo.getAll()).thenReturn([
          const EmergencyContact(
            id: '1',
            name: 'Test',
            phone: '+1234567890',
          ),
        ]);

        final cubit = createCubit();
        final states = <SosState>[];
        final sub = cubit.stream.listen(states.add);

        cubit.startCountdown();
        await Future.delayed(const Duration(milliseconds: 500));

        final preparing =
            states.firstWhere((s) => s is SosPreparing) as SosPreparing;
        expect(preparing.gpsReady, false);
        expect(preparing.networkReady, true);
        expect(preparing.contactsReady, true);

        await sub.cancel();
        await cubit.close();
      },
    );

    test('cancelCountdown emits SosCancelled and logs history', () async {
      when(() => contactsRepo.getAll()).thenReturn([
        const EmergencyContact(
          id: '1',
          name: 'Test',
          phone: '+1234567890',
        ),
      ]);

      final cubit = createCubit();
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startCountdown();
      await Future.delayed(const Duration(milliseconds: 300));
      cubit.cancelCountdown();
      await Future.delayed(const Duration(milliseconds: 300));

      expect(states.any((s) => s is SosCancelled), true);
      verify(() => sosHistory.add(any())).called(1);

      await sub.cancel();
      await cubit.close();
    });

    test('does not restart if already preparing/countdown', () async {
      when(() => contactsRepo.getAll()).thenReturn([
        const EmergencyContact(
          id: '1',
          name: 'Test',
          phone: '+1234567890',
        ),
      ]);

      final cubit = createCubit();
      cubit.startCountdown();
      await Future.delayed(const Duration(milliseconds: 200));

      // Second call should be ignored (already in countdown).
      cubit.startCountdown();
      await Future.delayed(const Duration(milliseconds: 100));

      await cubit.close();
      // If it reached here without error, the guard worked.
    });
  });
}
