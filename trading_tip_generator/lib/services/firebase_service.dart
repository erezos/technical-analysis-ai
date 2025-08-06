import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trading_tip.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, TradingTip>> getLatestTips() async {
    try {
      AppLogger.info('Fetching latest tips...');
      final snapshot = await _firestore.collection('latest_tips').get();
      AppLogger.info('Got ${snapshot.docs.length} tips');
      final tips = <String, TradingTip>{};
      
      for (var doc in snapshot.docs) {
        AppLogger.info('Processing tip document: ${doc.id}');
        AppLogger.info('Document data: ${doc.data()}');
        tips[doc.id] = TradingTip.fromMap(doc.data());
      }
      
      return tips;
    } catch (e) {
      AppLogger.error('Error fetching latest tips: $e');
      return {};
    }
  }

  Future<TradingTip?> getLatestTipForTimeframe(String timeframe) async {
    try {
      AppLogger.info('Fetching tip for timeframe: $timeframe');
      final doc = await _firestore.collection('latest_tips').doc(timeframe).get();
      AppLogger.info('Document exists: ${doc.exists}');
      if (doc.exists) {
        AppLogger.info('Document data: ${doc.data()}');
        return TradingTip.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching tip for timeframe $timeframe: $e');
      return null;
    }
  }
} 