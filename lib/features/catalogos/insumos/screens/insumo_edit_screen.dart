// lib/features/catalogos/insumos/screens/insumo_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/widgets/insumo_edit_form.dart';
import 'package:golo_app/models/insumo.dart';

class InsumoEditScreen extends StatelessWidget {
  final Insumo? insumo;

  const InsumoEditScreen({this.insumo, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InsumoController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(insumo == null ? 'Nuevo Insumo' : 'Editar Insumo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: InsumoEditForm(
          insumo: insumo,
          onSubmit: (editedInsumo) async {
            await controller.saveInsumo(editedInsumo);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}