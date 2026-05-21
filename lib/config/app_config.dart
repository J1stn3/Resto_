class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const double taxRate = 0.10;
  static const String tokenKey = 'pos_token';
  static const String userKey = 'pos_user';
}
