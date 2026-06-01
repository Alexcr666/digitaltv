
abstract class AppConfig {
  // Cargados desde --dart-define en build
  static const superAdminEmail =
      String.fromEnvironment('SUPER_ADMIN_EMAIL', defaultValue: '');
  static const superAdminPassword =
      String.fromEnvironment('SUPER_ADMIN_PASS', defaultValue: '');
}