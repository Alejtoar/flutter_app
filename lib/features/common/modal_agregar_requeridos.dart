import 'package:flutter/material.dart';

/// Modal genérico para agregar requeridos (insumos o intermedios) a una entidad (plato, intermedio, etc).
/// Permite inyectar el contexto del controlador y la lógica de búsqueda/agregado a través de callbacks y builders.
class ModalAgregarRequeridos<T> extends StatefulWidget {
  final String titulo;
  final List<T> requeridosIniciales;
  final void Function(List<T>) onGuardar;
  final Future<List<dynamic>> Function(String) onBuscar;
  final Widget Function(dynamic, bool yaAgregado, VoidCallback onTap) itemBuilder;
  final String Function(dynamic) unidadGetter;
  final T Function(dynamic, double) crearRequerido;
  final String labelCantidad;
  final String labelBuscar;
  final String Function(T) nombreMostrar;
  final String Function(T) subtitleBuilder;
  final String? unidadLabel;

  const ModalAgregarRequeridos({
    Key? key,
    required this.titulo,
    required this.requeridosIniciales,
    required this.onGuardar,
    required this.onBuscar,
    required this.itemBuilder,
    required this.unidadGetter,
    required this.crearRequerido,
    required this.labelCantidad,
    required this.labelBuscar,
    required this.nombreMostrar,
    required this.subtitleBuilder,
    this.unidadLabel,
  }) : super(key: key);

  @override
  State<ModalAgregarRequeridos<T>> createState() => _ModalAgregarRequeridosState<T>();
}

class _ModalAgregarRequeridosState<T> extends State<ModalAgregarRequeridos<T>> {
  final List<T> _requeridosSeleccionados = [];
  dynamic _itemActual;
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _buscarController = TextEditingController();
  List<dynamic> _itemsFiltrados = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requeridosSeleccionados.addAll(widget.requeridosIniciales);
    _buscarController.addListener(_buscar);
    _buscar('');
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _buscarController.dispose();
    super.dispose();
  }

  void _buscar([String? value]) async {
    setState(() { _loading = true; });
    final results = await widget.onBuscar(_buscarController.text);
    setState(() {
      _itemsFiltrados = results;
      _loading = false;
    });
  }

  void _agregar(dynamic item) {
    setState(() {
      _itemActual = item;
      _cantidadController.text = '';
    });
  }

  void _confirmarAgregar() {
    if (_itemActual == null) return;
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) return;
    final yaExiste = _requeridosSeleccionados.any((r) => widget.nombreMostrar(r) == widget.nombreMostrar(widget.crearRequerido(_itemActual, cantidad)));
    if (yaExiste) return;
    setState(() {
      _requeridosSeleccionados.add(widget.crearRequerido(_itemActual, cantidad));
      _itemActual = null;
      _cantidadController.clear();
    });
  }

  void _eliminar(T r) {
    setState(() {
      _requeridosSeleccionados.removeWhere((x) => widget.nombreMostrar(x) == widget.nombreMostrar(r));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _buscarController,
              decoration: InputDecoration(labelText: widget.labelBuscar),
            ),
            const SizedBox(height: 8),
            if (_itemActual == null) ...[
              SizedBox(
                height: 180,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _itemsFiltrados.length,
                        itemBuilder: (context, idx) {
                          final item = _itemsFiltrados[idx];
                          final yaAgregado = _requeridosSeleccionados.any((r) => widget.nombreMostrar(r) == widget.nombreMostrar(widget.crearRequerido(item, 1)));
                          return widget.itemBuilder(item, yaAgregado, () => _agregar(item));
                        },
                      ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: Text(widget.nombreMostrar(widget.crearRequerido(_itemActual, 0)))),
                  if (_itemActual != null)
                    Text('Unidad: ${widget.unidadGetter(_itemActual)}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
              TextField(
                controller: _cantidadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.labelCantidad,
                  hintText: _itemActual != null ? widget.unidadGetter(_itemActual) : null,
                  suffixText: _itemActual != null ? widget.unidadGetter(_itemActual) : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _confirmarAgregar,
                    child: const Text('Agregar'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _itemActual = null),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            Text('Agregados:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _requeridosSeleccionados.length,
                itemBuilder: (context, idx) {
                  final r = _requeridosSeleccionados[idx];
                  return ListTile(
                    title: Text(widget.nombreMostrar(r)),
                    subtitle: Text(widget.subtitleBuilder(r)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminar(r),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onGuardar(_requeridosSeleccionados);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
