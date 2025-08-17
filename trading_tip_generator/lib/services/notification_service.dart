import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'notification_permission_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/app_logger.dart';
import 'app_rating_service.dart';

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Don't need to initialize Firebase here - it's done automatically for background handlers
  AppLogger.info('🔔 Background message received: ${message.messageId}');
  AppLogger.info('📱 Background message data: ${message.data}');
  
  // 📊 Track background notification reception
  // Note: Firebase Analytics is automatically initialized for background handlers
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'notification_received_background',
      parameters: {
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'message_id': message.messageId ?? 'unknown',
        'notification_type': message.data['type'] ?? 'unknown',
        'symbol': message.data['symbol'] ?? 'unknown',
        'timeframe': message.data['timeframe'] ?? 'unknown',
        'has_notification': message.notification != null,
        'title': message.notification?.title ?? 'no_title',
      },
    );
    
    // Track trading tip specific background reception
    if (message.data['type'] == 'trading_tip') {
      await FirebaseAnalytics.instance.logEvent(
        name: 'trading_tip_notification_received',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'symbol': message.data['symbol'] ?? 'unknown',
          'timeframe': message.data['timeframe'] ?? 'unknown',
          'received_in': 'background',
        },
      );
      
      AppLogger.info('📈 Trading tip received in background: ${message.data['symbol']}');
    }
  } catch (e) {
    AppLogger.error('❌ Error tracking background notification: $e');
  }
}

class NotificationService {
  static FirebaseMessaging? _messaging;
  static String? _token;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    try {
      AppLogger.info('🔥 Initializing Firebase messaging...');
      
      _navigatorKey = navigatorKey;
      _messaging = FirebaseMessaging.instance;

      // Platform-specific permission setup
      await _setupPlatformPermissions();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Get initial message if app was opened from notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('📲 App opened from notification: ${initialMessage.messageId}');
        _handleMessageOpenedApp(initialMessage);
      }

      // Subscribe to trading tips topic
      await _messaging!.subscribeToTopic('trading_tips');
      AppLogger.info('📢 Subscribed to trading_tips topic');

      // Set up iOS-specific settings
      if (Platform.isIOS) {
        await _handleIOSSetup();
        
        // Configure iOS foreground notification presentation
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.info('🍎 iOS foreground notification presentation configured');
      }

      // Get FCM token
      _token = await _messaging!.getToken();
      AppLogger.info('🔑 FCM Token: $_token');

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        AppLogger.info('🔄 FCM Token refreshed: $newToken');
        _token = newToken;
        _saveTokenToFirebase();
      });

      // Save token to backend
      await _saveTokenToFirebase();
      
      AppLogger.info('✅ Notification setup completed successfully');
      
    } catch (e) {
      AppLogger.error('❌ Error setting up notifications: $e');
      AppLogger.error('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// FIXED: Platform-specific permission setup to avoid double dialogs
  static Future<void> _setupPlatformPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android: Use permission_handler for clean, single dialog
        final status = await ph.Permission.notification.status;
        AppLogger.info('🤖 Android notification permission status: $status');
        
        if (status.isDenied) {
          // COORDINATION: Mark that we're about to request permission (Android only)
          await NotificationPermissionService.markPermissionRequestMade();
          
          // First time - request permission using permission_handler
          AppLogger.info('🤖 Requesting Android notification permission...');
          final result = await ph.Permission.notification.request();
          AppLogger.info('🤖 Android permission result: $result');
          
          if (result.isGranted) {
            AppLogger.info('✅ Android notifications granted');
          } else if (result.isDenied) {
            AppLogger.info('❌ Android notifications denied');
          } else if (result.isPermanentlyDenied) {
            AppLogger.info('⚠️ Android notifications permanently denied');
          }
        } else if (status.isGranted) {
          AppLogger.info('✅ Android notifications already granted');
        } else if (status.isPermanentlyDenied) {
          AppLogger.info('⚠️ Android notifications permanently denied - user must enable in settings');
        }
      } else if (Platform.isIOS) {
        // iOS: Use Firebase for iOS-specific permission flow (no coordination needed)
        AppLogger.info('🍎 Requesting iOS notification permissions...');
        
        final settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false, // Explicit permission request
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );
        
        AppLogger.info('🍎 iOS permission result: ${settings.authorizationStatus}');
        AppLogger.info('🍎 iOS settings - Alert: ${settings.alert}, Badge: ${settings.badge}, Sound: ${settings.sound}');
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          AppLogger.info('✅ iOS notifications fully authorized');
        } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
          AppLogger.info('📱 iOS notifications provisionally authorized');
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          AppLogger.info('❌ iOS notifications denied');
        } else {
          AppLogger.info('🤔 iOS notification permission not determined');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error setting up platform permissions: $e');
    }
  }

  static Future<void> _handleIOSSetup() async {
    try {
      // Wait for APNS token to be available
      String? apnsToken = await _messaging!.getAPNSToken();
      if (apnsToken != null) {
        AppLogger.info('📱 APNS token available: ${apnsToken.substring(0, 20)}...');
      } else {
        AppLogger.info('⏳ Waiting for APNS token...');
        // Wait up to 10 seconds for APNS token
        int attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _messaging!.getAPNSToken();
          attempts++;
          if (apnsToken != null) {
            AppLogger.info('📱 APNS token received after ${attempts}s: ${apnsToken.substring(0, 20)}...');
            break;
          }
        }
        if (apnsToken == null) {
          AppLogger.info('⚠️ APNS token not available after 10 seconds - notifications may not work');
        }
      }

      // FIXED: Only get iOS notification settings on iOS (avoid Android dialog triggers)
      if (Platform.isIOS) {
        final settings = await _messaging!.getNotificationSettings();
        AppLogger.info('🍎 iOS-specific notification settings:');
        AppLogger.info('   Alert: ${settings.alert}');
        AppLogger.info('   Badge: ${settings.badge}');
        AppLogger.info('   Sound: ${settings.sound}');
        AppLogger.info('   Lock Screen: ${settings.lockScreen}');
        AppLogger.info('   Notification Center: ${settings.notificationCenter}');
      }
      
      if (apnsToken != null) {
        AppLogger.info('📱 APNS Token Length: ${apnsToken.length}');
        AppLogger.info('📱 APNS Token (first 20 chars): ${apnsToken.substring(0, 20)}...');
        
        // Determine if we're in development or production mode
        bool isDebugMode = false;
        assert(() {
          isDebugMode = true;
          return true;
        }());
        
        AppLogger.info('🔧 Build Mode: ${isDebugMode ? "DEBUG (Development APNS)" : "RELEASE (Production APNS)"}');
        AppLogger.info('🔧 Expected APNS Environment: ${isDebugMode ? "sandbox" : "production"}');
      }
    } catch (e) {
      AppLogger.error('❌ Error setting up iOS notifications: $e');
    }
  }

  static Future<void> _saveTokenToFirebase() async {
    if (_token != null) {
      try {
        // TODO: Save token to Firestore for server to use
        // We'll implement this when we add the server-side component
        AppLogger.info('💾 Token ready to save: $_token');
      } catch (e) {
        AppLogger.error('❌ Error saving token: $e');
      }
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('🔔 Received foreground message: ${message.messageId}');
    AppLogger.info('📱 Message data: ${message.data}');
    AppLogger.info('📢 Notification: ${message.notification?.title} - ${message.notification?.body}');
    
    // 📊 iOS-specific analytics: Track notification received in foreground
    FirebaseAnalytics.instance.logEvent(
      name: 'notification_received_foreground',
      parameters: {
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'message_id': message.messageId ?? 'unknown',
        'notification_type': message.data['type'] ?? 'unknown',
        'symbol': message.data['symbol'] ?? 'unknown',
        'timeframe': message.data['timeframe'] ?? 'unknown',
        'has_notification': message.notification != null,
        'title': message.notification?.title ?? 'no_title',
      },
    );
    
    // Handle trading tip notifications
    if (message.data['type'] == 'trading_tip') {
      AppLogger.info('📈 Trading tip received in foreground: ${message.data['symbol']}');
      
      // 📊 Track trading tip specific reception
      FirebaseAnalytics.instance.logEvent(
        name: 'trading_tip_notification_received',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'symbol': message.data['symbol'] ?? 'unknown',
          'timeframe': message.data['timeframe'] ?? 'unknown',
          'received_in': 'foreground',
        },
      );
      
      _showInAppNotification(message);
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('👆 Notification opened app: ${message.messageId}');
    AppLogger.info('📱 Message data: ${message.data}');
    
    // 📊 iOS-specific analytics: Track notification opened/clicked
    FirebaseAnalytics.instance.logEvent(
      name: 'notification_opened_app',
      parameters: {
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'message_id': message.messageId ?? 'unknown',
        'notification_type': message.data['type'] ?? 'unknown',
        'symbol': message.data['symbol'] ?? 'unknown',
        'timeframe': message.data['timeframe'] ?? 'unknown',
        'opened_from': 'background_tap',
      },
    );
    
    // Handle trading tip notifications
    if (message.data['type'] == 'trading_tip') {
      AppLogger.info('📈 Trading tip notification tapped: ${message.data['symbol']}');
      
      // 📊 Track trading tip notification tap
      FirebaseAnalytics.instance.logEvent(
        name: 'trading_tip_notification_tapped',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'symbol': message.data['symbol'] ?? 'unknown',
          'timeframe': message.data['timeframe'] ?? 'unknown',
          'tap_source': 'notification_center',
        },
      );
      
      _navigateToTradingTip(message);
    }
  }

  /// Show in-app notification when app is in foreground
  static void _showInAppNotification(RemoteMessage message) {
    if (_navigatorKey?.currentContext != null) {
      // 📊 Track in-app notification display
      FirebaseAnalytics.instance.logEvent(
        name: 'in_app_notification_shown',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'notification_title': message.notification?.title ?? 'New Trading Signal',
          'symbol': message.data['symbol'] ?? 'unknown',
          'timeframe': message.data['timeframe'] ?? 'unknown',
        },
      );
      
      final context = _navigatorKey!.currentContext!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'New Trading Signal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.notification?.body ?? ''),
            ],
          ),
          backgroundColor: const Color(0xFF00D4AA),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // 📊 Track in-app notification action button tap
              FirebaseAnalytics.instance.logEvent(
                name: 'in_app_notification_action_tapped',
                parameters: {
                  'platform': Platform.isIOS ? 'iOS' : 'Android',
                  'symbol': message.data['symbol'] ?? 'unknown',
                  'timeframe': message.data['timeframe'] ?? 'unknown',
                  'action': 'view_trading_tip',
                },
              );
              
              _navigateToTradingTip(message);
            },
          ),
        ),
      );
    }
  }

  /// Navigate to specific trading tip when notification is tapped
  static void _navigateToTradingTip(RemoteMessage message) {
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;
      final symbol = message.data['symbol'];
      final timeframe = message.data['timeframe'] ?? message.data['target_timeframe'];
      final targetTimeframe = message.data['target_timeframe'] ?? timeframe;
      
      AppLogger.info('🧭 Navigating to trading tip:');
      AppLogger.info('   Symbol: $symbol');
      AppLogger.info('   Timeframe: $timeframe');
      AppLogger.info('   Target Timeframe: $targetTimeframe');
      AppLogger.info('   Full data: ${message.data}');
      
      // 📊 Track navigation to trading tip from notification
      FirebaseAnalytics.instance.logEvent(
        name: 'notification_navigation_success',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'symbol': symbol ?? 'unknown',
          'timeframe': timeframe ?? 'unknown',
          'target_timeframe': targetTimeframe ?? 'unknown',
          'navigation_source': 'notification_tap',
        },
      );
      
      // Navigate to trading tip screen with timeframe-specific routing
      Navigator.of(context).pushNamed(
        '/trading_tip',
        arguments: {
          'symbol': symbol,
          'timeframe': timeframe,
          'target_timeframe': targetTimeframe, // Ensure we have the target timeframe
          'data': message.data,
          'from_notification': true, // Flag to trigger rating popup
        },
      );
      
      // 🌟 Trigger rating popup for engaged notification users
      AppRatingService.handleNotificationArrival(context);
    }
  }

  /// FIXED: Check if notifications are enabled (platform-specific)
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (_messaging == null) return false;
      
      if (Platform.isAndroid) {
        // Android: Use permission_handler to avoid Firebase dialog triggers
        final status = await ph.Permission.notification.status;
        return status.isGranted;
      } else {
        // iOS: Use Firebase for iOS-specific checking
        final settings = await _messaging!.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
    } catch (e) {
      AppLogger.error('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// FIXED: Test notification setup (platform-specific)
  static Future<void> testNotificationSetup() async {
    try {
      AppLogger.info('🧪 Testing notification setup...');
      
      // Check if messaging is initialized
      if (_messaging == null) {
        AppLogger.info('❌ Firebase Messaging not initialized');
        return;
      }
      
      // Platform-specific permission checking
      if (Platform.isAndroid) {
        // Android: Use permission_handler to avoid triggering dialogs
        final status = await ph.Permission.notification.status;
        AppLogger.info('📋 Android notification permission: $status');
        AppLogger.info('   Granted: ${status.isGranted}');
        AppLogger.info('   Denied: ${status.isDenied}');
        AppLogger.info('   Permanently Denied: ${status.isPermanentlyDenied}');
      } else {
        // iOS: Use Firebase for detailed settings
        final settings = await _messaging!.getNotificationSettings();
        AppLogger.info('📋 iOS notification settings:');
        AppLogger.info('   Authorization: ${settings.authorizationStatus}');
        AppLogger.info('   Alert: ${settings.alert}');
        AppLogger.info('   Badge: ${settings.badge}');
        AppLogger.info('   Sound: ${settings.sound}');
      }
      
      // Check token
      final token = await _messaging!.getToken();
      AppLogger.info('🔑 Current FCM token: $token');
      
      // Check topic subscription
      AppLogger.info('📢 Subscribed to trading_tips topic');
      
      AppLogger.info('✅ Notification setup test completed');
      
    } catch (e) {
      AppLogger.error('❌ Error testing notification setup: $e');
    }
  }

  static String? get token => _token;
} 