import 'package:flutter_test/flutter_test.dart';
import 'package:trading_tip_generator/models/trading_tip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Company Model Tests', () => {
    test('should create Company from valid map', () {
      final map = <String, dynamic>{
        'name': 'Apple Inc.',
        'symbol': 'AAPL',
        'logoUrl': 'assets/logos/stocks/AAPL.png',
        'sector': 'Technology',
        'business': 'Consumer Electronics',
        'isCrypto': false,
      };

      final company = Company.fromMap(map);

      expect(company.name, 'Apple Inc.');
      expect(company.symbol, 'AAPL');
      expect(company.logoUrl, 'assets/logos/stocks/AAPL.png');
      expect(company.sector, 'Technology');
      expect(company.business, 'Consumer Electronics');
      expect(company.isCrypto, false);
    }),

    test('should handle missing fields gracefully', () {
      final map = <String, dynamic>{
        'name': 'Test Company',
      };

      final company = Company.fromMap(map);

      expect(company.name, 'Test Company');
      expect(company.symbol, '');
      expect(company.logoUrl, '');
      expect(company.sector, '');
      expect(company.business, '');
      expect(company.isCrypto, false);
    }),

    test('should handle crypto companies', () {
      final map = <String, dynamic>{
        'name': 'Bitcoin',
        'symbol': 'BTC/USDT',
        'logoUrl': 'assets/logos/crypto/BTC.png',
        'sector': 'Cryptocurrency',
        'business': 'Digital Gold',
        'isCrypto': true,
      };

      final company = Company.fromMap(map);

      expect(company.name, 'Bitcoin');
      expect(company.isCrypto, true);
      expect(company.logoUrl, contains('crypto'));
    }),
  });

  group('TradingTip Model Tests', () => {
    test('should create TradingTip from valid map', () {
      final map = <String, dynamic>{
        'symbol': 'AAPL',
        'timeframe': 'long_term',
        'sentiment': 'bullish',
        'strength': 2.5,
        'entryPrice': 195.50,
        'stopLoss': 185.00,
        'takeProfit': 210.00,
        'company': <String, dynamic>{
          'name': 'Apple Inc.',
          'symbol': 'AAPL',
          'logoUrl': 'assets/logos/stocks/AAPL.png',
          'sector': 'Technology',
          'business': 'Consumer Electronics',
          'isCrypto': false,
        },
        'images': <String, dynamic>{
          'latestTradingCard': <String, dynamic>{
            'url': 'https://storage.googleapis.com/test-bucket/image.png'
          }
        },
        'reasoning': <String>['Strong RSI signal', 'MACD bullish crossover'],
        'createdAt': Timestamp.now(),
      };

      final tip = TradingTip.fromMap(map);

      expect(tip.symbol, 'AAPL');
      expect(tip.timeframe, 'long_term');
      expect(tip.sentiment, 'bullish');
      expect(tip.strength, 2.5);
      expect(tip.entryPrice, 195.50);
      expect(tip.stopLoss, 185.00);
      expect(tip.takeProfit, 210.00);
      expect(tip.company?.name, 'Apple Inc.');
      expect(tip.hasLogo, true);
      expect(tip.hasAnalysisData, true);
    }),

    test('should handle missing optional fields', () {
      final map = <String, dynamic>{
        'symbol': 'TEST',
        'timeframe': 'short_term',
        'sentiment': 'bearish',
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
      };

      final tip = TradingTip.fromMap(map);

      expect(tip.symbol, 'TEST');
      expect(tip.strength, null);
      expect(tip.entryPrice, null);
      expect(tip.company, null);
      expect(tip.hasLogo, false);
      expect(tip.hasAnalysisData, true); // Has sentiment
    }),

    test('should format display values correctly', () {
      final map = <String, dynamic>{
        'symbol': 'AAPL',
        'timeframe': 'long_term',
        'sentiment': 'bullish',
        'strength': 2.5,
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
      };

      final tip = TradingTip.fromMap(map);

      expect(tip.formattedTimeframe, 'LONG TERM');
      expect(tip.sentimentDisplay, 'BULLISH');
      expect(tip.strengthDisplay, '2.5');
    }),

    test('should handle null values in display methods', () {
      final map = <String, dynamic>{
        'symbol': 'TEST',
        'timeframe': 'short_term',
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
      };

      final tip = TradingTip.fromMap(map);

      expect(tip.sentimentDisplay, 'N/A');
      expect(tip.strengthDisplay, 'N/A');
      expect(tip.companyName, 'TEST'); // Falls back to symbol
    }),
  });

  group('TradingTip Validation Tests', () => {
    test('should validate required fields', () {
      final validMap = <String, dynamic>{
        'symbol': 'AAPL',
        'timeframe': 'long_term',
        'sentiment': 'bullish',
        'strength': 2.5,
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
      };

      final tip = TradingTip.fromMap(validMap);

      expect(tip.symbol.isNotEmpty, true);
      expect(tip.timeframe.isNotEmpty, true);
      expect(tip.sentiment?.isNotEmpty, true);
    }),

    test('should handle crypto trading pairs', () {
      final cryptoMap = <String, dynamic>{
        'symbol': 'BTC/USDT',
        'timeframe': 'mid_term',
        'sentiment': 'bearish',
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
        'company': <String, dynamic>{
          'name': 'Bitcoin',
          'isCrypto': true,
          'logoUrl': 'assets/logos/crypto/BTC.png',
        }
      };

      final tip = TradingTip.fromMap(cryptoMap);

      expect(tip.symbol, contains('/'));
      expect(tip.company?.isCrypto, true);
      expect(tip.company?.logoUrl, contains('crypto'));
    }),

    test('should handle price formatting safely', () {
      final map = <String, dynamic>{
        'symbol': 'AAPL',
        'timeframe': 'long_term',
        'entryPrice': 195.12345,
        'stopLoss': 185.98765,
        'takeProfit': 210.54321,
        'createdAt': Timestamp.now(),
        'images': <String, dynamic>{},
      };

      final tip = TradingTip.fromMap(map);

      // Safe formatting with null checks
      expect(tip.entryPrice?.toStringAsFixed(2), '195.12');
      expect(tip.stopLoss?.toStringAsFixed(2), '185.99');
      expect(tip.takeProfit?.toStringAsFixed(2), '210.54');
    }),
  });
} 