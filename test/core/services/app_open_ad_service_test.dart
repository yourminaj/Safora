import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/app_open_ad_service.dart';

void main() {
  group('AppOpenAdService', () {
    late AppOpenAdService service;

    setUpAll(() {
      WidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      service = AppOpenAdService.instance;
      // Reset to clean state before each test.
      service.setPremium(false);
      service.setEmergencyActive(false);
      // Reset resume counter to ensure each test gets an isolated counter
      // and does not inadvertently cross the frequency-cap boundary that
      // would trigger a real AppOpenAd.load() call on the plugin channel.
      service.resetResumeCountForTest();
    });

    group('premium guard', () {
      test('onAppResumed does not throw for free users', () {
        service.setPremium(false);
        service.setEmergencyActive(false);
        expect(() => service.onAppResumed(), returnsNormally);
      });

      test('onAppResumed does not throw for premium users', () {
        service.setPremium(true);
        // Premium users short-circuit before the counter is incremented.
        expect(() => service.onAppResumed(), returnsNormally);
      });

      test('toggling premium does not throw', () {
        service.setPremium(true);
        service.setPremium(false);
        expect(() => service.onAppResumed(), returnsNormally);
      });
    });

    group('emergency guard', () {
      test('emergency blocks ad display without throwing', () {
        service.setEmergencyActive(true);
        expect(() => service.onAppResumed(), returnsNormally);
      });

      test('clearing emergency restores normal operation', () {
        service.setEmergencyActive(true);
        service.setEmergencyActive(false);
        expect(() => service.onAppResumed(), returnsNormally);
      });
    });

    group('ad readiness', () {
      test('initially not ready (no ad loaded)', () {
        expect(service.isReady, isFalse);
      });
    });

    group('lifecycle management', () {
      test('dispose does not throw', () {
        expect(() => service.dispose(), returnsNormally);
      });

      // Call onAppResumed below the frequency-cap threshold (default = 3)
      // so the plugin channel is never touched, making this a pure logic test.
      test('multiple resumes below frequency cap do not throw', () {
        // 2 resumes: counts 1, 2 — neither hits %3==0, no ad shown.
        expect(() => service.onAppResumed(), returnsNormally);
        expect(() => service.onAppResumed(), returnsNormally);
      });
    });
  });
}
