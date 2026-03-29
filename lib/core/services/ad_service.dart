import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_logger.dart';

/// Centralized Ad management service for Safora.
///
/// Handles banner, interstitial, and native ads for free users with:
/// - Frequency capping (interstitials max once per 3 min)
/// - Premium bypass (no ads for Pro subscribers)
/// - Safety exclusion (never show during emergency)
/// - Meta Audience Network mediation (interstitial + native)
///
/// Monetization model:
/// - Free users: all ads shown (banner, interstitial, native, app open)
/// - Pro users: all ads disabled (paid subscription = ad-free)
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Whether the user has premium (skip all ads).
  bool _isPremium = false;

  /// Whether an emergency is active (block interstitials).
  bool _emergencyActive = false;

  /// Interstitial frequency cap.
  DateTime? _lastInterstitialTime;
  static const _interstitialCooldown = Duration(minutes: 3);

  InterstitialAd? _interstitialAd;

  // ── Ad Unit IDs ──────────────────────────────────────────
  static const _bannerAlerts = 'ca-app-pub-3413399953381965/9006242267';
  static const _bannerSettings = 'ca-app-pub-3413399953381965/5258568943';
  static const _bannerContacts = 'ca-app-pub-3413399953381965/3945487274';
  static const _bannerProfile = 'ca-app-pub-3413399953381965/7749505494';
  static const _interstitialUnit = 'ca-app-pub-3413399953381965/3778470893';
  static const _nativeAlertsFeed = 'ca-app-pub-3413399953381965/6150921784';

  /// Ad unit IDs for each screen with a banner.
  static String get bannerAlerts => _bannerAlerts;
  static String get bannerSettings => _bannerSettings;
  static String get bannerContacts => _bannerContacts;
  static String get bannerProfile => _bannerProfile;

  /// Native ad unit ID for alerts feed.
  static String get nativeAlertsFeed => _nativeAlertsFeed;

  /// Initialize the Mobile Ads SDK.
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    AppLogger.info('[AdService] Mobile Ads SDK initialized');
    // Pre-load interstitial ad for free users.
    instance._loadInterstitial();
  }

  /// Set premium status (skips all ads for Pro users).
  /// Whether the user is premium (getter for external checks).
  bool get isPremium => _isPremium;

  void setPremium(bool premium) => _isPremium = premium;

  /// Set emergency status (blocks interstitials during SOS).
  void setEmergencyActive(bool active) => _emergencyActive = active;

  // ── Interstitial ─────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
          : _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial(); // Pre-load next.
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          AppLogger.warning('[AdService] Interstitial load failed: $error');
          // Retry after delay.
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Show interstitial if allowed (cooldown + not premium + not emergency).
  void showInterstitial() {
    if (_isPremium || _emergencyActive) return;

    // Frequency cap check.
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed < _interstitialCooldown) return;
    }

    if (_interstitialAd != null) {
      _lastInterstitialTime = DateTime.now();
      _interstitialAd!.show();
    }
  }

  /// Dispose all loaded ads.
  void dispose() {
    _interstitialAd?.dispose();
  }
}
