# Estructura del Proyecto Hero Budget (Parte 1: Backend y Arquitectura)

## Visión General

Hero Budget es una aplicación de gestión financiera personal desarrollada con Flutter para el frontend y Go para los microservicios backend. La aplicación está diseñada con una arquitectura modular que separa las diferentes funcionalidades en servicios independientes.

## Archivos Relacionados

- [PROJECT_STRUCTURE_part2.md](PROJECT_STRUCTURE_part2.md) - Frontend Flutter y componentes

## Estructura de Directorios Backend

```
hero_budget/backend/
├── google_auth/           # Servicio de autenticación
│   ├── main.go            # Punto de entrada del servicio
│   └── users.db           # Base de datos SQLite
├── income_management/     # Servicio de gestión de ingresos
│   └── main.go            # Lógica para manejar ingresos
├── expense_management/    # Servicio de gestión de gastos
│   └── main.go            # Lógica para manejar gastos
├── bills_management/      # Servicio de gestión de facturas
│   └── main.go            # Lógica para manejar facturas
├── budget_overview_fetch/ # Servicio de obtención de datos presupuestarios
│   └── main.go            # Lógica para consultas de presupuesto
└── transaction_delete_service/ # Servicio de eliminación de transacciones
    └── main.go            # Lógica para eliminar transacciones
```

## Componentes Backend

### Servicio de Autenticación (`google_auth`)

El servicio de autenticación maneja el registro y login de usuarios, principalmente a través de Google OAuth. También es responsable de mantener la base de datos SQLite `users.db` que contiene todas las tablas del sistema.

**Puerto:** 8080
**Responsabilidades:**
- Autenticación Google OAuth
- Gestión de sesiones de usuario
- Mantenimiento de la base de datos central

### Servicio de Gestión de Ingresos (`income_management`)

Maneja todo lo relacionado con los ingresos de los usuarios.

**Puerto:** 8082
**Responsabilidades:**
- Registro de nuevos ingresos
- Actualización de ingresos existentes
- Eliminación de ingresos
- Actualización de balances generales
- **Actualización de balance mensual** (tras simplificación)

**Funciones principales:**
- `updateTimeBalances`: Función principal que coordina la actualización
- `updateMonthlyBalance`: Actualiza el balance mensual únicamente
- `updateSubsequentMonthlyBalances`: Actualiza meses posteriores

### Servicio de Gestión de Gastos (`expense_management`)

Similar al servicio de ingresos, pero especializado en gastos.

**Puerto:** 8083
**Responsabilidades:**
- Registro de nuevos gastos
- Actualización de gastos existentes
- Eliminación de gastos
- Actualización de balances generales
- **Actualización de balance mensual** (tras simplificación)

La estructura de funciones para actualizar balances es idéntica a la del servicio de ingresos, pero adaptada para trabajar con gastos.

### Servicio de Gestión de Facturas (`bills_management`)

Maneja las facturas recurrentes y no recurrentes.

**Puerto:** 8084
**Responsabilidades:**
- Creación de nuevas facturas
- Actualización de facturas existentes
- Marcar facturas como pagadas
- Eliminación de facturas
- **Actualización de balance mensual** (tras simplificación)

Las facturas pagadas también actualizan los balances mensuales, utilizando el mismo conjunto de funciones que los otros servicios.

### Servicio de Obtención de Datos Presupuestarios (`budget_overview_fetch`)

Este servicio se encarga de obtener y procesar datos financieros agregados y transacciones individuales.

**Puerto:** 8098
**Funcionalidades principales:**
- **Resumen presupuestario mensual**: Obtiene datos agregados solo de la tabla `monthly_cash_bank_balance`
- **Historial de transacciones**: Proporciona acceso unificado a todas las transacciones con filtros por mes
- **Próximas facturas**: Lista las facturas pendientes de pago

**Endpoints disponibles:**
- `POST /budget-overview`: Obtiene el resumen presupuestario para un mes específico
- `POST /transactions/history`: Obtiene el historial de transacciones del mes
- `POST /transactions/upcoming-bills`: Obtiene las facturas pendientes
- `GET /health`: Verificación de estado del servicio

### Servicio de Eliminación de Transacciones (`transaction_delete_service`)

Maneja la eliminación segura de transacciones de todos los tipos.

**Puerto:** 8099
**Responsabilidades:**
- Eliminación de ingresos, gastos y facturas
- Actualización de balances tras eliminaciones
- **Actualización solo de balance mensual** (tras simplificación)

## Base de Datos

La aplicación utiliza SQLite como motor de base de datos. El archivo `users.db` contiene todas las tablas necesarias para el funcionamiento de la aplicación.

### Tabla Principal de Balance (Tras Simplificación)

**Tabla mantenida:**
- `monthly_cash_bank_balance`: Balance mensual (única tabla de balance después de la migración)

**Tablas eliminadas tras simplificación:**
- `daily_cash_bank_balance`: Balance diario
- `weekly_cash_bank_balance`: Balance semanal
- `quarterly_cash_bank_balance`: Balance trimestral
- `semiannual_cash_bank_balance`: Balance semestral
- `annual_cash_bank_balance`: Balance anual

## Flujo de Datos Simplificado

El flujo de datos para la actualización de balance mensual es el siguiente:

1. El usuario realiza una acción desde la aplicación móvil
2. La aplicación envía la información al microservicio correspondiente
3. El microservicio procesa la solicitud y realiza:
   - Registra la transacción en su tabla específica (incomes, expenses, bills)
   - Actualiza el balance general del usuario (tabla balances)
   - Actualiza la distribución efectivo-banco (tabla cash_bank)
   - Llama a `updateMonthlyBalance` para actualizar solo el balance mensual
4. Se calcula el nuevo balance mensual
5. La aplicación móvil consulta y muestra los balances mensuales

## Cálculo de Balance Mensual

Para el período mensual, el balance se calcula de la siguiente manera:

```
Balance = BalanceAnterior + Ingresos - Gastos - Facturas
```

Donde:
- `BalanceAnterior` es el balance acumulado del mes anterior
- `Ingresos` es la suma de todos los ingresos del mes actual
- `Gastos` es la suma de todos los gastos del mes actual
- `Facturas` es la suma de todas las facturas pagadas del mes actual

## Consideraciones de Rendimiento

- La tabla mensual cuenta con índices optimizados para consultas frecuentes
- Las actualizaciones de balance se realizan de forma incremental
- Las operaciones de base de datos utilizan transacciones para garantizar integridad

---
**Nota:** Este documento es parte 1 de 2. Consultar PROJECT_STRUCTURE_part2.md para información sobre el frontend Flutter. 