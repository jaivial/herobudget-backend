# Esquema de Base de Datos - Hero Budget (Parte 1: Tablas Principales)

## Descripción

Este documento describe la estructura de la base de datos SQLite utilizada en Hero Budget, incluyendo tablas, columnas y sus relaciones. Esta es la parte 1 que cubre las tablas principales del sistema.

## Archivos Relacionados

- [DATABASE_SCHEMA_part2.md](DATABASE_SCHEMA_part2.md) - Tablas de balance y distribución
- [DATABASE_SCHEMA_part3.md](DATABASE_SCHEMA_part3.md) - Tablas de períodos y configuración

## Tablas Principales

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
- Las facturas con `paid = 1` se incluyen en el historial de transacciones
- Las facturas con `paid = 0` aparecen en la lista de próximas facturas
- El campo `due_date` se usa como `date` en las consultas de historial de transacciones

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

## Relaciones entre Tablas

- `incomes.user_id` → `users.id`
- `expenses.user_id` → `users.id`
- `bills.user_id` → `users.id`
- `categories.user_id` → `users.id`
- `balances.user_id` → `users.id`

## Índices Recomendados

- `idx_incomes_user`: Índice en `user_id` en tabla `incomes`
- `idx_expenses_user`: Índice en `user_id` en tabla `expenses`
- `idx_bills_user`: Índice en `user_id` en tabla `bills`
- `idx_categories_user`: Índice en `user_id` en tabla `categories`

---
**Nota:** Este documento es parte 1 de 3. Consultar las otras partes para información completa sobre el esquema de base de datos. 