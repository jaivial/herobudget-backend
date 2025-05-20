# Registro de Cambios (Changelog)

## [Versión Actual] - 2023-05-21

### Añadido
- Nuevo sistema de seguimiento de balances por periodos de tiempo (diario, semanal, mensual, trimestral, semestral y anual)
- Tablas en la base de datos para cada periodo de tiempo:
  - `daily_balance`: Balance diario
  - `weekly_balance`: Balance semanal
  - `monthly_balance`: Balance mensual
  - `quarterly_balance`: Balance trimestral
  - `semiannual_balance`: Balance semestral
  - `annual_balance`: Balance anual
- Índices en cada tabla para optimizar consultas
- Funcionalidad para actualizar automáticamente los balances cuando se registra un ingreso
- Funcionalidad para actualizar automáticamente los balances cuando se registra un gasto
- Funcionalidad para actualizar automáticamente los balances cuando se paga una factura
- Cálculo de balance acumulativo que incluye el balance de periodos anteriores

### Modificado
- Servicio de gestión de ingresos (`income_management`) para actualizar los balances por periodos
- Servicio de gestión de gastos (`expense_management`) para actualizar los balances por periodos
- Servicio de gestión de facturas (`bills_management`) para actualizar los balances por periodos
- Documentación de esquema de base de datos para incluir las nuevas tablas

### Eliminado
- Registros del usuario con ID 36 en todas las tablas, excepto en la tabla `users`

### Detalles Técnicos
- Cada transacción financiera ahora actualiza los balances correspondientes según su fecha
- Se implementó un sistema de balances acumulativos que tiene en cuenta los saldos de periodos anteriores
- Se mejoró la estructura de la base de datos con índices optimizados para consultas frecuentes

## [Versiones Anteriores]
Historial de versiones anteriores no disponible. 