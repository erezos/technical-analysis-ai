import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'app_logger.dart';

/// ANR Prevention Utilities
/// 
/// This class provides utilities to prevent Application Not Responding (ANR) errors
/// by managing heavy operations, UI rendering optimization, and background processing.
class ANRPrevention {
  
  /// Execute heavy computation in isolate to prevent main thread blocking
  static Future<T> executeInIsolate<T>(
    T Function(dynamic) computation, {
    String? debugName,
    dynamic message,
  }) async {
    if (kDebugMode && debugName != null) {
      AppLogger.info('🔄 [ANR] Starting isolate computation: $debugName');
    }
    
    try {
      final result = await compute(computation, message);
      
      if (kDebugMode && debugName != null) {
        AppLogger.info('✅ [ANR] Completed isolate computation: $debugName');
      }
      
      return result;
    } catch (e) {
      AppLogger.error('❌ [ANR] Isolate computation failed ($debugName): $e');
      rethrow;
    }
  }
  
  /// Execute async operation with timeout to prevent indefinite blocking
  static Future<T> executeWithTimeout<T>(
    Future<T> operation, {
    Duration timeout = const Duration(seconds: 10),
    String? debugName,
  }) async {
    if (kDebugMode && debugName != null) {
      AppLogger.info('⏱️ [ANR] Starting timed operation: $debugName');
    }
    
    try {
      final result = await operation.timeout(timeout);
      
      if (kDebugMode && debugName != null) {
        AppLogger.info('✅ [ANR] Completed timed operation: $debugName');
      }
      
      return result;
    } on TimeoutException {
      AppLogger.error('⏰ [ANR] Operation timed out ($debugName) after ${timeout.inSeconds}s');
      rethrow;
    } catch (e) {
      AppLogger.error('❌ [ANR] Timed operation failed ($debugName): $e');
      rethrow;
    }
  }
  
  /// Batch UI updates to prevent excessive rebuilds
  static void batchUIUpdates(VoidCallback updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        updates();
      } else {
        // Defer to next frame if currently building
        WidgetsBinding.instance.scheduleFrameCallback((_) {
          updates();
        });
      }
    });
  }
  
  /// Yield control to prevent blocking main thread during loops
  static Future<void> yieldToMainThread() async {
    await Future.delayed(Duration.zero);
  }
  
  /// Process large lists in chunks to prevent ANR
  static Future<List<T>> processListInChunks<T, R>(
    List<R> items,
    T Function(R item) processor, {
    int chunkSize = 50,
    String? debugName,
  }) async {
    final results = <T>[];
    
    if (kDebugMode && debugName != null) {
      AppLogger.info('📋 [ANR] Processing ${items.length} items in chunks of $chunkSize: $debugName');
    }
    
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      
      for (final item in chunk) {
        results.add(processor(item));
      }
      
      // Yield to main thread after each chunk
      await yieldToMainThread();
    }
    
    if (kDebugMode && debugName != null) {
      AppLogger.info('✅ [ANR] Completed processing ${results.length} items: $debugName');
    }
    
    return results;
  }
  
  /// Debounce rapid operations to prevent overwhelming the main thread
  static Timer? _debounceTimer;
  
  static void debounce(
    VoidCallback operation, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, operation);
  }
  
  /// Monitor frame rendering performance
  static void startFrameMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final frameDuration = timing.totalSpan;
          if (frameDuration > const Duration(milliseconds: 16)) {
            AppLogger.warning('🐌 [ANR] Slow frame detected: ${frameDuration.inMilliseconds}ms');
          }
        }
      });
    }
  }
  
  /// Cleanup resources to prevent memory leaks that can cause ANR
  static void cleanup() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

/// Mixin for widgets to easily use ANR prevention
mixin ANRPreventionMixin<T extends StatefulWidget> on State<T> {
  
  /// Execute heavy operation without blocking UI
  Future<R> executeHeavyOperation<R>(
    R Function() operation, {
    String? debugName,
  }) {
    return ANRPrevention.executeInIsolate(
      (dynamic _) => operation(),
      debugName: debugName ?? runtimeType.toString(),
      message: null,
    );
  }
  
  /// Batch multiple setState calls
  void batchSetState(VoidCallback updates) {
    ANRPrevention.batchUIUpdates(() {
      if (mounted) {
        setState(updates);
      }
    });
  }
  
  @override
  void dispose() {
    ANRPrevention.cleanup();
    super.dispose();
  }
}

/// Extension for Future to add ANR prevention
extension ANRPreventionFuture<T> on Future<T> {
  
  /// Add timeout to prevent indefinite waiting
  Future<T> withANRTimeout({
    Duration timeout = const Duration(seconds: 10),
    String? debugName,
  }) {
    return ANRPrevention.executeWithTimeout(
      this,
      timeout: timeout,
      debugName: debugName,
    );
  }
}
