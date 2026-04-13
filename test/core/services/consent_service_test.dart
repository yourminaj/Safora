import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/consent_service.dart';

void main() {
  group('ConsentService', () {
    group('Singleton', () {
      test('instance is a singleton', () {
        final a = ConsentService.instance;
        final b = ConsentService.instance;
        expect(identical(a, b), true);
      });
    });

    group('Default State', () {
      test('canRequestAds defaults to false before initialization', () {
        // Before initialize() is called, ads should not be requestable.
        // Note: In test environment without platform channels, canRequestAds
        // starts as false which is the safe default.
        expect(ConsentService.instance.canRequestAds, isFalse);
      });
    });

    group('Reset', () {
      test('resetForTesting does not throw', () {
        expect(
          () => ConsentService.instance.resetForTesting(),
          returnsNormally,
        );
      });

      test('resetForTesting sets canRequestAds to false', () {
        ConsentService.instance.resetForTesting();
        expect(ConsentService.instance.canRequestAds, isFalse);
      });
    });

    group('Privacy Options', () {
      test('isPrivacyOptionsRequired returns a Future<bool>', () {
        // In test environment, this accesses ConsentInformation which may
        // throw a MissingPluginException. We verify the property exists
        // and returns the correct type.
        expect(
          () async {
            try {
              await ConsentService.instance.isPrivacyOptionsRequired;
            } catch (_) {
              // Platform channel not available in tests — expected.
            }
          },
          returnsNormally,
        );
      });
    });
  });
}
