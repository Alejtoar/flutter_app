# Modelos

## IntermedioRequerido

Representa un ingrediente intermedio requerido para la preparación de un plato.

### Atributos
- `id` (String?, opcional): Identificador único del documento en Firestore
- `intermedioId` (String): ID del ingrediente intermedio base
- `codigo` (String): Código identificador
- `nombre` (String): Nombre del ingrediente intermedio
- `cantidad` (double): Cantidad requerida
- `instruccionesEspeciales` (String?, opcional): Instrucciones especiales para la preparación
- `fechaCreacion` (DateTime): Fecha de creación del registro
- `orden` (int): Orden de presentación/preparación

### Métodos
- `crear`: Factory constructor con validación de campos
- `fromFirestore`: Constructor para crear instancia desde documento Firestore
- `fromMap`: Constructor para crear instancia desde Map
- `toFirestore`: Convierte la instancia a Map para Firestore
- `copyWith`: Crea una copia con campos actualizados
- `==` y `hashCode`: Implementación de equidad
- `toString`: Representación en string del objeto

### Validaciones
- `intermedioId` no puede estar vacío
- `codigo` no puede estar vacío
- `nombre` no puede estar vacío
- `cantidad` debe ser positiva
