/// Shared responsive breakpoints for mobile, tablet and desktop layouts.
/// Keep breakpoint decisions in one place instead of scattering magic numbers.
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool useNavigationRail(double width) => width >= mobile;
  static bool useExtendedNavigationRail(double width) => width >= desktop;
}
