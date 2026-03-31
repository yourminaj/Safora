import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';

class MockAudioService extends Mock implements AudioService {}
class MockBox extends Mock implements Box<dynamic> {}

class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_foreground_task/methods'),
            (MethodCall methodCall) async {
      return true;
    });
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
  late MockBox mockBox;

  setUp(() {
    mockAudio = MockAudioService();
    mockUseCase = MockTriggerSosUseCase();
    mockContacts = MockContactsRepository();
    mockHistory = MockSosHistoryDatasource();
    mockLocation = MockLocationService();
    mockBox = MockBox();

    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(null);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    when(() => mockBox.delete(any())).thenAnswer((_) async {});

    when(() => mockAudio.playSiren()).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockUseCase.cancel()).thenAnswer((_) async {});
    // Provide at least one contact so pre-flight passes.
    when(() => mockContacts.getAll()).thenReturn([
      const EmergencyContact(
        id: '1',
        name: 'Test',
        phone: '+8801700000000',
        isPrimary: true,
      ),
    ]);
    when(() => mockHistory.add(any())).thenAnswer((_) async {});
    when(() => mockLocation.lastPosition).thenReturn(null);
    // Stub getCurrentPosition so pre-flight GPS fix resolves immediately.
    when(() => mockLocation.getCurrentPosition())
        .thenAnswer((_) async => null);
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
      settingsBox: mockBox,
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

  // ── SMS Pre-Flight Permission Guard ─────────────────────────────────────────
  // NOTE: SosCubit uses Telephony.instance directly (not injectable), so
  // the smsPermissionDenied path can only be verified on real Android hardware
  // or via integration tests.  These unit tests cover what IS mockable:
  // the noContacts pre-flight gate and state shape.
  group('SosCubit — SMS pre-flight — noContacts gate (testable)', () {
    test(
        'emits SosPreflightFailed(noContacts) when contact list is empty',
        () async {
      when(() => mockContacts.getAll()).thenReturn([]);
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Pre-flight must block with noContacts before reaching countdown.
      expect(
        states.whereType<SosPreflightFailed>().any(
              (f) => f.reason == SosFailureReason.noContacts,
            ),
        isTrue,
        reason: 'Expected SosPreflightFailed.noContacts when contact list empty',
      );
      // Must NOT have started countdown.
      expect(states.any((s) => s is SosCountdown), isFalse);

      await sub.cancel();
    });

    test(
        'emits SosPreparing then SosCountdown when contacts exist (happy path)',
        () async {
      // Contacts are already stubbed in setUp — one contact present.
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startCountdown();
      await Future<void>.delayed(Duration.zero);

      // Must pass contacts check and emit SosPreparing.
      expect(states.any((s) => s is SosPreparing), isTrue);
      // On non-Android (test host is macOS/Linux), SMS check is skipped;
      // countdown starts immediately after pre-flight.
      expect(states.any((s) => s is SosCountdown), isTrue);

      await sub.cancel();
    });

    test('SosPreflightFailed auto-resets to SosIdle after 3 seconds', () async {
      when(() => mockContacts.getAll()).thenReturn([]);
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startCountdown();
      await Future<void>.delayed(const Duration(seconds: 4));

      expect(cubit.state, const SosIdle());

      await sub.cancel();
    });
  });
}
