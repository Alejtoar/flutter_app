# Servicios de la Aplicación

## Servicios Principales

### 1. PlatoService
```dart
class PlatoService {
  Future<List<Plato>> obtenerTodos({bool? activo});
  Future<Plato> obtenerPlato(String id);
  Future<Plato> crearPlato(Plato plato);
  Future<void> actualizarPlato(Plato plato);
  Future<void> desactivarPlato(String id);
  Future<List<Plato>> buscarPlatos(String query);
}
```
**Descripción**: Gestiona todas las operaciones CRUD relacionadas con platos.

### 2. EventoService
```dart
class EventoService {
  Future<List<Evento>> obtenerEventos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoEvento? tipo,
    EstadoEvento? estado,
  });
  Future<Evento> obtenerEvento(String id);
  Future<void> crearEvento(Evento evento);
  Future<void> actualizarEvento(Evento evento);
  Future<void> confirmarEvento(String id, DateTime fecha);
}
```
**Descripción**: Maneja la gestión de eventos y reservaciones.

### 3. CostoProduccionService
```dart
class CostoProduccionService {
  Future<CostoProduccion> calcularCosto(String platoId);
  Future<void> actualizarCostos(String platoId, Map<String, double> costos);
  Future<List<CostoProduccion>> obtenerHistorial(String platoId);
}
```
**Descripción**: Calcula y gestiona los costos de producción.
- `intermedios_requeridos`: Colección en Firestore donde se almacenan los documentos

### Métodos
1. `crearIntermedioRequerido`
   - Valida que el intermedio base existe
   - Crea un nuevo documento en Firestore
   - Retorna el objeto creado con su ID asignado

2. `obtenerIntermedioRequerido`
   - Obtiene un intermedio requerido por su ID
   - Lanza excepción si no existe

3. `obtenerPorPlato`
   - Obtiene todos los intermedios requeridos de un plato
   - Ordenados por el campo `orden`

4. `actualizarIntermedioRequerido`
   - Actualiza un documento existente
   - Valida que el ID exista

5. `eliminarIntermedioRequerido`
   - Elimina un documento por su ID

6. `actualizarOrden`
   - Actualiza solo el campo orden
   - Registra fecha de actualización

7. `actualizarCantidad`
   - Actualiza solo el campo cantidad
   - Valida que la cantidad sea positiva
   - Registra fecha de actualización

### Manejo de Errores
- Traduce errores de Firebase a mensajes amigables
- Maneja casos específicos como:
  - Permisos denegados
  - Documento no encontrado
  - Errores generales de Firestore
