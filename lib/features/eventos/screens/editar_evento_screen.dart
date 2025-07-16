// editar_evento_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/lista_componentes_requeridos.dart';
import 'package:golo_app/features/eventos/widgets/modal_personalizar_plato_evento.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Controladores y Widgets específicos de Eventos
import '../controllers/buscador_eventos_controller.dart';
// Modales para agregar
import '../widgets/modal_agregar_platos_evento.dart';
import '../widgets/modal_agregar_intermedios_evento.dart';
import '../widgets/modal_agregar_insumos_evento.dart';
// Modales para editar
import '../widgets/modal_editar_cantidad_insumo_evento.dart';
import '../widgets/modal_editar_cantidad_intermedio_evento.dart';
import '../widgets/modal_editar_cantidad_plato_evento.dart';
// Importar ItemExtra si lo estás usando
// Ajusta ruta

class EditarEventoScreen extends StatefulWidget {
  final Evento? evento;
  const EditarEventoScreen({Key? key, this.evento}) : super(key: key);

  @override
  State<EditarEventoScreen> createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _nombreClienteController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  late TextEditingController _ubicacionController;
  late TextEditingController _numeroInvitadosController;
  late TextEditingController _comentariosLogisticaController;

  // Estado
  late DateTime _fecha;
  late TipoEvento _tipoEvento;
  late EstadoEvento _estadoEvento;
  late bool _facturable;
  String? _codigoGenerado;

  // Listas de Relaciones
  List<PlatoEvento> _platosEvento = [];
  List<IntermedioEvento> _intermediosEvento = [];
  List<InsumoEvento> _insumosEvento = [];

  // Banderas de estado
  bool _isLoadingRelations = false;
  bool _isSaving = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;

    // Inicializar controladores
    _nombreClienteController = TextEditingController(
      text: e?.nombreCliente ?? '',
    );
    _telefonoController = TextEditingController(text: e?.telefono ?? '');
    _correoController = TextEditingController(text: e?.correo ?? '');
    _ubicacionController = TextEditingController(text: e?.ubicacion ?? '');
    _numeroInvitadosController = TextEditingController(
      text: (e?.numeroInvitados ?? 0) > 0 ? e!.numeroInvitados.toString() : '',
    );
    _comentariosLogisticaController = TextEditingController(
      text: e?.comentariosLogistica ?? '',
    );

    // Inicializar estado
    _fecha = e?.fecha ?? DateTime.now();
    _tipoEvento = e?.tipoEvento ?? TipoEvento.institucional;
    _estadoEvento = e?.estado ?? EstadoEvento.enCotizacion;
    _facturable = e?.facturable ?? true;
    _codigoGenerado = e?.codigo;

    // Carga asíncrona post-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData(); // Llamar a la función de carga combinada
    });
  }

  // Combina la carga de relaciones y la precarga de catálogos
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    debugPrint(
      "[EditarEventoScreen] Iniciando carga inicial y/o generación de código...",
    );

    // 1. Precargar Catálogos Base (siempre se intenta)
    // Ejecutar en segundo plano, no necesitamos esperar aquí necesariamente
    await _preloadCatalogData();

    // 2. Manejar Lógica de Código y Carga de Relaciones
    final e = widget.evento;
    if (e == null) {
      // --- Modo Creación: Generar Código ---
      setState(() => _isGeneratingCode = true); // Indicar que estamos generando
      debugPrint("[EditarEventoScreen] Modo Creación: Generando código...");
      try {
        // *** USA EL CONTROLADOR DE EVENTOS ***
        final controller = Provider.of<BuscadorEventosController>(
          context,
          listen: false,
        );
        final codigo =
            await controller.eventoRepository
                .generarNuevoCodigo(); // Llama al repo directamente
        debugPrint("[EditarEventoScreen] Código generado: $codigo");
        if (mounted) {
          setState(() {
            _codigoGenerado = codigo;
            _isGeneratingCode = false; // Termina la generación
          });
        }
      } catch (error, st) {
        debugPrint(
          "[EditarEventoScreen][ERROR] al generar código: $error\n$st",
        );
        if (mounted) {
          setState(() => _isGeneratingCode = false); // Terminar aunque falle
          showAppSnackBar(
            context,
            'Error al generar código automático: $error',
            isError: true,
          );
        }
      }
    } else {
      // --- Modo Edición: Usar código existente y Cargar Relaciones ---
      _codigoGenerado = e.codigo; // Usar código existente
      debugPrint(
        "[EditarEventoScreen] Modo Edición: Código existente '$_codigoGenerado'. Cargando relaciones...",
      );
      setState(() => _isLoadingRelations = true);
      final controller = Provider.of<BuscadorEventosController>(
        context,
        listen: false,
      );
      try {
        await controller.cargarRelacionesPorEvento(e.id!);
        if (mounted) {
          setState(() {
            _platosEvento = List.from(controller.platosEvento);
            _intermediosEvento = List.from(controller.intermediosEvento);
            _insumosEvento = List.from(controller.insumosEvento);
            debugPrint(
              "[EditarEventoScreen] Relaciones cargadas en modo edición.",
            );
          });
        }
      } catch (error, st) {
        debugPrint(
          "[EditarEventoScreen][ERROR] al cargar relaciones en modo edición: $error\n$st",
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
    debugPrint("[EditarEventoScreen] Carga inicial finalizada.");
  }

  // Precarga los catálogos base (Platos, Insumos, Intermedios)
  Future<void> _preloadCatalogData() async {
    if (!mounted) return;
    debugPrint("[EditarEventoScreen] Precargando catálogos base...");
    // Usar listen: false porque solo disparamos la carga
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );

    try {
      // Cargar en paralelo
      await Future.wait([
        if (platoCtrl.platos.isEmpty)
          platoCtrl.cargarPlatos().then((_) => debugPrint("Catálogo Platos ✓")),
        if (insumoCtrl.insumos.isEmpty)
          insumoCtrl.cargarInsumos().then(
            (_) => debugPrint("Catálogo Insumos ✓"),
          ),
        if (intermedioCtrl.intermedios.isEmpty)
          intermedioCtrl.cargarIntermedios().then(
            (_) => debugPrint("Catálogo Intermedios ✓"),
          ),
      ]);
      debugPrint("[EditarEventoScreen] Precarga de catálogos finalizada.");
    } catch (error) {
      debugPrint("[EditarEventoScreen][ERROR] al precargar catálogos: $error");
      if (mounted) {
        // Mostrar un aviso no bloqueante
        showAppSnackBar(
          context,
          'Error al cargar catalagos necesarios: $error',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ubicacionController.dispose();
    _numeroInvitadosController.dispose();
    _comentariosLogisticaController.dispose();
    super.dispose();
  }

  // --- Funciones para Modales de Agregar (Estilo PlatoEditScreen) ---

  Future<void> _abrirModalPlatos() async {
    // Asegurar catálogos cargados ANTES de abrir
    await _preloadCatalogData();
    if (!mounted) return;

    // Verificar si el catálogo se cargó efectivamente
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    if (platoCtrl.platos.isEmpty) {
      showAppSnackBar(
        context,
        'El catálogo de platos no está disponible.',
        isError: true,
      );
      return;
    }

    debugPrint("[EditarEventoScreen] Abriendo ModalAgregarPlatosEvento...");
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarPlatosEvento(
            platosIniciales: _platosEvento,
            // Pasa setState directamente como callback
            onGuardar: (nuevos) {
              debugPrint(
                "[EditarEventoScreen] ModalAgregarPlatosEvento guardó, actualizando estado local con ${nuevos.length} platos...",
              );
              if (mounted) {
                // Re-verificar mounted por si acaso
                setState(() {
                  _platosEvento = List.from(nuevos); // Crear nueva lista
                });
              }
            },
          ),
    );
    debugPrint("[EditarEventoScreen] ModalAgregarPlatosEvento cerrado.");
  }

  Future<void> _abrirModalIntermedios() async {
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
      "[EditarEventoScreen] Abriendo ModalAgregarIntermediosEvento...",
    );
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarIntermediosEvento(
            intermediosIniciales: _intermediosEvento,
            onGuardar: (nuevos) {
              debugPrint(
                "[EditarEventoScreen] ModalAgregarIntermediosEvento guardó, actualizando estado local con ${nuevos.length} intermedios...",
              );

              if (mounted) {
                setState(() => _intermediosEvento = List.from(nuevos));
              }
            },
          ),
    );
    debugPrint("[EditarEventoScreen] ModalAgregarIntermediosEvento cerrado.");
  }

  Future<void> _abrirModalInsumos() async {
    await _preloadCatalogData();
    if (!mounted) return;
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      showAppSnackBar(
        context,
        'El catálogo de insumos no está disponible.',
        isError: true,
      );

      return;
    }

    debugPrint("[EditarEventoScreen] Abriendo ModalAgregarInsumosEvento...");
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosEvento(
            insumosIniciales: _insumosEvento,
            onGuardar: (nuevos) {
              debugPrint(
                "[EditarEventoScreen] ModalAgregarInsumosEvento guardó, actualizando estado local con ${nuevos.length} insumos...",
              );

              if (mounted) {
                setState(() => _insumosEvento = List.from(nuevos));
              }
            },
          ),
    );
    debugPrint("[EditarEventoScreen] ModalAgregarInsumosEvento cerrado.");
  }

  // --- Funciones para Editar Cantidad/Detalle (Estilo PlatoEditScreen - Usan await/pop/setState) ---
  // Mantendremos este patrón aquí ya que parece más estable para edición individual

  Future<void> _editarPlatoRequerido(PlatoEvento pe) async {
    await _preloadCatalogData(); // Asegurar catálogo
    if (!mounted) return;
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    final platoBase = platoCtrl.platos.firstWhere(
      (p) => p.id == pe.platoId,
      orElse: () {
        debugPrint(
          "[EditarEventoScreen][WARN] Plato base ID ${pe.platoId} no encontrado.",
        );
        // Devolver objeto temporal para evitar crash en el modal
        return Plato(
          id: pe.platoId,
          codigo: 'DESC',
          nombre: 'Plato Desconocido',
          categorias: [],
          porcionesMinimas: 1,
          receta: '',
        );
      },
    );

    debugPrint(
      "[EditarEventoScreen] Abriendo ModalEditarCantidadPlatoEvento para ${platoBase.nombre}",
    );
    final editado = await showDialog<PlatoEvento>(
      // Esperar resultado
      context: context,
      builder:
          (ctx) => ModalEditarCantidadPlatoEvento(
            platoEvento: pe,
            plato: platoBase,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(
                pe.copyWith(cantidad: nuevaCantidad.toInt()),
              ); // Pop con el objeto actualizado
            },
          ),
    );
    debugPrint(
      "[EditarEventoScreen] ModalEditarCantidadPlatoEvento cerrado. Resultado: ${editado != null ? 'Guardado' : 'Cancelado'}",
    );

    if (editado != null && mounted) {
      setState(() {
        final index = _platosEvento.indexWhere(
          (p) => p.platoId == editado.platoId && p.eventoId == editado.eventoId,
        );
        if (index != -1) {
          debugPrint(
            "[EditarEventoScreen] Actualizando plato en lista local: ${editado.platoId}",
          );
          _platosEvento[index] = editado;
        } else {
          debugPrint(
            "[EditarEventoScreen][WARN] No se encontró plato editado en la lista local para actualizar.",
          );
        }
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioEvento ie) async {
    await _preloadCatalogData();
    if (!mounted) return;
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    final intermedioBase = intermedioCtrl.intermedios.firstWhere(
      (i) => i.id == ie.intermedioId,
      orElse: () {
        debugPrint(
          "[EditarEventoScreen][WARN] Intermedio base ID ${ie.intermedioId} no encontrado.",
        );
        return Intermedio(
          id: ie.intermedioId,
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
      "[EditarEventoScreen] Abriendo ModalEditarCantidadIntermedioEvento para ${intermedioBase.nombre}",
    );
    final editado = await showDialog<IntermedioEvento>(
      // Esperar resultado
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioEvento(
            intermedioEvento: ie,
            intermedio: intermedioBase,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(
                ie.copyWith(cantidad: nuevaCantidad.toInt()),
              ); // Pop con objeto actualizado
            },
          ),
    );
    debugPrint(
      "[EditarEventoScreen] ModalEditarCantidadIntermedioEvento cerrado. Resultado: ${editado != null ? 'Guardado' : 'Cancelado'}",
    );

    if (editado != null && mounted) {
      setState(() {
        final index = _intermediosEvento.indexWhere(
          (i) =>
              i.intermedioId == editado.intermedioId &&
              i.eventoId == editado.eventoId,
        );
        if (index != -1) {
          debugPrint(
            "[EditarEventoScreen] Actualizando intermedio en lista local: ${editado.intermedioId}",
          );
          _intermediosEvento[index] = editado;
        } else {
          debugPrint(
            "[EditarEventoScreen][WARN] No se encontró intermedio editado en la lista local para actualizar.",
          );
        }
      });
    }
  }

  Future<void> _editarInsumoRequerido(InsumoEvento ie) async {
    await _preloadCatalogData();
    if (!mounted) return;
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    final insumoBase = insumoCtrl.insumos.firstWhere(
      (i) => i.id == ie.insumoId,
      orElse: () {
        debugPrint(
          "[EditarEventoScreen][WARN] Insumo base ID ${ie.insumoId} no encontrado.",
        );
        return Insumo(
          id: ie.insumoId,
          codigo: 'DESC',
          nombre: 'Insumo Desconocido',
          unidad: '?',
          categorias: ['Desconocida'],
          precioUnitario: 0,
          proveedorId: '',
          activo: false,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
        );
      },
    );

    debugPrint(
      "[EditarEventoScreen] Abriendo ModalEditarCantidadInsumoEvento para ${insumoBase.nombre}",
    );
    final editado = await showDialog<InsumoEvento>(
      // Esperar resultado
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoEvento(
            insumoEvento: ie,
            insumo: insumoBase,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(
                ie.copyWith(cantidad: nuevaCantidad),
              ); // Pop con objeto actualizado
            },
          ),
    );
    debugPrint(
      "[EditarEventoScreen] ModalEditarCantidadInsumoEvento cerrado. Resultado: ${editado != null ? 'Guardado' : 'Cancelado'}",
    );

    if (editado != null && mounted) {
      setState(() {
        final index = _insumosEvento.indexWhere(
          (i) =>
              i.insumoId == editado.insumoId && i.eventoId == editado.eventoId,
        );
        if (index != -1) {
          debugPrint(
            "[EditarEventoScreen] Actualizando insumo en lista local: ${editado.insumoId}",
          );
          _insumosEvento[index] = editado;
        } else {
          debugPrint(
            "[EditarEventoScreen][WARN] No se encontró insumo editado en la lista local para actualizar.",
          );
        }
      });
    }
  }

  // --- Funciones para Eliminar Relaciones ---

  void _eliminarPlatoRequerido(PlatoEvento pe) {
    setState(() {
      _platosEvento.removeWhere(
        (p) => p.platoId == pe.platoId,
      ); // Asume IDs únicos por ahora
      debugPrint(
        "[EditarEventoScreen] PlatoEvento eliminado localmente: ${pe.platoId}",
      );
    });
  }

  void _eliminarIntermedioRequerido(IntermedioEvento ie) {
    setState(() {
      _intermediosEvento.removeWhere((i) => i.intermedioId == ie.intermedioId);
      debugPrint(
        "[EditarEventoScreen] IntermedioEvento eliminado localmente: ${ie.intermedioId}",
      );
    });
  }

  void _eliminarInsumoRequerido(InsumoEvento ie) {
    setState(() {
      _insumosEvento.removeWhere((i) => i.insumoId == ie.insumoId);
      debugPrint(
        "[EditarEventoScreen] InsumoEvento eliminado localmente: ${ie.insumoId}",
      );
    });
  }

  // --- Función Principal para Guardar ---

  Future<void> _guardarEvento() async {
    debugPrint('[EditarEventoScreen] Iniciando guardado...');
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) {
      debugPrint('[EditarEventoScreen] Formulario inválido.');
      showAppSnackBar(
        context,
        'Por favor, corrige los errores en el formulario.',
        isError: true,
      );

      return;
    }

    if (widget.evento == null &&
        (_codigoGenerado == null || _codigoGenerado!.isEmpty)) {
      debugPrint(
        '[EditarEventoScreen][ERROR] Intento de guardar evento nuevo sin código generado.',
      );
      showAppSnackBar(
        context,
        'Aún se está generando el código, espera un momento.',
        isError: true,
      );

      // Opcionalmente, intentar generarlo de nuevo si falló la primera vez
      // if (!_isGeneratingCode) {
      //    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialDataAndCode());
      // }
      return; // No continuar si no hay código
    }

    if (!mounted) {
      debugPrint(
        '[EditarEventoScreen][WARN] Guardado cancelado, widget no montado.',
      );
      return;
    }
    setState(() => _isSaving = true);
    debugPrint('[EditarEventoScreen] Estado _isSaving = true');

    // 3. Construir objeto Evento
    final eventoData = Evento.crear(
      id: widget.evento?.id,
      codigo: _codigoGenerado!,
      nombreCliente: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      fecha: _fecha,
      ubicacion: _ubicacionController.text.trim(),
      numeroInvitados: int.tryParse(_numeroInvitadosController.text) ?? 0,
      tipoEvento: _tipoEvento,
      estado: _estadoEvento,
      fechaCotizacion: widget.evento?.fechaCotizacion,
      fechaConfirmacion: widget.evento?.fechaConfirmacion,
      fechaCreacion: widget.evento?.fechaCreacion,
      fechaActualizacion: DateTime.now(), // Se sobreescribe en repo
      comentariosLogistica:
          _comentariosLogisticaController.text.trim().isEmpty
              ? null
              : _comentariosLogisticaController.text.trim(),
      facturable: _facturable,
    );
    debugPrint(
      '[EditarEventoScreen] Objeto Evento construido: ${eventoData.codigo}',
    );

    // 4. Llamar al controlador
    final controller = Provider.of<BuscadorEventosController>(
      context,
      listen: false,
    );
    bool success = false;
    String? errorMessage;

    try {
      if (widget.evento == null) {
        // --- Crear ---
        debugPrint(
          '[EditarEventoScreen] Llamando a crearEventoConRelaciones...',
        );
        String codigoFinal = eventoData.codigo;
        if (codigoFinal.isEmpty) {
          codigoFinal = await controller.eventoRepository.generarNuevoCodigo();
          debugPrint(
            "[EditarEventoScreen] Código generado para nuevo evento: $codigoFinal",
          );
        }
        final eventoParaCrear = eventoData.copyWith(codigo: codigoFinal);

        final creado = await controller.crearEventoConRelaciones(
          eventoParaCrear,
          _platosEvento,
          _insumosEvento,
          _intermediosEvento,
        );
        success = creado != null;
        if (!success) {
          errorMessage = controller.error ?? "Error desconocido al crear.";
        }
        debugPrint(
          '[EditarEventoScreen] crearEventoConRelaciones completado. Éxito: $success',
        );
      } else {
        // --- Actualizar ---
        debugPrint(
          '[EditarEventoScreen] Llamando a actualizarEventoConRelaciones para ID: ${eventoData.id}...',
        );
        success = await controller.actualizarEventoConRelaciones(
          eventoData,
          _platosEvento,
          _insumosEvento,
          _intermediosEvento,
        );
        if (!success) {
          errorMessage = controller.error ?? "Error desconocido al actualizar.";
        }
        debugPrint(
          '[EditarEventoScreen] actualizarEventoConRelaciones completado. Éxito: $success',
        );
      }

      // 5. Manejar resultado y mostrar feedback
      if (mounted) {
        if (success) {
          showAppSnackBar(
            context,
            'Evento ${widget.evento == null ? 'creado' : 'actualizado'} con éxito.',
            isError: false,
          );

          Navigator.of(context).pop(); // Volver a la pantalla anterior
        } else {
          debugPrint('[EditarEventoScreen][ERROR] al guardar: $errorMessage');
          showAppSnackBar(
            context,
            'Error al guardar: ${errorMessage ?? "Inténtalo de nuevo"}',
            isError: true,
          );
        }
      }
    } catch (e, st) {
      // Capturar errores inesperados durante la llamada al controlador
      debugPrint('[EditarEventoScreen][ERROR GRAL] al guardar: $e\n$st');
      errorMessage = e.toString();
      if (mounted) {
        showAppSnackBar(
          context,
          'Error inesperado al guardar: $errorMessage',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        debugPrint('[EditarEventoScreen] Estado _isSaving = false');
      }
    }
  }

  // --- Construcción de la UI (similar a la versión anterior) ---
  @override
  Widget build(BuildContext context) {
    // ... (Misma estructura de Scaffold, AppBar, Form, ListView que la versión anterior) ...
    // ... (Usa los TextFormField con validadores) ...
    // ... (Usa los DropdownButtonFormField con validadores) ...
    // ... (Usa el helper _buildSectionHeader) ...
    // ... (Usa el helper _buildRelationListSection para mostrar las listas) ...

    // Asegúrate de que el botón de guardar final (si lo tienes) o el de la AppBar
    // muestre el indicador _isSaving correctamente.

    final esEdicion = widget.evento != null;
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Evento' : 'Nuevo Evento'),
        actions: [
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
                      tooltip: 'Guardar Evento',
                      onPressed:
                          _guardarEvento, // Llama a la función de guardado
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Mostrar Código si es edición
            if (esEdicion &&
                _codigoGenerado !=
                    null) // Modo Edición: Mostrar código existente
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Evento',
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
            else if (!esEdicion) // Modo Creación: Mostrar código generado o indicador
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Evento',
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
                            _codigoGenerado ??
                                'Error al generar', // Mostrar código o mensaje de error
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _codigoGenerado == null
                                      ? Colors.red
                                      : null, // Color rojo si hubo error
                            ),
                          ),
                ),
              ),

            // Campos del Formulario
            TextFormField(
              controller: _nombreClienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente *',
              ),
              textCapitalization: TextCapitalization.words,
              validator:
                  (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Campo requerido'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Campo requerido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo *',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Campo requerido';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacionController,
              decoration: const InputDecoration(
                labelText: 'Ubicación *',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator:
                  (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Campo requerido'
                          : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numeroInvitadosController,
              decoration: const InputDecoration(
                labelText: 'Nº Invitados *',
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo requerido';
                final n = int.tryParse(value);
                if (n == null || n <= 0) return 'Debe ser un número positivo';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selector de Fecha y Switch Facturable
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    // Hacer toda el área clickeable
                    onTap: _seleccionarFecha, // Llamar a función helper
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Evento *',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatter.format(_fecha)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Facturable', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _facturable,
                      onChanged: (v) => setState(() => _facturable = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dropdowns para Tipo y Estado
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoEvento>(
                    value: _tipoEvento,
                    items:
                        TipoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _tipoEvento = v!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo Evento *',
                    ),
                    validator:
                        (value) => value == null ? 'Selecciona un tipo' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<EstadoEvento>(
                    value: _estadoEvento,
                    items:
                        EstadoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.name),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _estadoEvento = v!),
                    decoration: const InputDecoration(labelText: 'Estado *'),
                    validator:
                        (value) =>
                            value == null ? 'Selecciona un estado' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Campo Comentarios
            TextFormField(
              controller: _comentariosLogisticaController,
              decoration: const InputDecoration(
                labelText: 'Comentarios Logística (Opcional)',
                hintText: 'Notas sobre montaje, horarios, personal, etc.',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const Divider(height: 32, thickness: 1),

            // Secciones de Relaciones (Platos, Intermedios, Insumos)
            _buildSectionHeader('Platos del Evento', _abrirModalPlatos),
            _buildRelationListSection(
              isLoading: _isLoadingRelations,
              isEmpty: _platosEvento.isEmpty,
              listWidget: ListaComponentesRequeridos<PlatoEvento>(
                items: _platosEvento,
                nombreGetter: (pe) {
                  // Necesitas acceder al PlatoController para obtener el nombre
                  final platoCtrl = context.read<PlatoController>();
                  return platoCtrl.platos
                          .firstWhereOrNull((p) => p.id == pe.platoId)
                          ?.nombre ??
                      pe.platoId;
                },
                cantidadGetter: (pe) => "${pe.cantidad} Platos",
                onEditar: _editarPlatoRequerido,
                onEliminar: _eliminarPlatoRequerido,
                onPersonalizar:
                    _personalizarPlatoRequerido, // El widget genérico soporta esto
                emptyListText: "No hay platos añadidos.",
              ),
              loadingText: 'Cargando platos...',
              emptyText: 'No hay platos añadidos.',
              isEditing: esEdicion,
            ),
            const Divider(height: 32, thickness: 1),

            _buildSectionHeader(
              'Intermedios Requeridos',
              _abrirModalIntermedios,
            ),
            _buildRelationListSection(
              isLoading: _isLoadingRelations,
              isEmpty: _intermediosEvento.isEmpty,
              listWidget: ListaComponentesRequeridos<IntermedioEvento>(
                items: _intermediosEvento,
                nombreGetter: (ie) {
                  final intermedioCtrl = context.read<IntermedioController>();
                  return intermedioCtrl.intermedios
                          .firstWhereOrNull((i) => i.id == ie.intermedioId)
                          ?.nombre ??
                      ie.intermedioId;
                },
                cantidadGetter: (ie) {
                  final intermedioCtrl = context.read<IntermedioController>();
                  final unidad =
                      intermedioCtrl.intermedios
                          .firstWhereOrNull((i) => i.id == ie.intermedioId)
                          ?.unidad ??
                      '';
                  return '${ie.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
                },
                onEditar: _editarIntermedioRequerido,
                onEliminar: _eliminarIntermedioRequerido,
                emptyListText: "No hay intermedios añadidos.",
              ),
              loadingText: 'Cargando intermedios...',
              emptyText: 'No hay intermedios añadidos.',
              isEditing: esEdicion,
            ),
            const Divider(height: 32, thickness: 1),

            _buildSectionHeader('Insumos Adicionales', _abrirModalInsumos),
            _buildRelationListSection(
              isLoading: _isLoadingRelations,
              isEmpty: _insumosEvento.isEmpty,
              listWidget: ListaComponentesRequeridos<InsumoEvento>(
                items: _insumosEvento,
                nombreGetter: (ie) {
                  final insumoCtrl = context.read<InsumoController>();
                  return insumoCtrl.insumos
                          .firstWhereOrNull((i) => i.id == ie.insumoId)
                          ?.nombre ??
                      ie.insumoId;
                },
                cantidadGetter:
                    (ie) =>
                        '${ie.cantidad}${ie.unidad.isNotEmpty ? ' ${ie.unidad}' : ''}',
                onEditar: _editarInsumoRequerido,
                onEliminar: _eliminarInsumoRequerido,
                emptyListText: "No hay insumos añadidos.",
              ),
              loadingText: 'Cargando insumos...',
              emptyText: 'No hay insumos añadidos.',
              isEditing: esEdicion,
            ),

            const SizedBox(height: 30),
            const SizedBox(height: 20), // Espacio final
          ],
        ),
      ),
    );
  }

  // --- Helper para seleccionar fecha ---
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(
        const Duration(days: 90),
      ), // Ajusta límites según necesidad
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _fecha && mounted) {
      setState(() => _fecha = picked);
    }
  }

  // --- Helper para construir encabezados ---
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

  // --- Helper para mostrar listas de relaciones ---
  Widget _buildRelationListSection({
    required bool isLoading,
    required bool isEmpty,
    required Widget listWidget,
    required String loadingText,
    required String emptyText,
    required bool isEditing,
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
      // Mostrar la lista si no está cargando y no está vacía
      return Container(
        constraints: const BoxConstraints(maxHeight: 200), // Limitar altura
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          // Para asegurar que el contenido respete el borde redondeado
          borderRadius: BorderRadius.circular(4),
          child: listWidget,
        ),
      );
    }
  }

  Future<void> _personalizarPlatoRequerido(PlatoEvento pe) async {
    debugPrint(
      "[EditarEventoScreen] Iniciando personalización para PlatoEvento ID: ${pe.id}, Plato ID: ${pe.platoId}",
    );
    if (!mounted) return;
    // 1. Obtener controladores y plato base
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    Plato? platoBase;
    try {
      if (platoCtrl.platos.isEmpty) await platoCtrl.cargarPlatos();
      platoBase = platoCtrl.platos.firstWhere((p) => p.id == pe.platoId);
      debugPrint(
        "[EditarEventoScreen] Plato base encontrado: ${platoBase.nombre}",
      );
    } catch (e) {
      debugPrint(
        "[EditarEventoScreen][ERROR] No se encontró Plato base ID ${pe.platoId}: $e",
      );
      showAppSnackBar(
        context,
        'No se pudo encontrar la info base del plato.',
        isError: true,
      );
      return;
    }

    // 2. Cargar relaciones originales del plato base
    List<InsumoRequerido> insumosBase = [];
    List<IntermedioRequerido> intermediosBase = [];
    try {
      debugPrint(
        "[EditarEventoScreen] Cargando relaciones originales para Plato ID: ${platoBase.id!}",
      );
      await platoCtrl.cargarRelacionesPorPlato(
        platoBase.id!,
      ); // Reusa método existente
      insumosBase = List.from(platoCtrl.insumosRequeridos);
      intermediosBase = List.from(platoCtrl.intermediosRequeridos);
      debugPrint(
        "[EditarEventoScreen] Relaciones base cargadas: I(${insumosBase.length}), Int(${intermediosBase.length})",
      );
    } catch (e, st) {
      debugPrint(
        "[EditarEventoScreen][ERROR] al cargar relaciones originales del plato base: $e\n$st",
      );
      showAppSnackBar(
        context,
        'Advertencia: No se pudieron cargar ingredientes base del plato.',
        isError: true,
      );
      // Continuar igualmente, el modal manejará las listas vacías
    }

    // 3. Precargar catálogos Insumo/Intermedio
    await _preloadCatalogData();
    if (!mounted) return;

    // 4. Abrir el Modal de Personalización
    debugPrint("[EditarEventoScreen] Abriendo ModalPersonalizarPlatoEvento...");
    final platoEventoActualizado = await showDialog<PlatoEvento>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => ModalPersonalizarPlatoEvento(
            platoEventoOriginal: pe,
            platoBase: platoBase!,
            insumosBaseRequeridos: insumosBase,
            intermediosBaseRequeridos: intermediosBase,
          ),
    );
    debugPrint(
      "[EditarEventoScreen] ModalPersonalizarPlatoEvento cerrado. Resultado: ${platoEventoActualizado != null ? 'Guardado' : 'Cancelado'}",
    );

    // 5. Actualizar Estado si Hubo Cambios
    if (platoEventoActualizado != null && mounted) {
      setState(() {
        final index = _platosEvento.indexWhere(
          (item) =>
              item.id == pe.id ||
              (item.platoId == pe.platoId && item.id == null),
        );
        if (index != -1) {
          debugPrint(
            "[EditarEventoScreen] Actualizando PlatoEvento (índice $index) con personalización.",
          );
          _platosEvento[index] = platoEventoActualizado;
        } else {
          debugPrint(
            "[EditarEventoScreen][WARN] No se encontró PlatoEvento original para actualizar tras personalizar.",
          );
        }
      });
    }
  }
} // Fin de _EditarEventoScreenState
