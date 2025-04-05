# Servicios

## IntermedioRequeridoService

Servicio que maneja las operaciones CRUD y la lógica de negocio para los intermedios requeridos en Firestore.

### Dependencias
- `FirebaseFirestore`: Para operaciones con la base de datos
- `IntermedioService`: Para validar la existencia de intermedios base

### Colección
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
