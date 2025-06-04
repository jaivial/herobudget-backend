package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Bill struct {
	ID             int     `json:"id"`
	UserID         string  `json:"user_id"`
	Name           string  `json:"name"`
	Amount         float64 `json:"amount"`
	DueDate        string  `json:"due_date"`        // Mantenido para compatibilidad
	StartDate      string  `json:"start_date"`      // Nueva: fecha de inicio de la factura
	PaymentDay     int     `json:"payment_day"`     // Nuevo: día del mes para pago (1-31)
	DurationMonths int     `json:"duration_months"` // Nuevo: duración en meses
	Regularity     string  `json:"regularity"`      // Nuevo: frecuencia (daily, weekly, monthly, etc.)
	Paid           bool    `json:"paid"`
	Overdue        bool    `json:"overdue"`
	OverdueDays    int     `json:"overdue_days"`
	Recurring      bool    `json:"recurring"`
	Category       string  `json:"category"`
	Icon           string  `json:"icon"`
	PaymentMethod  string  `json:"payment_method,omitempty"`
	CreatedAt      string  `json:"created_at,omitempty"`
	UpdatedAt      string  `json:"updated_at,omitempty"`
}

type AddBillRequest struct {
	UserID         string  `json:"user_id"`
	Name           string  `json:"name"`
	Amount         float64 `json:"amount"`
	StartDate      string  `json:"start_date"`      // Nueva: fecha de inicio
	PaymentDay     int     `json:"payment_day"`     // Nuevo: día del mes para pago
	DurationMonths int     `json:"duration_months"` // Nuevo: duración en meses
	Regularity     string  `json:"regularity"`      // Nuevo: frecuencia de pago
	Paid           bool    `json:"paid"`
	Overdue        bool    `json:"overdue"`
	Recurring      bool    `json:"recurring"`
	Category       string  `json:"category"`
	Icon           string  `json:"icon"`
	PaymentMethod  string  `json:"payment_method,omitempty"` // "cash" o "bank"
}

type UpdateBillRequest struct {
	UserID         string  `json:"user_id"`
	BillID         int     `json:"bill_id"`
	Name           string  `json:"name,omitempty"`
	Amount         float64 `json:"amount,omitempty"`
	StartDate      string  `json:"start_date,omitempty"`
	PaymentDay     int     `json:"payment_day,omitempty"`
	DurationMonths int     `json:"duration_months,omitempty"`
	Regularity     string  `json:"regularity,omitempty"`
	Recurring      bool    `json:"recurring,omitempty"`
	Category       string  `json:"category,omitempty"`
	Icon           string  `json:"icon,omitempty"`
}

type PayBillRequest struct {
	UserID        string `json:"user_id"`
	BillID        int    `json:"bill_id"`
	YearMonth     string `json:"year_month"`               // Nuevo: mes específico a pagar (YYYY-MM)
	PaymentMethod string `json:"payment_method,omitempty"` // "cash" o "bank"
	Description   string `json:"description,omitempty"`    // Descripción adicional para el gasto generado
}

type DeleteBillRequest struct {
	UserID string `json:"user_id"`
	BillID int    `json:"bill_id"`
}

type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

type BillToExpenseRequest struct {
	UserID        string  `json:"user_id"`
	Amount        float64 `json:"amount"`
	Date          string  `json:"date"`
	Category      string  `json:"category"`
	PaymentMethod string  `json:"payment_method"`
	Description   string  `json:"description,omitempty"`
}

var (
	db *sql.DB
)

func init() {
	var err error

	// Get the current working directory
	cwd, err := os.Getwd()
	if err != nil {
		log.Fatalf("Failed to get current directory: %v", err)
	}

	// Construct absolute path to the database file
	dbPath := filepath.Join(cwd, "..", "google_auth", "users.db")
	log.Printf("Using database at: %s", dbPath)

	// Open the database connection
	db, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}

	// Test the connection
	if err = db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Create tables if they don't exist
	createTablesIfNotExist()

	// Add cash_amount and bank_amount columns to all balance tables if needed
	addCashBankColumnsToAllTables()

	log.Println("Database connection established successfully")
}

func createTablesIfNotExist() {
	// Create bills table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS bills (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			name TEXT NOT NULL,
			amount REAL NOT NULL,
			due_date TEXT NOT NULL,
			paid BOOLEAN NOT NULL,
			overdue BOOLEAN NOT NULL,
			overdue_days INTEGER NOT NULL,
			recurring BOOLEAN NOT NULL,
			category TEXT NOT NULL,
			icon TEXT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create bills table: %v", err)
	}

	// Create daily_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS daily_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			date TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, date)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create daily_balance table: %v", err)
	}

	// Create indices for daily_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_daily_balance_user ON daily_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on daily_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_daily_balance_date ON daily_balance(date)`)
	if err != nil {
		log.Fatalf("Failed to create index on daily_balance: %v", err)
	}

	// Create weekly_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS weekly_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_week TEXT NOT NULL,
			start_date TEXT NOT NULL,
			end_date TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_week)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create weekly_balance table: %v", err)
	}

	// Create indices for weekly_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_weekly_balance_user ON weekly_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on weekly_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_weekly_balance_week ON weekly_balance(year_week)`)
	if err != nil {
		log.Fatalf("Failed to create index on weekly_balance: %v", err)
	}

	// Create monthly_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS monthly_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_month TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_month)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create monthly_balance table: %v", err)
	}

	// Create indices for monthly_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_monthly_balance_user ON monthly_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on monthly_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_monthly_balance_month ON monthly_balance(year_month)`)
	if err != nil {
		log.Fatalf("Failed to create index on monthly_balance: %v", err)
	}

	// Create quarterly_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS quarterly_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_quarter TEXT NOT NULL,
			start_date TEXT NOT NULL,
			end_date TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_quarter)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create quarterly_balance table: %v", err)
	}

	// Create indices for quarterly_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_quarterly_balance_user ON quarterly_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on quarterly_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_quarterly_balance_quarter ON quarterly_balance(year_quarter)`)
	if err != nil {
		log.Fatalf("Failed to create index on quarterly_balance: %v", err)
	}

	// Create semiannual_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS semiannual_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_half TEXT NOT NULL,
			start_date TEXT NOT NULL,
			end_date TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_half)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create semiannual_balance table: %v", err)
	}

	// Create indices for semiannual_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_semiannual_balance_user ON semiannual_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on semiannual_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_semiannual_balance_half ON semiannual_balance(year_half)`)
	if err != nil {
		log.Fatalf("Failed to create index on semiannual_balance: %v", err)
	}

	// Create annual_balance table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS annual_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year TEXT NOT NULL,
			income_amount REAL NOT NULL DEFAULT 0,
			expense_amount REAL NOT NULL DEFAULT 0,
			bills_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create annual_balance table: %v", err)
	}

	// Create indices for annual_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_annual_balance_user ON annual_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on annual_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_annual_balance_year ON annual_balance(year)`)
	if err != nil {
		log.Fatalf("Failed to create index on annual_balance: %v", err)
	}

	// Add cash_amount and bank_amount columns to existing tables if they don't exist
	// For daily_balance
	alterTableSafely("daily_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// For weekly_balance
	alterTableSafely("weekly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// For monthly_balance
	alterTableSafely("monthly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// For quarterly_balance
	alterTableSafely("quarterly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// For semiannual_balance
	alterTableSafely("semiannual_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// For annual_balance
	alterTableSafely("annual_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "total_previous_balance", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "total_balance", "REAL NOT NULL DEFAULT 0")

	// Add new fields to bills table for recurring bills system
	alterTableSafely("bills", "start_date", "TEXT")
	alterTableSafely("bills", "payment_day", "INTEGER DEFAULT 1")
	alterTableSafely("bills", "duration_months", "INTEGER DEFAULT 1")
	alterTableSafely("bills", "regularity", "TEXT DEFAULT 'monthly'")

	// Create bill_payments table for tracking payment periods
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS bill_payments (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			bill_id INTEGER NOT NULL,
			user_id TEXT NOT NULL,
			year_month TEXT NOT NULL,
			paid BOOLEAN DEFAULT 0,
			payment_date TEXT,
			payment_method TEXT,
			UNIQUE(bill_id, year_month),
			FOREIGN KEY(bill_id) REFERENCES bills(id) ON DELETE CASCADE
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create bill_payments table: %v", err)
	}

	// Create indices for bill_payments
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_bill_payments_bill_id ON bill_payments(bill_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on bill_payments: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_bill_payments_user_month ON bill_payments(user_id, year_month)`)
	if err != nil {
		log.Fatalf("Failed to create index on bill_payments: %v", err)
	}

	// Create monthly_cash_bank_balance table if it doesn't exist
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS monthly_cash_bank_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_month TEXT NOT NULL,
			income_cash_amount REAL NOT NULL DEFAULT 0,
			income_bank_amount REAL NOT NULL DEFAULT 0,
			expense_cash_amount REAL NOT NULL DEFAULT 0,
			expense_bank_amount REAL NOT NULL DEFAULT 0,
			bill_cash_amount REAL NOT NULL DEFAULT 0,
			bill_bank_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			total_balance REAL NOT NULL DEFAULT 0,
			total_previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_month)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create monthly_cash_bank_balance table: %v", err)
	}

	// Create indices for monthly_cash_bank_balance
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_monthly_cash_bank_balance_user ON monthly_cash_bank_balance(user_id)`)
	if err != nil {
		log.Fatalf("Failed to create index on monthly_cash_bank_balance: %v", err)
	}
	_, err = db.Exec(`CREATE INDEX IF NOT EXISTS idx_monthly_cash_bank_balance_month ON monthly_cash_bank_balance(year_month)`)
	if err != nil {
		log.Fatalf("Failed to create index on monthly_cash_bank_balance: %v", err)
	}

	// Create similar tables for daily and weekly cash bank balance
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS daily_cash_bank_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			date TEXT NOT NULL,
			income_cash_amount REAL NOT NULL DEFAULT 0,
			income_bank_amount REAL NOT NULL DEFAULT 0,
			expense_cash_amount REAL NOT NULL DEFAULT 0,
			expense_bank_amount REAL NOT NULL DEFAULT 0,
			bill_cash_amount REAL NOT NULL DEFAULT 0,
			bill_bank_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			total_balance REAL NOT NULL DEFAULT 0,
			total_previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, date)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create daily_cash_bank_balance table: %v", err)
	}

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS weekly_cash_bank_balance (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			year_week TEXT NOT NULL,
			income_cash_amount REAL NOT NULL DEFAULT 0,
			income_bank_amount REAL NOT NULL DEFAULT 0,
			expense_cash_amount REAL NOT NULL DEFAULT 0,
			expense_bank_amount REAL NOT NULL DEFAULT 0,
			bill_cash_amount REAL NOT NULL DEFAULT 0,
			bill_bank_amount REAL NOT NULL DEFAULT 0,
			cash_amount REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			previous_cash_amount REAL NOT NULL DEFAULT 0,
			previous_bank_amount REAL NOT NULL DEFAULT 0,
			balance_cash_amount REAL NOT NULL DEFAULT 0,
			balance_bank_amount REAL NOT NULL DEFAULT 0,
			total_balance REAL NOT NULL DEFAULT 0,
			total_previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(user_id, year_week)
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create weekly_cash_bank_balance table: %v", err)
	}
}

// Helper function to safely alter a table by adding a column if it doesn't exist
func alterTableSafely(tableName, columnName, columnType string) {
	// Check if the column exists
	var existsQuery string
	if err := db.QueryRow(`SELECT sql FROM sqlite_master WHERE type='table' AND name=?`, tableName).Scan(&existsQuery); err != nil {
		log.Printf("Error checking table %s: %v", tableName, err)
		return
	}

	// If the column doesn't exist in the schema, add it
	if !strings.Contains(existsQuery, columnName) {
		_, err := db.Exec(fmt.Sprintf(`ALTER TABLE %s ADD COLUMN %s %s`, tableName, columnName, columnType))
		if err != nil {
			log.Printf("Error adding column %s to table %s: %v", columnName, tableName, err)
		} else {
			log.Printf("Added column %s to table %s successfully", columnName, tableName)
		}
	}
}

func main() {
	// Set up CORS middleware and routes
	http.HandleFunc("/bills", corsMiddleware(handleFetchBills))
	http.HandleFunc("/bills/add", corsMiddleware(handleAddBill))
	http.HandleFunc("/bills/pay", corsMiddleware(handlePayBill))
	http.HandleFunc("/bills/update", corsMiddleware(handleUpdateBill))
	http.HandleFunc("/bills/delete", corsMiddleware(handleDeleteBill))
	http.HandleFunc("/bills/upcoming", corsMiddleware(handleGetUpcomingBills))

	port := 8091
	log.Printf("Bills Management service started on :%d", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Set headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		// If it's OPTIONS, return with just the headers (preflight request)
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Call the next handler
		next(w, r)
	}
}

func handleFetchBills(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from query parameter
	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	// Get optional period and date parameters for period-specific queries
	period := r.URL.Query().Get("period")
	date := r.URL.Query().Get("date")

	// If period is provided, we need a date to determine the specific period
	var yearMonth string
	if period != "" && date != "" {
		// Calculate year-month based on period and date
		parsedDate, err := time.Parse("2006-01-02", date)
		if err != nil {
			// Try parsing as YYYY-MM format
			parsedDate, err = time.Parse("2006-01", date)
			if err != nil {
				sendErrorResponse(w, "Invalid date format, use YYYY-MM-DD or YYYY-MM", http.StatusBadRequest)
				return
			}
		}

		switch period {
		case "monthly":
			yearMonth = parsedDate.Format("2006-01")
		case "daily":
			yearMonth = parsedDate.Format("2006-01")
		default:
			yearMonth = parsedDate.Format("2006-01")
		}

		log.Printf("📅 Fetching bills for period %s, date %s, calculated year_month: %s", period, date, yearMonth)
	}

	// Get bills from database with period-specific information
	bills, err := fetchBillsWithPeriod(userID, yearMonth)
	if err != nil {
		log.Printf("Error fetching bills: %v", err)
		sendErrorResponse(w, "Error fetching bills", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ Fetched %d bills for user %s (period: %s)", len(bills), userID, yearMonth)

	// Return bills as JSON
	sendSuccessResponse(w, "Bills fetched successfully", bills)
}

func handleAddBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var addRequest AddBillRequest
	err := json.NewDecoder(r.Body).Decode(&addRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if addRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}
	if addRequest.Name == "" {
		sendErrorResponse(w, "Bill name is required", http.StatusBadRequest)
		return
	}
	if addRequest.Amount <= 0 {
		sendErrorResponse(w, "Amount must be greater than 0", http.StatusBadRequest)
		return
	}
	if addRequest.StartDate == "" {
		sendErrorResponse(w, "Start date is required", http.StatusBadRequest)
		return
	}
	if addRequest.PaymentDay < 1 || addRequest.PaymentDay > 28 {
		sendErrorResponse(w, "Payment day must be between 1 and 28", http.StatusBadRequest)
		return
	}
	if addRequest.DurationMonths < 1 {
		sendErrorResponse(w, "Duration must be at least 1 month", http.StatusBadRequest)
		return
	}
	if addRequest.PaymentMethod != "cash" && addRequest.PaymentMethod != "bank" {
		sendErrorResponse(w, "Payment method must be 'cash' or 'bank'", http.StatusBadRequest)
		return
	}

	// Validate date format
	_, err = time.Parse("2006-01-02", addRequest.StartDate)
	if err != nil {
		sendErrorResponse(w, "Invalid start date format, use YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	// Set defaults
	if addRequest.Category == "" {
		addRequest.Category = "general"
	}
	if addRequest.Icon == "" {
		addRequest.Icon = "💳"
	}
	if addRequest.Regularity == "" {
		addRequest.Regularity = "monthly"
	}

	// Use the new algorithm to add the bill
	billID, err := AddBillToBalance(
		addRequest.UserID,
		addRequest.Name,
		addRequest.Amount,
		addRequest.StartDate,
		addRequest.PaymentDay,
		addRequest.DurationMonths,
		addRequest.PaymentMethod,
		addRequest.Category,
		addRequest.Icon,
		addRequest.Regularity,
	)

	if err != nil {
		log.Printf("Error adding bill: %v", err)
		sendErrorResponse(w, "Error adding bill", http.StatusInternalServerError)
		return
	}

	// Fetch the created bill for response
	bill, err := fetchBillByID(billID, addRequest.UserID)
	if err != nil {
		log.Printf("Error fetching created bill: %v", err)
		sendErrorResponse(w, "Bill created but error fetching details", http.StatusInternalServerError)
		return
	}

	log.Printf("✅ Bill %d added successfully using new algorithm for user %s", billID, addRequest.UserID)
	sendSuccessResponse(w, "Bill added successfully with correct balance algorithm", bill)
}

func handlePayBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payRequest PayBillRequest
	err := json.NewDecoder(r.Body).Decode(&payRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request
	if payRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}
	if payRequest.BillID <= 0 {
		sendErrorResponse(w, "Valid bill ID is required", http.StatusBadRequest)
		return
	}
	if payRequest.YearMonth == "" {
		sendErrorResponse(w, "Year-month is required (format: YYYY-MM)", http.StatusBadRequest)
		return
	}

	// Validate year-month format
	_, err = time.Parse("2006-01", payRequest.YearMonth)
	if err != nil {
		sendErrorResponse(w, "Invalid year-month format, use YYYY-MM", http.StatusBadRequest)
		return
	}

	// Use the new algorithm to mark bill as paid (NO conversion to expense)
	err = MarkBillAsPaid(payRequest.BillID, payRequest.UserID, payRequest.YearMonth)
	if err != nil {
		log.Printf("Error marking bill as paid: %v", err)
		sendErrorResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Get updated bill information
	bill, err := fetchBillByID(payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error fetching bill details: %v", err)
		sendErrorResponse(w, "Payment processed but error fetching bill details", http.StatusInternalServerError)
		return
	}

	// Get payment information for response
	var totalPayments, paidPayments int
	err = db.QueryRow(`
		SELECT COUNT(*) as total, SUM(CASE WHEN paid = 1 THEN 1 ELSE 0 END) as paid_count
		FROM bill_payments WHERE bill_id = ?
	`, payRequest.BillID).Scan(&totalPayments, &paidPayments)
	if err != nil {
		log.Printf("Error getting payment stats: %v", err)
	}

	responseData := map[string]interface{}{
		"bill_id":            bill.ID,
		"paid_month":         payRequest.YearMonth,
		"amount":             bill.Amount,
		"payment_method":     bill.PaymentMethod,
		"total_payments":     totalPayments,
		"completed_payments": paidPayments,
		"bill_completed":     bill.Paid,
		"bill_details":       bill,
		"algorithm_note":     "Bill remains as bill (NOT converted to expense) with cascade balance recalculation",
	}

	log.Printf("✅ Bill %d payment for %s marked as paid using correct algorithm (NO expense conversion)", payRequest.BillID, payRequest.YearMonth)
	sendSuccessResponse(w, "Bill payment marked as paid successfully with correct algorithm", responseData)
}

func handleDeleteBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var deleteRequest DeleteBillRequest
	err := json.NewDecoder(r.Body).Decode(&deleteRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if deleteRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}
	if deleteRequest.BillID <= 0 {
		sendErrorResponse(w, "Valid bill ID is required", http.StatusBadRequest)
		return
	}

	// Delete the bill
	err = deleteBill(deleteRequest.BillID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error deleting bill: %v", err)
		sendErrorResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("✅ Bill %d deleted successfully for user %s", deleteRequest.BillID, deleteRequest.UserID)
	sendSuccessResponse(w, "Bill deleted successfully", map[string]interface{}{
		"bill_id": deleteRequest.BillID,
		"deleted": true,
	})
}

func handleGetUpcomingBills(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from query parameter
	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	// Get optional date parameter (defaults to current month)
	dateParam := r.URL.Query().Get("date")
	var targetMonth string
	if dateParam != "" {
		parsedDate, err := time.Parse("2006-01-02", dateParam)
		if err != nil {
			// Try parsing as YYYY-MM format
			parsedDate, err = time.Parse("2006-01", dateParam)
			if err != nil {
				sendErrorResponse(w, "Invalid date format, use YYYY-MM-DD or YYYY-MM", http.StatusBadRequest)
				return
			}
		}
		targetMonth = parsedDate.Format("2006-01")
	} else {
		// Default to current month
		targetMonth = time.Now().Format("2006-01")
	}

	// Get upcoming bills for the specified month
	query := `
		SELECT 
			b.id, b.user_id, b.name, b.amount, b.due_date, b.start_date, b.payment_day, 
			b.duration_months, b.regularity, bp.paid, b.overdue, b.overdue_days, 
			b.recurring, b.category, b.icon, b.payment_method, b.created_at, b.updated_at,
			bp.payment_date
		FROM bills b 
		INNER JOIN bill_payments bp ON b.id = bp.bill_id
		WHERE b.user_id = ? AND bp.year_month = ? AND bp.paid = 0
		ORDER BY b.payment_day ASC, b.id ASC
	`

	rows, err := db.Query(query, userID, targetMonth)
	if err != nil {
		log.Printf("Error fetching upcoming bills: %v", err)
		sendErrorResponse(w, "Error fetching upcoming bills", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var upcomingBills []Bill
	for rows.Next() {
		var bill Bill
		var createdAt, updatedAt, paymentDate sql.NullString
		var paymentMethod sql.NullString

		err := rows.Scan(
			&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate,
			&bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity,
			&bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring,
			&bill.Category, &bill.Icon, &paymentMethod, &createdAt, &updatedAt,
			&paymentDate,
		)
		if err != nil {
			log.Printf("Error scanning upcoming bill: %v", err)
			continue
		}

		if createdAt.Valid {
			bill.CreatedAt = createdAt.String
		}
		if updatedAt.Valid {
			bill.UpdatedAt = updatedAt.String
		}
		if paymentMethod.Valid {
			bill.PaymentMethod = paymentMethod.String
		}

		// Calculate the correct due date for the specific month
		bill.DueDate = calculateDueDateForPeriod(bill.StartDate, bill.PaymentDay, targetMonth)

		upcomingBills = append(upcomingBills, bill)
	}

	log.Printf("✅ Fetched %d upcoming bills for user %s in month %s", len(upcomingBills), userID, targetMonth)

	responseData := map[string]interface{}{
		"month":          targetMonth,
		"upcoming_bills": upcomingBills,
		"total_amount":   calculateTotalUpcomingAmount(upcomingBills),
		"bill_count":     len(upcomingBills),
	}

	sendSuccessResponse(w, "Upcoming bills fetched successfully", responseData)
}

// Helper function to calculate total amount of upcoming bills
func calculateTotalUpcomingAmount(bills []Bill) float64 {
	var total float64
	for _, bill := range bills {
		total += bill.Amount
	}
	return total
}

// Helper functions for bills_management

// sendErrorResponse - Helper function to send error responses
func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	response := ApiResponse{
		Success: false,
		Message: message,
	}
	json.NewEncoder(w).Encode(response)
}

// sendSuccessResponse - Helper function to send success responses
func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	response := ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	}
	json.NewEncoder(w).Encode(response)
}

// fetchBillByID - Fetch a specific bill by ID and user_id
func fetchBillByID(billID int, userID string) (*Bill, error) {
	query := `
		SELECT id, user_id, name, amount, due_date, start_date, payment_day, 
		       duration_months, regularity, paid, overdue, overdue_days, 
		       recurring, category, icon, payment_method, created_at, updated_at
		FROM bills 
		WHERE id = ? AND user_id = ?
	`

	var bill Bill
	var createdAt, updatedAt sql.NullString
	var paymentMethod sql.NullString

	err := db.QueryRow(query, billID, userID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate,
		&bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity,
		&bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring,
		&bill.Category, &bill.Icon, &paymentMethod, &createdAt, &updatedAt,
	)

	if err != nil {
		return nil, err
	}

	if createdAt.Valid {
		bill.CreatedAt = createdAt.String
	}
	if updatedAt.Valid {
		bill.UpdatedAt = updatedAt.String
	}
	if paymentMethod.Valid {
		bill.PaymentMethod = paymentMethod.String
	}

	return &bill, nil
}

// fetchBills - Helper function to fetch bills from database
func fetchBills(userID string) ([]Bill, error) {
	query := `
		SELECT id, user_id, name, amount, due_date, start_date, payment_day, 
		       duration_months, regularity, paid, overdue, overdue_days, 
		       recurring, category, icon, payment_method, created_at, updated_at
		FROM bills 
		WHERE user_id = ? 
		ORDER BY id ASC
	`

	rows, err := db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bills []Bill
	for rows.Next() {
		var bill Bill
		var createdAt, updatedAt sql.NullString
		var paymentMethod sql.NullString

		err := rows.Scan(
			&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate,
			&bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity,
			&bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring,
			&bill.Category, &bill.Icon, &paymentMethod, &createdAt, &updatedAt,
		)
		if err != nil {
			log.Printf("Error scanning bill: %v", err)
			continue
		}

		if createdAt.Valid {
			bill.CreatedAt = createdAt.String
		}
		if updatedAt.Valid {
			bill.UpdatedAt = updatedAt.String
		}
		if paymentMethod.Valid {
			bill.PaymentMethod = paymentMethod.String
		}

		bills = append(bills, bill)
	}

	return bills, nil
}

// fetchBillsWithPeriod retrieves bills with period-specific payment status
func fetchBillsWithPeriod(userID string, yearMonth string) ([]Bill, error) {
	var bills []Bill
	var query string
	var args []interface{}

	if yearMonth != "" {
		// Query for bills that have a payment record for the specific period
		query = `
			SELECT 
				b.id, b.user_id, b.name, b.amount, b.due_date, b.start_date, b.payment_day, 
				b.duration_months, b.regularity, 
				bp.paid,
				b.overdue, b.overdue_days, b.recurring, b.category, b.icon, 
				b.payment_method, b.created_at, b.updated_at,
				bp.payment_date, bp.payment_method as period_payment_method
			FROM bills b 
			INNER JOIN bill_payments bp ON b.id = bp.bill_id
			WHERE b.user_id = ? AND bp.year_month = ?
			ORDER BY b.id ASC
		`
		args = []interface{}{userID, yearMonth}
	} else {
		// Fallback to original query without period-specific information
		query = `
			SELECT id, user_id, name, amount, due_date, start_date, payment_day, 
			       duration_months, regularity, paid, overdue, overdue_days, 
			       recurring, category, icon, payment_method, created_at, updated_at,
			       NULL as payment_date, NULL as period_payment_method
			FROM bills 
			WHERE user_id = ? 
			ORDER BY id ASC
		`
		args = []interface{}{userID}
	}

	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query bills: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var bill Bill
		var createdAt, updatedAt sql.NullString
		var paymentMethod sql.NullString
		var paymentDate, periodPaymentMethod sql.NullString

		err := rows.Scan(
			&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate,
			&bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity,
			&bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring,
			&bill.Category, &bill.Icon, &paymentMethod, &createdAt, &updatedAt,
			&paymentDate, &periodPaymentMethod,
		)
		if err != nil {
			log.Printf("Error scanning bill: %v", err)
			continue
		}

		if createdAt.Valid {
			bill.CreatedAt = createdAt.String
		}
		if updatedAt.Valid {
			bill.UpdatedAt = updatedAt.String
		}
		if paymentMethod.Valid {
			bill.PaymentMethod = paymentMethod.String
		}

		// Set payment method from period-specific data if available
		if periodPaymentMethod.Valid && periodPaymentMethod.String != "" {
			bill.PaymentMethod = periodPaymentMethod.String
		}

		// Calculate the correct due_date for the specific period
		if yearMonth != "" {
			bill.DueDate = calculateDueDateForPeriod(bill.StartDate, bill.PaymentDay, yearMonth)
		}

		bills = append(bills, bill)
	}

	return bills, nil
}

// calculateDueDateForPeriod calculates the correct due date for a specific period
func calculateDueDateForPeriod(startDate string, paymentDay int, yearMonth string) string {
	// Parse the yearMonth to get the target month
	targetDate, err := time.Parse("2006-01", yearMonth)
	if err != nil {
		log.Printf("Error parsing yearMonth %s: %v", yearMonth, err)
		return startDate // Fallback to start date
	}

	year := targetDate.Year()
	month := targetDate.Month()

	// Ensure payment day doesn't exceed days in the target month
	lastDayOfMonth := time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
	if paymentDay > lastDayOfMonth {
		paymentDay = lastDayOfMonth
	}

	// Create the due date for the specific period
	dueDate := time.Date(year, month, paymentDay, 0, 0, 0, 0, time.UTC)
	return dueDate.Format("2006-01-02")
}

// deleteBill - Helper function to delete a bill
func deleteBill(billID int, userID string) error {
	// First, verify bill exists
	_, err := fetchBillByID(billID, userID)
	if err != nil {
		return fmt.Errorf("bill not found: %v", err)
	}

	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %v", err)
	}
	defer tx.Rollback()

	// Delete bill payments
	_, err = tx.Exec("DELETE FROM bill_payments WHERE bill_id = ?", billID)
	if err != nil {
		return fmt.Errorf("error deleting bill payments: %v", err)
	}

	// Delete the bill
	_, err = tx.Exec("DELETE FROM bills WHERE id = ? AND user_id = ?", billID, userID)
	if err != nil {
		return fmt.Errorf("error deleting bill: %v", err)
	}

	if err = tx.Commit(); err != nil {
		return fmt.Errorf("error committing transaction: %v", err)
	}

	// TODO: Clean up balance records related to this bill
	log.Printf("✅ Bill %d deleted successfully", billID)
	return nil
}

// handleUpdateBill - Placeholder for update bill handler
func handleUpdateBill(w http.ResponseWriter, r *http.Request) {
	sendErrorResponse(w, "Update bill functionality not implemented yet", http.StatusNotImplemented)
}

// addCashBankColumnsToAllTables - Helper function to add cash/bank columns to all balance tables
func addCashBankColumnsToAllTables() {
	// This function ensures backward compatibility by adding new columns to existing tables
	log.Println("Checking and adding cash/bank columns to balance tables...")

	tables := []string{
		"daily_cash_bank_balance",
		"weekly_cash_bank_balance",
		"monthly_cash_bank_balance",
		"quarterly_cash_bank_balance",
		"semiannual_cash_bank_balance",
		"annual_cash_bank_balance",
	}

	for _, tableName := range tables {
		// Check if table exists first
		var exists int
		err := db.QueryRow("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?", tableName).Scan(&exists)
		if err != nil || exists == 0 {
			continue
		}

		// Add missing columns if needed
		alterTableSafely(tableName, "cash_amount", "REAL")
		alterTableSafely(tableName, "bank_amount", "REAL")
		alterTableSafely(tableName, "previous_cash_amount", "REAL")
		alterTableSafely(tableName, "previous_bank_amount", "REAL")
		alterTableSafely(tableName, "balance_cash_amount", "REAL")
		alterTableSafely(tableName, "balance_bank_amount", "REAL")
		alterTableSafely(tableName, "total_previous_balance", "REAL")
		alterTableSafely(tableName, "total_balance", "REAL")
	}
}

// UpdateCascadeBalances recalcula los saldos en cascada desde startMonth
func UpdateCascadeBalances(userID string, startMonth string) error {
	// Obtener todos los meses posteriores o iguales a startMonth
	rows, err := db.Query(`
		SELECT year_month FROM monthly_cash_bank_balance
		WHERE user_id = ? AND year_month >= ?
		ORDER BY year_month
	`, userID, startMonth)
	if err != nil {
		return fmt.Errorf("error fetching months: %v", err)
	}
	defer rows.Close()

	var months []string
	for rows.Next() {
		var month string
		if err := rows.Scan(&month); err != nil {
			return fmt.Errorf("error scanning month: %v", err)
		}
		months = append(months, month)
	}

	for i, month := range months {
		// Obtener el mes anterior (si existe)
		var previousMonth string
		if i > 0 {
			previousMonth = months[i-1]
		} else if month != startMonth {
			row := db.QueryRow(`
				SELECT year_month FROM monthly_cash_bank_balance
				WHERE user_id = ? AND year_month < ? ORDER BY year_month DESC LIMIT 1
			`, userID, month)
			if err := row.Scan(&previousMonth); err != nil && err != sql.ErrNoRows {
				return fmt.Errorf("error fetching previous month: %v", err)
			}
		}

		// Obtener saldos previos
		var previousCashAmount, previousBankAmount, totalPreviousBalance float64
		if previousMonth != "" {
			err := db.QueryRow(`
				SELECT cash_amount, bank_amount, total_balance
				FROM monthly_cash_bank_balance
				WHERE user_id = ? AND year_month = ?
			`, userID, previousMonth).Scan(&previousCashAmount, &previousBankAmount, &totalPreviousBalance)
			if err != nil && err != sql.ErrNoRows {
				return fmt.Errorf("error fetching previous balances: %v", err)
			}
		}

		// Obtener movimientos del mes actual
		var incomeCash, incomeBank, expenseCash, expenseBank, billCash, billBank float64
		err := db.QueryRow(`
			SELECT income_cash_amount, income_bank_amount,
			       expense_cash_amount, expense_bank_amount,
			       bill_cash_amount, bill_bank_amount
			FROM monthly_cash_bank_balance
			WHERE user_id = ? AND year_month = ?
		`, userID, month).Scan(&incomeCash, &incomeBank, &expenseCash, &expenseBank, &billCash, &billBank)
		if err != nil {
			return fmt.Errorf("error fetching current month data: %v", err)
		}

		// Calcular saldos del mes actual
		cashAmount := previousCashAmount + incomeCash - expenseCash - billCash
		bankAmount := previousBankAmount + incomeBank - expenseBank - billBank
		balanceCashAmount := cashAmount
		balanceBankAmount := bankAmount
		totalBalance := balanceCashAmount + balanceBankAmount

		// Actualizar registro
		_, err = db.Exec(`
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
		`, cashAmount, bankAmount, balanceCashAmount, balanceBankAmount,
			totalBalance, previousCashAmount, previousBankAmount, totalPreviousBalance,
			userID, month)
		if err != nil {
			return fmt.Errorf("error updating balance for month %s: %v", month, err)
		}
	}

	return nil
}

// AddBillToBalance registra una factura y sus pagos mensuales usando el algoritmo correcto
func AddBillToBalance(userID, name string, amount float64, dueDate string, paymentDay, durationMonths int, paymentMethod, category, icon, regularity string) (int, error) {
	if amount <= 0 || durationMonths < 1 || paymentDay < 1 || paymentDay > 28 || (paymentMethod != "cash" && paymentMethod != "bank") {
		return 0, fmt.Errorf("invalid bill data")
	}

	tx, err := db.Begin()
	if err != nil {
		return 0, fmt.Errorf("error starting transaction: %v", err)
	}
	defer tx.Rollback()

	startDate := dueDate // Asumimos que due_date es la fecha de inicio

	// Registrar factura
	result, err := tx.Exec(`
		INSERT INTO bills (user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, start_date, payment_day, duration_months, regularity, payment_method)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, userID, name, amount, dueDate, false, false, 0, true, category, icon, startDate, paymentDay, durationMonths, regularity, paymentMethod)
	if err != nil {
		return 0, fmt.Errorf("error inserting bill: %v", err)
	}

	billID, err := result.LastInsertId()
	if err != nil {
		return 0, fmt.Errorf("error getting bill ID: %v", err)
	}

	// Calcular meses afectados
	currentDate, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return 0, fmt.Errorf("invalid start date format: %v", err)
	}

	for i := 0; i < durationMonths; i++ {
		monthDate := currentDate.AddDate(0, i, 0)
		month := monthDate.Format("2006-01")

		// Crear registro en bill_payments
		_, err = tx.Exec(`
			INSERT INTO bill_payments (bill_id, user_id, year_month, paid, payment_date, payment_method)
			VALUES (?, ?, ?, ?, ?, ?)
		`, billID, userID, month, false, nil, paymentMethod)
		if err != nil {
			return 0, fmt.Errorf("error creating bill payment record: %v", err)
		}

		// Crear o actualizar registro mensual
		_, err = tx.Exec(`
			INSERT OR IGNORE INTO monthly_cash_bank_balance (user_id, year_month)
			VALUES (?, ?)
		`, userID, month)
		if err != nil {
			return 0, fmt.Errorf("error creating monthly record: %v", err)
		}

		// Registrar el importe de la factura para este mes
		if paymentMethod == "cash" {
			_, err = tx.Exec(`
				UPDATE monthly_cash_bank_balance
				SET bill_cash_amount = bill_cash_amount + ?
				WHERE user_id = ? AND year_month = ?
			`, amount, userID, month)
		} else {
			_, err = tx.Exec(`
				UPDATE monthly_cash_bank_balance
				SET bill_bank_amount = bill_bank_amount + ?
				WHERE user_id = ? AND year_month = ?
			`, amount, userID, month)
		}
		if err != nil {
			return 0, fmt.Errorf("error updating bill amount for month %s: %v", month, err)
		}
	}

	if err = tx.Commit(); err != nil {
		return 0, fmt.Errorf("error committing transaction: %v", err)
	}

	// Recalcular saldos en cascada desde el primer mes afectado
	firstMonth := currentDate.Format("2006-01")
	if err = UpdateCascadeBalances(userID, firstMonth); err != nil {
		return int(billID), fmt.Errorf("error updating cascade balances: %v", err)
	}

	return int(billID), nil
}

// MarkBillAsPaid marca una factura como pagada para un mes específico usando el algoritmo correcto
func MarkBillAsPaid(billID int, userID, yearMonth string) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %v", err)
	}
	defer tx.Rollback()

	// Obtener datos de la factura
	var amount float64
	var paymentMethod string
	err = tx.QueryRow(`
		SELECT amount, payment_method
		FROM bills WHERE id = ? AND user_id = ?
	`, billID, userID).Scan(&amount, &paymentMethod)
	if err != nil {
		return fmt.Errorf("bill not found: %v", err)
	}

	// Verificar que el pago existe y no está pagado
	var alreadyPaid bool
	err = tx.QueryRow(`
		SELECT paid FROM bill_payments 
		WHERE bill_id = ? AND year_month = ?
	`, billID, yearMonth).Scan(&alreadyPaid)
	if err != nil {
		return fmt.Errorf("payment record not found: %v", err)
	}
	if alreadyPaid {
		return fmt.Errorf("bill for this month is already paid")
	}

	// Marcar pago como pagado
	paymentDate := time.Now().Format("2006-01-02")
	_, err = tx.Exec(`
		UPDATE bill_payments
		SET paid = 1, payment_date = ?
		WHERE bill_id = ? AND year_month = ?
	`, paymentDate, billID, yearMonth)
	if err != nil {
		return fmt.Errorf("error marking payment as paid: %v", err)
	}

	// CORRECCIÓN: Al pagar una factura, debe restarse del bill_amount Y agregarse al expense_amount
	// Esto mantiene el gasto en el sistema como corresponde
	if paymentMethod == "cash" {
		_, err = tx.Exec(`
			UPDATE monthly_cash_bank_balance
			SET bill_cash_amount = bill_cash_amount - ?,
			    expense_cash_amount = expense_cash_amount + ?
			WHERE user_id = ? AND year_month = ?
		`, amount, amount, userID, yearMonth)
	} else {
		_, err = tx.Exec(`
			UPDATE monthly_cash_bank_balance
			SET bill_bank_amount = bill_bank_amount - ?,
			    expense_bank_amount = expense_bank_amount + ?
			WHERE user_id = ? AND year_month = ?
		`, amount, amount, userID, yearMonth)
	}
	if err != nil {
		return fmt.Errorf("error updating bill amount: %v", err)
	}

	// Crear registro en la tabla expenses para mantener el histórico del gasto
	var billName, billCategory string
	err = tx.QueryRow(`
		SELECT name, category FROM bills WHERE id = ? AND user_id = ?
	`, billID, userID).Scan(&billName, &billCategory)
	if err != nil {
		return fmt.Errorf("error getting bill details: %v", err)
	}

	// Crear el expense con fecha del pago
	expenseDate := yearMonth + "-" + fmt.Sprintf("%02d", time.Now().Day())
	description := fmt.Sprintf("Pago de factura: %s", billName)

	_, err = tx.Exec(`
		INSERT INTO expenses (user_id, amount, date, category, payment_method, description)
		VALUES (?, ?, ?, ?, ?, ?)
	`, userID, amount, expenseDate, billCategory, paymentMethod, description)
	if err != nil {
		return fmt.Errorf("error creating expense record: %v", err)
	}

	// Verificar si todos los pagos están completados
	var totalPayments, paidPayments int
	err = tx.QueryRow(`
		SELECT COUNT(*) as total, SUM(CASE WHEN paid = 1 THEN 1 ELSE 0 END) as paid_count
		FROM bill_payments WHERE bill_id = ?
	`, billID).Scan(&totalPayments, &paidPayments)
	if err != nil {
		return fmt.Errorf("error checking bill completion: %v", err)
	}

	// Si todos los pagos están completados, marcar la factura como pagada
	if totalPayments > 0 && paidPayments >= totalPayments {
		_, err = tx.Exec(`
			UPDATE bills SET paid = 1, updated_at = CURRENT_TIMESTAMP 
			WHERE id = ? AND user_id = ?
		`, billID, userID)
		if err != nil {
			return fmt.Errorf("error updating bill status: %v", err)
		}
	}

	if err = tx.Commit(); err != nil {
		return fmt.Errorf("error committing transaction: %v", err)
	}

	// Recalcular saldos en cascada
	return UpdateCascadeBalances(userID, yearMonth)
}
