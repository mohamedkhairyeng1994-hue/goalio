import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/utils/ad_manager.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    debugPrint("AdMob: Starting to load banner ad...");
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("AdMob: Banner ad loaded successfully!");
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("AdMob: Banner ad FAILED to load: ${error.message} (Code: ${error.code})");
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint("AdMob: Banner ad opened."),
        onAdClosed: (ad) => debugPrint("AdMob: Banner ad closed."),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show NOTHING until loaded. This prevents "big empty space".
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
