import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/repositories/insumo_evento_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_evento_repository_impl.dart';
import 'package:golo_app/repositories/plato_evento_repository_impl.dart';
import 'package:provider/provider.dart';
import 'buscador_eventos_controller.dart';
import '../../../../repositories/evento_repository_impl.dart';

class BuscadorEventosProvider extends StatelessWidget {
  final Widget child;
  const BuscadorEventosProvider({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => BuscadorEventosController(
            repository: EventoFirestoreRepository(FirebaseFirestore.instance),
            platoEventoRepository: PlatoEventoFirestoreRepository(
              FirebaseFirestore.instance,
            ),
            insumoEventoRepository: InsumoEventoFirestoreRepository(
              FirebaseFirestore.instance,
            ),
            intermedioEventoRepository: IntermedioEventoFirestoreRepository(
              FirebaseFirestore.instance,
            ),
          ),
      child: child,
    );
  }
}
