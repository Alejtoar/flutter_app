import 'package:flutter/material.dart';
import '../../../models/plato.dart';
import '../../../models/intermedio_requerido.dart';

class PlatoDetail extends StatelessWidget {
  final Plato plato;
  final List<dynamic> intermedios;
  final Map<String, double> costos;

  const PlatoDetail({
    Key? key,
    required this.plato,
    required this.intermedios,
    required this.costos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildCostosCard(context),
          const SizedBox(height: 16),
          _buildIntermediosCard(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plato.nombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Código: ${plato.codigo}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Categoría: ${plato.categoria}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (plato.descripcion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                plato.descripcion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostosCard(BuildContext context) {
    final costoTotal = costos['costoTotal'] ?? 0.0;
    final precioVenta = costos['precioVenta'] ?? 0.0;
    final margenGanancia = precioVenta - costoTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Costos y Precios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildCostoRow('Costo Total', costoTotal),
            _buildCostoRow('Precio de Venta', precioVenta),
            _buildCostoRow('Margen de Ganancia', margenGanancia),
            const Divider(),
            Text(
              'Distribución de Costos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildCostoRow('Costos Directos', costos['costoDirecto'] ?? 0.0),
            _buildCostoRow('Costos Indirectos', costos['costoIndirecto'] ?? 0.0),
            _buildCostoRow('Costos Adicionales', costos['costoAdicional'] ?? 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildIntermediosCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intermedios Requeridos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intermedios.length,
              itemBuilder: (context, index) {
                final intermedio = intermedios[index] as IntermedioRequerido;
                return ListTile(
                  title: Text(intermedio.nombre),
                  subtitle: Text('Cantidad: ${intermedio.cantidad}'),
                  trailing: intermedio.instruccionesEspeciales != null
                      ? IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Instrucciones Especiales'),
                                content: Text(intermedio.instruccionesEspeciales!),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostoRow(String label, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


}
