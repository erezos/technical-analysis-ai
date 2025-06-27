import 'package:flutter/material.dart';

/// Enhanced micro-animations for TradingTip cards and UI elements
/// Leverages our brand colors and provides premium feel

class AnimatedTradingCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enableHover;
  
  const AnimatedTradingCard({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.enableHover = true,
  }) : super(key: key);
  
  @override
  State<AnimatedTradingCard> createState() => _AnimatedTradingCardState();
}

class _AnimatedTradingCardState extends State<AnimatedTradingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shadowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 8.0,
      end: 16.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (!widget.enableHover) return;
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (!widget.enableHover) return;
    _controller.reverse();
  }
  
  void _handleTapCancel() {
    if (!widget.enableHover) return;
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Premium glow effect
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(_glowAnimation.value * 0.4),
                    blurRadius: _shadowAnimation.value,
                    spreadRadius: _glowAnimation.value * 2,
                  ),
                  // Depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _shadowAnimation.value * 0.5,
                    offset: Offset(0, _shadowAnimation.value * 0.3),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Animated sentiment indicator with pulsing effect
class AnimatedSentimentIndicator extends StatefulWidget {
  final String sentiment;
  final double size;
  final bool showPulse;
  
  const AnimatedSentimentIndicator({
    Key? key,
    required this.sentiment,
    this.size = 100.0,
    this.showPulse = true,
  }) : super(key: key);
  
  @override
  State<AnimatedSentimentIndicator> createState() => _AnimatedSentimentIndicatorState();
}

class _AnimatedSentimentIndicatorState extends State<AnimatedSentimentIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  Color get _sentimentColor {
    switch (widget.sentiment.toLowerCase()) {
      case 'bullish':
        return const Color(0xFF4CAF50);
      case 'bearish':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _sentimentColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _sentimentColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _sentimentColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.sentiment.toUpperCase(),
                style: TextStyle(
                  color: _sentimentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size * 0.15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Loading shimmer effect for skeleton loading
class LoadingShimmer extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color highlightColor;
  final Color baseColor;
  
  const LoadingShimmer({
    Key? key,
    required this.child,
    required this.isLoading,
    this.highlightColor = const Color(0xFF00D4AA),
    this.baseColor = const Color(0xFF424242),
  }) : super(key: key);
  
  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }
  
  @override
  void didUpdateWidget(LoadingShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor.withOpacity(0.5),
                widget.baseColor,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
}

/// Success celebration animation
class SuccessCelebration extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onComplete;
  
  const SuccessCelebration({
    Key? key,
    required this.isVisible,
    this.onComplete,
  }) : super(key: key);
  
  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: const Interval(0.7, 1.0),
    ));
  }
  
  @override
  void didUpdateWidget(SuccessCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _startCelebration();
    }
  }
  
  void _startCelebration() async {
    _celebrationController.forward();
    _particleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      widget.onComplete?.call();
      _celebrationController.reset();
      _particleController.reset();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: Listenable.merge([_celebrationController, _particleController]),
      builder: (context, child) {
        return Positioned.fill(
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Opacity(
                  opacity: 1 - _opacityAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _celebrationController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

/// Staggered fade-in animation for lists
class StaggeredFadeIn extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  
  const StaggeredFadeIn({
    Key? key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);
  
  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();
    
    _startStaggeredAnimation();
  }
  
  void _startStaggeredAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (mounted) {
        _controllers[i].forward();
        await Future.delayed(widget.delay);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - _animations[index].value)),
              child: Opacity(
                opacity: _animations[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
} 