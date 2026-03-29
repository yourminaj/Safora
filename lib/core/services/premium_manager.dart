import 'package:hive/hive.dart';
import 'ad_service.dart';
import 'app_open_ad_service.dart';

/// Central premium/free tier gate for Safora.
///
/// Controls which features are available to free vs. Pro users.
///
/// Monetization model:
/// - **Free**: Core safety features + ads (banner, interstitial, native, app open)
/// - **Pro**: All features unlocked, completely ad-free
///
/// Free tier includes: SOS, Shake-SOS, 3 contacts, decoy call, app lock, basic alerts
/// Pro tier adds: ML crash/fall, snatch, speed, geofence, context alerts,
///   dead man's switch, unlimited contacts/reminders, ad-free experience
class PremiumManager {
  PremiumManager._();
  static final PremiumManager instance = PremiumManager._();

  static const String _boxName = 'app_settings';
  static const String _premiumKey = 'is_premium';

  bool _isPremium = false;

  /// Whether the user has an active Pro subscription.
  bool get isPremium => _isPremium;

  /// Load premium state from Hive persistence.
  /// Silently falls back to in-memory default if Hive isn't initialized
  /// (e.g., in unit tests).
  Future<void> init() async {
    try {
      final box = Hive.box(_boxName);
      _isPremium = box.get(_premiumKey, defaultValue: false) as bool;
    } catch (_) {
      // Hive not initialized — keep in-memory default (false).
    }
  }

  /// Set premium state (e.g., after successful in-app purchase).
  /// Cascades to ad services so they respect premium state:
  /// - Pro users: all ads disabled
  /// - Free users: all ads enabled
  /// Always updates the in-memory flag; persists to Hive when available.
  Future<void> setPremium(bool premium) async {
    _isPremium = premium;

    // Cascade to ad services — single source of truth
    AdService.instance.setPremium(premium);
    AppOpenAdService.instance.setPremium(premium);

    try {
      final box = Hive.box(_boxName);
      await box.put(_premiumKey, premium);
    } catch (_) {
      // Hive not initialized — in-memory state is still set above.
    }
  }

  // ─── Feature Gate Definitions ──────────────────────────────

  /// Core safety features — always available to all users.
  /// Free users see ads alongside these features.
  static const Set<ProFeature> _freeFeatures = {
    ProFeature.sos,
    ProFeature.shakeSos,
    ProFeature.decoyCall,
    ProFeature.appLock,
    ProFeature.basicAlerts,
    ProFeature.liveMap,
    ProFeature.emergencyCenter,
    ProFeature.alertMap,
  };

  /// Features available only to Pro (paid) users.
  /// Pro users also get a completely ad-free experience.
  static const Set<ProFeature> _proFeatures = {
    ProFeature.crashFallDetection,
    ProFeature.snatchDetection,
    ProFeature.speedAlert,
    ProFeature.contextAlerts,
    ProFeature.deadManSwitch,
    ProFeature.unlimitedContacts,
    ProFeature.unlimitedReminders,
    ProFeature.unlimitedGeofenceZones,
    ProFeature.fullSosHistory,
    ProFeature.adFree,
  };

  /// Check if a specific feature is available to the current user.
  bool isFeatureAvailable(ProFeature feature) {
    if (_freeFeatures.contains(feature)) return true;
    if (_proFeatures.contains(feature)) return _isPremium;
    return false;
  }

  /// Check if a feature requires Pro (useful for showing lock badges).
  bool isProOnly(ProFeature feature) => _proFeatures.contains(feature);

  // ─── Tier Limits ───────────────────────────────────────────

  /// Max emergency contacts for free users.
  static const int freeContactLimit = 3;

  /// Max medicine reminders for free users.
  static const int freeReminderLimit = 2;

  /// Max geofence zones for free users.
  static const int freeGeofenceLimit = 1;

  /// SOS history retention for free users (days).
  static const int freeHistoryDays = 7;

  /// Get the effective contact limit for the current user.
  int get contactLimit => _isPremium ? 999 : freeContactLimit;

  /// Get the effective reminder limit for the current user.
  int get reminderLimit => _isPremium ? 999 : freeReminderLimit;

  /// Get the effective geofence zone limit for the current user.
  int get geofenceLimit => _isPremium ? 999 : freeGeofenceLimit;

  /// Get the SOS history retention period for the current user.
  int get historyRetentionDays => _isPremium ? 365 : freeHistoryDays;
}

/// Enumeration of all features that can be gated.
enum ProFeature {
  // Free tier (ads shown)
  sos,
  shakeSos,
  decoyCall,
  appLock,
  basicAlerts,
  liveMap,
  emergencyCenter,
  alertMap,

  // Pro tier (paid, ad-free)
  crashFallDetection,
  snatchDetection,
  speedAlert,
  contextAlerts,
  deadManSwitch,
  unlimitedContacts,
  unlimitedReminders,
  unlimitedGeofenceZones,
  fullSosHistory,
  adFree,
}
