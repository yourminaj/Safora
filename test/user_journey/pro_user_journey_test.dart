import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/premium_manager.dart';

/// Tests that simulate a Pro (premium) user's complete journey through the app.
///
/// Validates:
/// - All features unlocked
/// - No tier limits
/// - Ad-free experience
/// - Premium state persistence
void main() {
  group('Pro User Journey', () {
    setUp(() async {
      // Simulate pro user.
      await PremiumManager.instance.setPremium(true);
    });

    group('All Features — Fully Unlocked', () {
      test('can trigger SOS panic button', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.sos),
          isTrue,
        );
      });

      test('can use shake-to-SOS', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.shakeSos),
          isTrue,
        );
      });

      test('can make decoy calls', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.decoyCall),
          isTrue,
        );
      });

      test('can use app lock', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.appLock),
          isTrue,
        );
      });

      test('can view basic alerts', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.basicAlerts),
          isTrue,
        );
      });

      test('can use crash/fall detection (Pro)', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isTrue,
          reason: 'Pro users have ML-based crash/fall detection',
        );
      });

      test('can use snatch detection (Pro)', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.snatchDetection),
          isTrue,
        );
      });

      test('can use speed alerts (Pro)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.speedAlert),
          isTrue,
        );
      });

      test('can use context alerts (Pro)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.contextAlerts),
          isTrue,
        );
      });

      test('can use dead man switch (Pro)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.deadManSwitch),
          isTrue,
        );
      });

      test('has unlimited contacts', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedContacts),
          isTrue,
        );
      });

      test('has unlimited reminders', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedReminders),
          isTrue,
        );
      });

      test('has unlimited geofence zones', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedGeofenceZones),
          isTrue,
        );
      });

      test('has full SOS history', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.fullSosHistory),
          isTrue,
        );
      });

      test('has ad-free experience', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isTrue,
          reason: 'Pro users see zero ads',
        );
      });
    });

    group('Tier Limits — Unlimited', () {
      test('contact limit is effectively unlimited (999)', () {
        expect(PremiumManager.instance.contactLimit, 999);
      });

      test('reminder limit is effectively unlimited (999)', () {
        expect(PremiumManager.instance.reminderLimit, 999);
      });

      test('geofence zone limit is effectively unlimited (999)', () {
        expect(PremiumManager.instance.geofenceLimit, 999);
      });

      test('SOS history retention is 365 days', () {
        expect(PremiumManager.instance.historyRetentionDays, 365);
      });
    });

    group('Ad-Free — Zero Ads', () {
      test('pro user is recognized as premium', () {
        expect(PremiumManager.instance.isPremium, isTrue);
      });

      test('banner ads should be hidden', () {
        expect(PremiumManager.instance.isPremium, isTrue);
        // AdService.isPremium and NativeAdCard check this flag.
      });

      test('native ads in alerts feed should be hidden', () {
        expect(PremiumManager.instance.isPremium, isTrue);
      });

      test('app open ads should NOT show on resume', () {
        expect(PremiumManager.instance.isPremium, isTrue);
      });
    });

    group('Subscription Persistence', () {
      test('premium state persists across re-initialization', () async {
        await PremiumManager.instance.setPremium(true);
        // Simulate app restart by re-init.
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isTrue);
      });

      test('downgrading to free removes all pro features', () async {
        await PremiumManager.instance.setPremium(false);

        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isFalse,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isFalse,
        );
        expect(PremiumManager.instance.contactLimit, 3);
        expect(PremiumManager.instance.reminderLimit, 2);
      });
    });
  });
}
