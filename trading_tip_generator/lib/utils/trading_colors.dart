import 'package:flutter/material.dart';

/// Enhanced color system for Trading Tip Generator AI
/// Provides semantic colors beyond basic red/green for better accessibility
class TradingColors {
  // Primary trading colors
  static const Color bullish = Color(0xFF00D4AA);      // Current green - for gains
  static const Color bearish = Color(0xFFFF6B6B);      // Softer red - for losses
  static const Color neutral = Color(0xFF8E8E93);      // For neutral states
  static const Color warning = Color(0xFFFF9500);      // For alerts/warnings
  static const Color accent = Color(0xFF4ECDC4);       // Secondary actions
  
  // Background colors
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceBackground = Color(0xFF1A1A1A);
  static const Color primaryBackground = Color(0xFF121212);
  
  // Text colors
  static const Color primaryText = Color(0xFFE1E1E1);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color mutedText = Color(0xFF8E8E93);
  
  // High contrast variants for accessibility
  static const Color bullishHighContrast = Color(0xFF00FF88);
  static const Color bearishHighContrast = Color(0xFFFF4444);
  
  /// Get appropriate color based on gain/loss and accessibility settings
  static Color getTrendColor(bool isGainer, {bool highContrast = false}) {
    if (highContrast) {
      return isGainer ? bullishHighContrast : bearishHighContrast;
    }
    return isGainer ? bullish : bearish;
  }
  
  /// Get trend icon based on gain/loss
  static IconData getTrendIcon(bool isGainer) {
    return isGainer ? Icons.trending_up : Icons.trending_down;
  }
  
  /// Get semantic label for screen readers
  static String getTrendLabel(bool isGainer, double percentage) {
    final direction = isGainer ? 'up' : 'down';
    return '$direction ${percentage.abs().toStringAsFixed(2)} percent';
  }
} 