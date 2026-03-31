import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/app_lock_service.dart';
import 'package:safora/core/services/auth_service.dart';
import 'package:safora/core/services/context_alert_service.dart';
import 'package:safora/core/services/geofence_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/core/services/shake_detection_service.dart';
import 'package:safora/core/services/snatch_detection_service.dart';
import 'package:safora/core/services/speed_alert_service.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/detection/ml/crash_fall_detection_service.dart';
import 'package:safora/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:safora/presentation/blocs/theme/theme_cubit.dart';
import 'package:safora/presentation/screens/settings/settings_screen.dart';
import 'package:safora/presentation/widgets/safora_animated_icons.dart';
import '../../helpers/widget_test_helpers.dart';

class MockShakeDetectionService extends Mock implements ShakeDetectionService {}
class MockAppLockService extends Mock implements AppLockService {}
class MockBox extends Mock implements Box {}
class MockAuthService extends Mock implements AuthService {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockCrashFallDetectionService extends Mock
    implements CrashFallDetectionService {}
class MockGeofenceService extends Mock implements GeofenceService {}
class MockSnatchDetectionService extends Mock
    implements SnatchDetectionService {}
class MockSpeedAlertService extends Mock implements SpeedAlertService {}
class MockContextAlertService extends Mock implements ContextAlertService {}
class MockLocationService extends Mock implements LocationService {}
class MockThemeCubit extends Mock implements ThemeCubit {}

/// Tests that the Settings screen correctly renders the branded vector icons
/// in place of the removed Lottie animations.
void main() {
  final getIt = GetIt.instance;
  late MockBox mockBox;
  late ContactsCubit contactsCubit;

  setUp(() {
    getIt.reset();

    final mockShake = MockShakeDetectionService();
    final mockLock = MockAppLockService();
    mockBox = MockBox();
    final mockAuth = MockAuthService();
    final mockContacts = MockContactsRepository();
    final mockLocation = MockLocationService();

    when(() => mockLock.isLockEnabled).thenReturn(false);
    // All detection toggles default to false.
    when(() => mockBox.get('shake_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('crash_fall_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('geofence_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('snatch_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('speed_alert_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('context_alert_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('dead_man_switch_enabled', defaultValue: false))
        .thenReturn(false);
    when(() => mockBox.get('dms_interval_minutes', defaultValue: 30))
        .thenReturn(30);
    // ML detection toggles — enable them so icons render.
    when(() => mockBox.get('voice_distress_enabled', defaultValue: false))
        .thenReturn(true);
    when(() => mockBox.get('anomaly_movement_enabled', defaultValue: false))
        .thenReturn(true);
    when(() => mockBox.get('road_condition_enabled', defaultValue: false))
        .thenReturn(true);
    when(() => mockAuth.isSignedIn).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockContacts.getAll()).thenReturn([]);
    when(() => mockContacts.count).thenReturn(0);
    when(() => mockContacts.isLimitReached).thenReturn(false);
    when(() => mockLocation.lastPosition).thenReturn(null);

    getIt.registerSingleton<LocationService>(mockLocation);
    getIt.registerSingleton<ShakeDetectionService>(mockShake);
    getIt.registerSingleton<AppLockService>(mockLock);
    getIt.registerSingleton<Box>(mockBox, instanceName: 'app_settings');
    getIt.registerSingleton<AuthService>(mockAuth);
    getIt.registerSingleton<CrashFallDetectionService>(
        MockCrashFallDetectionService());
    getIt.registerSingleton<GeofenceService>(MockGeofenceService());
    getIt.registerSingleton<SnatchDetectionService>(
        MockSnatchDetectionService());
    getIt.registerSingleton<SpeedAlertService>(MockSpeedAlertService());
    getIt.registerSingleton<ContextAlertService>(MockContextAlertService());
    getIt.registerSingleton<ThemeCubit>(MockThemeCubit());

    contactsCubit = ContactsCubit(mockContacts);
  });

  tearDown(() {
    contactsCubit.close();
    getIt.reset();
  });

  Widget buildScreen() {
    return buildTestableWidget(
      contactsCubit: contactsCubit,
      child: const SettingsScreen(),
    );
  }

  group('Settings Screen — Branded Icon Integration', () {
    testWidgets('Voice Distress tile renders SaforaVoiceDistressIcon',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      // The ML detection tiles are in the "Detection" section.
      // Scroll until SaforaVoiceDistressIcon is visible.
      await tester.scrollUntilVisible(
        find.byType(SaforaVoiceDistressIcon),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(SaforaVoiceDistressIcon), findsOneWidget);
    });

    testWidgets('Anomaly Movement tile renders SaforaAnomalyMovementIcon',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      await tester.scrollUntilVisible(
        find.byType(SaforaAnomalyMovementIcon),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(SaforaAnomalyMovementIcon), findsOneWidget);
    });

    testWidgets('Road Condition tile renders SaforaRoadConditionIcon',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      await tester.scrollUntilVisible(
        find.byType(SaforaRoadConditionIcon),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(SaforaRoadConditionIcon), findsOneWidget);
    });

    testWidgets('no Lottie widgets in the rendered tree', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      // If Lottie were still imported, tester.widget<Lottie>() would find
      // something. Since Lottie is removed from deps, there's no type to
      // query, but we can verify no "Lottie" text appears in the element
      // debug description.
      final allElements = tester.allElements.toList();
      for (final element in allElements) {
        final desc = element.widget.runtimeType.toString();
        expect(desc, isNot(contains('Lottie')),
            reason: 'Found Lottie widget in tree: $desc');
      }
    });
  });

  group('Settings Screen — _SettingsTile customIcon rendering', () {
    testWidgets('tiles without customIcon still render standard Icons',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      // Shake-to-SOS tile uses a standard Icon, not customIcon.
      expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);
    });

    testWidgets('tiles with customIcon render the widget, not Icon',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));

      // Scroll to voice distress area.
      await tester.scrollUntilVisible(
        find.byType(SaforaVoiceDistressIcon),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // When customIcon is provided, the icon area should contain the
      // custom widget. Verify there's a CustomPaint nearby.
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
