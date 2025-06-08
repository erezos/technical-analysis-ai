import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trading_tip.dart';

class TradingTipScreen extends StatefulWidget {
  final TradingTip tip;

  const TradingTipScreen({super.key, required this.tip});

  @override
  State<TradingTipScreen> createState() => _TradingTipScreenState();
}

class _TradingTipScreenState extends State<TradingTipScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${widget.tip.symbol} - ${widget.tip.formattedTimeframe}'),
        backgroundColor: _getSentimentColor(widget.tip.sentiment),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getSentimentColor(widget.tip.sentiment),
                _getSentimentColor(widget.tip.sentiment).withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTradingTip,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // AI-Generated Background Image
              _buildBackgroundImage(),
              
              // Trading Data Overlay
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Company Logo Header
                    _buildCompanyLogoHeader(),
                    
                    // Analysis Summary Card with transparency
                    if (widget.tip.hasAnalysisData) _buildTransparentAnalysisSummaryCard(),
                    
                    // Trading Levels Card with transparency
                    if (widget.tip.hasAnalysisData) _buildTransparentTradingLevelsCard(),
                    
                    // Technical Indicators Card with transparency
                    if (widget.tip.hasIndicatorData) _buildTransparentTechnicalIndicatorsCard(),
                    
                    // Reasoning Card with transparency
                    if (widget.tip.reasoning != null && widget.tip.reasoning!.isNotEmpty) 
                      _buildTransparentReasoningCard(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: (widget.tip.images['latestTradingCard'] as Map<String, dynamic>?)?['url'] ?? '',
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getSentimentColor(widget.tip.sentiment).withOpacity(0.3),
                const Color(0xFF121212),
                const Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF00D4AA),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading AI Background...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getSentimentColor(widget.tip.sentiment).withOpacity(0.3),
                const Color(0xFF121212),
                const Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'AI Background Unavailable',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogoHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Company Logo
            _buildCompanyLogo(),
            const SizedBox(width: 16),
            // Company Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tip.companyName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tip.symbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getSentimentColor(widget.tip.sentiment),
                    ),
                  ),
                  if (widget.tip.businessInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.tip.businessInfo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    if (!widget.tip.hasLogo) {
      // Default logo when no company logo is available
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.business,
          size: 32,
          color: _getSentimentColor(widget.tip.sentiment),
        ),
      );
    }

    // Check if it's a data URI (fallback emoji logo)
    if (widget.tip.logoUrl.startsWith('data:')) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            widget.tip.company?.isCrypto == true ? '🪙' : '📈',
            style: const TextStyle(fontSize: 32),
          ),
        ),
      );
    }

    // Use local Flutter assets for logos - much faster and no server dependency!
    String assetPath;
    if (widget.tip.company?.isCrypto == true) {
      // For crypto: Extract symbol from BTC/USDT -> BTC
      final cryptoSymbol = widget.tip.symbol.contains('/') 
          ? widget.tip.symbol.split('/')[0] 
          : widget.tip.symbol;
      assetPath = 'assets/logos/crypto/$cryptoSymbol.png';
    } else {
      // For stocks: Use symbol directly
      assetPath = 'assets/logos/stocks/${widget.tip.symbol}.png';
    }
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji if asset not found
            return Container(
              color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.1),
              child: Center(
                child: Text(
                  widget.tip.company?.isCrypto == true ? '🪙' : '📈',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransparentAnalysisSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85), // Semi-transparent
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getSentimentColor(widget.tip.sentiment).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getSentimentColor(widget.tip.sentiment),
                        _getSentimentColor(widget.tip.sentiment).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSentimentIcon(widget.tip.sentiment),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Market Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGlassyInfoChip(
                    'Sentiment',
                    widget.tip.sentimentDisplay,
                    _getSentimentColor(widget.tip.sentiment),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGlassyInfoChip(
                    'Strength',
                    widget.tip.strengthDisplay,
                    _getStrengthColor(widget.tip.strength),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[300],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Generated: ${_formatDate(widget.tip.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparentTradingLevelsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85), // Semi-transparent
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Trading Levels',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.tip.entryPrice != null)
              _buildPremiumTradingLevelRow('Entry Price', widget.tip.entryPrice!, Colors.blue),
            if (widget.tip.stopLoss != null)
              _buildPremiumTradingLevelRow('Stop Loss', widget.tip.stopLoss!, Colors.red),
            if (widget.tip.takeProfit != null)
              _buildPremiumTradingLevelRow('Take Profit', widget.tip.takeProfit!, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparentTechnicalIndicatorsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85), // Semi-transparent
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Technical Indicators',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...widget.tip.indicators!.entries.map((entry) => _buildIndicatorRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparentReasoningCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85), // Semi-transparent
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'AI Reasoning',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...widget.tip.reasoning!.asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15), // More transparent for overlay
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Color(0xFFE65100)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassyInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTradingLevelRow(String label, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$${value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String key, dynamic value) {
    String displayValue = 'N/A';
    
    if (value is Map<String, dynamic>) {
      final keys = ['value', 'valueMACDHist', 'valueMiddleBand', 'valueUpperBand', 'valueLowerBand'];
      for (String k in keys) {
        if (value[k] != null) {
          displayValue = value[k].toStringAsFixed(2);
          break;
        }
      }
    } else if (value is num) {
      displayValue = value.toStringAsFixed(2);
    } else if (value != null) {
      displayValue = value.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'bullish':
        return const Color(0xFF4CAF50);
      case 'bearish':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getSentimentIcon(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'bullish':
        return Icons.trending_up;
      case 'bearish':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getStrengthColor(double? strength) {
    if (strength == null) return Colors.grey;
    if (strength >= 2) return const Color(0xFF4CAF50);
    if (strength <= -2) return const Color(0xFFF44336);
    return const Color(0xFFFF9800);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareTradingTip() async {
    try {
      // Build comprehensive share message
      final shareContent = _buildShareContent();
      
      // Show a brief loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('📤 Preparing to share...'),
            ],
          ),
          backgroundColor: _getSentimentColor(widget.tip.sentiment),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );

      // Get screen dimensions for iPad positioning
      final screenSize = MediaQuery.of(context).size;
      
      // Share using the share_plus package with iPad positioning
      await Share.share(
        shareContent,
        subject: '${widget.tip.symbol} - ${widget.tip.sentimentDisplay} Trading Signal',
        sharePositionOrigin: Rect.fromLTWH(
          screenSize.width * 0.8, // Near share button (right side)
          100, // Near app bar
          screenSize.width * 0.2, // Width of share area
          200, // Height of share area
        ),
      );

      print('✅ Trading tip shared successfully');
    } catch (e) {
      print('❌ Error sharing trading tip: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Unable to share trading tip'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _buildShareContent() {
    final sentimentEmoji = widget.tip.sentiment?.toLowerCase() == 'bullish' ? '📈' : '📉';
    final strengthStars = _getStrengthStars(widget.tip.strength);
    final companyName = widget.tip.companyName;
    final symbol = widget.tip.symbol;
    final timeframe = widget.tip.formattedTimeframe;
    
    String content = '';
    
    // Header with branding
    content += '🤖 AI Trading Signal\n';
    content += '━━━━━━━━━━━━━━━━━━━━\n\n';
    
    // Main signal info
    content += '$sentimentEmoji $companyName ($symbol)\n';
    content += '📊 Sentiment: ${widget.tip.sentimentDisplay}\n';
    content += '⚡ Strength: $strengthStars (${widget.tip.strengthDisplay}/5.0)\n';
    content += '⏰ Timeframe: $timeframe\n\n';
    
    // Trading levels if available
    if (widget.tip.hasAnalysisData) {
      content += '💰 Trading Levels:\n';
      if (widget.tip.entryPrice != null) {
        content += '🎯 Entry: \$${widget.tip.entryPrice!.toStringAsFixed(2)}\n';
      }
      if (widget.tip.stopLoss != null) {
        content += '🛡️ Stop Loss: \$${widget.tip.stopLoss!.toStringAsFixed(2)}\n';
      }
      if (widget.tip.takeProfit != null) {
        content += '🎉 Take Profit: \$${widget.tip.takeProfit!.toStringAsFixed(2)}\n';
      }
      content += '\n';
    }
    
    // Key reasoning points (max 3)
    if (widget.tip.reasoning != null && widget.tip.reasoning!.isNotEmpty) {
      content += '🧠 Key Analysis:\n';
      final topReasons = widget.tip.reasoning!.take(3);
      for (final reason in topReasons) {
        content += '• $reason\n';
      }
      content += '\n';
    }
    
    // Footer with app branding
    content += '━━━━━━━━━━━━━━━━━━━━\n';
    content += '🚀 Powered by Technical-Analysis.AI\n';
    content += '⚠️ Educational purposes only. Not financial advice.\n';
    content += '#TradingTips #AI #TechnicalAnalysis';
    
    return content;
  }

  String _getStrengthStars(double? strength) {
    if (strength == null) return '⭐⭐⭐ (N/A)';
    
    final absStrength = strength.abs();
    if (absStrength >= 4.5) return '⭐⭐⭐⭐⭐';
    if (absStrength >= 3.5) return '⭐⭐⭐⭐';
    if (absStrength >= 2.5) return '⭐⭐⭐';
    if (absStrength >= 1.5) return '⭐⭐';
    return '⭐';
  }
} 