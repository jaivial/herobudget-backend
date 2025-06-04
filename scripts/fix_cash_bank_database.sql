-- Corrección de Base de Datos Cash/Bank Management
-- Resuelve errores 500 en distribución y transferencias

-- Recrear tabla monthly_cash_bank_balance con estructura completa
DROP TABLE IF EXISTS monthly_cash_bank_balance;
CREATE TABLE monthly_cash_bank_balance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    year_month TEXT NOT NULL,
    income_bank_amount REAL DEFAULT 0,
    income_cash_amount REAL DEFAULT 0,
    expense_bank_amount REAL DEFAULT 0,
    expense_cash_amount REAL DEFAULT 0,
    bill_bank_amount REAL DEFAULT 0,
    bill_cash_amount REAL DEFAULT 0,
    bank_amount REAL DEFAULT 0,
    previous_bank_amount REAL DEFAULT 0,
    cash_amount REAL DEFAULT 0,
    previous_cash_amount REAL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    balance_cash_amount REAL DEFAULT 0,
    balance_bank_amount REAL DEFAULT 0,
    total_previous_balance REAL DEFAULT 0,
    total_balance REAL DEFAULT 0,
    UNIQUE(user_id, year_month)
);

-- Recrear tabla daily_cash_bank_balance 
DROP TABLE IF EXISTS daily_cash_bank_balance;
CREATE TABLE daily_cash_bank_balance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    income_bank_amount REAL DEFAULT 0,
    income_cash_amount REAL DEFAULT 0,
    expense_bank_amount REAL DEFAULT 0,
    expense_cash_amount REAL DEFAULT 0,
    bill_bank_amount REAL DEFAULT 0,
    bill_cash_amount REAL DEFAULT 0,
    bank_amount REAL DEFAULT 0,
    previous_bank_amount REAL DEFAULT 0,
    cash_amount REAL DEFAULT 0,
    previous_cash_amount REAL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    balance_cash_amount REAL DEFAULT 0,
    balance_bank_amount REAL DEFAULT 0,
    total_previous_balance REAL DEFAULT 0,
    total_balance REAL DEFAULT 0,
    UNIQUE(user_id, date)
);

-- Recrear tabla weekly_cash_bank_balance
DROP TABLE IF EXISTS weekly_cash_bank_balance;
CREATE TABLE weekly_cash_bank_balance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    year_week TEXT NOT NULL,
    income_bank_amount REAL DEFAULT 0,
    income_cash_amount REAL DEFAULT 0,
    expense_bank_amount REAL DEFAULT 0,
    expense_cash_amount REAL DEFAULT 0,
    bill_bank_amount REAL DEFAULT 0,
    bill_cash_amount REAL DEFAULT 0,
    bank_amount REAL DEFAULT 0,
    previous_bank_amount REAL DEFAULT 0,
    cash_amount REAL DEFAULT 0,
    previous_cash_amount REAL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    balance_cash_amount REAL DEFAULT 0,
    balance_bank_amount REAL DEFAULT 0,
    total_previous_balance REAL DEFAULT 0,
    total_balance REAL DEFAULT 0,
    UNIQUE(user_id, year_week)
);

-- Crear índices para optimización
CREATE INDEX IF NOT EXISTS idx_monthly_cash_bank_balance_user ON monthly_cash_bank_balance(user_id);
CREATE INDEX IF NOT EXISTS idx_monthly_cash_bank_balance_month ON monthly_cash_bank_balance(year_month);
CREATE INDEX IF NOT EXISTS idx_daily_cash_bank_balance_user ON daily_cash_bank_balance(user_id);  
CREATE INDEX IF NOT EXISTS idx_daily_cash_bank_balance_date ON daily_cash_bank_balance(date);
CREATE INDEX IF NOT EXISTS idx_weekly_cash_bank_balance_user ON weekly_cash_bank_balance(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_cash_bank_balance_week ON weekly_cash_bank_balance(year_week);

-- Insertar datos de ejemplo para user_id 19 (mes actual)
INSERT OR REPLACE INTO monthly_cash_bank_balance (
    user_id, year_month, 
    cash_amount, bank_amount, 
    balance_cash_amount, balance_bank_amount,
    total_balance
) VALUES (
    '19', '2025-06',
    1000.0, 2500.0,
    1000.0, 2500.0,
    3500.0
);

-- Insertar datos diarios para hoy
INSERT OR REPLACE INTO daily_cash_bank_balance (
    user_id, date,
    cash_amount, bank_amount,
    balance_cash_amount, balance_bank_amount,
    total_balance
) VALUES (
    '19', '2025-06-04',
    1000.0, 2500.0,
    1000.0, 2500.0,
    3500.0
);

-- Verificar datos insertados
SELECT 'Monthly balances:' as info;
SELECT user_id, year_month, cash_amount, bank_amount, total_balance 
FROM monthly_cash_bank_balance WHERE user_id = '19';

SELECT 'Daily balances:' as info;
SELECT user_id, date, cash_amount, bank_amount, total_balance 
FROM daily_cash_bank_balance WHERE user_id = '19'; 