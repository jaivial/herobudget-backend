package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Income struct {
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

type AddIncomeRequest struct {
	UserID        string  `json:"user_id"`
	Amount        float64 `json:"amount"`
	Date          string  `json:"date"`
	Category      string  `json:"category"`
	PaymentMethod string  `json:"payment_method"`
	Description   string  `json:"description,omitempty"`
}

type UpdateIncomeRequest struct {
	UserID        string  `json:"user_id"`
	IncomeID      int     `json:"income_id"`
	Amount        float64 `json:"amount,omitempty"`
	Date          string  `json:"date,omitempty"`
	Category      string  `json:"category,omitempty"`
	PaymentMethod string  `json:"payment_method,omitempty"`
	Description   string  `json:"description,omitempty"`
}

type DeleteIncomeRequest struct {
	UserID   string `json:"user_id"`
	IncomeID int    `json:"income_id"`
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
	// Create incomes table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS incomes (
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
		log.Fatalf("Failed to create incomes table: %v", err)
	}
}

func main() {
	// Set up CORS middleware and routes
	http.HandleFunc("/incomes", corsMiddleware(handleFetchIncomes))
	http.HandleFunc("/incomes/add", corsMiddleware(handleAddIncome))
	http.HandleFunc("/incomes/update", corsMiddleware(handleUpdateIncome))
	http.HandleFunc("/incomes/delete", corsMiddleware(handleDeleteIncome))

	port := 8093 // Nuevo puerto para el servicio de ingresos
	log.Printf("Income Management service started on :%d", port)
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

func handleFetchIncomes(w http.ResponseWriter, r *http.Request) {
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

	// Get incomes from database
	incomes, err := fetchIncomes(userID)
	if err != nil {
		log.Printf("Error fetching incomes: %v", err)
		sendErrorResponse(w, "Error fetching incomes", http.StatusInternalServerError)
		return
	}

	// Return incomes as JSON
	sendSuccessResponse(w, "Incomes fetched successfully", incomes)
}

func handleAddIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var addRequest AddIncomeRequest
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

	// Create an income object
	income := Income{
		UserID:        addRequest.UserID,
		Amount:        addRequest.Amount,
		Date:          addRequest.Date,
		Category:      addRequest.Category,
		PaymentMethod: addRequest.PaymentMethod,
		Description:   addRequest.Description,
	}

	// Add the income to the database
	incomeID, err := addIncome(income)
	if err != nil {
		log.Printf("Error adding income: %v", err)
		sendErrorResponse(w, "Error adding income", http.StatusInternalServerError)
		return
	}

	// Set the ID of the newly added income
	income.ID = incomeID

	// Update cash or bank balance based on payment method
	if err := updateBalance(income.UserID, income.Amount, income.PaymentMethod); err != nil {
		log.Printf("Error updating balance: %v", err)
		// Don't fail the entire request, just log the error
	}

	// Return success response
	sendSuccessResponse(w, "Income added successfully", income)
}

func handleUpdateIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var updateRequest UpdateIncomeRequest
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

	if updateRequest.IncomeID <= 0 {
		sendErrorResponse(w, "Valid income ID is required", http.StatusBadRequest)
		return
	}

	// Check if the income exists
	oldIncome, err := fetchIncomeByID(updateRequest.IncomeID, updateRequest.UserID)
	if err != nil {
		log.Printf("Error fetching income: %v", err)
		sendErrorResponse(w, "Error fetching income", http.StatusInternalServerError)
		return
	}

	if oldIncome == nil {
		sendErrorResponse(w, "Income not found", http.StatusNotFound)
		return
	}

	// Keep track of the old payment method and amount for balance adjustment
	oldAmount := oldIncome.Amount
	oldPaymentMethod := oldIncome.PaymentMethod

	// Update the income with the provided values
	if updateRequest.Amount > 0 {
		oldIncome.Amount = updateRequest.Amount
	}

	if updateRequest.Date != "" {
		oldIncome.Date = updateRequest.Date
	}

	if updateRequest.Category != "" {
		oldIncome.Category = updateRequest.Category
	}

	if updateRequest.PaymentMethod != "" {
		if updateRequest.PaymentMethod != "cash" && updateRequest.PaymentMethod != "bank" {
			sendErrorResponse(w, "Valid payment method (cash or bank) is required", http.StatusBadRequest)
			return
		}
		oldIncome.PaymentMethod = updateRequest.PaymentMethod
	}

	if updateRequest.Description != "" {
		oldIncome.Description = updateRequest.Description
	}

	// Update the income in the database
	err = updateIncome(*oldIncome)
	if err != nil {
		log.Printf("Error updating income: %v", err)
		sendErrorResponse(w, "Error updating income", http.StatusInternalServerError)
		return
	}

	// Adjust balances if amount or payment method changed
	if oldAmount != oldIncome.Amount || oldPaymentMethod != oldIncome.PaymentMethod {
		// Remove the old amount from the old payment method
		if err := updateBalance(oldIncome.UserID, -oldAmount, oldPaymentMethod); err != nil {
			log.Printf("Error updating old balance: %v", err)
		}

		// Add the new amount to the new payment method
		if err := updateBalance(oldIncome.UserID, oldIncome.Amount, oldIncome.PaymentMethod); err != nil {
			log.Printf("Error updating new balance: %v", err)
		}
	}

	// Return success response
	sendSuccessResponse(w, "Income updated successfully", oldIncome)
}

func handleDeleteIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var deleteRequest DeleteIncomeRequest
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

	if deleteRequest.IncomeID <= 0 {
		sendErrorResponse(w, "Valid income ID is required", http.StatusBadRequest)
		return
	}

	// Check if the income exists and get its details for balance adjustment
	income, err := fetchIncomeByID(deleteRequest.IncomeID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error fetching income: %v", err)
		sendErrorResponse(w, "Error fetching income", http.StatusInternalServerError)
		return
	}

	if income == nil {
		sendErrorResponse(w, "Income not found", http.StatusNotFound)
		return
	}

	// Delete the income from the database
	err = deleteIncome(deleteRequest.IncomeID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error deleting income: %v", err)
		sendErrorResponse(w, "Error deleting income", http.StatusInternalServerError)
		return
	}

	// Adjust the balance (subtract the amount)
	if err := updateBalance(income.UserID, -income.Amount, income.PaymentMethod); err != nil {
		log.Printf("Error updating balance: %v", err)
		// Don't fail the entire request, just log the error
	}

	// Return success response
	sendSuccessResponse(w, "Income deleted successfully", nil)
}

func fetchIncomes(userID string) ([]Income, error) {
	// Query to get all incomes for the given user
	query := `
		SELECT id, user_id, amount, date, category, payment_method, description, created_at, updated_at
		FROM incomes
		WHERE user_id = ?
		ORDER BY date DESC
	`

	rows, err := db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var incomes []Income

	for rows.Next() {
		var income Income
		if err := rows.Scan(
			&income.ID,
			&income.UserID,
			&income.Amount,
			&income.Date,
			&income.Category,
			&income.PaymentMethod,
			&income.Description,
			&income.CreatedAt,
			&income.UpdatedAt,
		); err != nil {
			return nil, err
		}

		incomes = append(incomes, income)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return incomes, nil
}

func fetchIncomeByID(incomeID int, userID string) (*Income, error) {
	// Query to get a specific income
	query := `
		SELECT id, user_id, amount, date, category, payment_method, description, created_at, updated_at
		FROM incomes
		WHERE id = ? AND user_id = ?
	`

	var income Income
	err := db.QueryRow(query, incomeID, userID).Scan(
		&income.ID,
		&income.UserID,
		&income.Amount,
		&income.Date,
		&income.Category,
		&income.PaymentMethod,
		&income.Description,
		&income.CreatedAt,
		&income.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil // No income found
	} else if err != nil {
		return nil, err
	}

	return &income, nil
}

func addIncome(income Income) (int, error) {
	// Insert income into the database
	query := `
		INSERT INTO incomes (
			user_id, amount, date, category, payment_method, description
		) VALUES (?, ?, ?, ?, ?, ?)
	`

	result, err := db.Exec(
		query,
		income.UserID,
		income.Amount,
		income.Date,
		income.Category,
		income.PaymentMethod,
		income.Description,
	)

	if err != nil {
		return 0, err
	}

	// Get the last inserted ID
	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return int(id), nil
}

func updateIncome(income Income) error {
	// Update income in the database
	query := `
		UPDATE incomes
		SET amount = ?, date = ?, category = ?, payment_method = ?, description = ?, updated_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ?
	`

	_, err := db.Exec(
		query,
		income.Amount,
		income.Date,
		income.Category,
		income.PaymentMethod,
		income.Description,
		income.ID,
		income.UserID,
	)

	return err
}

func deleteIncome(incomeID int, userID string) error {
	// Delete income from the database
	query := `
		DELETE FROM incomes
		WHERE id = ? AND user_id = ?
	`

	_, err := db.Exec(query, incomeID, userID)
	return err
}

func updateBalance(userID string, amount float64, paymentMethod string) error {
	// Get current month in format YYYY-MM
	currentMonth := time.Now().Format("2006-01")

	// Fetch current cash-bank distribution
	var distribution struct {
		CashAmount   float64
		BankAmount   float64
		MonthlyTotal float64
		Exists       bool
	}

	// Check if a record exists for the current month
	checkQuery := `
		SELECT 1
		FROM cash_bank
		WHERE user_id = ? AND month = ?
	`
	var exists bool
	err := db.QueryRow(checkQuery, userID, currentMonth).Scan(&exists)
	if err != nil && err != sql.ErrNoRows {
		return err
	}

	distribution.Exists = err != sql.ErrNoRows

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
			return err
		}

		// Update the appropriate amount based on payment method
		if paymentMethod == "cash" {
			distribution.CashAmount += amount
		} else if paymentMethod == "bank" {
			distribution.BankAmount += amount
		}

		distribution.MonthlyTotal = distribution.CashAmount + distribution.BankAmount

		// Calculate percentages
		var cashPercent, bankPercent float64
		if distribution.MonthlyTotal > 0 {
			cashPercent = (distribution.CashAmount / distribution.MonthlyTotal) * 100
			bankPercent = (distribution.BankAmount / distribution.MonthlyTotal) * 100
		}

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
			return err
		}
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

		// Calculate percentages
		var cashPercent, bankPercent float64
		if distribution.MonthlyTotal > 0 {
			cashPercent = (distribution.CashAmount / distribution.MonthlyTotal) * 100
			bankPercent = (distribution.BankAmount / distribution.MonthlyTotal) * 100
		}

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
			return err
		}
	}

	// Add transaction record if it's an addition (positive amount)
	if amount > 0 {
		// Add a transaction record
		transactionQuery := `
			INSERT INTO cash_bank_transactions (user_id, transaction_type, amount, date)
			VALUES (?, ?, ?, ?)
		`
		transactionType := "income_" + paymentMethod
		_, err = db.Exec(
			transactionQuery,
			userID,
			transactionType,
			amount,
			time.Now().Format("2006-01-02"),
		)
		if err != nil {
			return err
		}
	}

	return nil
}

func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	response := ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
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
