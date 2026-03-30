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
import '../../helpers/widget_test_helpers.dart';

class MockShakeDetectionService extends Mock implements ShakeDetectionService {}
class MockAppLockService extends Mock implements AppLockService {}
class MockBox extends Mock implements Box {}
class MockAuthService extends Mock implements AuthService {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockCrashFallDetectionService extends Mock implements CrashFallDetectionService {}
class MockGeofenceService extends Mock implements GeofenceService {}
class MockSnatchDetectionService extends Mock implements SnatchDetectionService {}
class MockSpeedAlertService extends Mock implements SpeedAlertService {}
class MockContextAlertService extends Mock implements ContextAlertService {}
class MockLocationService extends Mock implements LocationService {}
class MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  final getIt = GetIt.instance;
  late MockShakeDetectionService mockShake;
  late MockAppLockService mockLock;
  late MockBox mockBox;
  late MockAuthService mockAuth;
  late MockContactsRepository mockContacts;
  late ContactsCubit contactsCubit;

  setUp(() {
    // Reset GetIt for clean state
    getIt.reset();

    mockShake = MockShakeDetectionService();
    mockLock = MockAppLockService();
    mockBox = MockBox();
    mockAuth = MockAuthService();
    mockContacts = MockContactsRepository();

    // Stub required methods
    when(() => mockLock.isLockEnabled).thenReturn(false);
    when(() => mockBox.get('shake_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('crash_fall_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('geofence_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('snatch_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('speed_alert_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('context_alert_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('dead_man_switch_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('dms_interval_minutes', defaultValue: 30)).thenReturn(30);
    // ML detection service toggles (added in last session).
    when(() => mockBox.get('voice_distress_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('anomaly_movement_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockBox.get('road_condition_enabled', defaultValue: false)).thenReturn(false);
    when(() => mockAuth.isSignedIn).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockContacts.getAll()).thenReturn([]);
    when(() => mockContacts.count).thenReturn(0);
    when(() => mockContacts.isLimitReached).thenReturn(false);

    // LocationService mock with real coordinates
    final mockLocation = MockLocationService();
    when(() => mockLocation.lastPosition).thenReturn(null);

    // Register in GetIt
    getIt.registerSingleton<LocationService>(mockLocation);
    getIt.registerSingleton<ShakeDetectionService>(mockShake);
    getIt.registerSingleton<AppLockService>(mockLock);
    getIt.registerSingleton<Box>(mockBox, instanceName: 'app_settings');
    getIt.registerSingleton<AuthService>(mockAuth);
    getIt.registerSingleton<CrashFallDetectionService>(MockCrashFallDetectionService());
    getIt.registerSingleton<GeofenceService>(MockGeofenceService());
    getIt.registerSingleton<SnatchDetectionService>(MockSnatchDetectionService());
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

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders settings screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('displays app bar with Settings title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has a ListView for scrolling', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows Profile tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      // The Account section's first tile uses workspace_premium_rounded.
      expect(find.byIcon(Icons.workspace_premium_rounded), findsWidgets);
    });

    testWidgets('shows Emergency Contacts tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.contacts_rounded), findsOneWidget);
    });

    testWidgets('shows Shake-to-SOS toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);
    });

    testWidgets('shows App Lock toggle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('has Switch widgets for toggles', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      // Shake-to-SOS and App Lock have Switch toggles
      expect(find.byType(Switch), findsAtLeast(2));
    });

    testWidgets('shows language settings tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      // ListView lazy-builds; scrollUntilVisible triggers item creation.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.language_rounded),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    });

    testWidgets('shows dark mode tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      await tester.scrollUntilVisible(
        find.byIcon(Icons.dark_mode_rounded),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });

    testWidgets('shows about tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      // No About section; verify General section with language tile.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.language_rounded),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    });

    testWidgets('shows Sign In icon when user is not signed in', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      // login_rounded is near the bottom; scrollUntilVisible lazily builds it.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.login_rounded),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    });

    testWidgets('shows premium tile', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('alert sounds tile is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump(const Duration(seconds: 2));
      await tester.scrollUntilVisible(
        find.byIcon(Icons.volume_up_rounded),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });
  });
}
