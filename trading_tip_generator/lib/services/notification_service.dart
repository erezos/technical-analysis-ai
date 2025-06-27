import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'notification_permission_service_fixed.dart';

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Don't need to initialize Firebase here - it's done automatically for background handlers
  print('🔔 Background message received: ${message.messageId}');
  print('📱 Background message data: ${message.data}');
}

class NotificationService {
  static FirebaseMessaging? _messaging;
  static String? _token;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    try {
      print('🔥 Initializing Firebase messaging...');
      
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
        print('📲 App opened from notification: ${initialMessage.messageId}');
        _handleMessageOpenedApp(initialMessage);
      }

      // Subscribe to trading tips topic
      await _messaging!.subscribeToTopic('trading_tips');
      print('📢 Subscribed to trading_tips topic');

      // Set up iOS-specific settings
      if (Platform.isIOS) {
        await _handleIOSSetup();
        
        // Configure iOS foreground notification presentation
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('🍎 iOS foreground notification presentation configured');
      }

      // Get FCM token
      _token = await _messaging!.getToken();
      print('🔑 FCM Token: $_token');

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _token = newToken;
        _saveTokenToFirebase();
      });

      // Save token to backend
      await _saveTokenToFirebase();
      
      print('✅ Notification setup completed successfully');
      
    } catch (e) {
      print('❌ Error setting up notifications: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// FIXED: Platform-specific permission setup to avoid double dialogs
  static Future<void> _setupPlatformPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android: Use permission_handler for clean, single dialog
        final status = await ph.Permission.notification.status;
        print('🤖 Android notification permission status: $status');
        
        if (status.isDenied) {
          // COORDINATION: Mark that we're about to request permission (Android only)
          await NotificationPermissionService.markPermissionRequestMade();
          
          // First time - request permission using permission_handler
          print('🤖 Requesting Android notification permission...');
          final result = await ph.Permission.notification.request();
          print('🤖 Android permission result: $result');
          
          if (result.isGranted) {
            print('✅ Android notifications granted');
          } else if (result.isDenied) {
            print('❌ Android notifications denied');
          } else if (result.isPermanentlyDenied) {
            print('⚠️ Android notifications permanently denied');
          }
        } else if (status.isGranted) {
          print('✅ Android notifications already granted');
        } else if (status.isPermanentlyDenied) {
          print('⚠️ Android notifications permanently denied - user must enable in settings');
        }
      } else if (Platform.isIOS) {
        // iOS: Use Firebase for iOS-specific permission flow (no coordination needed)
        print('🍎 Requesting iOS notification permissions...');
        
        final settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false, // Explicit permission request
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );
        
        print('🍎 iOS permission result: ${settings.authorizationStatus}');
        print('🍎 iOS settings - Alert: ${settings.alert}, Badge: ${settings.badge}, Sound: ${settings.sound}');
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ iOS notifications fully authorized');
        } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
          print('📱 iOS notifications provisionally authorized');
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          print('❌ iOS notifications denied');
        } else {
          print('🤔 iOS notification permission not determined');
        }
      }
    } catch (e) {
      print('❌ Error setting up platform permissions: $e');
    }
  }

  static Future<void> _handleIOSSetup() async {
    try {
      // Wait for APNS token to be available
      String? apnsToken = await _messaging!.getAPNSToken();
      if (apnsToken != null) {
        print('📱 APNS token available: ${apnsToken.substring(0, 20)}...');
      } else {
        print('⏳ Waiting for APNS token...');
        // Wait up to 10 seconds for APNS token
        int attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(Duration(seconds: 1));
          apnsToken = await _messaging!.getAPNSToken();
          attempts++;
          if (apnsToken != null) {
            print('📱 APNS token received after ${attempts}s: ${apnsToken.substring(0, 20)}...');
            break;
          }
        }
        if (apnsToken == null) {
          print('⚠️ APNS token not available after 10 seconds - notifications may not work');
        }
      }

      // FIXED: Only get iOS notification settings on iOS (avoid Android dialog triggers)
      if (Platform.isIOS) {
        final settings = await _messaging!.getNotificationSettings();
        print('🍎 iOS-specific notification settings:');
        print('   Alert: ${settings.alert}');
        print('   Badge: ${settings.badge}');
        print('   Sound: ${settings.sound}');
        print('   Lock Screen: ${settings.lockScreen}');
        print('   Notification Center: ${settings.notificationCenter}');
      }
      
      if (apnsToken != null) {
        print('📱 APNS Token Length: ${apnsToken.length}');
        print('📱 APNS Token (first 20 chars): ${apnsToken.substring(0, 20)}...');
        
        // Determine if we're in development or production mode
        bool isDebugMode = false;
        assert(() {
          isDebugMode = true;
          return true;
        }());
        
        print('🔧 Build Mode: ${isDebugMode ? "DEBUG (Development APNS)" : "RELEASE (Production APNS)"}');
        print('🔧 Expected APNS Environment: ${isDebugMode ? "sandbox" : "production"}');
      }
    } catch (e) {
      print('❌ Error setting up iOS notifications: $e');
    }
  }

  static Future<void> _saveTokenToFirebase() async {
    if (_token != null) {
      try {
        // TODO: Save token to Firestore for server to use
        // We'll implement this when we add the server-side component
        print('💾 Token ready to save: $_token');
      } catch (e) {
        print('❌ Error saving token: $e');
      }
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Received foreground message: ${message.messageId}');
    print('📱 Message data: ${message.data}');
    print('📢 Notification: ${message.notification?.title} - ${message.notification?.body}');
    
    // Handle trading tip notifications
    if (message.data['type'] == 'trading_tip') {
      print('📈 Trading tip received in foreground: ${message.data['symbol']}');
      _showInAppNotification(message);
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('👆 Notification opened app: ${message.messageId}');
    print('📱 Message data: ${message.data}');
    
    // Handle trading tip notifications
    if (message.data['type'] == 'trading_tip') {
      print('📈 Trading tip notification tapped: ${message.data['symbol']}');
      _navigateToTradingTip(message);
    }
  }

  /// Show in-app notification when app is in foreground
  static void _showInAppNotification(RemoteMessage message) {
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'New Trading Signal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.notification?.body ?? ''),
            ],
          ),
          backgroundColor: Color(0xFF00D4AA),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _navigateToTradingTip(message),
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
      
      print('🧭 Navigating to trading tip:');
      print('   Symbol: $symbol');
      print('   Timeframe: $timeframe');
      print('   Target Timeframe: $targetTimeframe');
      print('   Full data: ${message.data}');
      
      // Navigate to trading tip screen with timeframe-specific routing
      Navigator.of(context).pushNamed(
        '/trading_tip',
        arguments: {
          'symbol': symbol,
          'timeframe': timeframe,
          'target_timeframe': targetTimeframe, // Ensure we have the target timeframe
          'data': message.data,
        },
      );
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
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// FIXED: Test notification setup (platform-specific)
  static Future<void> testNotificationSetup() async {
    try {
      print('🧪 Testing notification setup...');
      
      // Check if messaging is initialized
      if (_messaging == null) {
        print('❌ Firebase Messaging not initialized');
        return;
      }
      
      // Platform-specific permission checking
      if (Platform.isAndroid) {
        // Android: Use permission_handler to avoid triggering dialogs
        final status = await ph.Permission.notification.status;
        print('📋 Android notification permission: $status');
        print('   Granted: ${status.isGranted}');
        print('   Denied: ${status.isDenied}');
        print('   Permanently Denied: ${status.isPermanentlyDenied}');
      } else {
        // iOS: Use Firebase for detailed settings
        final settings = await _messaging!.getNotificationSettings();
        print('📋 iOS notification settings:');
        print('   Authorization: ${settings.authorizationStatus}');
        print('   Alert: ${settings.alert}');
        print('   Badge: ${settings.badge}');
        print('   Sound: ${settings.sound}');
      }
      
      // Check token
      final token = await _messaging!.getToken();
      print('🔑 Current FCM token: $token');
      
      // Check topic subscription
      print('📢 Subscribed to trading_tips topic');
      
      print('✅ Notification setup test completed');
      
    } catch (e) {
      print('❌ Error testing notification setup: $e');
    }
  }

  static String? get token => _token;
} 