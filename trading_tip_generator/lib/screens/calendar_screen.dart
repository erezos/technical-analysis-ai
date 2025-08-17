import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/app_logger.dart';
import '../services/calendar_service.dart';
import '../services/ad_service.dart';
import '../services/ad_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _selectedPeriod = 'Today';
  String _selectedImportance = 'All';
  bool _isLoading = false;
  List<CalendarEvent> _events = [];

  
  // Banner ad management (no interstitials for calendar)
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isLoadingBannerAd = false;

  final List<String> _periods = ['Yesterday', 'Today', 'Tomorrow', 'This Week', 'Next Week'];
  final List<String> _importanceLevels = ['All', 'High', 'Medium', 'Low'];
  final Map<String, String> _countries = {
    'US': '🇺🇸',
    'EU': '🇪🇺', 
    'UK': '🇬🇧',
    'JP': '🇯🇵',
    'CA': '🇨🇦',
    'AU': '🇦🇺',
    'CH': '🇨🇭',
    'CN': '🇨🇳',
  };

  @override
  void initState() {
    super.initState();
    _logPageView();
    _testFirebaseConnection();
    _loadCalendarData();


  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load banner ad here when MediaQuery is available
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _testFirebaseConnection() async {
    await CalendarService.testFirebaseConnection();
  }
  
  /// Load adaptive banner ad for bottom placement
  Future<void> _loadBannerAd() async {
    if (!mounted) return;
    
    if (_isLoadingBannerAd || _isBannerAdLoaded) return;
    
    setState(() {
      _isLoadingBannerAd = true;
    });
    
    final screenWidth = MediaQuery.of(context).size.width.truncate();
    
    try {
      _bannerAd = await AdService.createAdaptiveBanner(
        width: screenWidth,
        adUnitId: AdHelper.calendarBannerAdUnitId,
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _bannerAd = ad;
              _isBannerAdLoaded = true;
              _isLoadingBannerAd = false;
            });
            AppLogger.info('💰 Banner ad loaded for calendar screen');
          }
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.error('❌ Failed to load banner ad in calendar: $error');
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _isLoadingBannerAd = false;
            });
          }
        },
      );
      
    } catch (e) {
      AppLogger.error('💥 Exception loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isLoadingBannerAd = false;
        });
      }
    }
  }
  


  Future<void> _loadCalendarData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      AppLogger.info('📅 Loading calendar data from Firebase...');
      final events = await CalendarService.getCalendarEvents(
        period: _selectedPeriod,
        importance: _selectedImportance,
      );
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
        AppLogger.info('✅ Calendar data loaded: ${events.length} events');
      }
    } catch (error) {
      AppLogger.error('❌ Failed to load calendar data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _onPeriodChanged(String period) async {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
      });
      _logFilterChange('period', period);
      await _loadCalendarData();
    }
  }

  Future<void> _onImportanceChanged(String importance) async {
    if (_selectedImportance != importance) {
      setState(() {
        _selectedImportance = importance;
      });
      _logFilterChange('importance', importance);
      await _loadCalendarData();
    }
  }

  Future<void> _onRefresh() async {
    AppLogger.info('🔄 Manual refresh triggered');
    await CalendarService.triggerManualSync();
    await _loadCalendarData();

  }





  void _logPageView() {
    AppLogger.info('📅 [ANALYTICS] Economic calendar screen view logged');
    FirebaseAnalytics.instance.logEvent(
      name: 'economic_calendar_screen_view',
      parameters: {
        'screen_name': 'economic_calendar_screen',
        'implementation': 'native_flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void _logFilterChange(String filterType, String value) {
    AppLogger.info('📅 [ANALYTICS] Calendar filter changed: $filterType = $value');
    FirebaseAnalytics.instance.logEvent(
      name: 'economic_calendar_filter_change',
      parameters: {
        'filter_type': filterType,
        'filter_value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  List<CalendarEvent> get _filteredEvents {
    // Firebase service already handles filtering, so just return the events
    return _events;
  }

  Color _getImportanceColor(String importance) {
    switch (importance) {
      case 'High':
        return const Color(0xFFFF6B6B);
      case 'Medium':
        return const Color(0xFFFFE066);
      case 'Low':
        return const Color(0xFF4ECDC4);
      default:
        return Colors.grey;
    }
  }

  IconData _getImportanceIcon(String importance) {
    switch (importance) {
      case 'High':
        return Icons.priority_high;
      case 'Medium':
        return Icons.remove;
      case 'Low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0F13), Color(0xFF16222A), Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFF00373A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 24,
                color: Color(0xFF00F0C8),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ECONOMIC CALENDAR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 22,
                    letterSpacing: 1.1,
                    color: const Color(0xFF00F0C8),
                    shadows: const [
                      Shadow(
                        blurRadius: 16,
                        color: Color(0xFF00F0C8),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF00F0C8),
                  backgroundColor: const Color(0xFF2A2A3E),
                  child: Column(
                    children: [
                      // Filters Section
                      _buildFiltersSection(),
                      
                      // Events List
                      Expanded(
                        child: _buildEventsList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Banner Ad (Bottom placement for optimal revenue)
              if (_isBannerAdLoaded && _bannerAd != null) ...[
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFF2A2A3E),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Filter
          _buildPeriodFilter(),
          const SizedBox(height: 16),
          
          // Importance Filter
          _buildImportanceFilter(),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onPeriodChanged(period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF00F0C8), Color(0xFF00D4AA)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFF3A3A4E),
                    width: 1,
                  ),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImportanceFilter() {
    return Container(
      height: 32, // Compact height
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _importanceLevels.length,
        itemBuilder: (context, index) {
          final level = _importanceLevels[index];
          final isSelected = level == _selectedImportance;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onImportanceChanged(level),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected 
                    ? const LinearGradient(
                        colors: [Color(0xFF00F0C8), Color(0xFF00C4A7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                  color: isSelected ? null : const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00F0C8) : const Color(0xFF3A3A4E), 
                    width: 1
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (level != 'All') ...[
                      Icon(
                        _getImportanceIcon(level),
                        color: isSelected ? const Color(0xFF1A1A2E) : _getImportanceColor(level),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      level,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildEventsList() {
    final filteredEvents = _filteredEvents;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0C8)),
        ),
      );
    }
    
    if (filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildCompactEventRow(filteredEvents[index]);
      },
    );
  }

  Widget _buildCompactEventRow(CalendarEvent event) {
    final importanceColor = _getImportanceColor(event.importance);
    final countryFlag = _countries[event.country] ?? '🏳️';
    final isEarnings = event.type == 'earnings';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E).withValues(alpha: 0.6),
        border: Border(
          left: BorderSide(
            color: importanceColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 65,
            child: Text(
              event.time,
              style: const TextStyle(
                color: Color(0xFF00F0C8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Country Flag
          Text(
            countryFlag,
            style: const TextStyle(fontSize: 16),
          ),
          
          const SizedBox(width: 12),
          
          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name with Type Icon
                Row(
                  children: [
                    if (isEarnings) ...[
                      const Icon(
                        Icons.business,
                        size: 14,
                        color: Color(0xFFFFE066),
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      Icon(
                        _getImportanceIcon(event.importance),
                        size: 14,
                        color: importanceColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        event.event,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Data Row
                Row(
                  children: [
                    _buildCompactDataItem('F:', event.forecast, const Color(0xFFFFE066)),
                    const SizedBox(width: 12),
                    _buildCompactDataItem('P:', event.previous, Colors.white.withValues(alpha: 0.7)),
                    if (event.actual != null) ...[
                      const SizedBox(width: 12),
                      _buildCompactDataItem('A:', event.actual!, const Color(0xFF4ECDC4)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDataItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}

