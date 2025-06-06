import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static FirebaseMessaging? _messaging;
  static String? _token;

  static Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission for notifications
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
        
        // Subscribe to trading tips topic
        await _messaging!.subscribeToTopic('trading_tips');
        print('Subscribed to trading_tips topic');
        
        // Get the device token
        _token = await _messaging!.getToken();
        print('FCM Token: $_token');
        
        // Save token to Firebase for server to use
        await _saveTokenToFirebase();
        
        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((newToken) {
          _token = newToken;
          _saveTokenToFirebase();
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle background message taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        
      } else {
        print('User declined or has not accepted permission for notifications');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static Future<void> _saveTokenToFirebase() async {
    if (_token != null) {
      try {
        // TODO: Save token to Firestore for server to use
        // We'll implement this when we add the server-side component
        print('Token ready to save: $_token');
      } catch (e) {
        print('Error saving token: $e');
      }
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    // TODO: Show in-app notification or update UI
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification opened app: ${message.messageId}');
    // TODO: Navigate to relevant trading tip
  }

  static String? get token => _token;
} 