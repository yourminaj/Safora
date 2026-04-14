/// Shake SOS Integration Test
///
/// Validates the full foreground and background shake → SOS call chain.
///
/// ## Foreground chain
/// ```
/// ServiceBootstrapper.bootstrap()
///   → ShakeDetectionService.startListening(onShakeDetected: callback)
///   → processAccelerometerEvent() fired ×3 (magnitude≥15) → shake triggered
///   → callback() {
///       AlertEvent(type: shakeSos, confidenceLevel: 1.0, isUserTriggered: true)
///       AlertPreferences.shouldReceive(shakeSos) → true
///       RiskScoreEngine.computeScore(event)      → 88 ≥ 80  ✅
///       SosCubit.startCountdown()                            ✅
///     }
/// ```
///
/// ## Background chain
/// ```
/// ServiceBootstrapper.bootstrapBackground()
///   → ShakeDetectionService fires
///   → callback() {
///       ContactsRepository.getAll()
///       TriggerSosUseCase.execute(contacts, triggerType: 'shake_background')  ✅
///     }
/// ```
///
/// ## Test strategy
/// Uses a REAL [ShakeDetectionService] with [processAccelerometerEvent()] injection
/// so tests control when the shake fires without hardware or platform channels.
library;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/connectivity_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/service_bootstrapper.dart';
import 'package:safora/core/services/shake_detection_service.dart';
import 'package:safora/core/services/sos_contact_alert_listener.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/battery/battery_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';
import 'package:safora/services/risk_score_engine.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────
class MockBox extends Mock implements Box<dynamic> {}
class MockAlertsCubit extends Mock implements AlertsCubit {}
class MockSosCubit extends Mock implements SosCubit {}
class MockBatteryCubit extends Mock implements BatteryCubit {}
class MockAlertPreferences extends Mock implements AlertPreferences {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockLocationService extends Mock implements LocationService {}
class MockSosContactAlertListener extends Mock implements SosContactAlertListener {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}

// ── Test contacts ──────────────────────────────────────────────────────────
const _primaryContact = EmergencyContact(
  id: 'c1',
  name: 'Jane Doe',
  phone: '+8801712345678',
  isPrimary: true,
);

// ── Helpers ────────────────────────────────────────────────────────────────

/// Fires 3 high-magnitude accelerometer events via [processAccelerometerEvent].
/// Shake requires 3 threshold crossings within the 800ms window.
void triggerShake(ShakeDetectionService service) {
  for (int i = 0; i < 3; i++) {
    service.processAccelerometerEvent(15.0, 15.0, 15.0);
  }
}

// ── Main ───────────────────────────────────────────────────────────────────
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_foreground_task/methods'),
      (_) async => true,
    );

    registerFallbackValue(AlertType.shakeSos);
    registerFallbackValue(SosTriggerSource.manual);
    registerFallbackValue(
      AlertEvent(
        id: 'fallback',
        type: AlertType.shakeSos,
        title: 'fallback',
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
      ),
    );
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
  });

  late GetIt sl;
  late MockBox mockSettings;
  late ShakeDetectionService realShakeService;
  late MockAlertsCubit mockAlertsCubit;
  late MockSosCubit mockSosCubit;
  late MockAlertPreferences mockAlertPrefs;
  late MockContactsRepository mockContacts;
  late MockTriggerSosUseCase mockUseCase;

  setUp(() async {
    sl = GetIt.instance;
    await sl.reset();

    mockSettings = MockBox();
    // Real shake service — stream injection skipped (uses processAccelerometerEvent directly)
    realShakeService = ShakeDetectionService(
      shakeThreshold: 15.0,
      shakeCount: 3,
      shakeWindowMs: 800,
      // Inject an empty stream so startListening() never opens the hardware
      // sensor channel. Events are injected via processAccelerometerEvent().
      accelerometerStream: const Stream.empty(),
    );
    mockAlertsCubit = MockAlertsCubit();
    mockSosCubit = MockSosCubit();
    mockAlertPrefs = MockAlertPreferences();
    mockContacts = MockContactsRepository();
    mockUseCase = MockTriggerSosUseCase();

    // All settings false, then shake_enabled true (specific wins over catch-all in mocktail)
    when(
      () => mockSettings.get(any(), defaultValue: any(named: 'defaultValue')),
    ).thenReturn(false);
    when(
      () => mockSettings.get(
        'shake_enabled',
        defaultValue: any(named: 'defaultValue'),
      ),
    ).thenReturn(true);

    // catch-all first (returns false for any type), specific override last (wins)
    when(() => mockAlertPrefs.shouldReceive(any())).thenReturn(false);
    when(() => mockAlertPrefs.shouldReceive(AlertType.shakeSos)).thenReturn(true);
    when(() => mockContacts.getAll()).thenReturn([_primaryContact]);
    when(
      () => mockUseCase.execute(
        contacts: any(named: 'contacts'),
        triggerType: any(named: 'triggerType'),
        userName: any(named: 'userName'),
      ),
    ).thenAnswer(
      (_) async => const SosResult(
        smsSentCount: 1, totalContacts: 1, hasLocation: false,
      ),
    );

    final mockConnectivity = MockConnectivityService();
    final mockLocation = MockLocationService();
    final mockListener = MockSosContactAlertListener();
    final mockBattery = MockBatteryCubit();

    when(
      () => mockConnectivity.startMonitoring(onChanged: any(named: 'onChanged')),
    ).thenAnswer((_) {});
    when(() => mockListener.startListening()).thenAnswer((_) async {});
    when(() => mockLocation.lastPosition).thenReturn(null);
    when(() => mockBattery.startMonitoring()).thenAnswer((_) {});
    when(() => mockAlertsCubit.addLocalAlert(any())).thenAnswer((_) {});
    when(() => mockSosCubit.startCountdown(
      triggerSource: any(named: 'triggerSource'),
    )).thenAnswer((_) {});
    when(() => mockSosCubit.isClosed).thenReturn(false);
    when(() => mockSosCubit.state).thenReturn(const SosIdle());

    sl.registerSingleton<ConnectivityService>(mockConnectivity);
    sl.registerSingleton<SosContactAlertListener>(mockListener);
    sl.registerSingleton<LocationService>(mockLocation);
    sl.registerSingleton<ShakeDetectionService>(realShakeService);
    sl.registerSingleton<AlertsCubit>(mockAlertsCubit);
    sl.registerSingleton<SosCubit>(mockSosCubit);
    sl.registerSingleton<BatteryCubit>(mockBattery);
    sl.registerSingleton<AlertPreferences>(mockAlertPrefs);
    sl.registerSingleton<ContactsRepository>(mockContacts);
    sl.registerSingleton<TriggerSosUseCase>(mockUseCase);
  });

  tearDown(() async {
    realShakeService.stopListening();
    ServiceBootstrapper.dispose();
  });

  // ── GROUP 1: Foreground Shake → RiskEngine → SosCubit ─────────────────────

  group('Foreground Shake SOS — Full Wiring Chain', () {
    test(
      'GIVEN shake enabled, '
      'WHEN shake fires (3 threshold crossings), '
      'THEN SosCubit.startCountdown() is called — confidenceLevel=1.0 → score=88≥80',
      () async {
        // Wire the shake service callbacks
        await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);

        // Inject a shake (3 magnitude≥15 events within 800ms window)
        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Full chain verified:
        // processAccelerometerEvent → _onShakeDetected → AlertEvent(confidence=1.0)
        // → RiskScoreEngine(88≥80) → SosCubit.startCountdown() ✅
        verify(() => mockSosCubit.startCountdown(
          triggerSource: any(named: 'triggerSource'),
        )).called(1);
      },
    );

    test(
      'GIVEN shake fires, '
      'WHEN callback runs, '
      'THEN AlertsCubit.addLocalAlert() receives event with '
      'confidenceLevel=1.0 and isUserTriggered=true',
      () async {
        await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);
        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockAlertsCubit.addLocalAlert(
            any(
              that: predicate<AlertEvent>(
                (e) =>
                    e.type == AlertType.shakeSos &&
                    e.confidenceLevel == 1.0 &&
                    e.isUserTriggered == true,
                'AlertEvent(shakeSos, confidence=1.0, isUserTriggered=true)',
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'GIVEN shake fires but AlertPreferences disables shakeSos, '
      'THEN SosCubit.startCountdown() is NOT called',
      () async {
        when(() => mockAlertPrefs.shouldReceive(AlertType.shakeSos))
            .thenReturn(false);

        await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);
        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockSosCubit.startCountdown(
          triggerSource: any(named: 'triggerSource'),
        ));
      },
    );

    test(
      'GIVEN shake disabled in settings, '
      'WHEN shake fires, '
      'THEN SosCubit.startCountdown() is NEVER called',
      () async {
        when(
          () => mockSettings.get(
            'shake_enabled',
            defaultValue: any(named: 'defaultValue'),
          ),
        ).thenReturn(false);

        await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);
        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockSosCubit.startCountdown(
          triggerSource: any(named: 'triggerSource'),
        ));
      },
    );

    test(
      'GIVEN shake fires twice rapidly (buffer cleared between triggers), '
      'THEN SosCubit.startCountdown() is called twice — '
      'one call per shake trigger (no built-in cooldown)',
      () async {
        await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);

        triggerShake(realShakeService); // shake 1 → fires, clears buffer
        triggerShake(realShakeService); // shake 2 → fires again (fresh buffer)
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Both shakes fire independently — shake timestamps are cleared after
        // each trigger, so the second shake starts fresh and also fires.
        // Cooldown is a UI concern (SosCubit.startCountdown guards against
        // duplicate state), not a ShakeDetectionService concern.
        verify(() => mockSosCubit.startCountdown(
          triggerSource: any(named: 'triggerSource'),
        )).called(2);
      },
    );
  });

  // ── GROUP 2: Risk Score Gate — Math Verification ───────────────────────────

  group('Risk Score Gate — shakeSos AlertEvent Math', () {
    test(
      'shakeSos with confidenceLevel=1.0 (the fix) scores 88 — passes ≥80 gate',
      () {
        const engine = RiskScoreEngine();
        final event = AlertEvent(
          type: AlertType.shakeSos,
          title: 'Shake Detected',
          timestamp: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
          confidenceLevel: 1.0,
        );
        expect(engine.computeScore(event), equals(88));
        expect(engine.computeScore(event), greaterThanOrEqualTo(80));
      },
    );

    test(
      'shakeSos without confidenceLevel (the original bug) scores 78 — fails ≥80 gate',
      () {
        const engine = RiskScoreEngine();
        final event = AlertEvent(
          type: AlertType.shakeSos,
          title: 'Shake Detected',
          timestamp: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
        );
        expect(engine.computeScore(event), equals(78));
        expect(engine.computeScore(event), lessThan(80));
      },
    );
  });

  // ── GROUP 3: Background Shake → Direct TriggerSosUseCase ──────────────────

  group('Background Shake SOS — Direct Execute', () {
    test(
      'GIVEN shake fires in background, '
      'THEN TriggerSosUseCase.execute() is called with '
      'contacts and triggerType="shake_background"',
      () async {
        await ServiceBootstrapper.bootstrapBackground(
          sl: sl,
          settings: mockSettings,
        );

        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockUseCase.execute(
            contacts: [_primaryContact],
            triggerType: 'shake_background',
          ),
        ).called(1);
      },
    );

    test(
      'GIVEN shake fires in background but no contacts, '
      'THEN TriggerSosUseCase.execute() is NOT called',
      () async {
        when(() => mockContacts.getAll()).thenReturn([]);

        await ServiceBootstrapper.bootstrapBackground(
          sl: sl,
          settings: mockSettings,
        );

        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(
          () => mockUseCase.execute(
            contacts: any(named: 'contacts'),
            triggerType: any(named: 'triggerType'),
          ),
        );
      },
    );

    test(
      'GIVEN shake fires in background, '
      'THEN SosCubit.startCountdown() is NOT called '
      '(SosCubit is UI-bound, unavailable in background isolate)',
      () async {
        await ServiceBootstrapper.bootstrapBackground(
          sl: sl,
          settings: mockSettings,
        );

        triggerShake(realShakeService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockSosCubit.startCountdown(
          triggerSource: any(named: 'triggerSource'),
        ));
      },
    );
  });
}
