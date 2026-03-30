import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/context_alert_service.dart';

void main() {
  // ─────────────────────────── mapToAlertType ───────────────────────────────
  group('ContextAlertService.mapToAlertType', () {
    test('heatStroke maps to AlertType.heatStroke', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.heatStroke),
        AlertType.heatStroke,
      );
    });

    test('hypothermia maps to AlertType.hypothermia', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.hypothermia),
        AlertType.hypothermia,
      );
    });

    test('drowsyDriving maps to AlertType.drowsyDriving', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.drowsyDriving),
        AlertType.drowsyDriving,
      );
    });

    test('flashFloodRisk maps to AlertType.flood', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.flashFloodRisk),
        AlertType.flood,
      );
    });

    test('loneNightWalk maps to AlertType.suspiciousActivity', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.loneNightWalk),
        AlertType.suspiciousActivity,
      );
    });

    test('altitudeSickness maps to AlertType.altitudeSickness', () {
      expect(
        ContextAlertService.mapToAlertType(ContextAlertType.altitudeSickness),
        AlertType.altitudeSickness,
      );
    });
  });

  // ────────────────────── Observable state exposure ─────────────────────────
  group('ContextAlertService — observable state', () {
    test('temperature state sets correctly', () {
      final svc = ContextAlertService(checkIntervalMinutes: 999);
      svc.currentTemperatureCelsius = 38.0;
      expect(svc.currentTemperatureCelsius, 38.0);
      svc.dispose();
    });

    test('speed state sets correctly', () {
      final svc = ContextAlertService(checkIntervalMinutes: 999);
      svc.currentSpeedKmh = 80.0;
      expect(svc.currentSpeedKmh, 80.0);
      svc.dispose();
    });

    test('precipitation state sets correctly', () {
      final svc = ContextAlertService(checkIntervalMinutes: 999);
      svc.currentPrecipitationMm = 35.0;
      expect(svc.currentPrecipitationMm, 35.0);
      svc.dispose();
    });

    test('start() and stop() do not throw', () {
      final svc = ContextAlertService(checkIntervalMinutes: 999);
      expect(() {
        svc.start(onContextAlert: (_) {});
        svc.stop();
      }, returnsNormally);
    });

    test('dispose() is idempotent', () {
      final svc = ContextAlertService(checkIntervalMinutes: 999);
      expect(() {
        svc.dispose();
        svc.dispose();
      }, returnsNormally);
    });
  });

  // ───────────────── ContextAlertType enum coverage ─────────────────────────
  group('ContextAlertType — all values map without error', () {
    test('every ContextAlertType value maps to a valid AlertType', () {
      for (final type in ContextAlertType.values) {
        expect(
          () => ContextAlertService.mapToAlertType(type),
          returnsNormally,
        );
      }
    });
  });
}
