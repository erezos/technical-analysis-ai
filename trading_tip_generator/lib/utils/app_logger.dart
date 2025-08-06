import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A centralized logging utility for the app that follows Flutter best practices.
/// 
/// This logger provides different log levels and automatically handles
/// production vs development environments. In production, debug logs are
/// automatically disabled to improve performance.
class AppLogger {
  static const String _tag = 'TradingTipAI';
  
  /// Log a debug message (only shown in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 500, // Debug level
      );
    }
  }
  
  /// Log an info message (shown in all modes)
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }
  
  /// Log a warning message
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log an error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log a critical error message
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1200, // Critical level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log Firebase-related messages
  static void firebase(String message) {
    debug('🔥 Firebase: $message', tag: 'Firebase');
  }
  
  /// Log trading-related messages
  static void trading(String message) {
    debug('📈 Trading: $message', tag: 'Trading');
  }
  
  /// Log notification-related messages
  static void notification(String message) {
    debug('🔔 Notification: $message', tag: 'Notification');
  }
  
  /// Log UI-related messages
  static void ui(String message) {
    debug('🎨 UI: $message', tag: 'UI');
  }
  
  /// Log performance-related messages
  static void performance(String message) {
    debug('⚡ Performance: $message', tag: 'Performance');
  }
} 