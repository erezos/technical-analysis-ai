import 'package:flutter_test/flutter_test.dart';
import 'package:trading_tip_generator/utils/trading_background_utils.dart';

void main() {
  group('TradingBackgroundUtils Tests', () {
    
    test('should return bullish background for bullish sentiment', () {
      final background = TradingBackgroundUtils.getRandomBackground('bullish');
      
      expect(background, contains('bullish'));
      expect(background, contains('assets/images/trading_backgrounds/bullish/'));
      expect(background, endsWith('.png'));
    });
    
    test('should return bearish background for bearish sentiment', () {
      final background = TradingBackgroundUtils.getRandomBackground('bearish');
      
      expect(background, contains('bearish'));
      expect(background, contains('assets/images/trading_backgrounds/bearish/'));
      expect(background, endsWith('.png'));
    });
    
    test('should handle case insensitive sentiment', () {
      final backgrounds = [
        TradingBackgroundUtils.getRandomBackground('BULLISH'),
        TradingBackgroundUtils.getRandomBackground('Bullish'),
        TradingBackgroundUtils.getRandomBackground('bullish'),
      ];
      
      for (final bg in backgrounds) {
        expect(bg, contains('bullish'));
      }
    });
    
    test('should return valid background for null sentiment', () {
      final background = TradingBackgroundUtils.getRandomBackground(null);
      
      expect(background, isNotEmpty);
      expect(background, startsWith('assets/images/trading_backgrounds/'));
      expect(background, endsWith('.png'));
    });
    
    test('should return different backgrounds on multiple calls (randomness)', () {
      final backgrounds = <String>{};
      
      // Generate 20 backgrounds to test randomness
      for (int i = 0; i < 20; i++) {
        backgrounds.add(TradingBackgroundUtils.getRandomBackground('bullish'));
      }
      
      // Should have at least 2 different backgrounds (out of 5 available)
      expect(backgrounds.length, greaterThanOrEqualTo(2));
    });
    
    test('should return correct total background count', () {
      final total = TradingBackgroundUtils.getTotalBackgroundCount();
      expect(total, 10); // 5 bullish + 5 bearish
    });
    
    test('should correctly identify background type', () {
      const bullishPath = 'assets/images/trading_backgrounds/bullish/bullish_background_1.png';
      const bearishPath = 'assets/images/trading_backgrounds/bearish/bearish_background_1.png';
      const unknownPath = 'assets/images/other/unknown.png';
      
      expect(TradingBackgroundUtils.getBackgroundType(bullishPath), 'bullish');
      expect(TradingBackgroundUtils.getBackgroundType(bearishPath), 'bearish');
      expect(TradingBackgroundUtils.getBackgroundType(unknownPath), 'unknown');
    });
    
    group('Performance Tests', () {
      test('should generate background quickly', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          TradingBackgroundUtils.getRandomBackground('bullish');
        }
        
        stopwatch.stop();
        final avgTimePerCall = stopwatch.elapsedMicroseconds / 1000;
        
        // Should be very fast - less than 100 microseconds per call
        expect(avgTimePerCall, lessThan(100));
        
        // Performance test completed successfully
      });
    });
  });
} 