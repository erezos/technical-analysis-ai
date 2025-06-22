import 'package:flutter/material.dart';

/// Responsive layout widget that adapts to different screen sizes
/// Specifically designed to fix iPhone 13 mini layout issues (Apple Guideline 4.0)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 1024,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile;
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive padding that scales based on screen size
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.mobilePadding = 16.0,
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double padding = mobilePadding;
        
        if (constraints.maxWidth >= 600 && constraints.maxWidth < 1024) {
          padding = tabletPadding ?? mobilePadding * 1.5;
        } else if (constraints.maxWidth >= 1024) {
          padding = desktopPadding ?? mobilePadding * 2;
        }
        
        return Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        );
      },
    );
  }
}

/// Responsive text that scales appropriately for different screen sizes
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double mobileScale;
  final double? tabletScale;
  final double? desktopScale;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.mobileScale = 1.0,
    this.tabletScale,
    this.desktopScale,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double scale = mobileScale;
        
        if (constraints.maxWidth >= 600 && constraints.maxWidth < 1024) {
          scale = tabletScale ?? mobileScale * 1.1;
        } else if (constraints.maxWidth >= 1024) {
          scale = desktopScale ?? mobileScale * 1.2;
        }
        
        final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
        final scaledStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * scale,
        );
        
        return Text(
          text,
          style: scaledStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = mobileColumns;
        
        if (constraints.maxWidth >= 600 && constraints.maxWidth < 1024) {
          columns = tabletColumns ?? mobileColumns * 2;
        } else if (constraints.maxWidth >= 1024) {
          columns = desktopColumns ?? mobileColumns * 3;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Screen size helper class
class ScreenSize {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  static bool isSmallMobile(BuildContext context) {
    // iPhone 13 mini and similar small devices
    return MediaQuery.of(context).size.width <= 375;
  }
  
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Safe area wrapper that ensures content is visible on all devices
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
} 