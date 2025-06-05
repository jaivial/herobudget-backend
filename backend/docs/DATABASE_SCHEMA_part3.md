# Esquema de Base de Datos - Hero Budget (Parte 3: Configuración y Metadatos)

## Descripción

Esta es la parte 3 de la documentación del esquema de base de datos que cubre las tablas de configuración, metadatos y otras funcionalidades del sistema.

## Archivos Relacionados

- [DATABASE_SCHEMA_part1.md](DATABASE_SCHEMA_part1.md) - Tablas principales
- [DATABASE_SCHEMA_part2.md](DATABASE_SCHEMA_part2.md) - Distribución y transacciones

## Tablas de Configuración

### Metas de Ahorro (`savings_goals`)

Almacena las metas de ahorro configuradas por los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| goal_amount | REAL | Cantidad objetivo de ahorro |
| period | TEXT | Período de la meta (monthly, quarterly, annual) |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Nota:** Tras la simplificación a período mensual, solo se mantendrán metas con `period = 'monthly'`.

### Configuración de Usuario (`user_settings`)

Almacena las preferencias y configuraciones de cada usuario.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario (único) |
| currency | TEXT | Moneda preferida (EUR, USD, etc.) |
| language | TEXT | Idioma preferido |
| theme | TEXT | Tema de la aplicación (light, dark, system) |
| notifications_enabled | BOOLEAN | Si las notificaciones están habilitadas |
| period_preference | TEXT | Período preferido para vistas **[OBSOLETO tras migración]** |
| created_at | TIMESTAMP | Fecha de creación del registro |
| updated_at | TIMESTAMP | Fecha de última actualización |

**Migración:** El campo `period_preference` será eliminado tras la migración a período mensual único.

### Sesiones de Usuario (`user_sessions`)

Almacena las sesiones activas de los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| session_token | TEXT | Token de sesión |
| device_info | TEXT | Información del dispositivo |
| ip_address | TEXT | Dirección IP de la sesión |
| expires_at | DATETIME | Fecha de expiración de la sesión |
| created_at | TIMESTAMP | Fecha de creación del registro |
| last_accessed_at | TIMESTAMP | Última vez que se accedió a la sesión |

## Tablas de Auditoría y Logs

### Logs de Transacciones (`transaction_logs`)

Almacena un registro de auditoría de todas las transacciones realizadas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| transaction_type | TEXT | Tipo de transacción (income, expense, bill) |
| transaction_id | INTEGER | ID de la transacción original |
| action | TEXT | Acción realizada (create, update, delete) |
| old_values | TEXT | Valores anteriores (JSON) |
| new_values | TEXT | Valores nuevos (JSON) |
| ip_address | TEXT | Dirección IP desde donde se realizó |
| user_agent | TEXT | Información del navegador/app |
| created_at | TIMESTAMP | Fecha de creación del registro |

### Sistema de Notificaciones (`notifications`)

Almacena las notificaciones para los usuarios.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| title | TEXT | Título de la notificación |
| message | TEXT | Mensaje de la notificación |
| type | TEXT | Tipo de notificación (bill_reminder, goal_reminder, etc.) |
| read | BOOLEAN | Si la notificación ha sido leída |
| data | TEXT | Datos adicionales (JSON) |
| created_at | TIMESTAMP | Fecha de creación del registro |
| read_at | TIMESTAMP | Fecha en que se marcó como leída |

## Tablas de Backup y Migración

### Historial de Migraciones (`migrations`)

Rastrea las migraciones de base de datos aplicadas.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| version | TEXT | Versión de la migración |
| description | TEXT | Descripción de la migración |
| applied_at | TIMESTAMP | Fecha de aplicación |

### Backup de Configuración (`config_backup`)

Almacena copias de seguridad de configuraciones importantes.

| Columna | Tipo | Descripción |
| ------- | ---- | ----------- |
| id | INTEGER | Identificador único (PK, autoincremento) |
| user_id | TEXT | ID del usuario |
| backup_type | TEXT | Tipo de backup (full, settings_only, etc.) |
| backup_data | TEXT | Datos del backup (JSON comprimido) |
| created_at | TIMESTAMP | Fecha de creación del backup |

## Índices de Rendimiento

### Índices por Tabla

- `idx_savings_goals_user`: `savings_goals(user_id)`
- `idx_user_settings_user`: `user_settings(user_id)` (único)
- `idx_user_sessions_user`: `user_sessions(user_id)`
- `idx_user_sessions_token`: `user_sessions(session_token)` (único)
- `idx_transaction_logs_user`: `transaction_logs(user_id)`
- `idx_transaction_logs_type`: `transaction_logs(transaction_type, transaction_id)`
- `idx_notifications_user`: `notifications(user_id)`
- `idx_notifications_unread`: `notifications(user_id, read)`

## Consideraciones de Seguridad

- Los tokens de sesión deben ser generados de forma segura
- Las contraseñas deben ser hasheadas antes del almacenamiento
- Los logs de transacciones contienen información sensible y deben protegerse
- Los backups deben ser encriptados antes del almacenamiento

## Limpieza Automática

### Tareas de Mantenimiento

- Eliminar sesiones expiradas más antiguas de 30 días
- Archivar logs de transacciones más antiguos de 1 año
- Eliminar notificaciones leídas más antiguas de 90 días
- Mantener solo los 10 backups más recientes por usuario

## Relaciones

- `savings_goals.user_id` → `users.id`
- `user_settings.user_id` → `users.id`
- `user_sessions.user_id` → `users.id`
- `transaction_logs.user_id` → `users.id`
- `notifications.user_id` → `users.id`
- `config_backup.user_id` → `users.id`

---
**Nota:** Este documento es parte 3 de 3. Para información completa sobre el esquema de base de datos, consultar todas las partes. 