# Registro de Cambios (Changelog)

## [Versión 2025.05.27.2] - 2025-05-27

### Corregido
- **Sincronización de Períodos**: Corregida la sincronización entre el `PeriodSelector` principal y el widget `FinanceMetrics`
- **Datos en Cero**: Solucionado el problema donde los períodos semanales devolvían datos vacíos debido a formato de fecha incorrecto
- **Layout Responsivo**: Eliminado el selector de período duplicado que causaba problemas de layout
- **Formato de Fechas**: Corregido el formato de fechas semanales para coincidir con el formato de la base de datos (de `2025-W21` a `2025-21`)

### Técnico
- **Widget Controlado**: `FinanceMetricsWithPeriod` ahora es un widget completamente controlado por el dashboard padre
- **Eliminación de Duplicación**: Removido el `DropdownButton` interno que competía con el `PeriodSelector` principal
- **Formato de Fecha Semanal**: Corregido en `_formatDateForPeriod()` para generar `2025-21` en lugar de `2025-W21`
- **Sincronización Automática**: Los datos se actualizan automáticamente cuando el período o fecha cambian en el dashboard principal
- **Método `didUpdateWidget()`**: Implementado para detectar cambios en parámetros del widget padre

### Archivos Modificados
- `lib/widgets/finance_metrics.dart`: Eliminado selector duplicado, widget ahora controlado por parámetros
- `lib/services/dashboard_service.dart`: Corregido formato de fecha semanal en `_formatDateForPeriod()`
- `lib/screens/dashboard/dashboard_screen.dart`: Actualizado para pasar parámetros correctos al widget
- `docs/CHANGELOG.md`: Documentación de las correcciones realizadas

### Pruebas de Verificación
- **Período Mensual**: ✅ Funcionando correctamente ($400 income, $100 expenses)
- **Período Semanal**: ✅ Corregido y funcionando ($500 income, $0 expenses)
- **Otros Períodos**: ✅ Daily, quarterly, annual funcionando correctamente
- **Sincronización**: ✅ Cambios en PeriodSelector principal se reflejan en FinanceMetrics

### Impacto
- **Experiencia de Usuario**: Eliminada confusión de selectores duplicados
- **Datos Precisos**: Períodos semanales ahora muestran datos reales en lugar de ceros
- **Consistencia**: Sincronización perfecta entre todos los componentes del dashboard
- **Rendimiento**: Eliminada redundancia en llamadas al backend

## [Versión 2024.12.19] - 2024-12-19

### Añadido
- **Herencia de Datos para Períodos Futuros**: Implementada funcionalidad automática de herencia de datos cuando se navega a períodos futuros sin registros en las tablas `[periodtime]_cash_bank_balance`
- Función `findLastAvailablePeriod()` para búsqueda hacia atrás de datos históricos disponibles
- Función `fetchBalanceDataWithInheritance()` para manejo de herencia cuando no existen datos
- Función `extractPeriodAndDateFromCondition()` para extracción de período y fecha desde condiciones SQL
- Funciones auxiliares de navegación temporal: `parseDateString()` y `getPreviousPeriodDate()`
- Logging detallado para trazabilidad de herencia de datos
- Límite de búsqueda de 24 períodos hacia atrás para optimización de rendimiento

### Corregido
- **Bug de Parsing de Fechas Mensuales**: Corregido error en `parseDateString()` donde el formato de fecha para períodos mensuales no coincidía con el string parseado, causando fallo en la herencia de datos
- Error "parsing time '2025-06-01': extra text: '-01'" que impedía la funcionalidad de herencia

### Archivos Modificados
- `backend/budget_overview_fetch/main.go`: Implementación completa de herencia de datos y corrección de parsing
- `docs/DATABASE_SCHEMA.md`: Documentación de la nueva funcionalidad de herencia
- `docs/CHANGELOG.md`: Registro de cambios implementados

### Impacto
- **budget_overview**: Ahora muestra datos heredados del último período disponible en lugar de valores vacíos para períodos futuros
- **cash_bank_distribution**: Mantiene distribución de efectivo/banco consistente basada en datos históricos
- **Experiencia de Usuario**: Navegación temporal más fluida sin pantallas vacías en períodos futuros

### Notas Técnicas
- La herencia busca hasta 24 períodos hacia atrás para encontrar datos disponibles
- Se mantiene la funcionalidad original para períodos con datos existentes
- Logging detallado permite monitoreo y debugging de la funcionalidad de herencia

## [Versión 2025.05.27] - 2025-05-27

### Añadido
- **Integración Frontend-Backend para FinanceMetrics**: Implementada conexión completa entre el widget `FinanceMetrics` del frontend Flutter y el endpoint `/budget-overview` del backend Go
- **Nuevo Widget Dinámico**: `FinanceMetricsWithPeriod` que incluye selector de período y obtención automática de datos del backend
- **Método `fetchBudgetOverview()`** en `DashboardService`: Conecta con el endpoint `/budget-overview` del microservicio `budget_overview_fetch`
- **Método `createFinanceMetricsFromBudgetOverview()`**: Convierte datos del backend al modelo `FinanceMetrics` del frontend
- **Método `_formatDateForPeriod()`**: Formatea fechas según el tipo de período (daily, weekly, monthly, quarterly, semiannual, annual)
- **Selector de período compacto**: DropdownButton integrado que permite cambiar entre diferentes períodos de tiempo
- **Estados de carga y error**: Indicadores visuales para carga, errores de conexión y datos vacíos
- **Manejo de errores con reintento**: Botón de reintento automático en caso de errores de conexión

### Corregido
- **Error de Layout en FinanceMetricsWithPeriod**: Solucionado problema de "unbounded width constraints" que causaba errores de renderizado
- **Restricciones de ancho**: Reemplazado PeriodSelector complejo por DropdownButton compacto para evitar problemas de layout
- **Importaciones innecesarias**: Removida importación de `period_selector.dart` no utilizada

### Modificado
- **`lib/widgets/finance_metrics.dart`**: Añadido nuevo widget `FinanceMetricsWithPeriod` manteniendo compatibilidad con el widget original
- **`lib/services/dashboard_service.dart`**: Añadidos nuevos métodos para integración con backend
- **`lib/screens/dashboard/dashboard_screen.dart`**: Actualizado para usar el nuevo widget dinámico en lugar del estático
- **Importación de `intl`**: Añadida dependencia para formateo de fechas en `dashboard_service.dart`

### Funcionalidades Implementadas
- **Datos en tiempo real**: El widget ahora obtiene datos directamente de la base de datos según el período seleccionado
- **Sincronización automática**: Cambios de período se sincronizan automáticamente entre componentes del dashboard
- **Distribución porcentual dinámica**: Cálculo automático de porcentajes de ingresos, gastos y facturas basado en datos reales
- **Soporte completo de períodos**: daily, weekly, monthly, quarterly, semiannual, annual

### Flujo de Datos Implementado
1. Usuario selecciona período en el widget `FinanceMetricsWithPeriod`
2. Widget llama a `DashboardService.fetchBudgetOverview()` con parámetros seleccionados
3. Servicio hace petición HTTP POST a `http://localhost:8097/budget-overview`
4. Backend devuelve datos agregados del período solicitado desde la base de datos SQLite
5. Servicio convierte datos a modelo `FinanceMetrics` del frontend
6. Widget actualiza visualización con distribución porcentual de ingresos, gastos y facturas

### Archivos Modificados
- `lib/widgets/finance_metrics.dart`: Nuevo widget dinámico con selector de período
- `lib/services/dashboard_service.dart`: Métodos de integración con backend
- `lib/screens/dashboard/dashboard_screen.dart`: Integración del nuevo widget
- `docs/PROJECT_STRUCTURE.md`: Documentación actualizada de la nueva funcionalidad
- `docs/CHANGELOG.md`: Registro de cambios implementados

### Pruebas Realizadas
- **Conexión backend**: Verificada conectividad con endpoint `/budget-overview`
- **Datos reales**: Probado con usuario ID 36 que tiene datos de ingresos ($400) y gastos ($100)
- **Cálculo de porcentajes**: Verificado cálculo correcto (Income: 80%, Expenses: 20%, Bills: 0%)
- **Compilación**: Verificada compilación sin errores críticos en Flutter

### Impacto en la Experiencia de Usuario
- **Datos actualizados**: Los usuarios ahora ven datos reales de su situación financiera
- **Navegación temporal**: Posibilidad de ver métricas financieras de diferentes períodos
- **Feedback visual**: Indicadores de carga y manejo de errores mejoran la experiencia
- **Sincronización**: Cambios de período se reflejan consistentemente en toda la aplicación

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

## [Unreleased] - 2025-01-27

### Fixed
- **TransactionOverviewWidget Dynamic Period Support**: Solucionado el problema donde los datos de transacciones (bills, expenses, incomes) no se actualizaban dinámicamente al cambiar el período de tiempo en el selector de períodos.
- **Infinite Loop Bug**: Solucionado el bucle infinito que ocurría al cambiar períodos temporales cuando el backend devolvía `transactions: null`.
- **Null Transactions Handling**: Corregido el error de parsing cuando el backend devuelve `transactions: null` para períodos sin datos.
- **setState During Build Error**: Solucionado el error "setState() called during build" que ocurría al cambiar períodos temporales. Implementado `SchedulerBinding.instance.addPostFrameCallback()` para diferir las llamadas de refresh hasta después de completar el proceso de construcción del widget.

### Changed
- **TransactionOverviewWidget**: 
  - Agregado estado interno para manejar `_currentPeriod` y `_formattedDate`
  - Implementado método `_updatePeriodAndDate()` para formatear correctamente las fechas según el período seleccionado
  - Agregado servicio `BudgetOverviewService` para usar `formatDateForPeriod()`
  - Mejorado el método `_handleRefresh()` para refrescar ambos tabs (Upcoming Bills y Transaction History)
  - Agregadas keys para los widgets internos para permitir refresh programático
  - **Agregado mecanismo anti-bucle**: Implementado flag `_isRefreshing` para prevenir múltiples llamadas simultáneas de refresh
  - **Corregido setState durante build**: Implementado `SchedulerBinding.instance.addPostFrameCallback()` en `didUpdateWidget()` para diferir refresh hasta después del build
  - **Agregada importación**: `package:flutter/scheduler.dart` para usar `SchedulerBinding`

- **TransactionHistoryTable**: 
  - Agregado método público `refreshData()` para permitir refresh desde widgets externos

- **TransactionHistoryResponse Model**: 
  - **Mejorado manejo de null**: Agregada validación para manejar `transactions: null` del backend
  - Agregados valores por defecto para `total`, `limit` y `offset` cuando son null

- **Dashboard Screen**: 
  - Agregado método `_formatDateForPeriod()` para formatear fechas según el período específico
  - Modificado la llamada a `TransactionOverviewWidget` para usar el formato de fecha correcto

### Technical Details
- Los datos ahora se actualizan correctamente cuando se cambia el período temporal
- El formateo de fechas es consistente entre `BudgetOverviewWithPeriod` y `TransactionOverviewWidget`
- Se mantiene la funcionalidad de refresh manual y automático
- **Prevención de bucles infinitos**: El sistema ahora maneja correctamente los casos donde el backend devuelve datos null
- **Manejo robusto de errores**: Mejorada la tolerancia a fallos en la comunicación con el backend

### Technical Details
- Los datos ahora se actualizan correctamente cuando se cambia entre períodos (daily, weekly, monthly, quarterly, semiannual, annual, custom)
- El formato de fecha se ajusta automáticamente según el período: 
  - Daily: "2025-05-27"
  - Monthly: "2025-05" 
  - Quarterly: "2025-Q2"
  - etc.
- Implementado patrón similar a `BudgetOverviewWithPeriod` para consistencia en el manejo de períodos

### Files Modified
- `lib/widgets/transaction_overview_widget.dart`
- `lib/widgets/transaction_history_table.dart` 
- `lib/screens/dashboard/dashboard_screen.dart` 