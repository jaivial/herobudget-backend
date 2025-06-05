# Esquema de Base de Datos - Hero Budget

## Descripción

Este documento describe la estructura de la base de datos SQLite utilizada en Hero Budget, incluyendo tablas, columnas y sus relaciones.

## Tablas

### Usuarios (`users`)

Almacena información de los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| google_id | TEXT | ID de Google del usuario (único) |
| email | TEXT | Correo electrónico del usuario (único) |
| name | TEXT | Nombre completo |
| given_name | TEXT | Nombre |
| family_name | TEXT | Apellidos |
| picture | TEXT | URL de la imagen de perfil |
| locale | TEXT | Preferencia de idioma |
| verified_email | BOOLEAN | Si el email está verificado |
| password | TEXT | Contraseña (encriptada) |
| profile_image_blob | TEXT | Imagen de perfil en formato blob |
| verification_code | TEXT | Código de verificación |
| reset_token | TEXT | Token para reseteo de contraseña |
| reset_expires | DATETIME | Fecha de expiración del token |
| created_at | DATETIME | Fecha de creación del registro |
| updated_at | DATETIME | Fecha de última actualización |

### Ingresos (`incomes`)

Almacena los ingresos registrados por los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario (FK) |
| amount | REAL | Cantidad del ingreso |
| date | TEXT | Fecha del ingreso (YYYY-MM-DD) |
| category | TEXT | Categoría del ingreso |
| payment_method | TEXT | Método de pago ("cash" o "bank") |
| description | TEXT | Descripción del ingreso |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

### Gastos (`expenses`)

Almacena los gastos registrados por los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario (FK) |
| amount | REAL | Cantidad del gasto |
| date | TEXT | Fecha del gasto (YYYY-MM-DD) |
| category | TEXT | Categoría del gasto |
| payment_method | TEXT | Método de pago ("cash" o "bank") |
| description | TEXT | Descripción del gasto |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

### Facturas (`bills`)

Almacena las facturas recurrentes y no recurrentes de los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario (FK) |
| name | TEXT | Nombre de la factura |
| amount | REAL | Importe de la factura |
| due_date | TEXT | Fecha de vencimiento (YYYY-MM-DD) |
| paid | BOOLEAN | Si está pagada o no |
| overdue | BOOLEAN | Si está vencida |
| overdue_days | INTEGER | Días de retraso |
| recurring | BOOLEAN | Si es una factura recurrente |
| category | TEXT | Categoría de la factura |
| icon | TEXT | Icono representativo |
| payment_method | TEXT | Método de pago ("cash" o "bank") |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Uso en el sistema:**
- ❌ **Las facturas YA NO se incluyen** en el historial de transacciones (`/transactions/history`)
- ✅ **Las facturas con `paid = 0`** aparecen en la lista de próximas facturas (`/transactions/upcoming-bills`)
- ✅ **Cuando se paga una factura**, se crea automáticamente un registro en la tabla `expenses`
- 📊 **Separación lógica**: El historial muestra solo transacciones reales (ingresos y gastos), las facturas representan obligaciones futuras

**Flujo de pago actualizado:**
1. Factura pendiente (`paid = 0`) → Aparece en `/transactions/upcoming-bills`
2. Se paga la factura → Se actualiza `paid = 1` en tabla `bills`
3. **🆕 RECLASIFICACIÓN EN `monthly_cash_bank_balance`**: Se transfiere el monto de `bill_xxx_amount` a `expense_xxx_amount`
4. Se crea registro en tabla `expenses` con el pago realizado
5. El gasto aparece en `/transactions/history` como tipo `expense`
6. La factura ya no aparece en upcoming-bills pero tampoco en el historial (evita duplicación)

**Nueva funcionalidad de reclasificación (Enero 2025):**
- **`bill_cash_amount`** → **`expense_cash_amount`** (para pagos en efectivo)
- **`bill_bank_amount`** → **`expense_bank_amount`** (para pagos con banco)
- **Transacciones atómicas**: Garantiza consistencia en los datos
- **Prevención de negativos**: Evita valores negativos en `bill_xxx_amount`
- **Logging detallado**: Tracking completo de la reclasificación para auditoría

**Flujo de adición de facturas (Actualizado - Enero 2025):**
1. **Nueva factura añadida** → Se determina `payment_method` ("cash" o "bank")
2. **Si factura NO pagada** (`paid = 0`) - CASO MÁS COMÚN:
   - ✅ **Se suma automáticamente** a `bill_cash_amount` (si payment_method = "cash")
   - ✅ **Se suma automáticamente** a `bill_bank_amount` (si payment_method = "bank") 
   - ✅ **🆕 Se resta automáticamente** de `cash_amount` (si payment_method = "cash")
   - ✅ **🆕 Se resta automáticamente** de `bank_amount` (si payment_method = "bank")
   - Se actualiza `monthly_cash_bank_balance` para el mes de vencimiento
   - Se actualiza `daily_cash_bank_balance` para el día de vencimiento
   - Se resta del `balance_cash_amount`/`balance_bank_amount` (balance final actualizado)
3. **Si factura pagada** (`paid = 1`) - CASO MENOS COMÚN:
   - Se ejecuta `updateTimeBalances()` que actualiza todos los balances
   - Se ejecuta `recalculateAllBalances()` para actualización en cascada

**✅ FUNCIONALIDAD ACTUALIZADA (Enero 2025):**
- **Actualización automática**: Las facturas nuevas actualizan automáticamente las columnas `bill_cash_amount` y `bill_bank_amount`
- **🆕 Dinero comprometido**: Las facturas restan automáticamente de `cash_amount` y `bank_amount`
- **Método de pago respetado**: "cash" → afecta campos cash, "bank" → afecta campos bank
- **Tablas sincronizadas**: Se actualiza tanto `monthly_cash_bank_balance` como `daily_cash_bank_balance`
- **Auto-creación**: Crea registros en las tablas de balance si no existen para el período
- **🆕 Proyección realista**: El balance disponible refleja inmediatamente el dinero comprometido

**💰 Ejemplo de impacto al añadir factura de $100 (payment_method="bank"):**
- **Antes:** `bank_amount = $500`, `bill_bank_amount = $200`, `balance_bank_amount = $300`
- **Después:** `bank_amount = $400`, `bill_bank_amount = $300`, `balance_bank_amount = $200`
- **Resultado:** El usuario ve $100 menos disponible inmediatamente

**🎯 Lógica de negocio:**
- **Facturas = Compromisos financieros** que reducen el dinero realmente disponible
- **Transparencia total** entre dinero libre vs dinero comprometido
- **Prevención de sobregasto** al mostrar balance realista

### Balances (`balances`)

Almacena el balance total del usuario entre efectivo y banco.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario (único) |
| cash_balance | REAL | Balance en efectivo |
| bank_balance | REAL | Balance en banco |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

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

### Categorías (`categories`)

Almacena las categorías personalizadas de los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| name | TEXT | Nombre de la categoría |
| type | TEXT | Tipo de categoría (expense, income, bill) |
| emoji | TEXT | Emoji representativo |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

### Balance Diario (`daily_balance`)

Almacena el balance diario de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| date | TEXT | Fecha en formato YYYY-MM-DD |
| income_amount | REAL | Suma de ingresos del día |
| expense_amount | REAL | Suma de gastos del día |
| bills_amount | REAL | Suma de facturas pagadas del día |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance del día anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_daily_balance_user`: Índice en `user_id`
- `idx_daily_balance_date`: Índice en `date`

### Balance Semanal (`weekly_balance`)

Almacena el balance semanal de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year_week | TEXT | Semana en formato YYYY-WXX |
| start_date | TEXT | Fecha de inicio de semana (YYYY-MM-DD) |
| end_date | TEXT | Fecha de fin de semana (YYYY-MM-DD) |
| income_amount | REAL | Suma de ingresos de la semana |
| expense_amount | REAL | Suma de gastos de la semana |
| bills_amount | REAL | Suma de facturas pagadas de la semana |
| cash_amount | REAL | Suma de movimientos en efectivo de la semana. Este valor refleja las transacciones de la semana actual. |
| bank_amount | REAL | Suma de movimientos en banco de la semana. Este valor refleja las transacciones de la semana actual. |
| previous_cash_amount | REAL | Saldo en efectivo al inicio de la semana (heredado de la semana anterior). |
| previous_bank_amount | REAL | Saldo en banco al inicio de la semana (heredado de la semana anterior). |
| balance_cash_amount | REAL | Saldo final en efectivo de la semana (`previous_cash_amount` + `cash_amount` de la semana). |
| balance_bank_amount | REAL | Saldo final en banco de la semana (`previous_bank_amount` + `bank_amount` de la semana). |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance de la semana anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_weekly_balance_user`: Índice en `user_id`
- `idx_weekly_balance_week`: Índice en `year_week`

### Balance Mensual (`monthly_balance`)

Almacena el balance mensual de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year_month | TEXT | Mes en formato YYYY-MM |
| income_amount | REAL | Suma de ingresos del mes |
| expense_amount | REAL | Suma de gastos del mes |
| bills_amount | REAL | Suma de facturas pagadas del mes |
| cash_amount | REAL | Suma de movimientos en efectivo del mes. Este valor refleja las transacciones del mes actual. |
| bank_amount | REAL | Suma de movimientos en banco del mes. Este valor refleja las transacciones del mes actual. |
| previous_cash_amount | REAL | Saldo en efectivo al inicio del mes (heredado del mes anterior). |
| previous_bank_amount | REAL | Saldo en banco al inicio del mes (heredado del mes anterior). |
| balance_cash_amount | REAL | Saldo final en efectivo del mes (`previous_cash_amount` + `cash_amount` del mes). |
| balance_bank_amount | REAL | Saldo final en banco del mes (`previous_bank_amount` + `bank_amount` del mes). |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance del mes anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_monthly_balance_user`: Índice en `user_id`
- `idx_monthly_balance_month`: Índice en `year_month`

### Balance Trimestral (`quarterly_balance`)

Almacena el balance trimestral de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year_quarter | TEXT | Trimestre en formato YYYY-QX |
| start_date | TEXT | Fecha de inicio de trimestre (YYYY-MM-DD) |
| end_date | TEXT | Fecha de fin de trimestre (YYYY-MM-DD) |
| income_amount | REAL | Suma de ingresos del trimestre |
| expense_amount | REAL | Suma de gastos del trimestre |
| bills_amount | REAL | Suma de facturas pagadas del trimestre |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance del trimestre anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_quarterly_balance_user`: Índice en `user_id`
- `idx_quarterly_balance_quarter`: Índice en `year_quarter`

### Balance Semestral (`semiannual_balance`)

Almacena el balance semestral de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year_half | TEXT | Semestre en formato YYYY-HX |
| start_date | TEXT | Fecha de inicio de semestre (YYYY-MM-DD) |
| end_date | TEXT | Fecha de fin de semestre (YYYY-MM-DD) |
| income_amount | REAL | Suma de ingresos del semestre |
| expense_amount | REAL | Suma de gastos del semestre |
| bills_amount | REAL | Suma de facturas pagadas del semestre |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance del semestre anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_semiannual_balance_user`: Índice en `user_id`
- `idx_semiannual_balance_half`: Índice en `year_half`

### Balance Anual (`annual_balance`)

Almacena el balance anual de ingresos, gastos y facturas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| year | TEXT | Año en formato YYYY |
| income_amount | REAL | Suma de ingresos del año |
| expense_amount | REAL | Suma de gastos del año |
| bills_amount | REAL | Suma de facturas pagadas del año |
| balance | REAL | Balance total (incluye balance anterior) |
| previous_balance | REAL | Balance del año anterior |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Índices**:
- `idx_annual_balance_user`: Índice en `user_id`
- `idx_annual_balance_year`: Índice en `year`

### Otras Tablas

La base de datos también incluye otras tablas como `budget`, `savings`, `finance_metrics`, `balance_history` que complementan el sistema de gestión financiera.

## Relaciones

- Un usuario (`users`) puede tener múltiples registros en todas las demás tablas.
- Los ingresos (`incomes`), gastos (`expenses`), facturas (`bills`) afectan directamente a los balances por periodo.
- Cada transacción actualiza automáticamente los balances correspondientes según su fecha.

## Funcionamiento

1. Cuando se registra un ingreso, se actualiza:
   - La tabla `balances` incrementando el balance correspondiente según el método de pago
   - La tabla `cash_bank` para reflejar la distribución mensual
   - Las tablas de balance por periodo (`daily_balance`, `weekly_balance`, etc.)
   
2. Cuando se registra un gasto, se actualiza:
   - La tabla `balances` decrementando el balance correspondiente según el método de pago
   - La tabla `cash_bank` para reflejar la distribución mensual
   - Las tablas de balance por periodo (`daily_balance`, `weekly_balance`, etc.)
   
3. Cuando se paga una factura, se actualiza:
   - Las tablas de balance por periodo (`daily_balance`, `weekly_balance`, etc.)
   
4. El cálculo del balance en cada periodo incluye:
   - El balance del periodo anterior
   - Los ingresos del periodo actual
   - Los gastos del periodo actual
   - Las facturas pagadas del periodo actual

Esta estructura permite mantener un seguimiento detallado de los movimientos financieros de los usuarios en diferentes marcos temporales, facilitando el análisis y la visualización de tendencias.

## Tecnología
Hero Budget utiliza SQLite como su sistema de gestión de base de datos, con soporte explícito para codificación UTF-8.

## Schema de la Base de Datos

### Tabla: categories
Esta tabla almacena las categorías de gastos e ingresos definidas por los usuarios.

```sql
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    emoji TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único (clave primaria)
- `user_id`: Identificador del usuario propietario
- `name`: Nombre de la categoría
- `type`: Tipo de categoría (ingreso o gasto)
- `emoji`: Ícono representativo (carácter emoji)
- `created_at`: Fecha de creación
- `updated_at`: Fecha de última actualización

### Tabla: expenses
Almacena los registros de gastos de los usuarios.

```sql
CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    category TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto del gasto
- `date`: Fecha del gasto
- `category`: Categoría del gasto
- `payment_method`: Método de pago utilizado
- `description`: Descripción opcional
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

### Tabla: incomes
Almacena los registros de ingresos de los usuarios.

```sql
CREATE TABLE IF NOT EXISTS incomes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    category TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto del ingreso
- `date`: Fecha del ingreso
- `category`: Categoría del ingreso
- `payment_method`: Método de recepción del ingreso
- `description`: Descripción opcional
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

### Tabla: users
Almacena la información de los usuarios registrados.

```sql
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    google_id TEXT,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    given_name TEXT,
    family_name TEXT,
    picture TEXT,
    display_image TEXT,
    profile_image_blob TEXT,
    locale TEXT NOT NULL DEFAULT 'en',
    verified_email BOOLEAN NOT NULL DEFAULT 0,
    password TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `google_id`: Identificador de Google (en caso de login con Google)
- `email`: Correo electrónico (único)
- `name`: Nombre completo
- `given_name`: Nombre de pila (para integración con Google)
- `family_name`: Apellido (para integración con Google)
- `picture`: URL a imagen de perfil externa
- `display_image`: URL o ruta a la imagen de perfil mostrada
- `profile_image_blob`: Imagen de perfil almacenada como blob
- `locale`: Idioma preferido
- `verified_email`: Si el email ha sido verificado
- `password`: Hash de la contraseña
- `created_at`: Fecha de registro
- `updated_at`: Fecha de actualización

### Tabla: recurring_bills
Almacena información sobre gastos recurrentes (facturas, suscripciones).

```sql
CREATE TABLE IF NOT EXISTS bills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    amount REAL NOT NULL,
    due_date TEXT NOT NULL,
    paid BOOLEAN NOT NULL DEFAULT 0,
    overdue BOOLEAN NOT NULL DEFAULT 0,
    overdue_days INTEGER DEFAULT 0,
    recurring BOOLEAN NOT NULL DEFAULT 0,
    category TEXT NOT NULL,
    icon TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `name`: Nombre de la factura o suscripción
- `amount`: Monto
- `due_date`: Fecha de vencimiento
- `paid`: Indica si la factura ha sido pagada
- `overdue`: Indica si la factura está vencida
- `overdue_days`: Días de retraso
- `recurring`: Indica si es un gasto recurrente
- `category`: Categoría de la factura
- `icon`: Ícono representativo
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

### Tabla: savings
Almacena información sobre los ahorros del usuario.

```sql
CREATE TABLE IF NOT EXISTS savings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    goal REAL NOT NULL DEFAULT 0,
    available REAL NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `goal`: Monto objetivo de ahorro
- `available`: Monto actual ahorrado
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

### Tabla: savings_transactions
Almacena los movimientos relacionados con ahorros.

```sql
CREATE TABLE IF NOT EXISTS savings_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL,
    type TEXT NOT NULL,
    description TEXT,
    date TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto de la transacción
- `type`: Tipo (depósito o retiro)
- `description`: Descripción de la transacción
- `date`: Fecha de la transacción
- `created_at`: Fecha de registro

### Tabla: cash_bank_accounts
Almacena información sobre el dinero en efectivo y bancario del usuario.

```sql
CREATE TABLE IF NOT EXISTS cash_bank_accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    cash_amount REAL NOT NULL DEFAULT 0,
    bank_amount REAL NOT NULL DEFAULT 0,
    month TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `cash_amount`: Monto disponible en efectivo
- `bank_amount`: Monto disponible en cuenta bancaria
- `month`: Mes de registro
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

### Tabla: bank_transfers
Almacena información sobre transferencias entre efectivo y banco.

```sql
CREATE TABLE IF NOT EXISTS bank_transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    amount REAL NOT NULL,
    direction TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Campos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto de la transferencia
- `direction`: Dirección (efectivo-a-banco o banco-a-efectivo)
- `date`: Fecha de la transferencia
- `created_at`: Fecha de registro

## Implementación en el Código

### Modelos de Datos

#### CategoryModel (`lib/models/category_model.dart`)
Este modelo representa una categoría de ingreso o gasto y se corresponde con la tabla `categories`.

#### ExpenseModel (`lib/models/expense_model.dart`)
Representa un registro de gasto y se corresponde con la tabla `expenses`.

#### IncomeModel (`lib/models/income_model.dart`)
Representa un registro de ingreso y se corresponde con la tabla `incomes`.

#### UserModel (`lib/models/user_model.dart`)
Representa la información de un usuario registrado y se corresponde con la tabla `users`.

#### DashboardModel (`lib/models/dashboard_model.dart`)
Modelo que integra datos de múltiples tablas para mostrar en el dashboard. Contiene submodelos para:
- BudgetOverview: Vista general del presupuesto
- SavingsOverview: Vista general de ahorros
- CashBankDistribution: Distribución entre efectivo y banco
- FinanceMetrics: Métricas financieras generales
- Bill: Facturas y pagos recurrentes

### Servicios de Acceso a Datos

Los siguientes servicios gestionan las operaciones CRUD en la base de datos:

- `CategoryService` (`lib/services/category_service.dart`): Gestiona las operaciones relacionadas con categorías.
- `ExpenseService` (`lib/services/expense_service.dart`): Gestiona las operaciones relacionadas con gastos.
- `IncomeService` (`lib/services/income_service.dart`): Gestiona las operaciones relacionadas con ingresos.
- `ProfileService` (`lib/services/profile_service.dart`): Gestiona las operaciones relacionadas con perfiles de usuario.
- `SavingsService` (`lib/services/savings_service.dart`): Gestiona las operaciones relacionadas con ahorros.
- `BillsService` (`lib/services/bills_service.dart`): Gestiona las operaciones relacionadas con facturas recurrentes.
- `CashBankService` (`lib/services/cash_bank_service.dart`): Gestiona las operaciones relacionadas con efectivo y banco.
- `DashboardService` (`lib/services/dashboard_service.dart`): Integra datos de múltiples servicios para el dashboard.

## Directrices para Desarrolladores

1. **Soporte UTF-8**: Asegúrese de que todas las operaciones con la base de datos utilicen codificación UTF-8, especialmente para campos que puedan contener caracteres especiales o emojis.
2. **Versionado de Schema**: Cualquier cambio en el esquema debe ser versionado y debe incluir migraciones para usuarios existentes.
3. **Validación de Datos**: Valide los datos antes de insertarlos en la base de datos.
4. **Consultas Eficientes**: Optimice las consultas para minimizar el tiempo de respuesta.
5. **Transacciones**: Utilice transacciones para operaciones que afecten a múltiples tablas.

## Proceso de Actualización
Este documento debe actualizarse cuando:
1. Se añade o modifica una tabla
2. Se añaden o modifican campos
3. Se cambian relaciones entre tablas
4. Se agregan índices o restricciones

### Flujo de Pago de Facturas

Cuando una factura es pagada, se actualiza su estado en la tabla `bills` y se crea automáticamente un registro en la tabla `expenses`, siguiendo estos pasos:

1. Se marca la factura como pagada (`paid = true`) en `bills`.
2. Se crea un nuevo registro en `expenses` con:
   - `amount`: El mismo importe de la factura
   - `category`: La misma categoría de la factura
   - `payment_method`: El método de pago especificado al pagar la factura
   - `date`: La fecha actual en que se paga la factura (no la fecha de vencimiento)
   - `description`: Descripción generada automáticamente incluyendo el nombre de la factura

3. Se actualizan las tablas de balance para reflejar este movimiento:
   - `daily_balance`
   - `weekly_balance`
   - `monthly_balance`
   - `quarterly_balance`
   - `semiannual_balance`
   - `annual_balance`

4. Se ejecuta un proceso de recálculo en cascada para actualizar todos los balances a partir de la fecha de pago.

Este flujo asegura la consistencia entre las facturas pagadas y los gastos registrados, manteniendo actualizado el estado financiero del usuario en todos los periodos de tiempo.

## Herencia de Datos en Períodos Futuros

### Funcionalidad de Herencia Automática

A partir de la implementación de herencia de datos, cuando se consultan períodos futuros sin registros en las tablas `[periodtime]_cash_bank_balance`, el sistema automáticamente hereda los datos del último período disponible con información.

### Comportamiento del Sistema

**Escenario:** Usuario navega a un período futuro (ej: marzo 2025) que no tiene datos registrados.

**Proceso de herencia:**
1. El sistema busca datos para el período solicitado en la tabla correspondiente
2. Si no encuentra datos (`sql.ErrNoRows`), inicia búsqueda hacia atrás en el tiempo
3. Busca iterativamente en períodos anteriores hasta encontrar datos disponibles
4. Hereda y retorna los datos del último período con información
5. Registra en logs la herencia de datos para trazabilidad

### Tablas Afectadas

La herencia de datos aplica a todas las tablas de balance por período:
- `daily_cash_bank_balance`
- `weekly_cash_bank_balance`
- `monthly_cash_bank_balance`
- `quarterly_cash_bank_balance`
- `semiannual_cash_bank_balance`
- `annual_cash_bank_balance`

### Campos Heredados

Todos los campos de balance son heredados:
- `income_bank_amount` / `income_cash_amount`
- `expense_bank_amount` / `expense_cash_amount`
- `bill_bank_amount` / `bill_cash_amount`
- `bank_amount` / `cash_amount`
- `previous_bank_amount` / `previous_cash_amount`
- `balance_cash_amount` / `balance_bank_amount`
- `total_previous_balance` / `total_balance`

### Límites de Búsqueda

- **Máximo de períodos hacia atrás:** 24 períodos
- **Propósito:** Evitar búsquedas infinitas y mejorar rendimiento
- **Comportamiento:** Si no se encuentran datos en 24 períodos, retorna datos vacíos

### Impacto en la Interfaz de Usuario

Esta funcionalidad mejora la experiencia en:
- **Budget Overview Widget:** Muestra datos heredados en lugar de valores vacíos
- **Cash Bank Distribution Widget:** Mantiene distribución coherente en períodos futuros
- **Navegación temporal:** Experiencia fluida al avanzar en el tiempo

### Logging y Trazabilidad

El sistema registra automáticamente:
```
📊 Data inheritance: Using data from 2024-12 for requested period 2025-03 (user: user123)
```

### Consideraciones Técnicas

- **Rendimiento:** Búsqueda optimizada con límite de iteraciones
- **Consistencia:** Mantiene estructura de datos original
- **Compatibilidad:** No afecta funcionalidad existente para períodos con datos
- **Escalabilidad:** Funciona independientemente del tipo de período

## 🚨 CORRECCIÓN CRÍTICA: Filtrado de Facturas Pagadas (Enero 2025)

### **PROBLEMA IDENTIFICADO Y RESUELTO**

El microservicio `budget_overview_fetch` tenía un error crítico en el cálculo de gastos que afectaba la precisión de los datos presupuestarios.

#### ❌ **Problema Anterior:**
- El microservicio utilizaba campos preagregados (`bill_bank_amount`, `bill_cash_amount`) de las tablas de balance
- **NO** filtraba por el campo `paid = 1` en la tabla `bills`
- **Resultado:** Todas las facturas (pagadas y pendientes) se contaban como gastos realizados

#### ✅ **Solución Implementada:**
1. **Consultas directas a la tabla `bills`** con filtros apropiados:
   - `paid = 1` para gastos reales (expenses)
   - `paid = 0` para facturas pendientes
2. **Separación clara** entre gastos realizados y gastos pendientes
3. **Cálculos corregidos** en el budget overview

### **Archivos Modificados:**

#### `backend/budget_overview_fetch/main.go`

**Nuevas funciones añadidas:**
- `fetchPaidBillsAmount(userID, period, date)`: Consulta facturas pagadas (`paid = 1`)
- `fetchUnpaidBillsAmount(userID, period, date)`: Consulta facturas pendientes (`paid = 0`)

**Función modificada:**
- `calculateBudgetOverview()`: Ahora calcula correctamente:
  - `spentAmount` = gastos reales (expenses) + facturas pagadas
  - `upcomingAmount` = solo facturas pendientes (no pagadas)

### **Consultas SQL Corregidas:**

#### ✅ **Facturas Pagadas (Gastos Reales):**
```sql
SELECT 
    COALESCE(SUM(CASE WHEN payment_method = 'bank' THEN amount ELSE 0 END), 0) as bank_amount,
    COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0) as cash_amount
FROM bills 
WHERE user_id = ? AND paid = 1 AND [filtro_período]
```

#### ✅ **Facturas Pendientes:**
```sql
SELECT 
    COALESCE(SUM(CASE WHEN payment_method = 'bank' THEN amount ELSE 0 END), 0) as bank_amount,
    COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0) as cash_amount
FROM bills 
WHERE user_id = ? AND paid = 0 AND [filtro_período]
```

### **Impacto de la Corrección:**

1. **✅ Precisión Mejorada:**
   - Los gastos realizados ahora incluyen solo las facturas marcadas como pagadas
   - Las facturas pendientes se muestran separadamente como "upcoming"
   - El balance disponible refleja la realidad financiera del usuario

2. **✅ Logs Informativos:**
   ```
   💰 Budget Overview calculated (CORRECTED): Period=monthly, Date=2025-01, 
   SpentAmount=1500.00 (Expenses=800.00 + PaidBills=700.00), 
   UpcomingAmount=300.00 (UnpaidBills)
   ```

3. **✅ Compatibilidad Mantenida:**
   - La API mantiene la misma estructura de respuesta
   - No se requieren cambios en el frontend Flutter
   - Retrocompatibilidad completa

### **Campo Crítico en Tabla `bills`:**

| Campo | Valores | Uso en el Sistema |
|-------|---------|-------------------|
| `paid` | `0` = No pagada<br>`1` = Pagada | **⚠️ Campo crítico** para separar gastos reales de pendientes |

### **⚠️ Tablas de Balance Preagregadas (ADVERTENCIA):**

Las siguientes tablas contienen campos preagregados que **NO** consideran el estado `paid`:
- `monthly_cash_bank_balance`
- `daily_cash_bank_balance`
- `weekly_cash_bank_balance`
- `quarterly_cash_bank_balance`
- `semiannual_cash_bank_balance`
- `annual_cash_bank_balance`

**Campos problemáticos:**
- `bill_bank_amount` - Suma TODAS las facturas (pagadas y pendientes)
- `bill_cash_amount` - Suma TODAS las facturas (pagadas y pendientes)

**⚠️ IMPORTANTE:** NO usar estos campos para cálculos de gastos sin verificar manualmente el estado de pago en la tabla `bills`.

### **Validación Post-Corrección:**

Para verificar que la corrección funciona correctamente:

```sql
-- Verificar facturas pagadas vs pendientes
SELECT 
  paid,
  COUNT(*) as count_bills,
  SUM(amount) as total_amount
FROM bills 
WHERE user_id = 'usuario_test' 
GROUP BY paid;

-- Resultado esperado:
-- paid | count_bills | total_amount
-- 0    | X           | Y.YY        (pendientes)
-- 1    | Z           | W.WW        (pagadas)
```

---

**📅 Fecha de actualización:** Enero 2025  
**🔧 Responsable:** Sistema de corrección automática  
**✅ Estado:** Implementado y funcionando  
**📂 Archivos afectados:** `backend/budget_overview_fetch/main.go`

## 🚨 CORRECCIÓN CRÍTICA: Reclasificación de Facturas Pagadas (Enero 2025)

### **SEGUNDO PROBLEMA IDENTIFICADO Y RESUELTO**

Las funciones de reclasificación de facturas pagadas en `bills_management` tenían un error crítico que causaba duplicación de dinero disponible.

#### ❌ **Problema Anterior:**
- Al pagar una factura, las funciones `removeBillFromXXXBalances` restaban correctamente de `bill_xxx_amount`
- **PERO** también sumaban incorrectamente de vuelta a `cash_amount` y `bank_amount`
- **Resultado:** El dinero aparecía duplicado (disponible + como gasto) después del pago

#### ✅ **Solución Implementada:**
1. **Funciones corregidas en `backend/bills_management/main.go`:**
   - `removeBillFromDailyBalances()`
   - `removeBillFromWeeklyBalances()`
   - `removeBillFromMonthlyBalances()`

2. **Lógica simplificada:** Solo actualizar `bill_xxx_amount`, sin tocar balances disponibles

### **Código Corregido:**

#### ❌ **Antes (Incorrecto):**
```go
updateQuery := fmt.Sprintf(`
    UPDATE monthly_cash_bank_balance 
    SET %s = ?,
        cash_amount = cash_amount + ?,        // ❌ INCORRECTO
        bank_amount = bank_amount + ?,        // ❌ INCORRECTO
        balance_cash_amount = balance_cash_amount + ?,  // ❌ INCORRECTO
        balance_bank_amount = balance_bank_amount + ?   // ❌ INCORRECTO
    WHERE user_id = ? AND year_month = ?
`, columnName)
```

#### ✅ **Después (Correcto):**
```go
updateQuery := fmt.Sprintf(`
    UPDATE monthly_cash_bank_balance 
    SET %s = ?
    WHERE user_id = ? AND year_month = ?
`, columnName)
```

### **Flujo Correcto de Pago de Facturas:**

1. **Factura pendiente:** `bill_bank_amount = 50`, `expense_bank_amount = 0`
2. **Se paga la factura:**
   - ✅ `bill_bank_amount = 0` (resta 50)
   - ✅ `expense_bank_amount = 50` (suma 50) 
   - ✅ `cash_amount` y `bank_amount` NO se modifican (corrección aplicada)
3. **Resultado:** Transferencia limpia de bill a expense sin duplicación

### **Impacto de la Corrección:**

1. **✅ Eliminación de Duplicación:**
   - El dinero ya no aparece duplicado después del pago
   - Los balances disponibles reflejan correctamente la realidad
   - Las facturas se reclasifican apropiadamente a gastos

2. **✅ Logs Mejorados:**
   ```
   💰 Removed bill from monthly balance (CORRECTED): user=user123, 
   month=2025-01, amount=50.00→0.00, method=bank
   ```

3. **✅ Consistencia Restaurada:**
   - Todas las tablas de balance (daily, weekly, monthly) corregidas
   - Reclasificación atómica y consistente
   - Prevención de estados inconsistentes

### **Funciones Afectadas:**

| Función | Archivo | Corrección Aplicada |
|---------|---------|-------------------|
| `removeBillFromDailyBalances` | `bills_management/main.go` | ✅ Solo actualiza `bill_xxx_amount` |
| `removeBillFromWeeklyBalances` | `bills_management/main.go` | ✅ Solo actualiza `bill_xxx_amount` |
| `removeBillFromMonthlyBalances` | `bills_management/main.go` | ✅ Solo actualiza `bill_xxx_amount` |

**⚠️ IMPORTANTE:** Esta corrección es crítica para la integridad financiera del sistema. Sin ella, los usuarios verían balances incorrectamente inflados después de pagar facturas.