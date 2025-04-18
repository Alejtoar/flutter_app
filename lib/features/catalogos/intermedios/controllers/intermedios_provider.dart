import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/repositories/intermedio_repository_impl.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Este widget debe agregarse en main.dart como provider
class IntermediosProvider extends StatelessWidget {
  final Widget child;
  const IntermediosProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IntermedioController(
        IntermedioFirestoreRepository(FirebaseFirestore.instance),
        InsumoUtilizadoFirestoreRepository(FirebaseFirestore.instance),
      ),
      child: child,
    );
  }
}
