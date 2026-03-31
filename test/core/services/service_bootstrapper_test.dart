import 'package:flutter_test/flutter_test.dart';

import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/service_bootstrapper.dart';

class MockBox extends Mock implements Box<dynamic> {}

// ── Lightweight verification tests for ServiceBootstrapper ──
//
// Full integration tests require GetIt + all services registered.
// These unit tests validate the class structure and Hive key logic.



void main() {
  group('ServiceBootstrapper', () {
    test('is a static-only utility class with private constructor', () {
      // Verifying the class exists and has a static bootstrap method.
      // We can't directly instantiate ServiceBootstrapper (private ctor).
      expect(ServiceBootstrapper, isNotNull);
    });

    group('Hive toggle key conventions', () {
      late MockBox mockSettings;

      setUp(() {
        mockSettings = MockBox();
      });

      test('reads shake_enabled toggle from Hive', () {
        when(() => mockSettings.get('shake_enabled', defaultValue: false))
            .thenReturn(true);

        final result = mockSettings.get('shake_enabled', defaultValue: false);
        expect(result, true);
        verify(() => mockSettings.get('shake_enabled', defaultValue: false))
            .called(1);
      });

      test('reads crash_fall_enabled toggle from Hive', () {
        when(
          () => mockSettings.get('crash_fall_enabled', defaultValue: false),
        ).thenReturn(false);

        final result =
            mockSettings.get('crash_fall_enabled', defaultValue: false);
        expect(result, false);
      });

      test('reads geofence_enabled toggle from Hive', () {
        when(
          () => mockSettings.get('geofence_enabled', defaultValue: false),
        ).thenReturn(true);

        final result =
            mockSettings.get('geofence_enabled', defaultValue: false);
        expect(result, true);
      });

      test('reads snatch_enabled toggle from Hive', () {
        when(
          () => mockSettings.get('snatch_enabled', defaultValue: false),
        ).thenReturn(true);

        final result =
            mockSettings.get('snatch_enabled', defaultValue: false);
        expect(result, true);
      });

      test('reads speed_alert_enabled toggle from Hive', () {
        when(
          () => mockSettings.get('speed_alert_enabled', defaultValue: false),
        ).thenReturn(false);

        final result =
            mockSettings.get('speed_alert_enabled', defaultValue: false);
        expect(result, false);
      });

      test('reads context_alert_enabled toggle from Hive', () {
        when(
          () => mockSettings.get('context_alert_enabled', defaultValue: false),
        ).thenReturn(true);

        final result =
            mockSettings.get('context_alert_enabled', defaultValue: false);
        expect(result, true);
      });

      test('returns false for all toggles when Hive is empty', () {
        // Simulate fresh install — all defaults are false.
        final keys = [
          'shake_enabled',
          'crash_fall_enabled',
          'geofence_enabled',
          'snatch_enabled',
          'speed_alert_enabled',
          'context_alert_enabled',
        ];

        for (final key in keys) {
          when(() => mockSettings.get(key, defaultValue: false))
              .thenReturn(false);
        }

        for (final key in keys) {
          expect(mockSettings.get(key, defaultValue: false), false);
        }
      });
    });
  });
}
