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

var (
	db *sql.DB
)

// Estructura para la respuesta API
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Estructura para los datos de flujo de dinero
type MoneyFlowData struct {
	UserID           string    `json:"user_id"`
	Period           string    `json:"period"`
	Date             string    `json:"date"`
	TotalIncome      float64   `json:"total_income"`
	SpentAmount      float64   `json:"spent_amount"`
	UpcomingBills    float64   `json:"upcoming_bills"`
	FromPrevious     float64   `json:"from_previous"`
	RemainingAmount  float64   `json:"remaining_amount"`
	TotalBudget      float64   `json:"total_budget"`
	CombinedExpenses float64   `json:"combined_expenses"`
	ExpensePercent   float64   `json:"expense_percent"`
	DailyRate        float64   `json:"daily_rate"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

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
	// Set up HTTP handlers with CORS middleware
	http.HandleFunc("/money-flow/calculate", corsMiddleware(handleCalculateMoneyFlow))
	http.HandleFunc("/money-flow/data", corsMiddleware(handleGetMoneyFlowData))

	port := 8097
	log.Printf("Money Flow Calculation service started on :%d", port)
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

func handleCalculateMoneyFlow(w http.ResponseWriter, r *http.Request) {
	// Solo permitimos POST para esta operación
	if r.Method != "POST" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID and period from request
	userID := r.URL.Query().Get("user_id")
	period := r.URL.Query().Get("period")

	if userID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if period == "" {
		period = "monthly" // Default period
	}

	// Calculate money flow
	moneyFlowData, err := calculateMoneyFlow(userID, period)
	if err != nil {
		log.Printf("Error calculating money flow: %v", err)
		sendErrorResponse(w, "Error calculating money flow", http.StatusInternalServerError)
		return
	}

	// Store the calculated money flow data (opcional)
	err = storeMoneyFlowData(moneyFlowData)
	if err != nil {
		log.Printf("Error storing money flow data: %v", err)
		// Continue anyway, we can still return the calculated data
	}

	// Return money flow data
	sendSuccessResponse(w, "Money flow calculated successfully", moneyFlowData)
}

func handleGetMoneyFlowData(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		sendErrorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID and period from request
	userID := r.URL.Query().Get("user_id")
	period := r.URL.Query().Get("period")

	if userID == "" {
		sendErrorResponse(w, "User ID is required", http.StatusBadRequest)
		return
	}

	if period == "" {
		period = "monthly" // Default period
	}

	// Calculate money flow
	moneyFlowData, err := calculateMoneyFlow(userID, period)
	if err != nil {
		log.Printf("Error calculating money flow: %v", err)
		sendErrorResponse(w, "Error calculating money flow", http.StatusInternalServerError)
		return
	}

	// Return money flow data
	sendSuccessResponse(w, "Money flow data retrieved successfully", moneyFlowData)
}

func calculateMoneyFlow(userID, period string) (MoneyFlowData, error) {
	var moneyFlowData MoneyFlowData
	moneyFlowData.UserID = userID
	moneyFlowData.Period = period
	moneyFlowData.Date = time.Now().Format("2006-01-02")

	// Obtener el rango de fechas para el período actual
	startDate, endDate := getDateRangeForPeriod(period)

	log.Printf("Calculating money flow for user %s in period %s (%s to %s)", userID, period, startDate, endDate)

	// 1. Calcular ingresos totales del período
	err := db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM incomes
		WHERE user_id = ? AND date BETWEEN ? AND ?
	`, userID, startDate, endDate).Scan(&moneyFlowData.TotalIncome)

	if err != nil {
		return moneyFlowData, fmt.Errorf("error calculating total income: %v", err)
	}

	// 2. Calcular gastos realizados
	err = db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM expenses
		WHERE user_id = ? AND date BETWEEN ? AND ?
	`, userID, startDate, endDate).Scan(&moneyFlowData.SpentAmount)

	if err != nil {
		return moneyFlowData, fmt.Errorf("error calculating spent amount: %v", err)
	}

	// 3. Calcular facturas pendientes
	err = db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM bills
		WHERE user_id = ? AND paid = 0 AND due_date BETWEEN ? AND ?
	`, userID, startDate, endDate).Scan(&moneyFlowData.UpcomingBills)

	if err != nil {
		return moneyFlowData, fmt.Errorf("error calculating upcoming bills: %v", err)
	}

	// 4. Calcular saldo heredado de períodos anteriores
	moneyFlowData.FromPrevious = calculateBalanceFromPreviousPeriod(userID, period, startDate)

	// 5. Calcular el presupuesto total (ingresos + saldo heredado)
	moneyFlowData.TotalBudget = moneyFlowData.TotalIncome + moneyFlowData.FromPrevious

	// 6. Calcular gastos combinados (gastos realizados + facturas pendientes)
	moneyFlowData.CombinedExpenses = moneyFlowData.SpentAmount + moneyFlowData.UpcomingBills

	// 7. Calcular cantidad restante
	moneyFlowData.RemainingAmount = moneyFlowData.TotalBudget - moneyFlowData.CombinedExpenses

	// 8. Calcular porcentaje de gastos
	if moneyFlowData.TotalBudget > 0 {
		moneyFlowData.ExpensePercent = (moneyFlowData.CombinedExpenses / moneyFlowData.TotalBudget) * 100
	} else {
		moneyFlowData.ExpensePercent = 0
	}

	// 9. Calcular tasa diaria de gastos (usando gastos combinados)
	moneyFlowData.DailyRate = calculateDailyRate(moneyFlowData.CombinedExpenses, period, startDate, endDate)

	// Asegurar que la tasa diaria nunca sea cero si hay gastos
	if moneyFlowData.DailyRate == 0 && moneyFlowData.CombinedExpenses > 0 {
		log.Printf("Warning: Daily rate calculated as 0 but expenses exist. Applying default calculation.")
		moneyFlowData.DailyRate = calculateDefaultDailyRate(moneyFlowData.CombinedExpenses, period)
	}

	log.Printf("Daily rate calculated: %f for period %s with expenses %f",
		moneyFlowData.DailyRate, period, moneyFlowData.CombinedExpenses)

	// Actualizar marcas de tiempo
	now := time.Now()
	moneyFlowData.CreatedAt = now
	moneyFlowData.UpdatedAt = now

	return moneyFlowData, nil
}

func calculateBalanceFromPreviousPeriod(userID string, currentPeriod string, startDate string) float64 {
	log.Printf("Calculating balance from previous period for user %s in period %s (before %s)", userID, currentPeriod, startDate)

	var balance float64

	// Si hay una entrada en la tabla budget para el usuario, utilizamos el campo from_previous
	err := db.QueryRow(`
		SELECT COALESCE(from_previous, 0)
		FROM budget
		WHERE user_id = ? AND period = ?
		ORDER BY created_at DESC
		LIMIT 1
	`, userID, currentPeriod).Scan(&balance)

	if err == nil && balance > 0 {
		log.Printf("Found existing budget entry with from_previous=%f", balance)
		return balance
	}

	// Si no hay presupuesto o el saldo es 0, calculamos el saldo por diferencia entre ingresos y gastos
	// en períodos anteriores

	// 1. Primero obtenemos todos los ingresos anteriores
	var totalPreviousIncome float64
	err = db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM incomes
		WHERE user_id = ? AND date < ?
	`, userID, startDate).Scan(&totalPreviousIncome)

	if err != nil {
		log.Printf("Error calculating previous income: %v", err)
		return 0
	}

	// 2. Obtenemos todos los gastos anteriores
	var totalPreviousExpenses float64
	err = db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM expenses
		WHERE user_id = ? AND date < ?
	`, userID, startDate).Scan(&totalPreviousExpenses)

	if err != nil {
		log.Printf("Error calculating previous expenses: %v", err)
		return 0
	}

	// 3. Obtenemos facturas pagadas anteriores
	var totalPreviousPaidBills float64
	err = db.QueryRow(`
		SELECT COALESCE(SUM(amount), 0)
		FROM bills
		WHERE user_id = ? AND paid = 1 AND due_date < ?
	`, userID, startDate).Scan(&totalPreviousPaidBills)

	if err != nil {
		log.Printf("Error calculating previous paid bills: %v", err)
		return 0
	}

	// El saldo heredado es: ingresos - (gastos + facturas pagadas)
	balance = totalPreviousIncome - (totalPreviousExpenses + totalPreviousPaidBills)

	// Si el saldo es negativo, lo consideramos como 0 (no se hereda deuda)
	if balance < 0 {
		balance = 0
	}

	log.Printf("Calculated balance from previous periods: %f (income=%f, expenses=%f, paid bills=%f)",
		balance, totalPreviousIncome, totalPreviousExpenses, totalPreviousPaidBills)

	return balance
}

func storeMoneyFlowData(data MoneyFlowData) error {
	// Comprobamos si ya existe un registro para este usuario y período
	var count int
	err := db.QueryRow(`
		SELECT COUNT(*)
		FROM budget
		WHERE user_id = ? AND period = ?
	`, data.UserID, data.Period).Scan(&count)

	if err != nil {
		return err
	}

	if count > 0 {
		// Actualizar el registro existente
		_, err = db.Exec(`
			UPDATE budget
			SET date = ?,
				total_amount = ?,
				remaining_amount = ?,
				spent_amount = ?,
				upcoming_amount = ?,
				from_previous = ?,
				percent = ?,
				total_income = ?,
				daily_rate = ?,
				updated_at = CURRENT_TIMESTAMP
			WHERE user_id = ? AND period = ?
		`,
			data.Date,
			data.TotalBudget,
			data.RemainingAmount,
			data.SpentAmount,
			data.UpcomingBills,
			data.FromPrevious,
			data.ExpensePercent,
			data.TotalIncome,
			data.DailyRate,
			data.UserID,
			data.Period)
	} else {
		// Insertar un nuevo registro
		_, err = db.Exec(`
			INSERT INTO budget (
				user_id, period, date, total_amount, remaining_amount,
				spent_amount, upcoming_amount, from_previous, percent, total_income,
				daily_rate
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`,
			data.UserID,
			data.Period,
			data.Date,
			data.TotalBudget,
			data.RemainingAmount,
			data.SpentAmount,
			data.UpcomingBills,
			data.FromPrevious,
			data.ExpensePercent,
			data.TotalIncome,
			data.DailyRate)
	}

	return err
}

func getDateRangeForPeriod(period string) (string, string) {
	now := time.Now()
	var startDate, endDate time.Time

	switch period {
	case "daily":
		startDate = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		endDate = time.Date(now.Year(), now.Month(), now.Day(), 23, 59, 59, 0, now.Location())
	case "weekly":
		// Calculate the start of the week (assuming Monday is the first day)
		daysToMonday := int(now.Weekday())
		if daysToMonday == 0 {
			daysToMonday = 7 // Sunday is 0, so 7 days to the previous Monday
		} else {
			daysToMonday = daysToMonday - 1 // Monday is 1, so 0 days
		}
		startDate = time.Date(now.Year(), now.Month(), now.Day()-daysToMonday, 0, 0, 0, 0, now.Location())
		endDate = startDate.AddDate(0, 0, 6)
		endDate = time.Date(endDate.Year(), endDate.Month(), endDate.Day(), 23, 59, 59, 0, endDate.Location())
	case "monthly":
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		endDate = time.Date(now.Year(), now.Month()+1, 0, 23, 59, 59, 0, now.Location())
	case "quarterly":
		quarter := (int(now.Month()) - 1) / 3
		startDate = time.Date(now.Year(), time.Month(quarter*3+1), 1, 0, 0, 0, 0, now.Location())
		endDate = time.Date(now.Year(), time.Month(quarter*3+4), 0, 23, 59, 59, 0, now.Location())
	case "yearly":
		startDate = time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
		endDate = time.Date(now.Year(), 12, 31, 23, 59, 59, 0, now.Location())
	default:
		// Default to monthly
		startDate = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		endDate = time.Date(now.Year(), now.Month()+1, 0, 23, 59, 59, 0, now.Location())
	}

	return startDate.Format("2006-01-02"), endDate.Format("2006-01-02")
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

// Función para calcular la tasa diaria de gasto basada en el período
func calculateDailyRate(expenses float64, period string, startDate, endDate string) float64 {
	// Si no hay gastos, la tasa diaria es cero
	if expenses <= 0 {
		return 0
	}

	// Parseamos las fechas para calcular el número de días
	start, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		log.Printf("Error parsing startDate: %v", err)
		return calculateDefaultDailyRate(expenses, period)
	}

	end, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		log.Printf("Error parsing endDate: %v", err)
		return calculateDefaultDailyRate(expenses, period)
	}

	// Calculamos el número real de días en el período
	// Sumamos 1 porque incluimos ambos días (inicio y fin)
	days := end.Sub(start).Hours()/24 + 1

	log.Printf("Period %s from %s to %s has %.1f days",
		period, startDate, endDate, days)

	// Si hay algún problema con el cálculo de días, usamos valores predeterminados
	if days <= 0 {
		log.Printf("Error: Invalid days calculation (%f). Using default.", days)
		return calculateDefaultDailyRate(expenses, period)
	}

	dailyRate := expenses / days
	log.Printf("Daily rate calculation: %f / %f = %f", expenses, days, dailyRate)

	// Si por alguna razón el dailyRate es 0 pero hay gastos, usar el cálculo predeterminado
	if dailyRate == 0 && expenses > 0 {
		log.Printf("Warning: Daily rate calculated as 0 but expenses exist (%f). Using default calculation.", expenses)
		return calculateDefaultDailyRate(expenses, period)
	}

	return dailyRate
}

// Función para calcular la tasa diaria usando valores predeterminados por período
func calculateDefaultDailyRate(expenses float64, period string) float64 {
	// Si no hay gastos, la tasa diaria es cero
	if expenses <= 0 {
		return 0
	}

	var days float64 = 30 // default para mensual

	switch period {
	case "daily":
		days = 1
	case "weekly":
		days = 7
	case "monthly":
		days = 30
	case "quarterly":
		days = 90
	case "yearly":
		days = 365
	}

	dailyRate := expenses / days
	log.Printf("Default daily rate calculation: %f / %f = %f", expenses, days, dailyRate)

	return dailyRate
}
