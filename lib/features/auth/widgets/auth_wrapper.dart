import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golo_app/config/app_config.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/navigation/app_router.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/services/seed_data_service.dart';

/// Widget que maneja la autenticación de la aplicación.
///
/// Este widget se encarga de redirigir al usuario a la pantalla de inicio de sesión
/// si no está autenticado, o al dashboard si ya ha iniciado sesión.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        // --- Caso 1: Aún verificando el estado de autenticación ---
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- Caso 2: El usuario YA ESTÁ autenticado (anónimo o permanente) ---
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final user = userSnapshot.data!;
          // Es un buen lugar para llamar al sembrado de datos.
          // Usamos un FutureBuilder para manejar el estado del sembrado.
          return FutureBuilder<void>(
            // El future es la operación de sembrado.
            future: context.read<SeedDataService>().seedDataForUser(user.uid),
            builder: (context, seedSnapshot) {
              // Mientras el sembrado está en proceso
              if (seedSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Preparando datos de ejemplo..."),
                      ],
                    ),
                  ),
                );
              }
              // Si el sembrado tuvo un error
              if (seedSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      "Error al preparar datos: ${seedSnapshot.error}",
                    ),
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(AppRouter.dashboard);
              });

              // Mientras ocurre la redirección (que es casi instantánea), mostramos un loader.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        // --- Caso 3: NO hay usuario. Iniciar sesión anónima ---
        final environment = AppConfig.instance.environment;
        if (environment == Environment.port) {
          return FutureBuilder<UserCredential>(
            future: FirebaseAuth.instance.signInAnonymously(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                debugPrint("Iniciando sesión de invitado...");
                return const Scaffold(
                  body: Center(child: Text("Iniciando sesión de invitado...")),
                );
              }
              if (authSnapshot.hasError) {
                // Manejo de errores de signInAnonymously
                String errorMessage = "Error al iniciar sesión anónima.";
                if (authSnapshot.error is FirebaseAuthException) {
                  final e = authSnapshot.error as FirebaseAuthException;
                  errorMessage =
                      "Error de Firebase: ${e.message} (Código: ${e.code})";
                }
                debugPrint(errorMessage);
                return Scaffold(body: Center(child: Text(errorMessage)));
              }
              // Cuando signInAnonymously termina, el StreamBuilder de arriba
              // detectará el cambio y reconstruirá, entrando en el "Caso 2".
              // No necesitamos navegar, solo mostrar un loader.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
