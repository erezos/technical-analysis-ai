import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Premium fintech button system inspired by top trading apps
class PremiumFintechButtons {
  
  /// Primary action button - for main trading actions like "Start Trading" - RESPONSIVE
  static Widget primaryAction({
    required String text,
    required VoidCallback onPressed,
    required BuildContext context, // Added context for responsive sizing
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    double? width,
    String? subtitle, // Added subtitle support
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive sizing - BIGGER button (8% of screen height instead of 7%)
    final buttonHeight = (screenHeight * 0.08).clamp(56.0, 80.0);
    final fontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    final subtitleSize = (screenWidth * 0.025).clamp(12.0, 14.0);
    final iconSize = (fontSize * 1.2).clamp(18.0, 24.0);
    final borderRadius = (buttonHeight * 0.25).clamp(12.0, 18.0);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: buttonHeight,
      child: Material(
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isEnabled && !isLoading ? () {
            // Log event for Copy Traders button click
            print('📊 [ANALYTICS] Copy Traders button clicked');
            FirebaseAnalytics.instance.logEvent(name: 'copy_traders_button_click', parameters: {'button_name': 'Copy Traders'});
            HapticFeedback.mediumImpact();
            onPressed();
          } : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEnabled ? [
                  const Color(0xFFFF6B6B),
                  const Color(0xFFFF8E53),
                  const Color(0xFFFFB830),
                ] : [
                  const Color(0xFF3A3A3A),
                  const Color(0xFF2A2A2A),
                ],
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFFF8E53).withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ] : [],
            ),
            child: Center(
              child: isLoading 
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: iconSize),
                        SizedBox(width: fontSize * 0.5),
                      ],
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (icon != null) ...[
                        SizedBox(width: fontSize * 0.5),
                        Icon(Icons.arrow_forward, color: Colors.white, size: iconSize * 0.8),
                      ],
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  /// Glassmorphic button - for secondary actions
  static Widget glassmorphic({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? primaryColor,
    double? width,
  }) {
    final color = primaryColor ?? const Color(0xFF00D4AA);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Neomorphic button - for card actions
  static Widget neomorphic({
    required Widget child,
    required VoidCallback onPressed,
    double? width,
    double? height,
    Color? backgroundColor,
  }) {
    final bgColor = backgroundColor ?? const Color(0xFF1E1E1E);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height ?? 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  /// Floating action button - for quick actions
  static Widget floatingAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool isExtended = false,
    String? label,
  }) {
    final bgColor = backgroundColor ?? const Color(0xFF00D4AA);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(isExtended ? 28 : 28),
        child: InkWell(
          borderRadius: BorderRadius.circular(isExtended ? 28 : 28),
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          child: Container(
            padding: isExtended 
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
              : const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isExtended ? 28 : 28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (isExtended && label != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stats card button - for displaying metrics
  static Widget statsCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final color = iconColor ?? const Color(0xFF00D4AA);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap != null ? () {
          HapticFeedback.lightImpact();
          onTap();
        } : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E1E),
                Color(0xFF2A2A2A),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 12,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 