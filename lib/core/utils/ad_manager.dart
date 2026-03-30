import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid 
        ? 'ca-app-pub-3940256099942544/6300978111' 
        : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid 
      ? 'ca-app-pub-4262739856695834/2861055562' 
      : 'ca-app-pub-4262739856695834/2613643556';
  }

  static String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid 
        ? 'ca-app-pub-3940256099942544/2247696110' 
        : 'ca-app-pub-3940256099942544/3986624511';
    }
    return Platform.isAndroid 
      ? 'ca-app-pub-4262739856695834/5555501667' 
      : 'ca-app-pub-4262739856695834/1288953599';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid 
        ? 'ca-app-pub-3940256099942544/1033173712' 
        : 'ca-app-pub-3940256099942544/4411468910';
    }
    // Using user provided base ID (treating as interstitial for this helper)
    return Platform.isAndroid 
      ? 'ca-app-pub-4262739856695834/2613643556' 
      : 'ca-app-pub-4262739856695834/2861055562';
  }

  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;

  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          debugPrint("AdMob: Interstitial loaded.");
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= 3) {
            loadInterstitial();
          }
          debugPrint("AdMob: Interstitial failed: ${error.message}");
        },
      ),
    );
  }

  static void showInterstitial(VoidCallback onDismissed) {
    if (_interstitialAd == null) {
      onDismissed();
      loadInterstitial();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitial();
        onDismissed();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
