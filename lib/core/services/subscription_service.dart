import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'app_logger.dart';
import 'premium_manager.dart';

/// RevenueCat-powered subscription service for Digital Drive / Safora.
///
/// Manages the Pro subscription lifecycle:
/// - Initialize RevenueCat SDK with [_apiKey]
/// - Purchase any tier (monthly, yearly, lifetime)
/// - Present native RevenueCat paywall
/// - Present Customer Center for subscription management
/// - Restore previous purchases
/// - Listen for subscription status changes
/// - Cascade premium state to [PremiumManager]
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  // ── Configuration ──────────────────────────────────────────
  /// RevenueCat Public SDK Key for Google Play (Android).
  /// App ID: appd5b7f0b474
  static const _apiKey = 'goog_zTdOFvWUWYQNoNzuPTufQopXXdv';

  /// RevenueCat entitlement identifier.
  /// Set in: RevenueCat Dashboard → Entitlements → "Digital Drive Pro"
  static const entitlementId = 'Digital Drive Pro';

  /// Product identifiers configured in RevenueCat.
  static const productMonthly = 'monthly';
  static const productYearly = 'yearly';
  static const productLifetime = 'lifetime';

  // ── State ──────────────────────────────────────────────────
  bool _initialized = false;
  Offerings? _offerings;
  bool _isPurchasing = false;

  /// Whether RevenueCat has been initialized.
  bool get isInitialized => _initialized;

  /// Whether a purchase is in progress.
  bool get isPurchasing => _isPurchasing;

  /// Available offerings (pricing, packages).
  Offerings? get offerings => _offerings;

  /// Get the default offering's available packages.
  List<Package> get availablePackages =>
      _offerings?.current?.availablePackages ?? [];

  /// Get a specific package by type from the current offering.
  Package? getPackage(PackageType type) {
    switch (type) {
      case PackageType.monthly:
        return _offerings?.current?.monthly;
      case PackageType.annual:
        return _offerings?.current?.annual;
      case PackageType.lifetime:
        return _offerings?.current?.lifetime;
      default:
        return null;
    }
  }

  /// Get pricing string for a specific tier.
  String? getPriceString(PackageType type) {
    return getPackage(type)?.storeProduct.priceString;
  }

  /// Get the monthly package price string (convenience).
  String? get monthlyPriceString => getPriceString(PackageType.monthly);

  /// Get the yearly package price string (convenience).
  String? get yearlyPriceString => getPriceString(PackageType.annual);

  /// Get the lifetime package price string (convenience).
  String? get lifetimePriceString => getPriceString(PackageType.lifetime);

  // ── Initialize ─────────────────────────────────────────────

  /// Initialize RevenueCat SDK and sync subscription status.
  Future<void> init() async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );

      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      // Listen for customer info changes (renewal, expiry, etc.)
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      // Sync current status
      await _syncSubscriptionStatus();

      // Fetch offerings (for paywall pricing)
      await _fetchOfferings();

      _initialized = true;
      AppLogger.info('[Subscription] RevenueCat initialized');
    } catch (e) {
      AppLogger.warning('[Subscription] Init failed: $e');
      // Non-fatal — app works in free mode without RevenueCat
    }
  }

  // ── Native Paywall ─────────────────────────────────────────

  /// Present RevenueCat's native paywall UI.
  ///
  /// This uses the paywall configured in the RevenueCat Dashboard,
  /// which can be updated remotely without code changes.
  /// Returns the [PaywallResult] indicating what happened.
  Future<PaywallResult> presentPaywall() async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
      AppLogger.info('[Subscription] Paywall result: $result');

      // Sync status after paywall interaction
      await _syncSubscriptionStatus();

      return result;
    } catch (e) {
      AppLogger.warning('[Subscription] Present paywall failed: $e');
      return PaywallResult.error;
    }
  }

  // ── Customer Center ────────────────────────────────────────

  /// Present RevenueCat's Customer Center for subscription management.
  ///
  /// Allows users to:
  /// - View their subscription status
  /// - Cancel their subscription
  /// - Restore purchases
  /// - Contact support
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
      AppLogger.info('[Subscription] Customer Center presented');

      // Sync status after customer center interaction
      await _syncSubscriptionStatus();
    } catch (e) {
      AppLogger.warning('[Subscription] Customer Center failed: $e');
    }
  }

  // ── Purchase ───────────────────────────────────────────────

  /// Purchase a specific package.
  ///
  /// Returns `true` if purchase succeeded, `false` otherwise.
  Future<bool> purchasePackage(Package package) async {
    if (_isPurchasing) return false;
    _isPurchasing = true;

    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final entitlement =
          result.customerInfo.entitlements.all[entitlementId];

      if (entitlement != null && entitlement.isActive) {
        await GetIt.instance<PremiumManager>().setPremium(true);
        AppLogger.info(
          '[Subscription] Purchased: ${package.identifier}',
        );
        _isPurchasing = false;
        return true;
      }

      _isPurchasing = false;
      return false;
    } on PlatformException catch (e) {
      _isPurchasing = false;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.info('[Subscription] User cancelled purchase');
        return false;
      }

      AppLogger.warning('[Subscription] Purchase failed: $e');
      return false;
    }
  }

  /// Purchase Pro monthly subscription (convenience).
  Future<bool> purchaseMonthly() async {
    final pkg = getPackage(PackageType.monthly);
    if (pkg == null) {
      AppLogger.warning('[Subscription] No monthly package available');
      return false;
    }
    return purchasePackage(pkg);
  }

  /// Purchase Pro yearly subscription (convenience).
  Future<bool> purchaseYearly() async {
    final pkg = getPackage(PackageType.annual);
    if (pkg == null) {
      AppLogger.warning('[Subscription] No yearly package available');
      return false;
    }
    return purchasePackage(pkg);
  }

  /// Purchase Pro lifetime (convenience).
  Future<bool> purchaseLifetime() async {
    final pkg = getPackage(PackageType.lifetime);
    if (pkg == null) {
      AppLogger.warning('[Subscription] No lifetime package available');
      return false;
    }
    return purchasePackage(pkg);
  }

  // ── Restore ────────────────────────────────────────────────

  /// Restore previous purchases (e.g., after re-install).
  ///
  /// Returns `true` if Pro entitlement was restored.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final entitlement = customerInfo.entitlements.all[entitlementId];
      final isActive = entitlement != null && entitlement.isActive;

      await GetIt.instance<PremiumManager>().setPremium(isActive);
      AppLogger.info('[Subscription] Restore: isPro=$isActive');
      return isActive;
    } catch (e) {
      AppLogger.warning('[Subscription] Restore failed: $e');
      return false;
    }
  }

  // ── Status Check ───────────────────────────────────────────

  /// Check if the user has an active Pro entitlement.
  Future<bool> checkProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementId];
      return entitlement != null && entitlement.isActive;
    } catch (e) {
      AppLogger.warning('[Subscription] Status check failed: $e');
      return false;
    }
  }

  /// Sync subscription status with RevenueCat.
  Future<void> _syncSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementId];
      final isActive = entitlement != null && entitlement.isActive;

      await GetIt.instance<PremiumManager>().setPremium(isActive);
      AppLogger.info('[Subscription] Synced: isPro=$isActive');
    } catch (e) {
      AppLogger.warning('[Subscription] Status sync failed: $e');
    }
  }

  /// Fetch available offerings (packages + pricing).
  Future<void> _fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (_offerings?.current != null) {
        final pkgCount = _offerings!.current!.availablePackages.length;
        AppLogger.info(
          '[Subscription] Offering loaded: '
          '${_offerings!.current!.identifier} ($pkgCount packages)',
        );
      }
    } catch (e) {
      AppLogger.warning('[Subscription] Fetch offerings failed: $e');
    }
  }

  /// Listener for subscription changes (auto-renewal, expiry).
  void _onCustomerInfoUpdate(CustomerInfo info) {
    final entitlement = info.entitlements.all[entitlementId];
    final isActive = entitlement != null && entitlement.isActive;

    GetIt.instance<PremiumManager>().setPremium(isActive);
    AppLogger.info('[Subscription] Status updated: isPro=$isActive');
  }
}
