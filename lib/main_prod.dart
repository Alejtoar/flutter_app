import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/app_runner.dart'; // Llama a la misma lógica común
import 'package:golo_app/config/app_config.dart';
import 'package:golo_app/firebase_options_prod.dart'; // Opciones de Firebase para PROD
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // 1. Configurar el entorno
  AppConfig.instance = const AppConfig(
    environment: Environment.prod,
    appTitle: "Golo App",
  );

  // 2. Inicializar servicios base
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  // Usar las opciones de PROD
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Correr la app
  runGoloApp();
}