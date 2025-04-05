# ViewModels

## IntermedioRequeridoViewModel

ViewModel que gestiona el estado y la lógica de presentación para los intermedios requeridos.

### Estado
- `_intermediosRequeridos`: Lista de intermedios requeridos
- `_loading`: Estado de carga
- `_error`: Mensaje de error si existe
- `_intermedioSeleccionado`: Intermedio actualmente seleccionado

### Getters
- `intermediosRequeridos`: Acceso a la lista de intermedios
- `loading`: Estado de carga actual
- `error`: Mensaje de error actual
- `intermedioSeleccionado`: Intermedio seleccionado actual

### Métodos Principales

1. **Operaciones de Carga**
   - `cargarIntermediosPorPlato`: Carga todos los intermedios de un plato
   - `cargarIntermedioRequerido`: Carga un intermedio específico por ID

2. **Operaciones CRUD**
   - `crearIntermedioRequerido`: Crea nuevo intermedio
   - `actualizarIntermedioRequerido`: Actualiza intermedio existente
   - `eliminarIntermedioRequerido`: Elimina un intermedio

3. **Operaciones Específicas**
   - `actualizarOrden`: Actualiza el orden de un intermedio
   - `actualizarCantidad`: Actualiza la cantidad de un intermedio
   - `reordenarIntermedios`: Reordena la lista completa de intermedios

4. **Gestión de Selección**
   - `seleccionarIntermedio`: Establece el intermedio seleccionado
   - `limpiarSeleccion`: Limpia la selección actual

5. **Gestión de Estado**
   - `limpiarError`: Limpia el mensaje de error
   - `_setLoading`: Maneja el estado de carga

### Características
- Extiende `ChangeNotifier` para notificar cambios a los widgets
- Manejo de errores con try-catch
- Actualización automática de la UI con `notifyListeners()`
- Mantiene la lista local sincronizada con Firestore
- Gestión de estados de carga y error

### Patrón de Uso
1. Se instancia con un `IntermedioRequeridoService`
2. Los widgets se suscriben a los cambios usando `Provider`
3. Notifica automáticamente a los widgets cuando hay cambios
4. Maneja la lógica de negocio y estado de la UI
