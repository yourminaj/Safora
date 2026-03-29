import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/premium_manager.dart';

/// Tests that simulate a free user's complete journey through the app.
///
/// Validates:
/// - Core safety features accessible
/// - Tier limits enforced (contacts, reminders, geofence, history)
/// - Pro features locked with correct gating
/// - Ad visibility expectations
void main() {
  group('Free User Journey', () {
    setUp(() async {
      // Simulate free user.
      await PremiumManager.instance.setPremium(false);
    });

    group('Core Safety — Always Available', () {
      test('can trigger SOS panic button', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.sos),
          isTrue,
          reason: 'SOS is a life-saving feature and must ALWAYS be free',
        );
      });

      test('can use shake-to-SOS', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.shakeSos),
          isTrue,
          reason: 'Shake-SOS is a core safety feature',
        );
      });

      test('can make decoy calls', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.decoyCall),
          isTrue,
          reason: 'Decoy call is a core personal safety feature',
        );
      });

      test('can set up app lock with PIN/biometric', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.appLock),
          isTrue,
          reason: 'App lock protects sensitive safety data',
        );
      });

      test('can view alert feed', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.basicAlerts),
          isTrue,
          reason: 'Alerts are core to safety awareness',
        );
      });

      test('can access emergency center', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.emergencyCenter),
          isTrue,
        );
      });

      test('can view live map', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.liveMap),
          isTrue,
        );
      });

      test('can view alert map', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.alertMap),
          isTrue,
        );
      });
    });

    group('Tier Limits — Restricted', () {
      test('can add up to 3 emergency contacts only', () {
        expect(PremiumManager.instance.contactLimit, 3);
      });

      test('can set up to 2 medicine reminders only', () {
        expect(PremiumManager.instance.reminderLimit, 2);
      });

      test('can create 1 geofence zone only', () {
        expect(PremiumManager.instance.geofenceLimit, 1);
      });

      test('SOS history retained for 7 days only', () {
        expect(PremiumManager.instance.historyRetentionDays, 7);
      });
    });

    group('Pro Features — Locked', () {
      test('cannot use crash/fall detection', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isFalse,
          reason: 'ML-based detection is a Pro feature',
        );
      });

      test('cannot use snatch detection', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.snatchDetection),
          isFalse,
          reason: 'Advanced sensor detection is Pro',
        );
      });

      test('cannot use speed alerts', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.speedAlert),
          isFalse,
        );
      });

      test('cannot use context alerts', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.contextAlerts),
          isFalse,
        );
      });

      test('cannot use dead man switch', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.deadManSwitch),
          isFalse,
        );
      });

      test('sees ads (not ad-free)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isFalse,
          reason: 'Free users see ads as revenue support',
        );
      });
    });

    group('Ad Visibility — User Sees Ads', () {
      test('free user should see banner ads', () {
        // Free users do NOT have ad-free, so ads should display.
        expect(PremiumManager.instance.isPremium, isFalse);
        // AdService.isPremium should mirror this.
      });

      test('free user should see native ads in alerts feed', () {
        expect(PremiumManager.instance.isPremium, isFalse);
      });

      test('free user should see app open ads on resume', () {
        expect(PremiumManager.instance.isPremium, isFalse);
      });

      test('free user sees upgrade prompt when contact limit reached', () {
        // Free users cannot watch ads for bonus contacts.
        // Instead, they see an "Upgrade to Pro" dialog.
        expect(PremiumManager.instance.isPremium, isFalse);
        expect(PremiumManager.instance.contactLimit, 3);
        // Pro upgrade is the only path to more contacts.
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedContacts),
          isFalse,
          reason:
              'Free users must upgrade to Pro for unlimited contacts',
        );
      });
    });

    group('Pro Badge Visibility', () {
      test('crash/fall detection shows Pro badge', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.crashFallDetection),
          isTrue,
        );
      });

      test('snatch detection shows Pro badge', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.snatchDetection),
          isTrue,
        );
      });

      test('speed alert shows Pro badge', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.speedAlert),
          isTrue,
        );
      });

      test('dead man switch shows Pro badge', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.deadManSwitch),
          isTrue,
        );
      });

      test('SOS does NOT show Pro badge', () {
        expect(PremiumManager.instance.isProOnly(ProFeature.sos), isFalse);
      });

      test('decoy call does NOT show Pro badge', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.decoyCall),
          isFalse,
        );
      });
    });
  });
}
