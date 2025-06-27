import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'disclaimer_page.dart';
import 'providers/trading_tips_provider.dart';
import 'screens/trading_tip_screen.dart';
import 'screens/hot_board_screen_enhanced.dart';
import 'screens/lesson_screen.dart';
import 'models/trading_tip.dart';
import 'services/notification_service.dart';
import 'services/stats_service.dart';
import 'services/trading_link_service.dart';
import 'services/notification_permission_service_fixed.dart';
import 'services/educational_service.dart';
import 'widgets/premium_glassmorphism_nav.dart';
import 'widgets/responsive/responsive_layout.dart';
import 'widgets/education_category_button.dart';
import 'widgets/enhanced_micro_animations.dart';
import 'widgets/premium_fintech_buttons.dart';
import 'widgets/premium_trading_icons.dart';
import 'widgets/premium_typography.dart';
import 'utils/trading_background_utils.dart';
// CRITICAL: Background message handler for iOS and Android notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background context
  await Firebase.initializeApp();
  
  print('🔔 Background message received: ${message.messageId}');
  print('📱 Message data: ${message.data}');
  print('📢 Notification: ${message.notification?.title} - ${message.notification?.body}');
  
  // Handle the background message based on type
  if (message.data['type'] == 'trading_tip') {
    print('📈 Trading tip received in background: ${message.data['symbol']}');
    print('⏰ Timeframe: ${message.data['timeframe']}');
    print('🎯 Target timeframe: ${message.data['target_timeframe']}');
  } else if (message.data['type'] == 'crypto_tip') {
    print('₿ Crypto tip received in background: ${message.data['symbol']}');
  }
  
  // Optional: Show local notification for background messages
  // This ensures notifications are displayed even in background/terminated state
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // CRITICAL: Register background message handler BEFORE any other Firebase operations
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize app statistics
  await StatsService.initializeStatsForSession();
  
  // Initialize trading link
  await TradingLinkService.initializeTradingLinkForSession();
  
  // Initialize educational content (NEW)
  await EducationalService.initializeEducationalContent();
  
  // Enable edge-to-edge display - best practice for Android full screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Set transparent system bars for edge-to-edge experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global navigator key for notification handling
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TradingTipsProvider(),
      child: MaterialApp(
        title: 'Trading Tip Generator',
        theme: _buildTheme(),
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        // Add routes for notification navigation
        routes: {
          '/hot_board': (context) => const HotBoardScreenEnhanced(),
        },
        onGenerateRoute: (settings) {
          // Handle trading tip route with arguments
          if (settings.name == '/trading_tip') {
            final args = settings.arguments as Map<String, dynamic>?;
            
            // If we have notification data, navigate to the specific timeframe screen
            if (args != null) {
              final symbol = args['symbol'] ?? 'Unknown';
              final timeframe = args['target_timeframe'] ?? args['timeframe'] ?? 'short_term';
              
              print('🧭 Route handling: Navigating to $symbol ($timeframe)');
              
              // Instead of creating a placeholder tip, navigate to HomeScreen and then fetch the specific timeframe tip
              return MaterialPageRoute(
                builder: (context) => _NotificationTipNavigator(
                  symbol: symbol,
                  timeframe: timeframe,
                ),
                settings: settings,
              );
            }
          }
          return null;
        },
        // Initialize notifications after MaterialApp is ready
        builder: (context, child) {
          // Initialize notifications with navigator key
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.initialize(navigatorKey: navigatorKey);
          });
          return child!;
        },
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
        onSurface: Color(0xFFE1E1E1),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFE1E1E1), // Text/icon color
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
      extendBodyBehindAppBar: true, // Extend content behind status bar for full edge-to-edge
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
              Colors.black.withOpacity( 0.85),
              Colors.black.withOpacity( 0.9),
              Colors.black.withOpacity( 0.95),
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
          color: const Color(0xFF00D4AA).withOpacity( 0.2),
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
                    color: const Color(0xFF00D4AA).withOpacity( 0.2),
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
                color: const Color(0xFF00D4AA).withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity( 0.3),
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
          color: Colors.white.withOpacity( 0.1),
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
    // Screen-relative spacing based on best practices
    final screenHeight = MediaQuery.sizeOf(context).height;
    final baseSpacing = screenHeight * 0.01; // 1% of screen height as base unit
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        SizedBox(height: baseSpacing * 2.5), // 2.5% of screen height
        _buildStatsCard(),
        SizedBox(height: baseSpacing * 2), // 2% of screen height
        Flexible(
          flex: 1,
          child: _buildTimeframeButtons(buttonHeight),
        ),
        SizedBox(height: baseSpacing * 1.5), // 1.5% of screen height
        _buildFooter(),
      ],
    );
  }

  Widget _buildScrollableLayout(double buttonHeight, bool isSmallMobile, bool isTablet) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final baseSpacing = screenHeight * 0.01; // 1% of screen height as base unit
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: baseSpacing * 3), // 3% of screen height
          _buildStatsCard(),
          SizedBox(height: baseSpacing * 2.5), // 2.5% of screen height
          _buildTimeframeButtons(buttonHeight),
          SizedBox(height: baseSpacing * 2.5), // 2.5% of screen height
          _buildFooter(),
          SizedBox(height: baseSpacing * 4), // 4% of screen height bottom padding
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive breakpoints based on industry standards
    final isCompact = screenWidth < 600; // Phone
    final isMedium = screenWidth >= 600 && screenWidth < 900; // Tablet
    final isExpanded = screenWidth >= 900; // Desktop
    
    // BIGGER icon sizing (12% of screen height instead of 10%)
    final iconSize = (screenHeight * 0.12).clamp(90.0, 140.0);
    
    // Smaller spacing for tighter layout (1.5-2% of screen height)
    final spacing = (screenHeight * 0.015).clamp(12.0, 24.0);
    
    return Column(
      children: [
        PremiumTradingIcons.premiumLogo(
          size: iconSize,
          animated: true,
        ),
        SizedBox(height: spacing),
        PremiumTypography.responsiveTitle(
          text: 'AI Technical Analysis',
          context: context,
          animated: true,
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive breakpoints
    final isCompact = screenWidth < 600; // Phone
    final isMedium = screenWidth >= 600 && screenWidth < 900; // Tablet
    final isExpanded = screenWidth >= 900; // Desktop
    
    // Better padding for smaller height (3-4% of screen width)
    final horizontalPadding = (screenWidth * 0.035).clamp(20.0, 40.0);
    final verticalPadding = (screenHeight * 0.015).clamp(10.0, 20.0); // SMALLER vertical padding for lower height
    final borderRadius = (screenWidth * 0.03).clamp(16.0, 24.0);
    
    // Smaller divider height
    final dividerHeight = (screenHeight * 0.025).clamp(16.0, 28.0); // SMALLER divider
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.04).clamp(16.0, 32.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildStatItem('Tips', '23', Icons.trending_up, const Color(0xFF00D4AA), isCompact),
            ),
            Container(
              width: 1,
              height: dividerHeight,
              color: Colors.grey[600]?.withOpacity(0.5),
            ),
            Expanded(
              child: _buildStatItem('Success', '98%', Icons.check_circle, const Color(0xFF4CAF50), isCompact),
            ),
            Container(
              width: 1,
              height: dividerHeight,
              color: Colors.grey[600]?.withOpacity(0.5),
            ),
            Expanded(
              child: _buildStatItem('Accuracy', '97%', Icons.track_changes, const Color(0xFF2196F3), isCompact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, [bool isCompact = false]) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Responsive breakpoints
    final isMedium = screenWidth >= 600 && screenWidth < 900; // Tablet
    final isExpanded = screenWidth >= 900; // Desktop
    
    // Good icon sizing (6-7% of screen width)
    final iconSize = (screenWidth * 0.065).clamp(36.0, 54.0);
    final iconPadding = (iconSize * 0.25).clamp(7.0, 13.0);
    final borderRadius = (iconSize * 0.25).clamp(9.0, 13.0);
    
    // Good text sizing
    final valueTextSize = isCompact 
        ? (screenWidth * 0.045).clamp(18.0, 26.0)
        : (screenWidth * 0.038).clamp(22.0, 30.0);
    final labelTextSize = isCompact 
        ? (screenWidth * 0.028).clamp(11.0, 15.0)
        : (screenWidth * 0.024).clamp(13.0, 17.0);
    
    // SMALLER vertical spacing for more compact stats
    final verticalSpacing = (screenHeight * 0.005).clamp(4.0, 8.0);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withOpacity( 0.15),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(
            child: Icon(
              icon, 
              color: color, 
              size: iconSize * 0.55,
            ),
          ),
        ),
        SizedBox(height: verticalSpacing),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueTextSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: verticalSpacing * 0.5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelTextSize,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
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
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available space and adjust accordingly
            final availableHeight = constraints.maxHeight;
            final minButtonHeight = isSmallMobile ? 40.0 : 48.0;
            final spacing = (screenHeight * 0.015).clamp(8.0, 20.0); // 1.5% of screen height
            
            // Calculate if we have enough space for all buttons
            final totalSpacing = spacing * 3; // 3 spaces between 4 buttons
            final totalMinHeight = (minButtonHeight * 4) + totalSpacing;
            
            // Use IntrinsicHeight to prevent overflow
            return totalMinHeight > availableHeight
              ? _buildCompactTimeframeButtons(provider, isSmallMobile, isTablet)
              : _buildStandardTimeframeButtons(provider, isSmallMobile, isTablet, spacing);
          },
        );
      },
    );
  }

  Widget _buildStandardTimeframeButtons(TradingTipsProvider provider, bool isSmallMobile, bool isTablet, double spacing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: 1,
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
        SizedBox(height: spacing),
        Flexible(
          flex: 1,
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
        SizedBox(height: spacing),
        Flexible(
          flex: 1,
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
        SizedBox(height: spacing),
        Flexible(
          flex: 1,
          child: _buildTradingActionButton(),
        ),
      ],
    );
  }

  Widget _buildCompactTimeframeButtons(TradingTipsProvider provider, bool isSmallMobile, bool isTablet) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final spacing = (screenHeight * 0.01).clamp(6.0, 12.0); // 1% of screen height for compact spacing
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeframeButton(
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
          SizedBox(height: spacing),
          _buildTimeframeButton(
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
          SizedBox(height: spacing),
          _buildTimeframeButton(
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
          SizedBox(height: spacing),
          _buildTradingActionButton(),
          SizedBox(height: isSmallMobile ? 8.0 : 12.0), // Extra bottom padding
        ],
      ),
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on available space
        final availableHeight = constraints.maxHeight;
        final minHeight = isSmallMobile ? 40.0 : 48.0;
        final hasEnoughHeightForDescription = availableHeight >= 60 && !isSmallMobile;
        
        return AnimatedTradingCard(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: minHeight,
              maxHeight: availableHeight,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isLoading ? null : onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : (isTablet ? 24 : 16),
                    vertical: isSmallMobile ? 8 : (isTablet ? 12 : 10),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate if we truly have enough space for multi-line content
                            final reallyHasSpace = constraints.maxHeight >= 50 && hasEnoughHeightForDescription;
                            
                            return reallyHasSpace
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: isTablet ? 20 : 14,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (constraints.maxHeight >= 52) ...[
                                      const SizedBox(height: 2),
                                      Flexible(
                                        child: Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: isTablet ? 14 : 10,
                                            color: Colors.grey[400],
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: isSmallMobile ? 14 : (isTablet ? 18 : 16),
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                          },
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 10),
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
          ),
        );
      },
    );
  }

  Widget _buildTradingActionButton() {
    return Container(
      width: double.infinity,
      child: PremiumFintechButtons.primaryAction(
        text: 'Start Trading',
        subtitle: 'Turn insights into profits',
        icon: Icons.rocket_launch,
        context: context,
        onPressed: () async {
          _openTradingPlatform();
        },
      ),
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

/// Widget to handle notification-based navigation to specific timeframe tips
class _NotificationTipNavigator extends StatefulWidget {
  final String symbol;
  final String timeframe;

  const _NotificationTipNavigator({
    required this.symbol,
    required this.timeframe,
  });

  @override
  State<_NotificationTipNavigator> createState() => _NotificationTipNavigatorState();
}

class _NotificationTipNavigatorState extends State<_NotificationTipNavigator> {
  @override
  void initState() {
    super.initState();
    // Navigate to the specific timeframe tip after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSpecificTip();
    });
  }

  Future<void> _navigateToSpecificTip() async {
    try {
      // Get the trading tips provider
      final provider = context.read<TradingTipsProvider>();
      
      // Load latest tips if not already loaded
      await provider.loadLatestTips();
      
      // Get the tip for the specific timeframe
      final tip = await provider.getTipForTimeframe(widget.timeframe);
      
      if (tip != null && mounted) {
        // Navigate to the tip screen
        Navigator.of(context).pushReplacement(
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
        // If no tip available, show message and navigate to home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No ${widget.timeframe.replaceAll('_', ' ')} tip available for ${widget.symbol}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          
          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Error navigating to specific tip: $e');
      if (mounted) {
        // Navigate to home screen on error
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while navigating
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
                Colors.black.withOpacity( 0.85),
                Colors.black.withOpacity( 0.9),
                Colors.black.withOpacity( 0.95),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading Trading Tip...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
