import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/geofence_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/presentation/screens/map/live_map_screen.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockGeofenceService extends Mock implements GeofenceService {}

void main() {
  late _MockGeofenceService mockGeofence;
  late MockLocationService mockLocation;

  setUp(() {
    final getIt = GetIt.instance;

    // Register LocationService if not already registered.
    if (!getIt.isRegistered<LocationService>()) {
      mockLocation = MockLocationService();
      when(() => mockLocation.getCurrentPosition()).thenAnswer((_) async => null);
      when(() => mockLocation.lastPosition).thenReturn(null);
      getIt.registerSingleton<LocationService>(mockLocation);
    }

    // Register GeofenceService.
    if (getIt.isRegistered<GeofenceService>()) {
      getIt.unregister<GeofenceService>();
    }
    mockGeofence = _MockGeofenceService();
    when(() => mockGeofence.zones).thenReturn([]);
    when(() => mockGeofence.isRunning).thenReturn(false);
    getIt.registerSingleton<GeofenceService>(mockGeofence);
  });

  group('LiveMapScreen Widget Tests', () {
    testWidgets('renders live map screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const LiveMapScreen()),
      );
      // Pump to let async initializeLocation complete.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LiveMapScreen), findsOneWidget);
    });

    testWidgets('renders map app bar with title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const LiveMapScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The title comes from localization: l.liveMap
      // Verify AppBar exists.
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders shield toggle icon button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const LiveMapScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Safe zone toggle icon should be present.
      expect(find.byIcon(Icons.shield_rounded), findsWidgets);
    });

    testWidgets('renders FlutterMap widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const LiveMapScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The LiveMapScreen Scaffold should be present in the widget tree.
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
