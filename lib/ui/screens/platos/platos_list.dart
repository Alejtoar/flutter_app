import 'package:flutter/material.dart';
import '../../../models/plato.dart';

class PlatosList extends StatelessWidget {
  final List<Plato> platos;
  final Function(Plato) onPlatoSelected;
  final Function(Plato) onPlatoDeleted;

  const PlatosList({
    super.key,
    required this.platos,
    required this.onPlatoSelected,
    required this.onPlatoDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: platos.length,
      itemBuilder: (context, index) {
        final plato = platos[index];
        return ListTile(
          title: Text(plato.nombre),
          subtitle: Text('Código: ${plato.codigo}'),
          trailing: Icon(plato.activo ? Icons.check_circle : Icons.cancel),
          onTap: () => onPlatoSelected(plato),
          // trailing: IconButton(
          //   icon: const Icon(Icons.delete),
          //   onPressed: () => onPlatoDeleted(plato),
          // ),
        );
      },
    );
  }
}
