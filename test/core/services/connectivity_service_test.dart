import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Initial State', () {
      test('isOnline defaults to true', () {
        expect(service.isOnline, true);
      });
    });

    group('Monitoring Lifecycle', () {
      test('stopMonitoring does not throw when not started', () {
        expect(() => service.stopMonitoring(), returnsNormally);
      });

      test('stopMonitoring is idempotent', () {
        service.stopMonitoring();
        service.stopMonitoring();
        expect(() => service.stopMonitoring(), returnsNormally);
      });
    });

    group('Dispose', () {
      test('dispose does not throw', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('dispose can be called multiple times', () {
        service.dispose();
        expect(() => service.dispose(), returnsNormally);
      });

      test('state remains accessible after dispose', () {
        service.dispose();
        // Should still be able to read state after dispose
        expect(service.isOnline, isA<bool>());
      });
    });

    group('Multiple Instances', () {
      test('instances are independent', () {
        final a = ConnectivityService();
        final b = ConnectivityService();
        // Both default to online
        expect(a.isOnline, true);
        expect(b.isOnline, true);
        a.dispose();
        b.dispose();
      });
    });
  });
}
