import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

/// App Rating Service
/// 
/// Handles in-app rating requests with smart timing and user experience optimization.
/// Shows rating popup when users arrive from notifications and haven't rated yet.
class AppRatingService {
  static const String _hasRatedKey = 'has_rated_app';
  static const String _ratingRequestCountKey = 'rating_request_count';
  static const String _lastRatingRequestKey = 'last_rating_request';
  static const String _fromNotificationKey = 'came_from_notification';
  
  static final InAppReview _inAppReview = InAppReview.instance;
  
  /// Check if user came from notification and show rating popup if appropriate
  static Future<void> handleNotificationArrival(BuildContext context) async {
    try {
      AppLogger.info('🌟 [Rating] Checking if user came from notification...');
      
      // Mark that user came from notification
      await _setFromNotification(true);
      
      // Check if we should show rating popup
      if (await _shouldShowRatingPopup()) {
        AppLogger.info('✨ [Rating] Showing rating popup for notification user');
        
        // Small delay to let the tip screen load first
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (context.mounted) {
          await _showRatingPopup(context);
        }
      }
      
    } catch (e) {
      AppLogger.error('❌ [Rating] Error handling notification arrival: $e');
    }
  }
  
  /// Check if we should show the rating popup
  static Future<bool> _shouldShowRatingPopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Don't show if user already rated
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      if (hasRated) {
        AppLogger.info('🌟 [Rating] User already rated, skipping popup');
        return false;
      }
      
      // Don't show if user came from notification (we want to show it specifically for notification users)
      final fromNotification = prefs.getBool(_fromNotificationKey) ?? false;
      if (!fromNotification) {
        AppLogger.info('🌟 [Rating] User did not come from notification, skipping popup');
        return false;
      }
      
      // Check request frequency (max once per week)
      final requestCount = prefs.getInt(_ratingRequestCountKey) ?? 0;
      final lastRequest = prefs.getInt(_lastRatingRequestKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const weekInMs = 7 * 24 * 60 * 60 * 1000;
      
      if (requestCount > 0 && (now - lastRequest) < weekInMs) {
        AppLogger.info('🌟 [Rating] Too soon since last request, skipping popup');
        return false;
      }
      
      // Don't show more than 3 times total
      if (requestCount >= 3) {
        AppLogger.info('🌟 [Rating] Max requests reached, skipping popup');
        return false;
      }
      
      AppLogger.info('✅ [Rating] All conditions met, showing rating popup');
      return true;
      
    } catch (e) {
      AppLogger.error('❌ [Rating] Error checking rating conditions: $e');
      return false;
    }
  }
  
  /// Show the beautiful rating popup
  static Future<void> _showRatingPopup(BuildContext context) async {
    try {
      // Track rating popup shown
      await _trackRatingEvent('rating_popup_shown', {
        'source': 'notification_arrival',
        'user_type': 'engaged_notification_user',
      });
      
      // Update request tracking
      await _updateRequestTracking();
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) => _RatingPopupDialog(),
      );
      
    } catch (e) {
      AppLogger.error('❌ [Rating] Error showing rating popup: $e');
    }
  }
  
  /// Request in-app review (iOS/Android native)
  static Future<void> requestInAppReview() async {
    try {
      AppLogger.info('⭐ [Rating] Requesting in-app review...');
      
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        
        // Mark as rated and track success
        await _markAsRated();
        await _trackRatingEvent('in_app_review_requested', {
          'method': 'native_in_app',
          'success': true,
        });
        
        AppLogger.info('✅ [Rating] In-app review requested successfully');
      } else {
        AppLogger.warning('⚠️ [Rating] In-app review not available, falling back to store');
        await _openAppStore();
      }
      
    } catch (e) {
      AppLogger.error('❌ [Rating] Error requesting in-app review: $e');
      await _openAppStore(); // Fallback to store
    }
  }
  
  /// Open app store for rating
  static Future<void> _openAppStore() async {
    try {
      AppLogger.info('🏪 [Rating] Opening app store for rating...');
      
      final String storeUrl = Platform.isIOS
          ? 'https://apps.apple.com/app/technical-analysis-ai/id6738025969?action=write-review'
          : 'https://play.google.com/store/apps/details?id=com.ioa.TipSync&showAllReviews=true';
      
      final Uri url = Uri.parse(storeUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Mark as rated and track success
        await _markAsRated();
        await _trackRatingEvent('app_store_opened', {
          'method': 'external_store',
          'platform': Platform.isIOS ? 'ios' : 'android',
          'store_url': storeUrl,
        });
        
        AppLogger.info('✅ [Rating] App store opened successfully');
      } else {
        throw Exception('Could not launch store URL: $storeUrl');
      }
      
    } catch (e) {
      AppLogger.error('❌ [Rating] Error opening app store: $e');
      await _trackRatingEvent('app_store_error', {
        'error': e.toString(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    }
  }
  
  /// Mark user as having rated the app
  static Future<void> _markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRatedKey, true);
      AppLogger.info('✅ [Rating] User marked as having rated the app');
    } catch (e) {
      AppLogger.error('❌ [Rating] Error marking user as rated: $e');
    }
  }
  
  /// Set that user came from notification
  static Future<void> _setFromNotification(bool fromNotification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fromNotificationKey, fromNotification);
      
      // Clear the flag after a short time (so it only applies to immediate navigation)
      if (fromNotification) {
        Future.delayed(const Duration(minutes: 5), () async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_fromNotificationKey, false);
          } catch (e) {
            // Ignore errors during cleanup
            AppLogger.error('❌ [Rating] Error clearing notification flag: $e');
          }
        });
      }
    } catch (e) {
      AppLogger.error('❌ [Rating] Error setting notification flag: $e');
    }
  }
  
  /// Update request tracking
  static Future<void> _updateRequestTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_ratingRequestCountKey) ?? 0;
      await prefs.setInt(_ratingRequestCountKey, currentCount + 1);
      await prefs.setInt(_lastRatingRequestKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('❌ [Rating] Error updating request tracking: $e');
    }
  }
  
  /// Track rating events to Firebase Analytics
  static Future<void> _trackRatingEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'timestamp': DateTime.now().toIso8601String(),
          ...parameters,
        },
      );
      
      AppLogger.info('📊 [Rating] Tracked event: $eventName');
    } catch (e) {
      AppLogger.error('❌ [Rating] Error tracking rating event: $e');
    }
  }
  
  /// Get rating statistics (for debugging/analytics)
  static Future<Map<String, dynamic>> getRatingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'has_rated': prefs.getBool(_hasRatedKey) ?? false,
        'request_count': prefs.getInt(_ratingRequestCountKey) ?? 0,
        'last_request': prefs.getInt(_lastRatingRequestKey) ?? 0,
        'from_notification': prefs.getBool(_fromNotificationKey) ?? false,
      };
    } catch (e) {
      AppLogger.error('❌ [Rating] Error getting rating stats: $e');
      return {};
    }
  }
}

/// Beautiful rating popup dialog
class _RatingPopupDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Enjoying our AI tips?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            const Text(
              'Your feedback helps us improve our AI-powered trading insights for traders like you.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                // Maybe Later button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AppRatingService._trackRatingEvent('rating_popup_dismissed', {
                        'action': 'maybe_later',
                        'source': 'notification_arrival',
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Rate 5 Stars button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      
                      await AppRatingService._trackRatingEvent('rating_popup_accepted', {
                        'action': 'rate_5_stars',
                        'source': 'notification_arrival',
                      });
                      
                      // Request in-app review
                      await AppRatingService.requestInAppReview();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF1a1a2e),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rate 5 Stars',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
