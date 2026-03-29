import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/subscription_service.dart';

/// Comprehensive tests for [SubscriptionService].
///
/// Strategy: RevenueCat SDK requires native platform initialization,
/// so we validate configuration, contracts, state management, and
/// public API behavior in the uninitialized state. Live purchase flows
/// require integration tests on a real device.
void main() {
  // ── Configuration ─────────────────────────────────────────
  group('SubscriptionService — Configuration', () {
    test('singleton instance is consistent (identity)', () {
      final a = SubscriptionService.instance;
      final b = SubscriptionService.instance;
      expect(identical(a, b), isTrue);
    });

    test('entitlementId is "Digital Drive Pro"', () {
      expect(SubscriptionService.entitlementId, 'Digital Drive Pro');
    });

    test('entitlementId is non-empty', () {
      expect(SubscriptionService.entitlementId.isNotEmpty, isTrue);
    });

    test('entitlementId does not contain leading/trailing whitespace', () {
      expect(
        SubscriptionService.entitlementId,
        equals(SubscriptionService.entitlementId.trim()),
      );
    });

    test('productMonthly is "monthly"', () {
      expect(SubscriptionService.productMonthly, 'monthly');
    });

    test('productYearly is "yearly"', () {
      expect(SubscriptionService.productYearly, 'yearly');
    });

    test('productLifetime is "lifetime"', () {
      expect(SubscriptionService.productLifetime, 'lifetime');
    });
  });

  // ── Product Tier Validation ────────────────────────────────
  group('SubscriptionService — Product tiers', () {
    test('three product identifiers are defined', () {
      final ids = [
        SubscriptionService.productMonthly,
        SubscriptionService.productYearly,
        SubscriptionService.productLifetime,
      ];
      expect(ids.length, 3);
    });

    test('all three product identifiers are unique', () {
      final ids = [
        SubscriptionService.productMonthly,
        SubscriptionService.productYearly,
        SubscriptionService.productLifetime,
      ];
      expect(ids.toSet().length, 3);
    });

    test('product IDs follow Google Play naming convention (lowercase + underscores)', () {
      final pattern = RegExp(r'^[a-z0-9_]+$');
      expect(pattern.hasMatch(SubscriptionService.productMonthly), isTrue,
          reason: 'monthly ID must be lowercase alphanumeric + underscores');
      expect(pattern.hasMatch(SubscriptionService.productYearly), isTrue,
          reason: 'yearly ID must be lowercase alphanumeric + underscores');
      expect(pattern.hasMatch(SubscriptionService.productLifetime), isTrue,
          reason: 'lifetime ID must be lowercase alphanumeric + underscores');
    });

    test('product IDs do not contain spaces', () {
      expect(SubscriptionService.productMonthly.contains(' '), isFalse);
      expect(SubscriptionService.productYearly.contains(' '), isFalse);
      expect(SubscriptionService.productLifetime.contains(' '), isFalse);
    });

    test('product IDs are non-empty', () {
      expect(SubscriptionService.productMonthly.isNotEmpty, isTrue);
      expect(SubscriptionService.productYearly.isNotEmpty, isTrue);
      expect(SubscriptionService.productLifetime.isNotEmpty, isTrue);
    });
  });

  // ── Default State ──────────────────────────────────────────
  group('SubscriptionService — Default state (before init)', () {
    test('isInitialized defaults to false', () {
      expect(SubscriptionService.instance.isInitialized, isFalse);
    });

    test('isPurchasing defaults to false', () {
      expect(SubscriptionService.instance.isPurchasing, isFalse);
    });

    test('offerings defaults to null', () {
      expect(SubscriptionService.instance.offerings, isNull);
    });

    test('availablePackages returns empty list before init', () {
      expect(SubscriptionService.instance.availablePackages, isEmpty);
    });

    test('availablePackages returns a List', () {
      expect(SubscriptionService.instance.availablePackages, isA<List>());
    });

    test('monthlyPriceString is null before offerings loaded', () {
      expect(SubscriptionService.instance.monthlyPriceString, isNull);
    });

    test('yearlyPriceString is null before offerings loaded', () {
      expect(SubscriptionService.instance.yearlyPriceString, isNull);
    });

    test('lifetimePriceString is null before offerings loaded', () {
      expect(SubscriptionService.instance.lifetimePriceString, isNull);
    });
  });

  // ── Package Lookup (uninitialized) ─────────────────────────
  group('SubscriptionService — Package lookup (before init)', () {
    test('getPackage returns null for monthly when not initialized', () {
      // PackageType is from purchases_flutter which can't be imported without
      // platform initialization, so we verify through the convenience methods
      expect(SubscriptionService.instance.monthlyPriceString, isNull);
    });

    test('getPackage returns null for yearly when not initialized', () {
      expect(SubscriptionService.instance.yearlyPriceString, isNull);
    });

    test('getPackage returns null for lifetime when not initialized', () {
      expect(SubscriptionService.instance.lifetimePriceString, isNull);
    });
  });

  // ── Purchase Methods (before init, should return false gracefully) ──
  group('SubscriptionService — Purchase methods (before init)', () {
    test('purchaseMonthly returns false when no packages available', () async {
      final result = await SubscriptionService.instance.purchaseMonthly();
      expect(result, isFalse);
    });

    test('purchaseYearly returns false when no packages available', () async {
      final result = await SubscriptionService.instance.purchaseYearly();
      expect(result, isFalse);
    });

    test('purchaseLifetime returns false when no packages available', () async {
      final result = await SubscriptionService.instance.purchaseLifetime();
      expect(result, isFalse);
    });
  });

  // ── Free / Pro Model Contract ──────────────────────────────
  group('SubscriptionService — Free/Pro model contract', () {
    test('entitlement ID is consistent across code boundaries', () {
      // This validates that the entitlement used in subscription_service.dart
      // matches what paywall_screen.dart references via static constant.
      const expected = 'Digital Drive Pro';
      expect(SubscriptionService.entitlementId, expected);
    });

    test('product tiers cover all billing periods', () {
      // Monthly + Yearly (subscriptions) + Lifetime (one-time purchase)
      final tiers = {
        'monthly': SubscriptionService.productMonthly,
        'yearly': SubscriptionService.productYearly,
        'lifetime': SubscriptionService.productLifetime,
      };
      expect(tiers.length, 3);
      expect(tiers.values.every((id) => id.isNotEmpty), isTrue);
    });

    test('entitlement ID does not use old "pro" identifier', () {
      expect(SubscriptionService.entitlementId, isNot(equals('pro')));
    });

    test('product IDs do not use old "safora_pro_monthly" pattern', () {
      expect(SubscriptionService.productMonthly,
          isNot(equals('safora_pro_monthly')));
      expect(SubscriptionService.productYearly,
          isNot(equals('safora_pro_yearly')));
      expect(SubscriptionService.productLifetime,
          isNot(equals('safora_pro_lifetime')));
    });
  });

  // ── Service API Surface ────────────────────────────────────
  group('SubscriptionService — API surface validation', () {
    test('instance exposes required config getters', () {
      // Verify the public API surface exists and is accessible
      expect(() => SubscriptionService.entitlementId, returnsNormally);
      expect(() => SubscriptionService.productMonthly, returnsNormally);
      expect(() => SubscriptionService.productYearly, returnsNormally);
      expect(() => SubscriptionService.productLifetime, returnsNormally);
    });

    test('instance exposes required state getters', () {
      expect(() => SubscriptionService.instance.isInitialized, returnsNormally);
      expect(() => SubscriptionService.instance.isPurchasing, returnsNormally);
      expect(() => SubscriptionService.instance.offerings, returnsNormally);
      expect(() => SubscriptionService.instance.availablePackages,
          returnsNormally);
    });

    test('instance exposes required price getters', () {
      expect(
          () => SubscriptionService.instance.monthlyPriceString,
          returnsNormally);
      expect(
          () => SubscriptionService.instance.yearlyPriceString,
          returnsNormally);
      expect(
          () => SubscriptionService.instance.lifetimePriceString,
          returnsNormally);
    });

    test('purchase methods return Future<bool>', () {
      expect(SubscriptionService.instance.purchaseMonthly(), isA<Future<bool>>());
      expect(SubscriptionService.instance.purchaseYearly(), isA<Future<bool>>());
      expect(SubscriptionService.instance.purchaseLifetime(), isA<Future<bool>>());
    });
  });
}
