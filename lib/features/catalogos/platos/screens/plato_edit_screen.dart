// plato_edit_screen.dart (Refactorizada al estilo EditarEventoScreen)
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/lista_componentes_requeridos.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
// Widgets específicos de Platos
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_insumos_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_intermedios_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_insumo_requerido.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_intermedio_requerido.dart';
import 'package:golo_app/models/intermedio.dart'; // Necesario para _editarIntermedioRequerido
import 'package:golo_app/models/insumo.dart'; // Necesario para _editarInsumoRequerido
// Widgets comunes
import 'package:golo_app/features/common/widgets/selector_categorias.dart'; // Asumo que este existe

class PlatoEditScreen extends StatefulWidget {
  final Plato? plato; // Plato existente o null para crear
  const PlatoEditScreen({Key? key, this.plato}) : super(key: key);

  @override
  State<PlatoEditScreen> createState() => _PlatoEditScreenState();
}

class _PlatoEditScreenState extends State<PlatoEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _recetaController;
  late TextEditingController _porcionesController;

  // Estado
  String? _codigoGenerado;
  List<String> _categorias = [];
  List<InsumoRequerido> _insumos = [];
  List<IntermedioRequerido> _intermedios = [];

  // Banderas de estado
  bool _isLoadingRelations = false;
  bool _isSaving = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plato; // 'p' representa el plato existente o null

    // Inicializar controladores
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _recetaController = TextEditingController(text: p?.receta ?? '');
    _porcionesController = TextEditingController(
      text: (p?.porcionesMinimas ?? 1).toString(),
    );
    _categorias = List.from(p?.categorias ?? []);
    // _codigoGenerado se inicializa abajo

    // Lógica asíncrona post-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialDataAndCode();
    });
  }

  // Carga combinada de datos iniciales y código
  Future<void> _loadInitialDataAndCode() async {
    if (!mounted) return;
    debugPrint(
      "[PlatoEditScreen] Iniciando carga inicial y/o generación de código...",
    );

    // 1. Precargar Catálogos Base (Insumos, Intermedios)
    // Ejecutar en segundo plano
    _preloadCatalogData();

    // 2. Manejar Lógica de Código y Carga de Relaciones
    final p = widget.plato;
    if (p == null) {
      // --- Modo Creación: Generar Código ---
      setState(() => _isGeneratingCode = true);
      debugPrint("[PlatoEditScreen] Modo Creación: Generando código...");
      try {
        final controller = Provider.of<PlatoController>(context, listen: false);
        final codigo = await controller.generarNuevoCodigo();
        debugPrint("[PlatoEditScreen] Código generado: $codigo");
        if (mounted) {
          setState(() {
            _codigoGenerado = codigo;
            _isGeneratingCode = false;
          });
        }
      } catch (error, st) {
        debugPrint("[PlatoEditScreen][ERROR] al generar código: $error\n$st");
        if (mounted) {
          setState(() => _isGeneratingCode = false);
          showAppSnackBar(
            context,
            'Error al generar código automático: $error',
            isError: true,
          );
        }
      }
    } else {
      // --- Modo Edición: Usar código existente y Cargar Relaciones ---
      _codigoGenerado = p.codigo;
      debugPrint(
        "[PlatoEditScreen] Modo Edición: Código existente '$_codigoGenerado'. Cargando relaciones...",
      );
      setState(() => _isLoadingRelations = true);
      final controller = Provider.of<PlatoController>(context, listen: false);
      try {
        await controller.cargarRelacionesPorPlato(p.id!);
        if (mounted) {
          setState(() {
            _insumos = List.from(controller.insumosRequeridos);
            _intermedios = List.from(controller.intermediosRequeridos);
            debugPrint(
              "[PlatoEditScreen] Relaciones cargadas: Insumos(${_insumos.length}), Intermedios(${_intermedios.length})",
            );
          });
        }
      } catch (error, st) {
        debugPrint(
          "[PlatoEditScreen][ERROR] al cargar relaciones en modo edición: $error\n$st",
        );
        if (mounted) {
          showAppSnackBar(
            context,
            'Error al cargar datos asociados: $error',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingRelations = false);
        }
      }
    }
    debugPrint("[PlatoEditScreen] Carga inicial finalizada.");
  }

  // Precarga catálogos base (Insumos, Intermedios)
  Future<void> _preloadCatalogData() async {
    if (!mounted) return;
    debugPrint("[PlatoEditScreen] Precargando catálogos base...");
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    try {
      await Future.wait([
        if (insumoCtrl.insumos.isEmpty)
          insumoCtrl.cargarInsumos().then(
            (_) => debugPrint("Catálogo Insumos ✓"),
          ),
        if (intermedioCtrl.intermedios.isEmpty)
          intermedioCtrl.cargarIntermedios().then(
            (_) => debugPrint("Catálogo Intermedios ✓"),
          ),
      ]);
      debugPrint("[PlatoEditScreen] Precarga de catálogos base finalizada.");
    } catch (error) {
      debugPrint(
        "[PlatoEditScreen][ERROR] al precargar catálogos base: $error",
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Error al cargar catálogos necesarios: $error',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _recetaController.dispose();
    _porcionesController.dispose();
    super.dispose();
  }

  // --- Funciones Modales Agregar (Patrón setState directo) ---
  void _abrirModalInsumos() async {
    await _preloadCatalogData();
    if (!mounted) return;
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      showAppSnackBar(
        context,
        'El catálogo de insumos no está disponible',
        isError: true,
      );
      return;
    }
    debugPrint("[PlatoEditScreen] Abriendo ModalAgregarInsumosRequeridos...");
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosRequeridos(
            insumosIniciales: _insumos,
            onGuardar: (nuevos) {
              debugPrint(
                "[PlatoEditScreen] ModalAgregarInsumosRequeridos guardó, actualizando estado local con ${nuevos.length} insumos...",
              );
              if (mounted) {
                setState(() => _insumos = List.from(nuevos));
              }
            },
          ),
    );
    debugPrint("[PlatoEditScreen] ModalAgregarInsumosRequeridos cerrado.");
  }

  void _abrirModalIntermedios() async {
    await _preloadCatalogData();
    if (!mounted) return;
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty) {
      showAppSnackBar(
        context,
        'El catálogo de intermedios no está disponible.',
        isError: true,
      );
      return;
    }
    debugPrint(
      "[PlatoEditScreen] Abriendo ModalAgregarIntermediosRequeridos...",
    );
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarIntermediosRequeridos(
            intermediosIniciales: _intermedios,
            onGuardar: (nuevos) {
              debugPrint(
                "[PlatoEditScreen] ModalAgregarIntermediosRequeridos guardó, actualizando estado local con ${nuevos.length} intermedios...",
              );
              if (mounted) {
                setState(() => _intermedios = List.from(nuevos));
              }
            },
          ),
    );
    debugPrint("[PlatoEditScreen] ModalAgregarIntermediosRequeridos cerrado.");
  }

  // --- Funciones Editar Relaciones (Patrón await/pop/setState) ---
  Future<void> _editarInsumoRequerido(InsumoRequerido iu) async {
    await _preloadCatalogData();
    if (!mounted) return;
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    final insumoBase = insumoCtrl.insumos.firstWhere(
      (i) => i.id == iu.insumoId,
      orElse: () {
        debugPrint(
          "[PlatoEditScreen][WARN] Insumo base ID ${iu.insumoId} no encontrado.",
        );
        return Insumo(
          id: iu.insumoId,
          codigo: 'DESC',
          nombre: 'Insumo Desconocido',
          unidad: '?',
          categorias: ['Desconocida'],
          activo: false,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
          precioUnitario: 0,
          proveedorId: '',
        );
      },
    );

    debugPrint(
      "[PlatoEditScreen] Abriendo ModalEditarCantidadInsumoRequerido para ${insumoBase.nombre}",
    );
    final editado = await showDialog<InsumoRequerido>(
      // Esperar resultado
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoRequerido(
            insumoRequerido: iu,
            insumo: insumoBase,
            onGuardar: (nuevaCantidad) {
              // Pop con el objeto actualizado
              Navigator.of(ctx).pop(iu.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    debugPrint(
      "[PlatoEditScreen] ModalEditarCantidadInsumoRequerido cerrado. Resultado: ${editado != null ? 'Guardado' : 'Cancelado'}",
    );

    if (editado != null && mounted) {
      setState(() {
        final idxLocal = _insumos.indexWhere(
          (x) => x.insumoId == editado.insumoId,
        );
        if (idxLocal != -1) {
          debugPrint(
            "[PlatoEditScreen] Actualizando insumo requerido en lista local: ${editado.insumoId}",
          );
          _insumos[idxLocal] = editado;
        } else {
          debugPrint(
            "[PlatoEditScreen][WARN] No se encontró insumo editado en la lista local para actualizar.",
          );
        }
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioRequerido ir) async {
    await _preloadCatalogData();
    if (!mounted) return;
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    final intermedioBase = intermedioCtrl.intermedios.firstWhere(
      (i) => i.id == ir.intermedioId,
      orElse: () {
        debugPrint(
          "[PlatoEditScreen][WARN] Intermedio base ID ${ir.intermedioId} no encontrado.",
        );
        return Intermedio(
          id: ir.intermedioId,
          codigo: 'DESC',
          nombre: 'Intermedio Desconocido',
          unidad: 'Und',
          categorias: [],
          cantidadEstandar: 1,
          reduccionPorcentaje: 0,
          receta: '',
          tiempoPreparacionMinutos: 0,
          activo: false,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
        );
      },
    );

    debugPrint(
      "[PlatoEditScreen] Abriendo ModalEditarCantidadIntermedioRequerido para ${intermedioBase.nombre}",
    );
    final editado = await showDialog<IntermedioRequerido>(
      // Esperar resultado
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioRequerido(
            intermedioRequerido: ir,
            intermedio: intermedioBase,
            onGuardar: (nuevaCantidad) {
              // Pop con el objeto actualizado
              Navigator.of(ctx).pop(ir.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    debugPrint(
      "[PlatoEditScreen] ModalEditarCantidadIntermedioRequerido cerrado. Resultado: ${editado != null ? 'Guardado' : 'Cancelado'}",
    );

    if (editado != null && mounted) {
      setState(() {
        final idxLocal = _intermedios.indexWhere(
          (x) => x.intermedioId == editado.intermedioId,
        );
        if (idxLocal != -1) {
          debugPrint(
            "[PlatoEditScreen] Actualizando intermedio requerido en lista local: ${editado.intermedioId}",
          );
          _intermedios[idxLocal] = editado;
        } else {
          debugPrint(
            "[PlatoEditScreen][WARN] No se encontró intermedio editado en la lista local para actualizar.",
          );
        }
      });
    }
  }

  // --- Funciones Eliminar Relaciones ---
  void _eliminarInsumoRequerido(InsumoRequerido iu) {
    setState(() {
      _insumos.removeWhere((x) => x.insumoId == iu.insumoId);
      debugPrint(
        "[PlatoEditScreen] InsumoRequerido eliminado localmente: ${iu.insumoId}",
      );
    });
  }

  void _eliminarIntermedioRequerido(IntermedioRequerido ir) {
    setState(() {
      _intermedios.removeWhere((x) => x.intermedioId == ir.intermedioId);
      debugPrint(
        "[PlatoEditScreen] IntermedioRequerido eliminado localmente: ${ir.intermedioId}",
      );
    });
  }

  // --- Función Principal Guardar ---
  Future<void> _guardarPlato() async {
    debugPrint('[PlatoEditScreen] Iniciando guardado...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[PlatoEditScreen] Formulario inválido.');
      showAppSnackBar(
        context,
        'Por favor, corrige los errores en el formulario.',
        isError: true,
      );
      return;
    }
    if (_categorias.isEmpty) {
      debugPrint(
        '[PlatoEditScreen] Validación fallida: No hay categorías seleccionadas.',
      );
      showAppSnackBar(
        context,
        'Debes seleccionar al menos una categoría.',
        isError: true,
      );
      return;
    }
    // Validar código si es nuevo
    if (widget.plato == null &&
        (_codigoGenerado == null || _codigoGenerado!.isEmpty)) {
      debugPrint(
        '[PlatoEditScreen][ERROR] Intento de guardar plato nuevo sin código generado.',
      );
      showAppSnackBar(
        context,
        'Aún se está generando el código, espera un momento.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);
    debugPrint('[PlatoEditScreen] Estado _isSaving = true');

    // Construir objeto Plato
    final platoData = Plato.crear(
      // Usar factory con validaciones internas
      id: widget.plato?.id,
      codigo: _codigoGenerado!, // Usar código generado/existente
      nombre: _nombreController.text.trim(),
      categorias: _categorias,
      porcionesMinimas: int.tryParse(_porcionesController.text) ?? 1,
      receta: _recetaController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      fechaCreacion: widget.plato?.fechaCreacion,
      fechaActualizacion: DateTime.now(), // Se sobreescribe en repo
      activo: widget.plato?.activo ?? true, // Default a activo si es nuevo
    );
    debugPrint(
      '[PlatoEditScreen] Objeto Plato construido con código: ${platoData.codigo}',
    );

    // Llamar al controlador
    final controller = Provider.of<PlatoController>(context, listen: false);
    bool success = false;
    String? errorMessage;

    try {
      if (widget.plato == null) {
        // --- Crear ---
        debugPrint('[PlatoEditScreen] Llamando a crearPlatoConRelaciones...');
        final creado = await controller.crearPlatoConRelaciones(
          platoData,
          _intermedios,
          _insumos,
        );
        success = creado != null;
      } else {
        // --- Actualizar ---
        debugPrint(
          '[PlatoEditScreen] Llamando a actualizarPlatoConRelaciones...',
        );
        success = await controller.actualizarPlatoConRelaciones(
          platoData,
          _intermedios,
          _insumos,
        );
      }
      if (!success) errorMessage = controller.error;
    } catch (e, st) {
      debugPrint('[PlatoEditScreen][ERROR GRAL] al guardar: $e\n$st');
      errorMessage = e.toString();
      success = false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        debugPrint('[PlatoEditScreen] Estado _isSaving = false');
      }
    }

    // Manejar resultado y feedback
    if (mounted) {
      if (success) {
        showAppSnackBar(
          context,
          'Plato ${widget.plato == null ? 'creado' : 'actualizado'} con éxito.',
          isError: false,
        );
        Navigator.of(context).pop();
      } else {
        debugPrint(
          '[PlatoEditScreen][ERROR] al guardar (post-llamada): $errorMessage',
        );
        showAppSnackBar(
          context,
          'Error al guardar el plato: ${errorMessage ?? "Inténtalo de nuevo"}',
          isError: true,
        );
      }
    }
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.plato != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Plato' : 'Crear Plato'),
        actions: [
          // Botón guardar en AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                _isSaving
                    ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Guardar Plato',
                      onPressed:
                          _guardarPlato, // Llama a la función de guardado
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Sección Código ---
            if (esEdicion && _codigoGenerado != null) // Modo Edición
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Plato',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _codigoGenerado!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (!esEdicion) // Modo Creación
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Plato',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child:
                      _isGeneratingCode
                          ? const SizedBox(
                            height: 20,
                            child: Row(
                              children: [
                                Text("Generando... "),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Text(
                            _codigoGenerado ?? 'Error al generar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _codigoGenerado == null ? Colors.red : null,
                            ),
                          ),
                ),
              ),

            // --- Campos del Formulario ---
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              textCapitalization: TextCapitalization.words,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Campo requerido'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _porcionesController,
              decoration: const InputDecoration(
                labelText: 'Porciones estándar *',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Debe ser un número positivo';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- Selector Categorías ---
            Text('Categorías *', style: theme.textTheme.titleSmall), // Etiqueta
            const SizedBox(height: 4),
            SelectorCategorias(
              // Asume que este widget existe y funciona
              categorias: Plato.categoriasDisponibles.keys.toList(),
              seleccionadas: _categorias,
              onChanged: (cats) => setState(() => _categorias = cats),
              // Puedes añadir validación aquí si es necesario, o validar en _guardarPlato
            ),

            // Mostrar error si no hay categorías seleccionadas (opcional, ya validado en guardar)
            // if (_formKey.currentState?.validate() == false && _categorias.isEmpty)
            //    Padding(...)
            const SizedBox(height: 16),

            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
                hintText: 'Breve descripción del plato...',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recetaController,
              decoration: const InputDecoration(
                labelText: 'Receta (Opcional)',
                hintText: 'Pasos de preparación, notas...',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4, // Más espacio para receta
            ),
            const Divider(height: 32, thickness: 1),

            // --- Sección Insumos ---
            _buildSectionHeader('Insumos Requeridos', _abrirModalInsumos),
            _buildRelationListSection(
              isLoading:
                  _isLoadingRelations && esEdicion, // Loading solo en edición
              isEmpty: _insumos.isEmpty,
              listWidget: ListaComponentesRequeridos<InsumoRequerido>(
                items: _insumos,
                nombreGetter: (ir) {
                  final insumoCtrl = context.read<InsumoController>();
                  return insumoCtrl.insumos
                          .firstWhereOrNull((ins) => ins.id == ir.insumoId)
                          ?.nombre ??
                      ir.insumoId;
                },
                cantidadGetter: (ir) {
                  final insumoCtrl = context.read<InsumoController>();
                  final unidad =
                      insumoCtrl.insumos
                          .firstWhereOrNull((ins) => ins.id == ir.insumoId)
                          ?.unidad ??
                      '';
                  return '${ir.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
                },
                onEditar: _editarInsumoRequerido,
                onEliminar: _eliminarInsumoRequerido,
                emptyListText: "No hay insumos requeridos añadidos.",
              ),
              loadingText: 'Cargando insumos...',
              emptyText: 'No hay insumos requeridos añadidos.',
            ),
            const Divider(height: 32, thickness: 1),

            // --- Sección Intermedios ---
            _buildSectionHeader(
              'Intermedios Requeridos',
              _abrirModalIntermedios,
            ),
            _buildRelationListSection(
              isLoading: _isLoadingRelations && esEdicion,
              isEmpty: _intermedios.isEmpty,
              listWidget: ListaComponentesRequeridos<IntermedioRequerido>(
                items: _intermedios,
                nombreGetter: (ir) {
                  final intermedioCtrl = context.read<IntermedioController>();
                  return intermedioCtrl.intermedios
                          .firstWhereOrNull((i) => i.id == ir.intermedioId)
                          ?.nombre ??
                      ir.intermedioId;
                },
                cantidadGetter: (ir) {
                  final intermedioCtrl = context.read<IntermedioController>();
                  final unidad =
                      intermedioCtrl.intermedios
                          .firstWhereOrNull((i) => i.id == ir.intermedioId)
                          ?.unidad ??
                      '';
                  return '${ir.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
                },
                onEditar: _editarIntermedioRequerido,
                onEliminar: _eliminarIntermedioRequerido,
                emptyListText: "No hay intermedios requeridos añadidos.",
              ),
              loadingText: 'Cargando intermedios...',
              emptyText: 'No hay intermedios requeridos añadidos.',
            ),
            const SizedBox(height: 30),

            // Botón de Guardar al final (opcional)
            // if (!_isSaving)
            //    ElevatedButton.icon(...)
            // else
            //    const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper para encabezados (similar a Eventos) ---
  Widget _buildSectionHeader(String title, VoidCallback onAddPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar'),
            onPressed: onAddPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper para listas de relaciones (similar a Eventos) ---
  Widget _buildRelationListSection({
    required bool isLoading,
    required bool isEmpty,
    required Widget listWidget,
    required String loadingText,
    required String emptyText,
  }) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 8),
              Text(loadingText),
            ],
          ),
        ),
      );
    } else if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    } else {
      // Usa Container con constraints para limitar altura y añade borde
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 150,
        ), // Ajusta altura como necesites
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          // Para que el contenido respete el borde redondeado
          borderRadius: BorderRadius.circular(4),
          child: listWidget,
        ),
      );
    }
  }
} // Fin de _PlatoEditScreenState
