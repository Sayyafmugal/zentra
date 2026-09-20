import 'package:flutter/widgets.dart';

/// Breakpoints for the app's Flutter Web deployment, which previously had
/// zero responsive handling (grids hardcoded to a 2-column layout at every
/// viewport width, including desktop).
abstract class Responsive {
  static const mobileMax = 600.0;
  static const tabletMax = 1024.0;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mobileMax;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= tabletMax;

  /// Picks a value by current breakpoint, falling back to [mobile] when a
  /// narrower size isn't provided.
  static T value<T>(BuildContext context, {required T mobile, T? tablet, T? desktop}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletMax) return desktop ?? tablet ?? mobile;
    if (width >= mobileMax) return tablet ?? mobile;
    return mobile;
  }

  /// Product grid column count by breakpoint.
  static int gridColumns(BuildContext context) => value(context, mobile: 2, tablet: 3, desktop: 4);

  /// Caps content width on wide viewports so it doesn't stretch edge to edge.
  static const contentMaxWidth = 1100.0;
}
