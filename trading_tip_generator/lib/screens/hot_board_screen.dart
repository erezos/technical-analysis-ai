import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hot_board_models.dart';
import '../services/hot_board_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/color_utils.dart';

class HotBoardScreen extends StatefulWidget {
  const HotBoardScreen({Key? key}) : super(key: key);

  @override
  State<HotBoardScreen> createState() => _HotBoardScreenState();
}

class _HotBoardScreenState extends State<HotBoardScreen>
    with TickerProviderStateMixin {
  HotBoardData? _hotBoardData;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _refreshController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHotBoardData();
  }
  
  void _initializeAnimations() {
    // Fade in animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    
    // Slide up animation for cards
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Refresh indicator animation
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadHotBoardData() async {
    setState(() => _isLoading = true);
    
    // Reset animations
    _fadeController.reset();
    _slideController.reset();
    
    final data = await HotBoardService.getHotBoardData();
    
    if (mounted) {
      setState(() {
        _hotBoardData = data;
        _isLoading = false;
      });
      
      // Start entrance animations
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _slideController.forward();
      });
    }
  }

  Future<void> _onRefresh() async {
    _refreshController.forward().then((_) => _refreshController.reset());
    await _loadHotBoardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: AnimatedDefaultTextStyle(
          duration: ResponsiveUtils.getAnimationDuration(context),
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              base: 20,
              smallMobile: 18,
              tablet: 24,
            ),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('🔥 Hot Board'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: ResponsiveUtils.shouldReduceMotion(context) 
                    ? 0 
                    : _refreshController.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _onRefresh,
                  tooltip: 'Refresh market data',
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _hotBoardData == null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildHotBoardContent(),
                ),
    );
  }

  Widget _buildShimmerLoading() {
    final isTablet = ResponsiveUtils.isTablet(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last updated shimmer
          _buildShimmerContainer(
            height: isSmallMobile ? 40 : (isTablet ? 48 : 44),
            width: double.infinity,
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24)),
          
          // Gainers section
          _buildShimmerContainer(
            height: ResponsiveUtils.getResponsiveFontSize(context, base: 20),
            width: 150,
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShimmerContainer(
              height: isSmallMobile ? 60 : (isTablet ? 80 : 70),
              width: double.infinity,
            ),
          )),
          
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 32)),
          
          // Losers section
          _buildShimmerContainer(
            height: ResponsiveUtils.getResponsiveFontSize(context, base: 20),
            width: 130,
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShimmerContainer(
              height: isSmallMobile ? 60 : (isTablet ? 80 : 70),
              width: double.infinity,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                0.5 + (_fadeController.value * 0.5),
                1.0,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SlideTransition(
              position: _slideAnimation,
              child: Text(
                'Unable to load market data',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SlideTransition(
              position: _slideAnimation,
              child: ElevatedButton(
                onPressed: _loadHotBoardData,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotBoardContent() {
    final isTablet = ResponsiveUtils.isTablet(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: _buildLastUpdated(isTablet, isSmallMobile),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24)),
            _buildAnimatedSection(
              title: '📈 Top Gainers',
              stocks: _hotBoardData!.gainers.take(3).toList(),
              isGainers: true,
              startDelay: 0,
              isTablet: isTablet,
              isSmallMobile: isSmallMobile,
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 32)),
            _buildAnimatedSection(
              title: '📉 Top Losers',
              stocks: _hotBoardData!.losers.take(3).toList(),
              isGainers: false,
              startDelay: 300,
              isTablet: isTablet,
              isSmallMobile: isSmallMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(bool isTablet, bool isSmallMobile) {
    final timeSince = HotBoardService.getTimeSinceUpdate(_hotBoardData!.lastUpdated);
    final isStale = HotBoardService.isDataStale(_hotBoardData!.lastUpdated);

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 8 : (isTablet ? 12 : 10)),
      decoration: BoxDecoration(
        color: isStale ? ColorUtils.withOpacity(Colors.orange, 0.1) : ColorUtils.withOpacity(Colors.green, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStale ? ColorUtils.withOpacity(Colors.orange, 0.3) : ColorUtils.withOpacity(Colors.green, 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStale ? Icons.warning_amber : Icons.check_circle,
            color: isStale ? Colors.orange : Colors.green,
            size: isTablet ? 20 : 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: $timeSince',
            style: TextStyle(
              fontSize: isTablet ? 16 : (isSmallMobile ? 12 : 14),
              color: isStale ? Colors.orange[700] : Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<HotBoardStock> stocks,
    required bool isGainers,
    required bool isTablet,
    required bool isSmallMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : (isSmallMobile ? 18 : 20),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (stocks.isEmpty)
          _buildEmptyState(isGainers)
        else
          ...stocks.asMap().entries.map((entry) {
            final index = entry.key;
            final stock = entry.value;
            return _buildAnimatedStockCard(
              stock, 
              index + 1, 
              isGainers, 
              isTablet, 
              isSmallMobile,
              index * 150, // Staggered delay
            );
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(bool isGainers) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorUtils.withOpacity(Colors.grey, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No ${isGainers ? 'gainers' : 'losers'} data available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStockCard(
    HotBoardStock stock,
    int rank,
    bool isGainers,
    bool isTablet,
    bool isSmallMobile,
    int delayMs,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delayMs),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStockCard(stock, rank, isGainers, isTablet, isSmallMobile),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockCard(
    HotBoardStock stock,
    int rank,
    bool isGainers,
    bool isTablet,
    bool isSmallMobile,
  ) {
    final cardColor = isGainers ? Colors.green : Colors.red;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isSmallMobile ? 12 : (isTablet ? 16 : 14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorUtils.withOpacity(cardColor, 0.1),
            ColorUtils.withOpacity(cardColor, 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorUtils.withOpacity(cardColor, 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withOpacity(cardColor, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Add haptic feedback for interaction
            HapticFeedback.lightImpact();
            // Future: Navigate to stock details
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // Animated rank badge
                Hero(
                  tag: 'rank-${stock.symbol}',
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Container(
                          width: isTablet ? 32 : (isSmallMobile ? 24 : 28),
                          height: isTablet ? 32 : (isSmallMobile ? 24 : 28),
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorUtils.withOpacity(cardColor, 0.3 * value),
                                blurRadius: 6 * value,
                                spreadRadius: 1 * value,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16 : (isSmallMobile ? 12 : 14),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Stock info with animated text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'symbol-${stock.symbol}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            stock.symbol,
                            style: TextStyle(
                              fontSize: isTablet ? 20 : (isSmallMobile ? 16 : 18),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (stock.name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isTablet ? 14 : (isSmallMobile ? 11 : 12),
                            color: Colors.grey[600],
                          ),
                          child: Text(
                            stock.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Animated price and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Ticker-style price animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        stock.formattedPrice,
                        key: ValueKey('price-${stock.symbol}-${stock.price}'),
                        style: TextStyle(
                          fontSize: isTablet ? 18 : (isSmallMobile ? 14 : 16),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Pulsing percentage badge
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        final pulseValue = 1.0 + (0.05 * (1 - value));
                        return Transform.scale(
                          scale: pulseValue,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorUtils.withOpacity(cardColor, 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                stock.formattedPercentage,
                                key: ValueKey('percentage-${stock.symbol}-${stock.changesPercentage}'),
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : (isSmallMobile ? 11 : 12),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required String title,
    required List<HotBoardStock> stocks,
    required bool isGainers,
    required bool isTablet,
    required bool isSmallMobile,
    required int startDelay,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildSection(
        title: title,
        stocks: stocks,
        isGainers: isGainers,
        isTablet: isTablet,
        isSmallMobile: isSmallMobile,
      ),
    );
  }
} 