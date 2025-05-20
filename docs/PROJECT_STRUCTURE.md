# Estructura del Proyecto Hero Budget

## Visión General

Hero Budget es una aplicación de gestión financiera personal desarrollada con Flutter para el frontend y Go para los microservicios backend. La aplicación está diseñada con una arquitectura modular que separa las diferentes funcionalidades en servicios independientes.

## Estructura de Directorios

```
hero_budget/
├── backend/                   # Servicios backend en Go
│   ├── google_auth/           # Servicio de autenticación
│   │   ├── main.go            # Punto de entrada del servicio
│   │   └── users.db           # Base de datos SQLite
│   ├── income_management/     # Servicio de gestión de ingresos
│   │   └── main.go            # Lógica para manejar ingresos
│   ├── expense_management/    # Servicio de gestión de gastos
│   │   └── main.go            # Lógica para manejar gastos
│   ├── bills_management/      # Servicio de gestión de facturas
│   │   └── main.go            # Lógica para manejar facturas
│   └── ...
├── lib/                       # Código Flutter para el frontend
│   ├── main.dart              # Punto de entrada de la aplicación
│   ├── models/                # Modelos de datos
│   ├── screens/               # Pantallas de la aplicación
│   ├── widgets/               # Widgets reutilizables
│   ├── services/              # Servicios de conexión con backend
│   └── ...
├── docs/                      # Documentación del proyecto
│   ├── DATABASE_SCHEMA.md     # Esquema de la base de datos
│   ├── CHANGELOG.md           # Registro de cambios
│   └── PROJECT_STRUCTURE.md   # Este archivo
└── ...
```

## Componentes Backend

### Servicio de Autenticación (`google_auth`)

El servicio de autenticación maneja el registro y login de usuarios, principalmente a través de Google OAuth. También es responsable de mantener la base de datos SQLite `users.db` que contiene todas las tablas del sistema.

### Servicio de Gestión de Ingresos (`income_management`)

Maneja todo lo relacionado con los ingresos de los usuarios:

- Registro de nuevos ingresos
- Actualización de ingresos existentes
- Eliminación de ingresos
- Actualización de balances generales
- **Actualización de balances por periodos**

El servicio ahora incluye funciones para actualizar automáticamente los balances por diferentes periodos de tiempo cuando se registra un ingreso:

- `updateTimeBalances`: Función principal que coordina la actualización en todos los periodos
- `updateDailyBalance`: Actualiza el balance diario
- `updateWeeklyBalance`: Actualiza el balance semanal
- `updateMonthlyBalance`: Actualiza el balance mensual
- `updateQuarterlyBalance`: Actualiza el balance trimestral
- `updateSemiannualBalance`: Actualiza el balance semestral
- `updateAnnualBalance`: Actualiza el balance anual

### Servicio de Gestión de Gastos (`expense_management`)

Similar al servicio de ingresos, pero especializado en gastos:

- Registro de nuevos gastos
- Actualización de gastos existentes
- Eliminación de gastos
- Actualización de balances generales
- **Actualización de balances por periodos**

La estructura de funciones para actualizar balances es idéntica a la del servicio de ingresos, pero adaptada para trabajar con gastos.

### Servicio de Gestión de Facturas (`bills_management`)

Maneja las facturas recurrentes y no recurrentes:

- Creación de nuevas facturas
- Actualización de facturas existentes
- Marcar facturas como pagadas
- Eliminación de facturas
- **Actualización de balances por periodos**

Las facturas pagadas también actualizan los balances por periodos, utilizando el mismo conjunto de funciones que los otros servicios.

## Base de Datos

La aplicación utiliza SQLite como motor de base de datos. El archivo `users.db` contiene todas las tablas necesarias para el funcionamiento de la aplicación.

### Tablas de Balance por Periodo

Las nuevas tablas para el seguimiento de balances por periodos son:

1. `daily_balance`: Balance diario
2. `weekly_balance`: Balance semanal
3. `monthly_balance`: Balance mensual
4. `quarterly_balance`: Balance trimestral
5. `semiannual_balance`: Balance semestral
6. `annual_balance`: Balance anual

Cada tabla almacena la información de ingresos, gastos y facturas para su respectivo periodo, junto con el balance acumulado que incluye el saldo del periodo anterior.

## Flujo de Datos

El flujo de datos para la actualización de balances por periodos es el siguiente:

1. El usuario realiza una acción (agregar ingreso, agregar gasto, pagar factura) desde la aplicación móvil.
2. La aplicación envía la información al microservicio correspondiente.
3. El microservicio procesa la solicitud y realiza las siguientes acciones:
   - Registra la transacción en su tabla específica (incomes, expenses, bills)
   - Actualiza el balance general del usuario (tabla balances)
   - Actualiza la distribución efectivo-banco si corresponde (tabla cash_bank)
   - Llama a la función `updateTimeBalances` para actualizar los balances por periodos
4. La función `updateTimeBalances` identifica a qué periodos corresponde la transacción según su fecha y actualiza las tablas correspondientes.
5. Para cada periodo, se calcula el nuevo balance sumando el balance del periodo anterior y las transacciones del periodo actual.
6. La aplicación móvil puede consultar los balances de cualquier periodo y mostrarlos al usuario.

## Cálculo de Balances

Para cada periodo, el balance se calcula de la siguiente manera:

```
Balance = BalanceAnterior + Ingresos - Gastos - Facturas
```

Donde:
- `BalanceAnterior` es el balance acumulado del periodo inmediatamente anterior
- `Ingresos` es la suma de todos los ingresos del periodo actual
- `Gastos` es la suma de todos los gastos del periodo actual
- `Facturas` es la suma de todas las facturas pagadas del periodo actual

## Consideraciones de Rendimiento

- Las tablas cuentan con índices optimizados para mejorar el rendimiento de las consultas frecuentes.
- Las actualizaciones de balances se realizan de forma incremental para evitar recalcular todos los datos cada vez.
- Las operaciones de base de datos utilizan transacciones para garantizar la integridad de los datos.

## Extensiones Futuras

La estructura modular del proyecto permite agregar fácilmente nuevas funcionalidades o modificar las existentes. Algunas posibles extensiones incluyen:

- Integración con servicios bancarios para sincronización automática
- Exportación de informes financieros por periodos
- Sistema de metas de ahorro por periodos
- Análisis predictivo basado en tendencias históricas

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