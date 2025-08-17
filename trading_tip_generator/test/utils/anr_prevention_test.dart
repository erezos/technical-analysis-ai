import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../lib/utils/anr_prevention.dart';

void main() {
  group('ANRPrevention', () {
    
    group('executeWithTimeout', () {
      test('should complete operation within timeout', () async {
        // Arrange
        final operation = Future.delayed(
          const Duration(milliseconds: 100),
          () => 'success',
        );
        
        // Act
        final result = await ANRPrevention.executeWithTimeout(
          operation,
          timeout: const Duration(seconds: 1),
          debugName: 'test_operation',
        );
        
        // Assert
        expect(result, equals('success'));
      });
      
      test('should throw TimeoutException when operation exceeds timeout', () async {
        // Arrange
        final operation = Future.delayed(
          const Duration(seconds: 2),
          () => 'should not complete',
        );
        
        // Act & Assert
        expect(
          () => ANRPrevention.executeWithTimeout(
            operation,
            timeout: const Duration(milliseconds: 100),
            debugName: 'timeout_test',
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
      
      test('should propagate original exception when operation fails', () async {
        // Arrange
        final operation = Future<String>.error(Exception('Test error'));
        
        // Act & Assert
        expect(
          () => ANRPrevention.executeWithTimeout(
            operation,
            timeout: const Duration(seconds: 1),
            debugName: 'error_test',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('executeInIsolate', () {
      test('should execute computation in isolate and return result', () async {
        // Arrange
        String heavyComputation(dynamic input) {
          // Simulate heavy computation
          var result = '';
          for (int i = 0; i < 1000; i++) {
            result += i.toString();
          }
          return 'computed: ${result.length}';
        }
        
        // Act
        final result = await ANRPrevention.executeInIsolate(
          heavyComputation,
          debugName: 'heavy_computation_test',
          message: null,
        );
        
        // Assert
        expect(result, startsWith('computed:'));
        expect(result.length, greaterThan(10));
      });
      
      test('should handle isolate computation errors', () async {
        // Arrange
        String errorComputation(dynamic input) {
          throw Exception('Computation failed');
        }
        
        // Act & Assert
        expect(
          () => ANRPrevention.executeInIsolate(
            errorComputation,
            debugName: 'error_computation_test',
            message: null,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('processListInChunks', () {
      test('should process small list without chunking', () async {
        // Arrange
        final items = [1, 2, 3, 4, 5];
        String processor(int item) => 'item_$item';
        
        // Act
        final result = await ANRPrevention.processListInChunks(
          items,
          processor,
          chunkSize: 10,
          debugName: 'small_list_test',
        );
        
        // Assert
        expect(result, hasLength(5));
        expect(result, equals(['item_1', 'item_2', 'item_3', 'item_4', 'item_5']));
      });
      
      test('should process large list in chunks', () async {
        // Arrange
        final items = List.generate(100, (index) => index);
        String processor(int item) => 'processed_$item';
        
        // Act
        final result = await ANRPrevention.processListInChunks(
          items,
          processor,
          chunkSize: 25,
          debugName: 'large_list_test',
        );
        
        // Assert
        expect(result, hasLength(100));
        expect(result.first, equals('processed_0'));
        expect(result.last, equals('processed_99'));
      });
      
      test('should handle empty list', () async {
        // Arrange
        final items = <int>[];
        String processor(int item) => 'item_$item';
        
        // Act
        final result = await ANRPrevention.processListInChunks(
          items,
          processor,
          chunkSize: 10,
          debugName: 'empty_list_test',
        );
        
        // Assert
        expect(result, isEmpty);
      });
    });
    
    group('yieldToMainThread', () {
      test('should complete without blocking', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        await ANRPrevention.yieldToMainThread();
        
        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });
    
    group('debounce', () {
      test('should debounce rapid calls', () async {
        // Arrange
        var callCount = 0;
        void operation() => callCount++;
        
        // Act
        ANRPrevention.debounce(operation, delay: const Duration(milliseconds: 100));
        ANRPrevention.debounce(operation, delay: const Duration(milliseconds: 100));
        ANRPrevention.debounce(operation, delay: const Duration(milliseconds: 100));
        
        // Wait for debounce to complete
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Assert
        expect(callCount, equals(1));
      });
      
      test('should allow calls after debounce period', () async {
        // Arrange
        var callCount = 0;
        void operation() => callCount++;
        
        // Act
        ANRPrevention.debounce(operation, delay: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 100));
        
        ANRPrevention.debounce(operation, delay: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert
        expect(callCount, equals(2));
      });
    });
  });
  
  group('ANRPreventionFuture Extension', () {
    test('should add timeout to future', () async {
      // Arrange
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => 'success',
      );
      
      // Act
      final result = await future.withANRTimeout(
        timeout: const Duration(seconds: 1),
        debugName: 'extension_test',
      );
      
      // Assert
      expect(result, equals('success'));
    });
    
    test('should timeout future with extension', () async {
      // Arrange
      final future = Future.delayed(
        const Duration(seconds: 2),
        () => 'should not complete',
      );
      
      // Act & Assert
      expect(
        () => future.withANRTimeout(
          timeout: const Duration(milliseconds: 100),
          debugName: 'extension_timeout_test',
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
