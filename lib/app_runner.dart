import 'package:flutter/material.dart';
import 'package:golo_app/config/app_config.dart';
import 'package:golo_app/navigation/app_router.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/repositories/plato_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository_impl.dart';
import 'package:golo_app/repositories/insumo_requerido_repository_impl.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/repositories/insumo_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_repository_impl.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository_impl.dart';
import 'package:golo_app/repositories/proveedor_repository_impl.dart';
import 'package:golo_app/services/excel_export_service_sync.dart';
import 'package:golo_app/services/seed_data_service.dart';
//import 'package:golo_app/services/excel_export_service.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/eventos/controllers/buscador_eventos_controller.dart';
import 'repositories/evento_repository_impl.dart';
import 'repositories/plato_evento_repository_impl.dart';
import 'repositories/insumo_evento_repository_impl.dart';
import 'repositories/intermedio_evento_repository_impl.dart';

void runGoloApp() async {
  final db = FirebaseFirestore.instance;

  // --- Crear Instancias de Repositorios (usando la misma instancia 'db') ---
  // (Para mejor legibilidad y reutilización)
  final eventoRepo = EventoFirestoreRepository(db);
  final platoEventoRepo = PlatoEventoFirestoreRepository(db);
  final intermedioEventoRepo = IntermedioEventoFirestoreRepository(db);
  final insumoEventoRepo = InsumoEventoFirestoreRepository(db);
  final platoRepo = PlatoFirestoreRepository(db);
  final intermedioRepo = IntermedioFirestoreRepository(db);
  final insumoRepo = InsumoFirestoreRepository(db);
  final insumoRequeridoRepo = InsumoRequeridoFirestoreRepository(db);
  final intermedioRequeridoRepo = IntermedioRequeridoFirestoreRepository(db);
  final insumoUtilizadoRepo = InsumoUtilizadoFirestoreRepository(db);
  final proveedorRepo = ProveedorFirestoreRepository(db);
  final excelExportService = ExcelExportServiceSync();
  final seedDataService = SeedDataService(db);
  

  final shoppingListService = ShoppingListService(
    eventoRepo: eventoRepo,
    platoEventoRepo: platoEventoRepo,
    intermedioEventoRepo: intermedioEventoRepo,
    insumoEventoRepo: insumoEventoRepo,
    platoRepo: platoRepo,
    intermedioRepo: intermedioRepo,
    insumoRepo: insumoRepo,
    insumoRequeridoRepo: insumoRequeridoRepo,
    intermedioRequeridoRepo: intermedioRequeridoRepo,
    insumoUtilizadoRepo: insumoUtilizadoRepo,
    proveedorRepo: proveedorRepo,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => BuscadorEventosController(
                eventoRepo,
                platoEventoRepo,
                insumoEventoRepo,
                intermedioEventoRepo,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => InsumoController(insumoRepo, proveedorRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ProveedorController(proveedorRepo),
        ),
        ChangeNotifierProvider(
          create:
              (_) => IntermedioController(intermedioRepo, insumoUtilizadoRepo),
        ),
        ChangeNotifierProvider(
          create:
              (_) => PlatoController(
                platoRepo,
                intermedioRequeridoRepo,
                insumoRequeridoRepo,
              ),
        ),

        Provider<EventoRepository>(create: (_) => eventoRepo),
        Provider<ShoppingListService>(create: (_) => shoppingListService),
        Provider<ExcelExportServiceSync>(create: (_) => excelExportService),
        Provider<SeedDataService>(create: (_) => seedDataService),
      ],
      child: const MyApp(), 
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = AppConfig.instance.environment;

    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner:
          environment == Environment.dev,
      title: AppConfig.instance.appTitle, // <-- Usa el título del flavor
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
