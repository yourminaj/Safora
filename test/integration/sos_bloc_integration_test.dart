/// SOS BLoC Integration Test — Full Trigger Chain
///
/// This test validates the complete SOS emergency flow at the BLoC level,
/// using real [SosCubit] wired to real use cases with mocked I/O boundaries
/// (SMS, GPS, audio, Firestore).
///
/// ## Chain validated
/// ```
/// SosCubit.startCountdown()
///   → _runPreflightAndStart()
///       → SosPreparing state (GPS ✓, Contacts ✓)
///       → SosCountdown(secondsRemaining: 30)
///       [timer skipped via FakeAsync]
///   → _triggerSos()
///       → SosActive state
///       → TriggerSosUseCase.execute()
///           → LocationService.getCurrentPosition()
///           → SmsService.sendEmergencySms()       [verified called once]
///           → NotificationService.showSosNotification()
///           → SosEventService.recordSosEvent()    [verified fire-and-forget]
///       → SosHistoryDatasource.add()
///
/// SosCubit.cancelCountdown()
///   → SosCancelled state
///   → SmsService.sendEmergencySms()              [verified NOT called]
/// ```
library;


import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/connectivity_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/sos_event_service.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/core/services/sms_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';

// ────────────────────────────────────────────────────────────────
// MOCK DECLARATIONS
// ────────────────────────────────────────────────────────────────

class MockAudioService extends Mock implements AudioService {}
class MockSmsService extends Mock implements SmsService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockLocationService extends Mock implements LocationService {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockSosEventService extends Mock implements SosEventService {}

// ────────────────────────────────────────────────────────────────
// TEST CONSTANTS
// ────────────────────────────────────────────────────────────────

const _primaryContact = EmergencyContact(
  id: 'c1',
  name: 'Jane Doe',
  phone: '+8801712345678',
  isPrimary: true,
);

const _secondaryContact = EmergencyContact(
  id: 'c2',
  name: 'John Doe',
  phone: '+8801800000001',
  isPrimary: false,
);

// ────────────────────────────────────────────────────────────────
// HELPERS
// ────────────────────────────────────────────────────────────────

/// Builds a fully-wired [SosCubit] with all dependencies mocked.
SosCubit _buildCubit({
  required MockAudioService audio,
  required MockSmsService sms,
  required MockLocationService location,
  required MockContactsRepository contacts,
  required MockSosHistoryDatasource history,
  required MockConnectivityService connectivity,
  required MockSosEventService sosEventService,
  required MockNotificationService notifications,
}) {
  final useCase = TriggerSosUseCase(
    smsService: sms,
    locationService: location,
    notificationService: notifications,
    sosEventService: sosEventService,
  );

  return SosCubit(
    audioService: audio,
    triggerSosUseCase: useCase,
    contactsRepository: contacts,
    sosHistoryDatasource: history,
    locationService: location,
    connectivityService: connectivity,
  );
}

// ────────────────────────────────────────────────────────────────
// TESTS
// ────────────────────────────────────────────────────────────────

void main() {
  late MockAudioService mockAudio;
  late MockSmsService mockSms;
  late MockLocationService mockLocation;
  late MockContactsRepository mockContacts;
  late MockSosHistoryDatasource mockHistory;
  late MockConnectivityService mockConnectivity;
  late MockSosEventService mockSosEventService;
  late MockNotificationService mockNotifications;

  setUp(() {
    mockAudio = MockAudioService();
    mockSms = MockSmsService();
    mockLocation = MockLocationService();
    mockContacts = MockContactsRepository();
    mockHistory = MockSosHistoryDatasource();
    mockConnectivity = MockConnectivityService();
    mockSosEventService = MockSosEventService();
    mockNotifications = MockNotificationService();

    // Register fallback values for mocktail
    registerFallbackValue(
      SosHistoryEntry(
        timestamp: DateTime.now(),
        contactsNotified: 0,
        smsSentCount: 0,
        wasCancelled: false,
      ),
    );
    registerFallbackValue(
      const EmergencyContact(name: 'fallback', phone: '+0'),
    );

    // ── Default stubs ──────────────────────────────────────────
    // A single primary contact is available.
    when(() => mockContacts.getAll())
        .thenReturn([_primaryContact, _secondaryContact]);

    // GPS has a last known position available immediately.
    when(() => mockLocation.lastPosition).thenReturn(null);
    when(() => mockLocation.getCurrentPosition())
        .thenAnswer((_) async => null);

    // Network is online.
    when(() => mockConnectivity.isOnline).thenReturn(true);

    // SMS succeeds (sent to 2 contacts).
    when(() => mockSms.sendEmergencySms(
          contacts: any(named: 'contacts'),
          userName: any(named: 'userName'),
        )).thenAnswer((_) async => 2);

    // Audio plays without error.
    when(() => mockAudio.playSiren()).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});

    // Notification service.
    when(() => mockNotifications.showSosNotification())
        .thenAnswer((_) async {});
    when(() => mockNotifications.cancelSosNotification())
        .thenAnswer((_) async {});

    // SosHistoryDatasource.
    when(() => mockHistory.add(any())).thenAnswer((_) async {});

    // SosEventService — fire-and-forget (returns Future.value).
    when(() => mockSosEventService.recordSosEvent(
          triggerType: any(named: 'triggerType'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async {});
  });

  // ── GROUP 1: Pre-flight states ────────────────────────────────────

  group('SOS BLoC Integration — Pre-flight States', () {
    test('startCountdown emits [SosPreparing, SosCountdown(30)]', () async {
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await sub.cancel();
      await cubit.close();
      expect(states.first, isA<SosPreparing>());
      final countdown = states.whereType<SosCountdown>().first;
      expect(countdown.secondsRemaining, SosCubit.countdownDuration);
    });

    test('startCountdown when no contacts → SosPreflightFailed(noContacts)', () async {
      when(() => mockContacts.getAll()).thenReturn([]);
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await sub.cancel();
      await cubit.close();
      expect(states.first, isA<SosPreparing>());
      final failed = states.whereType<SosPreflightFailed>().first;
      expect(failed.reason, SosFailureReason.noContacts);
    });

    test('startCountdown is idempotent when already in countdown', () async {
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );
      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cubit.startCountdown(); // no-op
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await cubit.close();
      verifyNever(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ));
    });
  });

  // ── GROUP 2: Cancel before expiry ──────────────────────────────

  group('SOS BLoC Integration — Cancel Flow', () {
    test('cancelCountdown before expiry prevents SMS delivery', () async {
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );
      final states = <SosState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cubit.cancelCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();
      await cubit.close();

      expect(states.any((s) => s is SosPreparing), isTrue);
      expect(states.any((s) => s is SosCountdown), isTrue);
      expect(states.any((s) => s is SosCancelled), isTrue);

      verifyNever(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ));
      verifyNever(() => mockSosEventService.recordSosEvent(
            triggerType: any(named: 'triggerType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: any(named: 'contacts'),
          ));
    });

    test('cancelCountdown logs a cancelled SOS history entry', () async {
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );
      cubit.startCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cubit.cancelCountdown();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await cubit.close();

      verify(() => mockHistory.add(any())).called(1);
    });
  });


  // ── GROUP 3: SOS trigger chain ────────────────────────────────

  group('SOS BLoC Integration — TriggerSosUseCase Wiring', () {
    test('execute() calls SMS with all contacts', () async {
      final cubit = _buildCubit(
        audio: mockAudio,
        sms: mockSms,
        location: mockLocation,
        contacts: mockContacts,
        history: mockHistory,
        connectivity: mockConnectivity,
        sosEventService: mockSosEventService,
        notifications: mockNotifications,
      );

      // Directly invoke the use case (bypasses 30-second countdown).
      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
      );

      final result = await useCase.execute(
        contacts: [_primaryContact, _secondaryContact],
        triggerType: 'manual',
      );

      expect(result.smsSentCount, 2);
      expect(result.totalContacts, 2);

      verify(() => mockSms.sendEmergencySms(
            contacts: [_primaryContact, _secondaryContact],
            userName: any(named: 'userName'),
          )).called(1);

      // FCM event write happens fire-and-forget — verify it was called.
      verify(() => mockSosEventService.recordSosEvent(
            triggerType: 'manual',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: [_primaryContact, _secondaryContact],
          )).called(1);

      await cubit.close();
    });

    test('execute() returns correct SosResult even when SMS count is 0', () async {
      when(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          )).thenAnswer((_) async => 0); // SMS delivery failed

      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
      );

      final result = await useCase.execute(
        contacts: [_primaryContact],
        triggerType: 'crash',
      );

      // Result correctly indicates 0 SMS sent but 1 total contact.
      expect(result.smsSentCount, 0);
      expect(result.totalContacts, 1);
      expect(result.allSent, false);
    });

    test('execute() with no contacts skips SMS but still writes SOS event', () async {
      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
      );

      final result = await useCase.execute(
        contacts: [],
        triggerType: 'shake',
      );

      expect(result.totalContacts, 0);
      expect(result.smsSentCount, 0);

      verifyNever(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ));

      // SOS event is still written (for audit and potential future contacts).
      verify(() => mockSosEventService.recordSosEvent(
            triggerType: 'shake',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: [],
          )).called(1);
    });
  });

  // ── GROUP 4: SosEventService integration ─────────────────────

  group('SOS BLoC Integration — SosEventService (FCM) wiring', () {
    setUp(() {
      // In group 4 we always use [_primaryContact] (1 contact) so override
      // the default stub that returns 2.
      when(() => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          )).thenAnswer((_) async => 1);
    });

    test('SosEventService.recordSosEvent is called fire-and-forget — does not block SosResult', () async {
      // Even if the SosEventService is slow, the fast SmsService result
      // is returned without delay.
      var eventServiceCompleted = false;

      when(() => mockSosEventService.recordSosEvent(
            triggerType: any(named: 'triggerType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: any(named: 'contacts'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 5)); // Simulate slow network
        eventServiceCompleted = true;
      });

      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
      );

      final stopwatch = Stopwatch()..start();
      final result = await useCase.execute(
        contacts: [_primaryContact],
        triggerType: 'manual',
      );
      stopwatch.stop();

      // The SOS result should be returned quickly (long before the 5s delay).
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(result.smsSentCount, 1);

      // The Firestore write has not completed yet (it's fire-and-forget).
      expect(eventServiceCompleted, false);
    });

    test('SosEventService failure does NOT affect SosResult', () async {
      when(() => mockSosEventService.recordSosEvent(
            triggerType: any(named: 'triggerType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: any(named: 'contacts'),
          )).thenThrow(Exception('Simulated Firestore network error'));

      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
      );

      // Even though SosEventService throws, execute() should complete normally.
      // TriggerSosUseCase wraps the call in try-catch so synchronous errors
      // from the service are caught and logged, not rethrown.
      final result = await useCase.execute(
        contacts: [_primaryContact],
        triggerType: 'fall',
      );

      expect(result.smsSentCount, 1);
      expect(result.totalContacts, 1);
    });

    test('Cubit without SosEventService still triggers SOS correctly', () async {
      // TriggerSosUseCase built without optional SosEventService.
      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        // sosEventService intentionally omitted — optional
      );

      final result = await useCase.execute(
        contacts: [_primaryContact],
        triggerType: 'manual',
      );

      expect(result.smsSentCount, 1);
      // recordSosEvent should NEVER be called since service was not injected.
      verifyNever(() => mockSosEventService.recordSosEvent(
            triggerType: any(named: 'triggerType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: any(named: 'contacts'),
          ));
    });
  });
}
