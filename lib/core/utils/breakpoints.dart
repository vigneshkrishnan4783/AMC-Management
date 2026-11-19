import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobileMax = 650;
  static const double tabletMax = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletMax;

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1400) return 1350;
    return width;
  }

  static int gridColumns(BuildContext context, {int min = 1, int max = 4}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return min;
    if (width < 900) return 2;
    if (width < 1300) return 3;
    return max;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (Breakpoints.isTablet(context) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
