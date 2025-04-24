import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/buscador_eventos_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/evento_repository_impl.dart';
import '../../../repositories/plato_evento_repository_impl.dart';
import '../../../repositories/insumo_evento_repository_impl.dart';
import '../../../repositories/intermedio_evento_repository_impl.dart';

class BuscadorEventosProviderGlobal extends StatelessWidget {
  final Widget child;
  const BuscadorEventosProviderGlobal({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuscadorEventosController(
        repository: EventoFirestoreRepository(FirebaseFirestore.instance),
        platoEventoRepository: PlatoEventoFirestoreRepository(FirebaseFirestore.instance),
        insumoEventoRepository: InsumoEventoFirestoreRepository(FirebaseFirestore.instance),
        intermedioEventoRepository: IntermedioEventoFirestoreRepository(FirebaseFirestore.instance),
      ),
      child: child,
    );
  }
}
