# Esquema de Base de Datos - Hero Budget (Parte 2: Distribución y Transacciones)

## Descripción

Esta es la parte 2 de la documentación del esquema de base de datos que cubre las tablas de distribución efectivo-banco y transacciones.

## Archivos Relacionados

- [DATABASE_SCHEMA_part1.md](DATABASE_SCHEMA_part1.md) - Tablas principales
- [DATABASE_SCHEMA_part3.md](DATABASE_SCHEMA_part3.md) - Tablas de períodos y configuración

## Tablas de Distribución y Transacciones

### Distribución Efectivo-Banco (`cash_bank`)

Almacena la distribución mensual de efectivo y banco.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| month | TEXT | Mes en formato YYYY-MM |
| cash_amount | REAL | Cantidad en efectivo |
| cash_percent | REAL | Porcentaje en efectivo |
| bank_amount | REAL | Cantidad en banco |
| bank_percent | REAL | Porcentaje en banco |
| monthly_total | REAL | Total mensual |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

### Transacciones Efectivo-Banco (`cash_bank_transactions`)

Almacena las transacciones que afectan a la distribución de efectivo y banco.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| transaction_type | TEXT | Tipo de transacción |
| amount | REAL | Cantidad |
| date | TEXT | Fecha (YYYY-MM-DD) |
| created_at | TIMESTAMP | Fecha de creación del registro |

## Tabla de Balance Mensual (Principal)

### Balance Mensual (`monthly_cash_bank_balance`)

**Nota:** Esta es la única tabla de balance que se mantendrá tras la simplificación a período mensual únicamente.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year_month | TEXT | Mes en formato YYYY-MM |
| income_bank_amount | REAL | Suma de ingresos bancarios del mes |
| income_cash_amount | REAL | Suma de ingresos en efectivo del mes |
| expense_bank_amount | REAL | Suma de gastos bancarios del mes |
| expense_cash_amount | REAL | Suma de gastos en efectivo del mes |
| bill_bank_amount | REAL | Suma de facturas bancarias pagadas del mes |
| bill_cash_amount | REAL | Suma de facturas en efectivo pagadas del mes |
| cash_amount | REAL | Suma de movimientos en efectivo del mes |
| bank_amount | REAL | Suma de movimientos en banco del mes |
| previous_cash_amount | REAL | Saldo en efectivo al inicio del mes |
| previous_bank_amount | REAL | Saldo en banco al inicio del mes |
| balance_cash_amount | REAL | Saldo final en efectivo del mes |
| balance_bank_amount | REAL | Saldo final en banco del mes |
| total_previous_balance | REAL | Balance total del mes anterior |
| total_balance | REAL | Balance total al final del mes |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices:**
- `idx_monthly_balance_user`: Índice en `user_id`
- `idx_monthly_balance_month`: Índice en `year_month`

## Tablas de Períodos Obsoletas

**Importante:** Las siguientes tablas serán eliminadas tras la migración a período mensual únicamente:

- `daily_cash_bank_balance` - Balance diario
- `weekly_cash_bank_balance` - Balance semanal  
- `quarterly_cash_bank_balance` - Balance trimestral
- `semiannual_cash_bank_balance` - Balance semestral
- `annual_cash_bank_balance` - Balance anual

## Cálculo de Balances Mensual

Para el período mensual, el balance se calcula de la siguiente manera:

```
Balance = BalanceAnterior + Ingresos - Gastos - Facturas
```

Donde:
- `BalanceAnterior` es el balance acumulado del mes anterior
- `Ingresos` es la suma de todos los ingresos del mes actual
- `Gastos` es la suma de todos los gastos del mes actual
- `Facturas` es la suma de todas las facturas pagadas del mes actual

### Cálculo por Método de Pago

El sistema también rastrea separadamente:

**Efectivo:**
```
balance_cash_amount = previous_cash_amount + income_cash_amount - expense_cash_amount - bill_cash_amount
```

**Banco:**
```
balance_bank_amount = previous_bank_amount + income_bank_amount - expense_bank_amount - bill_bank_amount
```

**Total:**
```
total_balance = balance_cash_amount + balance_bank_amount
```

## Relaciones

- `cash_bank.user_id` → `users.id`
- `cash_bank_transactions.user_id` → `users.id`
- `monthly_cash_bank_balance.user_id` → `users.id`

## Consideraciones de Rendimiento

- Las tablas incluyen índices optimizados para consultas frecuentes por usuario y período
- Las actualizaciones de balance se realizan incrementalmente
- Se utilizan transacciones para garantizar la integridad de los datos

---
**Nota:** Este documento es parte 2 de 3. Consultar las otras partes para información completa sobre el esquema de base de datos. 