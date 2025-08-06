import 'package:flutter/material.dart';

/// Utility class for handling color operations with modern Flutter APIs.
/// 
/// This class provides methods to replace deprecated `withOpacity` calls
/// with the new `withValues` method for better precision and performance.
class ColorUtils {
  /// Creates a color with the specified alpha value using the modern API.
  /// 
  /// This replaces the deprecated `withOpacity` method with `withValues`
  /// for better precision and to follow current Flutter best practices.
  /// 
  /// [color] - The base color
  /// [alpha] - The alpha value (0.0 to 1.0)
  /// 
  /// Returns a new color with the specified alpha value.
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
  
  /// Creates a color with opacity using the modern API.
  /// 
  /// This is a convenience method that maintains the same API as `withOpacity`
  /// but uses the modern `withValues` method internally.
  /// 
  /// [color] - The base color
  /// [opacity] - The opacity value (0.0 to 1.0)
  /// 
  /// Returns a new color with the specified opacity.
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Creates a semi-transparent color with 50% opacity.
  static Color semiTransparent(Color color) {
    return color.withValues(alpha: 0.5);
  }
  
  /// Creates a light version of a color (30% opacity).
  static Color light(Color color) {
    return color.withValues(alpha: 0.3);
  }
  
  /// Creates a very light version of a color (15% opacity).
  static Color veryLight(Color color) {
    return color.withValues(alpha: 0.15);
  }
  
  /// Creates a dark version of a color (70% opacity).
  static Color dark(Color color) {
    return color.withValues(alpha: 0.7);
  }
  
  /// Creates a very dark version of a color (85% opacity).
  static Color veryDark(Color color) {
    return color.withValues(alpha: 0.85);
  }
} 