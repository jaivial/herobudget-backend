package models

import "time"

// BudgetOverview represents the budget overview data structure
type BudgetOverview struct {
	RemainingAmount float64   `json:"remaining_amount"`
	TotalIncome     float64   `json:"total_income"`
	SpentAmount     float64   `json:"spent_amount"`
	UpcomingBills   float64   `json:"upcoming_bills"`
	CombinedExpense float64   `json:"combined_expenses"`
	DailyRate       float64   `json:"daily_rate"`
	Period          string    `json:"period,omitempty"`
	StartDate       time.Time `json:"start_date,omitempty"`
	EndDate         time.Time `json:"end_date,omitempty"`
	UserID          string    `json:"-"` // Not included in JSON response
	TotalAmount     float64   `json:"total_amount"`
	ExpensePercent  float64   `json:"expense_percent"`
	MoneyFlow       MoneyFlow `json:"money_flow"`
}

// MoneyFlow contains the nested money flow data expected by the Flutter app
type MoneyFlow struct {
	FromPrevious float64 `json:"from_previous"`
}

// PeriodRequest represents the request parameters for calculating a period
type PeriodRequest struct {
	Period    string    `json:"period"`
	Date      time.Time `json:"date"`
	Direction string    `json:"direction"`
	UserID    string    `json:"user_id"`
}

// BudgetRecord represents a record in the budget table
type BudgetRecord struct {
	ID              int       `json:"id"`
	UserID          string    `json:"user_id"`
	Period          string    `json:"period"`
	Date            time.Time `json:"date"`
	TotalAmount     float64   `json:"total_amount"`
	RemainingAmount float64   `json:"remaining_amount"`
	SpentAmount     float64   `json:"spent_amount"`
	UpcomingAmount  float64   `json:"upcoming_amount"`
	FromPrevious    float64   `json:"from_previous"`
	ExpensePercent  float64   `json:"percent"`
	TotalIncome     float64   `json:"total_income"`
	DailyRate       float64   `json:"daily_rate"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}
