import 'package:flutter/material.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';

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
  // Estado
  String? _codigoGenerado;
  List<String> _categorias = [];
  // Banderas de estado
  bool _isSaving = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _telefonoController = TextEditingController(text: p?.telefono ?? '');
    _correoController = TextEditingController(text: p?.correo ?? '');
    _categorias = List.from(p?.tiposInsumos ?? []);

    // Usar addPostFrameCallback para la lógica asíncrona inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialDataAndCode();
    });
  }

  Future<void> _loadInitialDataAndCode() async {
    final p = widget.proveedor;
    if (p == null) {
      // Modo Creación: Generar Código
      if (!mounted) return;
      setState(() => _isGeneratingCode = true);
      debugPrint("[ProveedorEditScreen] Modo Creación: Generando código...");
      final controller = context.read<ProveedorController>();
      try {
        final codigo = await controller.generarNuevoCodigo();
        if (mounted) setState(() => _codigoGenerado = codigo);
      } catch (e) {
         if(mounted) showAppSnackBar(context, 'Error al generar código: $e', isError: true);
         // Asignar un código de error para que el usuario sepa que algo falló
         if(mounted) setState(() => _codigoGenerado = "P-ERR");
      } finally {
        if (mounted) setState(() => _isGeneratingCode = false);
      }
    } else {
      // Modo Edición
      if (mounted) {
        setState(() => _codigoGenerado = p.codigo);
      }
    }
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
    if (_codigoGenerado == null || _codigoGenerado!.isEmpty || _codigoGenerado == 'P-ERR') {
      showAppSnackBar(context, 'No se pudo generar un código válido. Inténtalo de nuevo.', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final proveedor = Proveedor.crear(
        id: widget.proveedor?.id,
        codigo: _codigoGenerado!,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        tiposInsumos: _categorias,
        fechaRegistro: widget.proveedor?.fechaRegistro,
        fechaActualizacion: DateTime.now(),
        activo: widget.proveedor?.activo ?? true,
      );
      final controller = context.read<ProveedorController>();
      if (widget.proveedor == null) {
        await controller.crearProveedor(proveedor);
      } else {
        await controller.actualizarProveedor(proveedor);
      }
      if (mounted) {
        showAppSnackBar(context, 'Proveedor ${widget.proveedor == null ? 'creado' : 'actualizado'} correctamente.');
        Navigator.pop(context, true); // Devuelve true para indicar recarga
      }
    } catch (e) {
      if(mounted) showAppSnackBar(context, 'Error al guardar proveedor: ${e.toString()}', isError: true);
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esEdicion = widget.proveedor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
                : IconButton(icon: const Icon(Icons.save), tooltip: 'Guardar', onPressed: _guardarProveedor),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Sección Código ---
             Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: InputDecorator(
                 decoration: const InputDecoration(labelText: 'Código Proveedor', border: InputBorder.none, contentPadding: EdgeInsets.zero),
                 child: _isGeneratingCode && !esEdicion
                   ? const SizedBox(height: 20, child: Row(children: [Text("Generando... "), SizedBox(width: 10), SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]))
                   : Text(
                       _codigoGenerado ?? (esEdicion ? '' : '...'), // Muestra código o placeholder
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: _codigoGenerado == 'P-ERR' ? Colors.red : null,
                        ),
                     ),
               ),
             ),

            // --- Campos del Formulario ---
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.business)),
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono *', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese un teléfono' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo electrónico *', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                 if (value == null || value.trim().isEmpty) return 'Ingrese un correo';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) return 'Correo no válido';
                  return null;
              }
            ),
            const SizedBox(height: 16),
            Text('Tipos de Insumo que Suministra', style: theme.textTheme.titleSmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
             const SizedBox(height: 4),
            SelectorCategorias(
              seleccionadas: _categorias,
              onChanged: (cats) => setState(() => _categorias = cats),
              mostrarContador: true, // Asumiendo que esta propiedad existe
              // Necesitarías pasar la lista de categorías disponibles
              // categorias: Insumo.categoriasDisponibles.keys.toList(),
            ),
            const SizedBox(height: 24),
            // El botón de guardar ahora está en la AppBar
          ],
        ),
      ),
    );
  }
}

