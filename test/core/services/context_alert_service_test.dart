import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/context_alert_service.dart';

void main() {
  group('ContextAlertService', () {
    late ContextAlertService service;

    setUp(() {
      service = ContextAlertService(checkIntervalMinutes: 5);
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not running', () {
      expect(service.isRunning, isFalse);
    });

    test('custom check interval is configurable', () {
      final custom = ContextAlertService(checkIntervalMinutes: 10);
      expect(custom.checkIntervalMinutes, 10);
      custom.dispose();
    });

    test('stop is safe when not running', () {
      expect(() => service.stop(), returnsNormally);
      expect(service.isRunning, isFalse);
    });

    test('dispose is safe when not running', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('external data fields default to null', () {
      expect(service.currentTemperatureCelsius, isNull);
      expect(service.currentWindSpeedKmh, isNull);
      expect(service.currentUvIndex, isNull);
      expect(service.currentSpeedKmh, isNull);
      expect(service.currentPrecipitationMm, isNull);
    });

    test('external data fields can be set', () {
      service.currentTemperatureCelsius = 42.0;
      service.currentWindSpeedKmh = 15.0;
      service.currentUvIndex = 11.0;
      service.currentSpeedKmh = 65.0;
      service.currentPrecipitationMm = 40.0;

      expect(service.currentTemperatureCelsius, 42.0);
      expect(service.currentWindSpeedKmh, 15.0);
      expect(service.currentUvIndex, 11.0);
      expect(service.currentSpeedKmh, 65.0);
      expect(service.currentPrecipitationMm, 40.0);
    });
  });

  group('ContextAlert model', () {
    test('creates with required fields', () {
      const alert = ContextAlert(
        type: ContextAlertType.heatStroke,
        title: 'Heat Stroke',
        message: 'Very hot!',
        severity: ContextSeverity.critical,
      );

      expect(alert.type, ContextAlertType.heatStroke);
      expect(alert.title, 'Heat Stroke');
      expect(alert.message, 'Very hot!');
      expect(alert.severity, ContextSeverity.critical);
    });
  });

  group('ContextAlertType enum', () {
    test('has all expected values', () {
      expect(ContextAlertType.values, containsAll([
        ContextAlertType.heatStroke,
        ContextAlertType.hypothermia,
        ContextAlertType.drowsyDriving,
        ContextAlertType.loneNightWalk,
        ContextAlertType.altitudeSickness,
        ContextAlertType.flashFloodRisk,
      ]));
    });
  });

  group('ContextSeverity enum', () {
    test('has all expected values', () {
      expect(ContextSeverity.values, containsAll([
        ContextSeverity.info,
        ContextSeverity.warning,
        ContextSeverity.critical,
      ]));
    });
  });

  group('Wind chill calculation', () {
    test('returns raw temp when wind is less than 5 km/h', () {
      final result = ContextAlertService.calculateWindChillForTest(-10, 3);
      expect(result, -10.0);
    });

    test('wind chill is lower than raw temp at high wind', () {
      const raw = -10.0;
      final result = ContextAlertService.calculateWindChillForTest(raw, 30);
      // Wind chill should make it feel colder.
      expect(result, lessThan(raw));
    });
  });

  group('mapToAlertType canonical mapping', () {
    test('covers all ContextAlertType values', () {
      for (final type in ContextAlertType.values) {
        expect(
          () => ContextAlertService.mapToAlertType(type),
          returnsNormally,
          reason: 'mapToAlertType should handle $type',
        );
      }
    });

    test('maps heatStroke correctly', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.heatStroke),
        AlertType.heatStroke,
      );
    });

    test('maps loneNightWalk to suspiciousActivity', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.loneNightWalk),
        AlertType.suspiciousActivity,
      );
    });

    test('maps altitudeSickness to altitudeSickness', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.altitudeSickness),
        AlertType.altitudeSickness,
      );
    });

    test('maps flashFloodRisk to flood', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.flashFloodRisk),
        AlertType.flood,
      );
    });
  });
}
