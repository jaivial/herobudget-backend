# Estructura del Proyecto Hero Budget (Parte 2: Frontend Flutter)

## Descripción

Esta es la parte 2 de la documentación de estructura del proyecto que cubre el frontend Flutter y sus componentes.

## Archivos Relacionados

- [PROJECT_STRUCTURE_part1.md](PROJECT_STRUCTURE_part1.md) - Backend y arquitectura

## Estructura de Directorios Frontend

```
hero_budget/lib/
├── main.dart              # Punto de entrada de la aplicación
├── models/                # Modelos de datos
│   ├── category_model.dart
│   ├── expense_model.dart
│   ├── income_model.dart
│   ├── user_model.dart
│   └── dashboard_model.dart
├── screens/               # Pantallas de la aplicación
│   ├── auth/              # Autenticación
│   ├── dashboard/         # Dashboard principal
│   ├── category/          # Gestión de categorías
│   ├── expense/           # Gestión de gastos
│   ├── income/            # Gestión de ingresos
│   ├── profile/           # Perfil del usuario
│   ├── savings/           # Gestión de ahorros
│   ├── recurring_bills/   # Gestión de facturas
│   ├── verification/      # Verificación de cuenta
│   ├── reset_password/    # Restablecimiento de contraseña
│   ├── onboarding/        # Introducción
│   └── settings/          # Configuración
├── widgets/               # Widgets reutilizables
│   ├── period_selector_monthly.dart  # Selector mensual (nuevo)
│   ├── monthly_navigation.dart       # Navegación mensual (nuevo)
│   ├── budget_overview_monthly.dart  # Overview mensual (nuevo)
│   ├── budget_overview_animations.dart # Animaciones (nuevo)
│   └── ...
├── services/              # Servicios de conexión con backend
│   ├── auth_service.dart
│   ├── budget_overview_service.dart
│   ├── monthly_date_service.dart     # Servicio de fechas mensuales (nuevo)
│   └── ...
└── docs/                  # Documentación del proyecto
    ├── DATABASE_SCHEMA_part*.md
    ├── CHANGELOG_part*.md
    └── PROJECT_STRUCTURE_part*.md
```

## Componentes Principales del Frontend

### 1. Models (`lib/models/`)
Contiene las clases de modelo que representan las entidades de datos de la aplicación.

- `category_model.dart`: Define la estructura de las categorías (gastos e ingresos)
- `expense_model.dart`: Define la estructura de los gastos
- `income_model.dart`: Define la estructura de los ingresos
- `user_model.dart`: Define la estructura de los usuarios
- `dashboard_model.dart`: Modelo para la pantalla principal del dashboard

### 2. Screens (`lib/screens/`)
Contiene las pantallas principales de la aplicación, organizadas por funcionalidad.

- `auth/`: Pantallas de autenticación (login, registro)
- `dashboard/`: Pantalla principal con resumen financiero mensual
- `category/`: Gestión de categorías
- `expense/`: Gestión de gastos
- `income/`: Gestión de ingresos
- `profile/`: Perfil del usuario
- `savings/`: Gestión de ahorros mensuales
- `recurring_bills/`: Gestión de facturas recurrentes
- `verification/`: Verificación de cuenta
- `reset_password/`: Proceso de restablecimiento de contraseña
- `onboarding/`: Pantallas de introducción
- `settings/`: Configuración de la aplicación

### 3. Services (`lib/services/`)
Contiene los servicios que implementan la lógica de negocio y comunicación con el backend.

**Servicios principales:**
- `auth_service.dart`: Gestiona la autenticación de usuarios
- `budget_overview_service.dart`: Obtiene datos del presupuesto mensual del backend
- `monthly_date_service.dart`: **[NUEVO]** Maneja cálculos y formateo de fechas mensuales
- `income_service.dart`: Comunicación con el servicio de ingresos
- `expense_service.dart`: Comunicación con el servicio de gastos
- `bills_service.dart`: Comunicación con el servicio de facturas

**Servicios simplificados tras migración:**
- Eliminación de lógica para períodos no mensuales
- Simplificación de parámetros de API
- Enfoque exclusivo en datos mensuales

### 4. Widgets (`lib/widgets/`)
Contiene widgets reutilizables específicos de la aplicación.

**Widgets principales (tras refactorización):**
- `period_selector_monthly.dart`: **[NUEVO]** Selector simplificado solo para navegación mensual
- `monthly_navigation.dart`: **[NUEVO]** Componente de navegación mes anterior/siguiente
- `budget_overview_monthly.dart`: **[NUEVO]** Widget principal de overview simplificado para mensual
- `budget_overview_animations.dart`: **[NUEVO]** Separación de lógica de animaciones
- `savings_overview.dart`: Widget de overview de ahorros mensuales
- `cash_bank_distribution.dart`: Widget de distribución efectivo-banco mensual

**Widgets eliminados tras refactorización:**
- `budget_overview_with_period.dart`: Reemplazado por componentes más pequeños
- `period_selector.dart`: Reemplazado por selector mensual simplificado

## Widgets Específicos Nuevos

### PeriodSelectorMonthly
**Ubicación:** `lib/widgets/period_selector_monthly.dart`
**Propósito:** Selector simplificado que solo permite navegación mensual
**Características:**
- Solo muestra navegación anterior/siguiente mes
- Formato de fecha consistente (MMM yyyy)
- Límites de navegación (10 años atrás, 5 años adelante)

### MonthlyNavigation  
**Ubicación:** `lib/widgets/monthly_navigation.dart`
**Propósito:** Componente dedicado para navegación entre meses
**Características:**
- Botones anterior/siguiente
- Validación de fechas límite
- Animaciones de transición

### BudgetOverviewMonthly
**Ubicación:** `lib/widgets/budget_overview_monthly.dart`
**Propósito:** Widget principal de overview simplificado
**Características:**
- Lógica específica para datos mensuales
- Integración con servicios mensuales
- Máximo 200 líneas

### BudgetOverviewAnimations
**Ubicación:** `lib/widgets/budget_overview_animations.dart`
**Propósito:** Lógica de animaciones separada
**Características:**
- Animaciones de slide y fade
- Controllers de animación
- Máximo 200 líneas

### MonthlyDateService
**Ubicación:** `lib/services/monthly_date_service.dart`
**Propósito:** Servicio específico para manejo de fechas mensuales
**Características:**
- Formateo de fechas mensuales
- Cálculos de mes anterior/siguiente
- Validaciones de rango
- Conversiones de formato

## Arquitectura Simplificada

### Flujo de Datos Frontend
1. **Usuario interactúa** con PeriodSelectorMonthly
2. **MonthlyNavigation** maneja cambios de mes
3. **BudgetOverviewMonthly** solicita datos vía BudgetOverviewService
4. **Servicio** obtiene datos del backend (solo monthly_cash_bank_balance)
5. **Widget** muestra datos con animaciones de BudgetOverviewAnimations

### Comunicación con Backend
- Todas las llamadas API especifican `period: "monthly"`
- Fechas en formato `YYYY-MM` exclusivamente
- Eliminación de parámetros de período en requests
- Simplificación de respuestas (solo datos mensuales)

## Localización
- **Arquitectura**: Sistema basado en JSON con archivos en `assets/l10n/`
- **Idiomas Soportados**: 14 idiomas
- **Implementación**: `AppLocalizations` con extensión `context.tr.translate()`
- **Detección**: Automática del idioma del dispositivo con fallback a inglés

## Consideraciones de Rendimiento Frontend
- Widgets más pequeños y especializados
- Reducción de lógica condicional por período
- Cacheo específico para datos mensuales
- Animaciones optimizadas para transiciones mensuales

## Extensiones Futuras Simplificadas
La estructura modular simplificada permite:
- Agregar funcionalidades mensuales específicas
- Integración con servicios bancarios mensuales
- Exportación de informes mensuales
- Sistema de metas de ahorro mensuales

---
**Nota:** Este documento es parte 2 de 2. Para información completa sobre la estructura del proyecto, consultar ambas partes. 