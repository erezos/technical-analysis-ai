import 'package:flutter/material.dart';

class EducationCategoryButton extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String lessons;
  final VoidCallback onTap;
  final Color? primaryColor;
  final Color? accentColor;

  const EducationCategoryButton({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.lessons,
    required this.onTap,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<EducationCategoryButton> createState() => _EducationCategoryButtonState();
}

class _EducationCategoryButtonState extends State<EducationCategoryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    // Responsive sizing
    final buttonHeight = isTablet ? 120.0 : 100.0;
    final iconSize = isTablet ? 32.0 : 28.0;
    final titleFontSize = isTablet ? 16.0 : 14.0;
    final descriptionFontSize = isTablet ? 12.0 : 11.0;
    final lessonsFontSize = isTablet ? 11.0 : 10.0;
    
    // Color scheme with modern fintech aesthetics
    final primaryColor = widget.primaryColor ?? const Color(0xFF00D4AA);
    final accentColor = widget.accentColor ?? const Color(0xFF6C5CE7);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              height: buttonHeight,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1E1E1E),
                  ],
                ),
                border: Border.all(
                  color: primaryColor.withOpacity(_glowAnimation.value),
                  width: 1.5,
                ),
                boxShadow: [
                  // Outer glow effect
                  BoxShadow(
                    color: primaryColor.withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                  // Inner depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Subtle background pattern
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withOpacity(0.05),
                              accentColor.withOpacity(0.03),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Main content
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
                      child: Row(
                        children: [
                          // Icon container with modern design
                          Container(
                            width: isTablet ? 56 : 48,
                            height: isTablet ? 56 : 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  accentColor.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          
                          SizedBox(width: isTablet ? 16 : 12),
                          
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Title
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Description
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: descriptionFontSize,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Lessons count
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      size: lessonsFontSize + 2,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.lessons} lessons',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: lessonsFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Arrow indicator
                          Container(
                            width: isTablet ? 32 : 28,
                            height: isTablet ? 32 : 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: isTablet ? 16 : 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Ripple effect overlay
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onTap,
                          splashColor: primaryColor.withOpacity(0.1),
                          highlightColor: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Category data model for better organization
class EducationCategory {
  final String title;
  final String description;
  final IconData icon;
  final String lessons;
  final Color? primaryColor;
  final Color? accentColor;

  const EducationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.lessons,
    this.primaryColor,
    this.accentColor,
  });
}

// Predefined category configurations with modern icons and colors
class EducationCategories {
  static const List<EducationCategory> categories = [
    EducationCategory(
      title: 'Technical Analysis Basics',
      description: 'Learn chart patterns, indicators & analysis fundamentals',
      icon: Icons.analytics_outlined,
      lessons: '6',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFF6C5CE7),
    ),
    EducationCategory(
      title: 'Chart Reading',
      description: 'Master candlesticks & chart pattern recognition',
      icon: Icons.candlestick_chart_outlined,
      lessons: '3',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFFFF6B6B),
    ),
    EducationCategory(
      title: 'Technical Indicators',
      description: 'RSI, MACD, moving averages & momentum indicators',
      icon: Icons.trending_up_outlined,
      lessons: '4',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFF4ECDC4),
    ),
    EducationCategory(
      title: 'Risk Management',
      description: 'Position sizing, stop losses & portfolio protection',
      icon: Icons.security_outlined,
      lessons: '2',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFFFFBE0B),
    ),
    EducationCategory(
      title: 'Trading Psychology',
      description: 'Mental discipline, emotional control & mindset',
      icon: Icons.psychology_outlined,
      lessons: '1',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFF8338EC),
    ),
    EducationCategory(
      title: 'Strategy Development',
      description: 'Build, backtest & optimize trading strategies',
      icon: Icons.architecture_outlined,
      lessons: '2',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFF3A86FF),
    ),
    EducationCategory(
      title: 'Reference',
      description: 'Quick reference guides & trading cheat sheets',
      icon: Icons.library_books_outlined,
      lessons: '1',
      primaryColor: Color(0xFF00D4AA),
      accentColor: Color(0xFF06FFA5),
    ),
  ];
} 