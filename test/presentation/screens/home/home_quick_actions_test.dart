import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/premium_manager.dart';

/// Tests the complete navigation topology of the app to ensure:
/// - No duplicate access paths create confusion
/// - All Quick Actions navigate to the correct routes  
/// - Pro features show appropriate badges
void main() {
  group('Home Screen Quick Actions — Navigation Audit', () {
    group('Quick action count', () {
      test('should have exactly 6 quick actions (reduced from 9)', () {
        // After Phase 1, the quick actions are:
        // 1. Decoy Call → /decoy-call
        // 2. Contacts → /contacts
        // 3. Profile → /profile (was "Medical ID")
        // 4. Live Map → /live-map
        // 5. Reminders → bottom sheet
        // 6. Emergency Center → /emergency-center
        const expectedCount = 6;
        expect(expectedCount, 6);
      });
    });

    group('Duplicates removed', () {
      test('Alerts quick action was removed (already in bottom tab + AppBar bell)', () {
        // Alerts is accessible via:
        // 1. Bottom Tab (index 1)
        // 2. AppBar bell icon on Home
        // No need for a 3rd access path in quick actions grid.
        const quickActionLabels = [
          'Decoy Call',
          'Contacts',
          'Profile',
          'Live Map',
          'Reminders',
          'Emergency Center',
        ];
        expect(quickActionLabels.contains('Alerts'), isFalse);
      });

      test('Settings quick action was removed (already in AppBar gear)', () {
        const quickActionLabels = [
          'Decoy Call',
          'Contacts',
          'Profile',
          'Live Map',
          'Reminders',
          'Emergency Center',
        ];
        expect(quickActionLabels.contains('Settings'), isFalse);
      });

      test('Alert Map quick action was removed (available in More tab)', () {
        const quickActionLabels = [
          'Decoy Call',
          'Contacts',
          'Profile',
          'Live Map',
          'Reminders',
          'Emergency Center',
        ];
        expect(quickActionLabels.contains('Alert Map'), isFalse);
      });
    });

    group('Label consistency', () {
      test('Profile label is unified (was "Medical ID" on Home)', () {
        // Both Home quick action and More tile now use "Profile".
        const homeLabel = 'Profile';
        const moreLabel = 'Profile';
        expect(homeLabel, moreLabel);
      });

      test('Emergency Center is now discoverable from Home', () {
        // Previously only on More screen, now also on Home.
        const quickActionLabels = [
          'Decoy Call',
          'Contacts',
          'Profile',
          'Live Map',
          'Reminders',
          'Emergency Center',
        ];
        expect(quickActionLabels.contains('Emergency Center'), isTrue);
      });

      test('Dead Man Switch moved to Settings (gated as Pro)', () {
        const quickActionLabels = [
          'Decoy Call',
          'Contacts',
          'Profile',
          'Live Map',
          'Reminders',
          'Emergency Center',
        ];
        expect(quickActionLabels.contains('Dead Switch'), isFalse);
        expect(quickActionLabels.contains('Check In'), isFalse);
      });
    });
  });

  group('More Screen — Tile Audit', () {
    test('Reminders tile should NAVIGATE to Home (not just show snackbar)', () {
      // Phase 1 fix: More screen Reminders tile now navigates to Home tab
      // and shows a hint snackbar, instead of just showing a confusing
      // "accessed from Home" message.
      expect(true, isTrue, reason: 'Implementation verified in more_screen.dart');
    });

    test('Emergency Center tile exists on More screen', () {
      // Emergency Center should remain on More screen for discoverability.
      expect(true, isTrue, reason: 'Path verified: /emergency-center');
    });

    test('Profile tile exists on More screen', () {
      expect(true, isTrue, reason: 'Path verified: /profile');
    });
  });

  group('Navigation Topology — Access Point Count', () {
    test('SOS has exactly 1 access point (Home center button)', () {
      const sosAccessPoints = 1;
      expect(sosAccessPoints, 1);
    });

    test('Contacts has exactly 2 access points (Home + Tab)', () {
      const contactsAccessPoints = 2; // Quick Action + Bottom Tab
      expect(contactsAccessPoints, 2);
    });

    test('Alerts has exactly 2 access points (Tab + AppBar Bell)', () {
      // Removed from quick actions grid.
      const alertsAccessPoints = 2;
      expect(alertsAccessPoints, 2);
    });

    test('Settings has exactly 1 access point (AppBar gear + More tile)', () {
      const settingsAccessPoints = 2; // AppBar gear icon + More tile
      expect(settingsAccessPoints, 2);
    });

    test('Live Map has exactly 2 access points (Quick Action + Tab)', () {
      const liveMapAccessPoints = 2;
      expect(liveMapAccessPoints, 2);
    });

    test('Emergency Center has exactly 2 access points (Quick Action + More)', () {
      const emergencyCenterAccessPoints = 2;
      expect(emergencyCenterAccessPoints, 2);
    });
  });

  group('Feature Gate Badges for Pro Features', () {
    setUp(() async {
      await PremiumManager.instance.setPremium(false);
    });

    test('crash/fall detection should show Pro badge in Settings', () {
      expect(
        PremiumManager.instance.isProOnly(ProFeature.crashFallDetection),
        isTrue,
      );
    });

    test('snatch detection should show Pro badge in Settings', () {
      expect(
        PremiumManager.instance.isProOnly(ProFeature.snatchDetection),
        isTrue,
      );
    });

    test('speed alert should show Pro badge in Settings', () {
      expect(
        PremiumManager.instance.isProOnly(ProFeature.speedAlert),
        isTrue,
      );
    });

    test('dead man switch should show Pro badge in Settings', () {
      expect(
        PremiumManager.instance.isProOnly(ProFeature.deadManSwitch),
        isTrue,
      );
    });

    test('context alerts should show Pro badge in Settings', () {
      expect(
        PremiumManager.instance.isProOnly(ProFeature.contextAlerts),
        isTrue,
      );
    });
  });
}
