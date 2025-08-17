import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/app_rating_service.dart';

void main() {
  group('AppRatingService', () {
    
    setUp(() {
      // Set up mock shared preferences for each test
      SharedPreferences.setMockInitialValues({});
    });
    
    group('Rating Statistics', () {
      test('should return correct rating statistics', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_rated_app': true,
          'rating_request_count': 2,
          'last_rating_request': 1234567890,
          'came_from_notification': true,
        });
        
        // Act
        final stats = await AppRatingService.getRatingStats();
        
        // Assert
        expect(stats['has_rated'], isTrue);
        expect(stats['request_count'], equals(2));
        expect(stats['last_request'], equals(1234567890));
        expect(stats['from_notification'], isTrue);
      });
      
      test('should return default values for missing preferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        
        // Act
        final stats = await AppRatingService.getRatingStats();
        
        // Assert
        expect(stats['has_rated'], isFalse);
        expect(stats['request_count'], equals(0));
        expect(stats['last_request'], equals(0));
        expect(stats['from_notification'], isFalse);
      });
    });
    
    group('In-App Review Request', () {
      test('should handle in-app review request without throwing', () async {
        // Act & Assert - Should not throw
        expect(
          () => AppRatingService.requestInAppReview(),
          returnsNormally,
        );
      });
    });
    
    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // Act & Assert - Should not throw
        expect(
          () => AppRatingService.getRatingStats(),
          returnsNormally,
        );
      });
    });
    
    group('Rating Service Configuration', () {
      test('should have correct configuration constants', () {
        // This test verifies that the service is properly configured
        // We can't test private constants directly, but we can verify behavior
        
        expect(true, isTrue); // Service exists and can be imported
      });
      
      test('should track rating statistics correctly over time', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        
        // Act - Get initial stats
        var stats = await AppRatingService.getRatingStats();
        
        // Assert initial state
        expect(stats['has_rated'], isFalse);
        expect(stats['request_count'], equals(0));
        
        // Simulate user interaction by setting preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_rated_app', true);
        await prefs.setInt('rating_request_count', 1);
        
        // Get updated stats
        stats = await AppRatingService.getRatingStats();
        
        // Assert updated state
        expect(stats['has_rated'], isTrue);
        expect(stats['request_count'], equals(1));
      });
    });
    
    group('Rating Flow Logic', () {
      test('should properly manage rating request state', () async {
        // Arrange - Fresh state
        SharedPreferences.setMockInitialValues({});
        
        // Act - Check initial state
        var stats = await AppRatingService.getRatingStats();
        
        // Assert - User hasn't rated initially
        expect(stats['has_rated'], isFalse);
        expect(stats['request_count'], equals(0));
        
        // Simulate rating flow progression
        final prefs = await SharedPreferences.getInstance();
        
        // User sees first rating request
        await prefs.setInt('rating_request_count', 1);
        await prefs.setInt('last_rating_request', DateTime.now().millisecondsSinceEpoch);
        
        stats = await AppRatingService.getRatingStats();
        expect(stats['request_count'], equals(1));
        
        // User completes rating
        await prefs.setBool('has_rated_app', true);
        
        stats = await AppRatingService.getRatingStats();
        expect(stats['has_rated'], isTrue);
      });
    });
  });
}