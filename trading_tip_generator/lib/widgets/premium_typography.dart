import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

/// Premium typography system for fintech apps
class PremiumTypography {
  
  /// Enhanced title text with gradient and glow effects
  static Widget enhancedTitle({
    required String text,
    double? fontSize,
    bool animated = true,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    final primary = primaryColor ?? const Color(0xFF00D4AA);
    final secondary = secondaryColor ?? const Color(0xFF4ECDC4);
    
    final textWidget = ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize ?? 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: Colors.white,
          shadows: [
            Shadow(
              color: ColorUtils.withOpacity(primary, 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            Shadow(
              color: ColorUtils.withOpacity(Colors.black, 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
    
    if (!animated) return textWidget;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: textWidget,
          ),
        );
      },
    );
  }
  
  /// Glowing text effect
  static Widget glowingText({
    required String text,
    double? fontSize,
    Color? glowColor,
    double glowRadius = 10,
    TextAlign textAlign = TextAlign.center,
  }) {
    final color = glowColor ?? const Color(0xFF00D4AA);
    
    return Stack(
      children: [
        // Glow effect
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize ?? 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = ColorUtils.withOpacity(color, 0.3)
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowRadius),
          ),
        ),
        // Main text
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize ?? 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                color: ColorUtils.withOpacity(color, 0.5),
                blurRadius: glowRadius / 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Animated typewriter effect
  static Widget typewriterText({
    required String text,
    double? fontSize,
    Duration duration = const Duration(milliseconds: 2000),
    Color? textColor,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize ?? 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: textColor ?? Colors.white,
            shadows: [
              Shadow(
                color: ColorUtils.withOpacity(Colors.black, 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Premium subtitle with subtle animations
  static Widget premiumSubtitle({
    required String text,
    double? fontSize,
    Color? textColor,
    bool animated = true,
  }) {
    final color = textColor ?? Colors.grey[300];
    
    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize ?? 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
        shadows: [
          Shadow(
            color: ColorUtils.withOpacity(Colors.black, 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
    
    if (!animated) return textWidget;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: textWidget,
          ),
        );
      },
    );
  }
  
  /// Responsive text that adapts to screen size - BIGGER for better visibility
  static Widget responsiveTitle({
    required String text,
    required BuildContext context,
    bool animated = true,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    
    // BIGGER text sizing (3.5% of screen width instead of 3%)
    final fontSize = (screenWidth * 0.035).clamp(20.0, 32.0);
    
    final textWidget = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF4ECDC4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1, // Force single line
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                color: ColorUtils.withOpacity(const Color(0xFF00D4AA), 0.3),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              Shadow(
                color: ColorUtils.withOpacity(Colors.black, 0.5),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (!animated) return textWidget;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: textWidget,
          ),
        );
      },
    );
  }
} 