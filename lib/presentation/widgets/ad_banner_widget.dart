import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/app_logger.dart';

/// Reusable adaptive banner ad widget.
///
/// Themed to match Safora's design — shows a subtle container while loading
/// and handles errors gracefully (collapses to zero height on failure).
///
/// Usage:
/// ```dart
/// AdBanner(adUnitId: AdService.bannerAlerts)
/// ```
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) _loadAd();
  }

  void _loadAd() {
    const adSize = AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // Test banner ID
          : widget.adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('[AdBanner] Failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
