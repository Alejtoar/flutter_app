import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// Importa tus archivos main usando alias para evitar conflictos de nombres
import 'package:golo_app/main_dev.dart' as dev_app;
import 'package:golo_app/main_prod.dart' as prod_app;

// La función main de este archivo es la que el motor web de Flutter buscará.
void main() {
  // `usePathUrlStrategy` elimina el /#/ de las URLs, es una buena práctica.
  usePathUrlStrategy();

  // Leer la variable de entorno 'FLUTTER_APP_FLAVOR' que pasaremos en el comando de build.
  const String flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

  print('Web entrypoint: Detected flavor "$flavor"');

  // Seleccionar qué main() ejecutar basándose en el flavor.
  switch (flavor) {
    case 'prod':
      prod_app.main();
      break;
    case 'dev':
    default:
      dev_app.main();
      break;
  }
}