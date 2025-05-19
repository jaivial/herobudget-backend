# Estructura del Proyecto Hero Budget

## Visión General

Hero Budget es una aplicación de gestión financiera personal desarrollada con Flutter. Este documento describe la estructura de archivos del proyecto y define la funcionalidad y relación entre ellos.

## Estructura de Directorios

```
hero_budget/
├── lib/                        # Código fuente principal de Dart/Flutter
│   ├── config/                 # Configuraciones de la aplicación
│   ├── examples/               # Ejemplos de código
│   ├── models/                 # Modelos de datos
│   ├── screens/                # Pantallas de la aplicación
│   ├── services/               # Servicios para lógica de negocio y comunicación con API
│   ├── theme/                  # Definición de temas y estilos
│   ├── utils/                  # Utilidades y helpers
│   ├── widgets/                # Widgets reutilizables
│   └── main.dart               # Punto de entrada de la aplicación
├── assets/                     # Recursos estáticos (imágenes, fuentes, etc.)
│   ├── images/                 # Imágenes y gráficos
│   ├── avatars/                # Imágenes de avatar para perfiles
│   ├── lang/                   # Archivos de idioma
│   └── l10n/                   # Localización
├── backend/                    # Código backend (Go)
│   ├── money_flow_sync/        # Sincronización de flujo de dinero
│   ├── categories_management/  # Gestión de categorías
│   ├── expense_management/     # Gestión de gastos
│   ├── income_management/      # Gestión de ingresos
│   ├── profile_management/     # Gestión de perfiles
│   ├── ... (otros módulos backend)
│   ├── schema.sql              # Definición del schema de base de datos
│   ├── go.mod                  # Dependencias de Go
│   └── main.go                 # Punto de entrada del backend
├── screens/                    # Posible duplicado o estructura alternativa de pantallas
├── ios/                        # Configuración específica de iOS
├── android/                    # Configuración específica de Android
├── macos/                      # Configuración específica de macOS
├── linux/                      # Configuración específica de Linux
├── windows/                    # Configuración específica de Windows
├── web/                        # Configuración específica de web
├── test/                       # Pruebas automatizadas
├── docs/                       # Documentación del proyecto
│   ├── UI_UX_GUIDE.md          # Guía de estilo UI/UX
│   ├── DATABASE_SCHEMA.md      # Documentación de la base de datos
│   ├── PROJECT_STRUCTURE.md    # Este documento
│   └── CHANGELOG.md            # Registro de cambios
├── pubspec.yaml                # Configuración y dependencias de Flutter
└── pubspec.lock                # Versiones específicas de dependencias
```

## Componentes Principales

### Frontend (Flutter)

#### 1. Models (`lib/models/`)
Contiene las clases de modelo que representan las entidades de datos de la aplicación.

- `category_model.dart`: Define la estructura de las categorías (gastos e ingresos).
- `expense_model.dart`: Define la estructura de los gastos.
- `income_model.dart`: Define la estructura de los ingresos.
- `user_model.dart`: Define la estructura de los usuarios.
- `dashboard_model.dart`: Modelo para la pantalla principal del dashboard.

#### 2. Screens (`lib/screens/`)
Contiene las pantallas principales de la aplicación, organizadas por funcionalidad.

- `auth/`: Pantallas de autenticación (login, registro).
- `dashboard/`: Pantalla principal con resumen financiero.
- `category/`: Gestión de categorías.
- `expense/`: Gestión de gastos.
- `income/`: Gestión de ingresos.
- `profile/`: Perfil del usuario.
- `savings/`: Gestión de ahorros.
- `recurring_bills/`: Gestión de facturas recurrentes.
- `verification/`: Verificación de cuenta.
- `reset_password/`: Proceso de restablecimiento de contraseña.
- `onboarding/`: Pantallas de introducción.
- `settings/`: Configuración de la aplicación.

#### 3. Services (`lib/services/`)
Contiene los servicios que implementan la lógica de negocio y la comunicación con el backend.

- `auth_service.dart`: Gestiona la autenticación de usuarios.
- `category_service.dart`: Gestiona las operaciones CRUD de categorías.
- `expense_service.dart`: Gestiona las operaciones CRUD de gastos.
- `income_service.dart`: Gestiona las operaciones CRUD de ingresos.
- `profile_service.dart`: Gestiona las operaciones del perfil de usuario.
- `dashboard_service.dart`: Gestiona los datos para el dashboard.
- `language_service.dart`: Gestiona la configuración de idioma.
- `savings_service.dart`: Gestiona las operaciones de ahorros.
- `bills_service.dart`: Gestiona las operaciones de facturas recurrentes.
- `api_helper.dart`: Utilidad para comunicación con la API.

#### 4. Theme (`lib/theme/`)
Define la apariencia visual de la aplicación.

- `app_theme.dart`: Definición de temas (claro/oscuro), colores y estilos.

#### 5. Widgets (`lib/widgets/`)
Contiene widgets reutilizables en toda la aplicación.

#### 6. Utils (`lib/utils/`)
Contiene utilidades y funciones helper.

### Backend (Go)

La estructura del backend está organizada por dominios funcionales:

- `money_flow_sync/`: Sincronización de flujos monetarios.
- `categories_management/`: Gestión de categorías.
- `expense_management/`: Gestión de gastos.
- `income_management/`: Gestión de ingresos.
- `profile_management/`: Gestión de perfiles de usuario.
- `bills_management/`: Gestión de facturas.
- `savings_management/`: Gestión de ahorros.
- `budget_management/`: Gestión de presupuestos.
- `dashboard_data/`: Generación de datos para dashboard.
- `signin/`, `signup/`: Autenticación de usuarios.
- `reset_password/`: Restablecimiento de contraseña.

## Flujo de Datos y Relaciones

1. **Flujo de datos frontend**:
   - Las pantallas (`screens`) utilizan widgets personalizados (`widgets`) para la interfaz.
   - Los servicios (`services`) proporcionan datos y funcionalidad a las pantallas.
   - Los servicios interactúan con los modelos (`models`) para manejar la estructura de datos.
   - Los temas (`theme`) controlan la apariencia visual de toda la aplicación.

2. **Comunicación frontend-backend**:
   - Los servicios en el frontend se comunican con el backend a través de API REST.
   - `api_helper.dart` proporciona funciones para simplificar las llamadas API.

3. **Flujo de datos backend**:
   - Los módulos del backend procesan solicitudes API.
   - Las operaciones CRUD interactúan con la base de datos SQLite.
   - `schema.sql` define la estructura de la base de datos.

## Convenciones y Directrices

1. **Nomenclatura**:
   - Archivos Dart: snake_case (ejemplo: `user_model.dart`)
   - Clases: PascalCase (ejemplo: `UserModel`)
   - Funciones y variables: camelCase (ejemplo: `getUserData()`)

2. **Estructura modular**:
   - Cada funcionalidad debe estar en su carpeta correspondiente.
   - Los servicios deben tener una responsabilidad única.
   - Los widgets reutilizables deben estar en la carpeta `widgets/`.

3. **Gestión de estado**:
   - Preferir soluciones simples para gestión de estado.
   - Mantener la lógica de estado separada de la UI.

4. **Localización**:
   - Todo el texto visible debe estar localizado.
   - Usar los archivos en `assets/lang/` y `assets/l10n/`.

## Proceso de Desarrollo

1. **Añadir nueva funcionalidad**:
   - Crear modelos de datos si es necesario.
   - Implementar servicios para la lógica de negocio.
   - Crear pantallas y widgets para la interfaz.
   - Implementar la funcionalidad correspondiente en el backend.

2. **Modificar funcionalidad existente**:
   - Localizar los componentes relevantes.
   - Modificar manteniendo la cohesión y acoplamiento bajo.
   - Actualizar la documentación pertinente.

## Recursos Relacionados

- `docs/UI_UX_GUIDE.md`: Guía de estilo y diseño visual.
- `docs/DATABASE_SCHEMA.md`: Documentación de la estructura de la base de datos.
- `docs/CHANGELOG.md`: Historial de cambios en el proyecto.

---
Última actualización: [Fecha actual] 