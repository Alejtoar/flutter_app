import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:golo_app/navigation/app_routes.dart'; // Para la navegación

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa correo y contraseña.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navega a la pantalla principal si el login es exitoso
      // No es necesario verificar `mounted` aquí si la navegación saca esta pantalla del árbol.
      if (mounted) { // Buena práctica de todos modos
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard, // O tu ruta de inicio principal
          (route) => false, // Elimina todas las rutas anteriores (la de login)
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.code == 'user-not-found') {
            _errorMessage = 'No se encontró un usuario con ese correo.';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'Contraseña incorrecta.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = 'El formato del correo electrónico no es válido.';
          } else {
            _errorMessage = 'Error de autenticación: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ocurrió un error inesperado: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Para evitar overflow en pantallas pequeñas
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Limita el ancho en web/desktop
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aquí podrías poner un logo
                Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16)
                        ),
                        child: const Text('Ingresar'),
                      ),
                // Aquí podrías añadir "Olvidé mi contraseña" o "Registrarse"
              ],
            ),
          ),
        ),
      ),
    );
  }
}