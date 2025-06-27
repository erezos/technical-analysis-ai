import 'dart:math';

/// Utility class for managing trading card backgrounds
/// Replaces DALL-E generated backgrounds with pre-generated assets
class TradingBackgroundUtils {
  
  // List of available bullish backgrounds
  static const List<String> _bullishBackgrounds = [
    'assets/images/trading_backgrounds/bullish/bullish_background_1.png',
    'assets/images/trading_backgrounds/bullish/bullish_background_2.png',
    'assets/images/trading_backgrounds/bullish/bullish_background_3.png',
    'assets/images/trading_backgrounds/bullish/bullish_background_4.png',
    'assets/images/trading_backgrounds/bullish/bullish_background_5.png',
  ];
  
  // List of available bearish backgrounds
  static const List<String> _bearishBackgrounds = [
    'assets/images/trading_backgrounds/bearish/bearish_background_1.png',
    'assets/images/trading_backgrounds/bearish/bearish_background_2.png',
    'assets/images/trading_backgrounds/bearish/bearish_background_3.png',
    'assets/images/trading_backgrounds/bearish/bearish_background_4.png',
    'assets/images/trading_backgrounds/bearish/bearish_background_5.png',
  ];
  
  static final Random _random = Random();
  
  /// Get a random background based on sentiment
  /// 
  /// [sentiment] - 'bullish', 'bearish', or any other value (defaults to neutral)
  /// Returns the asset path for the selected background
  static String getRandomBackground(String? sentiment) {
    if (sentiment == null) return _getRandomBullishBackground();
    
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return _getRandomBullishBackground();
      case 'bearish':
        return _getRandomBearishBackground();
      default:
        // For neutral or unknown sentiments, randomly pick either
        return _random.nextBool() 
            ? _getRandomBullishBackground() 
            : _getRandomBearishBackground();
    }
  }
  
  /// Get a specific bullish background by index (0-4)
  static String getBullishBackground(int index) {
    if (index < 0 || index >= _bullishBackgrounds.length) {
      index = 0; // Default to first background if index out of range
    }
    return _bullishBackgrounds[index];
  }
  
  /// Get a specific bearish background by index (0-4)
  static String getBearishBackground(int index) {
    if (index < 0 || index >= _bearishBackgrounds.length) {
      index = 0; // Default to first background if index out of range
    }
    return _bearishBackgrounds[index];
  }
  
  /// Get a random bullish background
  static String _getRandomBullishBackground() {
    final index = _random.nextInt(_bullishBackgrounds.length);
    return _bullishBackgrounds[index];
  }
  
  /// Get a random bearish background
  static String _getRandomBearishBackground() {
    final index = _random.nextInt(_bearishBackgrounds.length);
    return _bearishBackgrounds[index];
  }
  
  /// Get all available bullish backgrounds
  static List<String> getAllBullishBackgrounds() {
    return List.unmodifiable(_bullishBackgrounds);
  }
  
  /// Get all available bearish backgrounds
  static List<String> getAllBearishBackgrounds() {
    return List.unmodifiable(_bearishBackgrounds);
  }
  
  /// Get total number of available backgrounds
  static int getTotalBackgroundCount() {
    return _bullishBackgrounds.length + _bearishBackgrounds.length;
  }
  
  /// Get background type from asset path
  static String getBackgroundType(String assetPath) {
    if (assetPath.contains('bullish')) return 'bullish';
    if (assetPath.contains('bearish')) return 'bearish';
    return 'unknown';
  }
  
  /// Check if the tip should use local backgrounds instead of network images
  /// This can be used to gradually transition from DALL-E to local assets
  static bool shouldUseLocalBackground(String? networkImageUrl) {
    // If no network image URL provided, use local
    if (networkImageUrl == null || networkImageUrl.isEmpty) return true;
    
    // If network image fails to load, use local as fallback
    // This logic can be implemented in the widget
    return false;
  }
} 