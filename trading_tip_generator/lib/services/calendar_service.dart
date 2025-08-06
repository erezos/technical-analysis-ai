import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class CalendarEvent {
  final String id;
  final String date;
  final String time;
  final String country;
  final String importance;
  final String event;
  final String forecast;
  final String previous;
  final String? actual;
  final String type; // 'economic' or 'earnings'
  final String? company; // Only for earnings
  final String? symbol; // Only for earnings
  final String source;
  final DateTime? lastUpdated;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.time,
    required this.country,
    required this.importance,
    required this.event,
    required this.forecast,
    required this.previous,
    this.actual,
    required this.type,
    this.company,
    this.symbol,
    required this.source,
    this.lastUpdated,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      date: data['date'] ?? '',
      time: data['time'] ?? '00:00',
      country: data['country'] ?? 'Global',
      importance: data['importance'] ?? 'Medium',
      event: data['event'] ?? '',
      forecast: data['forecast'] ?? 'N/A',
      previous: data['previous'] ?? 'N/A',
      actual: data['actual'],
      type: data['type'] ?? 'economic',
      company: data['company'],
      symbol: data['symbol'],
      source: data['source'] ?? 'Unknown',
      lastUpdated: data['lastUpdated']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'time': time,
      'country': country,
      'importance': importance,
      'event': event,
      'forecast': forecast,
      'previous': previous,
      'actual': actual,
      'type': type,
      'company': company,
      'symbol': symbol,
      'source': source,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }
}

class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'calendar_events';

  /// Simple test method to verify Firebase connection
  static Future<int> testFirebaseConnection() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(5).get();
      AppLogger.info('📅 [TEST] Firebase connection test: ${snapshot.docs.length} documents found');
      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first.data();
        AppLogger.info('📅 [TEST] Sample document: ${firstDoc['date']} - ${firstDoc['event']}');
      }
      return snapshot.docs.length;
    } catch (error) {
      AppLogger.error('📅 [TEST] Firebase connection failed: $error');
      return -1;
    }
  }

  /// Get calendar events for a specific date range
  static Future<List<CalendarEvent>> getCalendarEvents({
    String? period,
    String? importance,
  }) async {
    try {
      AppLogger.info('📅 Fetching calendar events - Period: $period, Importance: $importance');

      // Calculate date range based on period
      final dateRange = _getDateRangeForPeriod(period ?? 'Today');
      AppLogger.info('📅 [DEBUG] Date range: ${dateRange['start']} to ${dateRange['end']}');
      
      Query query = _firestore.collection(_collection);
      
      // Filter by date range
      if (dateRange['start'] != null) {
        query = query.where('date', isGreaterThanOrEqualTo: dateRange['start']);
      }
      if (dateRange['end'] != null) {
        query = query.where('date', isLessThanOrEqualTo: dateRange['end']);
      }
      
      // Order by date and time
      query = query.orderBy('date').orderBy('time');
      
      final querySnapshot = await query.get();
      AppLogger.info('📅 [DEBUG] Raw query returned ${querySnapshot.docs.length} documents');
      
      List<CalendarEvent> events = querySnapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
      
      AppLogger.info('📅 [DEBUG] Events before importance filter: ${events.length}');
      if (events.isNotEmpty) {
        AppLogger.info('📅 [DEBUG] Sample event dates: ${events.take(3).map((e) => e.date).join(', ')}');
      }
      
      // Filter by importance if specified
      if (importance != null && importance != 'All') {
        events = events.where((event) => event.importance == importance).toList();
        AppLogger.info('📅 [DEBUG] Events after importance filter ($importance): ${events.length}');
      }
      
      AppLogger.info('✅ Fetched ${events.length} calendar events');
      return events;
      
    } catch (error) {
      AppLogger.error('❌ Failed to fetch calendar events: $error');
      
      // Return fallback data if Firebase fails
      return _getFallbackData(period);
    }
  }

  /// Get sync status from Firebase
  static Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final doc = await _firestore
          .collection('system_status')
          .doc('calendar_sync')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        AppLogger.info('📊 Calendar sync status: ${data['status']} - Last sync: ${data['lastSync']}');
        return data;
      }
      
      return null;
    } catch (error) {
      AppLogger.error('❌ Failed to get sync status: $error');
      return null;
    }
  }

  /// Listen to real-time calendar events (for live updates)
  static Stream<List<CalendarEvent>> streamCalendarEvents({
    String? period,
    String? importance,
  }) {
    try {
      AppLogger.info('🔄 Setting up real-time calendar events stream');
      
      final dateRange = _getDateRangeForPeriod(period ?? 'Today');
      
      Query query = _firestore.collection(_collection);
      
      // Filter by date range
      if (dateRange['start'] != null) {
        query = query.where('date', isGreaterThanOrEqualTo: dateRange['start']);
      }
      if (dateRange['end'] != null) {
        query = query.where('date', isLessThanOrEqualTo: dateRange['end']);
      }
      
      query = query.orderBy('date').orderBy('time');
      
      return query.snapshots().map((snapshot) {
        List<CalendarEvent> events = snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList();
        
        // Filter by importance if specified
        if (importance != null && importance != 'All') {
          events = events.where((event) => event.importance == importance).toList();
        }
        
        AppLogger.info('🔄 Real-time update: ${events.length} calendar events');
        return events;
      });
      
    } catch (error) {
      AppLogger.error('❌ Failed to setup calendar events stream: $error');
      
      // Return fallback stream
      return Stream.value(_getFallbackData(period));
    }
  }

  /// Calculate date range based on period selection
  static Map<String, String?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    String? startDate;
    String? endDate;
    
    switch (period) {
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = _formatDate(yesterday);
        endDate = _formatDate(yesterday);
        break;
      
      case 'Today':
        startDate = _formatDate(now);
        endDate = _formatDate(now);
        break;
      
      case 'Tomorrow':
        final tomorrow = now.add(const Duration(days: 1));
        startDate = _formatDate(tomorrow);
        endDate = _formatDate(tomorrow);
        break;
      
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        startDate = _formatDate(startOfWeek);
        endDate = _formatDate(endOfWeek);
        break;
      
      case 'Next Week':
        final nextWeekStart = now.add(Duration(days: 7 - now.weekday + 1));
        final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
        startDate = _formatDate(nextWeekStart);
        endDate = _formatDate(nextWeekEnd);
        break;
      
      default:
        // Default to today
        startDate = _formatDate(now);
        endDate = _formatDate(now);
    }
    
    return {'start': startDate, 'end': endDate};
  }

  /// Format date to YYYY-MM-DD string
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fallback data when Firebase is unavailable
  static List<CalendarEvent> _getFallbackData(String? period) {
    AppLogger.info('📋 Using fallback calendar data for period: $period');
    
    // Return a few sample events as fallback
    return [
      CalendarEvent(
        id: 'fallback_1',
        date: _formatDate(DateTime.now()),
        time: '08:30',
        country: 'US',
        importance: 'High',
        event: 'Sample Economic Event',
        forecast: 'N/A',
        previous: 'N/A',
        type: 'economic',
        source: 'Fallback',
      ),
      CalendarEvent(
        id: 'fallback_2',
        date: _formatDate(DateTime.now()),
        time: 'After Market',
        country: 'US',
        importance: 'High',
        event: 'Sample Earnings',
        forecast: 'N/A',
        previous: 'N/A',
        type: 'earnings',
        company: 'Sample Corp',
        symbol: 'SMPL',
        source: 'Fallback',
      ),
    ];
  }

  /// Manual refresh trigger (for pull-to-refresh)
  static Future<bool> triggerManualSync() async {
    try {
      AppLogger.info('🔄 Triggering manual calendar sync...');
      
      // You could call a Firebase Function to trigger immediate sync
      // For now, we'll just return true to indicate refresh is triggered
      // In a real implementation, you might call:
      // await FirebaseFunctions.instance.httpsCallable('syncCalendarData').call();
      
      return true;
    } catch (error) {
      AppLogger.error('❌ Failed to trigger manual sync: $error');
      return false;
    }
  }
}