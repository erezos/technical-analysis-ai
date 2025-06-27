import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:math';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class NotificationPermissionService {
  static const double _showPromptProbability = 0.7; // 70% chance for returning users
  static final Random _random = Random();
  static const String _hasLaunchedBeforeKey = 'has_launched_before';
  static const String _recentPermissionRequestKey = 'recent_permission_request_timestamp';

  /// Check if we should show the notification permission prompt
  static Future<bool> shouldShowPermissionPrompt() async {
    try {
      // COORDINATION FIX: Check if NotificationService recently requested permission
      final prefs = await SharedPreferences.getInstance();
      final recentRequestTime = prefs.getInt(_recentPermissionRequestKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceRequest = currentTime - recentRequestTime;
      
      // If a permission request happened in the last 10 seconds, skip our check
      if (timeSinceRequest < 10000) { // 10 seconds
        print('🤝 Recent permission request detected (${timeSinceRequest}ms ago) - skipping custom prompt');
        return false;
      }
      
      // Platform-specific permission checking to avoid Firebase issues on Android
      bool isAlreadyGranted = false;
      
      if (Platform.isAndroid) {
        // Android: Use permission_handler to check status (no dialogs)
        final status = await ph.Permission.notification.status;
        isAlreadyGranted = status.isGranted;
        print('🤖 Android notification status: $status');
      } else {
        // iOS: Use Firebase Messaging's native permission check
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.getNotificationSettings();
        isAlreadyGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
        print('🍎 iOS notification status: ${settings.authorizationStatus}');
      }
      
      // If already granted, no need to show prompt
      if (isAlreadyGranted) {
        print('✅ Notifications already approved - no prompt needed');
        return false;
      }
      
      // Check if this is the first session (prevent double dialogs)
      final hasLaunchedBefore = prefs.getBool(_hasLaunchedBeforeKey) ?? false;
      
      if (!hasLaunchedBefore) {
        await prefs.setBool(_hasLaunchedBeforeKey, true);
        print('🚀 First session detected - skipping custom notification prompt');
        return false;
      }
      
      // Generate random number (0.0 to 1.0) - show dialog regardless of denial status
      // This allows users to access settings through our custom dialog
      final randomValue = _random.nextDouble();
      final shouldShow = randomValue < _showPromptProbability;
      
      print('🎲 Notification permission check: ${(randomValue * 100).toInt()}% - ${shouldShow ? "SHOW" : "SKIP"} prompt');
      
      return shouldShow;
    } catch (e) {
      print('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// COORDINATION: Mark that a permission request was made (for NotificationService to call)
  static Future<void> markPermissionRequestMade() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_recentPermissionRequestKey, DateTime.now().millisecondsSinceEpoch);
      print('🤝 Permission request timestamp recorded');
    } catch (e) {
      print('❌ Error recording permission request: $e');
    }
  }

  /// Show the beautiful custom notification permission dialog
  static Future<void> showPermissionDialog(BuildContext context) async {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 375 && screenSize.height <= 812;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width * 0.9 : 400,
              maxHeight: isSmallScreen ? screenSize.height * 0.75 : 600,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF2A2A2A),
                  Color(0xFF1A1A1A),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: isSmallScreen ? 20 : 30,
                  offset: Offset(0, isSmallScreen ? 10 : 15),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with glow effect
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A688)],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.4),
                          blurRadius: isSmallScreen ? 15 : 20,
                          offset: Offset(0, isSmallScreen ? 6 : 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 32,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Title
                  Text(
                    '🚀 Never Miss a Signal!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Description
                  Text(
                    'Get instant alerts when fresh AI trading signals are ready.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 16,
                      color: Colors.grey[300],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  
                  // Benefits
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitRow('📈', 'Real-time trading opportunities', isSmallScreen),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        _buildBenefitRow('⚡', 'AI-powered market insights', isSmallScreen),
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        _buildBenefitRow('🎯', 'Perfect timing for entries', isSmallScreen),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                              side: BorderSide(
                                color: Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Maybe Later',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: isSmallScreen ? 12 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: isSmallScreen ? 8 : 16),
                      
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _requestNotificationPermission(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4AA),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFF00D4AA).withOpacity(0.4),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Never Miss a Signal',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper widget for benefit rows
  static Widget _buildBenefitRow(String emoji, String text, bool isSmallScreen) {
    return Row(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
        ),
        SizedBox(width: isSmallScreen ? 6 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 11 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// FIXED: Request notification permission with smart permission state checking
  static Future<void> _requestNotificationPermission(BuildContext context) async {
    try {
      print('🔔 Requesting notification permission...');
      
      String message;
      Color backgroundColor;
      bool showSettingsAction = false;
      
      if (Platform.isAndroid) {
        // ANDROID: Use permission_handler only (no Firebase calls)
        final status = await ph.Permission.notification.status;
        print('🤖 Android permission status: $status');
        
        if (status.isGranted) {
          message = '🔔 Notifications already enabled!';
          backgroundColor = const Color(0xFF4CAF50);
        } else if (status.isDenied) {
          // First time asking on Android - request directly
          final result = await ph.Permission.notification.request();
          print('🤖 Android permission request result: $result');
          
          if (result.isGranted) {
            message = '🔔 Notifications enabled! You\'ll never miss a signal.';
            backgroundColor = const Color(0xFF4CAF50);
          } else {
            message = '📱 Notifications disabled. Enable in Settings.';
            backgroundColor = const Color(0xFFFF9800);
            showSettingsAction = true;
          }
        } else if (status.isPermanentlyDenied) {
          message = '📱 Notifications disabled. Enable in Settings.';
          backgroundColor = const Color(0xFFFF9800);
          showSettingsAction = true;
        } else {
          message = '🤔 Permission not determined. Try again.';
          backgroundColor = Colors.grey;
        }
      } else {
        // iOS: Use Firebase messaging for iOS-specific flow
        final messaging = FirebaseMessaging.instance;
        final currentSettings = await messaging.getNotificationSettings();
        print('🍎 iOS permission status: ${currentSettings.authorizationStatus}');
        
        if (currentSettings.authorizationStatus == AuthorizationStatus.denied) {
          message = '📱 Notifications disabled. Enable in Settings.';
          backgroundColor = const Color(0xFFFF9800);
          showSettingsAction = true;
        } else if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
          message = '🔔 Notifications already enabled!';
          backgroundColor = const Color(0xFF4CAF50);
        } else {
          // Request permission on iOS
          final settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          
          switch (settings.authorizationStatus) {
            case AuthorizationStatus.authorized:
              message = '🔔 Notifications enabled! You\'ll never miss a signal.';
              backgroundColor = const Color(0xFF4CAF50);
              break;
            case AuthorizationStatus.provisional:
              message = '📱 Provisional notifications enabled.';
              backgroundColor = const Color(0xFF00D4AA);
              break;
            case AuthorizationStatus.denied:
              message = '📱 Notifications disabled. Enable in Settings.';
              backgroundColor = const Color(0xFFFF9800);
              showSettingsAction = true;
              break;
            default:
              message = '🤔 Permission not determined. Try again.';
              backgroundColor = Colors.grey;
          }
        }
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: showSettingsAction ? 6 : 3),
            action: showSettingsAction ? SnackBarAction(
              label: 'Open Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ) : null,
          ),
        );
      }
      
      print('🔔 Notification permission process completed');
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Could not request notification permission'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// FIXED: Open app settings (iOS & Android compatible) - NOW PUBLIC
  static Future<void> openAppSettings() async {
    try {
      print('🔧 Opening app settings for platform: ${Platform.isIOS ? "iOS" : "Android"}');
      
      if (Platform.isIOS) {
        // iOS: Use URL scheme approach
        const url = 'app-settings:';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          print('📱 Opened iOS app settings');
        } else {
          print('❌ Could not open iOS app settings');
        }
      } else if (Platform.isAndroid) {
        // Android: Use permission_handler plugin for app settings
        final bool opened = await ph.openAppSettings();
        
        if (opened) {
          print('🤖 Opened Android app settings');
        } else {
          print('❌ Could not open Android app settings');
        }
      }
    } catch (e) {
      print('❌ Error opening app settings: $e');
    }
  }
} 