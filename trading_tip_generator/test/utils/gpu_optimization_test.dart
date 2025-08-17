import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/gpu_optimization.dart';

void main() {
  group('GPUOptimization', () {
    
    testWidgets('optimizeForGPU should wrap widget with RepaintBoundary', (tester) async {
      // Arrange
      const testWidget = Text('Test Widget');
      
      // Act
      final optimizedWidget = GPUOptimization.optimizeForGPU(
        testWidget,
        debugName: 'test_widget',
      );
      
      // Assert
      expect(optimizedWidget, isA<RepaintBoundary>());
      
      await tester.pumpWidget(MaterialApp(home: optimizedWidget));
      expect(find.text('Test Widget'), findsOneWidget);
    });
    
    testWidgets('optimizedContainer should create container with RepaintBoundary', (tester) async {
      // Arrange
      const child = Text('Container Child');
      
      // Act
      final container = GPUOptimization.optimizedContainer(
        child: child,
        color: Colors.blue,
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(8),
      );
      
      // Assert
      expect(container, isA<RepaintBoundary>());
      
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: container)));
      expect(find.text('Container Child'), findsOneWidget);
    });
    
    testWidgets('optimizedImage should handle asset images', (tester) async {
      // Act
      final imageWidget = GPUOptimization.optimizedImage(
        imagePath: 'assets/test_image.png',
        width: 100,
        height: 100,
        isAsset: true,
      );
      
      // Assert
      expect(imageWidget, isA<RepaintBoundary>());
      
      // Note: We can't easily test actual image loading in unit tests
      // This would require integration tests with actual assets
    });
    
    testWidgets('optimizedListView should create ListView with RepaintBoundary', (tester) async {
      // Arrange
      Widget itemBuilder(BuildContext context, int index) {
        return ListTile(title: Text('Item $index'));
      }
      
      // Act
      final listView = GPUOptimization.optimizedListView(
        itemBuilder: itemBuilder,
        itemCount: 5,
        shrinkWrap: true,
      );
      
      // Assert
      expect(listView, isA<RepaintBoundary>());
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: listView),
      ));
      
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);
    });
    
    testWidgets('optimizedAnimatedBuilder should wrap with RepaintBoundary', (tester) async {
      // Arrange
      late AnimationController controller;
      late Animation<double> animation;
      
      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            controller = AnimationController(
              duration: const Duration(milliseconds: 300),
              vsync: const TestVSync(),
            );
            animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
            
            // Act
            final animatedWidget = GPUOptimization.optimizedAnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Opacity(
                  opacity: animation.value,
                  child: child,
                );
              },
              child: const Text('Animated Text'),
            );
            
            return Scaffold(body: animatedWidget);
          },
        ),
      ));
      
      // Assert
      expect(find.text('Animated Text'), findsOneWidget);
      
      // Cleanup
      controller.dispose();
    });
  });
  
  group('GPUOptimizationMixin', () {
    testWidgets('optimizeWidget should wrap with RepaintBoundary', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: TestWidgetWithMixin(),
      ));
      
      // Assert
      expect(find.text('Optimized Widget'), findsOneWidget);
    });
    
    testWidgets('buildOptimizedAnimation should create optimized animated widget', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: TestAnimatedWidgetWithMixin(),
      ));
      
      // Assert
      expect(find.text('Animated Content'), findsOneWidget);
    });
  });
  
  group('GPUOptimizationContext Extension', () {
    testWidgets('optimizedContainer extension should work', (tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            // Act
            final container = context.optimizedContainer(
              child: const Text('Extension Test'),
              color: Colors.red,
              width: 50,
              height: 50,
            );
            
            return Scaffold(body: container);
          },
        ),
      ));
      
      // Assert
      expect(find.text('Extension Test'), findsOneWidget);
    });
  });
}

// Test helper classes
class TestVSync implements TickerProvider {
  const TestVSync();
  
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

class TestWidgetWithMixin extends StatefulWidget {
  const TestWidgetWithMixin({Key? key}) : super(key: key);
  
  @override
  State<TestWidgetWithMixin> createState() => _TestWidgetWithMixinState();
}

class _TestWidgetWithMixinState extends State<TestWidgetWithMixin> 
    with GPUOptimizationMixin {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: optimizeWidget(
        const Text('Optimized Widget'),
        debugName: 'test_widget',
      ),
    );
  }
}

class TestAnimatedWidgetWithMixin extends StatefulWidget {
  const TestAnimatedWidgetWithMixin({Key? key}) : super(key: key);
  
  @override
  State<TestAnimatedWidgetWithMixin> createState() => _TestAnimatedWidgetWithMixinState();
}

class _TestAnimatedWidgetWithMixinState extends State<TestAnimatedWidgetWithMixin> 
    with GPUOptimizationMixin, TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildOptimizedAnimation(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: child,
          );
        },
        child: const Text('Animated Content'),
      ),
    );
  }
}
