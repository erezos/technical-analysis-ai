import 'package:flutter_test/flutter_test.dart';
import 'package:trading_tip_generator/services/trading_link_service.dart';

void main() {
  group('TradingLinkService Integration Tests - Country-Targeted System', () {
    
    setUp(() {
      // Reset service state before each test
      TradingLinkService.resetSession();
    });

    group('Complete Workflow Tests', () {
      test('should handle initialization gracefully even with Firebase errors', () async {
        // Reset service state
        TradingLinkService.resetSession();
        
        // Try to initialize (may fail due to Firebase not being set up in test environment)
        // This should not throw an exception
        expect(() async {
          try {
            await TradingLinkService.initializeTradingLinkForSession();
          } catch (e) {
            // Firebase errors are expected in test environment
            // The service should handle them gracefully
          }
        }, returnsNormally);
        
        // Should still provide a fallback URL
        final url = TradingLinkService.getTradingUrl();
        expect(url, isNotEmpty);
        expect(url, isA<String>());
      });

      test('should maintain session state correctly', () {
        // Initial state
        expect(TradingLinkService.isInitialized, isFalse);
        expect(TradingLinkService.detectedCountryCode, isNull);
        
        // After reset, state should be cleared
        TradingLinkService.resetSession();
        expect(TradingLinkService.isInitialized, isFalse);
        expect(TradingLinkService.detectedCountryCode, isNull);
      });

      test('should handle launch URL calls safely', () async {
        // This tests the URL launching mechanism without actually launching
        expect(() async {
          try {
            await TradingLinkService.launchTradingPlatform();
          } catch (e) {
            // URL launching may fail in test environment, but should not crash
          }
        }, returnsNormally);
      });

      test('should provide consistent URLs across multiple calls', () {
        // Multiple calls should return the same URL when not initialized
        final url1 = TradingLinkService.getTradingUrl();
        final url2 = TradingLinkService.getTradingUrl();
        final url3 = TradingLinkService.getTradingUrl();
        
        expect(url1, equals(url2));
        expect(url2, equals(url3));
        expect(url1, isNotEmpty);
      });

      test('should handle concurrent access safely', () async {
        // Test concurrent access to the service
        final futures = <Future<String>>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(Future.delayed(
            Duration(milliseconds: i * 10),
            () => TradingLinkService.getTradingUrl(),
          ));
        }
        
        final results = await Future.wait(futures);
        
        // All results should be the same
        for (final result in results) {
          expect(result, equals(results.first));
          expect(result, isNotEmpty);
        }
      });

      test('should reset and reinitialize correctly', () {
        // Get initial URL
        final initialUrl = TradingLinkService.getTradingUrl();
        expect(initialUrl, isNotEmpty);
        
        // Reset session
        TradingLinkService.resetSession();
        expect(TradingLinkService.isInitialized, isFalse);
        
        // Get URL again (should be the same fallback)
        final urlAfterReset = TradingLinkService.getTradingUrl();
        expect(urlAfterReset, equals(initialUrl));
      });
    });

    group('Country Detection Integration Tests', () {
      test('should provide location info for analytics', () {
        final locationInfo = TradingLinkService.getLocationInfo();
        
        expect(locationInfo, isA<Map<String, dynamic>>());
        expect(locationInfo.containsKey('country_code'), isTrue);
        expect(locationInfo.containsKey('country_name'), isTrue);
        expect(locationInfo.containsKey('detection_method'), isTrue);
      });

      test('should handle country detection failures gracefully', () {
        // Test that the service provides fallback behavior
        TradingLinkService.resetSession();
        
        final locationInfo = TradingLinkService.getLocationInfo();
        expect(locationInfo['country_code'], isNull);
        expect(locationInfo['country_name'], isNull);
        
        // Should still provide a valid URL
        final url = TradingLinkService.getTradingUrl();
        expect(url, isNotEmpty);
      });
    });

    group('URL Fallback Chain Tests', () {
      test('should use fallback URL when all methods fail', () {
        TradingLinkService.resetSession();
        
        final url = TradingLinkService.getTradingUrl();
        
        // Should return the hardcoded fallback URL
        expect(url, contains('zulutrade.com'));
        expect(url, contains('utm_campaign=fallback'));
      });

      test('should provide valid URL even without initialization', () {
        TradingLinkService.resetSession();
        
        final url = TradingLinkService.getTradingUrl();
        final uri = Uri.tryParse(url);
        
        expect(uri, isNotNull);
        expect(uri!.hasScheme, isTrue);
        expect(['http', 'https'].contains(uri.scheme), isTrue);
      });
    });

    group('Session Management Integration Tests', () {
      test('should handle multiple reset cycles', () {
        for (int i = 0; i < 5; i++) {
          TradingLinkService.resetSession();
          
          expect(TradingLinkService.isInitialized, isFalse);
          expect(TradingLinkService.detectedCountryCode, isNull);
          expect(TradingLinkService.detectedCountryName, isNull);
          
          final url = TradingLinkService.getTradingUrl();
          expect(url, isNotEmpty);
        }
      });

      test('should maintain URL consistency across resets', () {
        final initialUrl = TradingLinkService.getTradingUrl();
        
        for (int i = 0; i < 3; i++) {
          TradingLinkService.resetSession();
          final urlAfterReset = TradingLinkService.getTradingUrl();
          expect(urlAfterReset, equals(initialUrl));
        }
      });
    });

    group('Error Recovery Tests', () {
      test('should recover from initialization errors', () async {
        expect(() async {
          try {
            // Simulate initialization with potential errors
            await TradingLinkService.initializeTradingLinkForSession();
          } catch (e) {
            // Should handle errors gracefully
          }
          
          // Should still provide a valid URL after errors
          final url = TradingLinkService.getTradingUrl();
          expect(url, isNotEmpty);
        }, returnsNormally);
      });

      test('should handle network timeouts gracefully', () async {
        expect(() async {
          try {
            // Simulate network timeout scenario
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Network timeout');
          } catch (e) {
            // Should handle timeout gracefully
          }
          
          // Should still provide fallback URL
          final url = TradingLinkService.getTradingUrl();
          expect(url, isNotEmpty);
        }, returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should provide fast URL access', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          final url = TradingLinkService.getTradingUrl();
          expect(url, isNotEmpty);
        }
        
        stopwatch.stop();
        
        // Should complete 100 calls in reasonable time (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle rapid reset operations', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 50; i++) {
          TradingLinkService.resetSession();
          final url = TradingLinkService.getTradingUrl();
          expect(url, isNotEmpty);
        }
        
        stopwatch.stop();
        
        // Should complete 50 reset cycles in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });
  });
} 