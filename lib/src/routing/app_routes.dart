/// Centralized route name constants for named Navigator routes.
///
/// Use these constants with `Navigator.pushNamed(context, AppRoutes.onboarding)`
/// instead of inline strings to prevent typos and ease refactoring.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String addPart = '/inventory/add-part';
  static const String createTechnician = '/team/create-technician';
  static const String profile = '/profile';
  /// Debug-only component gallery.
  static const String uiShowcase = '/debug/ui-showcase';
}
