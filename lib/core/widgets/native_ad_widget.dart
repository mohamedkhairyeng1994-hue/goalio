import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_manager.dart';
import '../utils/size_config.dart';
import '../constants/constants.dart';

class GoalioNativeAdWidget extends StatefulWidget {
  const GoalioNativeAdWidget({super.key});

  @override
  State<GoalioNativeAdWidget> createState() => _GoalioNativeAdWidgetState();
}

class _GoalioNativeAdWidgetState extends State<GoalioNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdManager.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdMob: Native Ad failed to load: $error');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.black12,
          cornerRadius: 16.0,
          callToActionTextStyle: NativeTemplateTextStyle(
              textColor: const Color(0xFF0F172A),
              backgroundColor: GoalioColors.greenAccent,
              style: NativeTemplateFontStyle.bold,
              size: 16.0),
          primaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white,
              style: NativeTemplateFontStyle.bold,
              size: 16.0),
          secondaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white70,
              style: NativeTemplateFontStyle.normal,
              size: 14.0),
          tertiaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white70,
              style: NativeTemplateFontStyle.normal,
              size: 12.0)),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      height: 320.h, // Height for Medium template
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.w,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
