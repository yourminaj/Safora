import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:safora/core/services/premium_manager.dart';

void main() {
  late Box appSettingsBox;

  setUpAll(() async {
    Hive.init('/tmp/premium_manager_test_hive');
    appSettingsBox = await Hive.openBox('app_settings');
  });

  setUp(() async {
    await appSettingsBox.clear();
    // Reset singleton state.
    await PremiumManager.instance.setPremium(false);
  });

  tearDownAll(() async {
    await appSettingsBox.close();
    await Hive.close();
  });

  group('PremiumManager', () {
    group('initialization', () {
      test('defaults to free tier', () async {
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isFalse);
      });

      test('loads persisted premium state', () async {
        await appSettingsBox.put('is_premium', true);
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isTrue);
      });

      test('init with false in Hive stays free', () async {
        await appSettingsBox.put('is_premium', false);
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isFalse);
      });
    });

    group('setPremium', () {
      test('persists premium state to Hive', () async {
        await PremiumManager.instance.setPremium(true);
        expect(appSettingsBox.get('is_premium'), isTrue);
        expect(PremiumManager.instance.isPremium, isTrue);
      });

      test('can revert to free', () async {
        await PremiumManager.instance.setPremium(true);
        await PremiumManager.instance.setPremium(false);
        expect(appSettingsBox.get('is_premium'), isFalse);
        expect(PremiumManager.instance.isPremium, isFalse);
      });

      test('cascades to ad services without error', () async {
        // If cascade failed, AdService/AppOpenAdService.setPremium would throw
        await PremiumManager.instance.setPremium(true);
        expect(PremiumManager.instance.isPremium, isTrue);

        await PremiumManager.instance.setPremium(false);
        expect(PremiumManager.instance.isPremium, isFalse);
      });
    });

    group('feature gates — free tier (ads shown)', () {
      setUp(() async {
        await PremiumManager.instance.setPremium(false);
      });

      test('SOS is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.sos),
          isTrue,
        );
      });

      test('Shake-SOS is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.shakeSos),
          isTrue,
        );
      });

      test('Decoy Call is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.decoyCall),
          isTrue,
        );
      });

      test('App Lock is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.appLock),
          isTrue,
        );
      });

      test('Basic Alerts are always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.basicAlerts),
          isTrue,
        );
      });

      test('Live Map is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.liveMap),
          isTrue,
        );
      });

      test('Emergency Center is always available', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.emergencyCenter),
          isTrue,
        );
      });

      test('Alert Map is always available', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.alertMap),
          isTrue,
        );
      });

      test('crash/fall detection is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isFalse,
        );
      });

      test('snatch detection is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.snatchDetection),
          isFalse,
        );
      });

      test('speed alert is LOCKED for free users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.speedAlert),
          isFalse,
        );
      });

      test('context alerts are LOCKED for free users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.contextAlerts),
          isFalse,
        );
      });

      test('dead man switch is LOCKED for free users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.deadManSwitch),
          isFalse,
        );
      });

      test('unlimited contacts is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedContacts),
          isFalse,
        );
      });

      test('unlimited reminders is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedReminders),
          isFalse,
        );
      });

      test('unlimited geofence zones is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.unlimitedGeofenceZones),
          isFalse,
        );
      });

      test('full SOS history is LOCKED for free users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.fullSosHistory),
          isFalse,
        );
      });

      test('ad-free is LOCKED for free users (they see ads)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isFalse,
        );
      });
    });

    group('feature gates — pro tier (paid, ad-free)', () {
      setUp(() async {
        await PremiumManager.instance.setPremium(true);
      });

      test('all free features remain available for pro', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.sos),
          isTrue,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.decoyCall),
          isTrue,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.appLock),
          isTrue,
        );
      });

      test('crash/fall detection is AVAILABLE for pro users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isTrue,
        );
      });

      test('snatch detection is AVAILABLE for pro users', () {
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.snatchDetection),
          isTrue,
        );
      });

      test('speed alert is AVAILABLE for pro users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.speedAlert),
          isTrue,
        );
      });

      test('context alerts is AVAILABLE for pro users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.contextAlerts),
          isTrue,
        );
      });

      test('dead man switch is AVAILABLE for pro users', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.deadManSwitch),
          isTrue,
        );
      });

      test('ad-free is AVAILABLE for pro users (no ads)', () {
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isTrue,
        );
      });

      test('all pro features available after purchase', () {
        for (final feature in ProFeature.values) {
          expect(
            PremiumManager.instance.isFeatureAvailable(feature),
            isTrue,
            reason: '$feature should be available for pro',
          );
        }
      });
    });

    group('isProOnly', () {
      test('SOS is NOT pro-only', () {
        expect(PremiumManager.instance.isProOnly(ProFeature.sos), isFalse);
      });

      test('crash/fall detection IS pro-only', () {
        expect(
          PremiumManager.instance.isProOnly(ProFeature.crashFallDetection),
          isTrue,
        );
      });

      test('ad-free IS pro-only', () {
        expect(PremiumManager.instance.isProOnly(ProFeature.adFree), isTrue);
      });
    });

    group('tier limits — free user (ads shown)', () {
      setUp(() async {
        await PremiumManager.instance.setPremium(false);
      });

      test('free user gets limited contacts (3)', () {
        expect(PremiumManager.instance.contactLimit, 3);
      });

      test('free user gets limited reminders (2)', () {
        expect(PremiumManager.instance.reminderLimit, 2);
      });

      test('free user gets limited geofence zones (1)', () {
        expect(PremiumManager.instance.geofenceLimit, 1);
      });

      test('free user gets 7-day history retention', () {
        expect(PremiumManager.instance.historyRetentionDays, 7);
      });
    });

    group('tier limits — pro user (paid, ad-free)', () {
      setUp(() async {
        await PremiumManager.instance.setPremium(true);
      });

      test('pro user gets unlimited contacts', () {
        expect(PremiumManager.instance.contactLimit, 999);
      });

      test('pro user gets unlimited reminders', () {
        expect(PremiumManager.instance.reminderLimit, 999);
      });

      test('pro user gets unlimited geofence zones', () {
        expect(PremiumManager.instance.geofenceLimit, 999);
      });

      test('pro user gets 365-day history retention', () {
        expect(PremiumManager.instance.historyRetentionDays, 365);
      });
    });

    group('static constants', () {
      test('free contact limit is 3', () {
        expect(PremiumManager.freeContactLimit, 3);
      });

      test('free reminder limit is 2', () {
        expect(PremiumManager.freeReminderLimit, 2);
      });

      test('free geofence limit is 1', () {
        expect(PremiumManager.freeGeofenceLimit, 1);
      });

      test('free history retention is 7 days', () {
        expect(PremiumManager.freeHistoryDays, 7);
      });
    });

    group('full lifecycle', () {
      test('free user has limited features and sees ads', () {
        expect(PremiumManager.instance.isPremium, isFalse);
        expect(PremiumManager.instance.contactLimit, 3);
        expect(PremiumManager.instance.reminderLimit, 2);
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isFalse,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isFalse,
        );
      });

      test('free → purchase pro → all unlocked + ad-free', () async {
        expect(PremiumManager.instance.isPremium, isFalse);
        await PremiumManager.instance.setPremium(true);
        expect(PremiumManager.instance.isPremium, isTrue);
        expect(PremiumManager.instance.contactLimit, 999);
        expect(PremiumManager.instance.reminderLimit, 999);
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isTrue,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isTrue,
        );
      });

      test('pro → cancel subscription → back to free with ads', () async {
        await PremiumManager.instance.setPremium(true);
        await PremiumManager.instance.setPremium(false);

        // Pro features locked
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.crashFallDetection),
          isFalse,
        );
        expect(
          PremiumManager.instance
              .isFeatureAvailable(ProFeature.snatchDetection),
          isFalse,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.adFree),
          isFalse,
        );

        // Free features still work
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.sos),
          isTrue,
        );
        expect(
          PremiumManager.instance.isFeatureAvailable(ProFeature.decoyCall),
          isTrue,
        );

        // Limits restored to free
        expect(PremiumManager.instance.contactLimit, 3);
        expect(PremiumManager.instance.reminderLimit, 2);
      });

      test('premium state persists across init', () async {
        await PremiumManager.instance.setPremium(true);
        // Re-init (simulates app restart)
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isTrue);
        expect(PremiumManager.instance.contactLimit, 999);
      });

      test('free state persists across init', () async {
        await PremiumManager.instance.setPremium(false);
        await PremiumManager.instance.init();
        expect(PremiumManager.instance.isPremium, isFalse);
        expect(PremiumManager.instance.contactLimit, 3);
      });
    });
  });
}
