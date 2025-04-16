import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/features/common/selector_categorias.dart';

class ProveedorEditScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorEditScreen({super.key, this.proveedor});

  @override
  State<ProveedorEditScreen> createState() => _ProveedorEditScreenState();
}

class _ProveedorEditScreenState extends State<ProveedorEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  String? _codigo;
  List<String> _categorias = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final proveedor = widget.proveedor;
    _nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    _telefonoController = TextEditingController(text: proveedor?.telefono ?? '');
    _correoController = TextEditingController(text: proveedor?.correo ?? '');
    _codigo = proveedor?.codigo;
    _categorias = List<String>.from(proveedor?.tiposInsumos ?? []);
    if (_codigo == null) _generarCodigo();
  }

  Future<void> _generarCodigo() async {
    setState(() => _loading = true);
    try {
      final controller = context.read<ProveedorController>();
      final nuevoCodigo = await controller.generarNuevoCodigo();
      setState(() => _codigo = nuevoCodigo);
    } catch (_) {
      setState(() => _codigo = 'P-???');
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final proveedor = Proveedor.crear(
        id: widget.proveedor?.id,
        codigo: _codigo!,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        tiposInsumos: _categorias,
        fechaRegistro: widget.proveedor?.fechaRegistro,
        fechaActualizacion: DateTime.now(),
        activo: true,
      );
      final controller = context.read<ProveedorController>();
      if (widget.proveedor == null) {
        await controller.crearProveedor(proveedor);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor creado correctamente')),
        );
      } else {
        await controller.actualizarProveedor(proveedor);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proveedor actualizado correctamente')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      enabled: false,
                      initialValue: _codigo ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese un teléfono' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty ? 'Ingrese un correo electrónico' : null,
                    ),
                    const SizedBox(height: 16),
                    SelectorCategorias(
                      seleccionadas: _categorias,
                      onChanged: (cats) => setState(() => _categorias = cats),
                      mostrarContador: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _guardarProveedor,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

