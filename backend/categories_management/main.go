package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	_ "github.com/mattn/go-sqlite3"
)

// Definición de estructuras de datos
type Category struct {
	ID        int    `json:"id"`
	UserID    string `json:"user_id"`
	Name      string `json:"name"`
	Type      string `json:"type"` // "income" o "expense"
	Emoji     string `json:"emoji"`
	CreatedAt string `json:"created_at,omitempty"`
	UpdatedAt string `json:"updated_at,omitempty"`
}

type AddCategoryRequest struct {
	UserID string `json:"user_id"`
	Name   string `json:"name"`
	Type   string `json:"type"` // "income" o "expense"
	Emoji  string `json:"emoji"`
}

type UpdateCategoryRequest struct {
	UserID     string `json:"user_id"`
	CategoryID int    `json:"category_id"`
	Name       string `json:"name,omitempty"`
	Type       string `json:"type,omitempty"` // "income" o "expense"
	Emoji      string `json:"emoji,omitempty"`
}

type DeleteCategoryRequest struct {
	UserID     string `json:"user_id"`
	CategoryID int    `json:"category_id"`
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
	// Create categories table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS categories (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL,
			name TEXT NOT NULL,
			type TEXT NOT NULL,
			emoji TEXT NOT NULL DEFAULT '📊',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatalf("Failed to create categories table: %v", err)
	}
}

func main() {
	// Set up CORS middleware and routes
	http.HandleFunc("/categories", corsMiddleware(handleFetchCategories))
	http.HandleFunc("/categories/add", corsMiddleware(handleAddCategory))
	http.HandleFunc("/categories/update", corsMiddleware(handleUpdateCategory))
	http.HandleFunc("/categories/delete", corsMiddleware(handleDeleteCategory))

	port := 8095 // Puerto para el servicio de categorías
	log.Printf("Categories Management service started on :%d", port)
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

func handleFetchCategories(w http.ResponseWriter, r *http.Request) {
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

	// Get optional type filter
	categoryType := r.URL.Query().Get("type") // "income", "expense", or empty for all

	// Get categories from database
	categories, err := fetchCategories(userID, categoryType)
	if err != nil {
		log.Printf("Error fetching categories: %v", err)
		sendErrorResponse(w, "Error fetching categories", http.StatusInternalServerError)
		return
	}

	// Return categories as JSON
	sendSuccessResponse(w, "Categories fetched successfully", categories)
}

func handleAddCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var addRequest AddCategoryRequest
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
		sendErrorResponse(w, "Category name is required", http.StatusBadRequest)
		return
	}

	if addRequest.Type != "income" && addRequest.Type != "expense" {
		sendErrorResponse(w, "Category type must be 'income' or 'expense'", http.StatusBadRequest)
		return
	}

	// Set default emoji if not provided
	if addRequest.Emoji == "" {
		if addRequest.Type == "income" {
			addRequest.Emoji = "💰"
		} else {
			addRequest.Emoji = "🛒"
		}
	}

	// Create category object
	category := Category{
		UserID: addRequest.UserID,
		Name:   addRequest.Name,
		Type:   addRequest.Type,
		Emoji:  addRequest.Emoji,
	}

	// Add category to database
	categoryID, err := addCategory(category)
	if err != nil {
		log.Printf("Error adding category: %v", err)
		sendErrorResponse(w, "Error adding category", http.StatusInternalServerError)
		return
	}

	// Set ID in response
	category.ID = categoryID

	// Return success response
	sendSuccessResponse(w, "Category added successfully", category)
}

func handleUpdateCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var updateRequest UpdateCategoryRequest
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

	if updateRequest.CategoryID <= 0 {
		sendErrorResponse(w, "Valid category ID is required", http.StatusBadRequest)
		return
	}

	if updateRequest.Type != "" && updateRequest.Type != "income" && updateRequest.Type != "expense" {
		sendErrorResponse(w, "Category type must be 'income' or 'expense'", http.StatusBadRequest)
		return
	}

	// Fetch existing category
	existingCategory, err := fetchCategoryByID(updateRequest.CategoryID, updateRequest.UserID)
	if err != nil {
		if err == sql.ErrNoRows {
			sendErrorResponse(w, "Category not found", http.StatusNotFound)
		} else {
			log.Printf("Error fetching category: %v", err)
			sendErrorResponse(w, "Error fetching category", http.StatusInternalServerError)
		}
		return
	}

	// Update fields if provided
	if updateRequest.Name != "" {
		existingCategory.Name = updateRequest.Name
	}
	if updateRequest.Type != "" {
		existingCategory.Type = updateRequest.Type
	}
	if updateRequest.Emoji != "" {
		existingCategory.Emoji = updateRequest.Emoji
	}

	// Update category in database
	err = updateCategory(*existingCategory)
	if err != nil {
		log.Printf("Error updating category: %v", err)
		sendErrorResponse(w, "Error updating category", http.StatusInternalServerError)
		return
	}

	// Return success response
	sendSuccessResponse(w, "Category updated successfully", existingCategory)
}

func handleDeleteCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var deleteRequest DeleteCategoryRequest
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

	if deleteRequest.CategoryID <= 0 {
		sendErrorResponse(w, "Valid category ID is required", http.StatusBadRequest)
		return
	}

	// Delete category from database
	err = deleteCategory(deleteRequest.CategoryID, deleteRequest.UserID)
	if err != nil {
		log.Printf("Error deleting category: %v", err)
		sendErrorResponse(w, "Error deleting category", http.StatusInternalServerError)
		return
	}

	// Return success response
	sendSuccessResponse(w, "Category deleted successfully", nil)
}

// Database functions
func fetchCategories(userID, categoryType string) ([]Category, error) {
	var query string
	var args []interface{}

	if categoryType == "" {
		// Fetch all categories for the user
		query = `SELECT id, user_id, name, type, emoji, created_at, updated_at FROM categories WHERE user_id = ? ORDER BY name ASC`
		args = []interface{}{userID}
	} else {
		// Fetch categories of specific type
		query = `SELECT id, user_id, name, type, emoji, created_at, updated_at FROM categories WHERE user_id = ? AND type = ? ORDER BY name ASC`
		args = []interface{}{userID, categoryType}
	}

	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []Category
	for rows.Next() {
		var category Category
		err := rows.Scan(
			&category.ID,
			&category.UserID,
			&category.Name,
			&category.Type,
			&category.Emoji,
			&category.CreatedAt,
			&category.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
	}

	return categories, nil
}

func fetchCategoryByID(categoryID int, userID string) (*Category, error) {
	var category Category
	err := db.QueryRow(
		`SELECT id, user_id, name, type, emoji, created_at, updated_at FROM categories WHERE id = ? AND user_id = ?`,
		categoryID, userID,
	).Scan(
		&category.ID,
		&category.UserID,
		&category.Name,
		&category.Type,
		&category.Emoji,
		&category.CreatedAt,
		&category.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func addCategory(category Category) (int, error) {
	result, err := db.Exec(
		`INSERT INTO categories (user_id, name, type, emoji) VALUES (?, ?, ?, ?)`,
		category.UserID, category.Name, category.Type, category.Emoji,
	)
	if err != nil {
		return 0, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}

	return int(id), nil
}

func updateCategory(category Category) error {
	_, err := db.Exec(
		`UPDATE categories SET name = ?, type = ?, emoji = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND user_id = ?`,
		category.Name, category.Type, category.Emoji, category.ID, category.UserID,
	)
	return err
}

func deleteCategory(categoryID int, userID string) error {
	_, err := db.Exec(
		`DELETE FROM categories WHERE id = ? AND user_id = ?`,
		categoryID, userID,
	)
	return err
}

func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
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
