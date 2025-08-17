import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../lib/main.dart' as app;
import '../../lib/utils/anr_prevention.dart';
import '../../lib/services/anr_monitoring_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('ANR Prevention Integration Tests', () {
    
    testWidgets('App should start without ANR conditions', (tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Assert
      stopwatch.stop();
      expect(stopwatch.elapsedSeconds, lessThan(15)); // Should start within 15 seconds
      
      // Verify main screen elements are present
      expect(find.byType(Scaffold), findsWidgets);
    });
    
    testWidgets('Heavy operations should not block UI', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: HeavyOperationTestWidget(),
      ));
      
      // Act - Trigger heavy operation
      await tester.tap(find.byKey(const Key('heavy_operation_button')));
      await tester.pump(); // Start the operation
      
      // Assert - UI should remain responsive
      await tester.tap(find.byKey(const Key('responsive_button')));
      await tester.pump();
      
      expect(find.text('UI Responsive'), findsOneWidget);
      
      // Wait for heavy operation to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Heavy Operation Complete'), findsOneWidget);
    });
    
    testWidgets('Multiple concurrent operations should not cause ANR', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: ConcurrentOperationsTestWidget(),
      ));
      
      // Act - Start multiple operations
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('operation_button_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      
      // Assert - UI should remain responsive
      await tester.tap(find.byKey(const Key('check_responsive_button')));
      await tester.pump();
      
      expect(find.text('Still Responsive'), findsOneWidget);
      
      // Wait for all operations to complete
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
    
    testWidgets('Large list processing should not block UI', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: LargeListTestWidget(),
      ));
      
      // Act - Process large list
      await tester.tap(find.byKey(const Key('process_list_button')));
      await tester.pump();
      
      // Assert - Should be able to scroll while processing
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pump();
      
      // Wait for processing to complete
      await tester.pumpAndSettle(const Duration(seconds: 8));
      expect(find.text('Processing Complete'), findsOneWidget);
    });
    
    testWidgets('ANR monitoring should detect slow operations', (tester) async {
      // Arrange
      await ANRMonitoringService.initialize();
      
      await tester.pumpWidget(MaterialApp(
        home: SlowOperationTestWidget(),
      ));
      
      // Act - Trigger intentionally slow operation
      await tester.tap(find.byKey(const Key('slow_operation_button')));
      await tester.pump();
      
      // Wait for operation and monitoring
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Assert - Check that monitoring detected the slow operation
      final stats = ANRMonitoringService.getPerformanceStats();
      expect(stats['is_monitoring'], isTrue);
      
      ANRMonitoringService.dispose();
    });
    
    testWidgets('Timeout protection should prevent indefinite blocking', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: TimeoutTestWidget(),
      ));
      
      final stopwatch = Stopwatch()..start();
      
      // Act - Trigger operation with timeout
      await tester.tap(find.byKey(const Key('timeout_operation_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Assert - Should complete within timeout period
      stopwatch.stop();
      expect(stopwatch.elapsedSeconds, lessThan(8));
      expect(find.text('Operation Timed Out'), findsOneWidget);
    });
  });
}

// Test helper widgets
class HeavyOperationTestWidget extends StatefulWidget {
  @override
  _HeavyOperationTestWidgetState createState() => _HeavyOperationTestWidgetState();
}

class _HeavyOperationTestWidgetState extends State<HeavyOperationTestWidget> {
  bool _operationComplete = false;
  bool _uiResponsive = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('heavy_operation_button'),
            onPressed: _startHeavyOperation,
            child: const Text('Start Heavy Operation'),
          ),
          ElevatedButton(
            key: const Key('responsive_button'),
            onPressed: () => setState(() => _uiResponsive = true),
            child: const Text('Test Responsiveness'),
          ),
          if (_uiResponsive) const Text('UI Responsive'),
          if (_operationComplete) const Text('Heavy Operation Complete'),
        ],
      ),
    );
  }
  
  void _startHeavyOperation() async {
    // Use ANR prevention for heavy computation
    await ANRPrevention.executeInIsolate(
      (dynamic input) {
        // Simulate heavy computation
        var result = 0;
        for (int i = 0; i < 10000000; i++) {
          result += i;
        }
        return result;
      },
      message: null,
      debugName: 'heavy_computation_test',
    );
    
    setState(() => _operationComplete = true);
  }
}

class ConcurrentOperationsTestWidget extends StatefulWidget {
  @override
  _ConcurrentOperationsTestWidgetState createState() => _ConcurrentOperationsTestWidgetState();
}

class _ConcurrentOperationsTestWidgetState extends State<ConcurrentOperationsTestWidget> {
  bool _stillResponsive = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ...List.generate(5, (index) => ElevatedButton(
            key: Key('operation_button_$index'),
            onPressed: () => _startOperation(index),
            child: Text('Operation $index'),
          )),
          ElevatedButton(
            key: const Key('check_responsive_button'),
            onPressed: () => setState(() => _stillResponsive = true),
            child: const Text('Check Responsive'),
          ),
          if (_stillResponsive) const Text('Still Responsive'),
        ],
      ),
    );
  }
  
  void _startOperation(int index) async {
    await ANRPrevention.executeWithTimeout(
      Future.delayed(Duration(seconds: 2 + index)),
      timeout: const Duration(seconds: 10),
      debugName: 'concurrent_operation_$index',
    );
  }
}

class LargeListTestWidget extends StatefulWidget {
  @override
  _LargeListTestWidgetState createState() => _LargeListTestWidgetState();
}

class _LargeListTestWidgetState extends State<LargeListTestWidget> {
  List<String> _items = [];
  bool _processing = false;
  bool _processingComplete = false;
  
  @override
  void initState() {
    super.initState();
    _items = List.generate(1000, (index) => 'Item $index');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('process_list_button'),
            onPressed: _processing ? null : _processLargeList,
            child: const Text('Process Large List'),
          ),
          if (_processingComplete) const Text('Processing Complete'),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_items[index]));
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _processLargeList() async {
    setState(() => _processing = true);
    
    // Process list in chunks to prevent ANR
    await ANRPrevention.processListInChunks(
      _items,
      (item) => item.toUpperCase(),
      chunkSize: 50,
      debugName: 'large_list_processing',
    );
    
    setState(() {
      _processing = false;
      _processingComplete = true;
    });
  }
}

class SlowOperationTestWidget extends StatefulWidget {
  @override
  _SlowOperationTestWidgetState createState() => _SlowOperationTestWidgetState();
}

class _SlowOperationTestWidgetState extends State<SlowOperationTestWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('slow_operation_button'),
            onPressed: _slowOperation,
            child: const Text('Slow Operation'),
          ).withANRMonitoring('slow_operation_test'),
        ],
      ),
    );
  }
  
  void _slowOperation() {
    // Intentionally slow operation for monitoring test
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < 200) {
      // Busy wait to simulate slow operation
    }
  }
}

class TimeoutTestWidget extends StatefulWidget {
  @override
  _TimeoutTestWidgetState createState() => _TimeoutTestWidgetState();
}

class _TimeoutTestWidgetState extends State<TimeoutTestWidget> {
  bool _timedOut = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('timeout_operation_button'),
            onPressed: _timeoutOperation,
            child: const Text('Timeout Operation'),
          ),
          if (_timedOut) const Text('Operation Timed Out'),
        ],
      ),
    );
  }
  
  void _timeoutOperation() async {
    try {
      await ANRPrevention.executeWithTimeout(
        Future.delayed(const Duration(seconds: 10)), // Long operation
        timeout: const Duration(seconds: 3), // Short timeout
        debugName: 'timeout_test',
      );
    } on TimeoutException {
      setState(() => _timedOut = true);
    }
  }
}
