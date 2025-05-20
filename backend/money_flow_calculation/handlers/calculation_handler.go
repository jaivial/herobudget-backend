package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"money_flow_calculation/models"
	"money_flow_calculation/services"
)

// CalculationHandler handles HTTP requests for budget calculations
type CalculationHandler struct {
	service services.CalculationServiceInterface
}

// NewCalculationHandler creates a new calculation handler
func NewCalculationHandler(service services.CalculationServiceInterface) *CalculationHandler {
	return &CalculationHandler{service: service}
}

// HandleCalculate handles requests to calculate budget overview
func (h *CalculationHandler) HandleCalculate(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	// Handle preflight request
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	// Support both GET and POST for backward compatibility
	if r.Method != "GET" && r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse query parameters
	periodParam := r.URL.Query().Get("period")
	dateParam := r.URL.Query().Get("date")
	directionParam := r.URL.Query().Get("direction")
	userID := r.URL.Query().Get("user_id") // Optional for backward compatibility

	// Log the request
	log.Printf("Received request: period=%s, date=%s, direction=%s, user_id=%s",
		periodParam, dateParam, directionParam, userID)

	// Validate required parameters
	if periodParam == "" {
		log.Printf("Period parameter not provided, using default 'monthly'")
		periodParam = "monthly" // Default to monthly
	}

	if directionParam == "" {
		log.Printf("Direction parameter not provided, using default 'next'")
		directionParam = "next" // Default to next
	}

	// Validate direction parameter
	if directionParam != "next" && directionParam != "prev" {
		log.Printf("Invalid direction parameter provided: %s", directionParam)
		sendErrorResponse(w, "Invalid direction parameter. Must be 'prev' or 'next'", http.StatusBadRequest)
		return
	}

	// Parse date parameter
	var date time.Time
	var err error
	if dateParam != "" {
		date, err = time.Parse("2006-01-02", dateParam)
		if err != nil {
			log.Printf("Error parsing date parameter: %v", err)
			sendErrorResponse(w, "Invalid date format. Use YYYY-MM-DD", http.StatusBadRequest)
			return
		}
	} else {
		date = time.Now()
		log.Printf("Date parameter not provided, using current date: %s", date.Format("2006-01-02"))
	}

	// User ID validation
	if userID == "" {
		log.Printf("User ID not provided, calculations might be limited")
	}

	// Create the request model
	request := models.PeriodRequest{
		Period:    periodParam,
		Date:      date,
		Direction: directionParam,
		UserID:    userID,
	}

	// Calculate budget overview
	log.Printf("Calculating budget overview for user %s, period %s, direction %s, date %s",
		userID, periodParam, directionParam, date.Format("2006-01-02"))

	overview, err := h.service.CalculateBudgetOverview(request)
	if err != nil {
		log.Printf("Error calculating budget overview: %v", err)
		sendErrorResponse(w, "Error calculating budget overview", http.StatusInternalServerError)
		return
	}

	// Format dates for JSON response
	responseData := map[string]interface{}{
		"total_budget":      overview.TotalAmount,
		"remaining_amount":  overview.RemainingAmount,
		"spent_amount":      overview.SpentAmount,
		"upcoming_bills":    overview.UpcomingBills,
		"combined_expenses": overview.CombinedExpense,
		"expense_percent":   overview.ExpensePercent,
		"start_date":        overview.StartDate.Format("2006-01-02"),
		"end_date":          overview.EndDate.Format("2006-01-02"),
		"period":            overview.Period,
		"total_income":      overview.TotalIncome,
		"daily_rate":        overview.DailyRate,
		"from_previous":     overview.MoneyFlow.FromPrevious,
	}

	// Return the result
	log.Printf("Successfully calculated budget overview for user %s, period %s", userID, periodParam)
	sendSuccessResponse(w, "Budget overview calculated successfully", responseData)
}

// Common response utility functions

// ApiResponse represents a standardized API response
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// sendSuccessResponse sends a success response
func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding response: %v", err)
	}
}

// sendErrorResponse sends an error response
func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := ApiResponse{
		Success: false,
		Message: message,
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Error encoding error response: %v", err)
	}
}
