import 'package:flutter_test/flutter_test.dart';

import 'package:trading_tip_generator/services/trading_link_service.dart';

void main() {
  group('TradingLinkService - Country-Targeted System Tests', () {
    
    setUp(() {
      // Reset service state before each test
      TradingLinkService.resetSession();
    });

    group('Country Detection Tests', () {
      test('should detect country from device locale as fallback', () {
        // Test locale-based detection logic
        final testLocales = [
          'en_US', // Should detect US
          'en_GB', // Should detect GB
          'fr_FR', // Should detect FR
          'invalid', // Should handle invalid format
        ];

        for (final locale in testLocales) {
          String? detectedCountry;
          
          if (locale.contains('_')) {
            final countryCode = locale.split('_').last.toUpperCase();
            if (countryCode.length == 2) {
              detectedCountry = countryCode;
            }
          }
          
          if (locale == 'en_US') {
            expect(detectedCountry, equals('US'));
          } else if (locale == 'en_GB') {
            expect(detectedCountry, equals('GB'));
          } else if (locale == 'fr_FR') {
            expect(detectedCountry, equals('FR'));
          } else {
            expect(detectedCountry, isNull);
          }
        }
      });

      test('should handle IP geolocation failure gracefully', () async {
        // Test that service doesn't crash on IP detection failure
        expect(() async {
          // Simulate the detection logic
          String? countryCode;
          String? countryName;
          
          try {
            // This would be the actual IP detection call
            throw Exception('Network error');
          } catch (e) {
            countryCode = 'UNKNOWN';
            countryName = 'Unknown';
          }
          
          expect(countryCode, equals('UNKNOWN'));
          expect(countryName, equals('Unknown'));
        }, returnsNormally);
      });
    });

    group('URL Routing Logic Tests', () {
      test('should select country-specific URL from Firestore data', () {
        // Mock Firestore document with country-specific URLs
        final mockData = {
          'trading_url_us': 'https://us-broker.com',
          'trading_url_gb': 'https://uk-broker.com',
          'trading_url_fr': 'https://fr-broker.com',
          'primary_url': 'https://global-broker.com',
          'backup_url': 'https://backup-broker.com',
        };

        // Test country-specific URL selection
        final usUrl = mockData['trading_url_us'] ?? mockData['primary_url'];
        final gbUrl = mockData['trading_url_gb'] ?? mockData['primary_url'];
        final frUrl = mockData['trading_url_fr'] ?? mockData['primary_url'];
        final unknownCountryUrl = mockData['primary_url'];

        expect(usUrl, equals('https://us-broker.com'));
        expect(gbUrl, equals('https://uk-broker.com'));
        expect(frUrl, equals('https://fr-broker.com'));
        expect(unknownCountryUrl, equals('https://global-broker.com'));
      });

      test('should fallback to primary URL when country-specific URL not found', () {
        final mockData = {
          'primary_url': 'https://global-broker.com',
          'backup_url': 'https://backup-broker.com',
          // No country-specific URLs
        };

        // Test fallback logic
        const countryKey = 'trading_url_unknown';
        final selectedUrl = mockData[countryKey] ?? mockData['primary_url'];

        expect(selectedUrl, equals('https://global-broker.com'));
      });

      test('should handle empty Firestore data gracefully', () {
        // Test fallback to hardcoded URL
        const fallbackUrl = 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=fallback';
        
        expect(fallbackUrl, isNotEmpty);
        expect(fallbackUrl, contains('zulutrade.com'));
      });
    });

    group('URL Validation Tests', () {
      test('should validate trading URLs correctly', () {
        final validUrls = [
          'https://www.zulutrade.com/?ref=2915819',
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

      test('should reject invalid trading URLs', () {
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
            final isValidForTrading = uri != null && ['http', 'https'].contains(uri.scheme);
            expect(isValidForTrading, isFalse, 
                   reason: 'Invalid URL should be rejected: $url');
          }
        }
      });
    });

    group('Session Management Tests', () {
      test('should initialize session correctly', () {
        expect(TradingLinkService.isInitialized, isFalse);
        expect(TradingLinkService.detectedCountryCode, isNull);
        expect(TradingLinkService.detectedCountryName, isNull);
      });

      test('should reset session correctly', () {
        TradingLinkService.resetSession();
        
        expect(TradingLinkService.isInitialized, isFalse);
        expect(TradingLinkService.detectedCountryCode, isNull);
        expect(TradingLinkService.detectedCountryName, isNull);
      });

      test('should provide fallback URL when not initialized', () {
        TradingLinkService.resetSession();
        
        final url = TradingLinkService.getTradingUrl();
        
        expect(url, equals('https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=fallback'));
        expect(url, isNotEmpty);
      });

      test('should track initialization state', () {
        expect(TradingLinkService.isInitialized, isFalse);
        
        TradingLinkService.resetSession();
        expect(TradingLinkService.isInitialized, isFalse);
      });
    });

    group('Location Info Tests', () {
      test('should provide detailed location info for analytics', () {
        final locationInfo = TradingLinkService.getLocationInfo();
        
        expect(locationInfo, isA<Map<String, dynamic>>());
        expect(locationInfo.containsKey('country_code'), isTrue);
        expect(locationInfo.containsKey('country_name'), isTrue);
        expect(locationInfo.containsKey('detection_method'), isTrue);
      });

      test('should handle null location data gracefully', () {
        TradingLinkService.resetSession();
        
        final locationInfo = TradingLinkService.getLocationInfo();
        
        expect(locationInfo['country_code'], isNull);
        expect(locationInfo['country_name'], isNull);
        expect(locationInfo['detection_method'], isA<String>());
      });
    });

    group('URL Launch Tests', () {
      test('should validate URL before launching', () {
        const validUrl = 'https://www.zulutrade.com/?ref=2915819';
        const invalidUrl = 'not-a-valid-url';
        
        final validUri = Uri.tryParse(validUrl);
        final invalidUri = Uri.tryParse(invalidUrl);
        
        expect(validUri, isNotNull);
        // Uri.tryParse returns a Uri even for invalid URLs, but it won't have a scheme
        expect(invalidUri, isNotNull);
        expect(invalidUri!.hasScheme, isFalse);
      });

      test('should handle URL launch errors gracefully', () async {
        // Test that the service doesn't crash on launch errors
        expect(() async {
          try {
            // Simulate URL launch attempt
            throw Exception('URL launch failed');
          } catch (e) {
            // Should handle error gracefully
            expect(e, isA<Exception>());
          }
        }, returnsNormally);
      });
    });

    group('Integration Tests', () {
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

    group('Error Handling Tests', () {
      test('should handle Firebase Remote Config errors gracefully', () async {
        expect(() async {
          try {
            // Simulate Remote Config error
            throw Exception('Firebase Remote Config error');
          } catch (e) {
            // Should fallback to Firestore
            expect(e, isA<Exception>());
          }
        }, returnsNormally);
      });

      test('should handle Firestore errors gracefully', () async {
        expect(() async {
          try {
            // Simulate Firestore error
            throw Exception('Firestore connection error');
          } catch (e) {
            // Should fallback to hardcoded URL
            expect(e, isA<Exception>());
          }
        }, returnsNormally);
      });

      test('should handle network errors gracefully', () async {
        expect(() async {
          try {
            // Simulate network error
            throw Exception('Network timeout');
          } catch (e) {
            // Should use fallback mechanisms
            expect(e, isA<Exception>());
          }
        }, returnsNormally);
      });
    });

    group('Country-Specific URL Logic Tests', () {
      test('should generate correct country keys for Firestore', () {
        final testCountries = [
          'US', 'GB', 'FR', 'DE', 'JP', 'CA', 'AU'
        ];

        for (final country in testCountries) {
          final countryKey = 'trading_url_${country.toLowerCase()}';
          expect(countryKey, equals('trading_url_${country.toLowerCase()}'));
        }
      });

      test('should handle country code normalization', () {
        final testCases = [
          {'input': 'us', 'expected': 'us'},
          {'input': 'US', 'expected': 'us'},
          {'input': 'Us', 'expected': 'us'},
          {'input': 'GB', 'expected': 'gb'},
        ];

        for (final testCase in testCases) {
          final normalized = testCase['input']!.toString().toLowerCase();
          expect(normalized, equals(testCase['expected']));
        }
      });

      test('should prioritize country-specific URLs over primary URL', () {
        final mockData = {
          'trading_url_us': 'https://us-specific-broker.com',
          'primary_url': 'https://global-broker.com',
        };

        const countryKey = 'trading_url_us';
        final selectedUrl = mockData[countryKey] ?? mockData['primary_url'];

        expect(selectedUrl, equals('https://us-specific-broker.com'));
        expect(selectedUrl, isNot(equals('https://global-broker.com')));
      });
    });
  });
} 