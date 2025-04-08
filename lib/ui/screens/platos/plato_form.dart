import 'package:flutter/material.dart';
import '../../../models/plato.dart';
import '../../../viewmodels/plato_viewmodel.dart';

class PlatoForm extends StatefulWidget {
  final Plato? plato;
  final PlatoViewModel viewModel;

  const PlatoForm({
    Key? key,
    this.plato,
    required this.viewModel,
  }) : super(key: key);

  @override
  _PlatoFormState createState() => _PlatoFormState();
}

class _PlatoFormState extends State<PlatoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _codigoController;
  late TextEditingController _descripcionController;
  late TextEditingController _recetaController;
  late TextEditingController _porcionesMinimasController;
  late List<String> _categorias;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _codigoController = TextEditingController();
    _descripcionController = TextEditingController();
    _recetaController = TextEditingController();
    _porcionesMinimasController = TextEditingController();
    _categorias = [];
    _activo = true;

    if (widget.plato != null) {
      _nombreController.text = widget.plato!.nombre;
      _codigoController.text = widget.plato!.codigo;
      _descripcionController.text = widget.plato!.descripcion;
      _recetaController.text = widget.plato!.receta;
      _porcionesMinimasController.text = widget.plato!.porcionesMinimas.toString();
      _categorias = List.from(widget.plato!.categorias);
      _activo = widget.plato!.activo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _recetaController.dispose();
    _porcionesMinimasController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final plato = Plato(
        id: widget.plato?.id,
        nombre: _nombreController.text,
        codigo: _codigoController.text,
        descripcion: _descripcionController.text,
        receta: _recetaController.text,
        categorias: _categorias,
        porcionesMinimas: int.parse(_porcionesMinimasController.text),
        activo: _activo,
        fechaCreacion: widget.plato?.fechaCreacion ?? DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      if (widget.plato == null) {
        await widget.viewModel.crearPlato(plato);
      } else {
        await widget.viewModel.actualizarPlato(plato);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plato == null ? 'Nuevo Plato' : 'Editar Plato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _recetaController,
                decoration: const InputDecoration(labelText: 'Receta'),
                maxLines: 5,
              ),
              TextFormField(
                controller: _porcionesMinimasController,
                decoration: const InputDecoration(labelText: 'Porciones mínimas'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Categorías:'),
              Wrap(
                spacing: 8,
                children: widget.viewModel.categorias.map((categoria) {
                  final info = Plato.categoriasDisponibles[categoria];
                  return FilterChip(
                    label: Text(info!['nombre'] as String),
                    avatar: Icon(info['icon'] as IconData),
                    selected: _categorias.contains(categoria),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _categorias.add(categoria);
                        } else {
                          _categorias.remove(categoria);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Activo'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.plato == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
