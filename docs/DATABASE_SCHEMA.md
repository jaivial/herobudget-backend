# Documentación de la Base de Datos

## Introducción
Este documento describe la estructura de la base de datos utilizada en la aplicación Hero Budget, detallando tablas, columnas, relaciones y su implementación en el código.

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

### Otras tablas inferidas del modelo de datos

#### Tabla: expenses
Almacena los registros de gastos de los usuarios.

**Campos inferidos del modelo:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto del gasto
- `category_id`: Referencia a la categoría
- `date`: Fecha del gasto
- `description`: Descripción opcional
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

#### Tabla: incomes
Almacena los registros de ingresos de los usuarios.

**Campos inferidos del modelo:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `amount`: Monto del ingreso
- `category_id`: Referencia a la categoría
- `date`: Fecha del ingreso
- `description`: Descripción opcional
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

#### Tabla: users
Almacena la información de los usuarios registrados.

**Campos inferidos del modelo:**
- `id`: Identificador único
- `email`: Correo electrónico (único)
- `password_hash`: Hash de la contraseña
- `name`: Nombre completo
- `preferred_language`: Idioma preferido
- `profile_image`: URL o ruta a la imagen de perfil
- `created_at`: Fecha de registro
- `updated_at`: Fecha de actualización

#### Tabla: recurring_bills
Almacena información sobre gastos recurrentes (facturas, suscripciones).

**Campos inferidos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `name`: Nombre de la factura
- `amount`: Monto
- `frequency`: Frecuencia (mensual, anual, etc.)
- `due_date`: Fecha de vencimiento
- `category_id`: Referencia a la categoría
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

#### Tabla: savings
Almacena información sobre los ahorros del usuario.

**Campos inferidos:**
- `id`: Identificador único
- `user_id`: Identificador del usuario
- `name`: Nombre del objetivo de ahorro
- `target_amount`: Monto objetivo
- `current_amount`: Monto actual
- `target_date`: Fecha objetivo
- `created_at`: Fecha de creación
- `updated_at`: Fecha de actualización

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
Modelo que integra datos de múltiples tablas para mostrar en el dashboard.

### Servicios de Acceso a Datos

Los siguientes servicios gestionan las operaciones CRUD en la base de datos:

- `CategoryService` (`lib/services/category_service.dart`): Gestiona las operaciones relacionadas con categorías.
- `ExpenseService` (`lib/services/expense_service.dart`): Gestiona las operaciones relacionadas con gastos.
- `IncomeService` (`lib/services/income_service.dart`): Gestiona las operaciones relacionadas con ingresos.
- `ProfileService` (`lib/services/profile_service.dart`): Gestiona las operaciones relacionadas con perfiles de usuario.
- `SavingsService` (`lib/services/savings_service.dart`): Gestiona las operaciones relacionadas con ahorros.
- `BillsService` (`lib/services/bills_service.dart`): Gestiona las operaciones relacionadas con facturas recurrentes.
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

---
Última actualización: [Fecha actual] 