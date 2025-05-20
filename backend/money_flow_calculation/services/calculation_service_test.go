package services

import (
	"math"
	"testing"
	"time"

	"money_flow_calculation/models"
)

// MockDBRepository is a mock implementation of DBRepositoryInterface for testing
type MockDBRepository struct {
	mockTotalIncome            float64
	mockTotalExpenses          float64
	mockFutureBills            float64
	mockPreviousIncome         float64
	mockPreviousExpenses       float64
	mockPreviousPaidBills      float64
	mockPreviousRemainingMoney float64
	mockStoreBudgetDataCalled  bool
}

// GetTotalIncome mocks the repository GetTotalIncome method
func (m *MockDBRepository) GetTotalIncome(userID string, start, end time.Time) (float64, error) {
	return m.mockTotalIncome, nil
}

// GetTotalExpenses mocks the repository GetTotalExpenses method
func (m *MockDBRepository) GetTotalExpenses(userID string, start, end time.Time) (float64, error) {
	return m.mockTotalExpenses, nil
}

// GetFutureBills mocks the repository GetFutureBills method
func (m *MockDBRepository) GetFutureBills(userID string, start, end time.Time) (float64, error) {
	return m.mockFutureBills, nil
}

// GetPreviousIncome mocks the repository GetPreviousIncome method
func (m *MockDBRepository) GetPreviousIncome(userID string, before time.Time) (float64, error) {
	return m.mockPreviousIncome, nil
}

// GetPreviousExpenses mocks the repository GetPreviousExpenses method
func (m *MockDBRepository) GetPreviousExpenses(userID string, before time.Time) (float64, error) {
	return m.mockPreviousExpenses, nil
}

// GetPreviousPaidBills mocks the repository GetPreviousPaidBills method
func (m *MockDBRepository) GetPreviousPaidBills(userID string, before time.Time) (float64, error) {
	return m.mockPreviousPaidBills, nil
}

// GetPreviousRemainingMoney mocks the repository GetPreviousRemainingMoney method
func (m *MockDBRepository) GetPreviousRemainingMoney(userID string, period string) (float64, error) {
	return m.mockPreviousRemainingMoney, nil
}

// StoreBudgetData mocks the repository StoreBudgetData method
func (m *MockDBRepository) StoreBudgetData(userID, period string, date time.Time, totalBudget, remainingAmount, spentAmount, upcomingAmount, fromPrevious, expensePercent, totalIncome, dailyRate float64) error {
	m.mockStoreBudgetDataCalled = true
	return nil
}

// GetBudgetRecord mocks the repository GetBudgetRecord method
func (m *MockDBRepository) GetBudgetRecord(userID, period string) (*models.BudgetRecord, error) {
	return &models.BudgetRecord{
		UserID:          userID,
		Period:          period,
		TotalAmount:     1000,
		RemainingAmount: 500,
		FromPrevious:    200,
	}, nil
}

// Test the calculation service
func TestCalculateBudgetOverview(t *testing.T) {
	// Create a mock repository with test values
	mockRepo := &MockDBRepository{
		mockTotalIncome:            1000,
		mockTotalExpenses:          300,
		mockFutureBills:            200,
		mockPreviousRemainingMoney: 500, // Since we have this value, we won't use the other previous values
		mockPreviousIncome:         2000,
		mockPreviousExpenses:       1000,
		mockPreviousPaidBills:      500,
	}

	// Create the service with the mock repository
	service := NewCalculationService(mockRepo)

	// Create a request
	now := time.Now()
	request := models.PeriodRequest{
		Period:    "monthly",
		Date:      now,
		Direction: "next",
		UserID:    "test-user",
	}

	// Call the service
	overview, err := service.CalculateBudgetOverview(request)

	// Validate results
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	// Check that values are as expected
	if overview.TotalIncome != 1000 {
		t.Errorf("Expected TotalIncome to be 1000, got %f", overview.TotalIncome)
	}

	if overview.SpentAmount != 300 {
		t.Errorf("Expected SpentAmount to be 300, got %f", overview.SpentAmount)
	}

	if overview.UpcomingBills != 200 {
		t.Errorf("Expected UpcomingBills to be 200, got %f", overview.UpcomingBills)
	}

	if overview.MoneyFlow.FromPrevious != 500 {
		t.Errorf("Expected MoneyFlow.FromPrevious to be 500, got %f", overview.MoneyFlow.FromPrevious)
	}

	// Combined expense should be spent + upcoming
	if overview.CombinedExpense != 500 {
		t.Errorf("Expected CombinedExpense to be 500, got %f", overview.CombinedExpense)
	}

	// Total amount should be from previous + income
	if overview.TotalAmount != 1500 {
		t.Errorf("Expected TotalAmount to be 1500, got %f", overview.TotalAmount)
	}

	// Remaining amount should be total - combined expense
	if overview.RemainingAmount != 1000 {
		t.Errorf("Expected RemainingAmount to be 1000, got %f", overview.RemainingAmount)
	}

	// Expense percent should be (combined expense / total amount) * 100
	expectedPercent := (500.0 / 1500.0) * 100

	// Use a small epsilon for floating point comparison
	const epsilon = 0.000001
	if math.Abs(overview.ExpensePercent-expectedPercent) > epsilon {
		t.Errorf("Expected ExpensePercent to be %f, got %f", expectedPercent, overview.ExpensePercent)
	}

	// Verify that StoreBudgetData was called
	if !mockRepo.mockStoreBudgetDataCalled {
		t.Error("Expected StoreBudgetData to be called")
	}
}

// Test date range calculations
func TestGetDateRange(t *testing.T) {
	service := NewCalculationService(&MockDBRepository{})
	testDate := time.Date(2023, 5, 15, 0, 0, 0, 0, time.UTC)

	tests := []struct {
		name          string
		period        string
		direction     string
		expectedStart time.Time
		expectedEnd   time.Time
	}{
		{
			name:          "Daily next",
			period:        "daily",
			direction:     "next",
			expectedStart: time.Date(2023, 5, 16, 0, 0, 0, 0, time.UTC),
			expectedEnd:   time.Date(2023, 5, 16, 0, 0, 0, 0, time.UTC),
		},
		{
			name:          "Daily prev",
			period:        "daily",
			direction:     "prev",
			expectedStart: time.Date(2023, 5, 14, 0, 0, 0, 0, time.UTC),
			expectedEnd:   time.Date(2023, 5, 14, 0, 0, 0, 0, time.UTC),
		},
		{
			name:          "Monthly next",
			period:        "monthly",
			direction:     "next",
			expectedStart: time.Date(2023, 6, 1, 0, 0, 0, 0, time.UTC),
			expectedEnd:   time.Date(2023, 6, 30, 0, 0, 0, 0, time.UTC),
		},
		{
			name:          "Monthly prev",
			period:        "monthly",
			direction:     "prev",
			expectedStart: time.Date(2023, 4, 1, 0, 0, 0, 0, time.UTC),
			expectedEnd:   time.Date(2023, 4, 30, 0, 0, 0, 0, time.UTC),
		},
		{
			name:          "Annual next",
			period:        "annual",
			direction:     "next",
			expectedStart: time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC),
			expectedEnd:   time.Date(2024, 12, 31, 0, 0, 0, 0, time.UTC),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			start, end := service.getDateRange(tt.period, testDate, tt.direction)

			if !start.Equal(tt.expectedStart) {
				t.Errorf("Expected start date to be %v, got %v", tt.expectedStart, start)
			}

			if !end.Equal(tt.expectedEnd) {
				t.Errorf("Expected end date to be %v, got %v", tt.expectedEnd, end)
			}
		})
	}
}

func TestGetInheritedMoney(t *testing.T) {
	tests := []struct {
		name                   string
		mockRepo               *MockDBRepository
		expectedInheritedMoney float64
	}{
		{
			name: "With existing budget record",
			mockRepo: &MockDBRepository{
				mockPreviousRemainingMoney: 500,
			},
			expectedInheritedMoney: 500,
		},
		{
			name: "Without existing budget record, calculate from transactions",
			mockRepo: &MockDBRepository{
				mockPreviousRemainingMoney: 0, // No budget record
				mockPreviousIncome:         2000,
				mockPreviousExpenses:       800,
				mockPreviousPaidBills:      700,
			},
			expectedInheritedMoney: 500, // 2000 - (800 + 700)
		},
		{
			name: "With negative balance, should return 0",
			mockRepo: &MockDBRepository{
				mockPreviousRemainingMoney: 0, // No budget record
				mockPreviousIncome:         1000,
				mockPreviousExpenses:       1200,
				mockPreviousPaidBills:      300,
			},
			expectedInheritedMoney: 0, // 1000 - (1200 + 300) = -500, but min is 0
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewCalculationService(tt.mockRepo)
			result, err := service.getInheritedMoney("test-user", time.Now())

			if err != nil {
				t.Errorf("Expected no error, got %v", err)
			}

			if result != tt.expectedInheritedMoney {
				t.Errorf("Expected inherited money to be %f, got %f", tt.expectedInheritedMoney, result)
			}
		})
	}
}
