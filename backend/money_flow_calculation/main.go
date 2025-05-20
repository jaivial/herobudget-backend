package main

import (
	"database/sql"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"

	"money_flow_calculation/handlers"
	"money_flow_calculation/repositories"
	"money_flow_calculation/services"
)

const (
	PORT = 8097 // Keep port unchanged to maintain compatibility with restart_services.sh
)

func main() {
	// Configure logging
	logFile, err := setupLogging()
	if err != nil {
		log.Fatalf("Failed to set up logging: %v", err)
	}
	defer logFile.Close()

	// Log startup information
	log.Printf("Starting Money Flow Calculation Service v2.0.0")
	log.Printf("Running on port %d", PORT)

	// Write PID file
	writePIDFile()

	// Connect to database
	db, err := connectDatabase()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories, services, and handlers
	repo := repositories.NewDBRepository(db)
	service := services.NewCalculationService(repo)
	handler := handlers.NewCalculationHandler(service)

	// Set up HTTP routes with a router to handle multiple endpoints cleanly
	mux := http.NewServeMux()

	// Set up primary endpoint
	mux.HandleFunc("/calculate", handler.HandleCalculate)

	// Add backward compatibility routes
	mux.HandleFunc("/money-flow/calculate", handler.HandleCalculate)
	mux.HandleFunc("/money-flow/data", handler.HandleCalculate)

	// Add health check endpoint
	mux.HandleFunc("/health", healthCheckHandler)

	// Configure the server with timeouts
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", PORT),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start the server
	log.Printf("Money flow calculation service started on port %d", PORT)
	log.Fatal(server.ListenAndServe())
}

// healthCheckHandler provides a simple health check endpoint
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok","service":"money_flow_calculation","version":"2.0.0"}`))
}

// setupLogging configures logging to both console and file
func setupLogging() (*os.File, error) {
	logFilePath := "money_flow_calculation.log"
	logFile, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %v", err)
	}

	// Create a multi-writer to log to both file and console
	multiWriter := io.MultiWriter(os.Stdout, logFile)
	log.SetOutput(multiWriter)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	log.Printf("Logging to %s", logFilePath)
	return logFile, nil
}

// writePIDFile writes the current process ID to a file
func writePIDFile() {
	pidFilePath := "money_flow_calculation.pid"
	pid := os.Getpid()

	if err := os.WriteFile(pidFilePath, []byte(fmt.Sprintf("%d\n", pid)), 0644); err != nil {
		log.Printf("Warning: Failed to write PID file: %v", err)
	} else {
		log.Printf("PID %d written to %s", pid, pidFilePath)
	}
}

// connectDatabase establishes a connection to the SQLite database
func connectDatabase() (*sql.DB, error) {
	// Get the current working directory
	cwd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to get current directory: %v", err)
	}

	// Construct absolute path to the database file
	dbPath := filepath.Join(cwd, "..", "google_auth", "users.db")
	log.Printf("Using database at: %s", dbPath)

	// Open the database connection
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %v", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(time.Hour)

	// Test the connection
	if err = db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	log.Println("Database connection established successfully")
	return db, nil
}
