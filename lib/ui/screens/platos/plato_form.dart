import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/plato.dart';
import '../../../viewmodels/plato_viewmodel.dart';
import '../../common/crud_form.dart';

class PlatoForm extends StatefulWidget {
  final Plato? plato;

  const PlatoForm({Key? key, this.plato}) : super(key: key);

  @override
  _PlatoFormState createState() => _PlatoFormState();
}

class _PlatoFormState extends State<PlatoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _costoController;
  late TextEditingController _precioController;
  List<String> _categorias = [];
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.plato?.nombre);
    _descripcionController = TextEditingController(text: widget.plato?.descripcion);
    _costoController = TextEditingController(
      text: widget.plato?.costoTotal.toString() ?? '',
    );
    _precioController = TextEditingController(
      text: widget.plato?.precioVenta.toString() ?? '',
    );
    _categorias = widget.plato?.categorias.toList() ?? [];
    _activo = widget.plato?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlatoViewModel>();

    return CrudForm(
      title: widget.plato == null ? 'Nuevo Plato' : 'Editar Plato',
      formKey: _formKey,
      isLoading: viewModel.loading,
      error: viewModel.error,
      onSave: _guardarPlato,
      onCancel: () => Navigator.of(context).pop(),
      children: [
        TextFormField(
          controller: _nombreController,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ingrese el nombre del plato',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: InputDecoration(
            labelText: 'Descripción',
            hintText: 'Ingrese la descripción del plato',
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _costoController,
                decoration: InputDecoration(
                  labelText: 'Costo',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El costo es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _precioController,
                decoration: InputDecoration(
                  labelText: 'Precio de Venta',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  final costo = double.tryParse(_costoController.text) ?? 0;
                  final precio = double.tryParse(value) ?? 0;
                  if (precio <= costo) {
                    return 'El precio debe ser mayor al costo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildCategoriasChips(),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text('Activo'),
          value: _activo,
          onChanged: (value) => setState(() => _activo = value),
        ),
      ],
    );
  }

  Widget _buildCategoriasChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categorías'),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ..._categorias.map((categoria) => Chip(
              label: Text(categoria),
              onDeleted: () => setState(() => _categorias.remove(categoria)),
            )),
            ActionChip(
              label: Icon(Icons.add),
              onPressed: _agregarCategoria,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _agregarCategoria() async {
    final categoria = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Categoría'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Nombre de la categoría',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = (context.findRenderObject() as RenderBox)
                  .findDescendant<EditableText>()
                  ?.controller
                  ?.text;
              Navigator.of(context).pop(text);
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );

    if (categoria != null && categoria.isNotEmpty) {
      setState(() => _categorias.add(categoria));
    }
  }

  Future<void> _guardarPlato() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final plato = Plato(
      id: widget.plato?.id ?? '',
      codigo: widget.plato?.codigo ?? 'P${now.millisecondsSinceEpoch}',
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      costoTotal: double.parse(_costoController.text),
      precioVenta: double.parse(_precioController.text),
      categorias: _categorias,
      intermedios: widget.plato?.intermedios ?? [],
      porcionesMinimas: widget.plato?.porcionesMinimas ?? 1,
      receta: widget.plato?.receta ?? '',
      activo: _activo,
      fechaCreacion: widget.plato?.fechaCreacion ?? now,
      fechaActualizacion: now,
    );

    final viewModel = context.read<PlatoViewModel>();
    bool success;
    
    if (widget.plato == null) {
      success = await viewModel.crearPlato(plato);
    } else {
      success = await viewModel.actualizarPlato(plato);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

extension _RenderBoxExtension on RenderBox {
  T? findChild<T>(BuildContext context) {
    final controller = (context.findRenderObject() as RenderBox)
        .findDescendant<EditableTextState>()
        ?.widget
        .controller;
    return controller?.text as T?;
  }
}

extension _RenderBoxFindDescendant on RenderBox {
  T? findDescendant<T>() {
    T? result;
    visitChildren((child) {
      if (child is T) {
        result = child as T;
      } else if (child is RenderBox) {
        result = child.findDescendant<T>();
      }
    });
    return result;
  }
}
