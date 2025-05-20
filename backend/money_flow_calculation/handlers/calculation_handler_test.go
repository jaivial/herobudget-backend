package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"money_flow_calculation/models"
)

// MockCalculationService is a mock of the CalculationServiceInterface
type MockCalculationService struct {
	mockBudgetOverview models.BudgetOverview
	mockError          error
}

// CalculateBudgetOverview mock implementation
func (m *MockCalculationService) CalculateBudgetOverview(req models.PeriodRequest) (models.BudgetOverview, error) {
	return m.mockBudgetOverview, m.mockError
}

func TestHandleCalculate(t *testing.T) {
	// Create a mock service
	mockService := &MockCalculationService{
		mockBudgetOverview: models.BudgetOverview{
			RemainingAmount: 800,
			TotalIncome:     1000,
			SpentAmount:     300,
			UpcomingBills:   200,
			CombinedExpense: 500,
			TotalAmount:     1300,
			DailyRate:       50,
			ExpensePercent:  38.46,
			Period:          "monthly",
			StartDate:       time.Date(2023, 6, 1, 0, 0, 0, 0, time.UTC),
			EndDate:         time.Date(2023, 6, 30, 0, 0, 0, 0, time.UTC),
			MoneyFlow: models.MoneyFlow{
				FromPrevious: 300,
			},
		},
		mockError: nil,
	}

	// Create handler with mock service
	handler := NewCalculationHandler(mockService)

	// Create a test request
	req, err := http.NewRequest("GET", "/calculate?period=monthly&date=2023-05-15&direction=next&user_id=test123", nil)
	if err != nil {
		t.Fatalf("Could not create request: %v", err)
	}

	// Create a response recorder
	recorder := httptest.NewRecorder()

	// Serve the request
	handler.HandleCalculate(recorder, req)

	// Check status code
	if status := recorder.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	// Check content type
	contentType := recorder.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("Handler returned wrong content type: got %v want %v", contentType, "application/json")
	}

	// Parse the response
	var response ApiResponse
	err = json.Unmarshal(recorder.Body.Bytes(), &response)
	if err != nil {
		t.Fatalf("Could not parse response JSON: %v", err)
	}

	// Check response fields
	if !response.Success {
		t.Errorf("Handler returned success = false, expected true")
	}

	data, ok := response.Data.(map[string]interface{})
	if !ok {
		t.Fatalf("Response data is not a map[string]interface{}")
	}

	// Check some key data points
	if data["remaining_amount"].(float64) != 800 {
		t.Errorf("Expected remaining_amount to be 800, got %v", data["remaining_amount"])
	}

	if data["total_income"].(float64) != 1000 {
		t.Errorf("Expected total_income to be 1000, got %v", data["total_income"])
	}

	if data["from_previous"].(float64) != 300 {
		t.Errorf("Expected from_previous to be 300, got %v", data["from_previous"])
	}
}

func TestHandleCalculateWithInvalidParams(t *testing.T) {
	mockService := &MockCalculationService{}
	handler := NewCalculationHandler(mockService)

	tests := []struct {
		name       string
		url        string
		wantStatus int
	}{
		{
			name:       "Invalid direction",
			url:        "/calculate?period=monthly&date=2023-05-15&direction=invalid&user_id=test123",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "Invalid date format",
			url:        "/calculate?period=monthly&date=15-05-2023&direction=next&user_id=test123",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "Missing parameters but with defaults",
			url:        "/calculate?user_id=test123",
			wantStatus: http.StatusOK, // Should use default values
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", tt.url, nil)
			if err != nil {
				t.Fatalf("Could not create request: %v", err)
			}

			recorder := httptest.NewRecorder()
			handler.HandleCalculate(recorder, req)

			if status := recorder.Code; status != tt.wantStatus {
				t.Errorf("Handler returned wrong status code: got %v want %v", status, tt.wantStatus)
			}
		})
	}
}

func TestCORSSupport(t *testing.T) {
	mockService := &MockCalculationService{}
	handler := NewCalculationHandler(mockService)

	// Test OPTIONS request for CORS preflight
	req, err := http.NewRequest("OPTIONS", "/calculate", nil)
	if err != nil {
		t.Fatalf("Could not create request: %v", err)
	}

	recorder := httptest.NewRecorder()
	handler.HandleCalculate(recorder, req)

	// Check status code for OPTIONS request
	if status := recorder.Code; status != http.StatusOK {
		t.Errorf("OPTIONS handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	// Check CORS headers
	corsOrigin := recorder.Header().Get("Access-Control-Allow-Origin")
	if corsOrigin != "*" {
		t.Errorf("Expected Access-Control-Allow-Origin header to be '*', got %v", corsOrigin)
	}

	corsMethods := recorder.Header().Get("Access-Control-Allow-Methods")
	if corsMethods != "GET, POST, OPTIONS" {
		t.Errorf("Expected Access-Control-Allow-Methods header to be 'GET, POST, OPTIONS', got %v", corsMethods)
	}
}
