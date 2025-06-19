import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced responsive utilities with accessibility compliance
class ResponsiveUtils {
  // Apple's minimum touch target size
  static const double minTouchTarget = 44.0;
  
  /// Get responsive font size with minimum readability constraints
  static double getResponsiveFontSize(
    BuildContext context, {
    required double base,
    double? smallMobile,
    double? tablet,
    double minSize = 12.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 375;
    final isTablet = screenWidth > 600;
    
    double fontSize = base;
    
    if (isSmallMobile) {
      fontSize = smallMobile ?? base * 0.9; // Gentler scaling
    } else if (isTablet) {
      fontSize = tablet ?? base * 1.1;
    }
    
    // Ensure minimum readability
    return math.max(fontSize, minSize);
  }
  
  /// Get touch-compliant button height
  static double getButtonHeight(
    BuildContext context, {
    double? smallMobile,
    double mobile = 48.0,
    double? tablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 375;
    final isTablet = screenWidth > 600;
    
    double height = mobile;
    
    if (isSmallMobile) {
      height = smallMobile ?? mobile;
    } else if (isTablet) {
      height = tablet ?? mobile * 1.2;
    }
    
    // Always ensure minimum touch target
    return math.max(height, minTouchTarget);
  }
  
  /// Get responsive padding with iPhone 13 mini optimizations
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double? smallMobile,
    double mobile = 16.0,
    double? tablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 375;
    final isTablet = screenWidth > 600;
    
    double padding = mobile;
    
    if (isSmallMobile) {
      padding = smallMobile ?? mobile * 0.75;
    } else if (isTablet) {
      padding = tablet ?? mobile * 1.5;
    }
    
    return EdgeInsets.all(padding);
  }
  
  /// Check if device needs accessibility accommodations
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Check if animations should be reduced
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Get animation duration based on accessibility settings
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
  }) {
    return shouldReduceMotion(context) ? Duration.zero : normal;
  }
  
  /// Get responsive spacing
  static double getSpacing(
    BuildContext context, {
    double? smallMobile,
    double mobile = 16.0,
    double? tablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth <= 375;
    final isTablet = screenWidth > 600;
    
    if (isSmallMobile) {
      return smallMobile ?? mobile * 0.75;
    } else if (isTablet) {
      return tablet ?? mobile * 1.5;
    }
    return mobile;
  }
  
  /// Check if device is small mobile (iPhone 13 mini, etc.)
  static bool isSmallMobile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width <= 375 && size.height <= 812;
  }
  
  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 600 || size.height > 900;
  }
} 