
# Catering App - Sistema de Gestión para Catering y Eventos

## Descripción General
**Catering App** es una aplicación integral de gestión para negocios de catering y eventos, desarrollada con Flutter y Firebase. La plataforma permite una administración detallada del ciclo de vida de un evento, desde la creación de menús complejos y el cálculo de costos, hasta la planificación de la producción y la generación de reportes, todo dentro de una interfaz adaptable y moderna.

El proyecto está diseñado para funcionar en un modo **single-tenant** (para un cliente específico) o en un modo **multi-tenant** (ideal para demos de portafolio), donde cada usuario opera en un entorno de datos aislado y seguro (sandbox).

## Objetivos
-   **Gestión Centralizada de Catálogos:** Administrar platos, preparaciones intermedias, insumos y proveedores.
-   **Planificación de Eventos:** Crear, personalizar y gestionar eventos, desde la cotización hasta la ejecución.
-   **Cálculo de Producción:** Generar listas de compras detalladas y agrupadas por proveedor a partir de los requerimientos de uno o múltiples eventos.
-   **Análisis de Costos:** Calcular costos estimados de producción basados en recetas y precios de insumos.
-   **Exportación de Datos:** Generar documentos profesionales (PDF, Excel) para uso interno y para clientes.

## Arquitectura

### Patrón de Diseño
La aplicación sigue una arquitectura limpia basada en **Capas de Responsabilidad**, inspirada en patrones como **MVVM (Model-View-ViewModel) / MVC-S (Model-View-Controller-Service)**:

1.  **Models**: Clases de datos inmutables con lógica de serialización (`fromFirestore`, `toFirestore`).
2.  **UI (Views/Screens & Widgets)**: Componentes de Flutter que renderizan el estado y capturan la interacción del usuario. Se prioriza la creación de widgets genéricos y reutilizables (`GenericListView`, `ListaComponentesRequeridos`).
3.  **Controllers (`ChangeNotifier`)**: Gestionan el estado de la UI, orquestan las acciones del usuario y actúan como puente entre la UI y las capas inferiores.
4.  **Repositories**: Abstraen el acceso a la fuente de datos. Definen un "contrato" (interfaz `abstract class`) que es implementado por una clase concreta (ej. `PlatoFirestoreRepository`).
5.  **Services**: Encapsulan lógica de negocio compleja que no pertenece a un controlador específico, como `ShoppingListService` o `ExcelExportServiceSync`.

### Estructura del Proyecto
```
lib/
├── config/             # Configuración de la app (Flavors, Firebase Options)
├── features/           # Módulos de la aplicación (Eventos, Catálogos, etc.)
│   ├── common/         # Widgets, helpers y mixins compartidos
│   ├── eventos/
│   │   ├── actions/    # Lógica de acciones específicas (ej. generar lista de compras)
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── screens/
│   │   └── widgets/
│   └── ...             # Otras features (catalogos, dashboard, etc.)
├── models/             # Modelos de datos principales y de relación
├── navigation/         # Lógica de navegación (rutas, MainScaffold, Rail/Bottom Nav)
├── repositories/       # Implementaciones concretas de repositorios (Firestore)
└── services/           # Servicios de lógica de negocio
```

## Componentes y Funcionalidades Clave

### 1. Sistema de Catálogos Jerárquico
-   **Insumos:** Materias primas con unidad, precio y proveedor.
-   **Intermedios:** Preparaciones base (salsas, masas) compuestas por insumos. Tienen una `cantidadEstandar` para cálculos de proporción.
-   **Platos:** Productos finales compuestos por insumos y/o intermedios. Tienen `porcionesMinimas` para estandarizar recetas.

### 2. Gestión Avanzada de Eventos
-   **CRUD de Eventos:** Ciclo de vida completo con estados (En Cotización, Confirmado, etc.).
-   **Personalización de Platos por Evento:** Un plato en un evento (`PlatoEvento`) puede ser modificado sin alterar la receta original:
    -   **Remover** insumos o intermedios base.
    -   **Añadir** insumos o intermedios "extra" con cantidades específicas.
    -   Asignar un **nombre personalizado**.
-   **Calendario Interactivo:** Visualización de eventos en un calendario (`table_calendar`) con selección de día y vista de detalles.
-   **Selección Múltiple:** Las vistas de lista y calendario permiten seleccionar múltiples eventos para realizar acciones en lote.

### 3. Motor de Lista de Compras (`ShoppingListService`)
-   **Cálculo Recursivo:** "Desenrolla" jerárquicamente todos los componentes de uno o múltiples eventos para obtener una lista consolidada de insumos.
-   **Manejo de Proporciones:** Utiliza `porcionesMinimas` y `cantidadEstandar` para calcular correctamente las cantidades requeridas.
-   **Aplicación de Personalizaciones:** Considera los items removidos y extra de cada plato en el cálculo.
-   **Desglose por Facturabilidad:** Capaz de calcular y separar los insumos requeridos para eventos facturables y no facturables.
-   **Agrupación por Proveedor:** Agrupa la lista final de insumos por su proveedor asignado, facilitando las órdenes de compra.

### 4. Exportación de Datos (`ExcelExportServiceSync`)
-   **Generación de Archivos Excel (.xlsx):** Utiliza `syncfusion_flutter_xlsio` para crear reportes profesionales.
-   **Múltiples Hojas:** Genera un único archivo con una hoja de resumen general y hojas de detalle para cada proveedor.
-   **Formatos Flexibles:** Permite exportar la lista de compras combinada o con un desglose visual por facturabilidad.
-   **Guardado Multiplataforma:** Usa un helper (`file_saver`) con exportación condicional para permitir al usuario guardar el archivo en su dispositivo, tanto en plataformas nativas como en web.

## Tecnologías y Prácticas

-   **Framework:** Flutter (multiplataforma: Windows, Web, Android, iOS).
-   **Backend:** Firebase (Firestore, Authentication).
-   **Gestión de Estado:** `provider`.
-   **Navegación:** `Navigator 2.0` con rutas nombradas (`AppRoutes`), `MainScaffold` adaptable con `NavigationRail` (escritorio/tablet) y `BottomNavigationBar` (móvil).
-   **"Flavors" (Entornos):** Configuración robusta para `dev`, `prod` y `portfolio`, utilizando archivos `main_...dart` separados y `AppConfig` para gestionar diferentes configuraciones de Firebase y comportamiento de la aplicación.
-   **Principios de Código:**
    -   **DRY (Don't Repeat Yourself):** A través de widgets genéricos, servicios reutilizables y `mixin`s para lógica compartida.
    -   **Separación de Responsabilidades:** Capas bien definidas (UI, Controller, Service, Repository).
    -   **Inyección de Dependencias:** Uso de `MultiProvider` para inyectar controladores y servicios en el árbol de widgets.

## Roadmap

1.  **Fase 1 (Completada)**
    -   CRUD completo y consistente para todos los catálogos (Platos, Insumos, etc.).
    -   Gestión avanzada de Eventos con personalización.
    -   Motor de cálculo de lista de compras.
    -   Exportación a Excel con formatos complejos.
    -   UI responsive y sistema de "Flavors" funcional.

2.  **Fase 2 (Siguientes Pasos)**
    -   **Facturación:** Generar facturas o proformas a partir de un evento.
    -   **Gestión de Inventario:** Control de stock de insumos.
    -   **Reportes Avanzados:** Dashboards con más métricas y reportes históricos.
    -   **Integración con Google Calendar:** Sincronizar eventos.

3.  **Fase 3 (Futuro)**
    -   **Análisis de Rentabilidad:** Comparar costos estimados vs. reales.
    -   **Integración con POS:** Conectar con sistemas de punto de venta.

