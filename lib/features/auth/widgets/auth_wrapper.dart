import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/navigation/app_routes.dart';

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
      builder: (context, snapshot) {
        // Muestra un indicador de carga mientras se verifica el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Si el usuario está autenticado, redirigir al dashboard
        if (snapshot.hasData) {
          // Usar addPostFrameCallback para evitar problemas con el contexto durante la navegación
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si no hay usuario autenticado, mostrar la pantalla de inicio de sesión
        return const LoginPage();
      },
    );
  }
}