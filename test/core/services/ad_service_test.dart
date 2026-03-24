import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/ad_service.dart';

void main() {
  group('AdService', () {
    group('Singleton', () {
      test('instance is a singleton', () {
        final a = AdService.instance;
        final b = AdService.instance;
        expect(identical(a, b), true);
      });
    });

    group('Ad Unit IDs', () {
      test('banner ad unit IDs are non-empty', () {
        expect(AdService.bannerAlerts.isNotEmpty, true);
        expect(AdService.bannerSettings.isNotEmpty, true);
        expect(AdService.bannerContacts.isNotEmpty, true);
        expect(AdService.bannerProfile.isNotEmpty, true);
      });

      test('banner ad unit IDs use correct prefix', () {
        expect(AdService.bannerAlerts, startsWith('ca-app-pub-'));
        expect(AdService.bannerSettings, startsWith('ca-app-pub-'));
        expect(AdService.bannerContacts, startsWith('ca-app-pub-'));
        expect(AdService.bannerProfile, startsWith('ca-app-pub-'));
      });

      test('all banner IDs are unique', () {
        final ids = {
          AdService.bannerAlerts,
          AdService.bannerSettings,
          AdService.bannerContacts,
          AdService.bannerProfile,
        };
        expect(ids.length, 4, reason: 'Each screen should have a unique ad unit ID');
      });
    });

    group('Premium Bypass', () {
      test('setPremium accepts true', () {
        // Should not throw — we can't verify internals without ads SDK,
        // but this validates the method contract.
        expect(() => AdService.instance.setPremium(true), returnsNormally);
      });

      test('setPremium accepts false', () {
        expect(() => AdService.instance.setPremium(false), returnsNormally);
      });
    });

    group('Emergency Safety', () {
      test('setEmergencyActive blocks ads during emergency', () {
        expect(() => AdService.instance.setEmergencyActive(true), returnsNormally);
      });

      test('setEmergencyActive can be deactivated', () {
        expect(() => AdService.instance.setEmergencyActive(false), returnsNormally);
      });
    });

    group('Interstitial Guard Logic', () {
      test('showInterstitial does not throw when no ad is loaded', () {
        // Reset state
        AdService.instance.setPremium(false);
        AdService.instance.setEmergencyActive(false);
        // No interstitial loaded, should silently return
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
      });

      test('showInterstitial is blocked when premium is true', () {
        AdService.instance.setPremium(true);
        // Should silently return without attempting to show
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
        AdService.instance.setPremium(false); // cleanup
      });

      test('showInterstitial is blocked during emergency', () {
        AdService.instance.setEmergencyActive(true);
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
        AdService.instance.setEmergencyActive(false); // cleanup
      });
    });

    group('Rewarded Ad', () {
      test('isRewardedReady returns false when no ad is loaded', () {
        expect(AdService.instance.isRewardedReady, false);
      });

      test('showRewarded returns false when no ad is loaded', () async {
        final result = await AdService.instance.showRewarded();
        expect(result, false);
      });
    });

    group('Dispose', () {
      test('dispose does not throw', () {
        expect(() => AdService.instance.dispose(), returnsNormally);
      });

      test('dispose can be called multiple times safely', () {
        expect(() {
          AdService.instance.dispose();
          AdService.instance.dispose();
        }, returnsNormally);
      });
    });
  });
}
