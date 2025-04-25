import 'package:flutter/material.dart';
import '../../../../models/evento.dart';
import '../widgets/busqueda_bar_eventos.dart';
import '../widgets/lista_eventos.dart';
import 'editar_evento_screen.dart';

class BuscadorEventosScreen extends StatefulWidget {
  const BuscadorEventosScreen({Key? key}) : super(key: key);

  @override
  State<BuscadorEventosScreen> createState() => _BuscadorEventosScreenState();
}

class _BuscadorEventosScreenState extends State<BuscadorEventosScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool? _facturableFiltro;
  EstadoEvento? _estadoFiltro;
  TipoEvento? _tipoFiltro;
  DateTimeRange? _fechaRangoFiltro;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirNuevoEvento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEventoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _abrirNuevoEvento,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BusquedaBarEventos(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Filtros rápidos
                FilterChip(
                  label: const Text('Facturable'),
                  selected: _facturableFiltro == true,
                  onSelected: (v) => setState(() => _facturableFiltro = v ? true : null),
                ),
                FilterChip(
                  label: const Text('No facturable'),
                  selected: _facturableFiltro == false,
                  onSelected: (v) => setState(() => _facturableFiltro = v ? false : null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<EstadoEvento?>(
                  value: EstadoEvento.values.contains(_estadoFiltro) ? _estadoFiltro : null,
                  hint: const Text('Estado'),
                  items: [null, ...EstadoEvento.values].map((estado) => DropdownMenuItem(
                    value: estado,
                    child: Text(estado?.toString().split('.').last ?? 'Todos'),
                  )).toList(),
                  onChanged: (value) => setState(() => _estadoFiltro = value),
                ),
                const SizedBox(width: 8),
                DropdownButton<TipoEvento?>(
                  value: TipoEvento.values.contains(_tipoFiltro) ? _tipoFiltro : null,
                  hint: const Text('Tipo'),
                  items: [null, ...TipoEvento.values].map((tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo?.toString().split('.').last ?? 'Todos'),
                  )).toList(),
                  onChanged: (value) => setState(() => _tipoFiltro = value),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Fechas'),
                  onPressed: () async {
                    final rango = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (rango != null) setState(() => _fechaRangoFiltro = rango);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Evento>>(
                future: _buscarEventos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay eventos que coincidan'));
                  }
                  return ListaEventos(
                    eventos: snapshot.data!,
                    onVerDetalle: (evento) {}, // TODO: Navegar a detalle
                    onEditar: (evento) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarEventoScreen(evento: evento),
                        ),
                      );
                    },
                    onEliminar: (evento) {}, // TODO: Eliminar
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Evento>> _buscarEventos() async {
    // TODO: Implementar búsqueda real usando los filtros
    // Por ahora, simular lista vacía
    return [];
  }
}
