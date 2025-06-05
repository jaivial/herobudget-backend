Gracias por proporcionar la estructura detallada de las tablas. Con esta información, reescribiré el algoritmo para gestionar los movimientos de ingresos, gastos y facturas, asegurando que se actualicen correctamente las tablas relevantes, con un enfoque en la tabla `monthly_cash_bank_balance` para registrar los movimientos y calcular los saldos en cascada. La lógica seguirá los requisitos establecidos: registrar facturas con importe único por mes, propagar los saldos correctamente a través de `previous_cash_amount`, `previous_bank_amount`, y `total_previous_balance`, y evitar cualquier duplicación en los cálculos.

Dado que la estructura incluye múltiples tablas de balance (`daily_cash_bank_balance`, `weekly_cash_bank_balance`, etc.), me centraré en la tabla `monthly_cash_bank_balance` para los cálculos, ya que es la mencionada en el contexto de las facturas y los movimientos. Si necesitas que el algoritmo también actualice otras tablas de balance (como `daily_balance`, `weekly_balance`, etc.), puedo incluirlas, pero por ahora asumiré que el enfoque principal es `monthly_cash_bank_balance` y las tablas de transacciones (`incomes`, `expenses`, `bills`).

---

### **1. Lógica del algoritmo**
#### **Tablas relevantes**
- **bills**: Almacena las facturas con campos como `amount`, `start_date`, `duration_months`, `payment_day`, `payment_method`, y `paid`.
- **incomes**: Registra los ingresos con `amount`, `date`, `payment_method`, y `user_id`.
- **expenses**: Registra los gastos con `amount`, `date`, `payment_method`, y `user_id`.
- **monthly_cash_bank_balance**: Almacena los saldos mensuales con columnas como `income_cash_amount`, `income_bank_amount`, `expense_cash_amount`, `expense_bank_amount`, `bill_cash_amount`, `bill_bank_amount`, `cash_amount`, `bank_amount`, `previous_cash_amount`, `previous_bank_amount`, `balance_cash_amount`, `balance_bank_amount`, `total_previous_balance`, y `total_balance`.

#### **Reglas de negocio**
1. **Ingresos**:
   - Registrar en `incomes`.
   - Sumar el `amount` a `income_cash_amount` o `income_bank_amount` en `monthly_cash_bank_balance` según `payment_method`.
   - Actualizar `cash_amount`, `bank_amount`, y `total_balance` en el mes correspondiente.
   - Propagar los saldos a meses posteriores.

2. **Gastos**:
   - Registrar en `expenses`.
   - Sumar el `amount` a `expense_cash_amount` o `expense_bank_amount` en `monthly_cash_bank_balance`.
   - Restar el `amount` de `cash_amount` o `bank_amount`, y actualizar `total_balance`.
   - Propagar los saldos a meses posteriores.

3. **Facturas**:
   - Registrar en `bills`.
   - Para cada mes afectado (desde `start_date` hasta `duration_months`):
     - Sumar el `amount` a `bill_cash_amount` o `bill_bank_amount` en `monthly_cash_bank_balance` (solo una vez por mes).
     - Restar el `amount` de `cash_amount` o `bank_amount`, y actualizar `total_balance`.
   - Propagar los saldos a meses posteriores.
   - Si la factura se marca como `paid`, restar el `amount` de `bill_cash_amount` o `bill_bank_amount` en los meses afectados y recalcular saldos.

4. **Cálculo de saldos**:
   - Para cada mes:
     - `cash_amount = previous_cash_amount + income_cash_amount - expense_cash_amount - bill_cash_amount`
     - `bank_amount = previous_bank_amount + income_bank_amount - expense_bank_amount - bill_bank_amount`
     - `balance_cash_amount = cash_amount` (representa el saldo neto en efectivo)
     - `balance_bank_amount = bank_amount` (representa el saldo neto en banco)
     - `total_balance = balance_cash_amount + balance_bank_amount`
   - Los valores de `previous_cash_amount`, `previous_bank_amount`, y `total_previous_balance` se toman del mes anterior para propagar los efectos.

5. **Propagación en cascada**:
   - Cualquier movimiento (ingreso, gasto, factura, o factura pagada) en un mes desencadena un recálculo de los saldos desde ese mes hasta el último mes registrado en `monthly_cash_bank_balance`.

---

### **2. Algoritmo reescrito**
A continuación, presento el algoritmo en Python con SQLite, incluyendo las funciones para registrar ingresos, gastos, facturas, y marcar facturas como pagadas. El código está optimizado para la estructura de tablas proporcionada y evita duplicaciones en los cálculos.

```python
```python
from dateutil.relativedelta import relativedelta
from datetime import datetime
import sqlite3
import uuid

def update_cascade_balances(user_id, start_month, conn):
    cursor = conn.cursor()

    # Obtener todos los meses posteriores o iguales a start_month
    cursor.execute("""
        SELECT year_month FROM monthly_cash_bank_balance
        WHERE user_id = ? AND year_month >= ?
        ORDER BY year_month
    """, (user_id, start_month))
    months = [row[0] for row in cursor.fetchall()]

    for i, month in enumerate(months):
        # Obtener el mes anterior (si existe)
        previous_month = None
        if i > 0:
            previous_month = months[i-1]
        elif month != start_month:
            cursor.execute("""
                SELECT year_month FROM monthly_cash_bank_balance
                WHERE user_id = ? AND year_month < ? ORDER BY year_month DESC LIMIT 1
            """, (user_id, month))
            result = cursor.fetchone()
            previous_month = result[0] if result else None

        # Obtener saldos previos
        previous_cash_amount = 0
        previous_bank_amount = 0
        total_previous_balance = 0
        if previous_month:
            cursor.execute("""
                SELECT cash_amount, bank_amount, total_balance
                FROM monthly_cash_bank_balance
                WHERE user_id = ? AND year_month = ?
            """, (user_id, previous_month))
            result = cursor.fetchone()
            if result:
                previous_cash_amount, previous_bank_amount, total_previous_balance = result

        # Obtener movimientos del mes actual
        cursor.execute("""
            SELECT income_cash_amount, income_bank_amount,
                   expense_cash_amount, expense_bank_amount,
                   bill_cash_amount, bill_bank_amount
            FROM monthly_cash_bank_balance
            WHERE user_id = ? AND year_month = ?
        """, (user_id, month))
        result = cursor.fetchone()
        if not result:
            continue
        income_cash, income_bank, expense_cash, expense_bank, bill_cash, bill_bank = result

        # Calcular saldos del mes actual
        cash_amount = previous_cash_amount + income_cash - expense_cash - bill_cash
        bank_amount = previous_bank_amount + income_bank - expense_bank - bill_bank
        balance_cash_amount = cash_amount
        balance_bank_amount = bank_amount
        total_balance = balance_cash_amount + balance_bank_amount

        # Actualizar registro
        cursor.execute("""
            UPDATE monthly_cash_bank_balance
            SET cash_amount = ?,
                bank_amount = ?,
                balance_cash_amount = ?,
                balance_bank_amount = ?,
                total_balance = ?,
                previous_cash_amount = ?,
                previous_bank_amount = ?,
                total_previous_balance = ?
            WHERE user_id = ? AND year_month = ?
        """, (cash_amount, bank_amount, balance_cash_amount, balance_bank_amount,
              total_balance, previous_cash_amount, previous_bank_amount, total_previous_balance,
              user_id, month))

    conn.commit()

def add_income(user_id, amount, date, payment_method, category, description, conn):
    if amount <= 0 or payment_method not in ['cash', 'bank']:
        raise ValueError("Datos de ingreso inválidos")

    cursor = conn.cursor()
    month = datetime.strptime(date, '%Y-%m-%d').strftime('%Y-%m')

    # Registrar ingreso
    cursor.execute("""
        INSERT INTO incomes (user_id, amount, date, payment_method, category, description)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (user_id, amount, date, payment_method, category, description))

    # Crear o actualizar registro mensual
    cursor.execute("""
        INSERT OR IGNORE INTO monthly_cash_bank_balance (user_id, year_month)
        VALUES (?, ?)
    """, (user_id, month))

    # Actualizar ingresos
    if payment_method == 'cash':
        cursor.execute("""
            UPDATE monthly_cash_bank_balance
            SET income_cash_amount = income_cash_amount + ?
            WHERE user_id = ? AND year_month = ?
        """, (amount, user_id, month))
    else:  # bank
        cursor.execute("""
            UPDATE monthly_cash_bank_balance
            SET income_bank_amount = income_bank_amount + ?
            WHERE user_id = ? AND year_month = ?
        """, (amount, user_id, month))

    # Recalcular saldos en cascada
    update_cascade_balances(user_id, month, conn)

def add_expense(user_id, amount, date, payment_method, category, description, conn):
    if amount <= 0 or payment_method not in ['cash', 'bank']:
        raise ValueError("Datos de gasto inválidos")

    cursor = conn.cursor()
    month = datetime.strptime(date, '%Y-%m-%d').strftime('%Y-%m')

    # Registrar gasto
    cursor.execute("""
        INSERT INTO expenses (user_id, amount, date, payment_method, category, description)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (user_id, amount, date, payment_method, category, description))

    # Crear o actualizar registro mensual
    cursor.execute("""
        INSERT OR IGNORE INTO monthly_cash_bank_balance (user_id, year_month)
        VALUES (?, ?)
    """, (user_id, month))

    # Actualizar gastos
    if payment_method == 'cash':
        cursor.execute("""
            UPDATE monthly_cash_bank_balance
            SET expense_cash_amount = expense_cash_amount + ?
            WHERE user_id = ? AND year_month = ?
        """, (amount, user_id, month))
    else:  # bank
        cursor.execute("""
            UPDATE monthly_cash_bank_balance
            SET expense_bank_amount = expense_bank_amount + ?
            WHERE user_id = ? AND year_month = ?
        """, (amount, user_id, month))

    # Recalcular saldos en cascada
    update_cascade_balances(user_id, month, conn)

def add_bill(user_id, name, amount, due_date, payment_day, duration_months, payment_method, category, icon, conn, regularity='monthly'):
    if amount <= 0 or duration_months < 1 or payment_day not in range(1, 29) or payment_method not in ['cash', 'bank']:
        raise ValueError("Datos de factura inválidos")

    cursor = conn.cursor()
    start_date = due_date  # Asumimos que due_date es la fecha de inicio

    # Registrar factura
    cursor.execute("""
        INSERT INTO bills (user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, start_date, payment_day, duration_months, regularity, payment_method)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (user_id, name, amount, due_date, False, False, 0, True, category, icon, start_date, payment_day, duration_months, regularity, payment_method))
    bill_id = cursor.lastrowid

    # Calcular meses afectados
    current_date = datetime.strptime(start_date, '%Y-%m-%d')
    months_affected = [(current_date + relativedelta(months=i)).strftime('%Y-%m') for i in range(duration_months)]

    # Registrar gastos de factura
    for month in months_affected:
        # Crear o actualizar registro mensual
        cursor.execute("""
            INSERT OR IGNORE INTO monthly_cash_bank_balance (user_id, year_month)
            VALUES (?, ?)
        """, (user_id, month))

        # Registrar el importe de la factura solo para el mes actual
        if payment_method == 'cash':
            cursor.execute("""
                UPDATE monthly_cash_bank_balance
                SET bill_cash_amount = bill_cash_amount + ?
                WHERE user_id = ? AND year_month = ?
            """, (amount, user_id, month))
        else:  # bank
            cursor.execute("""
                UPDATE monthly_cash_bank_balance
                SET bill_bank_amount = bill_bank_amount + ?
                WHERE user_id = ? AND year_month = ?
            """, (amount, user_id, month))

    # Recalcular saldos en cascada desde el primer mes afectado
    update_cascade_balances(user_id, months_affected[0], conn)

    return bill_id

def mark_bill_paid(bill_id, conn):
    cursor = conn.cursor()

    # Obtener datos de la factura
    cursor.execute("""
        SELECT user_id, amount, start_date, duration_months, payment_method
        FROM bills WHERE id = ?
    """, (bill_id,))
    bill = cursor.fetchone()
    if not bill:
        raise ValueError("Factura no encontrada")
    user_id, amount, start_date, duration_months, payment_method = bill

    # Marcar factura como pagada
    cursor.execute("UPDATE bills SET paid = 1 WHERE id = ?", (bill_id,))

    # Calcular meses afectados
    current_date = datetime.strptime(start_date, '%Y-%m-%d')
    months_affected = [(current_date + relativedelta(months=i)).strftime('%Y-%m') for i in range(duration_months)]

    # Restar gastos de factura
    for month in months_affected:
        if payment_method == 'cash':
            cursor.execute("""
                UPDATE monthly_cash_bank_balance
                SET bill_cash_amount = bill_cash_amount - ?
                WHERE user_id = ? AND year_month = ?
            """, (amount, user_id, month))
        else:  # bank
            cursor.execute("""
                UPDATE monthly_cash_bank_balance
                SET bill_bank_amount = bill_bank_amount - ?
                WHERE user_id = ? AND year_month = ?
            """, (amount, user_id, month))

    # Recalcular saldos en cascada
    update_cascade_balances(user_id, months_affected[0], conn)
```
```

---

### **3. Explicación del algoritmo**
1. **update_cascade_balances**:
   - Obtiene todos los meses posteriores o iguales a `start_month` para el `user_id`.
   - Para cada mes:
     - Obtiene los saldos previos (`previous_cash_amount`, `previous_bank_amount`, `total_previous_balance`) del mes anterior.
     - Calcula los saldos del mes actual:
       - `cash_amount = previous_cash_amount + income_cash_amount - expense_cash_amount - bill_cash_amount`
       - `bank_amount = previous_bank_amount + income_bank_amount - expense_bank_amount - bill_bank_amount`
       - `balance_cash_amount = cash_amount`
       - `balance_bank_amount = bank_amount`
       - `total_balance = balance_cash_amount + balance_bank_amount`
     - Actualiza `monthly_cash_bank_balance` con los nuevos valores.

2. **add_income**:
   - Registra el ingreso en `incomes` con `category` y `description`.
   - Actualiza `income_cash_amount` o `income_bank_amount` en `monthly_cash_bank_balance` según `payment_method`.
   - Llama a `update_cascade_balances` para propagar los saldos.

3. **add_expense**:
   - Registra el gasto en `expenses` con `category` y `description`.
   - Actualiza `expense_cash_amount` o `expense_bank_amount` en `monthly_cash_bank_balance`.
   - Llama a `update_cascade_balances`.

4. **add_bill**:
   - Registra la factura en `bills` con todos los campos requeridos (`name`, `amount`, `due_date`, etc.).
   - Calcula los meses afectados según `start_date` y `duration_months`.
   - Para cada mes, suma el `amount` a `bill_cash_amount` o `bill_bank_amount` (sin acumulación).
   - Llama a `update_cascade_balances`.

5. **mark_bill_paid**:
   - Marca la factura como `paid` en `bills`.
   - Resta el `amount` de `bill_cash_amount` o `bill_bank_amount` en los meses afectados.
   - Llama a `update_cascade_balances`.

---

### **4. Ejemplo de funcionamiento**
Supongamos el siguiente escenario para `user_id = "123"`:
- **Marzo 2025**:
  - Ingreso en cash: 100, `date = '2025-03-01'`, `category = 'salary'`, `description = 'Monthly salary'`
  - Resultado en `monthly_cash_bank_balance`:
    - `year_month = '2025-03'`
    - `income_cash_amount = 100`
    - `cash_amount = 0 + 100 = 100`
    - `bank_amount = 0`
    - `balance_cash_amount = 100`
    - `balance_bank_amount = 0`
    - `total_balance = 100 + 0 = 100`
    - `previous_cash_amount = 0`, `previous_bank_amount = 0`, `total_previous_balance = 0`

- **Junio 2025**:
  - Ingreso en cash: 100, `date = '2025-06-01'`, `category = 'bonus'`, `description = 'Yearly bonus'`
  - Gasto en bank: 50, `date = '2025-06-01'`, `category = 'groceries'`, `description = 'Supermarket'`
  - Factura: `name = 'Internet'`, `amount = 20`, `due_date = '2025-06-01'`, `duration_months = 3`, `payment_method = 'cash'`, `category = 'utilities'`, `icon = '🌐'`
  - Resultado en `monthly_cash_bank_balance`:
    - `year_month = '2025-06'`
    - `income_cash_amount = 100`
    - `expense_bank_amount = 50`
    - `bill_cash_amount = 20`
    - `previous_cash_amount = 100` (de marzo)
    - `previous_bank_amount = 0` (de marzo)
    - `total_previous_balance = 100` (de marzo)
    - `cash_amount = 100 + 100 - 0 - 20 = 180`
    - `bank_amount = 0 + 0 - 50 - 0 = -50`
    - `balance_cash_amount = 180`
    - `balance_bank_amount = -50`
    - `total_balance = 180 + (-50) = 130`

- **Julio 2025**:
  - `bill_cash_amount = 20` (factura de junio)
  - `previous_cash_amount = 180` (de junio)
  - `previous_bank_amount = -50` (de junio)
  - `total_previous_balance = 130` (de junio)
  - `cash_amount = 180 + 0 - 0 - 20 = 160`
  - `bank_amount = -50 + 0 - 0 - 0 = -50`
  - `balance_cash_amount = 160`
  - `balance_bank_amount = -50`
  - `total_balance = 160 + (-50) = 110`

- **Agosto 2025**:
  - `bill_cash_amount = 20` (factura de junio)
  - `previous_cash_amount = 160` (de julio)
  - `previous_bank_amount = -50` (de julio)
  - `total_previous_balance = 110` (de julio)
  - `cash_amount = 160 + 0 - 0 - 20 = 140`
  - `bank_amount = -50 + 0 - 0 - 0 = -50`
  - `balance_cash_amount = 140`
  - `balance_bank_amount = -50`
  - `total_balance = 140 + (-50) = 90`

- **Nuevo ingreso en Marzo 2025** (bank: 50, `date = '2025-03-15'`, `category = 'freelance'`, `description = 'Project payment'):
  - Actualiza `monthly_cash_bank_balance` para marzo:
    - `income_bank_amount = 50`
    - `cash_amount = 100` (sin cambios)
    - `bank_amount = 0 + 50 = 50`
    - `balance_cash_amount = 100`
    - `balance_bank_amount = 50`
    - `total_balance = 100 + 50 = 150`
  - Recalcula en cascada:
    - **Junio**:
      - `previous_cash_amount = 100` (de marzo)
      - `previous_bank_amount = 50` (de marzo)
      - `total_previous_balance = 150` (de marzo)
      - `cash_amount = 100 + 100 - 0 - 20 = 180`
      - `bank_amount = 50 + 0 - 50 - 0 = 0`
      - `balance_cash_amount = 180`
      - `balance_bank_amount = 0`
      - `total_balance = 180 + 0 = 180`
    - **Julio**:
      - `previous_cash_amount = 180` (de junio)
      - `previous_bank_amount = 0` (de junio)
      - `total_previous_balance = 180` (de junio)
      - `cash_amount = 180 + 0 - 0 - 20 = 160`
      - `bank_amount = 0 + 0 - 0 - 0 = 0`
      - `balance_cash_amount = 160`
      - `balance_bank_amount = 0`
      - `total_balance = 160 + 0 = 160`
    - **Agosto**:
      - `previous_cash_amount = 160` (de julio)
      - `previous_bank_amount = 0` (de julio)
      - `total_previous_balance = 160` (de julio)
      - `cash_amount = 160 + 0 - 0 - 20 = 140`
      - `bank_amount = 0 + 0 - 0 - 0 = 0`
      - `balance_cash_amount = 140`
      - `balance_bank_amount = 0`
      - `total_balance = 140 + 0 = 140`

---

### **5. Consideraciones adicionales**
- **Otras tablas de balance**: Si necesitas actualizar tablas como `daily_cash_bank_balance`, `weekly_cash_bank_balance`, o `monthly_balance`, se puede extender el algoritmo para reflejar los movimientos en estas tablas. Por ejemplo, para `monthly_balance`, se sumarían los totales de `income_cash_amount + income_bank_amount` a `income_amount`, `expense_cash_amount + expense_bank_amount` a `expense_amount`, y `bill_cash_amount + bill_bank_amount` a `bills_amount`.
- **Integridad de datos**: El uso de transacciones (`conn.commit()` y `conn.rollback()`) es crucial para evitar inconsistencias.
- **Índices**: Crear índices en `monthly_cash_bank_balance (user_id, year_month)` y en `bills (user_id, start_date)` para optimizar consultas.
- **Validación**: Verificar formatos de fecha (`YYYY-MM-DD`), valores positivos para `amount`, y `payment_day` entre 1 y 28.
- **Optimización**: Para bases de datos grandes, limitar el recálculo en cascada o usar procesos asíncronos.

Este algoritmo respeta la estructura de las tablas proporcionadas y corrige los problemas anteriores, asegurando que las facturas se registren una sola vez por mes y que los saldos se propaguen correctamente. Si necesitas integrar otras tablas o más funcionalidades, házmelo saber.