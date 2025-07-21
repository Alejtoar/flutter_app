
enum Environment { dev, prod, port }

class AppConfig {
  final Environment environment;
  final String appTitle;
  final bool isMultiUser;
 

  const AppConfig({
    required this.environment,
    required this.appTitle,
    this.isMultiUser = false,
  
  });

  // Podríamos tener una instancia estática para accederla fácilmente
  static late AppConfig instance;
}