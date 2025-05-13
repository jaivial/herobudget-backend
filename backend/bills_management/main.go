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
		sendErrorResponse(w, "Bill name is required", http.StatusBadRequest)
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
		addRequest.Icon = "📋" // Default icon if not provided
	}

	// Create a bill object
	bill := Bill{
		UserID:    addRequest.UserID,
		Name:      addRequest.Name,
		Amount:    addRequest.Amount,
		DueDate:   addRequest.DueDate,
		Paid:      addRequest.Paid,
		Overdue:   addRequest.Overdue,
		Recurring: addRequest.Recurring,
		Category:  addRequest.Category,
		Icon:      addRequest.Icon,
	}

	// Calculate overdue status and days
	updateOverdueStatus(&bill)

	// Add the bill to the database
	billID, err := addBill(bill)
	if err != nil {
		log.Printf("Error adding bill: %v", err)
		sendErrorResponse(w, "Error adding bill", http.StatusInternalServerError)
		return
	}

	// Set the ID of the newly added bill
	bill.ID = billID

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

	// Mark the bill as paid
	err = markBillAsPaid(payRequest.BillID, payRequest.UserID)
	if err != nil {
		log.Printf("Error marking bill as paid: %v", err)
		sendErrorResponse(w, "Error marking bill as paid", http.StatusInternalServerError)
		return
	}

	// If the bill is recurring, create a new bill for next period
	if bill.Recurring {
		// Create a new bill with the next due date
		nextDueDate, err := calculateNextDueDate(bill.DueDate)
		if err != nil {
			log.Printf("Error calculating next due date: %v", err)
			// Don't fail the entire request just because we couldn't create the next bill
		} else {
			newBill := *bill // Create a copy of the existing bill
			newBill.ID = 0   // Reset ID so a new one is generated
			newBill.DueDate = nextDueDate
			newBill.Paid = false
			newBill.Overdue = false
			newBill.OverdueDays = 0

			// Add the new bill to the database
			_, err = addBill(newBill)
			if err != nil {
				log.Printf("Error creating next recurring bill: %v", err)
				// Continue despite the error
			}
		}
	}

	// Return success response
	sendSuccessResponse(w, "Bill paid successfully", nil)
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
