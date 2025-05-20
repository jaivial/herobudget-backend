package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Bill struct {
	ID          int     `json:"id"`
	UserID      string  `json:"user_id"`
	Name        string  `json:"name"`
	Amount      float64 `json:"amount"`
	DueDate     string  `json:"due_date"`
	Paid        bool    `json:"paid"`
	Overdue     bool    `json:"overdue"`
	OverdueDays int     `json:"overdue_days"`
	Recurring   bool    `json:"recurring"`
	Category    string  `json:"category"`
	Icon        string  `json:"icon"`
	CreatedAt   string  `json:"created_at,omitempty"`
	UpdatedAt   string  `json:"updated_at,omitempty"`
}

type AddBillRequest struct {
	UserID    string  `json:"user_id"`
	Name      string  `json:"name"`
	Amount    float64 `json:"amount"`
	DueDate   string  `json:"due_date"`
	Paid      bool    `json:"paid"`
	Overdue   bool    `json:"overdue"`
	Recurring bool    `json:"recurring"`
	Category  string  `json:"category"`
	Icon      string  `json:"icon"`
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
	UserID string `json:"user_id"`
	BillID int    `json:"bill_id"`
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
	http.HandleFunc("/bills", corsMiddleware(handleFetchBills))
	http.HandleFunc("/bills/add", corsMiddleware(handleAddBill))
	http.HandleFunc("/bills/pay", corsMiddleware(handlePayBill))
	http.HandleFunc("/bills/update", corsMiddleware(handleUpdateBill))
	http.HandleFunc("/bills/delete", corsMiddleware(handleDeleteBill))

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
		UserID:      addRequest.UserID,
		Name:        addRequest.Name,
		Amount:      addRequest.Amount,
		DueDate:     addRequest.DueDate,
		Paid:        addRequest.Paid,
		Overdue:     isOverdue,
		OverdueDays: overdueDays,
		Recurring:   addRequest.Recurring,
		Category:    addRequest.Category,
		Icon:        addRequest.Icon,
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

	// Actualizar los balances por periodos si la factura ya está pagada
	if bill.Paid {
		if err := updateTimeBalances(bill.UserID, bill.Amount, bill.DueDate); err != nil {
			log.Printf("Error updating time balances: %v", err)
			// Don't fail the entire request, just log the error
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

	// Check if the bill exists
	bill, err := fetchBillByID(payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error fetching bill: %v", err)
		sendErrorResponse(w, "Error fetching bill", http.StatusInternalServerError)
		return
	}

	if bill == nil {
		sendErrorResponse(w, "Bill not found", http.StatusNotFound)
		return
	}

	// If already paid, return error
	if bill.Paid {
		sendErrorResponse(w, "Bill already paid", http.StatusBadRequest)
		return
	}

	// Mark the bill as paid
	err = markBillAsPaid(payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error marking bill as paid: %v", err)
		sendErrorResponse(w, "Error marking bill as paid", http.StatusInternalServerError)
		return
	}

	// Update bill object
	bill.Paid = true
	bill.Overdue = false
	bill.OverdueDays = 0

	// Actualizar los balances por periodos
	if err := updateTimeBalances(bill.UserID, bill.Amount, bill.DueDate); err != nil {
		log.Printf("Error updating time balances: %v", err)
		// Don't fail the entire request, just log the error
	}

	// Return success response
	sendSuccessResponse(w, "Bill marked as paid successfully", bill)
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
	var createdAt, updatedAt string

	err := db.QueryRow(`
		SELECT id, user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon, created_at, updated_at
		FROM bills
		WHERE id = ? AND user_id = ?
	`, billID, userID).Scan(
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

	if err == sql.ErrNoRows {
		return nil, nil // Bill not found
	} else if err != nil {
		return nil, err
	}

	// Update overdue status
	updateOverdueStatus(&bill)

	return &bill, nil
}

func addBill(bill Bill) (int, error) {
	res, err := db.Exec(`
		INSERT INTO bills (
			user_id, name, amount, due_date, paid, overdue, overdue_days, recurring, category, icon
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
		bill.ID,
		bill.UserID,
	)

	return err
}

func markBillAsPaid(billID int, userID string) error {
	_, err := db.Exec(`
		UPDATE bills
		SET paid = 1,
			overdue = 0,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`, billID, userID)

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
func updateTimeBalances(userID string, amount float64, dateStr string) error {
	// Parse la fecha de la factura
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return fmt.Errorf("error parsing date: %v", err)
	}

	// Actualizar balance diario
	if err := updateDailyBalance(userID, 0, 0, amount, date); err != nil {
		log.Printf("Error updating daily balance: %v", err)
	}

	// Actualizar balance semanal
	if err := updateWeeklyBalance(userID, 0, 0, amount, date); err != nil {
		log.Printf("Error updating weekly balance: %v", err)
	}

	// Actualizar balance mensual
	if err := updateMonthlyBalance(userID, 0, 0, amount, date); err != nil {
		log.Printf("Error updating monthly balance: %v", err)
	}

	// Actualizar balance trimestral
	if err := updateQuarterlyBalance(userID, 0, 0, amount, date); err != nil {
		log.Printf("Error updating quarterly balance: %v", err)
	}

	// Actualizar balance semestral
	if err := updateSemiannualBalance(userID, 0, 0, amount, date); err != nil {
		log.Printf("Error updating semiannual balance: %v", err)
	}

	// Actualizar balance anual
	if err := updateAnnualBalance(userID, 0, 0, amount, date); err != nil {
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
