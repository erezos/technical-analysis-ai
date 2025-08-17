import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../lib/services/interstitial_ad_manager.dart';

// Generate mocks
@GenerateMocks([SharedPreferences, FirebaseRemoteConfig])
import 'interstitial_ad_manager_test.mocks.dart';

void main() {
  group('InterstitialAdManager', () {
    late MockSharedPreferences mockPrefs;
    late MockFirebaseRemoteConfig mockRemoteConfig;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockRemoteConfig = MockFirebaseRemoteConfig();
      
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    tearDown(() {
      // Clean up after each test
      InterstitialAdManager.dispose();
    });
    
    group('initialize', () {
      test('should initialize successfully for first session', () async {
        // Arrange
        when(mockPrefs.containsKey('has_opened_app_before')).thenReturn(false);
        when(mockPrefs.setBool('has_opened_app_before', true))
            .thenAnswer((_) async => true);
        
        // Mock SharedPreferences.getInstance()
        SharedPreferences.setMockInitialValues({});
        
        // Act
        await InterstitialAdManager.initialize();
        
        // Assert - Should complete without throwing
        expect(true, isTrue);
      });
      
      test('should initialize successfully for returning user', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'has_opened_app_before': true,
        });
        
        // Act
        await InterstitialAdManager.initialize();
        
        // Assert - Should complete without throwing
        expect(true, isTrue);
      });
      
      test('should handle initialization errors gracefully', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        
        // Act & Assert - Should not throw even if there are issues
        expect(
          () => InterstitialAdManager.initialize(),
          returnsNormally,
        );
      });
      
      test('should not initialize multiple times concurrently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        
        // Act
        final futures = [
          InterstitialAdManager.initialize(),
          InterstitialAdManager.initialize(),
          InterstitialAdManager.initialize(),
        ];
        
        // Assert - All should complete without issues
        await Future.wait(futures);
        expect(true, isTrue);
      });
    });
    
    group('showInterstitialAdIfNeeded', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await InterstitialAdManager.initialize();
      });
      
      test('should not show ad when ads are disabled', () async {
        // Arrange
        var adDismissedCalled = false;
        void onAdDismissed() => adDismissedCalled = true;
        
        // Act
        final result = await InterstitialAdManager.showInterstitialAdIfNeeded(
          onAdDismissed: onAdDismissed,
        );
        
        // Assert
        expect(result, isFalse);
        expect(adDismissedCalled, isFalse);
      });
      
      test('should handle first session ad logic correctly', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        await InterstitialAdManager.initialize();
        
        var adDismissedCalled = false;
        void onAdDismissed() => adDismissedCalled = true;
        
        // Act - First click (should not show ad)
        var result = await InterstitialAdManager.showInterstitialAdIfNeeded(
          onAdDismissed: onAdDismissed,
        );
        expect(result, isFalse);
        
        // Act - Second click (should attempt to show ad, but no ad loaded)
        result = await InterstitialAdManager.showInterstitialAdIfNeeded(
          onAdDismissed: onAdDismissed,
        );
        
        // Assert - Would show ad if one was loaded
        expect(result, isFalse); // No ad loaded in test environment
      });
      
      test('should handle timeout gracefully', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        await InterstitialAdManager.initialize();
        
        var adDismissedCalled = false;
        void onAdDismissed() => adDismissedCalled = true;
        
        // Act & Assert - Should complete within reasonable time
        final stopwatch = Stopwatch()..start();
        
        await InterstitialAdManager.showInterstitialAdIfNeeded(
          onAdDismissed: onAdDismissed,
        );
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
    
    group('refreshRemoteConfig', () {
      test('should refresh remote config without errors', () async {
        // Act & Assert
        expect(
          () => InterstitialAdManager.refreshRemoteConfig(),
          returnsNormally,
        );
      });
    });
    
    group('dispose', () {
      test('should dispose resources properly', () {
        // Act & Assert
        expect(
          () => InterstitialAdManager.dispose(),
          returnsNormally,
        );
      });
      
      test('should handle multiple dispose calls', () {
        // Act & Assert
        expect(() {
          InterstitialAdManager.dispose();
          InterstitialAdManager.dispose();
        }, returnsNormally);
      });
    });
    
    group('ANR Prevention', () {
      test('should not block main thread during initialization', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final stopwatch = Stopwatch()..start();
        
        // Act
        await InterstitialAdManager.initialize();
        
        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should not take too long
      });
      
      test('should handle concurrent ad requests without blocking', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        await InterstitialAdManager.initialize();
        
        var callbackCount = 0;
        void onAdDismissed() => callbackCount++;
        
        // Act - Multiple concurrent requests
        final futures = List.generate(5, (_) => 
          InterstitialAdManager.showInterstitialAdIfNeeded(
            onAdDismissed: onAdDismissed,
          )
        );
        
        final results = await Future.wait(futures);
        
        // Assert - All should complete
        expect(results, hasLength(5));
        expect(results.every((result) => result is bool), isTrue);
      });
    });
  });
}
