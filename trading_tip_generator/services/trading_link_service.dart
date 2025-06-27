import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class TradingLinkService {
  static const String _configCollection = 'app_config';
  static const String _configDoc = 'trading_links';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Session-based cached URL (fetch once per app launch)
  static String? _cachedTradingUrl;
  static bool _hasInitialized = false;
  static String? _detectedCountryCode;
  static bool _isUSUser = false;

  /// Initialize trading link on app launch (fetch once per session)
  static Future<void> initializeTradingLinkForSession() async {
    if (_hasInitialized) return; // Already initialized this session
    
    try {
      print('🔗 Fetching trading link for session...');
      
      // Step 1: Detect user's country
      await _detectUserCountry();
      
      // Step 2: Fetch appropriate URLs from Firebase
      final docRef = _firestore.collection(_configCollection).doc(_configDoc);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Use backup_url for US users, primary_url for others
        if (_isUSUser) {
          _cachedTradingUrl = data['backup_url'] ?? data['primary_url'] ?? _getFallbackUrl();
          print('🇺🇸 US user detected - using backup URL: $_cachedTradingUrl');
        } else {
          _cachedTradingUrl = data['primary_url'] ?? _getFallbackUrl();
          print('🌍 Non-US user detected ($_detectedCountryCode) - using primary URL: $_cachedTradingUrl');
        }
        
        _hasInitialized = true;
      } else {
        // Use fallback URL if document doesn't exist
        _cachedTradingUrl = _getFallbackUrl();
        _hasInitialized = true;
        print('⚠️ Using fallback trading link');
      }
    } catch (e) {
      print('❌ Error fetching trading link: $e');
      // Use fallback URL on error
      _cachedTradingUrl = _getFallbackUrl();
      _hasInitialized = true;
    }
  }

  /// Detect user's country using IP geolocation with device locale fallback
  static Future<void> _detectUserCountry() async {
    try {
      // Method 1: IP Geolocation (preferred for accuracy)
      await _detectCountryByIP();
      
      // Method 2: Device Locale (fallback if IP detection fails)
      if (_detectedCountryCode == null) {
        _detectCountryByLocale();
      }
      
      // Determine if user is from US
      _isUSUser = (_detectedCountryCode == 'US' || _detectedCountryCode == 'USA');
      
      print('🌍 Country detection complete: $_detectedCountryCode (US User: $_isUSUser)');
      
    } catch (e) {
      print('❌ Error detecting user country: $e');
      // Default to non-US if detection fails
      _isUSUser = false;
      _detectedCountryCode = 'UNKNOWN';
    }
  }

  /// Detect country using IP geolocation (privacy-friendly, free service)
  static Future<void> _detectCountryByIP() async {
    try {
      // Using ipapi.co - free, reliable, GDPR compliant
      final response = await http.get(
        Uri.parse('https://ipapi.co/country_code/'),
        headers: {'User-Agent': 'TradingTipGenerator/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final countryCode = response.body.trim().toUpperCase();
        if (countryCode.isNotEmpty && countryCode.length == 2) {
          _detectedCountryCode = countryCode;
          print('✅ IP-based country detection: $countryCode');
          return;
        }
      }
      
      print('⚠️ IP geolocation failed - status: ${response.statusCode}');
    } catch (e) {
      print('⚠️ IP geolocation error: $e');
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
          print('✅ Locale-based country detection: $countryCode');
          return;
        }
      }
      
      print('⚠️ Locale detection failed: $locale');
    } catch (e) {
      print('⚠️ Locale detection error: $e');
    }
  }

  /// Get current session trading URL (cached from app launch)
  static String getTradingUrl() {
    if (!_hasInitialized || _cachedTradingUrl == null) {
      // Return fallback if not initialized
      return _getFallbackUrl();
    }
    return _cachedTradingUrl!;
  }

  /// Fallback URL when Firebase is unavailable
  static String _getFallbackUrl() {
    return 'https://www.trading212.com/'; // Default trading platform
  }

  /// Launch trading platform URL
  static Future<bool> launchTradingPlatform() async {
    try {
      final url = getTradingUrl();
      print('🚀 Launching trading platform: $url');
      
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in external browser
        );
        return true;
      } else {
        print('❌ Cannot launch URL: $url');
        return false;
      }
    } catch (e) {
      print('❌ Error launching trading platform: $e');
      return false;
    }
  }

  /// Reset session (for debugging or manual refresh)
  static void resetSession() {
    _cachedTradingUrl = null;
    _hasInitialized = false;
    _detectedCountryCode = null;
    _isUSUser = false;
  }

  /// Check if link has been initialized this session
  static bool get isInitialized => _hasInitialized;

  /// Get detected country code
  static String? get detectedCountryCode => _detectedCountryCode;

  /// Check if user is from US
  static bool get isUSUser => _isUSUser;

  /// Update trading link (admin function - for server-side updates)
  static Future<void> updateTradingLink(String newPrimaryUrl, {String? newBackupUrl}) async {
    try {
      await _firestore.collection(_configCollection).doc(_configDoc).set({
        'primary_url': newPrimaryUrl,
        'backup_url': newBackupUrl ?? 'https://www.trading212.com/',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update cached value based on user location
      if (_isUSUser) {
        _cachedTradingUrl = newBackupUrl ?? newPrimaryUrl;
      } else {
        _cachedTradingUrl = newPrimaryUrl;
      }
      
      print('✅ Trading links updated - Primary: $newPrimaryUrl, Backup: ${newBackupUrl ?? 'unchanged'}');
    } catch (e) {
      print('❌ Error updating trading link: $e');
    }
  }
} 