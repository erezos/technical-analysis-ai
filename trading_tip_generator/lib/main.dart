import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'disclaimer_page.dart';
import 'providers/trading_tips_provider.dart';
import 'screens/trading_tip_screen.dart';
import 'services/notification_service.dart';
import 'services/stats_service.dart';
import 'services/trading_link_service.dart';
import 'services/notification_permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  // Initialize app statistics
  await StatsService.initializeStatsForSession();
  
  // Initialize trading link
  await TradingLinkService.initializeTradingLinkForSession();
  
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
      cardTheme: CardTheme(
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenHeight > 800;
    final buttonHeight = isTablet ? 65.0 : 60.0; // Reduced button heights
    final requiredHeight = (buttonHeight * 4) + (12 * 3) + 250; // More conservative estimate
    final needsScrolling = screenHeight < requiredHeight;
    
    return Scaffold(
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
                child: needsScrolling 
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                        child: _buildScrollableContent(screenHeight, isTablet, buttonHeight),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                      child: _buildFixedContent(screenHeight, isTablet, buttonHeight),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedContent(double screenHeight, bool isTablet, double buttonHeight) {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: screenHeight * 0.03),
        _buildStatsCard(),
        SizedBox(height: screenHeight * 0.02),
        Expanded(
          child: _buildTimeframeButtons(buttonHeight),
        ),
        SizedBox(height: screenHeight * 0.015),
        _buildFooter(),
      ],
    );
  }

  Widget _buildScrollableContent(double screenHeight, bool isTablet, double buttonHeight) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildStatsCard(),
        const SizedBox(height: 20),
        _buildTimeframeButtons(buttonHeight),
        const SizedBox(height: 20),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AI Technical Analysis',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Generator',
          style: TextStyle(
            fontSize: 24,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    // Get session-based cached stats (no real-time streaming)
    final stats = StatsService.getSessionStats();
    
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E1E1E).withOpacity(0.8),
                const Color(0xFF2A2A2A).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Generated Tips',
                StatsService.formatGeneratedTips(stats['generatedTips'] ?? 47),
                Icons.trending_up,
                Theme.of(context).colorScheme.primary,
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
              ),
            ],
          ),
        );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeButtons(double buttonHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenHeight > 800;
    
    return Consumer<TradingTipsProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: buttonHeight,
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
            SizedBox(height: isTablet ? 12 : 10),
            SizedBox(
              height: buttonHeight,
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
            SizedBox(height: isTablet ? 12 : 10),
            SizedBox(
              height: buttonHeight,
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
            SizedBox(height: isTablet ? 16 : 14),
            SizedBox(
              height: buttonHeight + 5, // Trading button slightly taller
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
    final isTablet = screenHeight > 800;
    
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
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 8 : 6,
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
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
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
                    width: isTablet ? 18 : 16,
                    height: isTablet ? 18 : 16,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: gradient.colors.first,
                    size: isTablet ? 14 : 12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradingActionButton() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenHeight > 800;
    
    return Container(
      width: double.infinity,
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
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 10 : 8,
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
                Container(
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Trading',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Turn insights into profits',
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
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
