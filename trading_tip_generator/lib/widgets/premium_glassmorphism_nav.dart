import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import '../utils/responsive_utils.dart';
import '../utils/trading_colors.dart';

class PremiumGlassmorphismNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PremiumGlassmorphismNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PremiumGlassmorphismNav> createState() => _PremiumGlassmorphismNavState();
}

class _PremiumGlassmorphismNavState extends State<PremiumGlassmorphismNav>
    with TickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    
    // Glow animation for the selected tab
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = MediaQuery.of(context).size.height;
          final isTablet = screenWidth > 600;
          final isAndroid = Platform.isAndroid;
          
          // Responsive calculations for all devices
          final navHeight = _calculateNavHeight(screenHeight, isTablet, isAndroid);
          final horizontalMargin = screenWidth * (isTablet ? 0.08 : 0.04);
          final cornerRadius = 30.0; // Matches the image design
          
          return Container(
            height: navHeight,
            margin: EdgeInsets.only(
              left: horizontalMargin,
              right: horizontalMargin,
              // No manual bottom margin; SafeArea handles it
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              // Premium glassmorphism background matching the image
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0A0A).withOpacity(0.95), // Much darker
                  const Color(0xFF1A1A1A).withOpacity(0.9),  // Much darker
                  const Color(0xFF0F0F0F).withOpacity(0.95), // Much darker
                ],
              ),
              // Subtle border like in the image
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                // Main shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
                // Inner glow
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    // Remove any overlay - let the background gradient handle it
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      // AI Tips Tab
                      Expanded(
                        child: _buildNavigationTab(
                          index: 0,
                          label: 'AI Tips',
                          isSelected: widget.currentIndex == 0,
                          navHeight: navHeight,
                          isAndroid: isAndroid,
                        ),
                      ),
                      
                      // Hot Board Tab
                      Expanded(
                        child: _buildNavigationTab(
                          index: 1,
                          label: 'Hot Board',
                          isSelected: widget.currentIndex == 1,
                          navHeight: navHeight,
                          isAndroid: isAndroid,
                        ),
                      ),
                      
                      // Education Tab (NEW)
                      Expanded(
                        child: _buildNavigationTab(
                          index: 2,
                          label: 'Edu',
                          isSelected: widget.currentIndex == 2,
                          navHeight: navHeight,
                          isAndroid: isAndroid,
                        ),
                      ),
                      
                      // Copy Tab (NEW)
                      Expanded(
                        child: _buildNavigationTab(
                          index: 3,
                          label: 'Copy',
                          isSelected: widget.currentIndex == 3,
                          navHeight: navHeight,
                          isAndroid: isAndroid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationTab({
    required int index,
    required String label,
    required bool isSelected,
    required double navHeight,
    required bool isAndroid,
  }) {
    final fontSize = _calculateFontSize(navHeight);
    final touchTarget = _calculateTouchTarget(isAndroid);
    final tabPadding = _calculateTabPadding(navHeight);
    
    return GestureDetector(
      onTap: () {
        if (index != widget.currentIndex) {
          // Premium haptic feedback
          if (Platform.isIOS) {
            HapticFeedback.lightImpact();
          } else if (Platform.isAndroid) {
            HapticFeedback.selectionClick();
          }
          widget.onTap(index);
        }
      },
      child: Container(
        height: touchTarget,
        margin: EdgeInsets.symmetric(
          horizontal: tabPadding,
          vertical: navHeight * 0.15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          // Selected state with cyan glow exactly like the image
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00D4AA).withOpacity(0.8), // Cyan color from image
                    const Color(0xFF00B894).withOpacity(0.9),
                    const Color(0xFF00A085).withOpacity(0.8),
                  ],
                )
              : null,
          // Premium glow effect for selected tab
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.8),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white // White text for selected (like in image)
                  : Colors.white.withOpacity(0.6), // Dimmed for unselected
              letterSpacing: 0.5,
              // Text shadow for selected state
              shadows: isSelected
                  ? [
                      const Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                semanticsLabel: '$label navigation tab',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Responsive calculations for all devices
  double _calculateNavHeight(double screenHeight, bool isTablet, bool isAndroid) {
    if (isTablet) {
      return (screenHeight * 0.08).clamp(75.0, 95.0);
    } else {
      // Ensure minimum touch targets for all devices
      final baseHeight = screenHeight * 0.095;
      final minHeight = isAndroid ? 60.0 : 56.0;
      final maxHeight = 75.0;
      return baseHeight.clamp(minHeight, maxHeight);
    }
  }

  double _calculateFontSize(double navHeight) {
    // Responsive font size that scales with navigation height
    // Increased font size for better readability while maintaining responsiveness
    final baseFontSize = navHeight * 0.22; // Increased from 0.18 to 0.22
    return baseFontSize.clamp(12.0, 18.0); // Increased min from 10.0 to 12.0 and max from 16.0 to 18.0
  }

  double _calculateTouchTarget(bool isAndroid) {
    // Platform-specific minimum touch targets
    return isAndroid ? 48.0 : 44.0;
  }

  double _calculateTabPadding(double navHeight) {
    // Responsive padding that maintains proportions
    // Reduced padding for 4 tabs
    return (navHeight * 0.04).clamp(1.0, 6.0);
  }
} 