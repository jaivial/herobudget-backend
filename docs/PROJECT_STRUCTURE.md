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

### Servicio de Obtención de Datos Presupuestarios (`budget_overview_fetch`)

Este servicio se encarga de obtener y procesar datos financieros agregados y transacciones individuales:

**Funcionalidades principales:**
- **Resumen presupuestario por períodos**: Obtiene datos agregados de balance, gastos, ingresos y facturas para diferentes períodos (diario, semanal, mensual, trimestral, semestral, anual)
- **Historial de transacciones**: Proporciona acceso unificado a todas las transacciones (ingresos, gastos, facturas pagadas) con filtros por período, tipo de transacción y método de pago
- **Próximas facturas**: Lista las facturas pendientes de pago con categorización por urgencia (vencidas, próximas, esta semana, este mes)

**Endpoints disponibles:**
- `POST /budget-overview`: Obtiene el resumen presupuestario para un período específico
- `POST /transactions/history`: Obtiene el historial de transacciones con filtros opcionales
- `POST /transactions/upcoming-bills`: Obtiene las facturas pendientes de pago
- `GET /health`: Verificación de estado del servicio

**Características técnicas:**
- **Herencia de datos**: Si no hay datos para un período solicitado, busca automáticamente en períodos anteriores
- **Paginación**: Soporte para paginación en consultas de transacciones (límite máximo: 1000 registros)
- **Filtros flexibles**: Permite filtrar por tipo de transacción, método de pago y rangos de fechas
- **Respuestas unificadas**: Estructura consistente de respuestas JSON con metadatos de paginación y estado

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
- `language_service.dart`: Gestiona las preferencias de idioma y localización.
- `language_update_service.dart`: Actualiza el idioma del usuario en la base de datos.
- `dashboard_service.dart`: Obtiene datos del dashboard financiero.
- `category_service.dart`: Gestiona las categorías de ingresos y gastos.
- `expense_service.dart`: Gestiona los gastos del usuario.
- `income_service.dart`: Gestiona los ingresos del usuario.
- `bills_service.dart`: Gestiona las facturas recurrentes.
- `savings_service.dart`: Gestiona las metas de ahorro.
- `signin_service.dart`: Manejo de inicio de sesión manual
- `verification_service.dart`: Manejo de verificación de email y códigos OTP

#### 4. Widgets (`lib/widgets/`)
Contiene widgets reutilizables específicos de la aplicación, organizados por funcionalidad.

**Estados de Carga (Enero 2025):**
- `loading_screen.dart`: Pantalla completa de carga con efectos de fade in/out elegantes
- `skeleton_loader.dart`: Placeholders animados con efecto shimmer para contenido en carga
- `loading_overlay.dart`: Wrapper universal para aplicar loading states a cualquier widget

**Navegación y Layout:**
- `app_header.dart`: Cabecera principal de la aplicación
- `app_bottom_navigation.dart`: Navegación inferior
- `quick_actions.dart`: Botones de acciones rápidas

**Visualización de Datos:**
- `budget_overview.dart`: Widget principal del resumen presupuestario
- `transaction_overview_widget.dart`: Overview de transacciones y facturas
- `finance_metrics.dart`: Métricas financieras
- `savings_overview.dart`: Resumen de ahorros

**Componentes de UI Especializados:**
- `period_selector.dart`: Selector de períodos temporales
- `transfer_modal.dart`: Modal para transferencias entre efectivo y banco
- `transaction_history_table.dart`: Tabla de historial de transacciones
- `upcoming_bills.dart`: Widget de facturas próximas

**Localización y Temas:**
- `language_selector_widget.dart`: Selector de idioma
- `theme_toggle_button.dart`: Botón para cambiar tema oscuro/claro
- `localized_text.dart`: Componentes de texto localizado

#### 5. Utils (`lib/utils/`)
Contiene utilidades y helpers para funcionalidades comunes.

#### 6. Config (`lib/config/`)
Configuración de la aplicación, incluyendo APIs y constantes.

#### 7. Theme (`lib/theme/`)
Configuración de temas, colores y estilos de la aplicación.

## Sistema de Localización

### Arquitectura de Traducciones

La aplicación implementa un sistema completo de localización que soporta 14 idiomas diferentes:

#### Componentes Principales:

1. **AppLocalizations** (`lib/utils/app_localizations.dart`):
   - Clase principal que maneja la carga y acceso a las traducciones
   - Implementa fallback automático a inglés para claves faltantes
   - Soporte para pluralización y parámetros dinámicos
   - Formateo de fechas y monedas según el idioma

2. **LanguageService** (`lib/services/language_service.dart`):
   - Gestiona las preferencias de idioma del usuario
   - Detecta automáticamente el idioma del dispositivo
   - Sincroniza preferencias con el servidor cuando está disponible
   - Almacena preferencias localmente en SharedPreferences

3. **Extensiones de Contexto** (`lib/utils/extensions.dart`):
   - Proporciona acceso fácil a traducciones mediante `context.tr.translate()`
   - Simplifica el uso del sistema de localización en widgets

#### Flujo de Detección de Idioma:

1. **Inicio de la aplicación**: Se verifica si existe una preferencia guardada
2. **Sin preferencia guardada**: Se detecta el idioma del dispositivo
3. **Idioma soportado**: Se usa el idioma detectado
4. **Idioma no soportado**: Se usa inglés como fallback
5. **Usuario autenticado**: Se sincroniza con la preferencia del servidor

#### Resolución de Problemas Comunes:

- **Pantallas en inglés únicamente**: Verificar que todas las claves de traducción existan en todos los archivos de idioma
- **Configuración incorrecta**: Asegurar que `MaterialApp.locale` esté correctamente configurado
- **Claves faltantes**: El sistema automáticamente usa inglés como fallback

#### Mantenimiento de Traducciones:

- Todas las claves deben existir en el archivo base `en.json`
- Los archivos de idioma deben mantenerse sincronizados
- Las nuevas funcionalidades requieren traducciones en todos los idiomas soportados
- Se recomienda usar herramientas de validación para verificar completitud

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

## Servicios de Autenticación

### SignInService (`lib/services/signin_service.dart`)
- **Función principal**: Manejo de inicio de sesión manual
- **Cambios recientes**: 
  - Detección mejorada de cuentas no verificadas
  - Retorno de información detallada sobre estado de verificación
  - Manejo de errores específicos para email no verificado

### VerificationService (`lib/services/verification_service.dart`)
- **Función principal**: Manejo de verificación de email y códigos OTP
- **Funcionalidades**:
  - Envío de códigos de verificación
  - Verificación de códigos OTP
  - Reenvío automático de códigos

### AuthService (`lib/services/auth_service.dart`)
- **Función principal**: Autenticación con Google y registro de usuarios
- **Relación**: Trabaja en conjunto con SignInService para autenticación completa

## Pantallas de Verificación

### EmailOTPVerificationScreen (`lib/screens/verification/email_otp_verification_screen.dart`)
- **Propósito**: Verificación obligatoria de email mediante código OTP
- **Características**:
  - Envío automático de código al inicializar
  - Interfaz de 6 dígitos para código OTP
  - Reenvío con cooldown de 60 segundos
  - Verificación automática al completar código

### Flujo de Navegación Actualizado
```
Inicio de App
├── Usuario con sesión guardada
│   ├── Email verificado → Dashboard
│   └── Email NO verificado → EmailOTPVerificationScreen
└── Usuario sin sesión → OnboardingScreen
    └── Login manual
        ├── Credenciales válidas + Email verificado → Dashboard
        └── Credenciales válidas + Email NO verificado → EmailOTPVerificationScreen
```

## Archivos Principales Modificados

### `lib/main.dart`
- **Cambios**: 
  - Verificación automática de estado de email en `_checkUserStatus()`
  - Navegación condicional basada en verificación
  - Envío automático de códigos OTP para cuentas no verificadas

### `lib/screens/auth/signin_screen.dart`
- **Cambios**:
  - Manejo mejorado de errores de verificación
  - Navegación automática a verificación OTP
  - Eliminación de errores genéricos para cuentas no verificadas

---
Última actualización: [Fecha actual] 