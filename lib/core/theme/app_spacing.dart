/// FlowSpace Spacing Tokens — 4px base grid
abstract class AppSpacing {
  static const double sp2 = 2.0;
  static const double sp4 = 4.0;
  static const double sp6 = 6.0;
  static const double sp8 = 8.0;
  static const double sp10 = 10.0;
  static const double sp12 = 12.0;
  static const double sp14 = 14.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp28 = 28.0;
  static const double sp32 = 32.0;
  static const double sp40 = 40.0;
  static const double sp48 = 48.0;
  static const double sp56 = 56.0;
  static const double sp64 = 64.0;
  static const double sp66 = 66.0;
  static const double sp80 = 80.0;
  static const double sp96 = 96.0;

  // Layout
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsed = 64.0;
  static const double topbarHeight = 56.0;
  static const double contentMaxWidth = 900.0;
  static const double pageMaxWidth = 1200.0;

  // Breakpoints
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 1024.0;
}

/// FlowSpace Border Radius Tokens
abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;
}

/// FlowSpace Animation Tokens
abstract class AppAnimations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration page = Duration(milliseconds: 280);
}

/// FlowSpace Elevation / Shadow Tokens
abstract class AppElevation {
  static const double none = 0;
  static const double card = 1;
  static const double dropdown = 4;
  static const double modal = 16;
}
