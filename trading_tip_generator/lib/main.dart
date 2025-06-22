import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'disclaimer_page.dart';
import 'providers/trading_tips_provider.dart';
import 'screens/trading_tip_screen.dart';
import 'screens/hot_board_screen_enhanced.dart';
import 'screens/lesson_screen.dart';
import 'services/notification_service.dart';
import 'services/stats_service.dart';
import 'services/trading_link_service.dart';
import 'services/notification_permission_service.dart';
import 'services/educational_service.dart';
import 'widgets/premium_glassmorphism_nav.dart';
import 'widgets/responsive/responsive_layout.dart';
import 'widgets/education_category_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  // Initialize app statistics
  await StatsService.initializeStatsForSession();
  
  // Initialize trading link
  await TradingLinkService.initializeTradingLinkForSession();
  
  // Initialize educational content (NEW)
  await EducationalService.initializeEducationalContent();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TradingTipsProvider(),
      child: MaterialApp(
        title: 'Trading Tip Generator',
        theme: _buildTheme(),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00D4AA),
        secondary: Color(0xFF4ECDC4),
        surface: Color(0xFF1A1A1A),
        background: Color(0xFF121212),
        onSurface: Color(0xFFE1E1E1),
        onBackground: Color(0xFFE1E1E1),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    
    // Load tips when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradingTipsProvider>().loadLatestTips();
      
      // Check if we should show notification permission prompt (40% chance)
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Check notification permission and show prompt with 40% probability
  Future<void> _checkNotificationPermission() async {
    try {
      // Wait a bit for the UI to settle after animations
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final shouldShow = await NotificationPermissionService.shouldShowPermissionPrompt();
      if (shouldShow && mounted) {
        await NotificationPermissionService.showPermissionDialog(context);
      }
    } catch (e) {
      print('❌ Error checking notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // iPhone 13 mini detection
    final isSmallMobile = screenWidth <= 375 && screenHeight <= 812;
    final isTablet = screenHeight > 800;
    
    return Scaffold(
      backgroundColor: Colors.black, // Ensure dark background
      extendBody: true, // Allow navigation bar to overlap body for glassmorphism
      body: _buildCurrentScreen(screenSize, isSmallMobile, isTablet),
      bottomNavigationBar: PremiumGlassmorphismNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildCurrentScreen(Size screenSize, bool isSmallMobile, bool isTablet) {
    switch (_currentIndex) {
      case 0: // AI Tips
        return _buildTradingTipsScreen(screenSize, isSmallMobile, isTablet);
      case 1: // Hot Board
        return const HotBoardScreenEnhanced();
      case 2: // Education
        return _buildEducationScreen(screenSize, isSmallMobile, isTablet);
      default:
        return _buildTradingTipsScreen(screenSize, isSmallMobile, isTablet);
    }
  }

  Widget _buildTradingTipsScreen(Size screenSize, bool isSmallMobile, bool isTablet) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use LayoutBuilder for proper responsive design
                  return _buildResponsiveContent(constraints, isSmallMobile, isTablet);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationScreen(Size screenSize, bool isSmallMobile, bool isTablet) {
    return ResponsiveLayout(
      mobile: _buildEducationMobile(),
      tablet: _buildEducationTablet(),
    );
  }

  Widget _buildEducationMobile() {
    return SafeArea(
      child: SingleChildScrollView(
        child: ResponsivePadding(
          mobilePadding: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEducationHeader(),
              const SizedBox(height: 16),
              _buildEducationStats(),
              const SizedBox(height: 20),
              const ResponsiveText(
                'Learning Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildEducationCategoriesMobile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationTablet() {
    return SafeArea(
      child: SingleChildScrollView(
        child: ResponsivePadding(
          mobilePadding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEducationHeader(),
              const SizedBox(height: 20),
              _buildEducationStats(),
              const SizedBox(height: 24),
              const ResponsiveText(
                'Learning Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildEducationCategoriesTablet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ResponsivePadding(
        mobilePadding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF00D4AA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'Trading Education',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ResponsiveText(
                        'Learn trading fundamentals & advanced strategies',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF00D4AA),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      'Educational content for learning purposes only. Not financial advice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Lessons', '15', Icons.book)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Categories', '7', Icons.category)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Difficulty', 'All Levels', Icons.school)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ResponsivePadding(
        mobilePadding: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF00D4AA),
              size: 20,
            ),
            const SizedBox(height: 6),
            ResponsiveText(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            ResponsiveText(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCategoriesMobile() {
    final categories = _getEducationCategories();
    
    return Column(
      children: categories.map((category) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEducationCategoryCard(category),
        )
      ).toList(),
    );
  }

  Widget _buildEducationCategoriesTablet() {
    final categories = _getEducationCategories();
    
    return Column(
      children: categories.map((category) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEducationCategoryCard(category),
        )
      ).toList(),
    );
  }

  Widget _buildEducationCategoryCard(Map<String, dynamic> category) {
    return EducationCategoryButton(
      title: category['title'],
      description: category['description'],
      icon: category['icon'],
      lessons: category['lessons'],
      onTap: () => _navigateToLessons(category['title']),
      primaryColor: category['primaryColor'],
      accentColor: category['accentColor'],
    );
  }

  List<Map<String, dynamic>> _getEducationCategories() {
    return [
      {
        'title': 'Technical Analysis Basics',
        'description': 'Learn chart patterns, indicators & analysis fundamentals',
        'icon': Icons.analytics_outlined,
        'lessons': '6',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFF6C5CE7),
      },
      {
        'title': 'Chart Reading',
        'description': 'Master candlesticks & chart pattern recognition',
        'icon': Icons.candlestick_chart_outlined,
        'lessons': '3',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFFFF6B6B),
      },
      {
        'title': 'Technical Indicators',
        'description': 'RSI, MACD, moving averages & momentum indicators',
        'icon': Icons.trending_up_outlined,
        'lessons': '4',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Risk Management',
        'description': 'Position sizing, stop losses & portfolio protection',
        'icon': Icons.security_outlined,
        'lessons': '2',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFFFFBE0B),
      },
      {
        'title': 'Trading Psychology',
        'description': 'Mental discipline, emotional control & mindset',
        'icon': Icons.psychology_outlined,
        'lessons': '1',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFF8338EC),
      },
      {
        'title': 'Strategy Development',
        'description': 'Build, backtest & optimize trading strategies',
        'icon': Icons.architecture_outlined,
        'lessons': '2',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFF3A86FF),
      },
      {
        'title': 'Reference',
        'description': 'Quick reference guides & trading cheat sheets',
        'icon': Icons.library_books_outlined,
        'lessons': '1',
        'primaryColor': const Color(0xFF00D4AA),
        'accentColor': const Color(0xFF06FFA5),
      },
    ];
  }

  void _navigateToLessons(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(category: category),
      ),
    );
  }

  Widget _buildResponsiveContent(BoxConstraints constraints, bool isSmallMobile, bool isTablet) {
    // Calculate responsive dimensions based on available space
    final availableHeight = constraints.maxHeight;
    final availableWidth = constraints.maxWidth;
    
    // Responsive button height based on available space
    final buttonHeight = _calculateButtonHeight(availableHeight, isSmallMobile, isTablet);
    
    // Calculate padding based on screen size
    final horizontalPadding = isSmallMobile ? 8.0 : (isTablet ? 24.0 : 20.0);
    final verticalPadding = isSmallMobile ? 8.0 : (isTablet ? 16.0 : 12.0);
    
    // Calculate required space for all components
    final headerHeight = isSmallMobile ? 120 : (isTablet ? 180 : 150);
    final statsHeight = isSmallMobile ? 80 : (isTablet ? 120 : 100);
    final footerHeight = isSmallMobile ? 40 : (isTablet ? 60 : 50);
    final buttonsHeight = buttonHeight * 4; // 4 buttons
    final spacingHeight = isSmallMobile ? 40 : (isTablet ? 80 : 60); // Total spacing
    
    final totalRequiredHeight = headerHeight + statsHeight + footerHeight + buttonsHeight + spacingHeight + (verticalPadding * 2);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: totalRequiredHeight > availableHeight
        ? _buildScrollableLayout(buttonHeight, isSmallMobile, isTablet)
        : _buildFixedLayout(buttonHeight, isSmallMobile, isTablet, availableHeight),
    );
  }

  double _calculateButtonHeight(double availableHeight, bool isSmallMobile, bool isTablet) {
    if (isSmallMobile) {
      return 44.0; // Apple's minimum touch target
    } else if (isTablet) {
      return (availableHeight * 0.08).clamp(50.0, 80.0);
    } else {
      return (availableHeight * 0.07).clamp(48.0, 70.0);
    }
  }

  Widget _buildFixedLayout(double buttonHeight, bool isSmallMobile, bool isTablet, double availableHeight) {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: isSmallMobile ? 8 : (availableHeight * 0.02)),
        _buildStatsCard(),
        SizedBox(height: isSmallMobile ? 6 : (availableHeight * 0.015)),
        Expanded(
          child: _buildTimeframeButtons(buttonHeight),
        ),
        SizedBox(height: isSmallMobile ? 4 : (availableHeight * 0.01)),
        _buildFooter(),
      ],
    );
  }

  Widget _buildScrollableLayout(double buttonHeight, bool isSmallMobile, bool isTablet) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: isSmallMobile ? 8 : 24),
          _buildStatsCard(),
          SizedBox(height: isSmallMobile ? 6 : 20),
          _buildTimeframeButtons(buttonHeight),
          SizedBox(height: isSmallMobile ? 6 : 20),
          _buildFooter(),
          SizedBox(height: isSmallMobile ? 20 : 30), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallMobile = screenSize.width <= 375 && screenSize.height <= 812;
    // Improved tablet detection - iPad Air 11-inch is 1180x820
    final isTablet = screenSize.width > 600 || screenSize.height > 900;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallMobile ? 12 : (isTablet ? 20 : 16)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: isSmallMobile ? 16 : (isTablet ? 24 : 20),
                spreadRadius: isSmallMobile ? 1 : (isTablet ? 3 : 2),
              ),
            ],
          ),
          child: Icon(
            Icons.analytics,
            size: isSmallMobile ? 36 : (isTablet ? 56 : 48),
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallMobile ? 12 : (isTablet ? 32 : 24)),
        Text(
          'AI Technical Analysis',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallMobile ? 22 : (isTablet ? 40 : 32),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    // Get session-based cached stats (no real-time streaming)
    final stats = StatsService.getSessionStats();
    final screenSize = MediaQuery.of(context).size;
    final isSmallMobile = screenSize.width <= 375 && screenSize.height <= 812;
    
    return Container(
          padding: EdgeInsets.all(isSmallMobile ? 12 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E1E1E).withOpacity(0.8),
                const Color(0xFF2A2A2A).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: isSmallMobile ? 12 : 16,
                offset: Offset(0, isSmallMobile ? 6 : 8),
              ),
            ],
          ),
          child: isSmallMobile 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildStatItem(
                    'Tips',
                    StatsService.formatGeneratedTips(stats['generatedTips'] ?? 47),
                    Icons.trending_up,
                    Theme.of(context).colorScheme.primary,
                    isSmallMobile,
                  )),
                  Expanded(child: _buildStatItem(
                    'Success',
                    StatsService.formatSuccessRate((stats['successRate'] ?? 96.2).toDouble()),
                    Icons.verified,
                    Colors.green,
                    isSmallMobile,
                  )),
                  Expanded(child: _buildStatItem(
                    'Accuracy',
                    StatsService.formatAiAccuracy((stats['aiAccuracy'] ?? 98.7).toDouble()),
                    Icons.psychology,
                    Colors.blue,
                    isSmallMobile,
                  )),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Generated Tips',
                    StatsService.formatGeneratedTips(stats['generatedTips'] ?? 47),
                    Icons.trending_up,
                    Theme.of(context).colorScheme.primary,
                    isSmallMobile,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[700],
                  ),
                  _buildStatItem(
                    'Success Rate',
                    StatsService.formatSuccessRate((stats['successRate'] ?? 96.2).toDouble()),
                    Icons.verified,
                    Colors.green,
                    isSmallMobile,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[700],
                  ),
                  _buildStatItem(
                    'AI Accuracy',
                    StatsService.formatAiAccuracy((stats['aiAccuracy'] ?? 98.7).toDouble()),
                    Icons.psychology,
                    Colors.blue,
                    isSmallMobile,
                  ),
                ],
              ),
        );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, [bool isSmallMobile = false]) {
    final screenSize = MediaQuery.of(context).size;
    // Improved tablet detection - iPad Air 11-inch is 1180x820
    final isTablet = screenSize.width > 600 || screenSize.height > 900;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isSmallMobile ? 28 : (isTablet ? 44 : 36),
          height: isSmallMobile ? 28 : (isTablet ? 44 : 36),
          padding: EdgeInsets.all(isSmallMobile ? 4 : (isTablet ? 8 : 6)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallMobile ? 6 : (isTablet ? 10 : 8)),
          ),
          child: Center(
            child: Icon(
              icon, 
              color: color, 
              size: isSmallMobile ? 16 : (isTablet ? 24 : 20),
            ),
          ),
        ),
        SizedBox(height: isSmallMobile ? 4 : (isTablet ? 8 : 6)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : (isTablet ? 22 : 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isSmallMobile ? 1 : (isTablet ? 4 : 3)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallMobile ? 8 : (isTablet ? 14 : 12),
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeButtons(double buttonHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Improved tablet detection - iPad Air 11-inch is 1180x820
    final isTablet = screenWidth > 600 || screenHeight > 900;
    final isSmallMobile = screenWidth <= 375 && screenHeight <= 812;
    
    return Consumer<TradingTipsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Expanded(
              child: _buildTimeframeButton(
                context,
                'Short Term',
                'Quick scalping opportunities',
                Icons.flash_on,
                const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                () => _navigateToTip(context, provider, 'short_term'),
                provider.isLoading,
              ),
            ),
            SizedBox(height: isSmallMobile ? 4 : (isTablet ? 16 : 10)),
            Expanded(
              child: _buildTimeframeButton(
                context,
                'Mid Term',
                'Swing trading positions',
                Icons.trending_up,
                const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                () => _navigateToTip(context, provider, 'mid_term'),
                provider.isLoading,
              ),
            ),
            SizedBox(height: isSmallMobile ? 4 : (isTablet ? 16 : 10)),
            Expanded(
              child: _buildTimeframeButton(
                context,
                'Long Term',
                'Investment opportunities',
                Icons.timeline,
                const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                () => _navigateToTip(context, provider, 'long_term'),
                provider.isLoading,
              ),
            ),
            SizedBox(height: isSmallMobile ? 6 : (isTablet ? 20 : 14)),
            Expanded(
              child: _buildTradingActionButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeframeButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
    bool isLoading,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Improved tablet detection - iPad Air 11-inch is 1180x820
    final isTablet = screenWidth > 600 || screenHeight > 900;
    final isSmallMobile = screenWidth <= 375 && screenHeight <= 812;
    
    return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 12 : (isTablet ? 24 : 16),
                vertical: isSmallMobile ? 1 : (isTablet ? 12 : 6),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient.colors.map((c) => c.withOpacity(0.1)).toList(),
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: gradient.colors.first.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 4 : (isTablet ? 12 : 8)),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: isSmallMobile ? 16 : (isTablet ? 24 : 18)),
                  ),
                  SizedBox(width: isTablet ? 16 : 10),
                  Expanded(
                    child: isSmallMobile 
                      ? Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 14,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 10,
                                color: Colors.grey[400],
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: isTablet ? 22 : 16,
                      height: isTablet ? 22 : 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: gradient.colors.first,
                      size: isTablet ? 16 : 12,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildTradingActionButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get actual available space from constraints
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        
        // Define responsive breakpoints based on Flutter best practices
        final isCompact = availableWidth < 600;
        final isMedium = availableWidth >= 600 && availableWidth < 840;
        final isExpanded = availableWidth >= 840;
        
        // Calculate responsive sizes based on available space
        final horizontalPadding = isCompact ? 16.0 : (isMedium ? 20.0 : 24.0);
        final iconSize = isCompact ? 18.0 : (isMedium ? 20.0 : 24.0);
        final titleFontSize = isCompact ? 16.0 : (isMedium ? 18.0 : 20.0);
        final subtitleFontSize = isCompact ? 11.0 : (isMedium ? 12.0 : 14.0);
        
        // Determine if we have enough height for two-line layout
        final hasEnoughHeight = availableHeight >= 60;
        final shouldShowSubtitle = hasEnoughHeight && !isCompact;
        
        // Calculate padding based on available height
        final verticalPadding = hasEnoughHeight ? 
          (isCompact ? 8.0 : (isMedium ? 12.0 : 16.0)) : 
          6.0;
        
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 44.0, // Minimum touch target
            maxHeight: availableHeight,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _openTradingPlatform();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFF8C00),
                      Color(0xFFFF6347),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6.0 : 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8.0 : 12.0),
                    
                    // Text content - use Flexible to prevent overflow
                    Flexible(
                      child: shouldShowSubtitle ? 
                        // Two-line layout when there's enough space
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start Trading',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Turn insights into profits',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ) :
                        // Single-line layout for compact spaces
                        Text(
                          'Start Trading',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ),
                    
                    SizedBox(width: isCompact ? 8.0 : 12.0),
                    
                    // Arrow icon
                    Container(
                      padding: EdgeInsets.all(isCompact ? 4.0 : 6.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: isCompact ? 14.0 : 16.0,
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

  void _openTradingPlatform() async {
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚀 Opening trading platform...'),
          backgroundColor: const Color(0xFFFFD700),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Launch trading platform URL from Firebase
      final success = await TradingLinkService.launchTradingPlatform();
      
      if (!success) {
        // Show error if launch failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Unable to open trading platform'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error opening trading platform: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Error opening trading platform'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildFooter() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DisclaimerPage(),
              ),
            );
          },
          child: Text(
            'Disclaimer',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              decoration: TextDecoration.underline,
              decorationColor: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToTip(BuildContext context, TradingTipsProvider provider, String timeframe) async {
    final tip = await provider.getTipForTimeframe(timeframe);
    if (tip != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TradingTipScreen(tip: tip),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $timeframe tip available'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
