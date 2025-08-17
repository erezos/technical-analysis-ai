import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/app_logger.dart';

/// ANR Monitoring Service
/// 
/// Monitors app performance and detects potential ANR conditions
/// Reports performance metrics to Firebase Analytics for tracking
class ANRMonitoringService {
  static final ANRMonitoringService _instance = ANRMonitoringService._internal();
  factory ANRMonitoringService() => _instance;
  ANRMonitoringService._internal();
  
  static bool _isInitialized = false;
  static Timer? _performanceTimer;
  static int _slowFrameCount = 0;
  static int _totalFrameCount = 0;
  static DateTime _sessionStart = DateTime.now();
  
  /// Initialize ANR monitoring
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      AppLogger.info('🔍 [ANR] Initializing ANR monitoring service...');
      
      _sessionStart = DateTime.now();
      
      // Start frame monitoring
      _startFrameMonitoring();
      
      // Start periodic performance checks
      _startPerformanceMonitoring();
      
      // Monitor memory usage
      _startMemoryMonitoring();
      
      _isInitialized = true;
      AppLogger.info('✅ [ANR] ANR monitoring initialized successfully');
      
    } catch (e) {
      AppLogger.error('❌ [ANR] Failed to initialize ANR monitoring: $e');
    }
  }
  
  /// Start monitoring frame rendering performance
  static void _startFrameMonitoring() {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        _totalFrameCount++;
        
        final frameDuration = timing.totalSpan;
        final buildDuration = timing.buildDuration;
        final rasterDuration = timing.rasterDuration;
        
        // Detect slow frames (>16ms for 60fps)
        if (frameDuration > const Duration(milliseconds: 16)) {
          _slowFrameCount++;
          
          AppLogger.warning(
            '🐌 [ANR] Slow frame detected: '
            'Total: ${frameDuration.inMilliseconds}ms, '
            'Build: ${buildDuration.inMilliseconds}ms, '
            'Raster: ${rasterDuration.inMilliseconds}ms'
          );
          
          // Report critical slow frames
          if (frameDuration > const Duration(milliseconds: 100)) {
            _reportSlowFrame(frameDuration, buildDuration, rasterDuration);
          }
        }
        
        // Detect potential ANR conditions (>5 seconds)
        if (frameDuration > const Duration(seconds: 5)) {
          _reportPotentialANR(frameDuration, buildDuration, rasterDuration);
        }
      }
    });
  }
  
  /// Start periodic performance monitoring
  static void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _checkPerformanceMetrics(),
    );
  }
  
  /// Start memory monitoring
  static void _startMemoryMonitoring() {
    if (kDebugMode) {
      Timer.periodic(const Duration(minutes: 5), (timer) {
        _checkMemoryUsage();
      });
    }
  }
  
  /// Check current performance metrics
  static void _checkPerformanceMetrics() {
    if (_totalFrameCount == 0) return;
    
    final slowFramePercentage = (_slowFrameCount / _totalFrameCount) * 100;
    final sessionDuration = DateTime.now().difference(_sessionStart);
    
    AppLogger.info(
      '📊 [ANR] Performance metrics: '
      'Slow frames: ${slowFramePercentage.toStringAsFixed(1)}% '
      '($_slowFrameCount/$_totalFrameCount), '
      'Session: ${sessionDuration.inMinutes}min'
    );
    
    // Report if slow frame percentage is high
    if (slowFramePercentage > 10.0) {
      _reportHighSlowFrameRate(slowFramePercentage, sessionDuration);
    }
    
    // Reset counters every hour
    if (sessionDuration.inHours > 0 && sessionDuration.inMinutes % 60 == 0) {
      _resetCounters();
    }
  }
  
  /// Check memory usage
  static void _checkMemoryUsage() {
    // This is a simplified memory check
    // In production, you might want to use more sophisticated memory monitoring
    AppLogger.info('🧠 [ANR] Memory check performed');
  }
  
  /// Report slow frame to analytics
  static void _reportSlowFrame(
    Duration totalDuration,
    Duration buildDuration,
    Duration rasterDuration,
  ) {
    FirebaseAnalytics.instance.logEvent(
      name: 'anr_slow_frame',
      parameters: {
        'total_ms': totalDuration.inMilliseconds,
        'build_ms': buildDuration.inMilliseconds,
        'raster_ms': rasterDuration.inMilliseconds,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'session_duration_min': DateTime.now().difference(_sessionStart).inMinutes,
      },
    );
  }
  
  /// Report potential ANR condition
  static void _reportPotentialANR(
    Duration totalDuration,
    Duration buildDuration,
    Duration rasterDuration,
  ) {
    AppLogger.error(
      '🚨 [ANR] Potential ANR detected: '
      'Frame took ${totalDuration.inSeconds} seconds!'
    );
    
    FirebaseAnalytics.instance.logEvent(
      name: 'anr_potential_anr',
      parameters: {
        'total_seconds': totalDuration.inSeconds,
        'build_ms': buildDuration.inMilliseconds,
        'raster_ms': rasterDuration.inMilliseconds,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'session_duration_min': DateTime.now().difference(_sessionStart).inMinutes,
      },
    );
  }
  
  /// Report high slow frame rate
  static void _reportHighSlowFrameRate(
    double percentage,
    Duration sessionDuration,
  ) {
    AppLogger.warning(
      '⚠️ [ANR] High slow frame rate: ${percentage.toStringAsFixed(1)}%'
    );
    
    FirebaseAnalytics.instance.logEvent(
      name: 'anr_high_slow_frame_rate',
      parameters: {
        'slow_frame_percentage': percentage,
        'total_frames': _totalFrameCount,
        'slow_frames': _slowFrameCount,
        'session_duration_min': sessionDuration.inMinutes,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }
  
  /// Reset performance counters
  static void _resetCounters() {
    AppLogger.info('🔄 [ANR] Resetting performance counters');
    _slowFrameCount = 0;
    _totalFrameCount = 0;
  }
  
  /// Report custom ANR event
  static void reportCustomEvent({
    required String eventName,
    required String operation,
    required Duration duration,
    Map<String, Object>? additionalParams,
  }) {
    final params = <String, Object>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'platform': Platform.isIOS ? 'ios' : 'android',
      if (additionalParams != null) ...additionalParams,
    };
    
    FirebaseAnalytics.instance.logEvent(
      name: 'anr_$eventName',
      parameters: params,
    );
    
    AppLogger.info(
      '📊 [ANR] Custom event: $eventName, '
      'Operation: $operation, '
      'Duration: ${duration.inMilliseconds}ms'
    );
  }
  
  /// Get current performance statistics
  static Map<String, Object> getPerformanceStats() {
    final sessionDuration = DateTime.now().difference(_sessionStart);
    final slowFramePercentage = _totalFrameCount > 0 
        ? (_slowFrameCount / _totalFrameCount) * 100 
        : 0.0;
    
    return {
      'session_duration_minutes': sessionDuration.inMinutes,
      'total_frames': _totalFrameCount,
      'slow_frames': _slowFrameCount,
      'slow_frame_percentage': slowFramePercentage,
      'is_monitoring': _isInitialized,
    };
  }
  
  /// Dispose of monitoring resources
  static void dispose() {
    AppLogger.info('🧹 [ANR] Disposing ANR monitoring service');
    
    _performanceTimer?.cancel();
    _performanceTimer = null;
    
    // Report final session stats
    final stats = getPerformanceStats();
    FirebaseAnalytics.instance.logEvent(
      name: 'anr_session_end',
      parameters: stats,
    );
    
    _isInitialized = false;
  }
}

/// Extension for easy ANR monitoring integration
extension ANRMonitoringExtension on Widget {
  
  /// Wrap widget with ANR monitoring
  Widget withANRMonitoring(String operationName) {
    return Builder(
      builder: (context) {
        final stopwatch = Stopwatch()..start();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          
          if (stopwatch.elapsedMilliseconds > 100) {
            ANRMonitoringService.reportCustomEvent(
              eventName: 'slow_widget_build',
              operation: operationName,
              duration: stopwatch.elapsed,
            );
          }
        });
        
        return this;
      },
    );
  }
}