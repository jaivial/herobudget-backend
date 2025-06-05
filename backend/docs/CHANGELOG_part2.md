# Registro de Cambios - Hero Budget (Parte 2: Cambios Históricos)

## Descripción

Esta es la parte 2 del registro de cambios que cubre el historial de cambios anteriores a la migración a período mensual.

## Archivos Relacionados

- [CHANGELOG_part1.md](CHANGELOG_part1.md) - Cambios recientes y migración mensual

## [2024-12-19] - Corrección de Localización OTP y Verificación Email

### Fixed
- **[email_otp_verification_screen.dart]**: Corregido problema de localización donde todos los textos aparecían solo en inglés
  - Añadidas 16 nuevas claves de traducción para pantalla de verificación OTP por email
  - Claves: `email_otp_description`, `email_otp_enter_6_digits`, `email_otp_enter_all_digits`, etc.
  - Añadidas traducciones a los 14 idiomas soportados
  - Reemplazados strings hardcodeados en inglés con `context.tr.translate()`
  - Pantalla ahora se muestra correctamente en el idioma configurado por el usuario

- **[email_verification_screen.dart]**: Corregido problema de localización
  - Añadidas 12 nuevas claves de traducción para pantalla de verificación de email
  - Claves: `email_verification_checking_status`, `email_verification_complete`, etc.
  - Sistema de traducción implementado correctamente

- **[email_sent_step.dart]**: Corregidos problemas de detección de idioma
  - Mejorada inicialización de locale en `main.dart`
  - Optimizado `LanguageService` con mejor manejo de formatos de locale antiguos
  - Corregidas claves de traducción faltantes en chino (`zh.json`)

## [2024-01-15] - Corrección del Sistema de Traducciones

### Problema Resuelto
- **Pantalla email_sent_step.dart mostrando solo en inglés**: Identificado y corregido problema de localización
- **Sistema de detección de idioma mejorado**: Implementada mejor detección del idioma del dispositivo

### Cambios Realizados
- **Strings hardcodeados eliminados**: Reemplazados textos en inglés por llamadas al sistema de traducción
- **12 nuevas claves de traducción**: Creadas claves específicas para verificación de email
- **Soporte completo multiidioma**: Pantallas ahora se muestran en los 14 idiomas soportados
- **Mejor manejo de formatos antiguos**: Conversión automática de formatos de locale antiguos

## [Unreleased] - 2025-01-27 - Dynamic Period Support

### Fixed
- **TransactionOverviewWidget Dynamic Period Support**: Solucionado problema donde datos de transacciones no se actualizaban dinámicamente al cambiar período
- **Infinite Loop Bug**: Solucionado bucle infinito al cambiar períodos cuando backend devolvía `transactions: null`
- **Null Transactions Handling**: Corregido error de parsing cuando backend devuelve `transactions: null`
- **setState During Build Error**: Solucionado error "setState() called during build" durante cambios de período

### Changed
- **TransactionOverviewWidget**: 
  - Agregado estado interno para manejar `_currentPeriod` y `_formattedDate`
  - Implementado método `_updatePeriodAndDate()` para formatear fechas según período
  - Agregado servicio `BudgetOverviewService` para usar `formatDateForPeriod()`
  - Mejorado método `_handleRefresh()` para refrescar ambos tabs
  - **Agregado mecanismo anti-bucle**: Flag `_isRefreshing` para prevenir llamadas simultáneas
  - **Corregido setState durante build**: `SchedulerBinding.instance.addPostFrameCallback()`

## [Versiones Anteriores] - Balance System Implementation

### Modificado
- `backend/income_management/main.go`: 
  - Modificadas funciones `updateSubsequentWeeklyBalances` y `updateSubsequentMonthlyBalances`
  - Corregidos cálculos para `balance_cash_amount` y `balance_bank_amount`
  - **Corregido Bug 2**: Mejorada función `updateSubsequentMonthlyBalances` para manejar meses intermedios sin registros
  - Implementada segunda pasada para procesar meses omitidos en primera iteración

- `backend/expense_management/main.go`:
  - Modificadas funciones de actualización de balances semanales y mensuales
  - Corregidos nombres de variables para mayor claridad

- `docs/DATABASE_SCHEMA.md`: Actualizada descripción de tablas `weekly_balance` y `monthly_balance`

### Eliminado
- Registros del usuario con ID 36 en todas las tablas, excepto en tabla `users`

### Detalles Técnicos
- Cada transacción financiera actualiza balances según su fecha
- Sistema de balances acumulativos con saldos de períodos anteriores
- Estructura de base de datos con índices optimizados

## [Pendiente de versión] - YYYY-MM-DD

### Añadido
- Funcionalidad para convertir automáticamente facturas pagadas en gastos
- Mejora en actualización en cascada de tablas de balance
- Transacción de base de datos para garantizar consistencia

### Modificado
- Actualización de estructura `PayBillRequest` para soportar descripción personalizada
- Mejora en manejo de errores durante pago de facturas

### Documentación
- Actualización del esquema de base de datos para flujo de pago de facturas
- Documentación del proceso de actualización de balances en cascada

## [Legacy] - Sistema de Períodos Múltiples (OBSOLETO)

**Nota:** Las siguientes funcionalidades fueron eliminadas en la migración a período mensual únicamente:

### Funcionalidades Eliminadas
- Soporte para períodos: daily, weekly, quarterly, semiannual, annual
- Selector de período con múltiples opciones
- Vistas personalizadas de rango de fechas
- Balances agregados por períodos no mensuales
- Comparativas entre diferentes tipos de período

### Archivos Afectados por Migración
- `lib/widgets/period_selector.dart` - Eliminado (770 líneas)
- `lib/widgets/budget_overview_with_period.dart` - Refactorizado en múltiples archivos
- `backend/*/main.go` - Simplificados todos los servicios backend

### Tablas de Base de Datos Obsoletas
- `daily_cash_bank_balance`
- `weekly_cash_bank_balance`
- `quarterly_cash_bank_balance`
- `semiannual_cash_bank_balance`
- `annual_cash_bank_balance`

**Importante:** Estas tablas ya no se actualizan desde la migración del 2024-12-19.

## Technical Details

### Sistema de Traducciones
- **Arquitectura**: Sistema basado en JSON con archivos en `assets/l10n/`
- **Idiomas Soportados**: 14 idiomas (en, es, fr, it, de, gsw, el, nl, da, ru, pt, zh, ja, hi)
- **Implementación**: `AppLocalizations` con extensión `context.tr.translate()`
- **Detección**: Automática del idioma del dispositivo con fallback a inglés

### Patrones de Código
- Todos los archivos mantienen límite de 200 líneas
- Separación de responsabilidades en widgets especializados
- Uso consistente del sistema de traducción
- Manejo robusto de errores en comunicación con backend

---
**Nota:** Este documento es parte 2 de 2. Para información sobre cambios recientes y migración mensual, consultar CHANGELOG_part1.md.