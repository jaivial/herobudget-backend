package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Bill struct {
	ID            int     `json:"id"`
	UserID        string  `json:"user_id"`
	Name          string  `json:"name"`
	Amount        float64 `json:"amount"`
	DueDate       string  `json:"due_date"`
	Paid          bool    `json:"paid"`
	Overdue       bool    `json:"overdue"`
	OverdueDays   int     `json:"overdue_days"`
	Recurring     bool    `json:"recurring"`
	Category      string  `json:"category"`
	Icon          string  `json:"icon"`
	PaymentMethod string  `json:"payment_method,omitempty"`
	CreatedAt     string  `json:"created_at,omitempty"`
	UpdatedAt     string  `json:"updated_at,omitempty"`
}

type AddBillRequest struct {
	UserID        string  `json:"user_id"`
	Name          string  `json:"name"`
	Amount        float64 `json:"amount"`
	DueDate       string  `json:"due_date"`
	Paid          bool    `json:"paid"`
	Overdue       bool    `json:"overdue"`
	Recurring     bool    `json:"recurring"`
	Category      string  `json:"category"`
	Icon          string  `json:"icon"`
	PaymentMethod string  `json:"payment_method,omitempty"` // "cash" o "bank"
}

type UpdateBillRequest struct {
	UserID    string  `json:"user_id"`
	BillID    int     `json:"bill_id"`
	Name      string  `json:"name,omitempty"`
	Amount    float64 `json:"amount,omitempty"`
	DueDate   string  `json:"due_date,omitempty"`
	Recurring bool    `json:"recurring,omitempty"`
	Category  string  `json:"category,omitempty"`
	Icon      string  `json:"icon,omitempty"`
}

type PayBillRequest struct {
	UserID        string `json:"user_id"`
	BillID        int    `json:"bill_id"`
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

	if addRequest.DueDate == "" {
		sendErrorResponse(w, "Due date is required", http.StatusBadRequest)
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

	// Parse the due date
	dueDate, err := time.Parse("2006-01-02", addRequest.DueDate)
	if err != nil {
		sendErrorResponse(w, "Invalid due date format, use YYYY-MM-DD", http.StatusBadRequest)
		return
	}

	// Calculate overdue status
	overdueDays := 0
	isOverdue := false
	today := time.Now()
	if today.After(dueDate) {
		isOverdue = true
		overdueDays = int(today.Sub(dueDate).Hours() / 24)
	}

	// Create a bill object
	bill := Bill{
		UserID:        addRequest.UserID,
		Name:          addRequest.Name,
		Amount:        addRequest.Amount,
		DueDate:       addRequest.DueDate,
		Paid:          addRequest.Paid,
		Overdue:       isOverdue,
		OverdueDays:   overdueDays,
		Recurring:     addRequest.Recurring,
		Category:      addRequest.Category,
		Icon:          addRequest.Icon,
		PaymentMethod: addRequest.PaymentMethod,
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
	if bill.PaymentMethod == "cash" {
		cashAmt = bill.Amount
		bankAmt = 0
	} else {
		cashAmt = 0
		bankAmt = bill.Amount
	}

	// Actualizar los balances por periodos siempre, independientemente de si está pagada o no
	// Si la factura está pagada, afecta a los balances reales
	if bill.Paid {
		if err := updateTimeBalances(bill.UserID, 0, 0, bill.Amount, cashAmt, bankAmt, bill.DueDate); err != nil {
			log.Printf("Error updating time balances: %v", err)
			// Don't fail the entire request, just log the error
		}

		// Recalcular todos los balances para asegurar que previous_xxx_amount y balance_xxx_amount se actualicen en cascada
		if err := recalculateAllBalances(bill.UserID, bill.DueDate); err != nil {
			log.Printf("Error recalculating balances: %v", err)
			// Continue despite the error
		}
	} else {
		// Si no está pagada, actualizar específicamente las tablas *_cash_bank_balance
		// para proyecciones futuras
		yearMonth := dueDate.Format("2006-01")

		// Actualizamos la tabla monthly_cash_bank_balance
		var exists bool
		err = db.QueryRow(`
			SELECT 1 FROM monthly_cash_bank_balance
			WHERE user_id = ? AND year_month = ?
		`, bill.UserID, yearMonth).Scan(&exists)

		if err != nil && err != sql.ErrNoRows {
			log.Printf("Error checking monthly_cash_bank_balance: %v", err)
		}

		if err == sql.ErrNoRows {
			// No existe registro, creamos uno nuevo
			_, err = db.Exec(`
				INSERT INTO monthly_cash_bank_balance (
					user_id, year_month, 
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, bill.UserID, yearMonth,
				0, 0,
				0, 0,
				cashAmt, bankAmt,
				0, 0,
				0, 0,
				-cashAmt, -bankAmt)

			if err != nil {
				log.Printf("Error inserting into monthly_cash_bank_balance: %v", err)
			} else {
				log.Printf("Added projection to monthly_cash_bank_balance for bill %d", bill.ID)
			}
		} else {
			// Actualizar registro existente
			_, err = db.Exec(`
				UPDATE monthly_cash_bank_balance
				SET bill_cash_amount = bill_cash_amount + ?,
					bill_bank_amount = bill_bank_amount + ?,
					balance_cash_amount = balance_cash_amount - ?,
					balance_bank_amount = balance_bank_amount - ?
				WHERE user_id = ? AND year_month = ?
			`, cashAmt, bankAmt, cashAmt, bankAmt, bill.UserID, yearMonth)

			if err != nil {
				log.Printf("Error updating monthly_cash_bank_balance: %v", err)
			} else {
				log.Printf("Updated projection in monthly_cash_bank_balance for bill %d", bill.ID)
			}
		}

		// También actualizar daily_cash_bank_balance para el día de vencimiento
		err = db.QueryRow(`
			SELECT 1 FROM daily_cash_bank_balance
			WHERE user_id = ? AND date = ?
		`, bill.UserID, bill.DueDate).Scan(&exists)

		if err != nil && err != sql.ErrNoRows {
			log.Printf("Error checking daily_cash_bank_balance: %v", err)
		}

		if err == sql.ErrNoRows {
			// No existe registro, creamos uno nuevo
			_, err = db.Exec(`
				INSERT INTO daily_cash_bank_balance (
					user_id, date, 
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, bank_amount,
					previous_cash_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, bill.UserID, bill.DueDate,
				0, 0,
				0, 0,
				cashAmt, bankAmt,
				0, 0,
				0, 0,
				-cashAmt, -bankAmt)

			if err != nil {
				log.Printf("Error inserting into daily_cash_bank_balance: %v", err)
			} else {
				log.Printf("Added projection to daily_cash_bank_balance for bill %d", bill.ID)
			}
		} else {
			// Actualizar registro existente
			_, err = db.Exec(`
				UPDATE daily_cash_bank_balance
				SET bill_cash_amount = bill_cash_amount + ?,
					bill_bank_amount = bill_bank_amount + ?,
					balance_cash_amount = balance_cash_amount - ?,
					balance_bank_amount = balance_bank_amount - ?
				WHERE user_id = ? AND date = ?
			`, cashAmt, bankAmt, cashAmt, bankAmt, bill.UserID, bill.DueDate)

			if err != nil {
				log.Printf("Error updating daily_cash_bank_balance: %v", err)
			} else {
				log.Printf("Updated projection in daily_cash_bank_balance for bill %d", bill.ID)
			}
		}
	}

	// Return success response
	sendSuccessResponse(w, "Bill added successfully", bill)
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

	// Get the bill details before updating
	var bill Bill
	err = db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, category, recurring, paid, payment_method, icon
		FROM bills WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate, &bill.Category, &bill.Recurring, &bill.Paid, &bill.PaymentMethod, &bill.Icon,
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

	// Check if bill is already paid
	if bill.Paid {
		sendErrorResponse(w, "Bill is already paid", http.StatusBadRequest)
		return
	}

	// Default payment method to "bank" if not specified
	paymentMethod := payRequest.PaymentMethod
	if paymentMethod == "" {
		// Usar el método de pago almacenado en la factura si no se proporciona uno nuevo
		if bill.PaymentMethod != "" {
			paymentMethod = bill.PaymentMethod
		} else {
			paymentMethod = "bank"
		}
	}

	// Actualizar el método de pago en la factura si es diferente
	if bill.PaymentMethod != paymentMethod {
		_, err = db.Exec(`
			UPDATE bills
			SET payment_method = ?
			WHERE id = ? AND user_id = ?
		`, paymentMethod, payRequest.BillID, payRequest.UserID)
		if err != nil {
			log.Printf("Error updating payment method: %v", err)
			// Continue despite the error
		}
	}

	// Mark the bill as paid
	_, err = db.Exec(`
		UPDATE bills
		SET paid = 1, updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error marking bill as paid: %v", err)
		sendErrorResponse(w, "Error marking bill as paid", http.StatusInternalServerError)
		return
	}

	// Process payment based on payment method
	// This is a simplification, in a real app you'd update account balances
	log.Printf("Bill %d paid with %s: $%.2f", bill.ID, paymentMethod, bill.Amount)

	// Determinar los montos de cash y bank según el método de pago
	var cashAmt, bankAmt float64
	if paymentMethod == "cash" {
		cashAmt = bill.Amount
		bankAmt = 0
	} else {
		cashAmt = 0
		bankAmt = bill.Amount
	}

	// Obtener la fecha actual para registrar el pago
	billDate := time.Now().Format("2006-01-02")

	// Actualizar los balances por periodos
	if err := updateTimeBalances(payRequest.UserID, 0, 0, bill.Amount, cashAmt, bankAmt, billDate); err != nil {
		log.Printf("Error updating time balances: %v", err)
		// Continue despite the error
	}

	// Recalcular todos los balances para asegurar que previous_xxx_amount y balance_xxx_amount se actualicen en cascada
	if err := recalculateAllBalances(payRequest.UserID, billDate); err != nil {
		log.Printf("Error recalculating balances: %v", err)
		// Continue despite the error
	}

	// Convertir la factura pagada en un gasto
	description := payRequest.Description
	if description == "" {
		description = fmt.Sprintf("Pago de factura: %s", bill.Name)
	}

	expenseReq := BillToExpenseRequest{
		UserID:        bill.UserID,
		Amount:        bill.Amount,
		Date:          billDate,
		Category:      bill.Category,
		PaymentMethod: paymentMethod,
		Description:   description,
	}

	// Registrar el gasto en el servicio de expense_management
	if err := createExpenseFromBill(expenseReq); err != nil {
		log.Printf("Error converting bill to expense: %v", err)
		// No fallamos la solicitud completa, solo registramos el error
	} else {
		log.Printf("Bill %d successfully converted to expense", bill.ID)
	}

	// Re-fetch the bill to ensure we have the latest data from the database
	err = db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, category, recurring, paid, payment_method, icon
		FROM bills WHERE id = ? AND user_id = ?
	`, payRequest.BillID, payRequest.UserID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate, &bill.Category, &bill.Recurring, &bill.Paid, &bill.PaymentMethod, &bill.Icon,
	)

	if err != nil {
		log.Printf("Error re-fetching bill after payment: %v", err)
		// If we can't re-fetch, manually set paid to true as a fallback
		bill.Paid = true
		log.Printf("Using manually set paid=true as fallback")
	} else {
		log.Printf("Re-fetched bill %d with paid status: %t", bill.ID, bill.Paid)
	}

	// Calculate overdue status (will be false since it's paid)
	updateOverdueStatus(&bill)

	// Return success response
	sendSuccessResponse(w, "Bill paid successfully and converted to expense", bill)
}

// Nueva función para convertir una factura pagada en un gasto
func createExpenseFromBill(billExpense BillToExpenseRequest) error {
	// Conectar directamente a la base de datos SQLite para agregar gastos
	// Esto evita depender de un servicio HTTP externo que puede fallar
	log.Printf("Creating expense directly in database for bill amount: %.2f", billExpense.Amount)

	// Get the current working directory
	cwd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get current directory: %v", err)
	}

	// Construct absolute path to the database file - same as init() function
	dbPath := filepath.Join(cwd, "..", "google_auth", "users.db")
	log.Printf("Opening database at path: %s", dbPath)

	// Inicio de transacción para asegurar la integridad de los datos
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return fmt.Errorf("error opening expenses database: %v", err)
	}
	defer db.Close()

	// Verificar que la conexión funcione
	if err = db.Ping(); err != nil {
		return fmt.Errorf("error connecting to expenses database: %v", err)
	}

	// Iniciar una transacción
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %v", err)
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

	// Verificar si la tabla expenses existe
	var tableExists bool
	err = tx.QueryRow("SELECT 1 FROM sqlite_master WHERE type='table' AND name='expenses'").Scan(&tableExists)
	if err != nil && err != sql.ErrNoRows {
		return rollbackOnError(fmt.Errorf("error checking if expenses table exists: %v", err))
	}

	// Si la tabla no existe, crearla
	if !tableExists {
		log.Printf("Expenses table does not exist. Creating it.")
		_, err := tx.Exec(`
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
			)
		`)
		if err != nil {
			return rollbackOnError(fmt.Errorf("error creating expenses table: %v", err))
		}
	}

	// Insertar el gasto
	result, err := tx.Exec(`
		INSERT INTO expenses (user_id, amount, date, category, payment_method, description)
		VALUES (?, ?, ?, ?, ?, ?)
	`, billExpense.UserID, billExpense.Amount, billExpense.Date, billExpense.Category, billExpense.PaymentMethod, billExpense.Description)

	if err != nil {
		return rollbackOnError(fmt.Errorf("error inserting expense: %v", err))
	}

	// Verificar que se haya insertado correctamente
	expenseID, err := result.LastInsertId()
	if err != nil {
		return rollbackOnError(fmt.Errorf("error getting last insert ID: %v", err))
	}

	// Confirmar la transacción
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("error committing transaction: %v", err)
	}

	log.Printf("Successfully created expense with ID %d from bill payment", expenseID)
	return nil
}

// Nueva función para recalcular todos los balances en cascada
func recalculateAllBalances(userID string, dateStr string) error {
	// Parse la fecha de la transacción
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return fmt.Errorf("error parsing date: %v", err)
	}

	// Verify if a transaction is already in progress by checking if there's a connection
	// and using a direct query instead of starting a new transaction
	updateSubsequentDailyBalances(userID, date)

	// Calcular el inicio de la semana que contiene la fecha
	dayOfWeek := int(date.Weekday())
	if dayOfWeek == 0 {
		dayOfWeek = 7 // Convertir domingo (0) a 7
	}
	startOfWeek := date.AddDate(0, 0, -(dayOfWeek - 1))

	// Update all time balances
	updateSubsequentWeeklyBalances(userID, startOfWeek)

	// Calcular el inicio del mes que contiene la fecha
	startOfMonth := time.Date(date.Year(), date.Month(), 1, 0, 0, 0, 0, time.UTC)
	updateSubsequentMonthlyBalances(userID, startOfMonth)

	// Calcular el inicio del trimestre que contiene la fecha
	quarter := (int(date.Month()) - 1) / 3
	startOfQuarter := time.Date(date.Year(), time.Month(quarter*3+1), 1, 0, 0, 0, 0, time.UTC)
	updateSubsequentQuarterlyBalances(userID, startOfQuarter)

	// Calcular el inicio del semestre que contiene la fecha
	halfYear := (int(date.Month()) - 1) / 6
	startOfHalfYear := time.Date(date.Year(), time.Month(halfYear*6+1), 1, 0, 0, 0, 0, time.UTC)
	updateSubsequentSemiannualBalances(userID, startOfHalfYear)

	// Calcular el inicio del año que contiene la fecha
	startOfYear := time.Date(date.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
	updateSubsequentAnnualBalances(userID, startOfYear)

	log.Printf("Successfully recalculated all balances for user %s from date %s", userID, dateStr)
	return nil
}

func handleUpdateBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var updateRequest UpdateBillRequest
	err := json.NewDecoder(r.Body).Decode(&updateRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request
	if updateRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if updateRequest.BillID <= 0 {
		sendErrorResponse(w, "Valid bill ID is required", http.StatusBadRequest)
		return
	}

	// Check if the bill exists
	bill, err := fetchBillByID(updateRequest.BillID, updateRequest.UserID)
	if err != nil {
		log.Printf("Error fetching bill: %v", err)
		sendErrorResponse(w, "Error fetching bill", http.StatusInternalServerError)
		return
	}

	if bill == nil {
		sendErrorResponse(w, "Bill not found", http.StatusNotFound)
		return
	}

	// Keep track of the old values for balance adjustments if necessary
	oldAmount := bill.Amount
	oldPaid := bill.Paid
	oldDueDate := bill.DueDate

	// Update the bill with the provided values
	if updateRequest.Name != "" {
		bill.Name = updateRequest.Name
	}

	if updateRequest.Amount > 0 {
		bill.Amount = updateRequest.Amount
	}

	if updateRequest.DueDate != "" {
		bill.DueDate = updateRequest.DueDate
		// Recalculate overdue status after changing the due date
		updateOverdueStatus(bill)
	}

	bill.Recurring = updateRequest.Recurring

	if updateRequest.Category != "" {
		bill.Category = updateRequest.Category
	}

	if updateRequest.Icon != "" {
		bill.Icon = updateRequest.Icon
	}

	// Update the bill in the database
	err = updateBill(*bill)
	if err != nil {
		log.Printf("Error updating bill: %v", err)
		sendErrorResponse(w, "Error updating bill", http.StatusInternalServerError)
		return
	}

	// If the amount, due date or paid status changed, we need to update balances
	if bill.Amount != oldAmount || bill.DueDate != oldDueDate || bill.Paid != oldPaid {
		// If the bill is paid, update balances
		if bill.Paid {
			// Determinar los montos de cash y bank según el método de pago (asumimos bank por defecto)
			var cashAmt, bankAmt float64
			paymentMethod := "bank" // Valor por defecto

			if paymentMethod == "cash" {
				cashAmt = bill.Amount
				bankAmt = 0
			} else {
				cashAmt = 0
				bankAmt = bill.Amount
			}

			// If previous amount was different, first remove it
			if oldPaid && oldAmount != bill.Amount {
				if err := updateTimeBalances(bill.UserID, 0, 0, -oldAmount, -cashAmt, -bankAmt, oldDueDate); err != nil {
					log.Printf("Error updating time balances for old amount: %v", err)
				}
			}

			// Add the new amount
			if err := updateTimeBalances(bill.UserID, 0, 0, bill.Amount, cashAmt, bankAmt, bill.DueDate); err != nil {
				log.Printf("Error updating time balances for new amount: %v", err)
			}
		}

		// Recalcular todos los balances para asegurar que previous_xxx_amount y balance_xxx_amount se actualicen en cascada
		if err := recalculateAllBalances(bill.UserID, bill.DueDate); err != nil {
			log.Printf("Error recalculating balances: %v", err)
			// Continue despite the error
		}
	}

	// Return success response
	sendSuccessResponse(w, "Bill updated successfully", bill)
}

func handleDeleteBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var deleteRequest DeleteBillRequest
	err := json.NewDecoder(r.Body).Decode(&deleteRequest)
	if err != nil {
		sendErrorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request
	if deleteRequest.UserID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if deleteRequest.BillID <= 0 {
		sendErrorResponse(w, "Valid bill ID is required", http.StatusBadRequest)
		return
	}

	// Check if the bill exists
	bill, err := fetchBillByID(deleteRequest.BillID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error fetching bill: %v", err)
		sendErrorResponse(w, "Error fetching bill", http.StatusInternalServerError)
		return
	}

	if bill == nil {
		sendErrorResponse(w, "Bill not found", http.StatusNotFound)
		return
	}

	// Delete the bill from the database
	err = deleteBill(deleteRequest.BillID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error deleting bill: %v", err)
		sendErrorResponse(w, "Error deleting bill", http.StatusInternalServerError)
		return
	}

	// Return success response
	sendSuccessResponse(w, "Bill deleted successfully", nil)
}

func fetchBills(userID string) ([]Bill, error) {
	// Query all bills for the given user
	rows, err := db.Query(`
		SELECT id, user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, created_at, updated_at
		FROM bills
		WHERE user_id = ? AND paid = 0
		ORDER BY due_date ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bills []Bill
	for rows.Next() {
		var bill Bill
		var createdAt, updatedAt string
		err := rows.Scan(
			&bill.ID,
			&bill.UserID,
			&bill.Name,
			&bill.Amount,
			&bill.DueDate,
			&bill.Paid,
			&bill.Overdue,
			&bill.OverdueDays,
			&bill.Recurring,
			&bill.Category,
			&bill.Icon,
			&createdAt,
			&updatedAt,
		)
		if err != nil {
			return nil, err
		}

		// Update overdue status for each bill
		updateOverdueStatus(&bill)

		// Update the bill in the database if the overdue status changed
		if bill.Overdue {
			err = updateBill(bill)
			if err != nil {
				log.Printf("Error updating bill overdue status: %v", err)
				// Continue despite the error
			}
		}

		bills = append(bills, bill)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return bills, nil
}

func fetchBillByID(billID int, userID string) (*Bill, error) {
	var bill Bill
	err := db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, payment_method, created_at, updated_at
		FROM bills WHERE id = ? AND user_id = ?
	`, billID, userID).Scan(
		&bill.ID, &bill.UserID, &bill.Name, &bill.Amount, &bill.DueDate, &bill.Paid, &bill.Overdue, &bill.OverdueDays, &bill.Recurring, &bill.Category, &bill.Icon, &bill.PaymentMethod, &bill.CreatedAt, &bill.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("bill not found: %w", err)
		}
		return nil, err
	}

	// Update overdue status
	updateOverdueStatus(&bill)

	return &bill, nil
}

func addBill(bill Bill) (int, error) {
	res, err := db.Exec(`
		INSERT INTO bills (
			user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, payment_method
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`,
		bill.UserID,
		bill.Name,
		bill.Amount,
		bill.DueDate,
		bill.Paid,
		bill.Overdue,
		bill.OverdueDays,
		bill.Recurring,
		bill.Category,
		bill.Icon,
		bill.PaymentMethod,
	)
	if err != nil {
		return 0, err
	}

	// Get the ID of the newly inserted bill
	id, err := res.LastInsertId()
	if err != nil {
		return 0, err
	}

	return int(id), nil
}

func updateBill(bill Bill) error {
	_, err := db.Exec(`
		UPDATE bills
		SET name = ?,
			amount = ?,
			due_date = ?,
			paid = ?,
			overdue = ?,
			overdue_days = ?,
			recurring = ?,
			category = ?,
			icon = ?,
			payment_method = ?,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`,
		bill.Name,
		bill.Amount,
		bill.DueDate,
		bill.Paid,
		bill.Overdue,
		bill.OverdueDays,
		bill.Recurring,
		bill.Category,
		bill.Icon,
		bill.PaymentMethod,
		bill.ID,
		bill.UserID,
	)

	return err
}

func deleteBill(billID int, userID string) error {
	_, err := db.Exec(`
		DELETE FROM bills
		WHERE id = ? AND user_id = ?
	`, billID, userID)

	return err
}

func updateOverdueStatus(bill *Bill) {
	// Skip if the bill is already paid
	if bill.Paid {
		bill.Overdue = false
		bill.OverdueDays = 0
		return
	}

	// Parse the due date
	dueDate, err := time.Parse("2006-01-02", bill.DueDate)
	if err != nil {
		// If we can't parse the date, assume it's not overdue
		bill.Overdue = false
		bill.OverdueDays = 0
		return
	}

	// Get the current date
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	// Check if the bill is overdue
	if today.After(dueDate) {
		bill.Overdue = true
		bill.OverdueDays = int(today.Sub(dueDate).Hours() / 24)
	} else {
		bill.Overdue = false
		bill.OverdueDays = 0
	}
}

func calculateNextDueDate(dueDate string) (string, error) {
	// Parse the due date
	date, err := time.Parse("2006-01-02", dueDate)
	if err != nil {
		return "", err
	}

	// Add one month to the due date
	nextMonth := date.AddDate(0, 1, 0)

	// Format the date
	return nextMonth.Format("2006-01-02"), nil
}

func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(ApiResponse{
		Success: false,
		Message: message,
	})
}

// Función para actualizar los balances por periodos al pagar una factura
func updateTimeBalances(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, dateStr string) error {
	// Parse la fecha del gasto
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return fmt.Errorf("error parsing date: %v", err)
	}

	// Actualizar balance diario
	if err := updateDailyBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating daily balance: %v", err)
	}

	// Actualizar balance semanal
	if err := updateWeeklyBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating weekly balance: %v", err)
	}

	// Actualizar balance mensual
	if err := updateMonthlyBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating monthly balance: %v", err)
	}

	// Actualizar balance trimestral
	if err := updateQuarterlyBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating quarterly balance: %v", err)
	}

	// Actualizar balance semestral
	if err := updateSemiannualBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating semiannual balance: %v", err)
	}

	// Actualizar balance anual
	if err := updateAnnualBalance(userID, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount, date); err != nil {
		log.Printf("Error updating annual balance: %v", err)
	}

	return nil
}

func updateDailyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	dateStr := date.Format("2006-01-02")

	// Obtener el balance del día anterior para calcular el balance previo
	prevDate := date.AddDate(0, 0, -1)
	prevDateStr := prevDate.Format("2006-01-02")

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del día anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM daily_balance 
		WHERE user_id = ? AND date = ?
	`, userID, prevDateStr).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del día anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como el balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta fecha
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM daily_balance
		WHERE user_id = ? AND date = ?
	`, userID, dateStr).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			INSERT INTO daily_balance (user_id, date, income_amount, expense_amount, bills_amount, cash_amount, bank_amount, previous_cash_amount, previous_bank_amount, balance_cash_amount, balance_bank_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, dateStr, incomeAmount, expenseAmount, billsAmount, totalCashAmount, totalBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE daily_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				previous_balance = ?,
				balance = ?,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND date = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, previousBalance, balance, userID, dateStr)
	}

	if err != nil {
		return err
	}

	// Actualizar todos los días posteriores en cascada
	return updateSubsequentDailyBalances(userID, date.AddDate(0, 0, 1))
}

// Función para actualizar días posteriores en cascada
func updateSubsequentDailyBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a un año para evitar bucles infinitos
	endDate := startDate.AddDate(1, 0, 0)
	currentDate := startDate

	for currentDate.Before(endDate) {
		currentDateStr := currentDate.Format("2006-01-02")

		// Verificar si existe un registro para esta fecha
		var exists bool
		var incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64
		err := db.QueryRow(`
			SELECT 1, income_amount, expense_amount, bills_amount, cash_amount, bank_amount FROM daily_balance
			WHERE user_id = ? AND date = ?
		`, userID, currentDateStr).Scan(&exists, &incomeAmount, &expenseAmount, &billsAmount, &cashAmount, &bankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		if err == sql.ErrNoRows {
			// No hay más registros para actualizar
			break
		}

		// Obtener el balance del día anterior
		prevDate := currentDate.AddDate(0, 0, -1)
		prevDateStr := prevDate.Format("2006-01-02")

		var previousBalance float64
		var prevCashAmount, prevBankAmount float64
		err = db.QueryRow(`
			SELECT balance, cash_amount, bank_amount FROM daily_balance 
			WHERE user_id = ? AND date = ?
		`, userID, prevDateStr).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

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

		// CAMBIO EN LA LÓGICA: Siempre acumulamos los valores del día anterior
		// independientemente de si hay transacciones en este día o no
		hasTransactions := incomeAmount != 0 || expenseAmount != 0 || billsAmount != 0

		// Inicializar con los valores del día anterior
		newCashAmount := prevCashAmount
		newBankAmount := prevBankAmount

		// Si hay transacciones propias en este día, las sumamos a lo heredado
		if hasTransactions {
			// Agregamos las transacciones propias de este día
			newCashAmount += cashAmount
			newBankAmount += bankAmount
		}

		// Calcular los valores de balance para cash y bank
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE daily_balance
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
			WHERE user_id = ? AND date = ?
		`, previousBalance, balance, newCashAmount, newBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, userID, currentDateStr)

		if err != nil {
			return err
		}

		// Pasar al siguiente día
		currentDate = currentDate.AddDate(0, 0, 1)
	}

	return nil
}

func updateWeeklyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Calcular el año e ISO semana
	year, week := date.ISOWeek()
	yearWeek := fmt.Sprintf("%d-W%02d", year, week)

	// Calcular fecha de inicio y fin de la semana
	// El día 0 de una semana es domingo, necesitamos ajustar para obtener lunes (día 1)
	dayOfWeek := int(date.Weekday())
	if dayOfWeek == 0 {
		dayOfWeek = 7 // Convertir domingo (0) a 7 para restar correctamente
	}
	startDate := date.AddDate(0, 0, -(dayOfWeek - 1))
	endDate := startDate.AddDate(0, 0, 6)

	startDateStr := startDate.Format("2006-01-02")
	endDateStr := endDate.Format("2006-01-02")

	// Calcular la semana anterior
	prevWeekStart := startDate.AddDate(0, 0, -7)
	prevYearWeek := fmt.Sprintf("%d-W%02d", prevWeekStart.Year(), func() int {
		year, week := prevWeekStart.ISOWeek()
		if prevWeekStart.Year() != year {
			// Ajustar para casos especiales al final/inicio de año
			return 53 // Última semana del año anterior
		}
		return week
	}())

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance de la semana anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM weekly_balance 
		WHERE user_id = ? AND year_week = ?
	`, userID, prevYearWeek).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro de la semana anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como: balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta semana
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM weekly_balance
		WHERE user_id = ? AND year_week = ?
	`, userID, yearWeek).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			INSERT INTO weekly_balance (user_id, year_week, start_date, end_date, income_amount, expense_amount, bills_amount, cash_amount, bank_amount, previous_cash_amount, previous_bank_amount, balance_cash_amount, balance_bank_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearWeek, startDateStr, endDateStr, incomeAmount, expenseAmount, billsAmount, totalCashAmount, totalBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE weekly_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_week = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount, previousBalance, balance, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, userID, yearWeek)
	}

	if err != nil {
		return err
	}

	// Actualizar todas las semanas posteriores en cascada
	return updateSubsequentWeeklyBalances(userID, startDate.AddDate(0, 0, 7))
}

// Función para actualizar semanas posteriores en cascada
func updateSubsequentWeeklyBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a un año para evitar bucles infinitos
	endDate := startDate.AddDate(1, 0, 0)
	currentDate := startDate

	for currentDate.Before(endDate) {
		year, week := currentDate.ISOWeek()
		currentYearWeek := fmt.Sprintf("%d-W%02d", year, week)

		// Verificar si existe un registro para esta semana
		var exists bool
		var incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64
		err := db.QueryRow(`
			SELECT 1, income_amount, expense_amount, bills_amount, cash_amount, bank_amount FROM weekly_balance
			WHERE user_id = ? AND year_week = ?
		`, userID, currentYearWeek).Scan(&exists, &incomeAmount, &expenseAmount, &billsAmount, &cashAmount, &bankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		if err == sql.ErrNoRows {
			// No hay más registros para actualizar
			break
		}

		// Obtener el balance de la semana anterior
		prevWeekStart := currentDate.AddDate(0, 0, -7)
		prevYear, prevWeek := prevWeekStart.ISOWeek()
		prevYearWeek := fmt.Sprintf("%d-W%02d", prevYear, prevWeek)

		var previousBalance float64
		var prevCashAmount, prevBankAmount float64
		err = db.QueryRow(`
			SELECT balance, cash_amount, bank_amount FROM weekly_balance 
			WHERE user_id = ? AND year_week = ?
		`, userID, prevYearWeek).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

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

		// CAMBIO EN LA LÓGICA: Siempre acumulamos los valores de la semana anterior
		// independientemente de si hay transacciones en esta semana o no
		hasTransactions := incomeAmount != 0 || expenseAmount != 0 || billsAmount != 0

		// Inicializar con los valores de la semana anterior
		newCashAmount := prevCashAmount
		newBankAmount := prevBankAmount

		// Si hay transacciones propias en esta semana, las sumamos a lo heredado
		if hasTransactions {
			// Agregamos las transacciones propias de esta semana
			newCashAmount += cashAmount
			newBankAmount += bankAmount
		}

		// Calcular los valores de balance para cash y bank
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE weekly_balance
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
			WHERE user_id = ? AND year_week = ?
		`, previousBalance, balance, newCashAmount, newBankAmount, prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount, userID, currentYearWeek)

		if err != nil {
			return err
		}

		// Pasar a la siguiente semana
		currentDate = currentDate.AddDate(0, 0, 7)
	}

	return nil
}

func updateMonthlyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Obtener año y mes de la fecha
	yearMonth := date.Format("2006-01")

	// Calcular el mes anterior
	prevMonth := date.AddDate(0, -1, 0)
	prevYearMonth := prevMonth.Format("2006-01")

	// Crear una transacción para mantener consistencia
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("error starting transaction: %v", err)
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

	// PARTE 1: Actualizar la tabla monthly_balance
	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del mes anterior
	err = tx.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM monthly_balance 
		WHERE user_id = ? AND year_month = ?
	`, userID, prevYearMonth).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return rollbackOnError(err)
	}
	// Si no existe registro del mes anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como: balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este mes
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = tx.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM monthly_balance
		WHERE user_id = ? AND year_month = ?
	`, userID, yearMonth).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return rollbackOnError(err)
	}

	// Calcular los balance_XXX_amount
	balanceCashAmount := prevCashAmount + cashAmount
	balanceBankAmount := prevBankAmount + bankAmount

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = tx.Exec(`
			INSERT INTO monthly_balance (
				user_id, year_month, income_amount, expense_amount, bills_amount, 
				cash_amount, bank_amount, previous_cash_amount, previous_bank_amount, 
				balance_cash_amount, balance_bank_amount, balance, previous_balance
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearMonth, incomeAmount, expenseAmount, billsAmount,
			cashAmount, bankAmount, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, balance, previousBalance)

		if err != nil {
			return rollbackOnError(fmt.Errorf("error inserting monthly_balance: %v", err))
		}
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = tx.Exec(`
			UPDATE monthly_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_month = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount,
			previousBalance, balance, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, userID, yearMonth)

		if err != nil {
			return rollbackOnError(fmt.Errorf("error updating monthly_balance: %v", err))
		}
	}

	// PARTE 2: Actualizar la tabla monthly_cash_bank_balance
	var prevCashAmountCB, prevBankAmountCB float64

	// Buscar los valores del mes anterior en monthly_cash_bank_balance
	err = tx.QueryRow(`
		SELECT cash_amount, bank_amount FROM monthly_cash_bank_balance 
		WHERE user_id = ? AND year_month = ?
	`, userID, prevYearMonth).Scan(&prevCashAmountCB, &prevBankAmountCB)

	if err != nil && err != sql.ErrNoRows {
		return rollbackOnError(err)
	}
	// Si no existe registro del mes anterior, buscar el último mes anterior disponible
	if err == sql.ErrNoRows {
		err = tx.QueryRow(`
			SELECT cash_amount, bank_amount FROM monthly_cash_bank_balance 
			WHERE user_id = ? AND year_month < ?
			ORDER BY year_month DESC LIMIT 1
		`, userID, yearMonth).Scan(&prevCashAmountCB, &prevBankAmountCB)

		if err != nil && err != sql.ErrNoRows {
			return rollbackOnError(err)
		}

		// Si no se encuentra ningún mes anterior, ambos valores son 0
		if err == sql.ErrNoRows {
			prevCashAmountCB = 0
			prevBankAmountCB = 0
		}
	}

	// Verificar si ya existe un registro para este mes en monthly_cash_bank_balance
	var existsCB bool
	var existingIncomeCash, existingIncomeBank float64
	var existingExpenseCash, existingExpenseBank float64
	var existingBillCash, existingBillBank float64
	var existingCashAmountCB, existingBankAmountCB float64
	err = tx.QueryRow(`
		SELECT 1, income_cash_amount, income_bank_amount, 
		expense_cash_amount, expense_bank_amount, 
		bill_cash_amount, bill_bank_amount,
		cash_amount, bank_amount
		FROM monthly_cash_bank_balance
		WHERE user_id = ? AND year_month = ?
	`, userID, yearMonth).Scan(&existsCB, &existingIncomeCash, &existingIncomeBank,
		&existingExpenseCash, &existingExpenseBank,
		&existingBillCash, &existingBillBank,
		&existingCashAmountCB, &existingBankAmountCB)

	if err != nil && err != sql.ErrNoRows {
		return rollbackOnError(err)
	}

	// Calcular los montos para balance_cash_amount y balance_bank_amount
	var balanceCashAmountCB, balanceBankAmountCB float64
	balanceCashAmountCB = prevCashAmountCB - cashAmount // Restamos porque es un gasto o factura
	balanceBankAmountCB = prevBankAmountCB - bankAmount

	if err == sql.ErrNoRows {
		// No existe registro, crear uno nuevo
		_, err = tx.Exec(`
			INSERT INTO monthly_cash_bank_balance (
				user_id, year_month,
				income_cash_amount, income_bank_amount,
				expense_cash_amount, expense_bank_amount,
				bill_cash_amount, bill_bank_amount,
				cash_amount, previous_cash_amount,
				bank_amount, previous_bank_amount,
				balance_cash_amount, balance_bank_amount
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearMonth,
			0, 0, // income_cash_amount, income_bank_amount
			0, 0, // expense_cash_amount, expense_bank_amount
			cashAmount, bankAmount, // bill_cash_amount, bill_bank_amount
			cashAmount, prevCashAmountCB, // cash_amount, previous_cash_amount
			bankAmount, prevBankAmountCB, // bank_amount, previous_bank_amount
			balanceCashAmountCB, balanceBankAmountCB) // balance_cash_amount, balance_bank_amount
	} else {
		// Actualizar registro existente
		// Actualizar los montos de cash y bank
		newCashAmountCB := existingCashAmountCB - cashAmount // Restamos porque es un gasto o factura
		newBankAmountCB := existingBankAmountCB - bankAmount

		_, err = tx.Exec(`
			UPDATE monthly_cash_bank_balance SET
				bill_cash_amount = bill_cash_amount + ?,
				bill_bank_amount = bill_bank_amount + ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_month = ?
		`, cashAmount, bankAmount,
			newCashAmountCB, newBankAmountCB,
			prevCashAmountCB, prevBankAmountCB,
			balanceCashAmountCB, balanceBankAmountCB,
			userID, yearMonth)
	}

	if err != nil {
		return rollbackOnError(err)
	}

	// Confirmar la transacción
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("error committing transaction: %v", err)
	}

	// Actualizar todos los meses posteriores en cascada
	return updateSubsequentMonthlyBalances(userID, date.AddDate(0, 1, 0))
}

// Función para actualizar meses posteriores en cascada
func updateSubsequentMonthlyBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a 5 años para evitar bucles infinitos
	currentDate := startDate

	// Mantener un registro de los meses procesados
	processedMonths := make(map[string]struct{})

	// Encontrar el mes anterior al mes de inicio para saber el valor de partida
	var lastPrevCashAmount, lastPrevBankAmount float64
	prevToStartDate := startDate.AddDate(0, -1, 0)
	prevToStartYearMonth := prevToStartDate.Format("2006-01")

	err := db.QueryRow(`
		SELECT cash_amount, bank_amount FROM monthly_cash_bank_balance 
		WHERE user_id = ? AND year_month = ?
	`, userID, prevToStartYearMonth).Scan(&lastPrevCashAmount, &lastPrevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// Si no hay un mes inmediatamente anterior, buscar el último mes anterior disponible
		err = db.QueryRow(`
			SELECT cash_amount, bank_amount FROM monthly_cash_bank_balance 
			WHERE user_id = ? AND year_month < ?
			ORDER BY year_month DESC LIMIT 1
		`, userID, startDate.Format("2006-01")).Scan(&lastPrevCashAmount, &lastPrevBankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		// Si no se encuentra ningún mes anterior, usar valores en cero
		if err == sql.ErrNoRows {
			lastPrevCashAmount = 0
			lastPrevBankAmount = 0
		}
	}

	// Obtener todos los meses existentes desde la fecha de inicio hasta 5 años después
	rows, err := db.Query(`
		SELECT year_month FROM monthly_cash_bank_balance
		WHERE user_id = ? AND year_month >= ?
		ORDER BY year_month ASC
	`, userID, startDate.Format("2006-01"))

	if err != nil {
		return err
	}
	defer rows.Close()

	var existingMonths []string
	for rows.Next() {
		var yearMonth string
		if err := rows.Scan(&yearMonth); err != nil {
			return err
		}
		existingMonths = append(existingMonths, yearMonth)
	}

	// Si no hay meses existentes, no hay nada que procesar
	if len(existingMonths) == 0 {
		return nil
	}

	// Determinar el último mes que necesitamos procesar
	lastMonthStr := existingMonths[len(existingMonths)-1]
	lastMonthParts := strings.Split(lastMonthStr, "-")
	if len(lastMonthParts) != 2 {
		return fmt.Errorf("invalid month format: %s", lastMonthStr)
	}
	lastYear, _ := strconv.Atoi(lastMonthParts[0])
	lastMonth, _ := strconv.Atoi(lastMonthParts[1])
	lastDate := time.Date(lastYear, time.Month(lastMonth), 1, 0, 0, 0, 0, time.UTC)

	// Crear un mapa para acceso rápido a los meses existentes
	existingMonthsMap := make(map[string]bool)
	for _, m := range existingMonths {
		existingMonthsMap[m] = true
	}

	// Variables para mantener los valores acumulados
	currentCashAmount := lastPrevCashAmount
	currentBankAmount := lastPrevBankAmount

	// Iterar mes por mes desde la fecha de inicio hasta el último mes existente
	for currentDate.Before(lastDate.AddDate(0, 1, 0)) {
		currentYearMonth := currentDate.Format("2006-01")

		if existingMonthsMap[currentYearMonth] {
			// Si el mes existe, actualizarlo con los valores correctos
			var incomeCashAmount, incomeBankAmount float64
			var expenseCashAmount, expenseBankAmount float64
			var billCashAmount, billBankAmount float64

			err := db.QueryRow(`
				SELECT income_cash_amount, income_bank_amount,
				       expense_cash_amount, expense_bank_amount,
				       bill_cash_amount, bill_bank_amount
				FROM monthly_cash_bank_balance
				WHERE user_id = ? AND year_month = ?
			`, userID, currentYearMonth).Scan(
				&incomeCashAmount, &incomeBankAmount,
				&expenseCashAmount, &expenseBankAmount,
				&billCashAmount, &billBankAmount)

			if err != nil {
				return err
			}

			// Calcular nuevos montos considerando los ingresos, gastos y facturas del mes actual
			prevCashAmount := currentCashAmount
			prevBankAmount := currentBankAmount

			// Actualizar los balances con el nuevo balance previo y las transacciones del mes
			currentCashAmount = prevCashAmount + incomeCashAmount - expenseCashAmount - billCashAmount
			currentBankAmount = prevBankAmount + incomeBankAmount - expenseBankAmount - billBankAmount

			// Actualizar el registro
			_, err = db.Exec(`
				UPDATE monthly_cash_bank_balance
				SET cash_amount = ?,
				    bank_amount = ?,
				    previous_cash_amount = ?,
				    previous_bank_amount = ?,
				    balance_cash_amount = ?,
				    balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				    updated_at = CURRENT_TIMESTAMP
				WHERE user_id = ? AND year_month = ?
			`, currentCashAmount, currentBankAmount,
				prevCashAmount, prevBankAmount,
				currentCashAmount, currentBankAmount,
				userID, currentYearMonth)

			if err != nil {
				return err
			}
		} else {
			// Si el mes no existe, crear un registro para él con valores en 0 para ingresos/gastos/facturas
			// pero con los valores correctos basados en el mes anterior
			prevCashAmount := currentCashAmount
			prevBankAmount := currentBankAmount

			// Los montos no cambian ya que no hay transacciones
			// Sin embargo, creamos el registro para mantener la continuidad
			_, err = db.Exec(`
				INSERT INTO monthly_cash_bank_balance (
					user_id, year_month,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, previous_cash_amount,
					bank_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, userID, currentYearMonth,
				0, 0,
				0, 0,
				0, 0,
				prevCashAmount, prevCashAmount,
				prevBankAmount, prevBankAmount,
				prevCashAmount, prevBankAmount)

			if err != nil {
				// Si el error es por duplicado, ignorarlo
				if !strings.Contains(err.Error(), "UNIQUE constraint failed") {
					return err
				}
			}
		}

		// Marcar este mes como procesado
		processedMonths[currentYearMonth] = struct{}{}

		// Avanzar al mes siguiente
		currentDate = currentDate.AddDate(0, 1, 0)
	}

	return nil
}

func updateQuarterlyBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Calcular el trimestre (1-4)
	quarter := (int(date.Month())-1)/3 + 1
	yearQuarter := fmt.Sprintf("%d-Q%d", date.Year(), quarter)

	// Calcular fecha de inicio y fin del trimestre
	startMonth := (quarter-1)*3 + 1
	startDate := time.Date(date.Year(), time.Month(startMonth), 1, 0, 0, 0, 0, date.Location())
	endDate := startDate.AddDate(0, 3, -1)

	startDateStr := startDate.Format("2006-01-02")
	endDateStr := endDate.Format("2006-01-02")

	// Calcular el trimestre anterior
	prevQuarterDate := startDate.AddDate(0, -3, 0)
	prevQuarter := (int(prevQuarterDate.Month())-1)/3 + 1
	prevYearQuarter := fmt.Sprintf("%d-Q%d", prevQuarterDate.Year(), prevQuarter)

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del trimestre anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM quarterly_balance 
		WHERE user_id = ? AND year_quarter = ?
	`, userID, prevYearQuarter).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del trimestre anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como: balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este trimestre
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM quarterly_balance
		WHERE user_id = ? AND year_quarter = ?
	`, userID, yearQuarter).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			INSERT INTO quarterly_balance (
				user_id, year_quarter, start_date, end_date, 
				income_amount, expense_amount, bills_amount, 
				cash_amount, bank_amount, 
				balance, previous_balance, 
				previous_cash_amount, previous_bank_amount, 
				balance_cash_amount, balance_bank_amount
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearQuarter, startDateStr, endDateStr,
			incomeAmount, expenseAmount, billsAmount,
			totalCashAmount, totalBankAmount,
			balance, previousBalance,
			prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE quarterly_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_quarter = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount,
			previousBalance, balance, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, userID, yearQuarter)
	}

	if err != nil {
		return err
	}

	// Actualizar todos los trimestres posteriores en cascada
	nextQuarterDate := startDate.AddDate(0, 3, 0)
	return updateSubsequentQuarterlyBalances(userID, nextQuarterDate)
}

// Función para actualizar trimestres posteriores en cascada
func updateSubsequentQuarterlyBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a 5 años para evitar bucles infinitos
	// Eliminamos la variable currentDate que no se usa

	// Mantener un registro de los trimestres procesados
	processedQuarters := make(map[string]struct{})

	// Encontrar el trimestre anterior al trimestre de inicio para saber el valor de partida
	var lastPrevCashAmount, lastPrevBankAmount float64

	// Calcular el trimestre anterior
	quarter := (int(startDate.Month()) - 1) / 3
	year := startDate.Year()
	var prevYear, prevQuarter int
	if quarter == 0 {
		prevYear = year - 1
		prevQuarter = 3 // Q4 del año anterior
	} else {
		prevYear = year
		prevQuarter = quarter - 1
	}
	prevToStartYearQuarter := fmt.Sprintf("%d-Q%d", prevYear, prevQuarter+1)

	err := db.QueryRow(`
		SELECT cash_amount, bank_amount FROM quarterly_cash_bank_balance 
		WHERE user_id = ? AND year_quarter = ?
	`, userID, prevToStartYearQuarter).Scan(&lastPrevCashAmount, &lastPrevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// Si no hay un trimestre inmediatamente anterior, buscar el último trimestre anterior disponible
		err = db.QueryRow(`
			SELECT cash_amount, bank_amount FROM quarterly_cash_bank_balance 
			WHERE user_id = ? AND year_quarter < ?
			ORDER BY year_quarter DESC LIMIT 1
		`, userID, fmt.Sprintf("%d-Q%d", year, quarter+1)).Scan(&lastPrevCashAmount, &lastPrevBankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		// Si no se encuentra ningún trimestre anterior, usar valores en cero
		if err == sql.ErrNoRows {
			lastPrevCashAmount = 0
			lastPrevBankAmount = 0
		}
	}

	// Obtener todos los trimestres existentes desde la fecha de inicio
	rows, err := db.Query(`
		SELECT year_quarter FROM quarterly_cash_bank_balance
		WHERE user_id = ? AND year_quarter >= ?
		ORDER BY year_quarter ASC
	`, userID, fmt.Sprintf("%d-Q%d", year, quarter+1))

	if err != nil {
		return err
	}
	defer rows.Close()

	var existingQuarters []string
	for rows.Next() {
		var yearQuarter string
		if err := rows.Scan(&yearQuarter); err != nil {
			return err
		}
		existingQuarters = append(existingQuarters, yearQuarter)
	}

	// Si no hay trimestres existentes, no hay nada que procesar
	if len(existingQuarters) == 0 {
		return nil
	}

	// Determinar el último trimestre que necesitamos procesar
	lastQuarterStr := existingQuarters[len(existingQuarters)-1]
	quarterRegex := regexp.MustCompile(`(\d+)-Q(\d+)`)
	matches := quarterRegex.FindStringSubmatch(lastQuarterStr)
	if len(matches) != 3 {
		return fmt.Errorf("invalid quarter format: %s", lastQuarterStr)
	}
	lastYear, _ := strconv.Atoi(matches[1])
	lastQuarter, _ := strconv.Atoi(matches[2])
	lastQuarter-- // Convertir de Q1-Q4 a 0-3

	// Crear un mapa para acceso rápido a los trimestres existentes
	existingQuartersMap := make(map[string]bool)
	for _, q := range existingQuarters {
		existingQuartersMap[q] = true
	}

	// Variables para mantener los valores acumulados
	currentCashAmount := lastPrevCashAmount
	currentBankAmount := lastPrevBankAmount

	// Iterar trimestre por trimestre desde la fecha de inicio hasta el último trimestre existente
	currentYear := year
	currentQuarter := quarter

	for {
		// Avanzar al trimestre siguiente (ya que estamos empezando desde el anterior a startDate)
		if currentQuarter == 3 {
			currentYear++
			currentQuarter = 0
		} else {
			currentQuarter++
		}

		currentYearQuarter := fmt.Sprintf("%d-Q%d", currentYear, currentQuarter+1)

		// Si hemos superado el último trimestre, salimos
		lastYearQuarter := fmt.Sprintf("%d-Q%d", lastYear, lastQuarter+1)
		if compareQuarters(currentYearQuarter, lastYearQuarter) > 0 {
			break
		}

		if existingQuartersMap[currentYearQuarter] {
			// Si el trimestre existe, actualizarlo con los valores correctos
			var incomeCashAmount, incomeBankAmount float64
			var expenseCashAmount, expenseBankAmount float64
			var billCashAmount, billBankAmount float64

			err := db.QueryRow(`
				SELECT income_cash_amount, income_bank_amount,
				       expense_cash_amount, expense_bank_amount,
				       bill_cash_amount, bill_bank_amount
				FROM quarterly_cash_bank_balance
				WHERE user_id = ? AND year_quarter = ?
			`, userID, currentYearQuarter).Scan(
				&incomeCashAmount, &incomeBankAmount,
				&expenseCashAmount, &expenseBankAmount,
				&billCashAmount, &billBankAmount)

			if err != nil {
				return err
			}

			// Calcular nuevos montos considerando los ingresos, gastos y facturas del trimestre actual
			prevCashAmount := currentCashAmount
			prevBankAmount := currentBankAmount

			// Actualizar los balances con el nuevo balance previo y las transacciones del trimestre
			currentCashAmount = prevCashAmount + incomeCashAmount - expenseCashAmount - billCashAmount
			currentBankAmount = prevBankAmount + incomeBankAmount - expenseBankAmount - billBankAmount

			// Actualizar el registro
			_, err = db.Exec(`
				UPDATE quarterly_cash_bank_balance
				SET cash_amount = ?,
				    bank_amount = ?,
				    previous_cash_amount = ?,
				    previous_bank_amount = ?,
				    balance_cash_amount = ?,
				    balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				    updated_at = CURRENT_TIMESTAMP
				WHERE user_id = ? AND year_quarter = ?
			`, currentCashAmount, currentBankAmount,
				prevCashAmount, prevBankAmount,
				currentCashAmount, currentBankAmount,
				userID, currentYearQuarter)

			if err != nil {
				return err
			}
		} else {
			// Si el trimestre no existe, crear un registro para él con valores en 0 para ingresos/gastos/facturas
			// pero con los valores correctos basados en el trimestre anterior
			prevCashAmount := currentCashAmount
			prevBankAmount := currentBankAmount

			// Los montos no cambian ya que no hay transacciones
			// Sin embargo, creamos el registro para mantener la continuidad
			_, err = db.Exec(`
				INSERT INTO quarterly_cash_bank_balance (
					user_id, year_quarter,
					income_cash_amount, income_bank_amount,
					expense_cash_amount, expense_bank_amount,
					bill_cash_amount, bill_bank_amount,
					cash_amount, previous_cash_amount,
					bank_amount, previous_bank_amount,
					balance_cash_amount, balance_bank_amount
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, userID, currentYearQuarter,
				0, 0,
				0, 0,
				0, 0,
				prevCashAmount, prevCashAmount,
				prevBankAmount, prevBankAmount,
				prevCashAmount, prevBankAmount)

			if err != nil {
				// Si el error es por duplicado, ignorarlo
				if !strings.Contains(err.Error(), "UNIQUE constraint failed") {
					return err
				}
			}
		}

		// Marcar este trimestre como procesado
		processedQuarters[currentYearQuarter] = struct{}{}
	}

	return nil
}

// Función auxiliar para comparar trimestres
func compareQuarters(q1, q2 string) int {
	q1Parts := strings.Split(q1, "-Q")
	q2Parts := strings.Split(q2, "-Q")

	if len(q1Parts) != 2 || len(q2Parts) != 2 {
		return 0 // Error formato
	}

	year1, _ := strconv.Atoi(q1Parts[0])
	quarter1, _ := strconv.Atoi(q1Parts[1])
	year2, _ := strconv.Atoi(q2Parts[0])
	quarter2, _ := strconv.Atoi(q2Parts[1])

	if year1 != year2 {
		return year1 - year2
	}
	return quarter1 - quarter2
}

func updateSemiannualBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Calcular el semestre (1-2)
	half := (int(date.Month())-1)/6 + 1
	yearHalf := fmt.Sprintf("%d-H%d", date.Year(), half)

	// Calcular fecha de inicio y fin del semestre
	startMonth := (half-1)*6 + 1
	startDate := time.Date(date.Year(), time.Month(startMonth), 1, 0, 0, 0, 0, date.Location())
	endDate := startDate.AddDate(0, 6, -1)

	startDateStr := startDate.Format("2006-01-02")
	endDateStr := endDate.Format("2006-01-02")

	// Calcular el semestre anterior
	prevHalfDate := startDate.AddDate(0, -6, 0)
	prevHalf := (int(prevHalfDate.Month())-1)/6 + 1
	prevYearHalf := fmt.Sprintf("%d-H%d", prevHalfDate.Year(), prevHalf)

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del semestre anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM semiannual_balance 
		WHERE user_id = ? AND year_half = ?
	`, userID, prevYearHalf).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del semestre anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como: balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este semestre
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM semiannual_balance
		WHERE user_id = ? AND year_half = ?
	`, userID, yearHalf).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			INSERT INTO semiannual_balance (
				user_id, year_half, start_date, end_date, 
				income_amount, expense_amount, bills_amount, 
				cash_amount, bank_amount,
				previous_cash_amount, previous_bank_amount,
				balance_cash_amount, balance_bank_amount,
				balance, previous_balance
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearHalf, startDateStr, endDateStr,
			incomeAmount, expenseAmount, billsAmount,
			totalCashAmount, totalBankAmount,
			prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount,
			balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE semiannual_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_half = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount,
			previousBalance, balance, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, userID, yearHalf)
	}

	if err != nil {
		return err
	}

	// Actualizar todos los semestres posteriores en cascada
	return updateSubsequentSemiannualBalances(userID, startDate.AddDate(0, 6, 0))
}

// Función para actualizar semestres posteriores en cascada
func updateSubsequentSemiannualBalances(userID string, startDate time.Time) error {
	// Limitar el proceso a 5 años para evitar bucles infinitos
	endDate := startDate.AddDate(5, 0, 0)
	currentDate := startDate

	for currentDate.Before(endDate) {
		// Determinar el semestre actual
		half := (int(currentDate.Month())-1)/6 + 1
		currentYearHalf := fmt.Sprintf("%d-H%d", currentDate.Year(), half)

		// Verificar si existe un registro para este semestre
		var exists bool
		var incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64
		err := db.QueryRow(`
			SELECT 1, income_amount, expense_amount, bills_amount, cash_amount, bank_amount FROM semiannual_balance
			WHERE user_id = ? AND year_half = ?
		`, userID, currentYearHalf).Scan(&exists, &incomeAmount, &expenseAmount, &billsAmount, &cashAmount, &bankAmount)

		if err != nil && err != sql.ErrNoRows {
			return err
		}

		if err == sql.ErrNoRows {
			// No hay más registros para actualizar
			break
		}

		// Obtener el balance del semestre anterior
		prevHalfDate := currentDate.AddDate(0, -6, 0)
		prevHalf := (int(prevHalfDate.Month())-1)/6 + 1
		prevYearHalf := fmt.Sprintf("%d-H%d", prevHalfDate.Year(), prevHalf)

		var previousBalance float64
		var prevCashAmount, prevBankAmount float64
		err = db.QueryRow(`
			SELECT balance, cash_amount, bank_amount FROM semiannual_balance 
			WHERE user_id = ? AND year_half = ?
		`, userID, prevYearHalf).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

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

		// CAMBIO EN LA LÓGICA: Siempre acumulamos los valores del semestre anterior
		// independientemente de si hay transacciones en este semestre o no
		hasTransactions := incomeAmount != 0 || expenseAmount != 0 || billsAmount != 0

		// Inicializar con los valores del semestre anterior
		newCashAmount := prevCashAmount
		newBankAmount := prevBankAmount

		// Si hay transacciones propias en este semestre, las sumamos a lo heredado
		if hasTransactions {
			// Agregamos las transacciones propias de este semestre
			newCashAmount += cashAmount
			newBankAmount += bankAmount
		}

		// Calcular los valores de balance para cash y bank
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE semiannual_balance
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
			WHERE user_id = ? AND year_half = ?
		`, previousBalance, balance, newCashAmount, newBankAmount,
			prevCashAmount, prevBankAmount, balanceCashAmount, balanceBankAmount,
			userID, currentYearHalf)

		if err != nil {
			return err
		}

		// Pasar al siguiente semestre
		currentDate = currentDate.AddDate(0, 6, 0)
	}

	return nil
}

func updateAnnualBalance(userID string, incomeAmount, expenseAmount, billsAmount, cashAmount, bankAmount float64, date time.Time) error {
	// Calcular el año
	year := strconv.Itoa(date.Year())

	// Calcular el año anterior
	prevYear := strconv.Itoa(date.Year() - 1)

	var previousBalance float64
	var prevCashAmount, prevBankAmount float64

	// Buscar el balance del año anterior
	err := db.QueryRow(`
		SELECT balance, cash_amount, bank_amount FROM annual_balance 
		WHERE user_id = ? AND year = ?
	`, userID, prevYear).Scan(&previousBalance, &prevCashAmount, &prevBankAmount)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del año anterior, el balance previo es 0
	if err == sql.ErrNoRows {
		previousBalance = 0
		prevCashAmount = 0
		prevBankAmount = 0
	}

	// Calcular el balance como: balance previo + ingresos - gastos - facturas
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este año
	var exists bool
	var existingCash, existingBank float64
	var existingIncome, existingExpense, existingBills float64
	err = db.QueryRow(`
		SELECT 1, cash_amount, bank_amount, income_amount, expense_amount, bills_amount FROM annual_balance
		WHERE user_id = ? AND year = ?
	`, userID, year).Scan(&exists, &existingCash, &existingBank, &existingIncome, &existingExpense, &existingBills)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		// Los montos de efectivo y banco deben acumularse del período anterior
		totalCashAmount := prevCashAmount + cashAmount
		totalBankAmount := prevBankAmount + bankAmount

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			INSERT INTO annual_balance (
				user_id, year, 
				income_amount, expense_amount, bills_amount, 
				cash_amount, bank_amount, 
				previous_cash_amount, previous_bank_amount,
				balance_cash_amount, balance_bank_amount,
				balance, previous_balance
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, year,
			incomeAmount, expenseAmount, billsAmount,
			totalCashAmount, totalBankAmount,
			prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount,
			balance, previousBalance)
	} else {
		// Actualizar registro existente
		// Calculamos los nuevos totales sumando los valores existentes
		newIncome := existingIncome + incomeAmount
		newExpense := existingExpense + expenseAmount
		newBills := existingBills + billsAmount

		// Actualizar los montos de cash y bank sumando los nuevos valores a los existentes
		newCashAmount := existingCash + cashAmount
		newBankAmount := existingBank + bankAmount

		// Recalcular el balance
		balance := previousBalance + newIncome - newExpense - newBills

		// Calcular los balance_XXX_amount
		balanceCashAmount := prevCashAmount + cashAmount
		balanceBankAmount := prevBankAmount + bankAmount

		_, err = db.Exec(`
			UPDATE annual_balance
			SET income_amount = ?,
				expense_amount = ?,
				bills_amount = ?,
				cash_amount = ?,
				bank_amount = ?,
				previous_balance = ?,
				balance = ?,
				previous_cash_amount = ?,
				previous_bank_amount = ?,
				balance_cash_amount = ?,
				balance_bank_amount = ?,
			total_balance = (balance_cash_amount + balance_bank_amount),
			total_previous_balance = (previous_cash_amount + previous_bank_amount),
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year = ?
		`, newIncome, newExpense, newBills, newCashAmount, newBankAmount,
			previousBalance, balance, prevCashAmount, prevBankAmount,
			balanceCashAmount, balanceBankAmount, userID, year)
	}

	if err != nil {
		return err
	}

	// No necesitamos actualizar años posteriores, ya que el proceso se hace anualmente
	// y no hay una cascada inmediata que actualizar
	return nil
}

// Add cash_amount and bank_amount columns to all balance tables if they don't exist
func addCashBankColumnsToAllTables() {
	alterTableSafely("daily_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("daily_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")

	alterTableSafely("weekly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("weekly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")

	alterTableSafely("monthly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("monthly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")

	alterTableSafely("quarterly_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("quarterly_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")

	alterTableSafely("semiannual_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("semiannual_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")

	alterTableSafely("annual_balance", "cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "previous_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "previous_bank_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "balance_cash_amount", "REAL NOT NULL DEFAULT 0")
	alterTableSafely("annual_balance", "balance_bank_amount", "REAL NOT NULL DEFAULT 0")
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
