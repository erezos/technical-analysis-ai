import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hot_board_models.dart';
import '../services/hot_board_service.dart';
import '../utils/trading_colors.dart';
import '../utils/responsive_utils.dart';

class HotBoardScreenEnhanced extends StatefulWidget {
  const HotBoardScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<HotBoardScreenEnhanced> createState() => _HotBoardScreenEnhancedState();
}

class _HotBoardScreenEnhancedState extends State<HotBoardScreenEnhanced>
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
      if (!ResponsiveUtils.shouldReduceMotion(context)) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _slideController.forward();
        });
      } else {
        _slideController.forward();
      }
    }
  }

  Future<void> _onRefresh() async {
    if (!ResponsiveUtils.shouldReduceMotion(context)) {
      _refreshController.forward().then((_) => _refreshController.reset());
    }
    await _loadHotBoardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradingColors.primaryBackground,
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '🔥 Hot Board',
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            base: 20,
            smallMobile: 18,
            tablet: 24,
          ),
          fontWeight: FontWeight.bold,
          color: TradingColors.primaryText,
        ),
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
                iconSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  base: 24,
                  smallMobile: 22,
                  tablet: 28,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last updated shimmer
          _buildShimmerContainer(height: 44, width: double.infinity),
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24)),
          
          // Gainers section
          _buildShimmerContainer(height: 24, width: 150),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShimmerContainer(height: 70, width: double.infinity),
          )),
          
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 32)),
          
          // Losers section
          _buildShimmerContainer(height: 24, width: 130),
          SizedBox(height: ResponsiveUtils.getSpacing(context)),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShimmerContainer(height: 70, width: double.infinity),
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
                TradingColors.neutral.withOpacity(0.3),
                TradingColors.neutral.withOpacity(0.1),
                TradingColors.neutral.withOpacity(0.3),
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
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: ResponsiveUtils.getAnimationDuration(
                  context,
                  normal: const Duration(milliseconds: 600),
                ),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: TradingColors.warning,
                    ),
                  );
                },
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              Text(
                'Unable to load market data',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    base: 18,
                    smallMobile: 16,
                  ),
                  color: TradingColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24)),
              SizedBox(
                height: ResponsiveUtils.getButtonHeight(context),
                child: ElevatedButton(
                  onPressed: _loadHotBoardData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TradingColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        base: 16,
                        smallMobile: 14,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotBoardContent() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: TradingColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: _buildLastUpdated(),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24)),
            _buildSection(
              title: '📈 Top Gainers',
              stocks: _hotBoardData!.gainers.take(3).toList(),
              isGainers: true,
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 32)),
            _buildSection(
              title: '📉 Top Losers',
              stocks: _hotBoardData!.losers.take(3).toList(),
              isGainers: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    final timeSince = HotBoardService.getTimeSinceUpdate(_hotBoardData!.lastUpdated);
    final isStale = HotBoardService.isDataStale(_hotBoardData!.lastUpdated);
    final isHighContrast = ResponsiveUtils.isHighContrast(context);

    return Semantics(
      label: 'Market data last updated $timeSince${isStale ? ', data may be stale' : ''}',
      child: Container(
        padding: ResponsiveUtils.getResponsivePadding(context, mobile: 12),
        decoration: BoxDecoration(
          color: isStale 
              ? TradingColors.warning.withOpacity(0.1) 
              : TradingColors.bullish.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isStale 
                ? (isHighContrast ? TradingColors.warning : TradingColors.warning.withOpacity(0.3))
                : (isHighContrast ? TradingColors.bullish : TradingColors.bullish.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isStale ? Icons.warning_amber : Icons.check_circle,
              color: isStale ? TradingColors.warning : TradingColors.bullish,
              size: ResponsiveUtils.getResponsiveFontSize(context, base: 20, smallMobile: 18),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8)),
            Expanded(
              child: Text(
                'Last updated: $timeSince',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    base: 14,
                    smallMobile: 12,
                    tablet: 16,
                  ),
                  color: isStale ? TradingColors.warning : TradingColors.bullish,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<HotBoardStock> stocks,
    required bool isGainers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: ResponsiveUtils.getAnimationDuration(
            context,
            normal: const Duration(milliseconds: 500),
          ),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      base: 20,
                      smallMobile: 18,
                      tablet: 24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: TradingColors.primaryText,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        if (stocks.isEmpty)
          _buildEmptyState(isGainers)
        else
          ...stocks.asMap().entries.map((entry) {
            final index = entry.key;
            final stock = entry.value;
            return _buildAnimatedStockCard(stock, isGainers, index * 150);
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(bool isGainers) {
    return TweenAnimationBuilder<double>(
      duration: ResponsiveUtils.getAnimationDuration(
        context,
        normal: const Duration(milliseconds: 400),
      ),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              padding: ResponsiveUtils.getResponsivePadding(context, mobile: 24),
              decoration: BoxDecoration(
                color: TradingColors.neutral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No ${isGainers ? 'gainers' : 'losers'} data available',
                  style: TextStyle(
                    color: TradingColors.secondaryText,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      base: 16,
                      smallMobile: 14,
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

  Widget _buildAnimatedStockCard(HotBoardStock stock, bool isGainers, int delayMs) {
    return TweenAnimationBuilder<double>(
      duration: ResponsiveUtils.getAnimationDuration(
        context,
        normal: Duration(milliseconds: 600 + delayMs),
      ),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEnhancedStockCard(stock, isGainers),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStockCard(HotBoardStock stock, bool isGainers) {
    final isHighContrast = ResponsiveUtils.isHighContrast(context);
    final trendColor = TradingColors.getTrendColor(isGainers, highContrast: isHighContrast);
    final trendIcon = TradingColors.getTrendIcon(isGainers);
    final semanticLabel = TradingColors.getTrendLabel(isGainers, stock.changesPercentage);

    return Semantics(
      label: '${stock.symbol}, ${stock.name}, current price ${stock.formattedPrice}, $semanticLabel',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            // Future: Navigate to stock details
          },
          child: Container(
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: TradingColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: trendColor,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: trendColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Stock info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary: Stock symbol
                      Text(
                        stock.symbol,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            base: 18,
                            smallMobile: 16,
                            tablet: 20,
                          ),
                          fontWeight: FontWeight.bold,
                          color: TradingColors.primaryText,
                        ),
                      ),
                      if (stock.name.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 4)),
                        Text(
                          stock.name,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              base: 12,
                              smallMobile: 11,
                              tablet: 14,
                            ),
                            color: TradingColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Price info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current price
                    AnimatedSwitcher(
                      duration: ResponsiveUtils.getAnimationDuration(context),
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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            base: 16,
                            smallMobile: 14,
                            tablet: 18,
                          ),
                          fontWeight: FontWeight.bold,
                          color: TradingColors.primaryText,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 4)),
                    // Change with icon for accessibility
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendIcon,
                          size: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            base: 16,
                            smallMobile: 14,
                          ),
                          color: trendColor,
                        ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 4)),
                        AnimatedSwitcher(
                          duration: ResponsiveUtils.getAnimationDuration(context),
                          child: Text(
                            stock.formattedPercentage,
                            key: ValueKey('percentage-${stock.symbol}-${stock.changesPercentage}'),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                base: 14,
                                smallMobile: 12,
                                tablet: 16,
                              ),
                              fontWeight: FontWeight.w600,
                              color: trendColor,
                            ),
                          ),
                        ),
                      ],
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
} 