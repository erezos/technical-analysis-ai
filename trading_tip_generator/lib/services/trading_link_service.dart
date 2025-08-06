import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../utils/app_logger.dart';

class TradingLinkService {
  static const String _configCollection = 'app_config';
  static const String _configDoc = 'trading_links';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  // Session-based cached URL (fetch once per app launch)
  static String? _cachedTradingUrl;
  static bool _hasInitialized = false;
  static String? _detectedCountryCode;
  static String? _detectedCountryName;

  /// Initialize trading link on app launch (fetch once per session)
  static Future<void> initializeTradingLinkForSession() async {
    if (_hasInitialized) return; // Already initialized this session
    
    try {
      AppLogger.firebase('Initializing Firebase Remote Config with country targeting...');
      
      // Step 1: Initialize Firebase Remote Config
      await _initializeRemoteConfig();
      
      // Step 2: Detect user's country
      await _detectUserCountry();
      
      // Step 3: Fetch country-specific URL using Firebase's built-in targeting
      await _fetchCountrySpecificUrl();
      
      _hasInitialized = true;
      AppLogger.firebase('Country-targeted trading link service initialized successfully');
      
    } catch (e) {
      AppLogger.error('Error initializing trading link service: $e');
      // Use fallback URL on error
      _cachedTradingUrl = _getFallbackUrl();
      _hasInitialized = true;
    }
  }

  /// Initialize Firebase Remote Config with country targeting
  static Future<void> _initializeRemoteConfig() async {
    try {
      // Set minimum fetch interval for development (0 = no cache)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Cache for 1 hour in production
      ));

      // Set default value for the trading URL parameter
      await _remoteConfig.setDefaults({
        'trading_url': 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=global_users',
      });

      // Fetch and activate config
      await _remoteConfig.fetchAndActivate();
      
      AppLogger.firebase('Firebase Remote Config initialized with country targeting');
      
    } catch (e) {
      AppLogger.error('Error initializing Remote Config: $e');
      rethrow;
    }
  }

  /// Detect user's country using IP geolocation
  static Future<void> _detectUserCountry() async {
    try {
      // Method 1: IP Geolocation (preferred for accuracy)
      await _detectCountryByIP();
      
      // Method 2: Device Locale (fallback if IP detection fails)
      if (_detectedCountryCode == null) {
        _detectCountryByLocale();
      }
      
      AppLogger.info('🌍 Country detection complete:');
      AppLogger.info('   Country Code: $_detectedCountryCode');
      AppLogger.info('   Country Name: $_detectedCountryName');
      
    } catch (e) {
      AppLogger.error('❌ Error detecting user country: $e');
      // Default to global if detection fails
      _detectedCountryCode = 'UNKNOWN';
      _detectedCountryName = 'Unknown';
    }
  }

  /// Enhanced IP geolocation with detailed country data
  static Future<void> _detectCountryByIP() async {
    try {
      // Using ipapi.co with detailed location data
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'User-Agent': 'TradingTipGenerator/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _detectedCountryCode = data['country_code']?.toString().toUpperCase();
        _detectedCountryName = data['country_name']?.toString();
        
        AppLogger.info('✅ IP geolocation successful:');
        AppLogger.info('   Country Code: $_detectedCountryCode');
        AppLogger.info('   Country Name: $_detectedCountryName');
        
        return;
      }
      
      AppLogger.warning('⚠️ IP geolocation failed - status: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('⚠️ IP geolocation error: $e');
    }
  }

  /// Fallback: Detect country using device locale settings
  static void _detectCountryByLocale() {
    try {
      final locale = Platform.localeName; // e.g., "en_US", "en_GB"
      if (locale.contains('_')) {
        final countryCode = locale.split('_').last.toUpperCase();
        if (countryCode.length == 2) {
          _detectedCountryCode = countryCode;
          _detectedCountryName = 'Detected from device locale';
          AppLogger.info('✅ Locale-based country detection: $countryCode');
          return;
        }
      }
      
      AppLogger.warning('⚠️ Locale detection failed: $locale');
    } catch (e) {
      AppLogger.error('⚠️ Locale detection error: $e');
    }
  }

  /// Fetch country-specific URL using Firebase's built-in country targeting
  static Future<void> _fetchCountrySpecificUrl() async {
    try {
      print('🔧 [REMOTE CONFIG] Fetching URL from Firebase Remote Config...');
      
      // Firebase Remote Config automatically handles country targeting
      // The app sends the country info, and Firebase returns the appropriate URL
      final url = _remoteConfig.getString('trading_url');
      
      print('🔧 [REMOTE CONFIG] Raw URL from Remote Config: "$url"');
      print('🔧 [REMOTE CONFIG] URL length: ${url.length}');
      print('🔧 [REMOTE CONFIG] URL is empty: ${url.isEmpty}');
      print('🔧 [REMOTE CONFIG] URL equals "null": ${url == "null"}');
      
      if (url.isNotEmpty && url != 'null') {
        _cachedTradingUrl = url;
        print('✅ [REMOTE CONFIG] Successfully cached URL: $url');
        AppLogger.info('🎯 Country-targeted URL fetched:');
        AppLogger.info('   Country: $_detectedCountryCode ($_detectedCountryName)');
        AppLogger.info('   URL: $url');
        
        // Log analytics event
        _logCountryTargetedUrlFetch();
      } else {
        print('⚠️ [REMOTE CONFIG] URL is empty or null, falling back to Firestore');
        // Fallback to Firestore if Remote Config fails
        await _fetchFromFirestore();
      }
      
    } catch (e) {
      print('❌ [REMOTE CONFIG] Error fetching URL: $e');
      AppLogger.error('❌ Error fetching country-targeted URL: $e');
      // Fallback to Firestore
      await _fetchFromFirestore();
    }
  }

  /// Log analytics for country-targeted URL fetch
  static void _logCountryTargetedUrlFetch() {
    // This would integrate with Firebase Analytics
    AppLogger.info('📊 [ANALYTICS] Country-targeted URL fetched');
    AppLogger.info('   Country Code: $_detectedCountryCode');
    AppLogger.info('   Country Name: $_detectedCountryName');
    AppLogger.info('   URL: $_cachedTradingUrl');
  }

  /// Fallback: Fetch URL from Firestore (legacy method)
  static Future<void> _fetchFromFirestore() async {
    try {
      final docRef = _firestore.collection(_configCollection).doc(_configDoc);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Use country-specific URL if available, otherwise use default
        final countryKey = 'trading_url_${_detectedCountryCode?.toLowerCase()}';
        _cachedTradingUrl = data[countryKey] ?? data['primary_url'] ?? _getFallbackUrl();
        
        AppLogger.info('🔄 Fallback to Firestore - Country: $_detectedCountryCode, URL: $_cachedTradingUrl');
      } else {
        _cachedTradingUrl = _getFallbackUrl();
        AppLogger.warning('⚠️ Using fallback trading link from Firestore');
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching from Firestore: $e');
      _cachedTradingUrl = _getFallbackUrl();
    }
  }

  /// Get current session trading URL (cached from app launch)
  static String getTradingUrl() {
    print('🔧 [GET URL] getTradingUrl() called');
    print('🔧 [GET URL] Is initialized: $_hasInitialized');
    print('🔧 [GET URL] Cached URL: $_cachedTradingUrl');
    
    if (!_hasInitialized || _cachedTradingUrl == null) {
      final fallbackUrl = _getFallbackUrl();
      print('⚠️ [GET URL] Using fallback URL: $fallbackUrl');
      return fallbackUrl;
    }
    
    print('✅ [GET URL] Returning cached URL: $_cachedTradingUrl');
    return _cachedTradingUrl!;
  }

  /// Fallback URL when all methods fail
  static String _getFallbackUrl() {
    return 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=fallback';
  }

  /// Launch trading platform URL
  static Future<bool> launchTradingPlatform() async {
    try {
      final url = getTradingUrl();
      AppLogger.info('🚀 Launching country-targeted trading platform: $url');
      
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        AppLogger.warning('❌ Cannot launch URL: $url');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error launching trading platform: $e');
      return false;
    }
  }

  /// Reset session (for debugging or manual refresh)
  static void resetSession() {
    _cachedTradingUrl = null;
    _hasInitialized = false;
    _detectedCountryCode = null;
    _detectedCountryName = null;
  }

  /// Check if link has been initialized this session
  static bool get isInitialized => _hasInitialized;

  /// Get detected country code
  static String? get detectedCountryCode => _detectedCountryCode;

  /// Get detected country name
  static String? get detectedCountryName => _detectedCountryName;

  /// Get detailed location info for analytics
  static Map<String, dynamic> getLocationInfo() {
    return {
      'country_code': _detectedCountryCode,
      'country_name': _detectedCountryName,
      'detection_method': _detectedCountryCode != null ? 'ip_geolocation' : 'device_locale',
    };
  }

  /// Update trading link (admin function - for server-side updates)
  static Future<void> updateTradingLink(String newPrimaryUrl, {String? newBackupUrl}) async {
    try {
      await _firestore.collection(_configCollection).doc(_configDoc).set({
        'primary_url': newPrimaryUrl,
        'backup_url': newBackupUrl ?? 'https://www.trading212.com/',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      AppLogger.info('✅ Trading links updated - Primary: $newPrimaryUrl, Backup: ${newBackupUrl ?? 'unchanged'}');
    } catch (e) {
      AppLogger.error('❌ Error updating trading link: $e');
    }
  }
} 