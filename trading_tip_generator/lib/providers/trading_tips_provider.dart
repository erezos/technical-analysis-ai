import 'package:flutter/foundation.dart';
import '../models/trading_tip.dart';
import '../services/firebase_service.dart';

class TradingTipsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, TradingTip> _latestTips = {};
  bool _isLoading = false;
  String? _error;

  Map<String, TradingTip> get latestTips => _latestTips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLatestTips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _latestTips = await _firebaseService.getLatestTips();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TradingTip?> getTipForTimeframe(String timeframe) async {
    try {
      return await _firebaseService.getLatestTipForTimeframe(timeframe);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
} 