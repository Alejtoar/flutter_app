// lib/features/catalogos/insumos/screens/insumos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/widgets/insumo_card.dart';
import 'package:golo_app/features/catalogos/insumos/widgets/insumo_search_bar.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumo_edit_screen.dart';

class InsumosScreen extends StatelessWidget {
  const InsumosScreen({Key? key}) : super(key: key);

  void _navigateToEdit(BuildContext context, [Insumo? insumo]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<InsumoController>(context, listen: false),
          child: InsumoEditScreen(insumo: insumo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Insumos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: Consumer<InsumoController>(
        builder: (context, controller, _) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              InsumoSearchBar(onSearchChanged: (query) => controller.filterInsumos(query)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.loadInsumos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: controller.insumos.length,
                    itemBuilder: (ctx, index) => InsumoCard(
                      insumo: controller.insumos[index],
                      onEdit: () => _navigateToEdit(context, controller.insumos[index]),
                      onDelete: () => controller.deleteInsumo(controller.insumos[index].id!),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}