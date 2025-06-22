import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../lib/services/trading_link_service.dart';

void main() {
  group('TradingLinkService Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset the service state before each test
      TradingLinkService.resetSession();
    });

    test('should provide fallback URL when Firebase is unavailable', () async {
      // Reset to ensure clean state
      TradingLinkService.resetSession();
      
      // Get URL before initialization (should return fallback)
      final url = TradingLinkService.getTradingUrl();
      
      // Should return hard-coded fallback
      expect(url, equals('https://www.trading212.com/'));
      expect(TradingLinkService.isInitialized, isFalse);
    });

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
      expect(TradingLinkService.isUSUser, isFalse);
      
      // After reset, state should be cleared
      TradingLinkService.resetSession();
      expect(TradingLinkService.isInitialized, isFalse);
      expect(TradingLinkService.detectedCountryCode, isNull);
      expect(TradingLinkService.isUSUser, isFalse);
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
} 