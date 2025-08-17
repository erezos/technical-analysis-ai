import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'app_logger.dart';

/// GPU Optimization Utilities
/// 
/// This class provides utilities to optimize GPU usage and prevent
/// GPU-related ANR issues by managing rendering performance.
class GPUOptimization {
  
  /// Optimize widget for better GPU performance
  static Widget optimizeForGPU(Widget child, {String? debugName}) {
    return RepaintBoundary(
      child: child,
    );
  }
  
  /// Create optimized container with reduced overdraw
  static Widget optimizedContainer({
    required Widget child,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          border: border,
        ),
        child: child,
      ),
    );
  }
  
  /// Optimized image widget that prevents GPU memory issues
  static Widget optimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit? fit,
    bool isAsset = true,
  }) {
    return RepaintBoundary(
      child: ClipRRect(
        child: isAsset
            ? Image.asset(
                imagePath,
                width: width,
                height: height,
                fit: fit ?? BoxFit.cover,
                cacheWidth: width?.toInt(),
                cacheHeight: height?.toInt(),
                filterQuality: FilterQuality.medium,
              )
            : Image.network(
                imagePath,
                width: width,
                height: height,
                fit: fit ?? BoxFit.cover,
                cacheWidth: width?.toInt(),
                cacheHeight: height?.toInt(),
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: width,
                    height: height,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.error('[GPU] Image load error: $error');
                  return SizedBox(
                    width: width,
                    height: height,
                    child: const Icon(Icons.error, color: Colors.grey),
                  );
                },
              ),
      ),
    );
  }
  
  /// Optimized list view that prevents GPU overdraw
  static Widget optimizedListView({
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
  }) {
    return RepaintBoundary(
      child: ListView.builder(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: itemBuilder(context, index),
          );
        },
        // Optimize for performance
        cacheExtent: 250.0,
        physics: const BouncingScrollPhysics(),
      ),
    );
  }
  
  /// Optimized animated widget that reduces GPU load
  static Widget optimizedAnimatedBuilder({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: builder,
        child: child != null ? RepaintBoundary(child: child) : null,
      ),
    );
  }
  
  /// Monitor GPU performance (debug only)
  static void startGPUMonitoring() {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        startGPUMonitoring();
      });
      return;
    }
    
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final buildDuration = timing.buildDuration;
        final rasterDuration = timing.rasterDuration;
        
        if (buildDuration > const Duration(milliseconds: 16)) {
          AppLogger.warning('[GPU] Slow build: ${buildDuration.inMilliseconds}ms');
        }
        
        if (rasterDuration > const Duration(milliseconds: 16)) {
          AppLogger.warning('[GPU] Slow raster: ${rasterDuration.inMilliseconds}ms');
        }
      }
    });
  }
  
  /// Reduce animation complexity during heavy operations
  static void reduceAnimationComplexity() {
    // Temporarily disable animations if performance is poor
    SchedulerBinding.instance.addTimingsCallback((timings) {
      bool hasSlowFrames = timings.any((timing) => 
        timing.totalSpan > const Duration(milliseconds: 32));
      
      if (hasSlowFrames) {
        AppLogger.info('[GPU] Reducing animation complexity due to slow frames');
        // You can implement animation reduction logic here
      }
    });
  }
}

/// Mixin for widgets to easily use GPU optimization
mixin GPUOptimizationMixin<T extends StatefulWidget> on State<T> {
  
  /// Wrap widget with GPU optimization
  Widget optimizeWidget(Widget child, {String? debugName}) {
    return GPUOptimization.optimizeForGPU(
      child,
      debugName: debugName ?? runtimeType.toString(),
    );
  }
  
  /// Create optimized animated widget
  Widget buildOptimizedAnimation({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    return GPUOptimization.optimizedAnimatedBuilder(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

/// Extension for BuildContext to easily access GPU optimization
extension GPUOptimizationContext on BuildContext {
  
  /// Get optimized container
  Widget optimizedContainer({
    required Widget child,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return GPUOptimization.optimizedContainer(
      child: child,
      color: color,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      border: border,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
    );
  }
}
