import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/navigation/navigation_state.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/app_theme.dart';
import 'viewmodels/plato_viewmodel.dart';
import 'viewmodels/evento_viewmodel.dart';
import 'services/plato_service.dart';
import 'services/evento_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlatoService>(
          create: (_) => PlatoService(),
        ),
        Provider<EventoService>(
          create: (_) => EventoService(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationState()),
        ChangeNotifierProxyProvider<PlatoService, PlatoViewModel>(
          create: (context) => PlatoViewModel(context.read<PlatoService>()),
          update: (context, service, previous) => 
              previous ?? PlatoViewModel(service),
        ),
        ChangeNotifierProxyProvider<EventoService, EventoViewModel>(
          create: (context) => EventoViewModel(context.read<EventoService>()),
          update: (context, service, previous) =>
              previous ?? EventoViewModel(service),
        ),
      ],
      child: MaterialApp(
        title: 'Golo App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}