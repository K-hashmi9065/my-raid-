class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'https://dummyjson.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String tasksKey = 'cached_tasks';
  static const String onboardingKey = 'onboarding_done';

  // Pagination
  static const int pageSize = 10;

  // Task Status
  static const String statusTodo = 'todo';
  static const String statusInProgress = 'in-progress';
  static const String statusDone = 'done';

  List<String> get taskStatuses => [statusTodo, statusInProgress, statusDone];
}
