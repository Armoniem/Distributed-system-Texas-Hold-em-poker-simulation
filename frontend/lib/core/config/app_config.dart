/// AppConfig reads compile-time --dart-define values for environment-specific config.
class AppConfig {
  static late String backendUrl;
  static late String environment;

  static void initialize() {
    backendUrl = const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8080',
    );
    environment = const String.fromEnvironment(
      'ENV',
      defaultValue: 'development',
    );
  }

  static bool get isDev => environment == 'development';
  static bool get isProd => environment == 'production';
}
