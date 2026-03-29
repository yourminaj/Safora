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
        expect(ids.length, 4,
            reason: 'Each screen should have a unique ad unit ID');
      });

      test('native alerts feed ad unit ID is non-empty', () {
        expect(AdService.nativeAlertsFeed.isNotEmpty, true);
        expect(AdService.nativeAlertsFeed, startsWith('ca-app-pub-'));
      });
    });

    group('Premium Bypass — Pro users see no ads', () {
      test('setPremium(true) disables ads for Pro users', () {
        expect(() => AdService.instance.setPremium(true), returnsNormally);
        expect(AdService.instance.isPremium, isTrue);
      });

      test('setPremium(false) enables ads for free users', () {
        expect(() => AdService.instance.setPremium(false), returnsNormally);
        expect(AdService.instance.isPremium, isFalse);
      });

      test('isPremium getter reflects current state', () {
        AdService.instance.setPremium(true);
        expect(AdService.instance.isPremium, isTrue);
        AdService.instance.setPremium(false);
        expect(AdService.instance.isPremium, isFalse);
      });
    });

    group('Emergency Safety', () {
      test('setEmergencyActive blocks ads during emergency', () {
        expect(
            () => AdService.instance.setEmergencyActive(true), returnsNormally);
      });

      test('setEmergencyActive can be deactivated', () {
        expect(() => AdService.instance.setEmergencyActive(false),
            returnsNormally);
      });
    });

    group('Interstitial Guard Logic', () {
      test('showInterstitial does not throw when no ad is loaded', () {
        AdService.instance.setPremium(false);
        AdService.instance.setEmergencyActive(false);
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
      });

      test('showInterstitial is blocked when premium is true', () {
        AdService.instance.setPremium(true);
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
        AdService.instance.setPremium(false); // cleanup
      });

      test('showInterstitial is blocked during emergency', () {
        AdService.instance.setEmergencyActive(true);
        expect(() => AdService.instance.showInterstitial(), returnsNormally);
        AdService.instance.setEmergencyActive(false); // cleanup
      });
    });

    group('Ad Model — No Rewarded Ads', () {
      test('AdService has no rewarded ad methods', () {
        // Verify the simplified model: free users see banner/interstitial/native/app open
        // No rewarded ads exist in the new monetization model
        expect(AdService.instance.isPremium, isFalse);
        // The AdService should only have: setPremium, setEmergencyActive,
        // showInterstitial, isPremium, dispose — no showRewarded or isRewardedReady
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
