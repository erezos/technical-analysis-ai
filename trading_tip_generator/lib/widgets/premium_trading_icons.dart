import 'package:flutter/material.dart';

/// Premium trading icons with enhanced visuals and animations
class PremiumTradingIcons {
  
  /// Animated trending up icon with glow effect
  static Widget trendingUp({
    double size = 24,
    Color? color,
    bool animated = true,
  }) {
    final iconColor = color ?? const Color(0xFF00D4AA);
    
    return animated
      ? TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 4),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3 * value),
                      blurRadius: 8 * value,
                      spreadRadius: 2 * value,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: iconColor,
                  size: size,
                ),
              ),
            );
          },
        )
      : Icon(Icons.trending_up_rounded, color: iconColor, size: size);
  }

  /// Animated trending down icon with red glow
  static Widget trendingDown({
    double size = 24,
    Color? color,
    bool animated = true,
  }) {
    final iconColor = color ?? const Color(0xFFFF6B6B);
    
    return animated
      ? TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 4),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3 * value),
                      blurRadius: 8 * value,
                      spreadRadius: 2 * value,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.trending_down_rounded,
                  color: iconColor,
                  size: size,
                ),
              ),
            );
          },
        )
      : Icon(Icons.trending_down_rounded, color: iconColor, size: size);
  }

  /// Premium AI-generated logo with glow effect
  static Widget premiumLogo({
    double size = 60,
    bool animated = true,
  }) {
    return animated
      ? TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.4 * value),
                      blurRadius: 20 * value,
                      offset: Offset(0, 8 * value),
                      spreadRadius: 2 * value,
                    ),
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.2 * value),
                      blurRadius: 40 * value,
                      offset: Offset(0, 16 * value),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size / 4),
                  child: Image.asset(
                    'assets/images/premium_ai_icon.png',
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        )
      : Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6600D4AA),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 4),
            child: Image.asset(
              'assets/images/premium_ai_icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        );
  }

  /// Floating action icon with pulse animation
  static Widget floatingAction({
    required IconData icon,
    double size = 24,
    Color? color,
    bool pulsing = true,
  }) {
    final iconColor = color ?? const Color(0xFF00D4AA);
    
    if (!pulsing) {
      return Icon(icon, color: iconColor, size: size);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: (1000 * (1 - value)).round()),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 10 + (10 * value),
                spreadRadius: 2 + (3 * value),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: size),
        );
      },
    );
  }

  /// Custom chart icon with animated paths
  static Widget chartIcon({
    double size = 24,
    Color? color,
    bool animated = true,
  }) {
    final iconColor = color ?? const Color(0xFF00D4AA);
    
    return CustomPaint(
      size: Size(size, size),
      painter: _ChartIconPainter(
        color: iconColor,
        animated: animated,
      ),
    );
  }

  /// Glassmorphic icon container
  static Widget glassmorphicIcon({
    required IconData icon,
    double size = 24,
    Color? color,
    Color? backgroundColor,
  }) {
    final iconColor = color ?? const Color(0xFF00D4AA);
    final bgColor = backgroundColor ?? const Color(0xFF1E1E1E);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withOpacity(0.8),
            bgColor.withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size),
    );
  }
}

/// Custom painter for animated chart icon
class _ChartIconPainter extends CustomPainter {
  final Color color;
  final bool animated;
  
  _ChartIconPainter({
    required this.color,
    required this.animated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Create a simple trending line chart
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.6);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.2);
    
    canvas.drawPath(path, paint);
    
    // Add dots for data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final points = [
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.2),
    ];
    
    for (final point in points) {
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 