# Registro de Cambios (Changelog)

## [Versión Actual] - 2025-05-20

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
- Se corrigió un error en el cálculo de `balance_cash_amount` y `balance_bank_amount` en las tablas `weekly_balance` y `monthly_balance`.
- Ahora, al agregar un nuevo ingreso, gasto o factura, se desencadena una recalculación en cascada de los campos `previous_cash_amount`, `previous_bank_amount`, `balance_cash_amount` y `balance_bank_amount` para todos los periodos subsecuentes, asegurando la consistencia de los saldos.
- Se ajustó el límite del bucle de actualización en cascada para balances mensuales a 1 año (anteriormente 2 años en `income_management` y `expense_management`) para consistencia y optimización.
- `backend/income_management/main.go`: 
    - Modificadas las funciones `updateSubsequentWeeklyBalances` y `updateSubsequentMonthlyBalances` para calcular y actualizar correctamente `balance_cash_amount` y `balance_bank_amount`.
    - Corregidos nombres de variables para mayor claridad (e.g., `prevMonth` a `prevDate` en `updateSubsequentMonthlyBalances`).
    - **Corregido el Bug 2:** Mejorada la función `updateSubsequentMonthlyBalances` para manejar correctamente la actualización en cascada cuando existen meses intermedios sin registros, asegurando que todos los meses posteriores se actualicen con los valores correctos. La función ahora realiza una segunda pasada para procesar meses que pudieron haber sido omitidos en la primera iteración.
- `backend/expense_management/main.go`:
    - Modificadas las funciones `updateSubsequentWeeklyBalances` y `updateSubsequentMonthlyBalances` para calcular y actualizar correctamente `balance_cash_amount` y `balance_bank_amount`.
    - Corregidos nombres de variables para mayor claridad.
- `docs/DATABASE_SCHEMA.md`: Actualizada la descripción de las tablas `weekly_balance` y `monthly_balance` para reflejar los campos de saldo de efectivo y banco y su lógica de cálculo.

### Eliminado
- Registros del usuario con ID 36 en todas las tablas, excepto en la tabla `users`

### Detalles Técnicos
- Cada transacción financiera ahora actualiza los balances correspondientes según su fecha
- Se implementó un sistema de balances acumulativos que tiene en cuenta los saldos de periodos anteriores
- Se mejoró la estructura de la base de datos con índices optimizados para consultas frecuentes

## [Versiones Anteriores]
Historial de versiones anteriores no disponible.

## [Pendiente de versión] - YYYY-MM-DD

### Añadido
- Implementación de funcionalidad para convertir automáticamente facturas pagadas en gastos
- Mejora en la actualización en cascada de tablas de balance para asegurar precisión en los datos
- Transacción de base de datos para garantizar consistencia en actualizaciones de balance

### Modificado
- Actualización de la estructura de datos de `PayBillRequest` para soportar la descripción personalizada de gastos
- Mejora en el manejo de errores durante el pago de facturas y actualización de balances

### Documentación
- Actualización del esquema de base de datos para incluir el flujo de pago de facturas
- Documentación del proceso de actualización de balances en cascada 