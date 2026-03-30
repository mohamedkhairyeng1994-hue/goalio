import 'dart:io';

class AdManager {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4262739856695834/2861055562';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4262739856695834/2613643556';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Add more ad units here if needed (Interstitial, Rewarded, etc.)
}
