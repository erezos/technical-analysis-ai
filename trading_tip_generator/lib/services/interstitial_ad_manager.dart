import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_helper.dart';
import '../utils/app_logger.dart';

class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static bool _isShowingAd = false;
  
  // Tracking for frequency capping
  static int _tipClickCount = 0;
  static bool _isFirstSession = false;
  
  // Remote-configurable cadence controls
  static int _firstSessionFirstAdIndex = 2; // default
  static int _firstSessionEveryNClicks = 2; // default
  static int _laterSessionFirstAdIndex = 1; // default
  static int _laterSessionEveryNClicks = 2; // default
  
  // Remote Config flags
  static bool _showAds = false;
  static bool _adsEnabled = false;

  /// Initialize the ad manager and check remote config
  static Future<void> initialize() async {
    AppLogger.info('🎯 Initializing InterstitialAdManager');
    
    await _checkFirstSession();
    await _fetchRemoteConfig();
    
    if (_shouldLoadAds()) {
      _loadInterstitialAd();
    }
  }

  /// Check if this is user's first session
  static Future<void> _checkFirstSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstSession = !prefs.containsKey('has_opened_app_before');
    
    if (_isFirstSession) {
      await prefs.setBool('has_opened_app_before', true);
      AppLogger.info('🆕 First session detected - ads enabled with first-session frequency rules');
    } else {
      AppLogger.info('👤 Returning user - ads potentially enabled');
    }
  }

  /// Fetch Firebase Remote Config for ad controls
  static Future<void> _fetchRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values
      await remoteConfig.setDefaults({
        'showAds': true,
        'first_session_first_ad_index': 2,
        'first_session_every_n_clicks': 2,
        'later_session_first_ad_index': 1,
        'later_session_every_n_clicks': 2,
      });
      
      // Fetch and activate
      await remoteConfig.fetchAndActivate();
      
      _showAds = remoteConfig.getBool('showAds');
      // Ads are enabled by Remote Config regardless of session type.
      // Frequency rules differ for first session vs returning users.
      _adsEnabled = _showAds;
      
      // Read cadence params
      _firstSessionFirstAdIndex = _sanitizeIndex(remoteConfig.getInt('first_session_first_ad_index'));
      _firstSessionEveryNClicks = _sanitizeEvery(remoteConfig.getInt('first_session_every_n_clicks'));
      _laterSessionFirstAdIndex = _sanitizeIndex(remoteConfig.getInt('later_session_first_ad_index'));
      _laterSessionEveryNClicks = _sanitizeEvery(remoteConfig.getInt('later_session_every_n_clicks'));
      
      AppLogger.info('🔧 Remote Config: showAds=$_showAds, adsEnabled=$_adsEnabled');
      AppLogger.info('🔧 RC Cadence: firstSession[firstIndex=$_firstSessionFirstAdIndex, everyN=$_firstSessionEveryNClicks], laterSession[firstIndex=$_laterSessionFirstAdIndex, everyN=$_laterSessionEveryNClicks]');
    } catch (e) {
      AppLogger.error('❌ Failed to fetch Remote Config: $e');
      // Default to ads enabled for returning users if Remote Config fails
      _showAds = true;
      _adsEnabled = true;
    }
  }

  /// Check if we should load ads based on conditions
  static bool _shouldLoadAds() {
    return _adsEnabled;
  }

  /// Load interstitial ad
  static void _loadInterstitialAd() {
    if (_isAdLoaded || _isShowingAd) return;
    
    AppLogger.info('📱 Loading interstitial ad...');
    
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          AppLogger.info('✅ Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isAdLoaded = true;
          
          _setFullScreenContentCallback(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          AppLogger.error('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
          
          // Retry loading after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (_shouldLoadAds()) {
              _loadInterstitialAd();
            }
          });
        },
      ),
    );
  }

  /// Set up full screen content callback
  static void _setFullScreenContentCallback(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        AppLogger.info('🎬 Interstitial ad showed full screen');
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        AppLogger.info('❌ Interstitial ad dismissed');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Load next ad for future use
        if (_shouldLoadAds()) {
          _loadInterstitialAd();
        }
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        AppLogger.error('❌ Interstitial ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Load next ad
        if (_shouldLoadAds()) {
          _loadInterstitialAd();
        }
      },
    );
  }

  /// Show interstitial ad before navigating to trading tip
  /// Returns true if ad was shown, false if navigation should proceed immediately
  static Future<bool> showInterstitialAdIfNeeded({
    required VoidCallback onAdDismissed,
  }) async {
    // Skip if ads disabled
    if (!_adsEnabled) {
      AppLogger.info('🚫 Ads disabled - proceeding to tip');
      return false;
    }
    
    // Increment click count
    _tipClickCount++;
    AppLogger.info('👆 Tip click count: $_tipClickCount');
    
    // Frequency rules via Remote Config
    final bool shouldShowAd = _isFirstSession
        ? _shouldShowThisClick(
            _tipClickCount,
            _firstSessionFirstAdIndex,
            _firstSessionEveryNClicks,
          )
        : _shouldShowThisClick(
            _tipClickCount,
            _laterSessionFirstAdIndex,
            _laterSessionEveryNClicks,
          );
    
    if (!shouldShowAd) {
      AppLogger.info('🔄 Not showing ad this click (frequency capping)');
      return false;
    }
    
    // Check if ad is ready
    if (!_isAdLoaded || _interstitialAd == null || _isShowingAd) {
      AppLogger.info('📭 No ad ready - proceeding to tip');
      return false;
    }
    
    AppLogger.info('🎯 Showing interstitial ad');
    
    // Show the ad
    _interstitialAd!.show();
    
    // Set up callback for when ad is dismissed
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Load next ad
        if (_shouldLoadAds()) {
          _loadInterstitialAd();
        }
        
        // Call the callback to proceed to tip
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        AppLogger.error('❌ Failed to show interstitial: $error');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        
        // Load next ad
        if (_shouldLoadAds()) {
          _loadInterstitialAd();
        }
        
        // Proceed to tip anyway
        onAdDismissed();
      },
    );
    
    return true;
  }

  // Helpers for cadence
  static int _sanitizeIndex(int value) {
    if (value.isNaN) return 1; // defensive
    if (value < 1) return 1;
    if (value > 1000) return 1000; // hard cap
    return value;
  }
  
  static int _sanitizeEvery(int value) {
    if (value.isNaN) return 0; // treat as disabled if invalid
    if (value < 1) return 0; // 0 => disabled cadence
    if (value > 1000) return 1000; // cap
    return value;
  }
  
  static bool _shouldShowThisClick(int clickIndex, int firstIndex, int everyN) {
    if (everyN < 1) return false; // disabled
    final int start = firstIndex < 1 ? 1 : firstIndex;
    if (clickIndex < start) return false;
    return ((clickIndex - start) % everyN) == 0;
  }

  /// Force refresh remote config (for testing)
  static Future<void> refreshRemoteConfig() async {
    await _fetchRemoteConfig();
    
    if (_shouldLoadAds() && !_isAdLoaded) {
      _loadInterstitialAd();
    }
  }

  /// Dispose of any loaded ads
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isShowingAd = false;
  }

  /// Get current ad status for debugging
  static Map<String, dynamic> getAdStatus() {
    return {
      'isFirstSession': _isFirstSession,
      'showAds': _showAds,
      'adsEnabled': _adsEnabled,
      'isAdLoaded': _isAdLoaded,
      'isShowingAd': _isShowingAd,
      'tipClickCount': _tipClickCount,
      'firstSessionFirstAdIndex': _firstSessionFirstAdIndex,
      'firstSessionEveryNClicks': _firstSessionEveryNClicks,
      'laterSessionFirstAdIndex': _laterSessionFirstAdIndex,
      'laterSessionEveryNClicks': _laterSessionEveryNClicks,
    };
  }
}