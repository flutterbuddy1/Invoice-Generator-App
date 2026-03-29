import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // --- Ad Unit IDs (Test) ---
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9666061878779882/3555309963';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9666061878779882/3555309963';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9666061878779882/1385082822';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9666061878779882/1385082822';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9666061878779882/5334874344'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9666061878779882/5334874344'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // --- Banner Ad ---
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => debugPrint('Banner Ad loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Banner Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  // --- Native Ad ---
  NativeAd createNativeAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  // --- Interstitial Ad ---
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _numInterstitialLoadAttempts += 1;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        createInterstitialAd(); // Load the next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        createInterstitialAd(); // Load the next one
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
