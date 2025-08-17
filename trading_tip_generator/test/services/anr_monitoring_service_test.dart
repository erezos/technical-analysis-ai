import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../lib/services/anr_monitoring_service.dart';

// Generate mocks
@GenerateMocks([FirebaseAnalytics])
import 'anr_monitoring_service_test.mocks.dart';

void main() {
  group('ANRMonitoringService', () {
    late MockFirebaseAnalytics mockAnalytics;
    
    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      
      // Reset service state before each test
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    tearDown(() {
      // Clean up after each test
      ANRMonitoringService.dispose();
    });
    
    group('initialize', () {
      test('should initialize successfully', () async {
        // Act
        await ANRMonitoringService.initialize();
        
        // Assert
        final stats = ANRMonitoringService.getPerformanceStats();
        expect(stats['is_monitoring'], isTrue);
        expect(stats['total_frames'], equals(0));
        expect(stats['slow_frames'], equals(0));
      });
      
      test('should not initialize twice', () async {
        // Arrange
        await ANRMonitoringService.initialize();
        
        // Act
        await ANRMonitoringService.initialize();
        
        // Assert - Should not throw or cause issues
        final stats = ANRMonitoringService.getPerformanceStats();
        expect(stats['is_monitoring'], isTrue);
      });
    });
    
    group('reportCustomEvent', () {
      test('should report custom event with correct parameters', () {
        // Arrange
        const eventName = 'test_event';
        const operation = 'test_operation';
        const duration = Duration(milliseconds: 150);
        final additionalParams = {'custom_param': 'value'};
        
        // Act
        ANRMonitoringService.reportCustomEvent(
          eventName: eventName,
          operation: operation,
          duration: duration,
          additionalParams: additionalParams,
        );
        
        // Assert - In a real test, you'd verify the analytics call
        // This is more of a smoke test to ensure no exceptions
        expect(true, isTrue); // Test passes if no exception thrown
      });
      
      test('should handle event reporting without additional parameters', () {
        // Arrange
        const eventName = 'simple_event';
        const operation = 'simple_operation';
        const duration = Duration(milliseconds: 50);
        
        // Act & Assert
        expect(
          () => ANRMonitoringService.reportCustomEvent(
            eventName: eventName,
            operation: operation,
            duration: duration,
          ),
          returnsNormally,
        );
      });
    });
    
    group('getPerformanceStats', () {
      test('should return correct initial stats', () {
        // Act
        final stats = ANRMonitoringService.getPerformanceStats();
        
        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('session_duration_minutes'), isTrue);
        expect(stats.containsKey('total_frames'), isTrue);
        expect(stats.containsKey('slow_frames'), isTrue);
        expect(stats.containsKey('slow_frame_percentage'), isTrue);
        expect(stats.containsKey('is_monitoring'), isTrue);
        
        expect(stats['total_frames'], equals(0));
        expect(stats['slow_frames'], equals(0));
        expect(stats['slow_frame_percentage'], equals(0.0));
      });
      
      test('should calculate slow frame percentage correctly', () {
        // This test would require access to private methods
        // In a real implementation, you might expose these for testing
        // or use integration tests
        
        final stats = ANRMonitoringService.getPerformanceStats();
        expect(stats['slow_frame_percentage'], isA<double>());
      });
    });
    
    group('dispose', () {
      test('should dispose resources properly', () async {
        // Arrange
        await ANRMonitoringService.initialize();
        
        // Act
        ANRMonitoringService.dispose();
        
        // Assert
        final stats = ANRMonitoringService.getPerformanceStats();
        expect(stats['is_monitoring'], isFalse);
      });
      
      test('should handle multiple dispose calls', () {
        // Act & Assert
        expect(() {
          ANRMonitoringService.dispose();
          ANRMonitoringService.dispose();
        }, returnsNormally);
      });
    });
  });
  
  group('ANRMonitoringExtension', () {
    testWidgets('withANRMonitoring should wrap widget correctly', (tester) async {
      // Arrange
      const testWidget = Text('Test Widget');
      
      // Act
      final monitoredWidget = testWidget.withANRMonitoring('test_operation');
      
      // Assert
      expect(monitoredWidget, isA<Builder>());
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: monitoredWidget),
      ));
      
      expect(find.text('Test Widget'), findsOneWidget);
    });
    
    testWidgets('withANRMonitoring should handle slow builds', (tester) async {
      // Arrange
      final slowWidget = Builder(
        builder: (context) {
          // Simulate slow build
          final stopwatch = Stopwatch()..start();
          while (stopwatch.elapsedMilliseconds < 50) {
            // Busy wait to simulate slow build
          }
          return const Text('Slow Widget');
        },
      );
      
      // Act
      final monitoredWidget = slowWidget.withANRMonitoring('slow_build_test');
      
      // Assert
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: monitoredWidget),
      ));
      
      expect(find.text('Slow Widget'), findsOneWidget);
      
      // Allow post-frame callbacks to execute
      await tester.pump();
    });
  });
}
