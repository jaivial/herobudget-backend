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

	// Get bills from database
	bills, err := fetchBills(userID)
	if err != nil {
		log.Printf("Error fetching bills: %v", err)
		sendErrorResponse(w, "Error fetching bills", http.StatusInternalServerError)
		return
	}

	// Return bills as JSON
	sendSuccessResponse(w, "Bills fetched successfully", bills)
}

func handleAddBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var addRequest AddBillRequest
	err := json.NewDecoder(r.Body).Decode(&addRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request
	if addRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if addRequest.Name == "" {
		sendErrorResponse(w, "Name is required", http.StatusBadRequest)
		return
	}

	if addRequest.Amount <= 0 {
		sendErrorResponse(w, "Amount must be greater than 0", http.StatusBadRequest)
		return
	}

	// Validate duration
	if addRequest.DurationMonths < 1 {
		sendErrorResponse(w, "Duration must be at least 1 month", http.StatusBadRequest)
		return
	}

	if addRequest.StartDate == "" {
		sendErrorResponse(w, "Start date is required", http.StatusBadRequest)
		return
	}

	if addRequest.Category == "" {
		sendErrorResponse(w, "Category is required", http.StatusBadRequest)
		return
	}

	if addRequest.Icon == "" {
		// Default icon if not provided
		addRequest.Icon = "bill"
	}

	// Set default payment method if not provided
	if addRequest.PaymentMethod == "" {
		addRequest.PaymentMethod = "bank"
	}

	// Set default regularity if not provided
	if addRequest.Regularity == "" {
		addRequest.Regularity = "monthly"
	}

	// Parse the start date
	startDate, err := time.Parse("2006-01-02", addRequest.StartDate)
	if err != nil {
		sendErrorResponse(w, "Invalid start date format, use YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	// Calculate overdue status based on first payment
	overdueDays := 0
	isOverdue := false
	firstPaymentDate := getPaymentDateForMonth(startDate, addRequest.PaymentDay)
	today := time.Now()
	if today.After(firstPaymentDate) {
		isOverdue = true
		overdueDays = int(today.Sub(firstPaymentDate).Hours() / 24)
	}

	// Create a bill object
	bill := Bill{
		UserID:         addRequest.UserID,
		Name:           addRequest.Name,
		Amount:         addRequest.Amount,
		DueDate:        firstPaymentDate.Format("2006-01-02"), // Para compatibilidad
		StartDate:      addRequest.StartDate,
		PaymentDay:     addRequest.PaymentDay,
		DurationMonths: addRequest.DurationMonths,
		Regularity:     addRequest.Regularity,
		Paid:           addRequest.Paid,
		Overdue:        isOverdue,
		OverdueDays:    overdueDays,
		Recurring:      addRequest.Recurring,
		Category:       addRequest.Category,
		Icon:           addRequest.Icon,
		PaymentMethod:  addRequest.PaymentMethod,
	}

	// Add the bill to the database
	billID, err := addBill(bill)
	if err != nil {
		log.Printf("Error adding bill: %v", err)
		sendErrorResponse(w, "Error adding bill", http.StatusInternalServerError)
		return
	}

	// Set the ID of the newly added bill
	bill.ID = billID

	// Determinar los montos de cash y bank según el método de pago
	var cashAmt, bankAmt float64
	if addRequest.PaymentMethod == "cash" {
		cashAmt = bill.Amount
		bankAmt = 0
	} else {
		cashAmt = 0
		bankAmt = bill.Amount
	}

	// Generar entradas en bill_payments para todos los meses de duración
	if err := generateBillPayments(billID, addRequest.UserID, startDate, addRequest.PaymentDay, addRequest.DurationMonths, addRequest.Regularity); err != nil {
		log.Printf("Error generating bill payments: %v", err)
		// Continuar a pesar del error
	}

	// Actualizar monthly_cash_bank_balance para todos los meses de duración
	if err := updateMonthlyBalancesForBillDuration(addRequest.UserID, cashAmt, bankAmt, startDate, addRequest.DurationMonths, addRequest.Regularity); err != nil {
		log.Printf("Error updating monthly balances for bill duration: %v", err)
		// Continuar a pesar del error
	}

	// Return success response
	sendSuccessResponse(w, "Bill added successfully with recurring schedule", bill)
}

func handlePayBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
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

	// Get the bill details
	var bill Bill
	err = db.QueryRow(`
		SELECT id, user_id, name, amount, start_date, payment_day, duration_months, regularity, category, icon
		FROM bills WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity, &bill.Category, &bill.Icon,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			sendErrorResponse(w, "Bill not found", http.StatusNotFound)
		} else {
			log.Printf("Error fetching bill: %v", err)
			sendErrorResponse(w, "Error fetching bill", http.StatusInternalServerError)
		}
		return
	}

	// Check if this specific month is already paid
	var alreadyPaid bool
	err = db.QueryRow(`
		SELECT paid FROM bill_payments 
		WHERE bill_id = ? AND year_month = ?
	`, payRequest.BillID, payRequest.YearMonth).Scan(&alreadyPaid)

	if err != nil {
		if err == sql.ErrNoRows {
			sendErrorResponse(w, "Payment record not found for this month", http.StatusNotFound)
		} else {
			log.Printf("Error checking payment status: %v", err)
			sendErrorResponse(w, "Error checking payment status", http.StatusInternalServerError)
		}
		return
	}

	if alreadyPaid {
		sendErrorResponse(w, "Bill for this month is already paid", http.StatusBadRequest)
		return
	}

	// Default payment method to "bank" if not specified
	paymentMethod := payRequest.PaymentMethod
	if paymentMethod == "" {
		paymentMethod = "bank"
	}

	// Mark this specific month as paid
	paymentDate := time.Now().Format("2006-01-02")
	_, err = db.Exec(`
		UPDATE bill_payments
		SET paid = 1, payment_date = ?, payment_method = ?
		WHERE bill_id = ? AND year_month = ?
	`, paymentDate, paymentMethod, payRequest.BillID, payRequest.YearMonth)

	if err != nil {
		log.Printf("Error marking bill payment as paid: %v", err)
		sendErrorResponse(w, "Error marking bill payment as paid", http.StatusInternalServerError)
		return
	}

	log.Printf("Bill %d payment for %s marked as paid with %s: $%.2f", bill.ID, payRequest.YearMonth, paymentMethod, bill.Amount)

	// Reclasificar en monthly_cash_bank_balance de bill_xxx_amount a expense_xxx_amount
	if err := reclassifyBillToExpenseInMonthlyBalance(payRequest.UserID, bill.Amount, paymentMethod, payRequest.YearMonth); err != nil {
		log.Printf("⚠️ Error reclassifying bill to expense in monthly_cash_bank_balance: %v", err)
		// Continuamos con el proceso, pero registramos el error
	}

	// Convertir el pago de la factura en un gasto
	description := payRequest.Description
	if description == "" {
		description = fmt.Sprintf("Pago de factura: %s (%s)", bill.Name, payRequest.YearMonth)
	}

	expenseReq := BillToExpenseRequest{
		UserID:        bill.UserID,
		Amount:        bill.Amount,
		Date:          paymentDate,
		Category:      bill.Category,
		PaymentMethod: paymentMethod,
		Description:   description,
	}

	// Registrar el gasto en el servicio de expense_management
	if err := createExpenseFromBill(expenseReq); err != nil {
		log.Printf("Error converting bill payment to expense: %v", err)
		// No fallamos la solicitud completa, solo registramos el error
	} else {
		log.Printf("Bill %d payment for %s successfully converted to expense", bill.ID, payRequest.YearMonth)
	}

	// Check if all payments for this bill are completed
	var totalPayments, paidPayments int
	err = db.QueryRow(`
		SELECT COUNT(*) as total, SUM(CASE WHEN paid = 1 THEN 1 ELSE 0 END) as paid_count
		FROM bill_payments WHERE bill_id = ?
	`, payRequest.BillID).Scan(&totalPayments, &paidPayments)

	if err != nil {
		log.Printf("Error checking bill completion status: %v", err)
	}

	// Prepare response data
	responseData := map[string]interface{}{
		"bill_id":            bill.ID,
		"paid_month":         payRequest.YearMonth,
		"amount":             bill.Amount,
		"payment_method":     paymentMethod,
		"total_payments":     totalPayments,
		"completed_payments": paidPayments,
		"bill_completed":     totalPayments > 0 && paidPayments >= totalPayments,
	}

	// Return success response
	sendSuccessResponse(w, fmt.Sprintf("Bill payment for %s completed successfully", payRequest.YearMonth), responseData)
}

// Función para actualizar años posteriores en cascada
func updateSubsequentAnnualBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a 5 años para evitar bucles infinitos
	endDate := startDate.AddDate(5, 0, 0)
	currentDate := startDate

	for currentDate.Before(endDate) {
		currentYear := currentDate.Format("2006")

		// Verificar si existe un registro para este año
		var exists bool
		var incomeAmount, expenseAmount, billsAmount, yearCashAmount, yearBankAmount float64
		err := db.QueryRow(`
			SELECT 1, income_amount, expense_amount, bills_amount, cash_amount, bank_amount FROM annual_balance
			WHERE user_id = ? AND year = ?
		`, userID, currentYear).Scan(&exists, &incomeAmount, &expenseAmount, &billsAmount, &yearCashAmount, &yearBankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		if err == sql.ErrNoRows {
			// No hay más registros para actualizar
			break
		}

		// Obtener el balance del año anterior
		prevYear := currentDate.AddDate(-1, 0, 0)
		prevYearStr := prevYear.Format("2006")

		var previousBalance float64
		var prevCashAmount, prevBankAmount float64
		err = db.QueryRow(`
			SELECT balance, cash_amount, bank_amount FROM annual_balance 
			WHERE user_id = ? AND year = ?
		`, userID, prevYearStr).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		if err == sql.ErrNoRows {
			previousBalance = 0
			prevCashAmount = 0
			prevBankAmount = 0
		}

		// Actualizar el balance con el nuevo balance previo
		balance := previousBalance + incomeAmount - expenseAmount - billsAmount

		// CAMBIO EN LA LÓGICA: Siempre acumulamos los valores del año anterior
		hasTransactions := incomeAmount != 0 || expenseAmount != 0 || billsAmount != 0

		// Inicializar con los valores del año anterior
		newCashAmount := prevCashAmount
		newBankAmount := prevBankAmount

		// Si hay transacciones propias en este año, las sumamos a lo heredado
		if hasTransactions {
			// Agregamos las transacciones propias de este año
			newCashAmount += yearCashAmount
			newBankAmount += yearBankAmount
		}

		// Calcular los valores de balance para cash y bank
		balanceCashAmount := prevCashAmount + yearCashAmount
		balanceBankAmount := prevBankAmount + yearBankAmount

		_, err = db.Exec(`
			UPDATE annual_balance
			SET previous_balance = ?,
				balance = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year = ?
		`, previousBalance, balance, newCashAmount, newBankAmount,
			prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount,
			userID, currentYear)

		if err != nil {
			return err
		}

		// Pasar al siguiente año
		currentDate = currentDate.AddDate(1, 0, 0)
	}

	return nil
}

// Función específica para actualizar monthly_cash_bank_balance cuando se paga una factura
func updateMonthlyBalanceForPaidBill(userID string, amount float64, paymentMethod string, billDate time.Time) error {
	log.Printf("💳 Starting bill payment balance update: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)

	// Crear una transacción para mantener consistencia
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction for paid bill balance update: %v", err)
	}

	// Función para hacer rollback en caso de error
	rollbackOnError := func(err error) error {
		rollbackErr := tx.Rollback()
		if rollbackErr != nil {
			log.Printf("Error rolling back transaction: %v", rollbackErr)
			return fmt.Errorf("error: %v, rollback error: %v", err, rollbackErr)
		}
		return err
	}

	// PASO 1: Buscar y remover la factura de TODOS los balances donde se registró originalmente
	if err := removeBillFromAllBalances(tx, userID, amount, paymentMethod); err != nil {
		return rollbackOnError(fmt.Errorf("error removing bill from original balances: %v", err))
	}

	// PASO 2: Agregar el expense en la fecha de pago (mes actual)
	if err := addExpenseToPaymentBalances(tx, userID, amount, paymentMethod, billDate); err != nil {
		return rollbackOnError(fmt.Errorf("error adding expense to payment balances: %v", err))
	}

	// Confirmar la transacción
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("error committing paid bill balance transaction: %v", err)
	}

	log.Printf("✅ Successfully updated all balances for paid bill: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)
	return nil
}

// Función auxiliar para remover una factura de TODOS los balances donde esté registrada
func removeBillFromAllBalances(tx *sql.Tx, userID string, amount float64, paymentMethod string) error {
	log.Printf("🔍 Searching for bill registrations to remove: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)

	// PASO 1: Buscar en daily_cash_bank_balance
	if err := removeBillFromDailyBalances(tx, userID, amount, paymentMethod); err != nil {
		return fmt.Errorf("error removing from daily balances: %v", err)
	}

	// PASO 2: Buscar en weekly_cash_bank_balance
	if err := removeBillFromWeeklyBalances(tx, userID, amount, paymentMethod); err != nil {
		return fmt.Errorf("error removing from weekly balances: %v", err)
	}

	// PASO 3: Buscar en monthly_cash_bank_balance
	if err := removeBillFromMonthlyBalances(tx, userID, amount, paymentMethod); err != nil {
		return fmt.Errorf("error removing from monthly balances: %v", err)
	}

	return nil
}

// Función auxiliar para remover factura de daily_cash_bank_balance
func removeBillFromDailyBalances(tx *sql.Tx, userID string, amount float64, paymentMethod string) error {
	var query string
	var columnName string

	if paymentMethod == "cash" {
		columnName = "bill_cash_amount"
		query = `
			SELECT date, bill_cash_amount 
			FROM daily_cash_bank_balance 
			WHERE user_id = ? AND bill_cash_amount >= ?
			ORDER BY bill_cash_amount DESC
		`
	} else {
		columnName = "bill_bank_amount"
		query = `
			SELECT date, bill_bank_amount 
			FROM daily_cash_bank_balance 
			WHERE user_id = ? AND bill_bank_amount >= ?
			ORDER BY bill_bank_amount DESC
		`
	}

	rows, err := tx.Query(query, userID, amount)
	if err != nil {
		return fmt.Errorf("error querying daily balances: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var date string
		var currentAmount float64

		if err := rows.Scan(&date, &currentAmount); err != nil {
			return fmt.Errorf("error scanning daily balance row: %v", err)
		}

		// Si encontramos una coincidencia exacta o suficiente, restar el monto
		if currentAmount >= amount {
			newAmount := currentAmount - amount

			// ✅ CORRECCIÓN: Solo actualizar el campo bill_xxx_amount, sin tocar los balances disponibles
			// El dinero NO debe regresar a cash_amount/bank_amount porque nunca debió ser restado en primer lugar
			updateQuery := fmt.Sprintf(`
				UPDATE daily_cash_bank_balance 
				SET %s = ?
				WHERE user_id = ? AND date = ?
			`, columnName)

			_, err = tx.Exec(updateQuery, newAmount, userID, date)
			if err != nil {
				return fmt.Errorf("error updating daily balance: %v", err)
			}

			log.Printf("📅 Removed bill from daily balance (CORRECTED): user=%s, date=%s, amount=%.2f→%.2f, method=%s",
				userID, date, currentAmount, newAmount, paymentMethod)

			return nil // Solo removemos de un registro
		}
	}

	log.Printf("📅 No matching daily balance found for removal: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)
	return nil
}

// Función auxiliar para remover factura de weekly_cash_bank_balance
func removeBillFromWeeklyBalances(tx *sql.Tx, userID string, amount float64, paymentMethod string) error {
	var query string
	var columnName string

	if paymentMethod == "cash" {
		columnName = "bill_cash_amount"
		query = `
			SELECT year_week, bill_cash_amount 
			FROM weekly_cash_bank_balance 
			WHERE user_id = ? AND bill_cash_amount >= ?
			ORDER BY bill_cash_amount DESC
		`
	} else {
		columnName = "bill_bank_amount"
		query = `
			SELECT year_week, bill_bank_amount 
			FROM weekly_cash_bank_balance 
			WHERE user_id = ? AND bill_bank_amount >= ?
			ORDER BY bill_bank_amount DESC
		`
	}

	rows, err := tx.Query(query, userID, amount)
	if err != nil {
		return fmt.Errorf("error querying weekly balances: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var yearWeek string
		var currentAmount float64

		if err := rows.Scan(&yearWeek, &currentAmount); err != nil {
			return fmt.Errorf("error scanning weekly balance row: %v", err)
		}

		// Si encontramos una coincidencia exacta o suficiente, restar el monto
		if currentAmount >= amount {
			newAmount := currentAmount - amount

			// ✅ CORRECCIÓN: Solo actualizar el campo bill_xxx_amount, sin tocar los balances disponibles
			// El dinero NO debe regresar a cash_amount/bank_amount porque nunca debió ser restado en primer lugar
			updateQuery := fmt.Sprintf(`
				UPDATE weekly_cash_bank_balance 
				SET %s = ?
				WHERE user_id = ? AND year_week = ?
			`, columnName)

			_, err = tx.Exec(updateQuery, newAmount, userID, yearWeek)
			if err != nil {
				return fmt.Errorf("error updating weekly balance: %v", err)
			}

			log.Printf("📊 Removed bill from weekly balance (CORRECTED): user=%s, week=%s, amount=%.2f→%.2f, method=%s",
				userID, yearWeek, currentAmount, newAmount, paymentMethod)

			return nil // Solo removemos de un registro
		}
	}

	log.Printf("📊 No matching weekly balance found for removal: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)
	return nil
}

// Función auxiliar para remover factura de monthly_cash_bank_balance
func removeBillFromMonthlyBalances(tx *sql.Tx, userID string, amount float64, paymentMethod string) error {
	var query string
	var columnName string

	if paymentMethod == "cash" {
		columnName = "bill_cash_amount"
		query = `
			SELECT year_month, bill_cash_amount 
			FROM monthly_cash_bank_balance 
			WHERE user_id = ? AND bill_cash_amount >= ?
			ORDER BY bill_cash_amount DESC
		`
	} else {
		columnName = "bill_bank_amount"
		query = `
			SELECT year_month, bill_bank_amount 
			FROM monthly_cash_bank_balance 
			WHERE user_id = ? AND bill_bank_amount >= ?
			ORDER BY bill_bank_amount DESC
		`
	}

	rows, err := tx.Query(query, userID, amount)
	if err != nil {
		return fmt.Errorf("error querying monthly balances: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var yearMonth string
		var currentAmount float64

		if err := rows.Scan(&yearMonth, &currentAmount); err != nil {
			return fmt.Errorf("error scanning monthly balance row: %v", err)
		}

		// Si encontramos una coincidencia exacta o suficiente, restar el monto
		if currentAmount >= amount {
			newAmount := currentAmount - amount

			// ✅ CORRECCIÓN: Solo actualizar el campo bill_xxx_amount, sin tocar los balances disponibles
			// El dinero NO debe regresar a cash_amount/bank_amount porque nunca debió ser restado en primer lugar
			updateQuery := fmt.Sprintf(`
				UPDATE monthly_cash_bank_balance 
				SET %s = ?
				WHERE user_id = ? AND year_month = ?
			`, columnName)

			_, err = tx.Exec(updateQuery, newAmount, userID, yearMonth)
			if err != nil {
				return fmt.Errorf("error updating monthly balance: %v", err)
			}

			log.Printf("💰 Removed bill from monthly balance (CORRECTED): user=%s, month=%s, amount=%.2f→%.2f, method=%s",
				userID, yearMonth, currentAmount, newAmount, paymentMethod)

			return nil // Solo removemos de un registro
		}
	}

	log.Printf("💰 No matching monthly balance found for removal: user=%s, amount=%.2f, method=%s", userID, amount, paymentMethod)
	return nil
}

// Función auxiliar para agregar expense en todos los balances de la fecha de pago
func addExpenseToPaymentBalances(tx *sql.Tx, userID string, amount float64, paymentMethod string, paymentDate time.Time) error {
	// Formatear las fechas para los diferentes períodos
	yearMonth := paymentDate.Format("2006-01")
	dateStr := paymentDate.Format("2006-01-02")

	// Calcular week (año-semana)
	year, week := paymentDate.ISOWeek()
	yearWeek := fmt.Sprintf("%d-%02d", year, week)

	log.Printf("🔄 Adding expense to payment balances for date=%s, month=%s, week=%s", dateStr, yearMonth, yearWeek)

	// 1. Actualizar monthly_cash_bank_balance
	if err := updateMonthlyBalanceForExpense(tx, userID, amount, paymentMethod, yearMonth); err != nil {
		return fmt.Errorf("error updating monthly balance: %v", err)
	}

	// 2. Actualizar daily_cash_bank_balance
	if err := updateDailyBalanceForExpense(tx, userID, amount, paymentMethod, dateStr); err != nil {
		return fmt.Errorf("error updating daily balance: %v", err)
	}

	// 3. Actualizar weekly_cash_bank_balance
	if err := updateWeeklyBalanceForExpense(tx, userID, amount, paymentMethod, yearWeek); err != nil {
		return fmt.Errorf("error updating weekly balance: %v", err)
	}

	return nil
}

// Función auxiliar para actualizar monthly_cash_bank_balance con expense
func updateMonthlyBalanceForExpense(tx *sql.Tx, userID string, amount float64, paymentMethod string, yearMonth string) error {
	// Verificar si existe el registro del mes
	var exists bool
	var currentExpenseCash, currentExpenseBank float64

	err := tx.QueryRow(`
		SELECT 1, expense_cash_amount, expense_bank_amount
		FROM monthly_cash_bank_balance
		WHERE user_id = ? AND year_month = ?
	`, userID, yearMonth).Scan(&exists, &currentExpenseCash, &currentExpenseBank)

	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("error checking monthly balance record: %v", err)
	}

	if err == sql.ErrNoRows {
		// No existe registro, crear uno nuevo solo con el expense
		if paymentMethod == "cash" {
			_, err = tx.Exec(`
				INSERT INTO monthly_cash_bank_balance (
					user_id, year_month,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, yearMonth, amount)
		} else {
			_, err = tx.Exec(`
				INSERT INTO monthly_cash_bank_balance (
					user_id, year_month,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, yearMonth, amount)
		}

		if err != nil {
			return fmt.Errorf("error creating monthly balance record: %v", err)
		}

		log.Printf("💰 Created monthly balance record for expense: user=%s, month=%s, amount=%.2f, method=%s",
			userID, yearMonth, amount, paymentMethod)
	} else {
		// Actualizar registro existente - solo agregar expense
		if paymentMethod == "cash" {
			newExpenseCash := currentExpenseCash + amount
			_, err = tx.Exec(`
				UPDATE monthly_cash_bank_balance
				SET expense_cash_amount = ?
				WHERE user_id = ? AND year_month = ?
			`, newExpenseCash, userID, yearMonth)
		} else {
			newExpenseBank := currentExpenseBank + amount
			_, err = tx.Exec(`
				UPDATE monthly_cash_bank_balance
				SET expense_bank_amount = ?
				WHERE user_id = ? AND year_month = ?
			`, newExpenseBank, userID, yearMonth)
		}

		if err != nil {
			return fmt.Errorf("error updating monthly balance: %v", err)
		}

		log.Printf("💳 Updated monthly balance for expense: user=%s, month=%s, amount=%.2f, method=%s",
			userID, yearMonth, amount, paymentMethod)
	}

	return nil
}

// Función auxiliar para actualizar daily_cash_bank_balance con expense
func updateDailyBalanceForExpense(tx *sql.Tx, userID string, amount float64, paymentMethod string, dateStr string) error {
	// Verificar si existe el registro del día
	var exists bool
	var currentExpenseCash, currentExpenseBank float64

	err := tx.QueryRow(`
		SELECT 1, expense_cash_amount, expense_bank_amount
		FROM daily_cash_bank_balance
		WHERE user_id = ? AND date = ?
	`, userID, dateStr).Scan(&exists, &currentExpenseCash, &currentExpenseBank)

	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("error checking daily balance record: %v", err)
	}

	if err == sql.ErrNoRows {
		// No existe registro, crear uno nuevo solo con el expense
		if paymentMethod == "cash" {
			_, err = tx.Exec(`
				INSERT INTO daily_cash_bank_balance (
					user_id, date,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, dateStr, amount)
		} else {
			_, err = tx.Exec(`
				INSERT INTO daily_cash_bank_balance (
					user_id, date,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, dateStr, amount)
		}

		if err != nil {
			return fmt.Errorf("error creating daily balance record: %v", err)
		}

		log.Printf("📅 Created daily balance record for expense: user=%s, date=%s, amount=%.2f, method=%s",
			userID, dateStr, amount, paymentMethod)
	} else {
		// Actualizar registro existente - solo agregar expense
		if paymentMethod == "cash" {
			newExpenseCash := currentExpenseCash + amount
			_, err = tx.Exec(`
				UPDATE daily_cash_bank_balance
				SET expense_cash_amount = ?
				WHERE user_id = ? AND date = ?
			`, newExpenseCash, userID, dateStr)
		} else {
			newExpenseBank := currentExpenseBank + amount
			_, err = tx.Exec(`
				UPDATE daily_cash_bank_balance
				SET expense_bank_amount = ?
				WHERE user_id = ? AND date = ?
			`, newExpenseBank, userID, dateStr)
		}

		if err != nil {
			return fmt.Errorf("error updating daily balance: %v", err)
		}

		log.Printf("📅 Updated daily balance for expense: user=%s, date=%s, amount=%.2f, method=%s",
			userID, dateStr, amount, paymentMethod)
	}

	return nil
}

// Función auxiliar para actualizar weekly_cash_bank_balance con expense
func updateWeeklyBalanceForExpense(tx *sql.Tx, userID string, amount float64, paymentMethod string, yearWeek string) error {
	// Verificar si existe el registro de la semana
	var exists bool
	var currentExpenseCash, currentExpenseBank float64

	err := tx.QueryRow(`
		SELECT 1, expense_cash_amount, expense_bank_amount
		FROM weekly_cash_bank_balance
		WHERE user_id = ? AND year_week = ?
	`, userID, yearWeek).Scan(&exists, &currentExpenseCash, &currentExpenseBank)

	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("error checking weekly balance record: %v", err)
	}

	if err == sql.ErrNoRows {
		// No existe registro, crear uno nuevo solo con el expense
		if paymentMethod == "cash" {
			_, err = tx.Exec(`
				INSERT INTO weekly_cash_bank_balance (
					user_id, year_week,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, yearWeek, amount)
		} else {
			_, err = tx.Exec(`
				INSERT INTO weekly_cash_bank_balance (
					user_id, year_week,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance, total_previous_balance
				) VALUES (?, ?, 0, 0, 0, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			`, userID, yearWeek, amount)
		}

		if err != nil {
			return fmt.Errorf("error creating weekly balance record: %v", err)
		}

		log.Printf("📊 Created weekly balance record for expense: user=%s, week=%s, amount=%.2f, method=%s",
			userID, yearWeek, amount, paymentMethod)
	} else {
		// Actualizar registro existente - solo agregar expense
		if paymentMethod == "cash" {
			newExpenseCash := currentExpenseCash + amount
			_, err = tx.Exec(`
				UPDATE weekly_cash_bank_balance
				SET expense_cash_amount = ?
				WHERE user_id = ? AND year_week = ?
			`, newExpenseCash, userID, yearWeek)
		} else {
			newExpenseBank := currentExpenseBank + amount
			_, err = tx.Exec(`
				UPDATE weekly_cash_bank_balance
				SET expense_bank_amount = ?
				WHERE user_id = ? AND year_week = ?
			`, newExpenseBank, userID, yearWeek)
		}

		if err != nil {
			return fmt.Errorf("error updating weekly balance: %v", err)
		}

		log.Printf("📊 Updated weekly balance for expense: user=%s, week=%s, amount=%.2f, method=%s",
			userID, yearWeek, amount, paymentMethod)
	}

	return nil
}

// Nueva función para calcular la fecha de pago en un mes específico
func getPaymentDateForMonth(monthStart time.Time, paymentDay int) time.Time {
	year := monthStart.Year()
	month := monthStart.Month()

	// Asegurar que el día no sea mayor al último día del mes
	lastDayOfMonth := time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
	if paymentDay > lastDayOfMonth {
		paymentDay = lastDayOfMonth
	}

	return time.Date(year, month, paymentDay, 0, 0, 0, 0, time.UTC)
}

// Nueva función para generar entradas en bill_payments
func generateBillPayments(billID int, userID string, startDate time.Time, paymentDay int, durationMonths int, regularity string) error {
	for i := 0; i < durationMonths; i++ {
		// Calcular el mes para este pago
		paymentMonth := startDate.AddDate(0, i, 0)
		yearMonth := paymentMonth.Format("2006-01")

		// Verificar si ya existe una entrada para este mes
		var exists bool
		err := db.QueryRow(`
			SELECT 1 FROM bill_payments 
			WHERE bill_id = ? AND year_month = ?
		`, billID, yearMonth).Scan(&exists)

		if err != nil && err != sql.ErrNoRows {
			log.Printf("Error checking bill_payments: %v", err)
			continue
		}

		if err == sql.ErrNoRows {
			// No existe, crear nueva entrada
			_, err = db.Exec(`
				INSERT INTO bill_payments (bill_id, user_id, year_month, paid, payment_date, payment_method)
				VALUES (?, ?, ?, 0, NULL, NULL)
			`, billID, userID, yearMonth)

			if err != nil {
				log.Printf("Error inserting bill_payment: %v", err)
				continue
			}

			log.Printf("✅ Created bill_payment entry for bill %d, month %s", billID, yearMonth)
		}
	}

	return nil
}

// Nueva función para actualizar monthly_cash_bank_balance para todos los meses
func updateMonthlyBalancesForBillDuration(userID string, cashAmt, bankAmt float64, startDate time.Time, durationMonths int, regularity string) error {
	for i := 0; i < durationMonths; i++ {
		// Calcular el mes para este pago
		paymentMonth := startDate.AddDate(0, i, 0)
		yearMonth := paymentMonth.Format("2006-01")

		// Verificar si ya existe registro para este mes
		var exists bool
		err := db.QueryRow(`
			SELECT 1 FROM monthly_cash_bank_balance
			WHERE user_id = ? AND year_month = ?
		`, userID, yearMonth).Scan(&exists)

		if err != nil && err != sql.ErrNoRows {
			log.Printf("Error checking monthly_cash_bank_balance: %v", err)
			continue
		}

		if err == sql.ErrNoRows {
			// No existe registro, crear uno nuevo
			_, err = db.Exec(`
				INSERT INTO monthly_cash_bank_balance (
					user_id, year_month, 
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount,
					total_balance
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, userID, yearMonth,
				0, 0,
				0, 0,
				cashAmt, bankAmt,
				-cashAmt, -bankAmt, // Restar el dinero comprometido con la factura
				0, 0,
				-cashAmt, -bankAmt,
				-cashAmt-bankAmt) // total_balance reducido por la factura

			if err != nil {
				log.Printf("Error inserting into monthly_cash_bank_balance: %v", err)
				continue
			}

			log.Printf("✅ Added bill projection to monthly_cash_bank_balance for month %s: bill_cash=%.2f, bill_bank=%.2f",
				yearMonth, cashAmt, bankAmt)
		} else {
			// Actualizar registro existente
			_, err = db.Exec(`
				UPDATE monthly_cash_bank_balance
				SET bill_cash_amount = bill_cash_amount + ?,
					bill_bank_amount = bill_bank_amount + ?,
					cash_amount = cash_amount - ?,
					bank_amount = bank_amount - ?,
					balance_cash_amount = balance_cash_amount - ?,
					balance_bank_amount = balance_bank_amount - ?,
					total_balance = total_balance - ?
				WHERE user_id = ? AND year_month = ?
			`, cashAmt, bankAmt, cashAmt, bankAmt, cashAmt, bankAmt, cashAmt+bankAmt, userID, yearMonth)

			if err != nil {
				log.Printf("Error updating monthly_cash_bank_balance: %v", err)
				continue
			}

			log.Printf("✅ Updated bill projection in monthly_cash_bank_balance for month %s: +bill_cash=%.2f, +bill_bank=%.2f",
				yearMonth, cashAmt, bankAmt)
		}
	}

	return nil
}

// Nueva función para reclasificar factura a gasto en monthly_cash_bank_balance
func reclassifyBillToExpenseInMonthlyBalance(userID string, amount float64, paymentMethod string, yearMonth string) error {
	// Determinar qué campos actualizar según el método de pago
	var billColumn, expenseColumn string
	if paymentMethod == "cash" {
		billColumn = "bill_cash_amount"
		expenseColumn = "expense_cash_amount"
	} else {
		billColumn = "bill_bank_amount"
		expenseColumn = "expense_bank_amount"
	}

	// Actualizar el registro mensual: restar de bill_xxx_amount y sumar a expense_xxx_amount
	_, err := db.Exec(fmt.Sprintf(`
		UPDATE monthly_cash_bank_balance
		SET %s = %s - ?,
			%s = %s + ?
		WHERE user_id = ? AND year_month = ?
	`, billColumn, billColumn, expenseColumn, expenseColumn), amount, amount, userID, yearMonth)

	if err != nil {
		return fmt.Errorf("error reclassifying bill to expense in monthly balance: %v", err)
	}

	log.Printf("✅ Reclassified bill to expense in monthly_cash_bank_balance: user=%s, month=%s, amount=%.2f, method=%s",
		userID, yearMonth, amount, paymentMethod)

	return nil
}

// addCashBankColumnsToAllTables - Helper function to add cash/bank columns to all balance tables
func addCashBankColumnsToAllTables() {
	// This function ensures backward compatibility by adding new columns to existing tables
	log.Println("Checking and adding cash/bank columns to balance tables...")
}

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

// fetchBills - Helper function to fetch bills from database
func fetchBills(userID string) ([]Bill, error) {
	query := `
		SELECT id, user_id, name, amount, due_date, start_date, payment_day, 
		       duration_months, regularity, paid, overdue, overdue_days, 
		       recurring, category, icon, created_at, updated_at
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
		var createdAt, updatedAt string

		err := rows.Scan(
			&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate,
			&bill.StartDate, &bill.PaymentDay, &bill.DurationMonths, &bill.Regularity,
			&bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring,
			&bill.Category, &bill.Icon, &createdAt, &updatedAt,
		)
		if err != nil {
			log.Printf("Error scanning bill: %v", err)
			continue
		}

		bill.CreatedAt = createdAt
		bill.UpdatedAt = updatedAt
		bills = append(bills, bill)
	}

	return bills, nil
}

// addBill - Helper function to add bill to database
func addBill(bill Bill) (int, error) {
	query := `
		INSERT INTO bills (
			user_id, name, amount, due_date, start_date, payment_day, 
			duration_months, regularity, paid, overdue, overdue_days, 
			recurring, category, icon
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`

	result, err := db.Exec(query,
		bill.UserID, bill.Name, bill.Amount, bill.DueDate, bill.StartDate,
		bill.PaymentDay, bill.DurationMonths, bill.Regularity, bill.Paid,
		bill.Overdue, bill.OverdueDays, bill.Recurring, bill.Category, bill.Icon,
	)
	if err != nil {
		return 0, err
	}

	billID, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return int(billID), nil
}

// createExpenseFromBill - Helper function to create expense from bill payment
func createExpenseFromBill(req BillToExpenseRequest) error {
	// This would typically call the expense_management service
	// For now, we'll just log it
	log.Printf("Creating expense from bill payment: %+v", req)
	return nil
}

// handleUpdateBill - Placeholder for update bill handler
func handleUpdateBill(w http.ResponseWriter, r *http.Request) {
	sendErrorResponse(w, "Update bill functionality not implemented yet", http.StatusNotImplemented)
}

// handleDeleteBill - Placeholder for delete bill handler
func handleDeleteBill(w http.ResponseWriter, r *http.Request) {
	sendErrorResponse(w, "Delete bill functionality not implemented yet", http.StatusNotImplemented)
}

// handleGetUpcomingBills - Placeholder for upcoming bills handler
func handleGetUpcomingBills(w http.ResponseWriter, r *http.Request) {
	sendErrorResponse(w, "Upcoming bills functionality not implemented yet", http.StatusNotImplemented)
}
