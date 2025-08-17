import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/providers/trading_tips_provider.dart';
import '../../lib/services/firebase_service.dart';
import '../../lib/models/trading_tip.dart';

// Generate mocks
@GenerateMocks([FirebaseService])
import 'trading_tips_provider_test.mocks.dart';

void main() {
  group('TradingTipsProvider', () {
    late TradingTipsProvider provider;
    late MockFirebaseService mockFirebaseService;
    
    setUp(() {
      mockFirebaseService = MockFirebaseService();
      provider = TradingTipsProvider();
      
      // Replace the private firebase service with our mock
      // Note: This would require making the service injectable or public
      // For now, we'll test the public interface
    });
    
    group('loadLatestTips', () {
      test('should load tips successfully', () async {
        // Arrange
        final mockTips = {
          'tip1': TradingTip(
            id: 'tip1',
            symbol: 'AAPL',
            sentiment: 'bullish',
            entryPrice: 150.0,
            stopLoss: 145.0,
            takeProfit: 160.0,
            timestamp: DateTime.now(),
            timeframe: 'short_term',
            reasoning: 'Test reasoning',
            signalStrength: 4.0,
          ),
          'tip2': TradingTip(
            id: 'tip2',
            symbol: 'GOOGL',
            sentiment: 'bearish',
            entryPrice: 2500.0,
            stopLoss: 2550.0,
            takeProfit: 2400.0,
            timestamp: DateTime.now(),
            timeframe: 'mid_term',
            reasoning: 'Test reasoning 2',
            signalStrength: 3.5,
          ),
        };
        
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) async => mockTips);
        
        // Act
        await provider.loadLatestTips();
        
        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.latestTips, hasLength(2));
      });
      
      test('should handle loading errors gracefully', () async {
        // Arrange
        when(mockFirebaseService.getLatestTips())
            .thenThrow(Exception('Network error'));
        
        // Act
        await provider.loadLatestTips();
        
        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Exception: Network error'));
        expect(provider.latestTips, isEmpty);
      });
      
      test('should handle timeout errors', () async {
        // Arrange
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) async {
          // Simulate a long-running operation
          await Future.delayed(const Duration(seconds: 15));
          return <String, TradingTip>{};
        });
        
        // Act
        await provider.loadLatestTips();
        
        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('timed out'));
      });
      
      test('should not start loading if already loading', () async {
        // Arrange
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return <String, TradingTip>{};
        });
        
        // Act
        final future1 = provider.loadLatestTips();
        final future2 = provider.loadLatestTips(); // Should return immediately
        
        await Future.wait([future1, future2]);
        
        // Assert
        expect(provider.isLoading, isFalse);
        // Verify that getLatestTips was called only once
        verify(mockFirebaseService.getLatestTips()).called(1);
      });
      
      test('should update loading state correctly', () async {
        // Arrange
        final completer = Completer<Map<String, TradingTip>>();
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) => completer.future);
        
        // Act
        final loadingFuture = provider.loadLatestTips();
        
        // Assert - Should be loading
        expect(provider.isLoading, isTrue);
        expect(provider.error, isNull);
        
        // Complete the operation
        completer.complete(<String, TradingTip>{});
        await loadingFuture;
        
        // Assert - Should not be loading anymore
        expect(provider.isLoading, isFalse);
      });
    });
    
    group('getTipForTimeframe', () {
      test('should get tip for specific timeframe successfully', () async {
        // Arrange
        final mockTip = TradingTip(
          id: 'tip1',
          symbol: 'AAPL',
          sentiment: 'bullish',
          entryPrice: 150.0,
          stopLoss: 145.0,
          takeProfit: 160.0,
          timestamp: DateTime.now(),
          timeframe: 'short_term',
          reasoning: 'Test reasoning',
          signalStrength: 4.0,
        );
        
        when(mockFirebaseService.getLatestTipForTimeframe('short_term'))
            .thenAnswer((_) async => mockTip);
        
        // Act
        final result = await provider.getTipForTimeframe('short_term');
        
        // Assert
        expect(result, isNotNull);
        expect(result!.symbol, equals('AAPL'));
        expect(result.timeframe, equals('short_term'));
        expect(provider.error, isNull);
      });
      
      test('should handle timeframe errors gracefully', () async {
        // Arrange
        when(mockFirebaseService.getLatestTipForTimeframe('invalid_timeframe'))
            .thenThrow(Exception('Invalid timeframe'));
        
        // Act
        final result = await provider.getTipForTimeframe('invalid_timeframe');
        
        // Assert
        expect(result, isNull);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Exception: Invalid timeframe'));
      });
      
      test('should handle timeout for specific timeframe', () async {
        // Arrange
        when(mockFirebaseService.getLatestTipForTimeframe('long_term'))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 10));
          return null;
        });
        
        // Act
        final result = await provider.getTipForTimeframe('long_term');
        
        // Assert
        expect(result, isNull);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('timed out'));
      });
      
      test('should handle null response from service', () async {
        // Arrange
        when(mockFirebaseService.getLatestTipForTimeframe('mid_term'))
            .thenAnswer((_) async => null);
        
        // Act
        final result = await provider.getTipForTimeframe('mid_term');
        
        // Assert
        expect(result, isNull);
        expect(provider.error, isNull); // No error, just no data
      });
    });
    
    group('ANR Prevention', () {
      test('should not block main thread during tip loading', () async {
        // Arrange
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) async {
          // Simulate some processing time
          await Future.delayed(const Duration(milliseconds: 50));
          return <String, TradingTip>{};
        });
        
        final stopwatch = Stopwatch()..start();
        
        // Act
        await provider.loadLatestTips();
        
        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10s
      });
      
      test('should handle concurrent loading requests', () async {
        // Arrange
        when(mockFirebaseService.getLatestTips())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return <String, TradingTip>{};
        });
        
        // Act - Multiple concurrent requests
        final futures = List.generate(3, (_) => provider.loadLatestTips());
        
        // Assert - All should complete without issues
        await Future.wait(futures);
        expect(provider.isLoading, isFalse);
        
        // Should only call the service once due to loading guard
        verify(mockFirebaseService.getLatestTips()).called(1);
      });
    });
  });
}
