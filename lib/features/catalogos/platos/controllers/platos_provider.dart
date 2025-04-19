import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/repositories/plato_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository_impl.dart';
import 'package:golo_app/repositories/insumo_requerido_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Este widget debe agregarse en main.dart o en la jerarquía de navegación para proveer PlatoController
class PlatosProvider extends StatelessWidget {
  final Widget child;
  const PlatosProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlatoController(
        PlatoFirestoreRepository(FirebaseFirestore.instance),
        IntermedioRequeridoFirestoreRepository(FirebaseFirestore.instance),
        InsumoRequeridoFirestoreRepository(FirebaseFirestore.instance),
      ),
      child: child,
    );
  }
}
