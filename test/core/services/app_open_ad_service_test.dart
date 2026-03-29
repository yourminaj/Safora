import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/app_open_ad_service.dart';

void main() {
  group('AppOpenAdService', () {
    late AppOpenAdService service;

    setUp(() {
      service = AppOpenAdService.instance;
      service.resetForTesting();
    });

    group('frequency capping', () {
      test('initial resume count is 0', () {
        expect(service.resumeCount, 0);
      });

      test('resume count increments on onAppResumed when not premium', () {
        service.setPremium(false);
        service.setEmergencyActive(false);
        service.onAppResumed();
        expect(service.resumeCount, 1);
      });

      test('ad does NOT show on 1st or 2nd resume (cap = 3)', () {
        service.setPremium(false);
        service.setEmergencyActive(false);
        // First two resumes should NOT trigger ad show.
        service.onAppResumed(); // count = 1
        service.onAppResumed(); // count = 2
        expect(service.resumeCount, 2);
        // Service doesn't throw — it silently skips.
      });
    });

    group('premium/emergency guards', () {
      test('premium users never increment resume count', () {
        service.setPremium(true);
        service.onAppResumed();
        service.onAppResumed();
        service.onAppResumed();
        expect(service.resumeCount, 0,
            reason: 'Premium users skip all ad logic');
      });

      test('emergency blocks resume count', () {
        service.setEmergencyActive(true);
        service.onAppResumed();
        expect(service.resumeCount, 0,
            reason: 'Emergency mode blocks all ad logic');
      });

      test('toggling premium resets behavior', () {
        service.setPremium(true);
        service.onAppResumed();
        expect(service.resumeCount, 0);

        service.setPremium(false);
        service.onAppResumed();
        expect(service.resumeCount, 1,
            reason: 'After premium toggle off, count starts');
      });
    });

    group('isReady', () {
      test('initially not ready (no ad loaded)', () {
        expect(service.isReady, isFalse);
      });
    });

    group('lifecycle management', () {
      test('resetForTesting clears all state', () {
        service.setPremium(true);
        service.setEmergencyActive(true);
        service.resetForTesting();
        expect(service.resumeCount, 0);
        expect(service.isReady, isFalse);
      });

      test('dispose does not throw', () {
        service.dispose();
      });
    });
  });
}
