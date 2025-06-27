import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trading_tip.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, TradingTip>> getLatestTips() async {
    try {
      print('Fetching latest tips...');
      final snapshot = await _firestore.collection('latest_tips').get();
      print('Got ${snapshot.docs.length} tips');
      final tips = <String, TradingTip>{};
      
      for (var doc in snapshot.docs) {
        print('Processing tip document: ${doc.id}');
        print('Document data: ${doc.data()}');
        tips[doc.id] = TradingTip.fromMap(doc.data());
      }
      
      return tips;
    } catch (e) {
      print('Error fetching latest tips: $e');
      return {};
    }
  }

  Future<TradingTip?> getLatestTipForTimeframe(String timeframe) async {
    try {
      print('Fetching tip for timeframe: $timeframe');
      final doc = await _firestore.collection('latest_tips').doc(timeframe).get();
      print('Document exists: ${doc.exists}');
      if (doc.exists) {
        print('Document data: ${doc.data()}');
        return TradingTip.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching tip for timeframe $timeframe: $e');
      return null;
    }
  }
} 