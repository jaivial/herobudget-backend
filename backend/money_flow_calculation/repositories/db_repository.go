package repositories

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"money_flow_calculation/models"
)

// DBRepositoryInterface defines the interface for the database repository
type DBRepositoryInterface interface {
	GetTotalIncome(userID string, start, end time.Time) (float64, error)
	GetTotalExpenses(userID string, start, end time.Time) (float64, error)
	GetFutureBills(userID string, start, end time.Time) (float64, error)
	GetPreviousIncome(userID string, before time.Time) (float64, error)
	GetPreviousExpenses(userID string, before time.Time) (float64, error)
	GetPreviousPaidBills(userID string, before time.Time) (float64, error)
	GetPreviousRemainingMoney(userID string, period string) (float64, error)
	StoreBudgetData(userID, period string, date time.Time, totalBudget, remainingAmount, spentAmount, upcomingAmount, fromPrevious, expensePercent, totalIncome, dailyRate float64) error
	GetBudgetRecord(userID, period string) (*models.BudgetRecord, error)
}

// DBRepository handles database interactions
type DBRepository struct {
	db *sql.DB
}

// NewDBRepository creates a new database repository
func NewDBRepository(db *sql.DB) *DBRepository {
	return &DBRepository{db: db}
}

// GetTotalIncome retrieves the total income for a user in a given period
func (r *DBRepository) GetTotalIncome(userID string, start, end time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM incomes WHERE user_id = ? AND date BETWEEN ? AND ?`

	err := r.db.QueryRow(query, userID, start.Format("2006-01-02"), end.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting total income: %w", err)
	}

	log.Printf("Total income for user %s between %s and %s: %f",
		userID, start.Format("2006-01-02"), end.Format("2006-01-02"), total)

	return total, nil
}

// GetTotalExpenses retrieves the total expenses for a user in a given period
func (r *DBRepository) GetTotalExpenses(userID string, start, end time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ? AND date BETWEEN ? AND ?`

	err := r.db.QueryRow(query, userID, start.Format("2006-01-02"), end.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting total expenses: %w", err)
	}

	log.Printf("Total expenses for user %s between %s and %s: %f",
		userID, start.Format("2006-01-02"), end.Format("2006-01-02"), total)

	return total, nil
}

// GetFutureBills retrieves the unpaid bills for a user in a given period
func (r *DBRepository) GetFutureBills(userID string, start, end time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM bills WHERE user_id = ? AND paid = 0 AND due_date BETWEEN ? AND ?`

	err := r.db.QueryRow(query, userID, start.Format("2006-01-02"), end.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting future bills: %w", err)
	}

	log.Printf("Future bills for user %s between %s and %s: %f",
		userID, start.Format("2006-01-02"), end.Format("2006-01-02"), total)

	return total, nil
}

// GetPreviousIncome retrieves all previous income for a user before a specific date
func (r *DBRepository) GetPreviousIncome(userID string, before time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM incomes WHERE user_id = ? AND date < ?`

	err := r.db.QueryRow(query, userID, before.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting previous income: %w", err)
	}

	log.Printf("Previous income for user %s before %s: %f",
		userID, before.Format("2006-01-02"), total)

	return total, nil
}

// GetPreviousExpenses retrieves all previous expenses for a user before a specific date
func (r *DBRepository) GetPreviousExpenses(userID string, before time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ? AND date < ?`

	err := r.db.QueryRow(query, userID, before.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting previous expenses: %w", err)
	}

	log.Printf("Previous expenses for user %s before %s: %f",
		userID, before.Format("2006-01-02"), total)

	return total, nil
}

// GetPreviousPaidBills retrieves all previous paid bills for a user before a specific date
func (r *DBRepository) GetPreviousPaidBills(userID string, before time.Time) (float64, error) {
	var total float64
	query := `SELECT COALESCE(SUM(amount), 0) FROM bills WHERE user_id = ? AND paid = 1 AND due_date < ?`

	err := r.db.QueryRow(query, userID, before.Format("2006-01-02")).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("error getting previous paid bills: %w", err)
	}

	log.Printf("Previous paid bills for user %s before %s: %f",
		userID, before.Format("2006-01-02"), total)

	return total, nil
}

// GetPreviousRemainingMoney retrieves the remaining money from the previous period
func (r *DBRepository) GetPreviousRemainingMoney(userID string, period string) (float64, error) {
	var balance float64
	query := `
		SELECT COALESCE(from_previous, 0)
		FROM budget
		WHERE user_id = ? AND period = ?
		ORDER BY created_at DESC
		LIMIT 1
	`
	err := r.db.QueryRow(query, userID, period).Scan(&balance)
	if err == sql.ErrNoRows {
		log.Printf("No previous budget record found for user %s with period %s", userID, period)
		return 0, nil // No previous record found
	}
	if err != nil {
		return 0, fmt.Errorf("error getting previous remaining money: %w", err)
	}

	log.Printf("Previous remaining balance for user %s with period %s: %f",
		userID, period, balance)

	return balance, nil
}

// GetBudgetRecord retrieves the latest budget record for a user and period
func (r *DBRepository) GetBudgetRecord(userID, period string) (*models.BudgetRecord, error) {
	query := `
		SELECT id, user_id, period, date, total_amount, remaining_amount, 
		       spent_amount, upcoming_amount, from_previous, percent, 
		       total_income, daily_rate, created_at, updated_at
		FROM budget
		WHERE user_id = ? AND period = ?
		ORDER BY created_at DESC
		LIMIT 1
	`

	var record models.BudgetRecord
	var dateStr string
	var createdAtStr, updatedAtStr string

	err := r.db.QueryRow(query, userID, period).Scan(
		&record.ID, &record.UserID, &record.Period, &dateStr,
		&record.TotalAmount, &record.RemainingAmount, &record.SpentAmount,
		&record.UpcomingAmount, &record.FromPrevious, &record.ExpensePercent,
		&record.TotalIncome, &record.DailyRate, &createdAtStr, &updatedAtStr,
	)

	if err == sql.ErrNoRows {
		return nil, nil // No record found, not an error
	}
	if err != nil {
		return nil, fmt.Errorf("error getting budget record: %w", err)
	}

	// Parse dates
	record.Date, err = time.Parse("2006-01-02", dateStr)
	if err != nil {
		return nil, fmt.Errorf("error parsing date: %w", err)
	}

	record.CreatedAt, err = time.Parse("2006-01-02 15:04:05", createdAtStr)
	if err != nil {
		// Try alternative format if the first one fails
		record.CreatedAt, err = time.Parse(time.RFC3339, createdAtStr)
		if err != nil {
			log.Printf("Warning: Could not parse created_at date: %v", err)
			record.CreatedAt = time.Now() // Use current time as fallback
		}
	}

	record.UpdatedAt, err = time.Parse("2006-01-02 15:04:05", updatedAtStr)
	if err != nil {
		// Try alternative format if the first one fails
		record.UpdatedAt, err = time.Parse(time.RFC3339, updatedAtStr)
		if err != nil {
			log.Printf("Warning: Could not parse updated_at date: %v", err)
			record.UpdatedAt = time.Now() // Use current time as fallback
		}
	}

	return &record, nil
}

// StoreBudgetData stores or updates budget data in the database
func (r *DBRepository) StoreBudgetData(
	userID, period string,
	date time.Time,
	totalBudget, remainingAmount, spentAmount, upcomingAmount,
	fromPrevious, expensePercent, totalIncome, dailyRate float64,
) error {
	// Check if a record already exists
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(*) FROM budget 
		WHERE user_id = ? AND period = ?
	`, userID, period).Scan(&count)

	if err != nil {
		return fmt.Errorf("error checking for existing budget record: %w", err)
	}

	dateStr := date.Format("2006-01-02")

	if count > 0 {
		// Update existing record
		_, err = r.db.Exec(`
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
			dateStr,
			totalBudget,
			remainingAmount,
			spentAmount,
			upcomingAmount,
			fromPrevious,
			expensePercent,
			totalIncome,
			dailyRate,
			userID,
			period)

		if err != nil {
			return fmt.Errorf("error updating budget record: %w", err)
		}

		log.Printf("Updated budget record for user %s with period %s", userID, period)
	} else {
		// Insert new record
		_, err = r.db.Exec(`
			INSERT INTO budget (
				user_id, period, date, total_amount, remaining_amount,
				spent_amount, upcoming_amount, from_previous, percent, total_income,
				daily_rate, created_at, updated_at
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		`,
			userID,
			period,
			dateStr,
			totalBudget,
			remainingAmount,
			spentAmount,
			upcomingAmount,
			fromPrevious,
			expensePercent,
			totalIncome,
			dailyRate)

		if err != nil {
			return fmt.Errorf("error inserting new budget record: %w", err)
		}

		log.Printf("Inserted new budget record for user %s with period %s", userID, period)
	}

	return nil
}
