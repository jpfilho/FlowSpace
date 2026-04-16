/// FlowSpace Route Constants
abstract class AppRoutes {
  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';

  // App (authenticated)
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String pages = '/pages';
  static const String pageDetail = '/pages/:id';
  static const String calendar = '/calendar';
  static const String gtd = '/gtd';
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String members = '/members';
  static const String databases = '/databases';
  static const String invite = '/invite';
}
