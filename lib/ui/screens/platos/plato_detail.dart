import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/plato.dart';
import '../../../viewmodels/plato_viewmodel.dart';

class PlatoDetail extends StatelessWidget {
  final Plato plato;

  const PlatoDetail({
    Key? key,
    required this.plato,
  }) : super(key: key);

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plato'),
        content: const Text('¿Está seguro que desea eliminar este plato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PlatoViewModel>(context, listen: false)
                  .eliminarPlato(plato.id!);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plato.nombre),
        actions: [
          IconButton(
            icon: Icon(plato.activo ? Icons.edit : Icons.delete),
            onPressed: () {
              if (plato.activo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlatoForm(
                      plato: plato,
                      viewModel: Provider.of<PlatoViewModel>(context),
                    ),
                  ),
                );
              } else {
                _showDeleteConfirmation(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Código: ${plato.codigo}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Nombre: ${plato.nombre}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Descripción:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(plato.descripcion),
              SizedBox(height: 16),
              Text(
                'Receta:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(plato.receta),
              SizedBox(height: 16),
              Text(
                'Categorías:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: plato.categorias.map((categoria) {
                  final info = Plato.categoriasDisponibles[categoria];
                  return Chip(
                    avatar: Icon(info!['icon'] as IconData),
                    label: Text(info['nombre'] as String),
                    backgroundColor: info['color'] as Color,
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text(
                'Porciones mínimas: ${plato.porcionesMinimas}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Estado: ${plato.activo ? 'Activo' : 'Inactivo'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Fecha de creación: ${plato.fechaCreacion}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Fecha de actualización: ${plato.fechaActualizacion}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
