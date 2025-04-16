//insumo_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/common/selector_categorias.dart';
import 'package:golo_app/features/common/selector_unidades.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/selector_proveedores.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:collection/collection.dart';

class AddEditInsumoScreen extends StatefulWidget {
  final Insumo? insumo;

  const AddEditInsumoScreen({super.key, this.insumo});

  @override
  _AddEditInsumoScreenState createState() => _AddEditInsumoScreenState();
}

class _AddEditInsumoScreenState extends State<AddEditInsumoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late List<String> _selectedCategories = [];
  Proveedor? _selectedProveedor;
  String? _unidadSeleccionada;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.insumo?.nombre ?? '',
    );

    _precioController = TextEditingController(
      text: widget.insumo?.precioUnitario.toString() ?? '',
    );
    _selectedCategories = widget.insumo?.categorias ?? [];
    // Si el insumo ya tiene proveedor, buscarlo en el controller
    if (widget.insumo?.proveedorId != null &&
        widget.insumo?.proveedorId != '') {
      final controller = context.read<InsumoController>();
      _selectedProveedor = controller.proveedores.firstWhereOrNull(
        (p) => p.id == widget.insumo!.proveedorId,
      );
    }
  }

  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una categoría')),
      );
      return;
    }

    final controller = context.read<InsumoController>();
    try {
      String codigo = widget.insumo?.codigo ?? '';
      if (widget.insumo == null) {
        // Generar código único automáticamente
        codigo = await controller.generarNuevoCodigo();
      }
      final insumo = Insumo.crear(
        id: widget.insumo?.id,
        codigo: codigo,
        nombre: _nombreController.text,
        categorias: _selectedCategories,
        unidad: _unidadSeleccionada ?? 'unidad',
        precioUnitario: double.parse(_precioController.text),
        proveedorId: _selectedProveedor?.id ?? '',
        fechaCreacion: widget.insumo?.fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
      if (widget.insumo == null) {
        await controller.crearInsumo(insumo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insumo creado correctamente')),
        );
      } else {
        await controller.actualizarInsumo(insumo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insumo actualizado correctamente')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.insumo == null ? 'Nuevo Insumo' : 'Editar Insumo'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(labelText: 'Precio Unitario'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Requerido';
                        if (double.tryParse(value) == null) return 'Número inválido';
                        if (double.parse(value) <= 0) return 'Debe ser mayor a 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: SelectorUnidades(
                      unidadSeleccionada: _unidadSeleccionada,
                      onChanged: (unidad) => setState(() => _unidadSeleccionada = unidad),
                      label: 'Unidad',
                    ),
                  ),
                ],
              ),
              // Selector de categorías
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: SelectorCategorias(
                  seleccionadas: _selectedCategories,
                  compacto: true,
                  onChanged:
                      (categorias) =>
                          setState(() => _selectedCategories = categorias),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: SelectorProveedores(
                  proveedores: context.read<InsumoController>().proveedores,
                  proveedorSeleccionado: _selectedProveedor,
                  onChanged: (Proveedor? proveedor) {
                    setState(() {
                      _selectedProveedor = proveedor;
                    });
                  },
                  label: 'Proveedor',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarInsumo,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}
