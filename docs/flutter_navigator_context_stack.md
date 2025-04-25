# Flujo de Contextos y Pilas de Navegación en Flutter

Este documento explica el funcionamiento del `BuildContext` y la pila de navegación (`Navigator`) en Flutter, usando ejemplos concretos del flujo de modales y pantallas en la gestión de insumos/intermedios de este proyecto.

## Conceptos Clave

### 1. `BuildContext`
- Es una referencia al árbol de widgets en un punto específico.
- Cada widget tiene su propio contexto.
- El contexto determina desde dónde se realiza una acción (por ejemplo, mostrar/cerrar un modal).

### 2. Navigator y la Pila de Rutas
- Flutter usa una **pila** (stack) para manejar las rutas (pantallas, modales, etc.).
- Cuando navegas a una nueva pantalla o abres un modal, se agrega (push) una nueva ruta a la pila.
- Cuando cierras una pantalla/modal, se remueve (pop) la ruta superior de la pila.

## Ejemplo Práctico en este Proyecto

### Flujo de Pantallas y Modales
Supongamos que el usuario está en:
1. **Pantalla principal de intermedios** (`IntermediosScreen`)
2. Abre la **pantalla de edición** (`IntermedioEditScreen`) → se hace un `push`
3. Desde ahí, abre el **modal para editar cantidad de insumo** (`ModalEditarCantidadInsumo`) → se hace un `showDialog` (otro push)

La pila se ve así:

```
[IntermediosScreen]
  └─ [IntermedioEditScreen]
        └─ [ModalEditarCantidadInsumo]
```

### Cerrar Modales y Pantallas
- Cuando cierras el modal (`Navigator.of(context).pop()` usando el contexto del modal), solo se remueve `ModalEditarCantidadInsumo` y regresas a `IntermedioEditScreen`.
- Cuando guardas el intermedio y cierras la pantalla de edición (`Navigator.of(context).pop()` usando el contexto de la pantalla de edición), regresas a la pantalla principal.

### Problema Común: Doble Pop
Si accidentalmente llamas a `Navigator.of(context).pop()` dos veces (por ejemplo, en el callback y en el botón), puedes cerrar tanto el modal como la pantalla de edición, regresando a la pantalla principal inesperadamente.

#### Ejemplo de código correcto (modal):
```dart
ElevatedButton(
  onPressed: () {
    final nuevaCantidad = double.tryParse(_cantidadController.text);
    if (nuevaCantidad == null || nuevaCantidad <= 0) return;
    widget.onGuardar(nuevaCantidad); // Aquí se hace el pop desde el callback
  },
  child: const Text('Guardar'),
)
```
Y en el callback:
```dart
onGuardar: (nuevaCantidad) {
  Navigator.of(ctx).pop(iu.copyWith(cantidad: nuevaCantidad));
},
```

## Buenas Prácticas
- **Siempre usa el contexto más cercano al widget que quieres afectar.**
- **Evita pops redundantes:** Solo haz pop una vez por acción de cierre.
- **Para modales, usa el contexto (`ctx`) del builder del showDialog.**
- **Para pantallas, usa el contexto de la pantalla.**

## Resumen Visual

| Acción                | Contexto usado         | Qué se cierra        |
|-----------------------|-----------------------|----------------------|
| Cerrar modal          | Modal (`ctx`)         | Solo el modal        |
| Cerrar pantalla       | Pantalla (`context`)  | Solo la pantalla     |
| Doble pop (error)     | Ambos                 | Modal + pantalla     |


---

**Referencia:**
- [Navigator docs](https://docs.flutter.dev/cookbook/navigation/navigation-basics)
- [BuildContext docs](https://docs.flutter.dev/development/ui/widgets-intro#context)

Este flujo garantiza una experiencia de usuario predecible y evita errores de navegación en aplicaciones Flutter complejas como esta.
