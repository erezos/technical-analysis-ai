import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';
import '../utils/app_logger.dart';

/// Service for managing AdMob ads in the application
/// 
/// This service handles the creation, loading, and lifecycle management
/// of different ad types (banner, interstitial) with proper error handling
/// and analytics tracking.
class AdService {
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isBannerAdLoaded = false;
  static bool _isInterstitialAdLoaded = false;
  static int _interstitialLoadAttempts = 0;
  static const int _maxInterstitialLoadAttempts = 3;
  
  /// Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    try {
      AppLogger.info('💰 Initializing AdMob SDK...');
      await MobileAds.instance.initialize();
      AppLogger.info('✅ AdMob SDK initialized successfully');
    } catch (error) {
      AppLogger.error('❌ Failed to initialize AdMob SDK: $error');
    }
  }
  
  /// Create and load an adaptive banner ad
  /// 
  /// [width] - The width of the banner ad in dp
  /// [onAdLoaded] - Callback when ad is successfully loaded
  /// [onAdFailedToLoad] - Callback when ad fails to load
  /// [adUnitId] - Optional specific ad unit ID (uses calendar banner by default)
  static Future<BannerAd?> createAdaptiveBanner({
    required int width,
    required Function(BannerAd) onAdLoaded,
    required Function(BannerAd, LoadAdError) onAdFailedToLoad,
    String? adUnitId,
  }) async {
    try {
      AppLogger.info('📱 Creating adaptive banner ad with width: $width');
      
      // Get the adaptive banner size
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      
      if (size == null) {
        AppLogger.error('❌ Unable to get adaptive banner size');
        return null;
      }
      
      final finalAdUnitId = adUnitId ?? AdHelper.calendarBannerAdUnitId;
      
      _bannerAd = BannerAd(
        adUnitId: finalAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            AppLogger.info('✅ Banner ad loaded successfully');
            _isBannerAdLoaded = true;
            onAdLoaded(ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            AppLogger.error('❌ Banner ad failed to load: $error');
            _isBannerAdLoaded = false;
            ad.dispose();
            onAdFailedToLoad(ad as BannerAd, error);
          },
          onAdOpened: (ad) {
            AppLogger.info('📈 Banner ad opened');
          },
          onAdClosed: (ad) {
            AppLogger.info('📉 Banner ad closed');
          },
          onAdImpression: (ad) {
            AppLogger.info('👁️ Banner ad impression recorded');
          },
          onAdClicked: (ad) {
            AppLogger.info('👆 Banner ad clicked');
          },
        ),
      );
      
      await _bannerAd!.load();
      return _bannerAd;
      
    } catch (error) {
      AppLogger.error('❌ Error creating adaptive banner: $error');
      return null;
    }
  }
  
  /// Create and load an interstitial ad
  /// 
  /// [onAdLoaded] - Callback when ad is successfully loaded
  /// [onAdFailedToLoad] - Callback when ad fails to load
  static Future<void> createInterstitialAd({
    required Function(InterstitialAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) async {
    try {
      AppLogger.info('🎬 Creating interstitial ad...');
      
      await InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            AppLogger.info('✅ Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _interstitialLoadAttempts = 0;
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (error) {
            AppLogger.error('❌ Interstitial ad failed to load: $error');
            _interstitialLoadAttempts++;
            _isInterstitialAdLoaded = false;
            _interstitialAd = null;
            
            // Retry loading if under max attempts
            if (_interstitialLoadAttempts < _maxInterstitialLoadAttempts) {
              AppLogger.info('🔄 Retrying interstitial ad load (attempt $_interstitialLoadAttempts)');
              createInterstitialAd(
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            } else {
              onAdFailedToLoad(error);
            }
          },
        ),
      );
    } catch (error) {
      AppLogger.error('❌ Error creating interstitial ad: $error');
      onAdFailedToLoad(LoadAdError(0, 'AdService', 'Unknown error', null));
    }
  }
  
  /// Show the loaded interstitial ad
  /// 
  /// [onAdClosed] - Callback when ad is closed (optional)
  static void showInterstitialAd({Function()? onAdClosed}) {
    if (_interstitialAd == null || !_isInterstitialAdLoaded) {
      AppLogger.error('⚠️ Attempted to show interstitial ad before loading');
      return;
    }
    
    AppLogger.info('🎬 Showing interstitial ad');
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AppLogger.info('🎬 Interstitial ad showed full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.info('✅ Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdLoaded = false;
        
        // Preload next interstitial ad
        createInterstitialAd(
          onAdLoaded: (ad) => AppLogger.info('🔄 Next interstitial ad preloaded'),
          onAdFailedToLoad: (error) => AppLogger.error('❌ Failed to preload next interstitial: $error'),
        );
        
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.error('❌ Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdLoaded = false;
      },
      onAdImpression: (ad) {
        AppLogger.info('👁️ Interstitial ad impression recorded');
      },
      onAdClicked: (ad) {
        AppLogger.info('👆 Interstitial ad clicked');
      },
    );
    
    _interstitialAd!.show();
  }
  
  /// Check if banner ad is loaded and ready to display
  static bool get isBannerAdLoaded => _isBannerAdLoaded;
  
  /// Check if interstitial ad is loaded and ready to display
  static bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  
  /// Get the current banner ad instance
  static BannerAd? get bannerAd => _bannerAd;
  
  /// Dispose of all ads and clean up resources
  static void dispose() {
    AppLogger.info('🧹 Disposing AdMob ads');
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
  }
}