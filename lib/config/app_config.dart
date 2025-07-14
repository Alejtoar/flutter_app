
enum Environment { dev, prod }

class AppConfig {
  final Environment environment;
  final String appTitle;
 

  const AppConfig({
    required this.environment,
    required this.appTitle,
  
  });

  // Podríamos tener una instancia estática para accederla fácilmente
  static late AppConfig instance;
}