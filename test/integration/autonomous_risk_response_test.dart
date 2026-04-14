import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/connectivity_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/service_bootstrapper.dart';
import 'package:safora/core/services/sos_contact_alert_listener.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/detection/ml/crash_fall_detection_service.dart';
import 'package:safora/detection/ml/crash_fall_detection_engine.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/battery/battery_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';

class MockBox extends Mock implements Box<dynamic> {}

class MockCrashFallDetectionService extends Mock
    implements CrashFallDetectionService {}

class MockAlertsCubit extends Mock implements AlertsCubit {}

class MockSosCubit extends Mock implements SosCubit {}

class MockBatteryCubit extends Mock implements BatteryCubit {}

class MockAlertPreferences extends Mock implements AlertPreferences {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockLocationService extends Mock implements LocationService {}

class MockSosContactAlertListener extends Mock
    implements SosContactAlertListener {}

void main() {
  late GetIt sl;
  late MockBox mockSettings;
  late MockCrashFallDetectionService mockCrashService;
  late MockAlertsCubit mockAlertsCubit;
  late MockSosCubit mockSosCubit;
  late MockAlertPreferences mockAlertPrefs;

  // Real stream controller to simulate alerts emitted by the ML service
  late StreamController<DetectionAlert> crashAlertController;

  setUpAll(() {
    registerFallbackValue(AlertType.carAccident);
    registerFallbackValue(SosTriggerSource.manual);
    registerFallbackValue(
      AlertEvent(
        id: 'test',
        type: AlertType.carAccident,
        title: 't',
        description: 'd',
        timestamp: DateTime.now(),
        source: 's',
        latitude: 0.0,
        longitude: 0.0,
      ),
    );
  });

  setUp(() async {
    sl = GetIt.instance;
    await sl.reset();

    mockSettings = MockBox();
    mockCrashService = MockCrashFallDetectionService();
    mockAlertsCubit = MockAlertsCubit();
    mockSosCubit = MockSosCubit();
    mockAlertPrefs = MockAlertPreferences();
    crashAlertController = StreamController<DetectionAlert>.broadcast();

    // Default mock setups
    when(() => mockSettings.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      if (key == 'crash_fall_enabled') return true;
      return false;
    });

    when(() => mockCrashService.alerts)
        .thenAnswer((_) => crashAlertController.stream);
    when(() => mockCrashService.start()).thenAnswer((_) async {});

    when(() => mockAlertPrefs.shouldReceive(any())).thenReturn(true);

    // Provide dependencies into GetIt that Bootstrapper needs
    sl.registerSingleton<ConnectivityService>(MockConnectivityService());
    sl.registerSingleton<SosContactAlertListener>(
        MockSosContactAlertListener());
    sl.registerSingleton<LocationService>(MockLocationService());
    sl.registerSingleton<CrashFallDetectionService>(mockCrashService);
    sl.registerSingleton<AlertsCubit>(mockAlertsCubit);
    sl.registerSingleton<SosCubit>(mockSosCubit);
    sl.registerSingleton<BatteryCubit>(MockBatteryCubit());
    sl.registerSingleton<AlertPreferences>(mockAlertPrefs);

    // Stubs
    when(() => mockAlertsCubit.addLocalAlert(any())).thenAnswer((_) {});
    when(() => mockSosCubit.startCountdown(
      triggerSource: any(named: 'triggerSource'),
    )).thenAnswer((_) {});
    when(() => sl<ConnectivityService>().startMonitoring(
        onChanged: any(named: 'onChanged'))).thenAnswer((_) {});
    when(() => sl<SosContactAlertListener>().startListening())
        .thenAnswer((_) async {});
    when(() => sl<LocationService>().lastPosition).thenReturn(null);
    when(() => sl<BatteryCubit>().startMonitoring()).thenAnswer((_) {});
  });

  tearDown(() {
    crashAlertController.close();
    ServiceBootstrapper.dispose();
  });

  group('Autonomous Risk Response Integration Test', () {
    test(
        'Given crash detection enabled, '
        'When severe car accident occurs and preferences allow, '
        'Then risk score is high, local alert added, and SOS countdown automatically starts',
        () async {
      // 1. Arrange: Bootstrap the environment (wires up listeners)
      await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);

      crashAlertController.add(DetectionAlert(
        alertType: AlertType.carAccident,
        detectionType: DetectionType.vehicleCrash,
        severity: AlertPriority.critical,
        confidence: 0.95,
        title: 'Severe Vehicle Crash Detected',
        message: 'Impact force exceeded 10G',
        timestamp: DateTime.now(),
        peakGForce: 10.5,
      ));

      // Allow stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Assert:
      // A local alert should be saved for history/UI
      verify(() => mockAlertsCubit.addLocalAlert(any())).called(1);

      // Preferences should be checked by the bootstrapper
      verify(() => mockAlertPrefs.shouldReceive(AlertType.carAccident))
          .called(1);

      // The risk score engine computed >= 80 (because it's a car accident + 10.5 G),
      // so the system autonomously triggers the SOS countdown.
      verify(() => mockSosCubit.startCountdown(
        triggerSource: any(named: 'triggerSource'),
      )).called(1);
    });

    test(
        'Given crash detection enabled, '
        'When severe accident occurs but user DISABLED this specific alert type in preferences, '
        'Then local alert is saved for history, but SOS countdown does NOT start',
        () async {
      // 1. Arrange
      // User turned OFF car accident alerts specifically
      when(() => mockAlertPrefs.shouldReceive(AlertType.carAccident))
          .thenReturn(false);
      await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);

      // 2. Act
      crashAlertController.add(DetectionAlert(
        alertType: AlertType.carAccident,
        detectionType: DetectionType.vehicleCrash,
        severity: AlertPriority.critical,
        confidence: 0.95,
        title: 'Severe Vehicle Crash Detected',
        message: 'Impact force exceeded 10G',
        timestamp: DateTime.now(),
        peakGForce: 10.5,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Assert
      verify(() => mockAlertsCubit.addLocalAlert(any())).called(1);
      verify(() => mockAlertPrefs.shouldReceive(AlertType.carAccident))
          .called(1);

      // SOS countdown NEVER starts
      verifyNever(() => mockSosCubit.startCountdown(
        triggerSource: any(named: 'triggerSource'),
      ));
    });

    test(
        'Given crash detection enabled, '
        'When minor bump occurs (low risk score), '
        'Then local alert is saved, but SOS countdown does NOT start',
        () async {
      // 1. Arrange: enabled in preferences
      when(() => mockAlertPrefs.shouldReceive(AlertType.carAccident))
          .thenReturn(true);
      await ServiceBootstrapper.bootstrap(sl: sl, settings: mockSettings);

      // 2. Act: Minor bump (1.5 G force, low risk)
      // The RiskScoreEngine calculates score based on urgency mapping and G force.
      // Minor bumps won't reach 80.
      crashAlertController.add(DetectionAlert(
        alertType: AlertType.carAccident,
        detectionType: DetectionType.vehicleCrash,
        severity: AlertPriority.advisory,
        confidence: 0.45,
        title: 'Minor Vehicle Bump',
        message: 'Impact force 1.5G',
        timestamp: DateTime.now(),
        peakGForce: 1.5,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Assert
      verify(() => mockAlertsCubit.addLocalAlert(any())).called(1);
      verify(() => mockAlertPrefs.shouldReceive(AlertType.carAccident))
          .called(1);

      // SOS countdown NEVER starts because risk score < 80
      verifyNever(() => mockSosCubit.startCountdown(
        triggerSource: any(named: 'triggerSource'),
      ));
    });
  });
}
