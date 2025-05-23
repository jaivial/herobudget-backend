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

// BudgetOverview represents the budget overview data structure
type BudgetOverview struct {
	RemainingAmount      float64              `json:"remaining_amount"`
	ExpensePercent       float64              `json:"expense_percent"`
	SpentAmount          float64              `json:"spent_amount"`
	UpcomingAmount       float64              `json:"upcoming_amount"`
	TotalAmount          float64              `json:"total_amount"`
	CombinedExpense      float64              `json:"combined_expense"`
	TotalIncome          float64              `json:"total_income"`
	DailyRate            float64              `json:"daily_rate"`
	HighSpending         bool                 `json:"high_spending"`
	MoneyFlow            MoneyFlow            `json:"money_flow"`
	CashBankDistribution CashBankDistribution `json:"cash_bank_distribution"`
	SavingsData          SavingsData          `json:"savings_data"`
}

// MoneyFlow represents money flow from previous period
type MoneyFlow struct {
	FromPrevious float64 `json:"from_previous"`
}

// BudgetOverviewRequest represents the request structure
type BudgetOverviewRequest struct {
	UserID    string `json:"user_id"`
	Period    string `json:"period"`               // daily, weekly, monthly, quarterly, semiannual, annual
	Date      string `json:"date"`                 // Format depends on period type
	StartDate string `json:"start_date,omitempty"` // For custom periods
	EndDate   string `json:"end_date,omitempty"`   // For custom periods
}

// ApiResponse represents the standard API response
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// BalanceData represents the balance data from database
type BalanceData struct {
	IncomeBankAmount     float64 `json:"income_bank_amount"`
	IncomeCashAmount     float64 `json:"income_cash_amount"`
	ExpenseBankAmount    float64 `json:"expense_bank_amount"`
	ExpenseCashAmount    float64 `json:"expense_cash_amount"`
	BillBankAmount       float64 `json:"bill_bank_amount"`
	BillCashAmount       float64 `json:"bill_cash_amount"`
	BankAmount           float64 `json:"bank_amount"`
	PreviousBankAmount   float64 `json:"previous_bank_amount"`
	CashAmount           float64 `json:"cash_amount"`
	PreviousCashAmount   float64 `json:"previous_cash_amount"`
	BalanceCashAmount    float64 `json:"balance_cash_amount"`
	BalanceBankAmount    float64 `json:"balance_bank_amount"`
	TotalPreviousBalance float64 `json:"total_previous_balance"`
	TotalBalance         float64 `json:"total_balance"`
}

// CashBankDistribution represents the cash and bank distribution
type CashBankDistribution struct {
	CashAmount  float64 `json:"cash_amount"`
	CashPercent float64 `json:"cash_percent"`
	BankAmount  float64 `json:"bank_amount"`
	BankPercent float64 `json:"bank_percent"`
	TotalAmount float64 `json:"total_amount"`
}

// SavingsData represents savings information
type SavingsData struct {
	Available float64 `json:"available"`
	Goal      float64 `json:"goal"`
	Percent   float64 `json:"percent"`
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

	log.Println("Database connection established successfully")
}

func main() {
	// Set up HTTP routes
	http.HandleFunc("/budget-overview", corsMiddleware(handleBudgetOverview))
	http.HandleFunc("/health", corsMiddleware(handleHealth))

	// Start server on port 8097
	port := "8097"
	log.Printf("Budget Overview Fetch service starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// corsMiddleware adds CORS headers to allow cross-origin requests
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	}
}

// handleHealth provides a health check endpoint
func handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	sendSuccessResponse(w, "Service is healthy", map[string]string{
		"service": "budget_overview_fetch",
		"status":  "active",
		"port":    "8097",
	})
}

// handleBudgetOverview handles the budget overview requests
func handleBudgetOverview(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var request BudgetOverviewRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		log.Printf("Error decoding request: %v", err)
		sendErrorResponse(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if request.UserID == "" {
		sendErrorResponse(w, "user_id is required", http.StatusBadRequest)
		return
	}

	if request.Period == "" {
		request.Period = "monthly" // Default to monthly
	}

	if request.Date == "" {
		// Default to current date/period
		request.Date = formatDateForPeriod(time.Now(), request.Period)
	}

	// Fetch budget overview data
	overview, err := fetchBudgetOverview(request)
	if err != nil {
		log.Printf("Error fetching budget overview: %v", err)
		sendErrorResponse(w, "Failed to fetch budget overview", http.StatusInternalServerError)
		return
	}

	sendSuccessResponse(w, "Budget overview fetched successfully", overview)
}

// fetchBudgetOverview retrieves budget overview data for the specified period
func fetchBudgetOverview(request BudgetOverviewRequest) (*BudgetOverview, error) {
	// Get the appropriate table name and date condition
	tableName, dateCondition := getTableAndCondition(request.Period, request.Date)

	// Fetch balance data from the appropriate table
	balanceData, err := fetchBalanceData(tableName, request.UserID, dateCondition)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch balance data: %v", err)
	}

	// Calculate budget overview from balance data
	overview := calculateBudgetOverview(balanceData, request.Period)

	return overview, nil
}

// getTableAndCondition returns the table name and WHERE condition for the given period
func getTableAndCondition(period, date string) (string, string) {
	switch period {
	case "daily":
		return "daily_cash_bank_balance", fmt.Sprintf("date = '%s'", date)
	case "weekly":
		return "weekly_cash_bank_balance", fmt.Sprintf("year_week = '%s'", date)
	case "monthly":
		return "monthly_cash_bank_balance", fmt.Sprintf("year_month = '%s'", date)
	case "quarterly":
		return "quarterly_cash_bank_balance", fmt.Sprintf("year_quarter = '%s'", date)
	case "semiannual":
		return "semiannual_cash_bank_balance", fmt.Sprintf("year_half = '%s'", date)
	case "annual":
		return "annual_cash_bank_balance", fmt.Sprintf("year = '%s'", date)
	default:
		// Default to monthly
		return "monthly_cash_bank_balance", fmt.Sprintf("year_month = '%s'", date)
	}
}

// fetchBalanceData retrieves balance data from the specified table
func fetchBalanceData(tableName, userID, condition string) (*BalanceData, error) {
	query := fmt.Sprintf(`
		SELECT 
			COALESCE(income_bank_amount, 0) as income_bank_amount,
			COALESCE(income_cash_amount, 0) as income_cash_amount,
			COALESCE(expense_bank_amount, 0) as expense_bank_amount,
			COALESCE(expense_cash_amount, 0) as expense_cash_amount,
			COALESCE(bill_bank_amount, 0) as bill_bank_amount,
			COALESCE(bill_cash_amount, 0) as bill_cash_amount,
			COALESCE(bank_amount, 0) as bank_amount,
			COALESCE(previous_bank_amount, 0) as previous_bank_amount,
			COALESCE(cash_amount, 0) as cash_amount,
			COALESCE(previous_cash_amount, 0) as previous_cash_amount,
			COALESCE(balance_cash_amount, 0) as balance_cash_amount,
			COALESCE(balance_bank_amount, 0) as balance_bank_amount,
			COALESCE(total_previous_balance, 0) as total_previous_balance,
			COALESCE(total_balance, 0) as total_balance
		FROM %s 
		WHERE user_id = ? AND %s
	`, tableName, condition)

	row := db.QueryRow(query, userID)

	var data BalanceData
	err := row.Scan(
		&data.IncomeBankAmount,
		&data.IncomeCashAmount,
		&data.ExpenseBankAmount,
		&data.ExpenseCashAmount,
		&data.BillBankAmount,
		&data.BillCashAmount,
		&data.BankAmount,
		&data.PreviousBankAmount,
		&data.CashAmount,
		&data.PreviousCashAmount,
		&data.BalanceCashAmount,
		&data.BalanceBankAmount,
		&data.TotalPreviousBalance,
		&data.TotalBalance,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			// Return empty data if no record found
			return &BalanceData{}, nil
		}
		return nil, err
	}

	return &data, nil
}

// calculateBudgetOverview calculates the budget overview from balance data
func calculateBudgetOverview(data *BalanceData, period string) *BudgetOverview {
	// Calculate basic amounts
	totalIncome := data.IncomeBankAmount + data.IncomeCashAmount
	spentAmount := data.ExpenseBankAmount + data.ExpenseCashAmount
	upcomingAmount := data.BillBankAmount + data.BillCashAmount
	combinedExpense := spentAmount + upcomingAmount

	// Calculate total amount (current balance + expenses)
	totalAmount := data.TotalBalance + combinedExpense

	// Calculate remaining amount
	remainingAmount := totalAmount - combinedExpense

	// Calculate expense percentage
	var expensePercent float64
	if totalAmount > 0 {
		expensePercent = (combinedExpense / totalAmount) * 100
	}

	// Calculate daily rate based on period
	dailyRate := calculateDailyRate(spentAmount, period)

	// Determine high spending (if expense percent > 80%)
	highSpending := expensePercent > 80

	// Money flow from previous period
	moneyFlow := MoneyFlow{
		FromPrevious: data.TotalPreviousBalance,
	}

	// Calculate Cash/Bank Distribution
	cashAmount := data.CashAmount
	bankAmount := data.BankAmount
	totalCashBank := cashAmount + bankAmount

	var cashPercent, bankPercent float64
	if totalCashBank > 0 {
		cashPercent = (cashAmount / totalCashBank) * 100
		bankPercent = (bankAmount / totalCashBank) * 100
	}

	cashBankDistribution := CashBankDistribution{
		CashAmount:  cashAmount,
		CashPercent: cashPercent,
		BankAmount:  bankAmount,
		BankPercent: bankPercent,
		TotalAmount: totalCashBank,
	}

	// Calculate Savings Data (remaining amount is considered as available savings)
	// For now, we use a basic goal calculation (could be made configurable)
	savingsGoal := totalIncome * 0.2 // 20% of income as goal
	var savingsPercent float64
	if savingsGoal > 0 {
		savingsPercent = (remainingAmount / savingsGoal) * 100
	}

	savingsData := SavingsData{
		Available: remainingAmount,
		Goal:      savingsGoal,
		Percent:   savingsPercent,
	}

	return &BudgetOverview{
		RemainingAmount:      remainingAmount,
		ExpensePercent:       expensePercent,
		SpentAmount:          spentAmount,
		UpcomingAmount:       upcomingAmount,
		TotalAmount:          totalAmount,
		CombinedExpense:      combinedExpense,
		TotalIncome:          totalIncome,
		DailyRate:            dailyRate,
		HighSpending:         highSpending,
		MoneyFlow:            moneyFlow,
		CashBankDistribution: cashBankDistribution,
		SavingsData:          savingsData,
	}
}

// calculateDailyRate calculates the daily spending rate based on the period
func calculateDailyRate(spentAmount float64, period string) float64 {
	var days float64

	switch period {
	case "daily":
		days = 1
	case "weekly":
		days = 7
	case "monthly":
		days = 30 // Average month
	case "quarterly":
		days = 90 // 3 months
	case "semiannual":
		days = 180 // 6 months
	case "annual":
		days = 365
	default:
		days = 30 // Default to monthly
	}

	if days > 0 {
		return spentAmount / days
	}

	return 0
}

// formatDateForPeriod formats the current date according to the period type
func formatDateForPeriod(date time.Time, period string) string {
	switch period {
	case "daily":
		return date.Format("2006-01-02")
	case "weekly":
		year, week := date.ISOWeek()
		return fmt.Sprintf("%d-W%02d", year, week)
	case "monthly":
		return date.Format("2006-01")
	case "quarterly":
		quarter := ((date.Month() - 1) / 3) + 1
		return fmt.Sprintf("%d-Q%d", date.Year(), quarter)
	case "semiannual":
		half := 1
		if date.Month() > 6 {
			half = 2
		}
		return fmt.Sprintf("%d-H%d", date.Year(), half)
	case "annual":
		return strconv.Itoa(date.Year())
	default:
		return date.Format("2006-01")
	}
}

// sendSuccessResponse sends a successful JSON response
func sendSuccessResponse(w http.ResponseWriter, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := ApiResponse{
		Success: true,
		Message: message,
		Data:    data,
	}

	json.NewEncoder(w).Encode(response)
}

// sendErrorResponse sends an error JSON response
func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := ApiResponse{
		Success: false,
		Message: message,
	}

	json.NewEncoder(w).Encode(response)
}
