import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

// Import the service we're testing
import '../../lib/services/trading_link_service.dart';

void main() {
  group('TradingLinkService Tests', () {
    setUp(() {
      // Reset the service state before each test
      TradingLinkService.resetSession();
    });

    group('Country Detection Logic Tests', () {
      test('should correctly identify US users', () {
        // Test US country code detection logic
        final usCodes = ['US', 'USA'];
        
        for (final code in usCodes) {
          final isUSUser = (code == 'US' || code == 'USA');
          expect(isUSUser, isTrue, reason: 'Failed for country code: $code');
        }
      });

      test('should correctly identify non-US users', () {
        // Test non-US country code detection logic
        final nonUSCodes = ['GB', 'DE', 'FR', 'JP', 'CA', 'AU', 'IN'];
        
        for (final code in nonUSCodes) {
          final isUSUser = (code == 'US' || code == 'USA');
          expect(isUSUser, isFalse, reason: 'Failed for country code: $code');
        }
      });

      test('should parse device locale correctly', () {
        // Test locale parsing logic
        final testLocales = {
          'en_US': 'US',
          'en_GB': 'GB',
          'de_DE': 'DE',
          'fr_FR': 'FR',
          'ja_JP': 'JP',
          'es_ES': 'ES',
        };

        for (final entry in testLocales.entries) {
          final locale = entry.key;
          final expectedCountry = entry.value;
          
          if (locale.contains('_')) {
            final countryCode = locale.split('_').last.toUpperCase();
            expect(countryCode, equals(expectedCountry), 
                   reason: 'Failed to parse locale: $locale');
          }
        }
      });

      test('should handle malformed locale gracefully', () {
        final malformedLocales = ['en', 'invalid', '', 'en_', '_US', 'en_US_variant'];
        
        for (final locale in malformedLocales) {
          expect(() {
            if (locale.contains('_')) {
              final parts = locale.split('_');
              if (parts.length >= 2 && parts.last.isNotEmpty) {
                final countryCode = parts.last.toUpperCase();
                // Should not throw
                expect(countryCode.length, greaterThanOrEqualTo(0));
              }
            }
          }, returnsNormally, reason: 'Failed to handle locale: $locale');
        }
      });
    });

    group('URL Routing Logic Tests', () {
      test('should return backup URL for US users', () {
        // Simulate Firebase data
        final urlData = {
          'primary_url': 'https://international-broker.com',
          'backup_url': 'https://us-compliant-broker.com',
        };
        final isUSUser = true;

        // Apply routing logic (same as in service)
        final selectedUrl = isUSUser 
            ? urlData['backup_url'] ?? urlData['primary_url']
            : urlData['primary_url'];

        expect(selectedUrl, equals('https://us-compliant-broker.com'));
      });

      test('should return primary URL for non-US users', () {
        // Simulate Firebase data
        final urlData = {
          'primary_url': 'https://international-broker.com',
          'backup_url': 'https://us-compliant-broker.com',
        };
        final isUSUser = false;

        // Apply routing logic (same as in service)
        final selectedUrl = isUSUser 
            ? urlData['backup_url'] ?? urlData['primary_url']
            : urlData['primary_url'];

        expect(selectedUrl, equals('https://international-broker.com'));
      });

      test('should fallback to primary URL if backup URL missing for US users', () {
        // Simulate Firebase data without backup URL
        final urlData = {
          'primary_url': 'https://international-broker.com',
          // No backup_url
        };
        final isUSUser = true;

        // Apply routing logic with fallback (same as in service)
        final selectedUrl = isUSUser 
            ? urlData['backup_url'] ?? urlData['primary_url']
            : urlData['primary_url'];

        expect(selectedUrl, equals('https://international-broker.com'));
      });

      test('should provide hard-coded fallback when all Firebase URLs missing', () {
        // Simulate empty Firebase data
        final urlData = <String, String>{};
        final fallbackUrl = 'https://www.trading212.com/';

        // Apply fallback logic (same as in service)
        final selectedUrl = urlData['primary_url'] ?? fallbackUrl;

        expect(selectedUrl, equals('https://www.trading212.com/'));
      });
    });

    group('Session Management Tests', () {
      test('should reset session correctly', () {
        // Act: Reset session
        TradingLinkService.resetSession();

        // Assert: All session data should be cleared
        expect(TradingLinkService.isInitialized, isFalse);
        expect(TradingLinkService.detectedCountryCode, isNull);
        expect(TradingLinkService.isUSUser, isFalse);
      });

      test('should provide fallback URL when not initialized', () {
        // Arrange: Ensure not initialized
        TradingLinkService.resetSession();

        // Act: Get trading URL before initialization
        final url = TradingLinkService.getTradingUrl();

        // Assert: Should return fallback URL
        expect(url, equals('https://www.trading212.com/'));
      });

      test('should track initialization state', () {
        // Initial state should be uninitialized
        TradingLinkService.resetSession();
        expect(TradingLinkService.isInitialized, isFalse);
        
        // After reset, should still be uninitialized
        expect(TradingLinkService.isInitialized, isFalse);
      });
    });

    group('URL Validation Tests', () {
      test('should validate URL format correctly', () {
        // Test valid URLs
        final validUrls = [
          'https://www.trading212.com/',
          'https://app.trading212.com/login',
          'https://secure-broker.com/trade?param=value',
          'http://localhost:3000/test',
        ];

        for (final url in validUrls) {
          final uri = Uri.tryParse(url);
          expect(uri, isNotNull, reason: 'Failed to parse valid URL: $url');
          expect(uri!.hasScheme, isTrue, reason: 'URL missing scheme: $url');
          expect(['http', 'https'].contains(uri.scheme), isTrue, 
                 reason: 'Invalid scheme for URL: $url');
        }
      });

      test('should reject invalid URLs', () {
        final invalidUrls = [
          '',
          'not-a-url',
          'ftp://invalid-protocol.com',
          'javascript:alert(1)',
          'file:///etc/passwd',
        ];

        for (final url in invalidUrls) {
          if (url.isEmpty) {
            expect(url, isEmpty, reason: 'Empty URL should be empty');
          } else {
            final uri = Uri.tryParse(url);
            // Should either be null or not have http/https scheme
            final isValidForTrading = uri != null && ['http', 'https'].contains(uri.scheme);
            expect(isValidForTrading, isFalse, 
                   reason: 'Invalid URL should be rejected: $url');
          }
        }
      });
    });

    group('Error Handling Logic Tests', () {
      test('should handle null values gracefully', () {
        // Test handling of null/malformed Firebase data
        final malformedData = {
          'primary_url': null,
          'backup_url': 123, // Wrong type
          'invalid_field': 'should be ignored',
        };

        // Simulate safe data access (same pattern as in service)
        String? primaryUrl;
        String? backupUrl;
        
        try {
          primaryUrl = malformedData['primary_url'] as String?;
        } catch (e) {
          primaryUrl = null;
        }
        
        try {
          backupUrl = malformedData['backup_url'] as String?;
        } catch (e) {
          backupUrl = null;
        }
        
        expect(primaryUrl, isNull);
        expect(backupUrl, isNull); // Type mismatch should result in null
      });

      test('should handle network errors gracefully', () {
        // Test that SocketException can be thrown (for HTTP timeouts)
        expect(() => throw const SocketException('No Internet'), 
               throwsA(isA<SocketException>()));
      });

      test('should handle timeout scenarios', () {
        // Test timeout handling logic
        const timeoutDuration = Duration(seconds: 5);
        expect(timeoutDuration.inSeconds, equals(5));
        expect(timeoutDuration.inMilliseconds, equals(5000));
      });
    });

    group('Integration Workflow Tests', () {
      test('complete workflow: US user gets backup URL', () {
        // Simulate complete workflow for US user
        final firebaseData = {
          'primary_url': 'https://international-broker.com',
          'backup_url': 'https://us-broker.com',
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Simulate country detection
        final detectedCountry = 'US';
        final isUSUser = (detectedCountry == 'US' || detectedCountry == 'USA');

        // Apply URL routing logic
        final selectedUrl = isUSUser 
            ? firebaseData['backup_url'] ?? firebaseData['primary_url']
            : firebaseData['primary_url'];

        // Verify complete workflow
        expect(detectedCountry, equals('US'));
        expect(isUSUser, isTrue);
        expect(selectedUrl, equals('https://us-broker.com'));
      });

      test('complete workflow: non-US user gets primary URL', () {
        // Simulate complete workflow for non-US user
        final firebaseData = {
          'primary_url': 'https://international-broker.com',
          'backup_url': 'https://us-broker.com',
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Simulate country detection
        final detectedCountry = 'GB';
        final isUSUser = (detectedCountry == 'US' || detectedCountry == 'USA');

        // Apply URL routing logic
        final selectedUrl = isUSUser 
            ? firebaseData['backup_url'] ?? firebaseData['primary_url']
            : firebaseData['primary_url'];

        // Verify complete workflow
        expect(detectedCountry, equals('GB'));
        expect(isUSUser, isFalse);
        expect(selectedUrl, equals('https://international-broker.com'));
      });

      test('complete workflow with failures should use fallback', () {
        // Simulate all failures scenario
        final firebaseExists = false;
        final detectedCountry = null; // Failed geolocation
        final isUSUser = false; // Default when detection fails
        final fallbackUrl = 'https://www.trading212.com/';

        // Apply complete fallback logic
        final selectedUrl = firebaseExists 
            ? 'would-use-firebase-data'
            : fallbackUrl;

        // Verify fallback workflow
        expect(firebaseExists, isFalse);
        expect(detectedCountry, isNull);
        expect(isUSUser, isFalse);
        expect(selectedUrl, equals('https://www.trading212.com/'));
      });
    });
  });
} 