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
import 'package:hive/hive.dart';
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
class MockBox extends Mock implements Box<dynamic> {}
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

/// Captured tel: URIs from the injected phone call launcher.
List<Uri> capturedCallUris = [];

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
  required MockBox settingsBox,
  PhoneCallLauncher? phoneCallLauncher,
}) {
  final useCase = TriggerSosUseCase(
    smsService: sms,
    locationService: location,
    notificationService: notifications,
    sosEventService: sosEventService,
    phoneCallLauncher: phoneCallLauncher ?? (uri) async {
      capturedCallUris.add(uri);
      return true;
    },
  );

  return SosCubit(
    audioService: audio,
    triggerSosUseCase: useCase,
    contactsRepository: contacts,
    sosHistoryDatasource: history,
    locationService: location,
    connectivityService: connectivity,
    settingsBox: settingsBox,
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
  late MockBox mockBox;

  setUp(() {
    mockAudio = MockAudioService();
    mockSms = MockSmsService();
    mockLocation = MockLocationService();
    mockContacts = MockContactsRepository();
    mockHistory = MockSosHistoryDatasource();
    mockConnectivity = MockConnectivityService();
    mockSosEventService = MockSosEventService();
    mockNotifications = MockNotificationService();
    mockBox = MockBox();

    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(null);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    when(() => mockBox.delete(any())).thenAnswer((_) async {});
    
    capturedCallUris.clear();

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
            settingsBox: mockBox,
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
            settingsBox: mockBox,
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
            settingsBox: mockBox,
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
            settingsBox: mockBox,
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
            settingsBox: mockBox,
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
            settingsBox: mockBox,
      );

      // Directly invoke the use case (bypasses 30-second countdown).
      final useCase = TriggerSosUseCase(
        smsService: mockSms,
        locationService: mockLocation,
        notificationService: mockNotifications,
        sosEventService: mockSosEventService,
        phoneCallLauncher: (uri) async => true,
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
        phoneCallLauncher: (uri) async => true,
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
        phoneCallLauncher: (uri) async => true,
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
        phoneCallLauncher: (uri) async => true,
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
        phoneCallLauncher: (uri) async => true,
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
        phoneCallLauncher: (uri) async => true,
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

  // ── GROUP 5: Countdown expiry → contact wiring ────────────────────────────
  //
  // Strategy: resumeCountdown(pastDeadline) calls _triggerSos() immediately,
  // bypassing the 30-second real-time wait while exercising the exact same code
  // path that fires when the Timer.periodic countdown reaches zero.
  //
  // This group proves that the contacts fetched from ContactsRepository are
  // forwarded correctly all the way to SmsService.sendEmergencySms().

  group('SOS BLoC Integration — Countdown Expiry Contact Wiring', () {
    test(
      'GIVEN two contacts in repository, '
      'WHEN countdown expires, '
      'THEN sendEmergencySms is called with BOTH contacts',
      () async {
        // setUp already stubs getAll() → [_primaryContact, _secondaryContact]
        final cubit = _buildCubit(
          audio: mockAudio,
          sms: mockSms,
          location: mockLocation,
          contacts: mockContacts,
          history: mockHistory,
          connectivity: mockConnectivity,
          sosEventService: mockSosEventService,
          notifications: mockNotifications,
          settingsBox: mockBox,
        );

        final states = <SosState>[];
        final sub = cubit.stream.listen(states.add);

        // resumeCountdown with a past deadline fires _triggerSos() immediately
        cubit.resumeCountdown(
          DateTime.now().subtract(const Duration(seconds: 1)),
        );

        // Allow _triggerSos() async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sub.cancel();
        await cubit.close();

        // 1. State became SosActive
        expect(
          states.any((s) => s is SosActive),
          isTrue,
          reason: 'Expired countdown must emit SosActive',
        );

        // 2. SMS was sent with the EXACT two contacts from getAll()
        verify(
          () => mockSms.sendEmergencySms(
            contacts: [_primaryContact, _secondaryContact],
            userName: any(named: 'userName'),
          ),
        ).called(1);

        // 3. Notification shown
        verify(() => mockNotifications.showSosNotification()).called(1);

        // 4. SOS event written for FCM
        verify(
          () => mockSosEventService.recordSosEvent(
            triggerType: any(named: 'triggerType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            contacts: any(named: 'contacts'),
          ),
        ).called(1);

        // 5. History logged with correct counts and wasCancelled=false
        verify(
          () => mockHistory.add(
            any(
              that: predicate<SosHistoryEntry>(
                (e) => e.contactsNotified == 2 && !e.wasCancelled,
                'contactsNotified=2 and wasCancelled=false',
              ),
            ),
          ),
        ).called(1);
        
        // 6. Auto-call initiated to primary contact
        expect(capturedCallUris, hasLength(1));
        expect(capturedCallUris.first.toString(), 'tel:+8801712345678');
      },
    );

    test(
      'GIVEN only primary contact, '
      'WHEN countdown expires, '
      'THEN sendEmergencySms is called with primary contact only',
      () async {
        when(() => mockContacts.getAll()).thenReturn([_primaryContact]);
        when(() => mockSms.sendEmergencySms(
              contacts: any(named: 'contacts'),
              userName: any(named: 'userName'),
            )).thenAnswer((_) async => 1);

        final cubit = _buildCubit(
          audio: mockAudio,
          sms: mockSms,
          location: mockLocation,
          contacts: mockContacts,
          history: mockHistory,
          connectivity: mockConnectivity,
          sosEventService: mockSosEventService,
          notifications: mockNotifications,
          settingsBox: mockBox,
        );

        cubit.resumeCountdown(
          DateTime.now().subtract(const Duration(seconds: 1)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await cubit.close();

        verify(
          () => mockSms.sendEmergencySms(
            contacts: [_primaryContact], // ← only the one contact
            userName: any(named: 'userName'),
          ),
        ).called(1);
      },
    );

    test(
      'GIVEN countdown expires, '
      'THEN siren plays AND SMS is sent (both fire-and-forget + awaited)',
      () async {
        final cubit = _buildCubit(
          audio: mockAudio,
          sms: mockSms,
          location: mockLocation,
          contacts: mockContacts,
          history: mockHistory,
          connectivity: mockConnectivity,
          sosEventService: mockSosEventService,
          notifications: mockNotifications,
          settingsBox: mockBox,
        );

        cubit.resumeCountdown(
          DateTime.now().subtract(const Duration(seconds: 1)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await cubit.close();

        // Both audio and SMS must be triggered
        verify(() => mockAudio.playSiren()).called(1);
        verify(
          () => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ),
        ).called(1);
      },
    );

    test(
      'GIVEN countdown is cancelled before expiry, '
      'THEN sendEmergencySms is NEVER called',
      () async {
        final cubit = _buildCubit(
          audio: mockAudio,
          sms: mockSms,
          location: mockLocation,
          contacts: mockContacts,
          history: mockHistory,
          connectivity: mockConnectivity,
          sosEventService: mockSosEventService,
          notifications: mockNotifications,
          settingsBox: mockBox,
        );

        cubit.startCountdown();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        cubit.cancelCountdown();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await cubit.close();

        verifyNever(
          () => mockSms.sendEmergencySms(
            contacts: any(named: 'contacts'),
            userName: any(named: 'userName'),
          ),
        );
      },
    );
  });
}
