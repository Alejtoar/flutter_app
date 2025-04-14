import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/features/catalogos/insumos/widgets/categoria_selector.dart';

class InsumoEditForm extends StatefulWidget {
  final Insumo? insumo;
  final Function(Insumo) onSubmit;

  const InsumoEditForm({
    Key? key,
    this.insumo,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _InsumoEditFormState createState() => _InsumoEditFormState();
}

class _InsumoEditFormState extends State<InsumoEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _unidadController;
  late TextEditingController _proveedorController;
  late List<String> _categoriasSeleccionadas;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.insumo?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.insumo?.nombre ?? '');
    _precioController = TextEditingController(
      text: widget.insumo?.precioUnitario.toString() ?? '0',
    );
    _unidadController = TextEditingController(text: widget.insumo?.unidad ?? 'unidad');
    _proveedorController = TextEditingController(text: widget.insumo?.proveedorId ?? '');
    _categoriasSeleccionadas = widget.insumo?.categorias ?? [];
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _unidadController.dispose();
    _proveedorController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _categoriasSeleccionadas.isNotEmpty) {
      final insumo = Insumo(
        id: widget.insumo?.id,
        codigo: _codigoController.text,
        nombre: _nombreController.text,
        categorias: _categoriasSeleccionadas,
        unidad: _unidadController.text,
        precioUnitario: double.parse(_precioController.text),
        proveedorId: _proveedorController.text,
        fechaCreacion: widget.insumo?.fechaCreacion ?? DateTime.now(),
        fechaActualizacion: DateTime.now(),
        activo: widget.insumo?.activo ?? true,
      );
      widget.onSubmit(insumo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'Ej: I-001',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El código es requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Harina de trigo',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El nombre es requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio Unitario',
                hintText: 'Ej: 25.50',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El precio es requerido';
                if (double.tryParse(value!) == null) return 'Ingrese un número válido';
                if (double.parse(value) <= 0) return 'El precio debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unidadController,
              decoration: const InputDecoration(
                labelText: 'Unidad de Medida',
                hintText: 'Ej: kg, litro, pieza',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La unidad es requerida';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proveedorController,
              decoration: const InputDecoration(
                labelText: 'ID de Proveedor',
                hintText: 'Ej: PROV-001',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El proveedor es requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Categorías:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            CategoriaSelector(
              initialSelection: _categoriasSeleccionadas,
              onChanged: (categorias) {
                _categoriasSeleccionadas = categorias;
              },
            ),
            if (_categoriasSeleccionadas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Seleccione al menos una categoría',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}