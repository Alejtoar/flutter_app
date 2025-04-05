# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-04-05

### Añadido
- Estructura inicial del proyecto con arquitectura MVVM
- Implementación de modelos base (Plato, Evento, etc.)
- Servicios para interacción con Firebase
- ViewModels para gestión de estado
- UI básica con navegación
- Documentación inicial

### Modelos
- Plato: Modelo para gestión de platos y recetas
- Evento: Modelo para gestión de eventos y reservaciones
- IntermedioRequerido: Modelo para componentes intermedios
- CostoProduccion: Modelo para cálculo de costos

### Servicios
- PlatoService: CRUD y lógica de negocio para platos
- EventoService: Gestión de eventos y reservaciones
- FirebaseService: Integración con Firebase

### ViewModels
- PlatoViewModel: Gestión de estado para platos
- EventoViewModel: Gestión de estado para eventos
- NavigationViewModel: Control de navegación

### UI
- Implementación de AdminScaffold
- Navegación adaptativa
- Pantallas principales estructuradas

### Documentación
- README.md con visión general del proyecto
- Documentación de arquitectura
- Guías de configuración
- Documentación de API
- Guías de testing

## [0.0.1] - 2025-04-01

### Añadido
- Inicialización del proyecto Flutter
- Configuración básica de Firebase
- Estructura de directorios inicial
- Dependencias principales
