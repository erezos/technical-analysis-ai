import 'dart:io';

/// AdMob helper class to manage ad unit IDs and configuration
/// 
/// This centralizes all AdMob-related configurations and provides
/// test/production ad unit IDs for different platforms and ad types.
class AdHelper {
  
  // Test Ad Unit IDs (use during development)
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBanneriOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialiOS = 'ca-app-pub-3940256099942544/4411468910';
  
  // Production Calendar Banner Ad Unit IDs
  static const String _prodCalendarBannerAndroid = 'ca-app-pub-9307424222926115/5552241744';
  static const String _prodCalendarBanneriOS = 'ca-app-pub-9307424222926115/6889358231';
  
  // Production Education Banner Ad Unit IDs
  static const String _prodEducationBannerAndroid = 'ca-app-pub-9307424222926115/3213837105';
  static const String _prodEducationBanneriOS = 'ca-app-pub-9307424222926115/7077076407';
  
  // Production Interstitial Ad Unit IDs (if needed later)
  static const String _prodInterstitialAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXXX/XXXXXXXXXX'; // TODO: Create if needed
  static const String _prodInterstitialiOS = 'ca-app-pub-XXXXXXXXXXXXXXXXX/XXXXXXXXXX'; // TODO: Create if needed
  
  // App IDs (your real AdMob app IDs)
  static const String _appIdAndroid = 'ca-app-pub-9307424222926115~2893470577';
  static const String _appIdiOS = 'ca-app-pub-9307424222926115~2398646553';
  
  /// Flag to determine if we're using test ads (set to false for production)
  static const bool _useTestAds = false; // PRODUCTION MODE - REAL ADS FOR REVENUE!
  
  /// Get the appropriate app ID for the current platform
  static String get appId {
    if (Platform.isAndroid) {
      return _appIdAndroid;
    } else if (Platform.isIOS) {
      return _appIdiOS;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Get calendar banner ad unit ID for the current platform
  static String get calendarBannerAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? _testBannerAndroid : _testBanneriOS;
    }
    
    if (Platform.isAndroid) {
      return _prodCalendarBannerAndroid;
    } else if (Platform.isIOS) {
      return _prodCalendarBanneriOS;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Get education banner ad unit ID for the current platform
  static String get educationBannerAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? _testBannerAndroid : _testBanneriOS;
    }
    
    if (Platform.isAndroid) {
      return _prodEducationBannerAndroid;
    } else if (Platform.isIOS) {
      return _prodEducationBanneriOS;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Get banner ad unit ID for the current platform (legacy - use specific methods above)
  @deprecated
  static String get bannerAdUnitId => calendarBannerAdUnitId;
  
  /// Get interstitial ad unit ID for the current platform
  static String get interstitialAdUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? _testInterstitialAndroid : _testInterstitialiOS;
    }
    
    if (Platform.isAndroid) {
      return _prodInterstitialAndroid;
    } else if (Platform.isIOS) {
      return _prodInterstitialiOS;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}