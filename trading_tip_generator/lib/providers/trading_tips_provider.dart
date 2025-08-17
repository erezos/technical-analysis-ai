import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trading_tip.dart';
import '../services/firebase_service.dart';
import '../utils/anr_prevention.dart';
import '../utils/app_logger.dart';

class TradingTipsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, TradingTip> _latestTips = {};
  bool _isLoading = false;
  String? _error;

  Map<String, TradingTip> get latestTips => _latestTips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLatestTips() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('📊 Loading latest trading tips with ANR prevention...');
      
      // Use timeout to prevent indefinite blocking
      _latestTips = await ANRPrevention.executeWithTimeout(
        _firebaseService.getLatestTips(),
        timeout: const Duration(seconds: 10),
        debugName: 'loadLatestTips',
      );
      
      AppLogger.info('✅ Loaded ${_latestTips.length} trading tips');
      
    } on TimeoutException catch (e) {
      _error = 'Loading timed out. Please check your connection.';
      AppLogger.error('⏰ Tips loading timeout: $e');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('❌ Error loading tips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TradingTip?> getTipForTimeframe(String timeframe) async {
    try {
      AppLogger.info('📊 Loading tip for timeframe: $timeframe');
      
      final tip = await ANRPrevention.executeWithTimeout(
        _firebaseService.getLatestTipForTimeframe(timeframe),
        timeout: const Duration(seconds: 8),
        debugName: 'getTipForTimeframe_$timeframe',
      );
      
      return tip;
    } on TimeoutException catch (e) {
      _error = 'Tip loading timed out for $timeframe';
      AppLogger.error('⏰ Tip timeout for $timeframe: $e');
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('❌ Error loading tip for $timeframe: $e');
      notifyListeners();
      return null;
    }
  }
} 