import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../lib/utils/anr_prevention.dart';
import '../../lib/services/anr_monitoring_service.dart';

void main() {
  group('ANR Prevention Performance Benchmarks', () {
    
    setUp(() async {
      await ANRMonitoringService.initialize();
    });
    
    tearDown(() {
      ANRMonitoringService.dispose();
    });
    
    group('Timeout Performance', () {
      test('executeWithTimeout should have minimal overhead for fast operations', () async {
        // Arrange
        const iterations = 1000;
        final stopwatch = Stopwatch();
        
        // Measure without timeout
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await Future.value(i);
        }
        stopwatch.stop();
        final baselineTime = stopwatch.elapsedMicroseconds;
        
        // Measure with timeout
        stopwatch.reset();
        stopwatch.start();
        for (int i = 0; i < iterations; i++) {
          await ANRPrevention.executeWithTimeout(
            Future.value(i),
            timeout: const Duration(seconds: 1),
          );
        }
        stopwatch.stop();
        final timeoutTime = stopwatch.elapsedMicroseconds;
        
        // Assert - Overhead should be less than 50%
        final overhead = (timeoutTime - baselineTime) / baselineTime;
        expect(overhead, lessThan(0.5));
        
        print('Baseline: ${baselineTime}μs, With timeout: ${timeoutTime}μs, Overhead: ${(overhead * 100).toStringAsFixed(1)}%');
      });
      
      test('timeout should trigger within acceptable margin', () async {
        // Arrange
        const timeoutDuration = Duration(milliseconds: 100);
        final stopwatch = Stopwatch();
        
        // Act
        stopwatch.start();
        try {
          await ANRPrevention.executeWithTimeout(
            Future.delayed(const Duration(seconds: 1)),
            timeout: timeoutDuration,
          );
          fail('Should have timed out');
        } on TimeoutException {
          stopwatch.stop();
        }
        
        // Assert - Should timeout within 20% margin
        final actualTimeout = stopwatch.elapsedMilliseconds;
        final expectedTimeout = timeoutDuration.inMilliseconds;
        final margin = (actualTimeout - expectedTimeout).abs() / expectedTimeout;
        
        expect(margin, lessThan(0.2));
        print('Expected: ${expectedTimeout}ms, Actual: ${actualTimeout}ms, Margin: ${(margin * 100).toStringAsFixed(1)}%');
      });
    });
    
    group('Isolate Performance', () {
      test('isolate execution should be efficient for CPU-intensive tasks', () async {
        // Arrange
        int heavyComputation(dynamic input) {
          var result = 0;
          for (int i = 0; i < 1000000; i++) {
            result += (i * i) % 1000;
          }
          return result;
        }
        
        final stopwatch = Stopwatch();
        
        // Measure main thread execution
        stopwatch.start();
        final mainThreadResult = heavyComputation(null);
        stopwatch.stop();
        final mainThreadTime = stopwatch.elapsedMilliseconds;
        
        // Measure isolate execution
        stopwatch.reset();
        stopwatch.start();
        final isolateResult = await ANRPrevention.executeInIsolate(
          heavyComputation,
          message: null,
        );
        stopwatch.stop();
        final isolateTime = stopwatch.elapsedMilliseconds;
        
        // Assert
        expect(isolateResult, equals(mainThreadResult));
        // Isolate should not be more than 3x slower (accounting for overhead)
        expect(isolateTime, lessThan(mainThreadTime * 3));
        
        print('Main thread: ${mainThreadTime}ms, Isolate: ${isolateTime}ms, Ratio: ${(isolateTime / mainThreadTime).toStringAsFixed(2)}x');
      });
    });
    
    group('Chunk Processing Performance', () {
      test('chunk processing should scale linearly', () async {
        // Test different list sizes
        final sizes = [100, 500, 1000, 5000];
        final times = <int, int>{};
        
        for (final size in sizes) {
          final items = List.generate(size, (index) => index);
          final stopwatch = Stopwatch()..start();
          
          await ANRPrevention.processListInChunks(
            items,
            (item) => item * 2,
            chunkSize: 50,
          );
          
          stopwatch.stop();
          times[size] = stopwatch.elapsedMilliseconds;
        }
        
        // Assert roughly linear scaling
        final ratio1000to100 = times[1000]! / times[100]!;
        final ratio5000to500 = times[5000]! / times[500]!;
        
        // Should be roughly 10x (linear scaling)
        expect(ratio1000to100, greaterThan(5));
        expect(ratio1000to100, lessThan(20));
        expect(ratio5000to500, greaterThan(5));
        expect(ratio5000to500, lessThan(20));
        
        print('Processing times: ${times.entries.map((e) => '${e.key}: ${e.value}ms').join(', ')}');
      });
      
      test('optimal chunk size should minimize total time', () async {
        // Test different chunk sizes
        const listSize = 1000;
        final items = List.generate(listSize, (index) => index);
        final chunkSizes = [10, 25, 50, 100, 200];
        final times = <int, int>{};
        
        for (final chunkSize in chunkSizes) {
          final stopwatch = Stopwatch()..start();
          
          await ANRPrevention.processListInChunks(
            items,
            (item) => item * item,
            chunkSize: chunkSize,
          );
          
          stopwatch.stop();
          times[chunkSize] = stopwatch.elapsedMilliseconds;
        }
        
        // Find optimal chunk size (should be somewhere in the middle)
        final optimalChunkSize = times.entries
            .reduce((a, b) => a.value < b.value ? a : b)
            .key;
        
        expect(optimalChunkSize, greaterThan(10));
        expect(optimalChunkSize, lessThan(200));
        
        print('Chunk size performance: ${times.entries.map((e) => '${e.key}: ${e.value}ms').join(', ')}');
        print('Optimal chunk size: $optimalChunkSize');
      });
    });
    
    group('Memory Usage', () {
      test('ANR prevention should not cause memory leaks', () async {
        // This is a simplified memory test
        // In a real scenario, you'd use more sophisticated memory monitoring
        
        final initialStats = ANRMonitoringService.getPerformanceStats();
        
        // Perform many operations
        for (int i = 0; i < 100; i++) {
          await ANRPrevention.executeWithTimeout(
            Future.delayed(const Duration(milliseconds: 1)),
            timeout: const Duration(seconds: 1),
          );
          
          await ANRPrevention.yieldToMainThread();
        }
        
        final finalStats = ANRMonitoringService.getPerformanceStats();
        
        // Assert monitoring is still working
        expect(finalStats['is_monitoring'], isTrue);
        
        // In a real test, you'd check actual memory usage here
        print('Initial stats: $initialStats');
        print('Final stats: $finalStats');
      });
    });
    
    group('Concurrent Operations', () {
      test('concurrent timeout operations should not interfere', () async {
        // Arrange
        const concurrentCount = 10;
        final stopwatch = Stopwatch()..start();
        
        // Act - Run multiple timeout operations concurrently
        final futures = List.generate(concurrentCount, (index) =>
          ANRPrevention.executeWithTimeout(
            Future.delayed(Duration(milliseconds: 50 + (index * 10))),
            timeout: const Duration(seconds: 1),
          )
        );
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert - Should complete in roughly the time of the longest operation
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        print('Concurrent operations completed in: ${stopwatch.elapsedMilliseconds}ms');
      });
      
      test('mixed operation types should not block each other', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act - Mix of different operation types
        final futures = [
          ANRPrevention.executeWithTimeout(
            Future.delayed(const Duration(milliseconds: 100)),
            timeout: const Duration(seconds: 1),
          ),
          ANRPrevention.executeInIsolate(
            (dynamic input) {
              var result = 0;
              for (int i = 0; i < 100000; i++) {
                result += i;
              }
              return result;
            },
            message: null,
          ),
          ANRPrevention.processListInChunks(
            List.generate(500, (index) => index),
            (item) => item * 2,
            chunkSize: 25,
          ),
        ];
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert - Should complete efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        print('Mixed operations completed in: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
    
    group('Real-world Scenarios', () {
      test('simulated app startup should not exceed ANR threshold', () async {
        // Simulate app startup operations
        final stopwatch = Stopwatch()..start();
        
        // Simulate multiple initialization tasks
        await Future.wait([
          ANRPrevention.executeWithTimeout(
            _simulateServiceInitialization('AuthService'),
            timeout: const Duration(seconds: 5),
          ),
          ANRPrevention.executeWithTimeout(
            _simulateServiceInitialization('DatabaseService'),
            timeout: const Duration(seconds: 5),
          ),
          ANRPrevention.executeWithTimeout(
            _simulateServiceInitialization('NetworkService'),
            timeout: const Duration(seconds: 5),
          ),
        ]);
        
        stopwatch.stop();
        
        // Assert - Should complete well under ANR threshold (5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        print('Simulated app startup: ${stopwatch.elapsedMilliseconds}ms');
      });
      
      test('simulated data processing should remain responsive', () async {
        // Simulate processing large dataset
        final largeDataset = List.generate(10000, (index) => {
          'id': index,
          'value': Random().nextDouble() * 1000,
          'category': 'category_${index % 10}',
        });
        
        final stopwatch = Stopwatch()..start();
        
        // Process in chunks to prevent ANR
        final processed = await ANRPrevention.processListInChunks(
          largeDataset,
          (item) => {
            ...item,
            'processed': true,
            'doubled_value': (item['value'] as double) * 2,
          },
          chunkSize: 100,
        );
        
        stopwatch.stop();
        
        // Assert
        expect(processed, hasLength(10000));
        expect(processed.first['processed'], isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        
        print('Large dataset processing: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}

// Helper functions
Future<String> _simulateServiceInitialization(String serviceName) async {
  // Simulate varying initialization times
  final delay = Duration(milliseconds: 100 + Random().nextInt(200));
  await Future.delayed(delay);
  return '$serviceName initialized';
}
