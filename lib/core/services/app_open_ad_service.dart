import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_logger.dart';

/// Lifecycle-aware App Open Ad service.
///
/// Shows a full-screen ad every Nth foreground resume with:
/// - Configurable frequency cap (default: every 3rd resume)
/// - 4-hour expiry check (Google requirement)
/// - Premium bypass
/// - Emergency exclusion
class AppOpenAdService {
  AppOpenAdService._();
  static final AppOpenAdService instance = AppOpenAdService._();

  // ── Configuration ──────────────────────────────────────
  static const _adUnitId = 'ca-app-pub-3413399953381965/4261837520';
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

  /// Show ad every Nth foreground resume.
  static const _frequencyCap = 3;

  /// Google requires discarding ads older than 4 hours.
  static const _maxAdAge = Duration(hours: 4);

  // ── State ──────────────────────────────────────────────
  AppOpenAd? _appOpenAd;
  DateTime? _adLoadTime;
  bool _isShowingAd = false;
  bool _isPremium = false;
  bool _emergencyActive = false;
  int _resumeCount = 0;

  /// Set premium status (skips all ads).
  void setPremium(bool premium) => _isPremium = premium;

  /// Set emergency status (blocks ads during SOS).
  void setEmergencyActive(bool active) => _emergencyActive = active;

  /// Whether the ad has expired (loaded > 4 hours ago).
  bool get _isAdExpired {
    if (_adLoadTime == null) return true;
    return DateTime.now().difference(_adLoadTime!) > _maxAdAge;
  }

  /// Load an App Open Ad.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: kDebugMode ? _testAdUnitId : _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _adLoadTime = DateTime.now();
          AppLogger.info('[AppOpenAd] Loaded successfully');
        },
        onAdFailedToLoad: (error) {
          AppLogger.warning('[AppOpenAd] Failed to load: $error');
          // Retry after delay.
          Future.delayed(const Duration(seconds: 60), loadAd);
        },
      ),
    );
  }

  /// Called when the app comes to the foreground.
  ///
  /// Only shows the ad every [_frequencyCap]th resume, and only
  /// when not premium, not in emergency, and ad is loaded + fresh.
  void onAppResumed() {
    if (_isPremium || _emergencyActive) return;

    _resumeCount++;

    // Only show on every Nth resume.
    if (_resumeCount % _frequencyCap != 0) return;

    _showAdIfAvailable();
  }

  void _showAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAd();
      return;
    }

    if (_isAdExpired) {
      AppLogger.info('[AppOpenAd] Ad expired, reloading');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }

    if (_isShowingAd) return;

    _isShowingAd = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AppLogger.info('[AppOpenAd] Showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Pre-load next.
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        AppLogger.warning('[AppOpenAd] Failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  /// Whether an App Open Ad is ready to show.
  bool get isReady => _appOpenAd != null && !_isAdExpired;

  /// Current resume count (for testing).
  int get resumeCount => _resumeCount;

  /// Reset resume counter (for testing).
  @visibleForTesting
  void resetForTesting() {
    _resumeCount = 0;
    _isPremium = false;
    _emergencyActive = false;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _adLoadTime = null;
    _isShowingAd = false;
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
