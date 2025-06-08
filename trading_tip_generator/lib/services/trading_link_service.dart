import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TradingLinkService {
  static const String _configCollection = 'app_config';
  static const String _configDoc = 'trading_links';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Session-based cached URL (fetch once per app launch)
  static String? _cachedTradingUrl;
  static bool _hasInitialized = false;

  /// Initialize trading link on app launch (fetch once per session)
  static Future<void> initializeTradingLinkForSession() async {
    if (_hasInitialized) return; // Already initialized this session
    
    try {
      print('🔗 Fetching trading link for session...');
      final docRef = _firestore.collection(_configCollection).doc(_configDoc);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _cachedTradingUrl = data['primary_url'] ?? _getFallbackUrl();
        _hasInitialized = true;
        print('✅ Trading link loaded: $_cachedTradingUrl');
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
  }

  /// Check if link has been initialized this session
  static bool get isInitialized => _hasInitialized;

  /// Update trading link (admin function - for server-side updates)
  static Future<void> updateTradingLink(String newUrl) async {
    try {
      await _firestore.collection(_configCollection).doc(_configDoc).set({
        'primary_url': newUrl,
        'updated_at': FieldValue.serverTimestamp(),
        'backup_url': 'https://www.trading212.com/', // Fallback
      }, SetOptions(merge: true));
      
      // Update cached value
      _cachedTradingUrl = newUrl;
      print('✅ Trading link updated: $newUrl');
    } catch (e) {
      print('❌ Error updating trading link: $e');
    }
  }
} 