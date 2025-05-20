package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Expense struct {
	ID            int     `json:"id"`
	UserID        string  `json:"user_id"`
	Amount        float64 `json:"amount"`
	Date          string  `json:"date"`
	Category      string  `json:"category"`
	PaymentMethod string  `json:"payment_method"` // "cash" o "bank"
	Description   string  `json:"description,omitempty"`
	CreatedAt     string  `json:"created_at,omitempty"`
	UpdatedAt     string  `json:"updated_at,omitempty"`
}

type AddExpenseRequest struct {
	UserID        string  `json:"user_id"`
	Amount        float64 `json:"amount"`
	Date          string  `json:"date"`
	Category      string  `json:"category"`
	PaymentMethod string  `json:"payment_method"`
	Description   string  `json:"description,omitempty"`
}

type UpdateExpenseRequest struct {
	UserID        string  `json:"user_id"`
	ExpenseID     int     `json:"expense_id"`
	Amount        float64 `json:"amount,omitempty"`
	Date          string  `json:"date,omitempty"`
	Category      string  `json:"category,omitempty"`
	PaymentMethod string  `json:"payment_method,omitempty"`
	Description   string  `json:"description,omitempty"`
}

type DeleteExpenseRequest struct {
	UserID    string `json:"user_id"`
	ExpenseID int    `json:"expense_id"`
}

type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
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

	log.Println("Database connection established successfully")
}

func createTablesIfNotExist() {
	// Create expenses table
	_, err := db.Exec(`
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
		log.Fatalf("Failed to create expenses table: %v", err)
	}

	// Create balances table if it doesn't exist
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS balances (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT UNIQUE NOT NULL,
			cash_balance REAL NOT NULL DEFAULT 0,
			bank_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create balances table: %v", err)
	}

	// Ensure cash_bank table exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS cash_bank (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			month TEXT NOT NULL,
			cash_amount REAL NOT NULL DEFAULT 0,
			cash_percent REAL NOT NULL DEFAULT 0,
			bank_amount REAL NOT NULL DEFAULT 0,
			bank_percent REAL NOT NULL DEFAULT 0,
			monthly_total REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create cash_bank table: %v", err)
	}

	// Ensure cash_bank_transactions table exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS cash_bank_transactions (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			transaction_type TEXT NOT NULL,
			amount REAL NOT NULL,
			date TEXT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create cash_bank_transactions table: %v", err)
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
			balance REAL NOT NULL DEFAULT 0,
			previous_balance REAL NOT NULL DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
}

func main() {
	// Set up CORS middleware and routes
	http.HandleFunc("/expenses", corsMiddleware(handleFetchExpenses))
	http.HandleFunc("/expenses/add", corsMiddleware(handleAddExpense))
	http.HandleFunc("/expenses/update", corsMiddleware(handleUpdateExpense))
	http.HandleFunc("/expenses/delete", corsMiddleware(handleDeleteExpense))

	port := 8094 // Puerto para el servicio de gastos
	log.Printf("Expense Management service started on :%d", port)
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

func handleFetchExpenses(w http.ResponseWriter, r *http.Request) {
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

	// Get expenses from database
	expenses, err := fetchExpenses(userID)
	if err != nil {
		log.Printf("Error fetching expenses: %v", err)
		sendErrorResponse(w, "Error fetching expenses", http.StatusInternalServerError)
		return
	}

	// Return expenses as JSON
	sendSuccessResponse(w, "Expenses fetched successfully", expenses)
}

func handleAddExpense(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var addRequest AddExpenseRequest
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

	if addRequest.Amount <= 0 {
		sendErrorResponse(w, "Amount must be greater than 0", http.StatusBadRequest)
		return
	}

	if addRequest.Date == "" {
		// Use current date if not provided
		addRequest.Date = time.Now().Format("2006-01-02")
	}

	if addRequest.Category == "" {
		sendErrorResponse(w, "Category is required", http.StatusBadRequest)
		return
	}

	if addRequest.PaymentMethod == "" || (addRequest.PaymentMethod != "cash" && addRequest.PaymentMethod != "bank") {
		sendErrorResponse(w, "Valid payment method (cash or bank) is required", http.StatusBadRequest)
		return
	}

	// Create an expense object
	expense := Expense{
		UserID:        addRequest.UserID,
		Amount:        addRequest.Amount,
		Date:          addRequest.Date,
		Category:      addRequest.Category,
		PaymentMethod: addRequest.PaymentMethod,
		Description:   addRequest.Description,
	}

	// Add the expense to the database
	expenseID, err := addExpense(expense)
	if err != nil {
		log.Printf("Error adding expense: %v", err)
		sendErrorResponse(w, "Error adding expense", http.StatusInternalServerError)
		return
	}

	// Set the ID of the newly added expense
	expense.ID = expenseID

	// Update cash or bank balance based on payment method (subtract the amount)
	if err := updateBalance(expense.UserID, -expense.Amount, expense.PaymentMethod); err != nil {
		log.Printf("Error updating balance: %v", err)
	}

	// Actualizar los balances por periodos
	if err := updateTimeBalances(expense.UserID, expense.Amount, expense.Date); err != nil {
		log.Printf("Error updating time balances: %v", err)
		// Don't fail the entire request, just log the error
	}

	// Return success response
	sendSuccessResponse(w, "Expense added successfully", expense)
}

func handleUpdateExpense(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var updateRequest UpdateExpenseRequest
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

	if updateRequest.ExpenseID <= 0 {
		sendErrorResponse(w, "Expense ID is required", http.StatusBadRequest)
		return
	}

	// Fetch the expense to update
	origExpense, err := fetchExpenseByID(updateRequest.ExpenseID, updateRequest.UserID)
	if err != nil {
		log.Printf("Error fetching expense: %v", err)
		sendErrorResponse(w, "Expense not found", http.StatusNotFound)
		return
	}

	// Calculate the difference in amount for balance update
	amountDifference := 0.0
	if updateRequest.Amount > 0 {
		amountDifference = origExpense.Amount - updateRequest.Amount
	}

	// Update expense object with new values
	expense := Expense{
		ID:            updateRequest.ExpenseID,
		UserID:        updateRequest.UserID,
		Amount:        updateRequest.Amount,
		Date:          updateRequest.Date,
		Category:      updateRequest.Category,
		PaymentMethod: updateRequest.PaymentMethod,
		Description:   updateRequest.Description,
	}

	// If fields are not provided, use original values
	if updateRequest.Amount <= 0 {
		expense.Amount = origExpense.Amount
	}

	if updateRequest.Date == "" {
		expense.Date = origExpense.Date
	}

	if updateRequest.Category == "" {
		expense.Category = origExpense.Category
	}

	if updateRequest.PaymentMethod == "" {
		expense.PaymentMethod = origExpense.PaymentMethod
	}

	if updateRequest.Description == "" {
		expense.Description = origExpense.Description
	}

	// Update expense in database
	err = updateExpense(expense)
	if err != nil {
		log.Printf("Error updating expense: %v", err)
		sendErrorResponse(w, "Error updating expense", http.StatusInternalServerError)
		return
	}

	// Update user's balance if amount changed
	if amountDifference != 0 {
		err = updateBalance(expense.UserID, amountDifference, expense.PaymentMethod)
		if err != nil {
			log.Printf("Error updating balance: %v", err)
			// Continue since the expense was already updated
		}
	}

	// Fetch the updated expense
	updatedExpense, err := fetchExpenseByID(expense.ID, expense.UserID)
	if err != nil {
		log.Printf("Error fetching updated expense: %v", err)
		// Return the updated expense without timestamps
		sendSuccessResponse(w, "Expense updated successfully", expense)
		return
	}

	// Return the updated expense
	sendSuccessResponse(w, "Expense updated successfully", updatedExpense)
}

func handleDeleteExpense(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var deleteRequest DeleteExpenseRequest
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

	if deleteRequest.ExpenseID <= 0 {
		sendErrorResponse(w, "Expense ID is required", http.StatusBadRequest)
		return
	}

	// Fetch the expense to delete
	expense, err := fetchExpenseByID(deleteRequest.ExpenseID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error fetching expense: %v", err)
		sendErrorResponse(w, "Expense not found", http.StatusNotFound)
		return
	}

	// Delete expense from database
	err = deleteExpense(deleteRequest.ExpenseID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error deleting expense: %v", err)
		sendErrorResponse(w, "Error deleting expense", http.StatusInternalServerError)
		return
	}

	// Update user's balance (add the amount back)
	err = updateBalance(deleteRequest.UserID, expense.Amount, expense.PaymentMethod)
	if err != nil {
		log.Printf("Error updating balance: %v", err)
		// Continue since the expense was already deleted
	}

	// Return success
	sendSuccessResponse(w, "Expense deleted successfully", nil)
}

func fetchExpenses(userID string) ([]Expense, error) {
	// SQL query to fetch all expenses for a user, ordered by most recent
	query := `
		SELECT id, user_id, amount, date, category, payment_method, description, created_at, updated_at
		FROM expenses
		WHERE user_id = ?
		ORDER BY date DESC, id DESC
	`

	rows, err := db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Parse rows into expense objects
	expenses := []Expense{}
	for rows.Next() {
		var expense Expense
		err := rows.Scan(
			&expense.ID,
			&expense.UserID,
			&expense.Amount,
			&expense.Date,
			&expense.Category,
			&expense.PaymentMethod,
			&expense.Description,
			&expense.CreatedAt,
			&expense.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		expenses = append(expenses, expense)
	}

	return expenses, nil
}

func fetchExpenseByID(expenseID int, userID string) (*Expense, error) {
	// SQL query to fetch a specific expense by ID and user ID
	query := `
		SELECT id, user_id, amount, date, category, payment_method, description, created_at, updated_at
		FROM expenses
		WHERE id = ? AND user_id = ?
	`

	row := db.QueryRow(query, expenseID, userID)

	var expense Expense
	err := row.Scan(
		&expense.ID,
		&expense.UserID,
		&expense.Amount,
		&expense.Date,
		&expense.Category,
		&expense.PaymentMethod,
		&expense.Description,
		&expense.CreatedAt,
		&expense.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &expense, nil
}

func addExpense(expense Expense) (int, error) {
	// SQL query to insert a new expense
	query := `
		INSERT INTO expenses (user_id, amount, date, category, payment_method, description)
		VALUES (?, ?, ?, ?, ?, ?)
	`

	result, err := db.Exec(
		query,
		expense.UserID,
		expense.Amount,
		expense.Date,
		expense.Category,
		expense.PaymentMethod,
		expense.Description,
	)
	if err != nil {
		return 0, err
	}

	// Get the ID of the inserted expense
	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return int(id), nil
}

func updateExpense(expense Expense) error {
	// SQL query to update an existing expense
	query := `
		UPDATE expenses
		SET amount = ?, date = ?, category = ?, payment_method = ?, description = ?, updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`

	_, err := db.Exec(
		query,
		expense.Amount,
		expense.Date,
		expense.Category,
		expense.PaymentMethod,
		expense.Description,
		expense.ID,
		expense.UserID,
	)
	if err != nil {
		return err
	}

	return nil
}

func deleteExpense(expenseID int, userID string) error {
	// SQL query to delete an expense
	query := `
		DELETE FROM expenses
		WHERE id = ? AND user_id = ?
	`

	_, err := db.Exec(query, expenseID, userID)
	if err != nil {
		return err
	}

	return nil
}

func updateBalance(userID string, amount float64, paymentMethod string) error {
	log.Printf("updateBalance called with userID: %s, amount: %.2f, paymentMethod: %s", userID, amount, paymentMethod)

	// SQL query to check if user exists in the balances table
	checkQuery := `
		SELECT COUNT(*)
		FROM balances
		WHERE user_id = ?
	`

	var count int
	err := db.QueryRow(checkQuery, userID).Scan(&count)
	if err != nil {
		log.Printf("Error checking balances table: %v", err)
		return err
	}

	log.Printf("Found %d records in balances table for user %s", count, userID)
	var query string

	// If user doesn't exist in balances table, insert a new record
	if count == 0 {
		query = `
			INSERT INTO balances (user_id, cash_balance, bank_balance)
			VALUES (?, ?, ?)
		`
		cashAmount := 0.0
		bankAmount := 0.0

		if paymentMethod == "cash" {
			cashAmount = amount
		} else {
			bankAmount = amount
		}

		log.Printf("Inserting new balance record with cash: %.2f, bank: %.2f", cashAmount, bankAmount)
		_, err = db.Exec(query, userID, cashAmount, bankAmount)
	} else {
		// Update existing balance
		if paymentMethod == "cash" {
			query = `
				UPDATE balances
				SET cash_balance = cash_balance + ?
				WHERE user_id = ?
			`
		} else {
			query = `
				UPDATE balances
				SET bank_balance = bank_balance + ?
				WHERE user_id = ?
			`
		}

		log.Printf("Updating existing balance with amount: %.2f for method: %s", amount, paymentMethod)
		_, err = db.Exec(query, amount, userID)
	}

	if err != nil {
		log.Printf("Error updating balances table: %v", err)
		return err
	} else {
		log.Printf("Successfully updated balances table")
	}

	// Get current month in format YYYY-MM
	currentMonth := time.Now().Format("2006-01")
	log.Printf("Processing cash_bank for month: %s", currentMonth)

	// Fetch current cash-bank distribution
	var distribution struct {
		CashAmount   float64
		BankAmount   float64
		MonthlyTotal float64
		Exists       bool
	}

	// Check if a record exists for the current month
	cashBankCheckQuery := `
		SELECT 1
		FROM cash_bank
		WHERE user_id = ? AND month = ?
	`
	var exists bool
	err = db.QueryRow(cashBankCheckQuery, userID, currentMonth).Scan(&exists)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("Error checking cash_bank: %v", err)
		return err
	}

	distribution.Exists = err != sql.ErrNoRows
	log.Printf("Record exists in cash_bank for user %s and month %s: %v", userID, currentMonth, distribution.Exists)

	if distribution.Exists {
		// Get current values
		getQuery := `
			SELECT cash_amount, bank_amount, monthly_total
			FROM cash_bank
			WHERE user_id = ? AND month = ?
		`
		err := db.QueryRow(getQuery, userID, currentMonth).Scan(
			&distribution.CashAmount,
			&distribution.BankAmount,
			&distribution.MonthlyTotal,
		)
		if err != nil {
			log.Printf("Error fetching cash_bank data: %v", err)
			return err
		}

		log.Printf("Current cash_bank values - cash: %.2f, bank: %.2f, total: %.2f",
			distribution.CashAmount, distribution.BankAmount, distribution.MonthlyTotal)

		// Update the appropriate amount based on payment method
		if paymentMethod == "cash" {
			distribution.CashAmount += amount
		} else if paymentMethod == "bank" {
			distribution.BankAmount += amount
		}

		distribution.MonthlyTotal = distribution.CashAmount + distribution.BankAmount

		log.Printf("Updated cash_bank values - cash: %.2f, bank: %.2f, total: %.2f",
			distribution.CashAmount, distribution.BankAmount, distribution.MonthlyTotal)

		// Calculate percentages
		var cashPercent, bankPercent float64
		if distribution.MonthlyTotal > 0 {
			cashPercent = (distribution.CashAmount / distribution.MonthlyTotal) * 100
			bankPercent = (distribution.BankAmount / distribution.MonthlyTotal) * 100
		}

		log.Printf("Calculated cash_bank percentages - cash: %.2f%%, bank: %.2f%%",
			cashPercent, bankPercent)

		// Update the record
		updateQuery := `
			UPDATE cash_bank
			SET cash_amount = ?, cash_percent = ?, bank_amount = ?, bank_percent = ?, monthly_total = ?, updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND month = ?
		`
		_, err = db.Exec(
			updateQuery,
			distribution.CashAmount,
			cashPercent,
			distribution.BankAmount,
			bankPercent,
			distribution.MonthlyTotal,
			userID,
			currentMonth,
		)
		if err != nil {
			log.Printf("Error updating cash_bank: %v", err)
			return err
		}
		log.Printf("Successfully updated cash_bank record")
	} else {
		// Create a new record with initial values
		if paymentMethod == "cash" {
			distribution.CashAmount = amount
			distribution.BankAmount = 0
		} else if paymentMethod == "bank" {
			distribution.CashAmount = 0
			distribution.BankAmount = amount
		}

		distribution.MonthlyTotal = distribution.CashAmount + distribution.BankAmount

		log.Printf("Creating new cash_bank record - cash: %.2f, bank: %.2f, total: %.2f",
			distribution.CashAmount, distribution.BankAmount, distribution.MonthlyTotal)

		// Calculate percentages
		var cashPercent, bankPercent float64
		if distribution.MonthlyTotal > 0 {
			cashPercent = (distribution.CashAmount / distribution.MonthlyTotal) * 100
			bankPercent = (distribution.BankAmount / distribution.MonthlyTotal) * 100
		}

		log.Printf("Calculated cash_bank percentages for new record - cash: %.2f%%, bank: %.2f%%",
			cashPercent, bankPercent)

		// Insert the new record
		insertQuery := `
			INSERT INTO cash_bank (user_id, month, cash_amount, cash_percent, bank_amount, bank_percent, monthly_total)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`
		_, err = db.Exec(
			insertQuery,
			userID,
			currentMonth,
			distribution.CashAmount,
			cashPercent,
			distribution.BankAmount,
			bankPercent,
			distribution.MonthlyTotal,
		)
		if err != nil {
			log.Printf("Error inserting new cash_bank record: %v", err)
			return err
		}
		log.Printf("Successfully inserted new cash_bank record")
	}

	// Add transaction record for the expense (negative amount)
	// Note: For expenses, we record a negative transaction
	transactionQuery := `
		INSERT INTO cash_bank_transactions (user_id, transaction_type, amount, date)
		VALUES (?, ?, ?, ?)
	`
	transactionType := "expense_" + paymentMethod
	transactionAmount := -math.Abs(amount) // Ensure amount is negative for expenses

	log.Printf("Recording transaction - type: %s, amount: %.2f", transactionType, transactionAmount)

	_, err = db.Exec(
		transactionQuery,
		userID,
		transactionType,
		transactionAmount,
		time.Now().Format("2006-01-02"),
	)
	if err != nil {
		log.Printf("Error recording cash_bank_transaction: %v", err)
		return err
	}
	log.Printf("Successfully recorded cash_bank_transaction")

	log.Printf("updateBalance completed successfully")
	return nil
}

func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	response := ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	response := ApiResponse{
		Success: false,
		Message: message,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

// Función para actualizar los balances por periodos al añadir un gasto
func updateTimeBalances(userID string, amount float64, dateStr string) error {
	// Parse la fecha del gasto
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return fmt.Errorf("error parsing date: %v", err)
	}

	// Actualizar balance diario
	if err := updateDailyBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating daily balance: %v", err)
	}

	// Actualizar balance semanal
	if err := updateWeeklyBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating weekly balance: %v", err)
	}

	// Actualizar balance mensual
	if err := updateMonthlyBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating monthly balance: %v", err)
	}

	// Actualizar balance trimestral
	if err := updateQuarterlyBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating quarterly balance: %v", err)
	}

	// Actualizar balance semestral
	if err := updateSemiannualBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating semiannual balance: %v", err)
	}

	// Actualizar balance anual
	if err := updateAnnualBalance(userID, 0, amount, 0, date); err != nil {
		log.Printf("Error updating annual balance: %v", err)
	}

	return nil
}

func updateDailyBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
	dateStr := date.Format("2006-01-02")

	// Obtener el balance del día anterior para calcular el balance previo
	prevDate := date.AddDate(0, 0, -1)
	prevDateStr := prevDate.Format("2006-01-02")

	var previousBalance float64

	// Buscar el balance del día anterior
	err := db.QueryRow(`
		SELECT balance FROM daily_balance 
		WHERE user_id = ? AND date = ?
	`, userID, prevDateStr).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del día anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta fecha
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM daily_balance
		WHERE user_id = ? AND date = ?
	`, userID, dateStr).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO daily_balance (user_id, date, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`, userID, dateStr, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE daily_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND date = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, dateStr)
	}

	return err
}

func updateWeeklyBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
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

	// Buscar el balance de la semana anterior
	err := db.QueryRow(`
		SELECT balance FROM weekly_balance 
		WHERE user_id = ? AND year_week = ?
	`, userID, prevYearWeek).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro de la semana anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para esta semana
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM weekly_balance
		WHERE user_id = ? AND year_week = ?
	`, userID, yearWeek).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO weekly_balance (user_id, year_week, start_date, end_date, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearWeek, startDateStr, endDateStr, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE weekly_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_week = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, yearWeek)
	}

	return err
}

func updateMonthlyBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
	// Calcular el año y mes
	yearMonth := date.Format("2006-01")

	// Calcular el mes anterior
	prevMonth := date.AddDate(0, -1, 0)
	prevYearMonth := prevMonth.Format("2006-01")

	var previousBalance float64

	// Buscar el balance del mes anterior
	err := db.QueryRow(`
		SELECT balance FROM monthly_balance 
		WHERE user_id = ? AND year_month = ?
	`, userID, prevYearMonth).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del mes anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este mes
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM monthly_balance
		WHERE user_id = ? AND year_month = ?
	`, userID, yearMonth).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO monthly_balance (user_id, year_month, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`, userID, yearMonth, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE monthly_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_month = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, yearMonth)
	}

	return err
}

func updateQuarterlyBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
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

	// Buscar el balance del trimestre anterior
	err := db.QueryRow(`
		SELECT balance FROM quarterly_balance 
		WHERE user_id = ? AND year_quarter = ?
	`, userID, prevYearQuarter).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del trimestre anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este trimestre
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM quarterly_balance
		WHERE user_id = ? AND year_quarter = ?
	`, userID, yearQuarter).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO quarterly_balance (user_id, year_quarter, start_date, end_date, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearQuarter, startDateStr, endDateStr, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE quarterly_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_quarter = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, yearQuarter)
	}

	return err
}

func updateSemiannualBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
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

	// Buscar el balance del semestre anterior
	err := db.QueryRow(`
		SELECT balance FROM semiannual_balance 
		WHERE user_id = ? AND year_half = ?
	`, userID, prevYearHalf).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del semestre anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este semestre
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM semiannual_balance
		WHERE user_id = ? AND year_half = ?
	`, userID, yearHalf).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO semiannual_balance (user_id, year_half, start_date, end_date, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, userID, yearHalf, startDateStr, endDateStr, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE semiannual_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year_half = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, yearHalf)
	}

	return err
}

func updateAnnualBalance(userID string, incomeAmount, expenseAmount, billsAmount float64, date time.Time) error {
	// Calcular el año
	year := strconv.Itoa(date.Year())

	// Calcular el año anterior
	prevYear := strconv.Itoa(date.Year() - 1)

	var previousBalance float64

	// Buscar el balance del año anterior
	err := db.QueryRow(`
		SELECT balance FROM annual_balance 
		WHERE user_id = ? AND year = ?
	`, userID, prevYear).Scan(&previousBalance)

	if err != nil && err != sql.ErrNoRows {
		return err
	}
	// Si no existe registro del año anterior, el balance previo es 0

	// Calcular el balance actual
	balance := previousBalance + incomeAmount - expenseAmount - billsAmount

	// Verificar si ya existe un registro para este año
	var exists bool
	err = db.QueryRow(`
		SELECT 1 FROM annual_balance
		WHERE user_id = ? AND year = ?
	`, userID, year).Scan(&exists)

	if err != nil && err != sql.ErrNoRows {
		return err
	}

	if err == sql.ErrNoRows {
		// No existe registro, insertar uno nuevo
		_, err = db.Exec(`
			INSERT INTO annual_balance (user_id, year, income_amount, expense_amount, bills_amount, balance, previous_balance)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`, userID, year, incomeAmount, expenseAmount, billsAmount, balance, previousBalance)
	} else {
		// Actualizar registro existente
		_, err = db.Exec(`
			UPDATE annual_balance
			SET income_amount = income_amount + ?,
				expense_amount = expense_amount + ?,
				bills_amount = bills_amount + ?,
				balance = previous_balance + income_amount - expense_amount - bills_amount,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND year = ?
		`, incomeAmount, expenseAmount, billsAmount, userID, year)
	}

	return err
}
